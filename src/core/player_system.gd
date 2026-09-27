class_name PlayerSystem
extends RefCounted
## 플레이어 생성·입력·내공 회복·이동·기본 경공(GAME_DESIGN 5.1, 7.1, 7.2, D-016).


static func create_player(cfg: CombatConfig, main_def: MartialDefinition) -> PlayerState:
	var p: PlayerState = PlayerState.new()
	p.pos = cfg.arena_start
	p.max_hp = cfg.player_max_hp
	p.hp = cfg.player_max_hp
	p.max_mp = cfg.player_max_mp
	p.mp = cfg.player_max_mp
	p.mp_regen = cfg.player_mp_regen
	p.move_speed = cfg.player_move_speed
	p.body_radius = cfg.player_body_radius
	# 권법 방어 +10 은 주공 정의에서 한 번만 더한다(GAME_DESIGN 6장, D-013).
	p.defense = cfg.player_base_defense + main_def.passive_defense
	p.dash_max_charges = cfg.dash_charges
	p.dash_charges = cfg.dash_charges
	return p


## 틱 처리 1단계: 플레이어 타이머.
static func tick_timers(p: PlayerState, cfg: CombatConfig, dt: float) -> void:
	p.hit_invuln_remaining = maxf(0.0, p.hit_invuln_remaining - dt)
	p.dash_iframe_remaining = maxf(0.0, p.dash_iframe_remaining - dt)
	if p.dash_charges < p.dash_max_charges:
		p.dash_recharge_remaining = maxf(0.0, p.dash_recharge_remaining - dt)
		if p.dash_recharge_remaining <= SimConstants.EPS:
			p.dash_charges += 1
			p.dash_recharge_remaining = cfg.dash_recharge if p.dash_charges < p.dash_max_charges else 0.0


## 틱 처리 2단계: 입력 적용. 경공 요청은 이 틱에만 유효하며 버퍼링하지 않는다.
static func apply_input(state: RunState, cfg: CombatConfig, input: InputFrame) -> void:
	var p: PlayerState = state.player
	var mv: Vector2 = input.move
	if mv.length_squared() > 1.0:
		mv = mv.normalized()
	p.move_input = mv
	var has_move: bool = mv.length_squared() > SimConstants.EPS
	if has_move:
		p.last_move_dir = mv.normalized()

	if input.dash_pressed and p.dash_charges > 0 and not p.is_dashing():
		var dir: Vector2 = Vector2.RIGHT
		if has_move:
			dir = mv.normalized()
		elif p.last_move_dir != Vector2.ZERO:
			dir = p.last_move_dir
		p.dash_dir = dir
		p.dash_remaining = cfg.dash_duration
		p.dash_iframe_remaining = cfg.dash_iframe
		if p.dash_charges == p.dash_max_charges:
			p.dash_recharge_remaining = cfg.dash_recharge
		p.dash_charges -= 1
		state.stats.dashes += 1


## 틱 처리 3단계: 내공 회복.
static func regen_mp(p: PlayerState, dt: float) -> void:
	p.mp = minf(p.max_mp, p.mp + p.mp_regen * dt)


## 틱 처리 4단계: 이동. 경공 중에는 이동 입력을 무시한다.
static func move(p: PlayerState, cfg: CombatConfig, dt: float) -> void:
	if p.is_dashing():
		var step: float = minf(dt, p.dash_remaining)
		var speed: float = cfg.dash_distance / cfg.dash_duration
		p.pos += p.dash_dir * (speed * step)
		p.dash_remaining -= step
		if p.dash_remaining <= SimConstants.EPS:
			p.dash_remaining = 0.0
	else:
		p.pos += p.move_input * (p.move_speed * dt)
	p.pos = Arena.clamp_circle(cfg, p.pos, p.body_radius)
