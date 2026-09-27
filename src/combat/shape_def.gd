class_name ShapeDef
extends RefCounted
## 공격 판정 도형 정의. 판정은 Shapes 를 사용한다.

enum Kind { SECTOR, RECT_FORWARD }

var kind: Kind = Kind.SECTOR
# SECTOR
var radius: float = 0.0
var angle_deg_total: float = 0.0
var cos_half: float = 1.0
# RECT_FORWARD: x_min_exclusive < local_x <= x_max, |local_y| <= half_width
var x_min_exclusive: float = 0.0
var x_max: float = 0.0
var half_width: float = 0.0


static func sector(r: float, angle_total: float) -> ShapeDef:
	var s: ShapeDef = ShapeDef.new()
	s.kind = Kind.SECTOR
	s.radius = r
	s.angle_deg_total = angle_total
	s.cos_half = cos(deg_to_rad(angle_total * 0.5))
	return s


static func rect_forward(x_min: float, x_max_value: float, hw: float) -> ShapeDef:
	var s: ShapeDef = ShapeDef.new()
	s.kind = Kind.RECT_FORWARD
	s.x_min_exclusive = x_min
	s.x_max = x_max_value
	s.half_width = hw
	return s
