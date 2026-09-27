class_name InputLatch
extends RefCounted
## 누르는 순간이 중요한 입력의 래치(D-003).
## 틱이 0번 도는 프레임에 누른 입력은 다음 틱에서, 여러 틱이 도는 프레임에서는 첫 틱에서만 소비된다.

var _dash: bool = false


func press_dash() -> void:
	_dash = true


func consume_dash() -> bool:
	var v: bool = _dash
	_dash = false
	return v


func clear() -> void:
	_dash = false
