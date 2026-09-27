class_name InputFrame
extends RefCounted
## 한 틱에 적용할 입력. 시뮬레이션은 Input 싱글턴이 아니라 이것만 읽는다.

var move: Vector2 = Vector2.ZERO
var dash_pressed: bool = false


static func make(p_move: Vector2, p_dash: bool = false) -> InputFrame:
	var f: InputFrame = InputFrame.new()
	f.move = p_move
	f.dash_pressed = p_dash
	return f
