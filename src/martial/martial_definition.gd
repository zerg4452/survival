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
