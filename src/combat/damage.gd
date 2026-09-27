class_name Damage
extends RefCounted
## 내공 지불과 피해 계산(GAME_DESIGN 7.1, 7.3, D-007, D-011, D-012).


## 비용 이상이면 지불(정상 초식), 아니면 내공을 건드리지 않음(기본 초식).
## 반환: {"paid": bool, "mp_after": float}
static func pay_or_basic(mp: float, cost: float) -> Dictionary:
	if mp + SimConstants.EPS >= cost:
		return {"paid": true, "mp_after": maxf(0.0, mp - cost)}
	return {"paid": false, "mp_after": mp}


## 방어 적용 피해 = 피해 × 100 / (100 + 방어력). 방어력은 설정 범위로 제한한다.
static func after_defense(raw: float, defense: float, cfg: CombatConfig) -> float:
	var def_clamped: float = clampf(defense, cfg.defense_min, cfg.defense_max)
	return raw * 100.0 / (100.0 + def_clamped)
