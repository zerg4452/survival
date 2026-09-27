extends TestCase
## M0-08: 혈강시 스폰·추적·분리.


func test_spawn_positions_in_ring_and_inside() -> bool:
	for start: Vector2 in [Vector2(25.5, 25.5), Vector2(1.35, 1.35), Vector2(49.65, 25.5)]:
		var sim: RunSimulation = SimFixture.make(&"cheongun_sword", 7)
		sim.state.player.pos = start
		var bad: int = 0
		var none: int = 0
		for i: int in range(1000):
			var p: Vector2 = Spawner.find_spawn_pos(sim.state, sim.cfg, 0.35)
			if not p.is_finite():
				none += 1
				continue
			var d: float = p.distance_to(start)
			if d < 8.0 - 1e-4 or d > 13.0 + 1e-4 or not Arena.contains_circle(sim.cfg, p, 0.35):
				bad += 1
		check_eq(bad, 0, "%s 기준 스폰 위치 규칙 위반" % start)
		check(none < 1000, "%s 기준 후보를 찾음" % start)
	return true


func test_no_candidate_postpones() -> bool:
	var sim: RunSimulation = SimFixture.make()
	sim.state.auto_spawn = true
	sim.cfg.spawn_min_dist = 100.0
	sim.cfg.spawn_max_dist = 110.0
	SimFixture.run(sim, 300)
	check_eq(sim.state.enemies.size(), 0, "후보가 없으면 스폰하지 않음(대체 위치 없음)")
	check(sim.state.spawn_acc <= sim.cfg.spawn_debt_cap + 1e-9, "부채 상한 유지")
	return true


func test_cap_and_no_burst() -> bool:
	var sim: RunSimulation = SimFixture.make()
	sim.state.auto_spawn = true
	sim.state.debug_invincible = true
	for i: int in range(300):
		sim.spawn_enemy_at(Vector2(2.0 + float(i % 20) * 0.8, 2.0 + floorf(float(i) / 20.0) * 0.8))
	SimFixture.run(sim, 120)
	check_eq(sim.state.enemies.size(), 300, "상한 300에서 추가 스폰 없음")
	sim.state.enemies.resize(50)
	var before: int = sim.state.enemies.size()
	SimFixture.run(sim, 1)
	var spawned: int = sim.state.enemies.size() - before
	check(spawned <= 2, "빈자리가 생겨도 한 틱 2마리 이하(실제 %d)" % spawned)
	return true


func test_telegraph_activation_and_no_contact() -> bool:
	var sim: RunSimulation = SimFixture.make()
	sim.state.auto_spawn = true
	sim.state.enemy_hp_mult = 1000.0
	var spawn_tick: int = -1
	while sim.state.enemies.is_empty():
		SimFixture.run(sim, 1)
	spawn_tick = sim.state.tick - 1
	var e: EnemyState = sim.state.enemies[0]
	check(not e.is_targetable(), "스폰 직후 예고 중")
	e.pos = sim.state.player.pos
	var hp0: float = sim.state.player.hp
	var pos0: Vector2 = e.pos
	while not e.active:
		SimFixture.run(sim, 1)
		if not e.active:
			check_eq(e.pos, pos0, "예고 중 이동 없음")
	check_eq(sim.state.tick - 1 - spawn_tick, 48, "0.8초(48틱) 뒤 활성")
	check_eq(sim.state.player.hp, hp0 - 8.0, "활성된 틱부터 접촉 피해(예고 중에는 없음)")
	return true


func test_same_seed_same_spawns() -> bool:
	var a: RunSimulation = SimFixture.make(&"cheongun_sword", 99)
	var b: RunSimulation = SimFixture.make(&"cheongun_sword", 99)
	for sim: RunSimulation in [a, b]:
		sim.state.auto_spawn = true
		sim.state.player.max_hp = 1e6
		sim.state.player.hp = 1e6
		SimFixture.run(sim, 600, Vector2(0.3, -0.2))
	check_eq(SimFixture.snapshot(a), SimFixture.snapshot(b), "같은 시드·입력이면 같은 결과")
	check(a.state.stats.kills > 0, "적이 실제로 생성·처치됨")
	return true


func test_enemies_stay_outside_player_and_inside_arena() -> bool:
	var sim: RunSimulation = SimFixture.make(&"pajin_spear", 3)
	sim.state.debug_invincible = true
	sim.state.enemy_hp_mult = 1000.0
	for i: int in range(40):
		var a: float = TAU * float(i) / 40.0
		sim.spawn_enemy_at(Vector2(25.5, 25.5) + Vector2(cos(a), sin(a)) * 5.0)
	SimFixture.run(sim, 300)
	var min_d: float = 0.35 + 0.35
	var inside: int = 0
	var outside_arena: int = 0
	for e: EnemyState in sim.state.enemies:
		if e.pos.distance_to(sim.state.player.pos) < min_d - 1e-4:
			inside += 1
		if not Arena.contains_circle(sim.cfg, e.pos, 0.35 - 1e-4):
			outside_arena += 1
	check_eq(inside, 0, "플레이어 몸체 안으로 들어온 적 없음")
	check_eq(outside_arena, 0, "전장 밖 적 없음")
	return true


func test_separation_reduces_overlap() -> bool:
	var sim: RunSimulation = SimFixture.make(&"pajin_spear", 3)
	sim.state.debug_invincible = true
	sim.state.enemy_hp_mult = 1000.0
	for i: int in range(30):
		sim.spawn_enemy_at(Vector2(35.0, 35.0))
	SimFixture.run(sim, 120)
	var worst: float = INF
	var list: Array[EnemyState] = sim.state.enemies
	for i: int in range(list.size()):
		for j: int in range(i + 1, list.size()):
			worst = minf(worst, list[i].pos.distance_to(list[j].pos))
	check(worst > 0.35, "같은 점에 겹친 적이 분리됨(최소 간격 %.3f)" % worst)
	return true


func test_perf_300_enemies_report() -> bool:
	var sim: RunSimulation = SimFixture.make(&"swaeam_blade", 5)
	sim.state.debug_invincible = true
	sim.state.enemy_hp_mult = 1e6
	for i: int in range(300):
		var a: float = TAU * float(i) / 300.0
		sim.spawn_enemy_at(Vector2(25.5, 25.5) + Vector2(cos(a), sin(a)) * (3.0 + float(i % 7)))
	var t0: int = Time.get_ticks_usec()
	SimFixture.run(sim, 120)
	var per_tick_ms: float = float(Time.get_ticks_usec() - t0) / 1000.0 / 120.0
	print("      [참고] 적 300 밀집, 헤드리스 시뮬레이션 평균 %.3f ms/틱" % per_tick_ms)
	check_eq(sim.state.enemies.size(), 300, "적 수 유지")
	return true
