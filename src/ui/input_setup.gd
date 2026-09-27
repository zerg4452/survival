class_name InputSetup
extends RefCounted
## 입력 액션 등록(GAME_DESIGN 3장: WASD/방향키 이동, Space 경공, Esc 일시정지).
## 물리 키 코드를 써서 키보드 배열과 무관하게 같은 위치의 키로 동작한다.

const BINDINGS: Dictionary[StringName, Array] = {
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"move_up": [KEY_W, KEY_UP],
	&"move_down": [KEY_S, KEY_DOWN],
	&"dash": [KEY_SPACE],
	&"pause": [KEY_ESCAPE],
}


static func ensure_actions() -> void:
	for action: StringName in BINDINGS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: int in BINDINGS[action]:
			var ev: InputEventKey = InputEventKey.new()
			ev.physical_keycode = key as Key
			InputMap.action_add_event(action, ev)
