class_name PlayerState
extends RefCounted
## 판 안의 플레이어 상태.

var pos: Vector2 = Vector2.ZERO
var hp: float = 0.0
var max_hp: float = 0.0
var mp: float = 0.0
var max_mp: float = 0.0
var mp_regen: float = 0.0
var move_speed: float = 0.0
var body_radius: float = 0.0
var defense: float = 0.0
var hit_invuln_remaining: float = 0.0

## 이번 틱에 적용된 이동 입력(길이 1 이하).
var move_input: Vector2 = Vector2.ZERO
## 마지막으로 0이 아닌 이동 입력의 방향. 한 번도 없으면 ZERO.
var last_move_dir: Vector2 = Vector2.ZERO

var dash_max_charges: int = 1
var dash_charges: int = 1
var dash_recharge_remaining: float = 0.0
var dash_remaining: float = 0.0
var dash_dir: Vector2 = Vector2.RIGHT
var dash_iframe_remaining: float = 0.0


func is_dashing() -> bool:
	return dash_remaining > SimConstants.EPS


func is_invulnerable() -> bool:
	return hit_invuln_remaining > SimConstants.EPS or dash_iframe_remaining > SimConstants.EPS
