extends TestCase
## M0-09: 접촉 피해, 사망, 결과, 재시작.


func _hit_ticks(sim: RunSimulation, ticks: int) -> Array[int]:
	var out: Array[int] = []
	var hits: int = sim.state.stats.contact_hits
	for i: int in range(ticks):
		var t: int = sim.state.tick
		SimFixture.run(sim, 1)
		if sim.state.stats.contact_hits != hits:
			hits = sim.state.stats.contact_hits
			out.append(t)
	return out


func test_single_enemy_contact_every_second() -> bool:
	var sim: RunSimulation = SimFixture.make()
	sim.state.player.hp = 1e6
	SimFixture.spawn_still(sim, Vector2(26.2, 25.5))
	var ticks: Array[int] = _hit_ticks(sim, 181)
	check_eq(str(ticks), "[0, 60, 120, 180]", "1초(60틱)마다 1회")
	return true


func test_multiple_enemies_respect_invuln() -> bool:
	var sim: RunSimulation = SimFixture.make()
	sim.state.player.hp = 1e6
	for p: Vector2 in [Vector2(26.2, 25.5), Vector2(24.8, 25.5), Vector2(25.5, 26.2)]:
		SimFixture.spawn_still(sim, p)
	SimFixture.run(sim, 1)
	check_eq(sim.state.stats.contact_hits, 1, "같은 틱에는 1회")
	var ticks: Array[int] = _hit_ticks(sim, 200)
	ticks.push_front(0)
	var min_gap: int = 1000
	for i: int in range(1, ticks.size()):
		min_gap = mini(min_gap, ticks[i] - ticks[i - 1])
	check_eq(ticks[1] - ticks[0], 21, "무적에 막힌 적이 21틱 뒤 재시도")
	check(min_gap >= 21, "피격 간격 21틱 이상(최소 %d)" % min_gap)
	return true


func test_dash_iframe_blocks_without_consuming_cooldown() -> bool:
	var sim: RunSimulation = SimFixture.make()
	sim.state.player.hp = 1e6
	sim.state.player.pos = Vector2(49.65, 25.5)
	var e: EnemyState = SimFixture.spawn_still(sim, Vector2(48.95, 25.5))
	sim.step(InputFrame.make(Vector2.RIGHT, true))
	for i: int in range(7):
		SimFixture.run(sim, 1)
	check_eq(sim.state.stats.contact_hits, 0, "경공 무적 0~7틱 피해 없음")
	check_eq(e.contact_cooldown_remaining, 0.0, "막힌 접촉은 대기시간을 쓰지 않음")
	SimFixture.run(sim, 1)
	check_eq(sim.state.stats.contact_hits, 1, "무적이 끝난 8틱째 피해")
	return true


func test_death_to_result() -> bool:
	var sim: RunSimulation = SimFixture.make()
	sim.state.player.hp = 1.0
	SimFixture.spawn_still(sim, Vector2(26.2, 25.5))
	SimFixture.run(sim, 1)
	check_eq(sim.state.phase, RunState.Phase.RESULT, "사망 틱에 RESULT")
	check(sim.state.result != null, "결과 생성")
	check_eq(sim.state.result.end_tick, 1, "종료 틱")
	check(sim.state.result.last_damage_source.contains("접촉"), "마지막 피해 원인 기록")
	SimFixture.run(sim, 30)
	check_eq(sim.state.tick, 1, "RESULT 뒤 틱 불변")
	return true


func test_restart_creates_fresh_state() -> bool:
	var old: RunSimulation = SimFixture.make()
	old.state.auto_spawn = true
	SimFixture.run(old, 900)
	old.step(InputFrame.make(Vector2.ZERO, true))
	check(old.state.tick > 0 and old.state.stats.normal_attacks > 0, "이전 판 진행")
	var fresh: RunSimulation = RunSimulation.new(old.content, old.state.main_martial.definition.id, 2)
	var s: RunState = fresh.state
	check(s != old.state, "새 RunState")
	check_eq(s.player.hp, 100.0, "체력")
	check_eq(s.player.mp, 100.0, "내공")
	check_eq(s.enemies.size(), 0, "적 0")
	check_eq(s.attacks.size(), 0, "공격 인스턴스 0")
	check_eq(s.main_martial.cooldown_remaining, 0.0, "주공 대기시간 0")
	check_eq(s.player.dash_charges, 1, "경공 충전 1")
	check_eq(s.player.dash_recharge_remaining, 0.0, "경공 재충전 0")
	check_eq(s.tick, 0, "틱 0")
	check_eq(s.stats.kills + s.stats.normal_attacks + s.stats.dashes, 0, "통계 0")
	check_eq(s.player.pos, Vector2(25.5, 25.5), "시작 위치")
	return true
