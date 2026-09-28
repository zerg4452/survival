class_name MartialDefinition
extends RefCounted
## 무공의 고정 정의(GAME_DESIGN 16.2). 판 안 상태는 MartialRuntime 에 둔다.
## M2 에서 five_star_effect_id, apex_effect_id 를 추가한다.

enum Family { SWORD, BLADE, SPEAR, FIST }
enum Slot { MAIN }

var id: StringName = &""
var family: Family = Family.SWORD
var slot: Slot = Slot.MAIN
var display_name: String = ""
var damage: float = 0.0
var interval: float = 0.0
var mp_cost: float = 0.0
var max_targets: int = 1
var active_time: float = 0.0
var passive_defense: float = 0.0
var shape: ShapeDef = null
## 패링(D-025). 창이 0이면 없음. 주공 공격 전후 parry_window 초 안의 접촉 피격을 무효로 하고
## 공격자에게 damage × parry_counter_ratio 를 1회 준다.
var parry_window: float = 0.0
var parry_counter_ratio: float = 0.0


func has_parry() -> bool:
	return parry_window > 0.0
