class_name RunSimulation
extends RefCounted
## 한 판의 시뮬레이션. step() 이 D-018 의 틱 처리 순서를 그대로 따른다.
## Node·Input·전역 난수를 참조하지 않는다(ARCHITECTURE 2장).

var content: GameContent = null
var cfg: CombatConfig = null
var state: RunState = null
var enemy_system: EnemySystem = EnemySystem.new()
var _spawn_def: EnemyDefinition = null


func _init(p_content: GameContent, martial_id: StringName, p_seed: int) -> void:
	content = p_content
	cfg = content.config
	_spawn_def = content.enemy(cfg.spawn_enemy_id)
	var def: MartialDefinition = content.martial(martial_id)
	assert(def != null, "알 수 없는 주공: %s" % martial_id)
	state = RunState.new()
	state.seed = p_seed
	state.rng.seed = p_seed
	state.main_martial = MartialRuntime.new(def)
	state.player = PlayerSystem.create_player(cfg, def)


func step(input: InputFrame) -> void:
	if state.phase != RunState.Phase.RUNNING:
		return
	var dt: float = SimConstants.FIXED_DT
	state.deaths_this_tick.clear()
	_tick_timers(dt)                                       # 1
	PlayerSystem.apply_input(state, cfg, input)            # 2
	PlayerSystem.regen_mp(state.player, dt)                # 3
	PlayerSystem.move(state.player, cfg, dt)               # 4
	enemy_system.move_enemies(state, cfg, dt)              # 5
	MainAttackSystem.try_fire(state, cfg)                  # 6
	MainAttackSystem.resolve(state)                        # 7
	_cleanup()                                             # 8
	EnemySystem.contact_damage(state, cfg)                 # 9
	_check_death()                                         # 10
	if state.phase == RunState.Phase.RUNNING:
		Spawner.step(state, cfg, _spawn_def, dt)           # 11
	state.tick += 1                                        # 12


func _tick_timers(dt: float) -> void:
	PlayerSystem.tick_timers(state.player, cfg, dt)
	var rt: MartialRuntime = state.main_martial
	rt.cooldown_remaining = maxf(0.0, rt.cooldown_remaining - dt)
	for inst: AttackInstance in state.attacks:
		inst.remaining_active = maxf(0.0, inst.remaining_active - dt)
	for e: EnemyState in state.enemies:
		e.contact_cooldown_remaining = maxf(0.0, e.contact_cooldown_remaining - dt)
		if not e.active:
			e.telegraph_remaining = maxf(0.0, e.telegraph_remaining - dt)
			if e.telegraph_remaining <= SimConstants.EPS:
				e.active = true


func _cleanup() -> void:
	var keep_attacks: Array[AttackInstance] = []
	for inst: AttackInstance in state.attacks:
		if inst.remaining_active > SimConstants.EPS:
			keep_attacks.append(inst)
	state.attacks = keep_attacks
	var keep_enemies: Array[EnemyState] = []
	for e: EnemyState in state.enemies:
		if e.alive:
			keep_enemies.append(e)
	state.enemies = keep_enemies


func _check_death() -> void:
	if state.player.hp > SimConstants.EPS:
		return
	state.phase = RunState.Phase.RESULT
	var r: RunResult = RunResult.new()
	r.reason = RunResult.Reason.DEATH
	r.end_tick = state.tick + 1
	r.survived_seconds = float(state.tick + 1) * SimConstants.FIXED_DT
	r.kills = state.stats.kills
	r.last_damage_source = state.last_damage_source
	state.result = r


# ---- 일시정지(D-019). 틱 사이에 표시 계층이 호출한다. ----

func set_paused(paused: bool) -> void:
	if state.phase == RunState.Phase.RESULT:
		return
	state.phase = RunState.Phase.PAUSED if paused else RunState.Phase.RUNNING


# ---- 테스트·디버그용 배치 ----

## 적 하나를 지정 위치에 만든다. telegraph <= 0 이면 즉시 활성.
func spawn_enemy_at(pos: Vector2, telegraph: float = 0.0) -> EnemyState:
	return Spawner.spawn_enemy(state, _spawn_def, pos, telegraph)


# ---- 디버그 조작(D-022). 사용하면 debug_used 가 켜진다. ----

func debug_toggle_auto_spawn() -> void:
	state.debug_used = true
	state.auto_spawn = not state.auto_spawn
	state.spawn_acc = 0.0


func debug_spawn_ring(count: int) -> void:
	state.debug_used = true
	for i: int in range(count):
		var pos: Vector2 = Spawner.find_spawn_pos(state, cfg, _spawn_def.body_radius)
		if pos.is_finite():
			spawn_enemy_at(pos, cfg.spawn_telegraph)


func debug_kill_all() -> void:
	state.debug_used = true
	state.enemies.clear()


func debug_set_mp_zero() -> void:
	state.debug_used = true
	state.player.mp = 0.0


func debug_set_enemy_hp_mult(mult: float) -> void:
	state.debug_used = true
	state.enemy_hp_mult = mult


func debug_toggle_invincible() -> void:
	state.debug_used = true
	state.debug_invincible = not state.debug_invincible


## 고정 대형: 플레이어 기준 +X 방향 일렬 6마리(1.5~4.0칸, 0.5 간격)와 반경 2.2칸 원형 8마리. 즉시 활성.
func debug_spawn_formation() -> void:
	state.debug_used = true
	var c: Vector2 = state.player.pos
	for i: int in range(6):
		spawn_enemy_at(Arena.clamp_circle(cfg, c + Vector2(1.5 + 0.5 * float(i), 0.0), _spawn_def.body_radius))
	for i: int in range(8):
		var a: float = TAU * float(i) / 8.0 + PI / 8.0
		spawn_enemy_at(Arena.clamp_circle(cfg, c + Vector2(cos(a), sin(a)) * 2.2, _spawn_def.body_radius))
