class_name MainMenu
extends Control
## 시작 화면: 네 주공 중 하나를 선택한다(마우스 또는 1~4 키).

signal martial_selected(id: StringName)

var _content: GameContent = null


func setup(content: GameContent) -> void:
	_content = content


func _ready() -> void:
	UiTheme.full_rect(self)
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.07, 0.06, 0.07)
	UiTheme.full_rect(bg)
	add_child(bg)

	var center: CenterContainer = CenterContainer.new()
	UiTheme.full_rect(center)
	add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	box.add_child(UiTheme.label("만법귀종: 혈겁", 44, UiTheme.COLOR_ACCENT))
	box.add_child(UiTheme.label("M0 전투 실험실 — 주공을 고르세요", 22, UiTheme.COLOR_DIM))

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	box.add_child(grid)
	for i: int in range(_content.martial_order.size()):
		var id: StringName = _content.martial_order[i]
		var b: Button = Button.new()
		b.text = _describe(i + 1, _content.martial(id))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(420, 120)
		b.pressed.connect(func() -> void: martial_selected.emit(id))
		grid.add_child(b)
		if i == 0:
			b.call_deferred("grab_focus")

	box.add_child(UiTheme.label("이동 WASD/방향키 · 경공 Space · 일시정지 Esc", 18, UiTheme.COLOR_DIM))
	if OS.is_debug_build():
		box.add_child(UiTheme.label("디버그 빌드: F1 판정 표시 · F2~F9 실험 조작(게임 화면에서 F1로 목록 확인)", 16, UiTheme.COLOR_DIM))


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var idx: int = -1
	match key.physical_keycode:
		KEY_1: idx = 0
		KEY_2: idx = 1
		KEY_3: idx = 2
		KEY_4: idx = 3
	if idx >= 0 and idx < _content.martial_order.size():
		get_viewport().set_input_as_handled()
		martial_selected.emit(_content.martial_order[idx])


static func _describe(n: int, m: MartialDefinition) -> String:
	var fam: String = ["검", "도", "창", "권"][m.family]
	var shape: String = ""
	if m.shape.kind == ShapeDef.Kind.SECTOR:
		shape = "전방 %d° · %s칸" % [int(m.shape.angle_deg_total), _num(m.shape.radius)]
	else:
		shape = "전방 %s칸 초과~%s칸 · 폭 %s칸" % [_num(m.shape.x_min_exclusive), _num(m.shape.x_max), _num(m.shape.half_width * 2.0)]
	var extra: String = " · 방어 +%d" % int(m.passive_defense) if m.passive_defense > 0.0 else ""
	return "[%d] %s (%s)\n피해 %s · 간격 %s초 · 내공 %s · 최대 %d명\n%s%s" % [
		n, m.display_name, fam, _num(m.damage), _num(m.interval), _num(m.mp_cost), m.max_targets, shape, extra]


static func _num(v: float) -> String:
	return str(snappedf(v, 0.01)).trim_suffix(".0")
