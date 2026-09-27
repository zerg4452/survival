class_name AttackInstance
extends RefCounted
## 한 번의 시전으로 생긴 공격 인스턴스(GAME_DESIGN 5.3, 16.3, D-010).

enum EffectKind { MAIN_NORMAL, MAIN_BASIC }

var instance_id: int = 0
var source_id: StringName = &""
var effect_kind: EffectKind = EffectKind.MAIN_NORMAL
## M0 에서는 항상 false. 파생 효과가 생기는 M2 부터 사용한다.
var can_trigger_procs: bool = false
var created_tick: int = 0
var origin: Vector2 = Vector2.ZERO
var dir_x: float = 1.0
var dir_y: float = 0.0
var shape: ShapeDef = null
var damage: float = 0.0
var max_targets: int = 1
var remaining_active: float = 0.0
var hit_count: int = 0
var hit_ids: Dictionary[int, bool] = {}
## 조준 단계에서 유효로 판정된 주 목표. 생성 틱 판정에 무조건 포함한 뒤 -1 로 지운다(D-008).
var forced_first_target_id: int = -1


func dir() -> Vector2:
	return Vector2(dir_x, dir_y)


func is_basic() -> bool:
	return effect_kind == EffectKind.MAIN_BASIC
