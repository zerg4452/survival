class_name GameView
extends Node2D
## 게임 화면: 고정 틱 구동, 입력, 카메라, HUD·일시정지·결과·디버그 조작(D-003, D-019, D-020, D-022).

signal back_to_menu

const FIXED_SEED: int = 12345
const HP_MULTS: Array[float] = [1.0, 3.0, 10.0]

## 디버그: 다음 판부터 고정 시드 사용(F9). 판을 넘어 유지한다.
static var fixed_seed_enabled: bool = false

var content: GameContent = null
var martial_id: StringName = &""
var sim: RunSimulation = null
var runner: FixedStepRunner = FixedStepRunner.new()
var latch: InputLatch = InputLatch.new()

var renderer: WorldRenderer = null
var camera: Camera2D = null
var hud: Hud = null
var pause_menu: OverlayMenu = null
var result_screen: OverlayMenu = null

var _theme: Theme = null
var _hp_mult_index: int = 0
var _tick_ms_avg: float = 0.0
var _result_shown: bool = false

# ---- 개발용 자동 실행·화면 캡처(사용자 인자 --autoplay) ----
var autoplay: bool = false
var autoplay_seconds: float = 5.0
var capture_dir: String = ""
var _capture_ticks: Array[int] = [60, 150, 300]
var _result_captured: bool = false
var _capturing: bool = false
var _quitting: bool = false


func setup(p_content: GameContent, p_martial_id: StringName, theme: Theme) -> void:
	content = p_content
	martial_id = p_martial_id
	_theme = theme


func _ready() -> void:
	renderer = WorldRenderer.new()
	add_child(renderer)
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.theme = _theme
	layer.add_child(hud)
	pause_menu = OverlayMenu.new()
	pause_menu.theme = _theme
	layer.add_child(pause_menu)
	pause_menu.action.connect(_on_menu_action)
	result_screen = OverlayMenu.new()
	result_screen.theme = _theme
	layer.add_child(result_screen)
	result_screen.action.connect(_on_menu_action)
	_new_run()
	if autoplay:
		renderer.show_debug = true


func _new_run() -> void:
	var run_seed: int = FIXED_SEED if fixed_seed_enabled else int(randi())
	sim = RunSimulation.new(content, martial_id, run_seed)
	renderer.sim = sim
	runner = FixedStepRunner.new()
	latch.clear()
	_hp_mult_index = 0
	_result_shown = false
	pause_menu.visible = false
	result_screen.visible = false
	if autoplay:
		sim.debug_spawn_formation()


func _process(delta: float) -> void:
	if sim.state.phase == RunState.Phase.RUNNING:
		runner.advance(delta, _step_once)
	if sim.state.phase == RunState.Phase.RESULT and not _result_shown:
		_show_result()
	_update_camera()
	renderer.queue_redraw()
	hud.refresh(sim.state, _debug_text())
	if autoplay:
		_autoplay_tick()


func _step_once() -> void:
	var t0: int = Time.get_ticks_usec()
	sim.step(InputFrame.make(_read_move(), latch.consume_dash()))
	var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0
	_tick_ms_avg = lerpf(_tick_ms_avg, ms, 0.05)


func _read_move() -> Vector2:
	if autoplay:
		return Vector2.from_angle(float(sim.state.tick) / 90.0) * 0.8
	return Vector2(Input.get_axis(&"move_left", &"move_right"), Input.get_axis(&"move_up", &"move_down"))


func _update_camera() -> void:
	camera.position = sim.state.player.pos * WorldRenderer.PPC
	var h: float = get_viewport_rect().size.y
	var z: float = h / (sim.cfg.camera_visible_rows * WorldRenderer.PPC)
	camera.zoom = Vector2(z, z)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause", false):
		get_viewport().set_input_as_handled()
		_toggle_pause()
		return
	var key: InputEventKey = event as InputEventKey
	if sim.state.phase == RunState.Phase.RESULT:
		if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_R:
			get_viewport().set_input_as_handled()
			_new_run()
		return
	if sim.state.phase != RunState.Phase.RUNNING:
		return
	if event.is_action_pressed(&"dash", false):
		get_viewport().set_input_as_handled()
		latch.press_dash()
		return
	if OS.is_debug_build() and key != null and key.pressed and not key.echo:
		if _debug_key(key.physical_keycode):
			get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	match sim.state.phase:
		RunState.Phase.RUNNING:
			sim.set_paused(true)
			latch.clear()
			pause_menu.present("일시정지", "", [[&"resume", "계속 (Esc)"], [&"restart", "재시작"], [&"menu", "메뉴로"]])
		RunState.Phase.PAUSED:
			_resume()
		RunState.Phase.RESULT:
			back_to_menu.emit()


func _resume() -> void:
	sim.set_paused(false)
	runner.reset()
	pause_menu.visible = false


func _on_menu_action(id: StringName) -> void:
	match id:
		&"resume":
			_resume()
		&"restart":
			_new_run()
		&"menu":
			back_to_menu.emit()


func _show_result() -> void:
	_result_shown = true
	var s: RunState = sim.state
	var r: RunResult = s.result
	var t: int = int(r.survived_seconds)
	var lines: PackedStringArray = [
		"생존 시간   %02d:%02d (%.2f초)" % [floori(t / 60.0), t % 60, r.survived_seconds],
		"처치   %d" % r.kills,
		"주공   %s" % s.main_martial.definition.display_name,
		"마지막 피해   %s" % (r.last_damage_source if not r.last_damage_source.is_empty() else "-"),
		"정상 / 기본 초식   %d / %d" % [s.stats.normal_attacks, s.stats.basic_attacks],
		"피격 / 패링   %d / %d" % [s.stats.contact_hits, s.stats.parries],
		"시드   %d" % s.seed,
	]
	if s.debug_used:
		lines.append("DEBUG 조작 사용됨")
	result_screen.present("패배", "\n".join(lines), [[&"restart", "재시작 (R)"], [&"menu", "메뉴로 (Esc)"]])


# ---- 디버그 조작(D-022) ----

func _debug_key(code: Key) -> bool:
	match code:
		KEY_F1:
			renderer.show_debug = not renderer.show_debug
		KEY_F2:
			sim.debug_toggle_auto_spawn()
		KEY_F3:
			sim.debug_spawn_ring(20)
		KEY_F4:
			sim.debug_kill_all()
		KEY_F5:
			sim.debug_set_mp_zero()
		KEY_F6:
			_hp_mult_index = (_hp_mult_index + 1) % HP_MULTS.size()
			sim.debug_set_enemy_hp_mult(HP_MULTS[_hp_mult_index])
		KEY_F7:
			sim.debug_toggle_invincible()
		KEY_F8:
			sim.debug_spawn_formation()
		KEY_F9:
			fixed_seed_enabled = not fixed_seed_enabled
		_:
			return false
	return true


func _debug_text() -> String:
	if not OS.is_debug_build():
		return ""
	if not renderer.show_debug:
		return "[F1] 판정 표시·디버그"
	var s: RunState = sim.state
	var onoff: Callable = func(v: bool) -> String: return "켬" if v else "끔"
	return "\n".join(PackedStringArray([
		"틱 %d · FPS %d · 시뮬 %.3f ms/틱 · 버린 틱 %d" % [s.tick, Engine.get_frames_per_second(), _tick_ms_avg, runner.dropped_ticks],
		"정상/기본 초식 %d / %d · 경공 %d · 피격 %d · 패링 %d" % [s.stats.normal_attacks, s.stats.basic_attacks, s.stats.dashes, s.stats.contact_hits, s.stats.parries],
		"시드 %d · 다음 판 고정 시드 %s" % [s.seed, onoff.call(fixed_seed_enabled)],
		"적 체력 ×%s · 자동 스폰 %s · 무적 %s" % [str(s.enemy_hp_mult), onoff.call(s.auto_spawn), onoff.call(s.debug_invincible)],
		"",
		"[F1] 판정 표시  [F2] 자동 스폰  [F3] 적 20",
		"[F4] 전멸  [F5] 내공 0  [F6] 적 체력 배율",
		"[F7] 무적  [F8] 고정 대형  [F9] 고정 시드",
	]))


# ---- 개발용 자동 실행 ----

func _autoplay_tick() -> void:
	var headless: bool = DisplayServer.get_name() == "headless"
	if not capture_dir.is_empty() and not headless and not _capture_ticks.is_empty() and sim.state.tick >= _capture_ticks[0]:
		var tk: int = _capture_ticks.pop_front()
		_capture("%s/%s_%04d.png" % [capture_dir, martial_id, tk])
	if _capturing:
		return
	var ended: bool = sim.state.phase == RunState.Phase.RESULT
	if ended and not capture_dir.is_empty() and not headless and not _result_captured:
		_result_captured = true
		_capturing = true
		await _capture("%s/%s_result.png" % [capture_dir, martial_id])
		_capturing = false
	if sim.state.sim_time() >= autoplay_seconds or ended:
		if (_capture_ticks.is_empty() or capture_dir.is_empty() or headless or ended) and not _quitting:
			_quitting = true
			print("autoplay 종료: 틱 %d, 처치 %d, 체력 %.1f" % [sim.state.tick, sim.state.stats.kills, sim.state.player.hp])
			get_tree().quit(0)


func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var err: Error = img.save_png(path)
	print("캡처 %s (%s)" % [path, error_string(err)])
