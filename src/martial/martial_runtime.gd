class_name MartialRuntime
extends RefCounted
## 무공의 판 안 상태(GAME_DESIGN 16.2).
## M2 에서 mastery_points, five_star_unlocked, apex_unlocked, effective_hit_counter,
## focus_training_count, last_body_hit_tick 을 추가한다.

var definition: MartialDefinition = null
var cooldown_remaining: float = 0.0
## 마지막 조준 방향. 경계 판정 정밀도를 위해 64비트 스칼라로 보관한다(D-007).
var last_aim_x: float = 1.0
var last_aim_y: float = 0.0
## 표시용
var last_target_pos: Vector2 = Vector2.ZERO
var last_fire_tick: int = -1000


func _init(def: MartialDefinition = null) -> void:
	definition = def


func last_aim_dir() -> Vector2:
	return Vector2(last_aim_x, last_aim_y)
