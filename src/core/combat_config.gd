class_name CombatConfig
extends RefCounted
## content/combat_config.json 의 값.

var player_max_hp: float = 0.0
var player_move_speed: float = 0.0
var player_body_radius: float = 0.0
var player_hit_invuln: float = 0.0
var player_base_defense: float = 0.0
var player_max_mp: float = 0.0
var player_mp_regen: float = 0.0

var dash_distance: float = 0.0
var dash_duration: float = 0.0
var dash_iframe: float = 0.0
var dash_charges: int = 0
var dash_recharge: float = 0.0

var basic_damage_ratio: float = 0.0
var defense_min: float = 0.0
var defense_max: float = 0.0
var contact_margin: float = 0.0

var arena_size: int = 0
var arena_wall: int = 0
var arena_start: Vector2 = Vector2.ZERO

var camera_visible_rows: float = 0.0

var spawn_enemy_id: StringName = &""
var spawn_rate: float = 0.0
var spawn_min_dist: float = 0.0
var spawn_max_dist: float = 0.0
var spawn_tries: int = 0
var spawn_telegraph: float = 0.0
var spawn_normal_cap: int = 0
var spawn_debt_cap: float = 0.0


## 내부(이동 가능) 영역의 최소 좌표. 벽 1칸이면 1.0.
func interior_min() -> float:
	return float(arena_wall)


## 내부 영역의 최대 좌표. 51칸, 벽 1칸이면 50.0.
func interior_max() -> float:
	return float(arena_size - arena_wall)
