class_name SpatialGrid
extends RefCounted
## 균일 격자 버킷. 적끼리 분리할 때 주변 3×3 칸만 조사한다(GAME_DESIGN 16.4).

const ROW_STRIDE: int = 4096

var cell_size: float = 1.0
var _cells: Dictionary[int, Array] = {}


func _init(p_cell_size: float = 1.0) -> void:
	cell_size = p_cell_size


func rebuild(enemies: Array[EnemyState]) -> void:
	_cells.clear()
	for e: EnemyState in enemies:
		if not e.is_targetable():
			continue
		var key: int = _key(_cell(e.pos.x), _cell(e.pos.y))
		if not _cells.has(key):
			_cells[key] = []
		_cells[key].append(e)


## pos 가 속한 칸과 인접 8칸의 적. 순서는 칸 순서이며 호출 측에서 ID 로 중복 처리를 막는다.
func neighbors(pos: Vector2) -> Array[EnemyState]:
	var out: Array[EnemyState] = []
	var cx: int = _cell(pos.x)
	var cy: int = _cell(pos.y)
	for oy: int in range(-1, 2):
		for ox: int in range(-1, 2):
			var key: int = _key(cx + ox, cy + oy)
			if _cells.has(key):
				for e: EnemyState in _cells[key]:
					out.append(e)
	return out


func _cell(v: float) -> int:
	return int(floorf(v / cell_size))


func _key(cx: int, cy: int) -> int:
	return cx + cy * ROW_STRIDE
