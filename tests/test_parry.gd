extends TestCase
## D-025: 연환권법 패링. 주공 공격 전후 0.1초(6틱) 안의 접촉 피격은 무효가 되고 공격자에게 권법 피해 1회.
## 권법 간격 0.3초(18틱)에서 공격이 0틱에 나가면 0~6틱은 공격 후 창, 12~17틱은 다음 공격(18틱) 전 창이다.

const FAR: Vector2 = Vector2(26.8, 25.5)
const ADJ: Vector2 = Vector2(24.8, 25.5)


## 멀리 있는 허수아비를 0틱부터 치게 한 뒤, k틱에 인접한 적을 붙여 그 틱의 접촉을 본다.
func _contact_at(k: int, adj_hp: float = 1e9) -> Array:
	var sim: RunSimulation = SimFixture.make(&"yeonhwan_fist")
	SimFixture.spawn_still(sim, FAR)
	SimFixture.run(sim, k)
	var e: EnemyState = SimFixture.spawn_still(sim, ADJ, adj_hp)
	SimFixture.run(sim, 1)
	return [sim, e]


func test_parry_window_boundaries() -> bool:
	var fist_hit: float = 100.0 - 8.0 * 100.0 / 110.0
	for row: Array in [[0, true], [6, true], [7, false], [11, false], [12, true]]:
		var r: Array = _contact_at(row[0])
		var sim: RunSimulation = r[0]
		var parried: bool = row[1]
		check_eq(sim.state.main_martial.last_fire_tick if row[0] < 18 else -1, 0, "틱 %d: 첫 공격은 0틱" % row[0])
		check_eq(sim.state.stats.parries, 1 if parried else 0, "틱 %d 패링 여부" % row[0])
		check_eq(sim.state.stats.contact_hits, 0 if parried else 1, "틱 %d 피격 여부" % row[0])
		check_near(sim.state.player.hp, 100.0 if parried else fist_hit, 1e-9, "틱 %d 체력" % row[0])
	return true


func test_parry_counter_damage_once() -> bool:
	var r: Array = _contact_at(12, 1000.0)
	var e: EnemyState = r[1]
	check_near(e.hp, 1000.0 - 15.0, 1e-9, "반격은 권법 피해 1회(15)")
	return true


func test_parry_consumes_enemy_contact_cooldown() -> bool:
	var r: Array = _contact_at(12)
	var sim: RunSimulation = r[0]
	var e: EnemyState = r[1]
	check_near(e.contact_cooldown_remaining, 1.0, 1e-9, "패링한 적은 접촉 대기시간 1초를 소모")
	check_eq(sim.state.player.hit_invuln_remaining, 0.0, "피해가 없으므로 피격 무적 없음")
	SimFixture.run(sim, 59)
	check_eq(sim.state.stats.parries, 1, "같은 적이 매 틱 반격받지 않음")
	check_eq(sim.state.stats.contact_hits, 0, "대기시간 동안 피격 없음")
	return true


func test_parry_counter_kill_counted_once() -> bool:
	var r: Array = _contact_at(12, 15.0)
	var sim: RunSimulation = r[0]
	var e: EnemyState = r[1]
	check(not e.alive, "반격으로 처치")
	check_eq(sim.state.stats.kills, 1, "처치 1")
	check_eq(sim.state.deaths_this_tick.size(), 1, "사망 이벤트 1회")
	check_near(sim.state.stats.damage_dealt - 15.0 * float(sim.state.stats.normal_attacks + sim.state.stats.basic_attacks), 15.0, 1e-9, "반격 피해 집계는 남은 체력까지")
	return true


func test_no_parry_while_invulnerable() -> bool:
	var sim: RunSimulation = SimFixture.make(&"yeonhwan_fist")
	sim.state.player.pos = Vector2(49.65, 25.5)
	SimFixture.spawn_still(sim, Vector2(48.95, 25.5))
	sim.step(InputFrame.make(Vector2.RIGHT, true))
	SimFixture.run(sim, 7)
	check_eq(sim.state.stats.parries, 0, "경공 무적 중에는 접촉 자체가 없어 패링도 없음")
	check_eq(sim.state.stats.contact_hits, 0, "피격 없음")
	return true


func test_sword_has_no_parry() -> bool:
	var sim: RunSimulation = SimFixture.make(&"cheongun_sword")
	check(not sim.state.main_martial.definition.has_parry(), "검은 패링 없음")
	SimFixture.spawn_still(sim, Vector2(26.2, 25.5))
	SimFixture.run(sim, 1)
	check_eq(sim.state.stats.parries, 0, "공격 틱 접촉도 패링 아님")
	check_eq(sim.state.stats.contact_hits, 1, "그대로 피격")
	return true


func test_loader_parry_validation() -> bool:
	var c: GameContent = SimFixture.content()
	var fist: MartialDefinition = c.martial(&"yeonhwan_fist")
	check_eq(fist.parry_window, 0.1, "권법 패링 창 0.1초")
	check_eq(fist.parry_counter_ratio, 1.0, "반격 배율 1.0")
	var errors: Array[String] = []
	var d: Dictionary = {
		"id": "x", "family": "FIST", "slot": "MAIN", "display_name": "x",
		"damage": 1, "interval": 1, "mp_cost": 1, "max_targets": 1,
		"active_time": 0, "passive_defense": 0,
		"parry": {"window": 0, "counter_damage_ratio": 1},
		"shape": {"kind": "SECTOR", "radius": 1, "angle_deg_total": 90},
	}
	check(ContentLoader.parse_martial(d, "t", errors) == null, "패링 창 0 거부")
	check(errors.size() == 1 and errors[0].contains("parry"), "패링 오류: %s" % str(errors))
	return true
