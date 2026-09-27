class_name OverlayMenu
extends Control
## 반투명 배경 위 가운데 정렬된 제목·본문·버튼. 일시정지 메뉴와 결과 화면이 공용으로 쓴다.

signal action(id: StringName)

var _title: Label = null
var _body: Label = null
var _buttons: HBoxContainer = null


func _ready() -> void:
	UiTheme.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.62)
	UiTheme.full_rect(bg)
	add_child(bg)
	var center: CenterContainer = CenterContainer.new()
	UiTheme.full_rect(center)
	add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)
	_title = UiTheme.label("", 40, UiTheme.COLOR_ACCENT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_body = UiTheme.label("", 20)
	box.add_child(_body)
	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 16)
	box.add_child(_buttons)


## buttons: [[id, 표시 문자열], ...]
func present(title: String, body: String, buttons: Array) -> void:
	_title.text = title
	_body.text = body
	_body.visible = not body.is_empty()
	for c: Node in _buttons.get_children():
		c.queue_free()
	var first: Button = null
	for pair: Array in buttons:
		var b: Button = Button.new()
		b.text = pair[1]
		b.custom_minimum_size = Vector2(180, 52)
		var id: StringName = pair[0]
		b.pressed.connect(func() -> void: action.emit(id))
		_buttons.add_child(b)
		if first == null:
			first = b
	visible = true
	if first != null:
		first.call_deferred("grab_focus")
