extends TestCase
## M0-05: 기본 경공. T06.


func _dash(sim: RunSimulation, move: Vector2 = Vector2.ZERO) -> void:
	sim.step(InputFrame.make(move, true))


func test_t06_dash_works_with_zero_mp() -> bool:
	var sim: RunSimulation = SimFixture.make()
	sim.state.player.mp = 0.0
	sim.state.player.mp_regen = 0.0
	_dash(sim)
	check(sim.state.player.is_dashing(), "내공 0에서도 경공 발동")
	check_eq(sim.state.stats.dashes, 1, "경공 횟수")
	check_eq(sim.state.player.mp, 0.0, "경공이 내공을 쓰지 않음")
	return true


func test_t06_distance_and_duration() -> bool:
	var sim: RunSimulation = SimFixture.make()
	_dash(sim)
	SimFixture.run(sim, 9)
	check(sim.state.player.is_dashing(), "10틱째 아직 경공 중")
	SimFixture.run(sim, 1)
	check(not sim.state.player.is_dashing(), "11틱째 경공 종료")
	check_near(sim.state.player.pos.x, 28.0, 1e-4, "이동 거리 2.5칸")
	check_near(sim.state.player.pos.y, 25.5, 1e-6, "기본 방향 +X")
	return true


func test_t06_iframe_duration() -> bool:
	var sim: RunSimulation = SimFixture.make()
	_dash(sim)
	for k: int in range(1, 10):
		var invuln: bool = sim.state.player.is_invulnerable()
		var elapsed: float = float(k - 1) / 60.0
		if elapsed < 0.12:
			check(invuln, "틱 %d(경과 %.4f초) 무적" % [k - 1, elapsed])
		else:
			check(not invuln, "틱 %d(경과 %.4f초) 무적 아님" % [k - 1, elapsed])
		sim.step(InputFrame.make(Vector2.ZERO))
	return true


func test_t06_recharge_no_buffer() -> bool:
	var sim: RunSimulation = SimFixture.make()
	_dash(sim)
	SimFixture.run(sim, 99)
	_dash(sim)
	check_eq(sim.state.stats.dashes, 1, "재충전 중 입력 무시")
	SimFixture.run(sim, 200)
	check_eq(sim.state.stats.dashes, 1, "버퍼링되지 않음")
	_dash(sim)
	check_eq(sim.state.stats.dashes, 2, "재충전 후 발동")
	return true


func test_t06_recharge_exact_4s() -> bool:
	var sim: RunSimulation = SimFixture.make()
	_dash(sim)
	SimFixture.run(sim, 238)
	_dash(sim)
	check_eq(sim.state.stats.dashes, 1, "239틱(3.98초)에는 불가")
	_dash(sim)
	check_eq(sim.state.stats.dashes, 2, "240틱(4.00초)에 가능")
	return true


func test_t06_wall_not_crossed() -> bool:
	var sim: RunSimulation = SimFixture.make()
	sim.state.player.pos = Vector2(49.15, 25.5)
	_dash(sim, Vector2.RIGHT)
	for i: int in range(12):
		check(sim.state.player.pos.x <= 49.65 + 1e-5, "틱 %d 경계 안" % i)
		sim.step(InputFrame.make(Vector2.ZERO))
	check_near(sim.state.player.pos.x, 49.65, 1e-5, "벽에서 멈춤")
	return true


func test_t06_diagonal_slides_along_wall() -> bool:
	var sim: RunSimulation = SimFixture.make()
	sim.state.player.pos = Vector2(49.15, 25.5)
	_dash(sim, Vector2(1.0, 1.0))
	SimFixture.run(sim, 12)
	check_near(sim.state.player.pos.x, 49.65, 1e-5, "x 는 벽")
	check_near(sim.state.player.pos.y, 25.5 + 2.5 * sqrt(0.5), 1e-4, "y 는 계속 이동")
	return true


func test_dash_direction_uses_last_move() -> bool:
	var sim: RunSimulation = SimFixture.make()
	SimFixture.run(sim, 1, Vector2.UP)
	var y0: float = sim.state.player.pos.y
	_dash(sim, Vector2.ZERO)
	SimFixture.run(sim, 11)
	check_near(sim.state.player.pos.y, y0 - 2.5, 1e-4, "입력이 없으면 마지막 이동 방향")
	return true


func test_move_input_ignored_while_dashing() -> bool:
	var sim: RunSimulation = SimFixture.make()
	_dash(sim, Vector2.RIGHT)
	SimFixture.run(sim, 10, Vector2.DOWN)
	check_near(sim.state.player.pos.y, 25.5, 1e-6, "경공 중 이동 입력 무시")
	check_near(sim.state.player.pos.x, 28.0, 1e-4, "경공 거리 유지")
	return true


## M0 리뷰 R01: 경공 중에는 적 몸체를 통과한다(GAME_DESIGN 7.2). 정면·측면 모두 적을 밀지 않는다.
func test_dash_passes_through_enemy() -> bool:
	for lateral: float in [0.0, 0.1, 0.3]:
		var sim: RunSimulation = SimFixture.make(&"pajin_spear")
		var e: EnemyState = SimFixture.spawn_still(sim, Vector2(26.8, 25.5 + lateral))
		var start: Vector2 = e.pos
		_dash(sim, Vector2.RIGHT)
		SimFixture.run(sim, 12)
		check(sim.state.player.pos.x > e.pos.x + 0.7, "측면 %.1f: 플레이어가 적을 지나감" % lateral)
		check(e.pos.distance_to(start) < 1e-5, "측면 %.1f: 적이 밀리지 않음(이동 %.3f)" % [lateral, e.pos.distance_to(start)])
	return true


## 경공이 끝난 순간 겹쳐 있으면 그때 밀어낸다(D-014). 보행 중 밀어내기는 유지된다.
func test_overlap_after_dash_and_walking_push_unchanged() -> bool:
	var sim: RunSimulation = SimFixture.make(&"pajin_spear")
	var e: EnemyState = SimFixture.spawn_still(sim, Vector2(28.0, 25.5))
	_dash(sim, Vector2.RIGHT)
	SimFixture.run(sim, 10)
	check(not sim.state.player.is_dashing(), "경공 종료")
	check(e.pos.distance_to(sim.state.player.pos) >= 0.7 - 1e-4, "종료 후 겹침 해소")
	var sim2: RunSimulation = SimFixture.make(&"pajin_spear")
	var e2: EnemyState = SimFixture.spawn_still(sim2, Vector2(26.3, 25.5))
	SimFixture.run(sim2, 30, Vector2.RIGHT)
	check(e2.pos.x > 26.3 + 0.5, "보행 중에는 정면 적을 밀어냄(D-014)")
	return true
