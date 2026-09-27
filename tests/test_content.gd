extends TestCase
## M0-02: 콘텐츠 데이터와 로더. T02(데이터 부분).


func test_content_loads_without_errors() -> bool:
	var c: GameContent = ContentLoader.load_from_dir()
	check(c.is_ok(), "로드 오류: %s" % str(c.errors))
	check_eq(c.martial_order.size(), 4, "주공 4종")
	check(c.enemy(&"blood_jiangshi") != null, "혈강시 정의")
	return true


func test_t02_martial_values_match_design_table() -> bool:
	var c: GameContent = ContentLoader.load_from_dir()
	# GAME_DESIGN 6장 표: id, 피해, 간격, 비용, 대상, 도형
	var rows: Array = [
		[&"cheongun_sword", MartialDefinition.Family.SWORD, 24.0, 0.65, 6.0, 3, ShapeDef.Kind.SECTOR, 2.0, 90.0],
		[&"swaeam_blade", MartialDefinition.Family.BLADE, 40.0, 1.0, 12.0, 5, ShapeDef.Kind.SECTOR, 2.6, 140.0],
		[&"pajin_spear", MartialDefinition.Family.SPEAR, 48.0, 1.15, 14.0, 4, ShapeDef.Kind.RECT_FORWARD, 0.0, 0.0],
		[&"yeonhwan_fist", MartialDefinition.Family.FIST, 15.0, 0.3, 2.0, 1, ShapeDef.Kind.SECTOR, 1.2, 80.0],
	]
	for row: Array in rows:
		var m: MartialDefinition = c.martial(row[0])
		check(m != null, "%s 존재" % row[0])
		if m == null:
			continue
		check_eq(m.family, row[1], "%s 계열" % m.id)
		check_eq(m.damage, row[2], "%s 피해" % m.id)
		check_eq(m.interval, row[3], "%s 간격" % m.id)
		check_eq(m.mp_cost, row[4], "%s 비용" % m.id)
		check_eq(m.max_targets, row[5], "%s 최대 대상" % m.id)
		check_eq(m.shape.kind, row[6], "%s 도형 종류" % m.id)
		if m.shape.kind == ShapeDef.Kind.SECTOR:
			check_eq(m.shape.radius, row[7], "%s 반경" % m.id)
			check_eq(m.shape.angle_deg_total, row[8], "%s 전체 각" % m.id)
		check_eq(m.passive_defense, 10.0 if m.id == &"yeonhwan_fist" else 0.0, "%s 방어 보너스" % m.id)
	var spear: MartialDefinition = c.martial(&"pajin_spear")
	check_eq(spear.shape.x_min_exclusive, 1.0, "창 사각")
	check_eq(spear.shape.x_max, 4.5, "창 도달")
	check_eq(spear.shape.half_width, 0.4, "창 반폭")
	return true


func test_config_values() -> bool:
	var cfg: CombatConfig = ContentLoader.load_from_dir().config
	check_eq(cfg.player_max_hp, 100.0, "최대 체력")
	check_eq(cfg.player_max_mp, 100.0, "최대 내공")
	check_eq(cfg.player_mp_regen, 12.0, "내공 회복")
	check_eq(cfg.basic_damage_ratio, 0.65, "기본 초식 비율")
	check_eq(cfg.dash_distance, 2.5, "경공 거리")
	check_eq(cfg.dash_recharge, 4.0, "경공 재충전")
	check_eq(cfg.arena_start, Vector2(25.5, 25.5), "시작 위치")
	check_eq(cfg.interior_min(), 1.0, "내부 최소")
	check_eq(cfg.interior_max(), 50.0, "내부 최대")
	return true


func test_missing_field_is_error_not_default() -> bool:
	var errors: Array[String] = []
	var d: Dictionary = _valid_martial()
	d.erase("damage")
	var m: MartialDefinition = ContentLoader.parse_martial(d, "t", errors)
	check(m == null, "누락 시 정의를 만들지 않음")
	check(errors.size() == 1 and errors[0].contains("damage"), "damage 누락 오류: %s" % str(errors))
	return true


func test_negative_interval_is_error() -> bool:
	var errors: Array[String] = []
	var d: Dictionary = _valid_martial()
	d["interval"] = -0.5
	check(ContentLoader.parse_martial(d, "t", errors) == null, "음수 간격 거부")
	check(errors.size() == 1 and errors[0].contains("interval"), "interval 오류: %s" % str(errors))
	return true


func test_unknown_shape_kind_is_error() -> bool:
	var errors: Array[String] = []
	var d: Dictionary = _valid_martial()
	d["shape"] = {"kind": "CIRCLE", "radius": 2.0}
	check(ContentLoader.parse_martial(d, "t", errors) == null, "알 수 없는 도형 거부")
	check(errors.size() == 1 and errors[0].contains("CIRCLE"), "도형 오류: %s" % str(errors))
	return true


func test_valid_dict_parses() -> bool:
	var errors: Array[String] = []
	var m: MartialDefinition = ContentLoader.parse_martial(_valid_martial(), "t", errors)
	check(m != null and errors.is_empty(), "정상 사전: %s" % str(errors))
	return true


func _valid_martial() -> Dictionary:
	return {
		"id": "x", "family": "SWORD", "slot": "MAIN", "display_name": "x",
		"damage": 1, "interval": 1, "mp_cost": 1, "max_targets": 1,
		"active_time": 0, "passive_defense": 0,
		"shape": {"kind": "SECTOR", "radius": 1, "angle_deg_total": 90},
	}
