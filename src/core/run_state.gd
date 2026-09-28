class_name RunState
extends RefCounted
## 한 판의 모든 가변 상태(ARCHITECTURE 5.5). 재시작은 새 인스턴스를 만든다(D-020).

enum Phase { RUNNING, PAUSED, RESULT }

const ATTACK_LOG_CAP: int = 32
const DEATH_LOG_CAP: int = 64
const PARRY_LOG_CAP: int = 32

var seed: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var tick: int = 0
var phase: Phase = Phase.RUNNING

var player: PlayerState = null
var main_martial: MartialRuntime = null
## ID 오름차순을 유지한다(생성 순서 = ID 순서).
var enemies: Array[EnemyState] = []
var attacks: Array[AttackInstance] = []

var spawn_acc: float = 0.0
var next_entity_id: int = 0

var stats: RunStats = RunStats.new()
var result: RunResult = null
var last_damage_source: String = ""

## 이번 틱에 사망이 확정된 적 ID. 틱 시작마다 비운다.
var deaths_this_tick: Array[int] = []

# ---- 표시용 기록(시뮬레이션 규칙에 영향 없음) ----
var attack_log: Array[AttackInstance] = []
## x, y = 위치, z = 사망 틱
var death_log: Array[Vector3] = []
## x, y = 패링한 적 위치, z = 틱
var parry_log: Array[Vector3] = []

# ---- 디버그(D-022) ----
var auto_spawn: bool = true
var enemy_hp_mult: float = 1.0
var debug_invincible: bool = false
var debug_used: bool = false


func alloc_id() -> int:
	next_entity_id += 1
	return next_entity_id


func sim_time() -> float:
	return float(tick) * SimConstants.FIXED_DT


func log_attack(inst: AttackInstance) -> void:
	attack_log.append(inst)
	if attack_log.size() > ATTACK_LOG_CAP:
		attack_log.pop_front()


func log_death(pos: Vector2) -> void:
	death_log.append(Vector3(pos.x, pos.y, float(tick)))
	if death_log.size() > DEATH_LOG_CAP:
		death_log.pop_front()


func log_parry(pos: Vector2) -> void:
	parry_log.append(Vector3(pos.x, pos.y, float(tick)))
	if parry_log.size() > PARRY_LOG_CAP:
		parry_log.pop_front()


func active_enemy_count() -> int:
	var n: int = 0
	for e: EnemyState in enemies:
		if e.is_targetable():
			n += 1
	return n
