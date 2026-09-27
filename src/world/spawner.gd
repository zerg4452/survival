class_name Spawner
extends RefCounted
## M0 연무장 스폰(D-017, GAME_DESIGN 13.3). 난수는 RunState.rng 만 쓴다.


## 틱 처리 11단계.
static func step(state: RunState, cfg: CombatConfig, def: EnemyDefinition, dt: float) -> void:
	if not state.auto_spawn:
		return
	state.spawn_acc = minf(state.spawn_acc + cfg.spawn_rate * dt, cfg.spawn_debt_cap)
	while state.spawn_acc >= 1.0:
		if state.enemies.size() >= cfg.spawn_normal_cap:
			break
		var pos: Vector2 = find_spawn_pos(state, cfg, def.body_radius)
		if not pos.is_finite():
			break
		spawn_enemy(state, def, pos, cfg.spawn_telegraph)
		state.spawn_acc -= 1.0


## 플레이어로부터 min~max 거리 고리에서 내부 영역 안의 후보를 찾는다. 없으면 (INF, INF).
static func find_spawn_pos(state: RunState, cfg: CombatConfig, radius: float) -> Vector2:
	var center: Vector2 = state.player.pos
	for i: int in range(cfg.spawn_tries):
		var angle: float = state.rng.randf() * TAU
		var dist: float = lerpf(cfg.spawn_min_dist, cfg.spawn_max_dist, state.rng.randf())
		var pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * dist
		if Arena.contains_circle(cfg, pos, radius):
			return pos
	return Vector2(INF, INF)


## 적 하나를 만든다. telegraph <= 0 이면 즉시 활성.
static func spawn_enemy(state: RunState, def: EnemyDefinition, pos: Vector2, telegraph: float) -> EnemyState:
	var e: EnemyState = EnemyState.new()
	e.id = state.alloc_id()
	e.definition = def
	e.pos = pos
	e.max_hp = def.max_hp * state.enemy_hp_mult
	e.hp = e.max_hp
	e.telegraph_remaining = maxf(0.0, telegraph)
	e.active = e.telegraph_remaining <= SimConstants.EPS
	state.enemies.append(e)
	return e
