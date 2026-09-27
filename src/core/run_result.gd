class_name RunResult
extends RefCounted
## 판 결과. M0 의 종료 사유는 사망뿐이다. M1 에서 승리·제한시간을 추가한다.

enum Reason { DEATH }

var reason: Reason = Reason.DEATH
var end_tick: int = 0
var survived_seconds: float = 0.0
var kills: int = 0
var last_damage_source: String = ""
