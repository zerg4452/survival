class_name SimFixture
extends RefCounted
## 테스트용 시뮬레이션 생성 도우미. 테스트끼리 설정을 공유하지 않도록 매번 콘텐츠를 새로 읽는다.


static func content() -> GameContent:
	var c: GameContent = ContentLoader.load_from_dir()
	assert(c.is_ok(), str(c.errors))
	return c


## 자동 스폰을 끈 시뮬레이션.
static func make(martial_id: StringName = &"cheongun_sword", p_seed: int = 1) -> RunSimulation:
	var sim: RunSimulation = RunSimulation.new(content(), martial_id, p_seed)
	sim.state.auto_spawn = false
	return sim


static func run(sim: RunSimulation, ticks: int, move: Vector2 = Vector2.ZERO) -> void:
	for i: int in range(ticks):
		sim.step(InputFrame.make(move))


## 움직이지 않고 체력이 큰 적(테스트 전용 정의).
static func spawn_still(sim: RunSimulation, pos: Vector2, hp: float = 1e9) -> EnemyState:
	var e: EnemyState = sim.spawn_enemy_at(pos)
	var still: EnemyDefinition = EnemyDefinition.new()
	still.id = &"test_still"
	still.display_name = "테스트 허수아비"
	still.max_hp = hp
	still.move_speed = 0.0
	still.contact_damage = e.definition.contact_damage
	still.contact_interval = e.definition.contact_interval
	still.body_radius = e.definition.body_radius
	e.definition = still
	e.max_hp = hp
	e.hp = hp
	return e


## 주공 정의 복사본(테스트에서 값 하나만 바꿀 때).
static func clone_martial(src: MartialDefinition) -> MartialDefinition:
	var m: MartialDefinition = MartialDefinition.new()
	m.id = src.id
	m.family = src.family
	m.slot = src.slot
	m.display_name = src.display_name
	m.damage = src.damage
	m.interval = src.interval
	m.mp_cost = src.mp_cost
	m.max_targets = src.max_targets
	m.active_time = src.active_time
	m.passive_defense = src.passive_defense
	m.shape = src.shape
	return m


## 두 시뮬레이션 상태 비교용 문자열. 부동소수는 정확한 값으로 기록한다.
static func snapshot(sim: RunSimulation) -> String:
	var s: RunState = sim.state
	var p: PlayerState = s.player
	var parts: PackedStringArray = []
	parts.append("tick=%d phase=%d" % [s.tick, s.phase])
	parts.append("p=%s hp=%s mp=%s" % [var_to_str(p.pos), var_to_str(p.hp), var_to_str(p.mp)])
	parts.append("dash=%d/%s/%s/%s" % [p.dash_charges, var_to_str(p.dash_recharge_remaining), var_to_str(p.dash_remaining), var_to_str(p.dash_iframe_remaining)])
	parts.append("inv=%s cd=%s" % [var_to_str(p.hit_invuln_remaining), var_to_str(s.main_martial.cooldown_remaining)])
	parts.append("kills=%d normal=%d basic=%d acc=%s" % [s.stats.kills, s.stats.normal_attacks, s.stats.basic_attacks, var_to_str(s.spawn_acc)])
	parts.append("dashes=%d hits=%d taken=%s dealt=%s" % [s.stats.dashes, s.stats.contact_hits, var_to_str(s.stats.damage_taken), var_to_str(s.stats.damage_dealt)])
	for e: EnemyState in s.enemies:
		parts.append("e%d=%s,%s,%s" % [e.id, var_to_str(e.pos), var_to_str(e.hp), str(e.active)])
	return "\n".join(parts)
