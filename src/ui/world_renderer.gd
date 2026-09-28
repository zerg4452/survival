class_name WorldRenderer
extends Node2D
## 월드 표시. RunState 를 읽기만 하고 규칙을 갖지 않는다(ARCHITECTURE 10장).
## 색만으로 구분하지 않는다: 적은 채운 원, 예고 중인 적은 끊어진 링, 공격은 반투명 면과 외곽선,
## 기본 초식은 외곽선 없이 면만 그린다.

const PPC: float = 64.0
## 공격 도형을 표시할 틱 수(시뮬레이션 활성 시간과 무관한 표시용).
const ATTACK_SHOW_TICKS: int = 9
const DEATH_SHOW_TICKS: int = 30
const PARRY_SHOW_TICKS: int = 14

const C_OUTSIDE: Color = Color(0.03, 0.03, 0.04)
const C_WALL: Color = Color(0.24, 0.2, 0.2)
const C_FLOOR: Color = Color(0.12, 0.11, 0.12)
const C_GRID: Color = Color(1, 1, 1, 0.035)
const C_GRID_MAJOR: Color = Color(1, 1, 1, 0.08)
const C_PLAYER: Color = Color(0.85, 0.85, 0.78)
const C_PLAYER_EDGE: Color = Color(0.2, 0.2, 0.18)
const C_ENEMY: Color = Color(0.62, 0.16, 0.16)
const C_ENEMY_EDGE: Color = Color(0.25, 0.05, 0.05)
const C_TELEGRAPH: Color = Color(0.95, 0.45, 0.35)
const C_ATTACK: Color = Color(0.95, 0.78, 0.35)
const C_BASIC: Color = Color(0.6, 0.75, 0.95)
const C_DEBUG: Color = Color(0.4, 0.95, 0.6)
const C_DANGER: Color = Color(0.95, 0.35, 0.3)

var sim: RunSimulation = null
var show_debug: bool = false


func _draw() -> void:
	if sim == null:
		return
	var s: RunState = sim.state
	var cfg: CombatConfig = sim.cfg
	_draw_arena(cfg)
	_draw_deaths(s)
	for e: EnemyState in s.enemies:
		if not e.active:
			_draw_telegraph(e, sim.cfg.spawn_telegraph)
	_draw_attacks(s)
	for e: EnemyState in s.enemies:
		if e.active:
			_draw_enemy(e, s.tick)
	_draw_player(s)
	_draw_parries(s)
	if show_debug:
		_draw_debug(s, cfg)


func _draw_arena(cfg: CombatConfig) -> void:
	var size: float = float(cfg.arena_size)
	draw_rect(Rect2(Vector2(-20, -20) * PPC, Vector2(size + 40, size + 40) * PPC), C_OUTSIDE)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size, size) * PPC), C_WALL)
	var lo: float = cfg.interior_min()
	var hi: float = cfg.interior_max()
	draw_rect(Rect2(Vector2(lo, lo) * PPC, Vector2(hi - lo, hi - lo) * PPC), C_FLOOR)
	for i: int in range(int(lo), int(hi) + 1):
		var c: Color = C_GRID_MAJOR if i % 5 == 0 else C_GRID
		draw_line(Vector2(i, lo) * PPC, Vector2(i, hi) * PPC, c, 1.0)
		draw_line(Vector2(lo, i) * PPC, Vector2(hi, i) * PPC, c, 1.0)


func _draw_deaths(s: RunState) -> void:
	for d: Vector3 in s.death_log:
		var age: int = s.tick - int(d.z)
		if age < 0 or age > DEATH_SHOW_TICKS:
			continue
		var a: float = 1.0 - float(age) / float(DEATH_SHOW_TICKS)
		var p: Vector2 = Vector2(d.x, d.y) * PPC
		var r: float = 0.25 * PPC
		var c: Color = Color(C_ENEMY, 0.8 * a)
		draw_line(p + Vector2(-r, -r), p + Vector2(r, r), c, 3.0)
		draw_line(p + Vector2(-r, r), p + Vector2(r, -r), c, 3.0)


## 패링(D-025): 막아낸 적 위치에 퍼지는 이중 링.
func _draw_parries(s: RunState) -> void:
	for d: Vector3 in s.parry_log:
		var age: int = s.tick - int(d.z)
		if age < 0 or age > PARRY_SHOW_TICKS:
			continue
		var t: float = float(age) / float(PARRY_SHOW_TICKS)
		var p: Vector2 = Vector2(d.x, d.y) * PPC
		var c: Color = Color(1, 1, 1, 0.9 * (1.0 - t))
		draw_arc(p, (0.3 + 0.4 * t) * PPC, 0.0, TAU, 24, c, 3.0)
		draw_arc(p, (0.15 + 0.3 * t) * PPC, 0.0, TAU, 16, c, 1.5)


func _draw_telegraph(e: EnemyState, total: float) -> void:
	var p: Vector2 = e.pos * PPC
	var r: float = e.definition.body_radius * PPC
	var segs: int = 8
	for i: int in range(segs):
		var a0: float = TAU * float(i) / float(segs)
		draw_arc(p, r, a0, a0 + TAU / float(segs) * 0.55, 6, C_TELEGRAPH, 2.0)
	var progress: float = 1.0 - clampf(e.telegraph_remaining / maxf(total, 0.001), 0.0, 1.0)
	draw_circle(p, r * 0.35 * progress, Color(C_TELEGRAPH, 0.6))


func _draw_attacks(s: RunState) -> void:
	for inst: AttackInstance in s.attack_log:
		var age: int = s.tick - inst.created_tick
		if age < 0 or age >= ATTACK_SHOW_TICKS:
			continue
		var fade: float = 1.0 - float(age) / float(ATTACK_SHOW_TICKS)
		var pts: PackedVector2Array = shape_polygon(inst.shape, inst.origin, inst.dir())
		var base: Color = C_BASIC if inst.is_basic() else C_ATTACK
		draw_colored_polygon(pts, Color(base, 0.28 * fade))
		if not inst.is_basic():
			var closed: PackedVector2Array = pts.duplicate()
			closed.append(pts[0])
			draw_polyline(closed, Color(base, 0.9 * fade), 2.0)


func _draw_enemy(e: EnemyState, tick: int) -> void:
	var p: Vector2 = e.pos * PPC
	var r: float = e.definition.body_radius * PPC
	draw_circle(p, r, C_ENEMY)
	var flash: bool = tick - e.last_hit_tick <= 4
	draw_arc(p, r, 0.0, TAU, 20, Color.WHITE if flash else C_ENEMY_EDGE, 3.0 if flash else 2.0)
	if e.hp < e.max_hp:
		var w: float = r * 2.0
		var top: Vector2 = p + Vector2(-r, -r - 10.0)
		draw_rect(Rect2(top, Vector2(w, 4.0)), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(top, Vector2(w * clampf(e.hp / e.max_hp, 0.0, 1.0), 4.0)), Color(0.9, 0.3, 0.25))


func _draw_player(s: RunState) -> void:
	var pl: PlayerState = s.player
	var p: Vector2 = pl.pos * PPC
	var r: float = pl.body_radius * PPC
	var c: Color = C_PLAYER
	if pl.is_invulnerable() and posmod(floori(s.tick / 3.0), 2) == 0:
		c = Color(C_PLAYER, 0.45)
	draw_circle(p, r, c)
	draw_arc(p, r, 0.0, TAU, 24, C_PLAYER_EDGE, 2.0)
	var aim: Vector2 = s.main_martial.last_aim_dir()
	draw_line(p, p + aim * r * 1.6, C_ATTACK, 3.0)
	if pl.is_dashing():
		draw_arc(p, r * 1.5, 0.0, TAU, 24, Color(C_PLAYER, 0.5), 2.0)


func _draw_debug(s: RunState, cfg: CombatConfig) -> void:
	var pl: PlayerState = s.player
	var p: Vector2 = pl.pos * PPC
	var enemy_r: float = sim.content.enemy(cfg.spawn_enemy_id).body_radius
	var reach: float = (pl.body_radius + enemy_r + cfg.contact_margin) * PPC
	draw_arc(p, reach, 0.0, TAU, 32, Color(C_DANGER, 0.8), 1.5)
	var def: MartialDefinition = s.main_martial.definition
	var aim: Vector2 = s.main_martial.last_aim_dir()
	var preview: PackedVector2Array = shape_polygon(def.shape, pl.pos, aim)
	var closed: PackedVector2Array = preview.duplicate()
	closed.append(preview[0])
	draw_polyline(closed, Color(C_DEBUG, 0.6), 1.5)
	if def.shape.kind == ShapeDef.Kind.RECT_FORWARD:
		var dz: ShapeDef = ShapeDef.rect_forward(0.0, def.shape.x_min_exclusive, def.shape.half_width)
		draw_colored_polygon(shape_polygon(dz, pl.pos, aim), Color(C_DANGER, 0.18))
	if s.tick - s.main_martial.last_fire_tick < 40:
		draw_line(p, s.main_martial.last_target_pos * PPC, Color(C_DEBUG, 0.8), 1.5)
	for e: EnemyState in s.enemies:
		draw_circle(e.pos * PPC, 3.0, C_DEBUG)


## 도형을 월드 좌표 다각형(픽셀)으로 만든다.
static func shape_polygon(shape: ShapeDef, origin: Vector2, dir: Vector2) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	var ang: float = dir.angle()
	if shape.kind == ShapeDef.Kind.SECTOR:
		var half: float = deg_to_rad(shape.angle_deg_total * 0.5)
		pts.append(origin * PPC)
		var segs: int = 18
		for i: int in range(segs + 1):
			var a: float = ang - half + 2.0 * half * float(i) / float(segs)
			pts.append((origin + Vector2(cos(a), sin(a)) * shape.radius) * PPC)
	else:
		var locals: Array[Vector2] = [
			Vector2(shape.x_min_exclusive, -shape.half_width), Vector2(shape.x_max, -shape.half_width),
			Vector2(shape.x_max, shape.half_width), Vector2(shape.x_min_exclusive, shape.half_width)]
		for l: Vector2 in locals:
			pts.append((origin + l.rotated(ang)) * PPC)
	return pts
