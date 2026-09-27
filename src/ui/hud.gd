class_name Hud
extends Control
## 전투 HUD(GAME_DESIGN 15장의 M0 부분)와 디버그 정보 패널.

var _title: Label = null
var _hp_bar: ProgressBar = null
var _hp_label: Label = null
var _mp_bar: ProgressBar = null
var _mp_label: Label = null
var _dash_label: Label = null
var _enemy_label: Label = null
var _debug_badge: Label = null
var _debug_panel: Label = null


func _ready() -> void:
	UiTheme.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(16, 16)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	_title = UiTheme.label("", 22, UiTheme.COLOR_ACCENT)
	box.add_child(_title)
	_hp_label = UiTheme.label("")
	box.add_child(_hp_label)
	_hp_bar = _bar(Color(0.8, 0.25, 0.22))
	box.add_child(_hp_bar)
	_mp_label = UiTheme.label("")
	box.add_child(_mp_label)
	_mp_bar = _bar(Color(0.3, 0.55, 0.9))
	box.add_child(_mp_bar)
	_dash_label = UiTheme.label("")
	box.add_child(_dash_label)
	_enemy_label = UiTheme.label("")
	box.add_child(_enemy_label)
	_debug_badge = UiTheme.label("DEBUG 조작 사용됨", 18, UiTheme.COLOR_DANGER)
	box.add_child(_debug_badge)

	_debug_panel = UiTheme.label("", 16, UiTheme.COLOR_TEXT)
	_debug_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_debug_panel.offset_left = -430
	_debug_panel.offset_right = -16
	_debug_panel.offset_top = 16
	_debug_panel.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_debug_panel)


func refresh(state: RunState, debug_text: String) -> void:
	var p: PlayerState = state.player
	var t: int = int(state.sim_time())
	_title.text = "%s   %02d:%02d" % [state.main_martial.definition.display_name, floori(t / 60.0), t % 60]
	_hp_label.text = "체력 %d / %d" % [int(ceilf(maxf(p.hp, 0.0))), int(p.max_hp)]
	_hp_bar.max_value = p.max_hp
	_hp_bar.value = maxf(p.hp, 0.0)
	_mp_label.text = "내공 %d / %d" % [int(floorf(p.mp)), int(p.max_mp)]
	_mp_bar.max_value = p.max_mp
	_mp_bar.value = p.mp
	if p.dash_charges > 0:
		_dash_label.text = "경공 준비 [Space]"
	else:
		_dash_label.text = "경공 %.1f초" % p.dash_recharge_remaining
	var total: int = state.enemies.size()
	var active: int = state.active_enemy_count()
	_enemy_label.text = "적 %d (+%d 예고) · 처치 %d" % [active, total - active, state.stats.kills]
	_debug_badge.visible = state.debug_used
	_debug_panel.visible = not debug_text.is_empty()
	_debug_panel.text = debug_text


static func _bar(color: Color) -> ProgressBar:
	var b: ProgressBar = ProgressBar.new()
	b.custom_minimum_size = Vector2(280, 14)
	b.show_percentage = false
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = color
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.14, 0.15)
	b.add_theme_stylebox_override("fill", fill)
	b.add_theme_stylebox_override("background", bg)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b
