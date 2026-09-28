extends TestCase
## M0-12: T23. 같은 틱별 입력을 서로 다른 렌더 프레임 간격으로 구동해도 시뮬레이션 결과가 같다.

const TARGET_TICK: int = 600


## 틱 번호로 정해지는 입력(이동 유지 + 경공 2회).
static func _input_for(tick: int) -> InputFrame:
	var move: Vector2 = Vector2.ZERO
	if tick < 120:
		move = Vector2.RIGHT
	elif tick < 240:
		move = Vector2.DOWN
	elif tick < 360:
		move = Vector2(-1.0, -1.0)
	elif tick < 480:
		move = Vector2.LEFT
	return InputFrame.make(move, tick == 120 or tick == 360)


func _run_with_frames(martial: StringName, frame_dts: Callable) -> String:
	var sim: RunSimulation = SimFixture.make(martial, 2024)
	sim.state.auto_spawn = true
	sim.state.player.max_hp = 1e6
	sim.state.player.hp = 1e6
	# 접촉 피해·피격 무적 경로도 비교하도록 체력이 큰 적 12마리를 둘러 둔다(M0 리뷰 R02).
	sim.state.enemy_hp_mult = 50.0
	for i: int in range(12):
		var a: float = TAU * float(i) / 12.0
		sim.spawn_enemy_at(Vector2(25.5, 25.5) + Vector2(cos(a), sin(a)) * 3.0)
	sim.state.enemy_hp_mult = 1.0
	var runner: FixedStepRunner = FixedStepRunner.new()
	var snap: Array[String] = [""]
	var step_fn: Callable = func() -> void:
		if sim.state.tick >= TARGET_TICK:
			return
		sim.step(_input_for(sim.state.tick))
		if sim.state.tick == TARGET_TICK:
			snap[0] = SimFixture.snapshot(sim)
	var frame: int = 0
	while snap[0].is_empty() and frame < 100000:
		var dt: float = frame_dts.call(frame)
		runner.advance(dt, step_fn)
		frame += 1
	return snap[0]


func test_t23_frame_rate_independent() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var irregular: PackedFloat64Array = []
	for i: int in range(20000):
		irregular.append(rng.randf_range(1.0 / 200.0, 1.0 / 20.0))
	var sequences: Dictionary[String, Callable] = {
		"30fps": func(_f: int) -> float: return 1.0 / 30.0,
		"60fps": func(_f: int) -> float: return 1.0 / 60.0,
		"144fps": func(_f: int) -> float: return 1.0 / 144.0,
		"irregular": func(f: int) -> float: return irregular[f % irregular.size()],
	}
	for martial: StringName in [&"cheongun_sword", &"pajin_spear", &"yeonhwan_fist"]:
		var ref: String = ""
		for name: String in sequences:
			var snap: String = _run_with_frames(martial, sequences[name])
			check(not snap.is_empty(), "%s %s: %d틱 도달" % [martial, name, TARGET_TICK])
			if ref.is_empty():
				ref = snap
				var contacts: int = _stat(snap, "hits") + _stat(snap, "parries")
				check(contacts > 0, "%s: 접촉(피격+패링)이 실제로 발생(%d회)" % [martial, contacts])
				check(_stat(snap, "dashes") == 2, "%s: 경공 2회" % martial)
				check(_stat(snap, "kills") > 0, "%s: 처치 발생" % martial)
			else:
				check(snap == ref, "%s %s 결과가 30fps 와 동일" % [martial, name])
		check(ref.contains("tick=%d" % TARGET_TICK), "%s 스냅샷 틱" % martial)
	return true


static func _stat(snap: String, key: String) -> int:
	var re: RegEx = RegEx.create_from_string("(?:^|\\s)%s=(\\d+)" % key)
	var m: RegExMatch = re.search(snap)
	return int(m.get_string(1)) if m != null else -1
