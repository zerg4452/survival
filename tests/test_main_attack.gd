extends TestCase
## M0-07: 주공 발동, 내공, 기본 초식, 공격 인스턴스. T02(동작)·T05·T16.


func _no_regen(sim: RunSimulation, mp: float) -> void:
	sim.state.player.mp_regen = 0.0
	sim.state.player.mp = mp


func test_t05_pay_or_basic_unit() -> bool:
	var r: Dictionary = Damage.pay_or_basic(6.0, 6.0)
	check(r["paid"], "내공 = 비용이면 정상 초식")
	check_eq(r["mp_after"], 0.0, "지불 후 0")
	r = Damage.pay_or_basic(6.0 - 1e-9, 6.0)
	check(r["paid"], "부동소수 오차 범위는 정상 초식")
	check_eq(r["mp_after"], 0.0, "음수가 아니라 0")
	r = Damage.pay_or_basic(5.9, 6.0)
	check(not r["paid"], "부족하면 기본 초식")
	check_eq(r["mp_after"], 5.9, "내공 불변")
	return true


func test_t05_integration_exact_cost() -> bool:
	var sim: RunSimulation = SimFixture.make()
	_no_regen(sim, 6.0)
	SimFixture.spawn_still(sim, Vector2(27.0, 25.5))
	SimFixture.run(sim, 1)
	check_eq(sim.state.stats.normal_attacks, 1, "정상 초식 발동")
	check_eq(sim.state.player.mp, 0.0, "내공 0")
	return true


func test_t05_basic_technique() -> bool:
	var sim: RunSimulation = SimFixture.make()
	_no_regen(sim, 5.9)
	var e: EnemyState = SimFixture.spawn_still(sim, Vector2(27.0, 25.5), 100.0)
	SimFixture.run(sim, 1)
	check_eq(sim.state.stats.basic_attacks, 1, "기본 초식 발동")
	check_eq(sim.state.stats.normal_attacks, 0, "정상 초식 없음")
	check_eq(sim.state.player.mp, 5.9, "내공 불변")
	check_near(e.hp, 100.0 - 24.0 * 0.65, 1e-9, "피해 65%")
	SimFixture.run(sim, 200)
	check(sim.state.player.mp >= 0.0, "내공 음수 아님")
	check(sim.state.stats.basic_attacks > 1, "내공 부족에도 공격 계속")
	return true


func test_t02_fire_counts_600_ticks() -> bool:
	# 간격 틱: 검 39, 도 60, 창 69, 권 18. 기대 = ceil(600 / 간격 틱)
	var cases: Array = [[&"cheongun_sword", 1.5, 16], [&"swaeam_blade", 1.5, 10], [&"pajin_spear", 3.0, 9], [&"yeonhwan_fist", 1.0, 34]]
	for row: Array in cases:
		var sim: RunSimulation = SimFixture.make(row[0])
		SimFixture.spawn_still(sim, Vector2(25.5 + float(row[1]), 25.5))
		SimFixture.run(sim, 1)
		check_eq(sim.state.main_martial.last_fire_tick, 0, "%s 첫 발동 0틱" % row[0])
		SimFixture.run(sim, 599)
		var fired: int = sim.state.stats.normal_attacks + sim.state.stats.basic_attacks
		check_eq(fired, row[2], "%s 600틱 발동 수" % row[0])
	return true


func test_no_target_no_cost() -> bool:
	var sim: RunSimulation = SimFixture.make()
	_no_regen(sim, 50.0)
	SimFixture.run(sim, 100)
	check_eq(sim.state.player.mp, 50.0, "목표 없으면 내공 불변")
	check_eq(sim.state.main_martial.cooldown_remaining, 0.0, "준비 상태로 대기")
	check_eq(sim.state.stats.normal_attacks + sim.state.stats.basic_attacks, 0, "발동 없음")
	SimFixture.spawn_still(sim, Vector2(26.5, 25.5))
	SimFixture.run(sim, 1)
	check_eq(sim.state.main_martial.last_fire_tick, 100, "목표가 생긴 첫 틱에 발동")
	return true


func test_spear_dead_zone_only_no_fire() -> bool:
	var sim: RunSimulation = SimFixture.make(&"pajin_spear")
	_no_regen(sim, 50.0)
	SimFixture.spawn_still(sim, Vector2(26.4, 25.5))
	SimFixture.run(sim, 60)
	check_eq(sim.state.stats.normal_attacks + sim.state.stats.basic_attacks, 0, "사각 안 적만 있으면 발동 없음")
	check_eq(sim.state.player.mp, 50.0, "내공 불변")
	return true


func test_t16_hit_once_per_instance() -> bool:
	var sim: RunSimulation = SimFixture.make()
	var e: EnemyState = SimFixture.spawn_still(sim, Vector2(26.5, 25.5), 1000.0)
	SimFixture.run(sim, 10)
	check_eq(sim.state.stats.normal_attacks, 1, "인스턴스 1개")
	check_near(e.hp, 1000.0 - 24.0, 1e-9, "활성 6틱 동안 1회만 피해")
	return true


func test_t16_entering_enemy_hit_once_and_max_targets() -> bool:
	var sim: RunSimulation = SimFixture.make()
	var primary: EnemyState = SimFixture.spawn_still(sim, Vector2(26.5, 25.5), 1000.0)
	SimFixture.run(sim, 2)
	var late: EnemyState = SimFixture.spawn_still(sim, Vector2(27.0, 25.7), 1000.0)
	SimFixture.run(sim, 8)
	check_near(primary.hp, 976.0, 1e-9, "주 목표 1회")
	check_near(late.hp, 976.0, 1e-9, "활성 시간 중 들어온 적 1회")
	var after: EnemyState = SimFixture.spawn_still(sim, Vector2(27.0, 25.3), 1000.0)
	SimFixture.run(sim, 5)
	check_near(after.hp, 1000.0, 1e-9, "활성 시간이 끝난 뒤 들어온 적은 맞지 않음")

	var sim2: RunSimulation = SimFixture.make()
	var first: Array[EnemyState] = []
	for y: float in [25.5, 25.7, 25.3]:
		first.append(SimFixture.spawn_still(sim2, Vector2(26.5, y), 1000.0))
	SimFixture.run(sim2, 2)
	var fourth: EnemyState = SimFixture.spawn_still(sim2, Vector2(26.8, 25.5), 1000.0)
	SimFixture.run(sim2, 8)
	for f: EnemyState in first:
		check_near(f.hp, 976.0, 1e-9, "처음 3마리 적중")
	check_near(fourth.hp, 1000.0, 1e-9, "최대 대상 3을 활성 시간 전체에서 셈")
	return true


func test_t16_long_active_time_test_definition() -> bool:
	var sim: RunSimulation = SimFixture.make()
	var def: MartialDefinition = SimFixture.clone_martial(sim.state.main_martial.definition)
	def.active_time = 0.5
	sim.state.main_martial.definition = def
	var e: EnemyState = SimFixture.spawn_still(sim, Vector2(26.5, 25.5), 1000.0)
	SimFixture.run(sim, 35)
	check_eq(sim.state.stats.normal_attacks, 1, "인스턴스 1개")
	check_near(e.hp, 976.0, 1e-9, "활성 0.5초 동안 1회만 피해")
	return true


func test_overkill_same_tick_counts_one_kill() -> bool:
	var sim: RunSimulation = SimFixture.make()
	var e: EnemyState = sim.spawn_enemy_at(Vector2(26.5, 25.5))
	for i: int in range(2):
		var inst: AttackInstance = AttackInstance.new()
		inst.instance_id = sim.state.alloc_id()
		inst.created_tick = sim.state.tick
		inst.origin = Vector2(25.5, 25.5)
		inst.shape = sim.state.main_martial.definition.shape
		inst.damage = 100.0
		inst.max_targets = 3
		sim.state.attacks.append(inst)
	MainAttackSystem.resolve(sim.state)
	check_eq(sim.state.stats.kills, 1, "처치 1")
	check_eq(sim.state.deaths_this_tick.size(), 1, "사망 이벤트 1회")
	check(not e.alive, "사망")
	check_near(sim.state.stats.damage_dealt, 20.0, 1e-9, "가한 피해는 남은 체력까지만 집계")
	return true


func test_fist_defense_applies_once() -> bool:
	for row: Array in [[&"yeonhwan_fist", 8.0 * 100.0 / 110.0], [&"cheongun_sword", 8.0]]:
		var sim: RunSimulation = SimFixture.make(row[0])
		SimFixture.spawn_still(sim, Vector2(26.2, 25.5))
		SimFixture.run(sim, 1)
		check_near(sim.state.player.hp, 100.0 - float(row[1]), 1e-9, "%s 접촉 피해" % row[0])
	return true
