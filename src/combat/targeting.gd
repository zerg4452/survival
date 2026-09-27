class_name Targeting
extends RefCounted
## 자동 조준과 명중 대상 선택(GAME_DESIGN 5.2, D-008).


## 조준 가능한 가장 가까운 적. 거리가 같으면 ID 가 작은 적. 없으면 null.
static func pick_primary(enemies: Array[EnemyState], origin: Vector2, shape: ShapeDef) -> EnemyState:
	var best: EnemyState = null
	var best_d2: float = INF
	for e: EnemyState in enemies:
		if not e.is_targetable():
			continue
		var vx: float = e.pos.x - origin.x
		var vy: float = e.pos.y - origin.y
		var d2: float = vx * vx + vy * vy
		if not Shapes.aim_range_ok(shape, d2):
			continue
		if d2 < best_d2 or (d2 == best_d2 and best != null and e.id < best.id):
			best = e
			best_d2 = d2
	return best


## 이번 틱에 인스턴스가 새로 맞힐 적. 거리 오름차순, 같으면 ID 오름차순으로 남은 대상 수만큼.
## 이미 맞힌 적(hit_ids)과 죽었거나 예고 중인 적은 제외한다.
static func select_hits(enemies: Array[EnemyState], inst: AttackInstance) -> Array[EnemyState]:
	var out: Array[EnemyState] = []
	var remaining: int = inst.max_targets - inst.hit_count
	if remaining <= 0:
		return out
	var cands: Array[Array] = []
	for e: EnemyState in enemies:
		if not e.is_targetable() or inst.hit_ids.has(e.id):
			continue
		var forced: bool = e.id == inst.forced_first_target_id
		if forced or Shapes.contains(inst.shape, inst.origin, inst.dir_x, inst.dir_y, e.pos):
			var vx: float = e.pos.x - inst.origin.x
			var vy: float = e.pos.y - inst.origin.y
			var key: float = -1.0 if forced else vx * vx + vy * vy
			cands.append([key, e.id, e])
	cands.sort_custom(_less)
	for i: int in range(mini(remaining, cands.size())):
		out.append(cands[i][2])
	return out


static func _less(a: Array, b: Array) -> bool:
	var ka: float = a[0]
	var kb: float = b[0]
	if ka != kb:
		return ka < kb
	var ia: int = a[1]
	var ib: int = b[1]
	return ia < ib
