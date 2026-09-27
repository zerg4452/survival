extends Node
## 진입점: 콘텐츠를 읽고 메뉴와 게임 화면을 전환한다.
## 개발용 인자(-- 뒤): --autoplay=<주공 ID> --seconds=<초> --capture=<폴더>, --menu_capture=<png 경로>

var content: GameContent = null
var _theme: Theme = null
var _current: Node = null


func _ready() -> void:
	InputSetup.ensure_actions()
	_theme = UiTheme.build()
	content = ContentLoader.load_from_dir()
	if not content.is_ok():
		for e: String in content.errors:
			push_error(e)
		var l: Label = UiTheme.label("콘텐츠 로드 실패:\n" + "\n".join(content.errors), 18, UiTheme.COLOR_DANGER)
		l.theme = _theme
		add_child(l)
		return
	var args: Dictionary[String, String] = _parse_args()
	if args.has("autoplay"):
		var id: StringName = StringName(args["autoplay"])
		if content.martial(id) == null:
			push_error("알 수 없는 주공: %s" % id)
			get_tree().quit(2)
			return
		_start_game(id, args)
	else:
		_show_menu()
		if args.has("menu_capture"):
			_capture_menu(args["menu_capture"])


func _show_menu() -> void:
	var menu: MainMenu = MainMenu.new()
	menu.setup(content)
	menu.theme = _theme
	menu.martial_selected.connect(func(id: StringName) -> void: _start_game(id, {}))
	_swap(menu)


func _start_game(id: StringName, args: Dictionary[String, String]) -> void:
	var g: GameView = GameView.new()
	g.setup(content, id, _theme)
	if args.has("autoplay"):
		g.autoplay = true
		g.autoplay_seconds = float(args.get("seconds", "5"))
		g.capture_dir = args.get("capture", "")
		GameView.fixed_seed_enabled = true
	g.back_to_menu.connect(_show_menu)
	_swap(g)


func _swap(n: Node) -> void:
	if _current != null:
		_current.queue_free()
	_current = n
	add_child(n)


## 개발용: 메뉴 화면을 캡처하고 종료한다(--menu_capture=<png 경로>).
func _capture_menu(path: String) -> void:
	for i: int in range(3):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var err: Error = get_viewport().get_texture().get_image().save_png(path)
	print("캡처 %s (%s)" % [path, error_string(err)])
	get_tree().quit(0)


static func _parse_args() -> Dictionary[String, String]:
	var out: Dictionary[String, String] = {}
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
			out[kv[0]] = kv[1]
	return out
