class_name Arena
extends RefCounted
## M0 전장: 51×51, 외곽 1칸 벽, 장애물 없음(GAME_DESIGN 5.1, 13.1).
## 장애물 지형이 들어오면 이 모듈을 교체한다(D-002).


## 원(중심, 반경)을 내부 영역 [min + r, max - r] 로 축별 클램프한다. 벽을 따라 미끄러진다.
static func clamp_circle(cfg: CombatConfig, pos: Vector2, radius: float) -> Vector2:
	var lo: float = cfg.interior_min() + radius
	var hi: float = cfg.interior_max() - radius
	return Vector2(clampf(pos.x, lo, hi), clampf(pos.y, lo, hi))


static func contains_circle(cfg: CombatConfig, pos: Vector2, radius: float) -> bool:
	var lo: float = cfg.interior_min() + radius
	var hi: float = cfg.interior_max() - radius
	return pos.x >= lo and pos.x <= hi and pos.y >= lo and pos.y <= hi
