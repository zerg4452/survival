class_name Shapes
extends RefCounted
## 공격 도형 판정(GAME_DESIGN 5.3, 6.1, D-006, D-007).
## 적의 피격 중심점이 도형 안이면 명중. 국소 좌표는 64비트 스칼라로 계산하고 엡실론을 넣지 않는다.


static func contains(shape: ShapeDef, origin: Vector2, dir_x: float, dir_y: float, point: Vector2) -> bool:
	var vx: float = point.x - origin.x
	var vy: float = point.y - origin.y
	match shape.kind:
		ShapeDef.Kind.SECTOR:
			var d2: float = vx * vx + vy * vy
			if d2 > shape.radius * shape.radius:
				return false
			if d2 < 1e-12:
				return true
			return (vx * dir_x + vy * dir_y) / sqrt(d2) >= shape.cos_half
		ShapeDef.Kind.RECT_FORWARD:
			var lx: float = vx * dir_x + vy * dir_y
			var ly: float = -vx * dir_y + vy * dir_x
			return shape.x_min_exclusive < lx and lx <= shape.x_max and absf(ly) <= shape.half_width
	return false


## 조준 후보 거리 조건(D-008). 부채꼴은 반경 이내, 창 직사각형은 사각 밖~도달거리.
static func aim_range_ok(shape: ShapeDef, d2: float) -> bool:
	match shape.kind:
		ShapeDef.Kind.SECTOR:
			return d2 <= shape.radius * shape.radius
		ShapeDef.Kind.RECT_FORWARD:
			var d: float = sqrt(d2)
			return shape.x_min_exclusive < d and d <= shape.x_max
	return false
