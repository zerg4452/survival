extends TestCase
## M0-03: 고정 틱, 입력 래치, 상태 전환.


func test_same_sim_time_same_tick_count() -> bool:
	for fps: float in [30.0, 60.0, 144.0]:
		var runner: FixedStepRunner = FixedStepRunner.new()
		var count: Array[int] = [0]
		var step_fn: Callable = func() -> void: count[0] += 1
		var frames: int = int(round(10.0 * fps))
		for i: int in range(frames):
			runner.advance(1.0 / fps, step_fn)
		check_eq(count[0], 600, "%dfps 10초 틱 수" % int(fps))
	return true


func test_irregular_frames_keep_time() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 42
	var runner: FixedStepRunner = FixedStepRunner.new()
	var count: Array[int] = [0]
	var step_fn: Callable = func() -> void: count[0] += 1
	var total: float = 0.0
	while total < 10.0:
		var d: float = rng.randf_range(1.0 / 200.0, 1.0 / 20.0)
		total += d
		runner.advance(d, step_fn)
	check_near(float(count[0]) * SimConstants.FIXED_DT + runner.acc, total, 1e-6, "틱 시간 + 남은 누산 = 실제 시간")
	check(runner.acc < SimConstants.FIXED_DT, "누산기에 한 틱 이상 남지 않음")
	check_eq(runner.dropped_ticks, 0, "버린 틱 없음")
	return true


func test_max_ticks_per_frame() -> bool:
	var runner: FixedStepRunner = FixedStepRunner.new()
	var count: Array[int] = [0]
	var ticks: int = runner.advance(1.0, func() -> void: count[0] += 1)
	check_eq(ticks, 8, "한 프레임 최대 8틱")
	check_eq(count[0], 8, "호출 수")
	check_eq(runner.dropped_ticks, 52, "버린 틱 기록")
	check_eq(runner.acc, 0.0, "남은 누산 폐기")
	return true


func test_dash_latched_on_zero_tick_frame() -> bool:
	var runner: FixedStepRunner = FixedStepRunner.new()
	var latch: InputLatch = InputLatch.new()
	var seen: Array[bool] = []
	var step_fn: Callable = func() -> void: seen.append(latch.consume_dash())
	latch.press_dash()
	check_eq(runner.advance(0.005, step_fn), 0, "틱이 돌지 않는 프레임")
	check_eq(runner.advance(1.0 / 60.0, step_fn), 1, "다음 프레임 1틱")
	check_eq(str(seen), "[true]", "래치된 경공이 다음 틱에 1회 처리")
	return true


func test_dash_only_first_tick_in_multi_tick_frame() -> bool:
	var runner: FixedStepRunner = FixedStepRunner.new()
	var latch: InputLatch = InputLatch.new()
	var seen: Array[bool] = []
	var step_fn: Callable = func() -> void: seen.append(latch.consume_dash())
	latch.press_dash()
	check_eq(runner.advance(2.0 / 60.0, step_fn), 2, "2틱 프레임")
	check_eq(str(seen), "[true, false]", "첫 틱에만 경공")
	return true


func test_paused_sim_does_not_change() -> bool:
	var sim: RunSimulation = SimFixture.make()
	sim.spawn_enemy_at(Vector2(27.0, 25.5))
	SimFixture.run(sim, 5, Vector2.RIGHT)
	sim.set_paused(true)
	var before: String = SimFixture.snapshot(sim)
	SimFixture.run(sim, 30, Vector2.RIGHT)
	check_eq(SimFixture.snapshot(sim), before, "일시정지 중 상태 불변")
	sim.set_paused(false)
	SimFixture.run(sim, 1, Vector2.RIGHT)
	check_eq(sim.state.tick, 6, "복귀 후 틱 진행")
	return true


func test_reset_discards_pending_time() -> bool:
	var runner: FixedStepRunner = FixedStepRunner.new()
	var count: Array[int] = [0]
	var step_fn: Callable = func() -> void: count[0] += 1
	runner.advance(0.01, step_fn)
	runner.reset()
	runner.advance(0.01, step_fn)
	check_eq(count[0], 0, "일시정지 복귀 시 밀린 시간 폐기")
	return true
