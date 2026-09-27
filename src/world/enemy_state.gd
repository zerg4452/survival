class_name EnemyState
extends RefCounted
## 판 안의 적 상태.

var id: int = 0
var definition: EnemyDefinition = null
var pos: Vector2 = Vector2.ZERO
var hp: float = 0.0
var max_hp: float = 0.0
## 사망은 딱 한 번 true -> false 로 바뀐다(D-012).
var alive: bool = true
## 스폰 예고가 끝나 활성화되었는지(D-017).
var active: bool = false
var telegraph_remaining: float = 0.0
var contact_cooldown_remaining: float = 0.0
## 표시용: 마지막으로 피해를 받은 틱.
var last_hit_tick: int = -1000


func is_targetable() -> bool:
	return alive and active
