class_name ContentLoader
extends RefCounted
## content/*.json 을 읽어 타입 있는 정의로 만든다(D-004).
## 누락·형식 오류는 errors 에 기록하고 기본값으로 조용히 대체하지 않는다.

const DEFAULT_DIR: String = "res://content"


static func load_from_dir(dir: String = DEFAULT_DIR) -> GameContent:
	var content: GameContent = GameContent.new()
	var errors: Array[String] = content.errors

	var cfg_data: Variant = _read_json("%s/combat_config.json" % dir, errors)
	if cfg_data is Dictionary:
		content.config = parse_config(cfg_data, errors)

	var m_data: Variant = _read_json("%s/martials.json" % dir, errors)
	if m_data is Dictionary:
		var list: Variant = (m_data as Dictionary).get("martials", null)
		if list is Array:
			for i: int in range((list as Array).size()):
				var item: Variant = (list as Array)[i]
				if not item is Dictionary:
					errors.append("martials[%d] 가 객체가 아님" % i)
					continue
				var m: MartialDefinition = parse_martial(item, "martials[%d]" % i, errors)
				if m == null:
					continue
				if content.martials.has(m.id):
					errors.append("무공 ID 중복: %s" % m.id)
					continue
				content.martials[m.id] = m
				content.martial_order.append(m.id)
		else:
			errors.append("martials.json: martials 배열 누락")

	var e_data: Variant = _read_json("%s/enemies.json" % dir, errors)
	if e_data is Dictionary:
		var elist: Variant = (e_data as Dictionary).get("enemies", null)
		if elist is Array:
			for i: int in range((elist as Array).size()):
				var item: Variant = (elist as Array)[i]
				if not item is Dictionary:
					errors.append("enemies[%d] 가 객체가 아님" % i)
					continue
				var e: EnemyDefinition = parse_enemy(item, "enemies[%d]" % i, errors)
				if e == null:
					continue
				if content.enemies.has(e.id):
					errors.append("적 ID 중복: %s" % e.id)
					continue
				content.enemies[e.id] = e
		else:
			errors.append("enemies.json: enemies 배열 누락")

	if content.config != null and not content.enemies.has(content.config.spawn_enemy_id):
		errors.append("m0_spawn.enemy_id 가 enemies.json 에 없음: %s" % content.config.spawn_enemy_id)
	return content


static func parse_martial(d: Dictionary, ctx: String, errors: Array[String]) -> MartialDefinition:
	var before: int = errors.size()
	var m: MartialDefinition = MartialDefinition.new()
	m.id = StringName(_str(d, "id", ctx, errors))
	var fam: String = _str(d, "family", ctx, errors)
	if d.has("family"):
		if MartialDefinition.Family.has(fam):
			m.family = MartialDefinition.Family[fam]
		else:
			errors.append("%s.family 알 수 없는 값: %s" % [ctx, fam])
	var slot: String = _str(d, "slot", ctx, errors)
	if d.has("slot") and slot != "MAIN":
		errors.append("%s.slot 은 M0 에서 MAIN 만 허용: %s" % [ctx, slot])
	m.display_name = _str(d, "display_name", ctx, errors)
	m.damage = _num(d, "damage", ctx, errors, 0.0, false)
	m.interval = _num(d, "interval", ctx, errors, 0.0, false)
	m.mp_cost = _num(d, "mp_cost", ctx, errors, 0.0, false)
	m.max_targets = _int(d, "max_targets", ctx, errors, 1)
	m.active_time = _num(d, "active_time", ctx, errors, 0.0, true)
	m.passive_defense = _num(d, "passive_defense", ctx, errors, 0.0, true)
	# 활성 시간이 간격 이상이면 이전 인스턴스가 새 인스턴스의 주 목표를 먼저 처치해
	# 내공만 쓰고 빗나갈 수 있다(M0 리뷰 R03). 공격속도 보너스가 생기면 적용 후 간격으로 다시 확인한다.
	if errors.size() == before and m.active_time >= m.interval:
		errors.append("%s.active_time 은 interval 보다 짧아야 함 (%s >= %s)" % [ctx, str(m.active_time), str(m.interval)])
	if d.has("shape") and d["shape"] is Dictionary:
		m.shape = parse_shape(d["shape"], ctx + ".shape", errors)
	else:
		errors.append("%s.shape 누락 또는 객체가 아님" % ctx)
	return m if errors.size() == before else null


static func parse_shape(d: Dictionary, ctx: String, errors: Array[String]) -> ShapeDef:
	var kind: String = _str(d, "kind", ctx, errors)
	match kind:
		"SECTOR":
			var r: float = _num(d, "radius", ctx, errors, 0.0, false)
			var a: float = _num(d, "angle_deg_total", ctx, errors, 0.0, false)
			if a > 360.0:
				errors.append("%s.angle_deg_total 는 360 이하" % ctx)
			return ShapeDef.sector(r, a)
		"RECT_FORWARD":
			var x_min: float = _num(d, "x_min_exclusive", ctx, errors, 0.0, true)
			var x_max: float = _num(d, "x_max", ctx, errors, 0.0, false)
			var hw: float = _num(d, "half_width", ctx, errors, 0.0, false)
			if x_max <= x_min:
				errors.append("%s.x_max 는 x_min_exclusive 보다 커야 함" % ctx)
			return ShapeDef.rect_forward(x_min, x_max, hw)
		_:
			if d.has("kind"):
				errors.append("%s.kind 알 수 없는 도형: %s" % [ctx, kind])
			return null


static func parse_enemy(d: Dictionary, ctx: String, errors: Array[String]) -> EnemyDefinition:
	var before: int = errors.size()
	var e: EnemyDefinition = EnemyDefinition.new()
	e.id = StringName(_str(d, "id", ctx, errors))
	e.display_name = _str(d, "display_name", ctx, errors)
	e.max_hp = _num(d, "max_hp", ctx, errors, 0.0, false)
	e.move_speed = _num(d, "move_speed", ctx, errors, 0.0, true)
	e.contact_damage = _num(d, "contact_damage", ctx, errors, 0.0, true)
	e.contact_interval = _num(d, "contact_interval", ctx, errors, 0.0, false)
	e.body_radius = _num(d, "body_radius", ctx, errors, 0.0, false)
	e.exp = _int(d, "exp", ctx, errors, 0)
	return e if errors.size() == before else null


static func parse_config(d: Dictionary, errors: Array[String]) -> CombatConfig:
	var c: CombatConfig = CombatConfig.new()
	var p: Dictionary = _obj(d, "player", "config", errors)
	c.player_max_hp = _num(p, "max_hp", "player", errors, 0.0, false)
	c.player_move_speed = _num(p, "move_speed", "player", errors, 0.0, false)
	c.player_body_radius = _num(p, "body_radius", "player", errors, 0.0, false)
	c.player_hit_invuln = _num(p, "hit_invuln", "player", errors, 0.0, true)
	c.player_base_defense = _num(p, "base_defense", "player", errors, 0.0, true)
	c.player_max_mp = _num(p, "max_mp", "player", errors, 0.0, false)
	c.player_mp_regen = _num(p, "mp_regen", "player", errors, 0.0, true)

	var ds: Dictionary = _obj(d, "dash", "config", errors)
	c.dash_distance = _num(ds, "distance", "dash", errors, 0.0, false)
	c.dash_duration = _num(ds, "duration", "dash", errors, 0.0, false)
	c.dash_iframe = _num(ds, "iframe", "dash", errors, 0.0, true)
	c.dash_charges = _int(ds, "charges", "dash", errors, 1)
	c.dash_recharge = _num(ds, "recharge", "dash", errors, 0.0, false)

	var cb: Dictionary = _obj(d, "combat", "config", errors)
	c.basic_damage_ratio = _num(cb, "basic_damage_ratio", "combat", errors, 0.0, true)
	c.defense_min = _num(cb, "defense_min", "combat", errors, 0.0, true)
	c.defense_max = _num(cb, "defense_max", "combat", errors, 0.0, true)
	c.contact_margin = _num(cb, "contact_margin", "combat", errors, 0.0, true)

	var ar: Dictionary = _obj(d, "arena", "config", errors)
	c.arena_size = _int(ar, "size", "arena", errors, 3)
	c.arena_wall = _int(ar, "wall", "arena", errors, 0)
	c.arena_start = _vec2(ar, "start", "arena", errors)

	var cam: Dictionary = _obj(d, "camera", "config", errors)
	c.camera_visible_rows = _num(cam, "visible_rows", "camera", errors, 0.0, false)

	var sp: Dictionary = _obj(d, "m0_spawn", "config", errors)
	c.spawn_enemy_id = StringName(_str(sp, "enemy_id", "m0_spawn", errors))
	c.spawn_rate = _num(sp, "rate", "m0_spawn", errors, 0.0, true)
	c.spawn_min_dist = _num(sp, "min_dist", "m0_spawn", errors, 0.0, true)
	c.spawn_max_dist = _num(sp, "max_dist", "m0_spawn", errors, 0.0, false)
	c.spawn_tries = _int(sp, "tries", "m0_spawn", errors, 1)
	c.spawn_telegraph = _num(sp, "telegraph", "m0_spawn", errors, 0.0, true)
	c.spawn_normal_cap = _int(sp, "normal_cap", "m0_spawn", errors, 1)
	c.spawn_debt_cap = _num(sp, "debt_cap", "m0_spawn", errors, 1.0, true)
	if c.spawn_max_dist < c.spawn_min_dist:
		errors.append("m0_spawn.max_dist 는 min_dist 이상")
	return c


# ---- 내부 도우미 ----

static func _read_json(path: String, errors: Array[String]) -> Variant:
	if not FileAccess.file_exists(path):
		errors.append("파일 없음: %s" % path)
		return null
	var text: String = FileAccess.get_file_as_string(path)
	var json: JSON = JSON.new()
	var err: Error = json.parse(text)
	if err != OK:
		errors.append("%s: JSON 오류 %d행: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


static func _obj(d: Dictionary, key: String, ctx: String, errors: Array[String]) -> Dictionary:
	if d.has(key) and d[key] is Dictionary:
		return d[key]
	errors.append("%s.%s 누락 또는 객체가 아님" % [ctx, key])
	return {}


static func _str(d: Dictionary, key: String, ctx: String, errors: Array[String]) -> String:
	if not d.has(key):
		errors.append("%s.%s 누락" % [ctx, key])
		return ""
	if not d[key] is String:
		errors.append("%s.%s 는 문자열이어야 함" % [ctx, key])
		return ""
	var s: String = d[key]
	if s.is_empty():
		errors.append("%s.%s 가 비어 있음" % [ctx, key])
	return s


static func _num(d: Dictionary, key: String, ctx: String, errors: Array[String], min_value: float, min_inclusive: bool) -> float:
	if not d.has(key):
		errors.append("%s.%s 누락" % [ctx, key])
		return 0.0
	var v: Variant = d[key]
	if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
		errors.append("%s.%s 는 숫자여야 함" % [ctx, key])
		return 0.0
	var f: float = float(v)
	if (min_inclusive and f < min_value) or (not min_inclusive and f <= min_value):
		errors.append("%s.%s 범위 오류: %s (최소 %s%s)" % [ctx, key, str(f), str(min_value), "" if min_inclusive else " 초과"])
	return f


static func _int(d: Dictionary, key: String, ctx: String, errors: Array[String], min_value: int) -> int:
	var f: float = _num(d, key, ctx, errors, float(min_value), true)
	if d.has(key) and f != floorf(f):
		errors.append("%s.%s 는 정수여야 함" % [ctx, key])
	return int(f)


static func _vec2(d: Dictionary, key: String, ctx: String, errors: Array[String]) -> Vector2:
	if d.has(key) and d[key] is Array and (d[key] as Array).size() == 2:
		var a: Array = d[key]
		if (typeof(a[0]) == TYPE_FLOAT or typeof(a[0]) == TYPE_INT) and (typeof(a[1]) == TYPE_FLOAT or typeof(a[1]) == TYPE_INT):
			return Vector2(float(a[0]), float(a[1]))
	errors.append("%s.%s 는 숫자 2개 배열이어야 함" % [ctx, key])
	return Vector2.ZERO
