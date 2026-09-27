extends TestCase
## M0-06: 판정 도형과 자동 조준. T03.

const O: Vector2 = Vector2(25.5, 25.5)


func _spear() -> ShapeDef:
	return SimFixture.content().martial(&"pajin_spear").shape


func _hit(shape: ShapeDef, dir: Vector2, local_x: float, local_y: float) -> bool:
	var d: Vector2 = dir.normalized()
	var dx: float = d.x
	var dy: float = d.y
	var p: Vector2 = Vector2(O.x + dx * local_x - dy * local_y, O.y + dy * local_x + dx * local_y)
	return Shapes.contains(shape, O, dx, dy, p)


func test_t03_spear_forward_boundaries_axis() -> bool:
	var s: ShapeDef = _spear()
	for dir: Vector2 in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
		check(not _hit(s, dir, 0.9, 0.0), "%s 0.9 빗나감" % dir)
		check(not _hit(s, dir, 1.0, 0.0), "%s 1.0 빗나감" % dir)
		check(_hit(s, dir, 1.01, 0.0), "%s 1.01 적중" % dir)
		check(_hit(s, dir, 4.5, 0.0), "%s 4.5 적중" % dir)
		check(not _hit(s, dir, 4.51, 0.0), "%s 4.51 빗나감" % dir)
	return true


func test_t03_spear_width() -> bool:
	var s: ShapeDef = _spear()
	check(_hit(s, Vector2.RIGHT, 2.0, 0.4), "폭 +0.4 적중")
	check(_hit(s, Vector2.RIGHT, 2.0, -0.4), "폭 -0.4 적중")
	check(not _hit(s, Vector2.RIGHT, 2.0, 0.41), "폭 +0.41 빗나감")
	check(not _hit(s, Vector2.RIGHT, 2.0, -0.41), "폭 -0.41 빗나감")
	return true


## 대각선에서는 위치가 32비트 Vector2 로 저장되므로 정확히 1.0 인 점을 만들 수 없다.
## 경계 양쪽 값으로 확인한다(D-007).
func test_t03_spear_diagonal() -> bool:
	var s: ShapeDef = _spear()
	for dir: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -2)]:
		check(not _hit(s, dir, 0.9, 0.0), "%s 0.9 빗나감" % dir)
		check(not _hit(s, dir, 0.999, 0.0), "%s 0.999 빗나감" % dir)
		check(_hit(s, dir, 1.01, 0.0), "%s 1.01 적중" % dir)
	return true


func test_sector_boundaries() -> bool:
	var c: GameContent = SimFixture.content()
	var sword: ShapeDef = c.martial(&"cheongun_sword").shape
	check(_hit(sword, Vector2.RIGHT, 2.0, 0.0), "검 2.0 적중")
	check(not _hit(sword, Vector2.RIGHT, 2.01, 0.0), "검 2.01 빗나감")
	check(_hit(sword, Vector2.RIGHT, 0.0, 0.0), "거리 0 적중")
	var cases: Array = [[&"cheongun_sword", 44.0, 46.0], [&"swaeam_blade", 69.0, 71.0], [&"yeonhwan_fist", 39.0, 41.0]]
	for row: Array in cases:
		var shape: ShapeDef = c.martial(row[0]).shape
		for sgn: float in [1.0, -1.0]:
			var a_in: float = deg_to_rad(float(row[1])) * sgn
			var a_out: float = deg_to_rad(float(row[2])) * sgn
			check(_hit(shape, Vector2.RIGHT, cos(a_in), sin(a_in)), "%s %s도 적중" % [row[0], row[1]])
			check(not _hit(shape, Vector2.RIGHT, cos(a_out), sin(a_out)), "%s %s도 빗나감" % [row[0], row[2]])
	return true


func test_primary_nearest_and_tie_by_id() -> bool:
	var sim: RunSimulation = SimFixture.make()
	var sword: ShapeDef = sim.state.main_martial.definition.shape
	var far: EnemyState = sim.spawn_enemy_at(Vector2(27.2, 25.5))
	var near: EnemyState = sim.spawn_enemy_at(Vector2(26.5, 25.5))
	check(Targeting.pick_primary(sim.state.enemies, O, sword) == near, "가장 가까운 적")
	sim.state.enemies.clear()
	var a: EnemyState = sim.spawn_enemy_at(Vector2(27.5, 25.5))
	var b: EnemyState = sim.spawn_enemy_at(Vector2(23.5, 25.5))
	check(a.id < b.id, "ID 순서 전제")
	check(Targeting.pick_primary(sim.state.enemies, O, sword) == a, "같은 거리면 작은 ID")
	check(far != null, "")
	return true


func test_primary_excludes_telegraph_and_dead() -> bool:
	var sim: RunSimulation = SimFixture.make()
	var sword: ShapeDef = sim.state.main_martial.definition.shape
	var tele: EnemyState = sim.spawn_enemy_at(Vector2(26.0, 25.5), 0.8)
	var dead: EnemyState = sim.spawn_enemy_at(Vector2(26.2, 25.5))
	dead.alive = false
	var ok: EnemyState = sim.spawn_enemy_at(Vector2(27.0, 25.5))
	check(not tele.is_targetable(), "예고 중 적은 대상 아님")
	check(Targeting.pick_primary(sim.state.enemies, O, sword) == ok, "예고·사망 적 제외")
	return true


func test_spear_aim_skips_dead_zone() -> bool:
	var sim: RunSimulation = SimFixture.make(&"pajin_spear")
	var shape: ShapeDef = sim.state.main_martial.definition.shape
	sim.spawn_enemy_at(Vector2(26.4, 25.5))
	var far: EnemyState = sim.spawn_enemy_at(Vector2(25.5, 28.5))
	check(Targeting.pick_primary(sim.state.enemies, O, shape) == far, "0.9칸 적 대신 3.0칸 적 조준")
	sim.state.enemies.erase(far)
	check(Targeting.pick_primary(sim.state.enemies, O, shape) == null, "0.9칸 적만 있으면 대상 없음")
	return true


func test_max_targets_nearest_first() -> bool:
	var sim: RunSimulation = SimFixture.make(&"swaeam_blade")
	var def: MartialDefinition = sim.state.main_martial.definition
	var list: Array[EnemyState] = []
	for i: int in range(10):
		list.append(sim.spawn_enemy_at(Vector2(25.5 + 0.2 + 0.2 * float(i), 25.5)))
	list.reverse()
	sim.state.enemies = list
	var inst: AttackInstance = AttackInstance.new()
	inst.origin = O
	inst.shape = def.shape
	inst.max_targets = def.max_targets
	var hits: Array[EnemyState] = Targeting.select_hits(sim.state.enemies, inst)
	check_eq(hits.size(), 5, "도 최대 5")
	for i: int in range(hits.size()):
		check_near(hits[i].pos.x, 25.5 + 0.2 + 0.2 * float(i), 1e-5, "가까운 순 %d" % i)
	return true
