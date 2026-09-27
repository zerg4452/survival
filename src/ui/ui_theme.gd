class_name UiTheme
extends RefCounted
## 공용 테마. 한글 표시를 위해 운영체제의 시스템 폰트를 이름으로 지정한다.
## 폰트 파일을 프로젝트에 포함하지 않으므로 별도 라이선스 대상 자산이 없다(README 참조).

const FONT_NAMES: PackedStringArray = ["Malgun Gothic", "Apple SD Gothic Neo", "Noto Sans CJK KR", "NanumGothic", "sans-serif"]

const COLOR_TEXT: Color = Color(0.92, 0.9, 0.86)
const COLOR_DIM: Color = Color(0.65, 0.63, 0.6)
const COLOR_ACCENT: Color = Color(0.95, 0.75, 0.35)
const COLOR_DANGER: Color = Color(0.95, 0.35, 0.3)


static func build() -> Theme:
	var font: SystemFont = SystemFont.new()
	font.font_names = FONT_NAMES
	var t: Theme = Theme.new()
	t.default_font = font
	t.default_font_size = 20
	t.set_color("font_color", "Label", COLOR_TEXT)
	return t


static func label(text: String, size: int = 20, color: Color = COLOR_TEXT) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func full_rect(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
