class_name TestCase
extends RefCounted
## 테스트 파일의 기반 클래스.
## 규칙: test_ 로 시작하는 메서드는 -> bool 이며 마지막에 true 를 반환한다.
## 도중에 스크립트 오류가 나면 반환값이 true 가 아니므로 실행기가 실패로 처리한다.

var failures: Array[String] = []
var assertions: int = 0


func check(cond: bool, msg: String) -> void:
	assertions += 1
	if not cond:
		failures.append(msg)


func check_eq(actual: Variant, expected: Variant, msg: String) -> void:
	assertions += 1
	if not (actual == expected):
		failures.append("%s (기대 %s, 실제 %s)" % [msg, str(expected), str(actual)])


func check_near(actual: float, expected: float, tol: float, msg: String) -> void:
	assertions += 1
	if absf(actual - expected) > tol:
		failures.append("%s (기대 %.9f ± %s, 실제 %.9f)" % [msg, expected, str(tol), actual])
