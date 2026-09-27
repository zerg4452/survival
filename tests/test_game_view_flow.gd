extends TestCase
## M0 리뷰 R04: 게임 화면의 입력 흐름(경공·일시정지·복귀·사망·결과·재시작·메뉴).
## 실제 키 이벤트를 뷰포트에 넣고, 프레임은 GameView._process 를 직접 호출해 진행한다.
## 버튼 포커스는 지연 호출이라 이 테스트에서는 잡히지 않는다. 그래서 일시정지 중 Space 는 "경공이 나가지 않음"만 확인한다.

const DT: float = 1.0 / 60.0


func _key(code: Key, pressed: bool) -> InputEventKey:
	var e: InputEventKey = InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	return e


func _tap(vp: Viewport, code: Key) -> void:
	vp.push_input(_key(code, true))
	vp.push_input(_key(code, false))


func _frames(g: GameView, n: int) -> void:
	for i: int in range(n):
		g._process(DT)


func _kill_player(g: GameView) -> void:
	g.sim.state.player.hp = 0.5
	g.sim.state.enemy_hp_mult = 1000.0
	g.sim.spawn_enemy_at(g.sim.state.player.pos + Vector2(0.7, 0.0))
	_frames(g, 2)


func test_pause_dash_result_flow() -> bool:
	InputSetup.ensure_actions()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var vp: Viewport = tree.root
	var g: GameView = GameView.new()
	g.setup(ContentLoader.load_from_dir(), &"cheongun_sword", UiTheme.build())
	tree.root.add_child(g)
	var went_menu: Array[bool] = [false]
	g.back_to_menu.connect(func() -> void: went_menu[0] = true)
	g.sim.state.auto_spawn = false

	_tap(vp, KEY_SPACE)
	_frames(g, 20)
	check_eq(g.sim.state.stats.dashes, 1, "Space → 경공")

	_tap(vp, KEY_ESCAPE)
	check_eq(g.sim.state.phase, RunState.Phase.PAUSED, "Esc → 일시정지")
	check(g.pause_menu.visible, "일시정지 메뉴 표시")
	var t: int = g.sim.state.tick
	_frames(g, 30)
	check_eq(g.sim.state.tick, t, "일시정지 중 틱 고정")
	_tap(vp, KEY_SPACE)
	_frames(g, 3)
	check_eq(g.sim.state.stats.dashes, 1, "일시정지 중 Space 로 경공이 나가지 않음")

	if g.sim.state.phase == RunState.Phase.PAUSED:
		_tap(vp, KEY_ESCAPE)
	check_eq(g.sim.state.phase, RunState.Phase.RUNNING, "Esc → 복귀")
	check(not g.pause_menu.visible, "일시정지 메뉴 숨김")
	_frames(g, 20)
	g.sim.state.player.dash_charges = 1
	g.sim.state.player.dash_recharge_remaining = 0.0
	_tap(vp, KEY_SPACE)
	_frames(g, 2)
	check_eq(g.sim.state.stats.dashes, 2, "복귀 후 Space → 경공")
	_frames(g, 20)

	_kill_player(g)
	check_eq(g.sim.state.phase, RunState.Phase.RESULT, "사망 → RESULT")
	check(g.result_screen.visible, "결과 화면 표시")
	var old_sim: RunSimulation = g.sim
	_tap(vp, KEY_R)
	check(g.sim != old_sim, "R → 새 판")
	check_eq(g.sim.state.phase, RunState.Phase.RUNNING, "새 판 진행 중")
	check_eq(g.sim.state.player.hp, 100.0, "새 판 체력")
	check(not g.result_screen.visible, "결과 화면 숨김")

	g.sim.state.auto_spawn = false
	_kill_player(g)
	_tap(vp, KEY_ESCAPE)
	check(went_menu[0], "결과 화면에서 Esc → 메뉴 신호")

	tree.root.remove_child(g)
	g.free()
	return true
