extends TestCase
## M0-04: 전장과 플레이어 이동. T01.


func test_t01_start_position() -> bool:
	var sim: RunSimulation = SimFixture.make()
	check_eq(sim.state.player.pos, Vector2(25.5, 25.5), "시작 위치")
	return true


func test_t01_straight_speed() -> bool:
	var sim: RunSimulation = SimFixture.make()
	SimFixture.run(sim, 60, Vector2.RIGHT)
	check_near(sim.state.player.pos.x, 29.5, 1e-4, "1초 오른쪽 이동 4칸")
	check_near(sim.state.player.pos.y, 25.5, 1e-6, "y 불변")
	return true


func test_t01_diagonal_normalized() -> bool:
	var sim: RunSimulation = SimFixture.make()
	SimFixture.run(sim, 60, Vector2(1.0, 1.0))
	var moved: float = sim.state.player.pos.distance_to(Vector2(25.5, 25.5))
	check_near(moved, 4.0, 1e-4, "대각선 1초 이동 거리 4칸")
	return true


func test_t01_walls_clamp() -> bool:
	var sim: RunSimulation = SimFixture.make()
	SimFixture.run(sim, 60 * 15, Vector2(-1.0, -1.0))
	check_near(sim.state.player.pos.x, 1.35, 1e-5, "왼쪽 벽")
	check_near(sim.state.player.pos.y, 1.35, 1e-5, "위쪽 벽")
	SimFixture.run(sim, 60 * 20, Vector2(1.0, 1.0))
	check_near(sim.state.player.pos.x, 49.65, 1e-5, "오른쪽 벽")
	check_near(sim.state.player.pos.y, 49.65, 1e-5, "아래쪽 벽")
	return true


func test_zero_input_keeps_position_and_direction() -> bool:
	var sim: RunSimulation = SimFixture.make()
	SimFixture.run(sim, 1, Vector2.UP)
	var pos: Vector2 = sim.state.player.pos
	SimFixture.run(sim, 30, Vector2.ZERO)
	check_eq(sim.state.player.pos, pos, "입력 0이면 정지")
	check_eq(sim.state.player.last_move_dir, Vector2.UP, "마지막 이동 방향 유지")
	return true
