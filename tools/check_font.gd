extends SceneTree
## 校验运行时像素字体是否覆盖项目里出现的所有字符。
## 缺字会显示成方块，所以新增文案后必须跑一次这个检查。
## 用法：Godot --headless --path . --script res://tools/check_font.gd [字体路径]

const DEFAULT_FONT := "res://assets/fonts/fusion_pixel_12px_zh_cn.ttf"
const SOURCES: Array[String] = [
	"res://scripts",
	"res://scenes",
	"res://localization",
]
const EXTRA_FILES: Array[String] = ["res://project.godot"]
const EXTENSIONS: Array[String] = ["gd", "tscn", "po", "godot"]
## 与 tools/subset_font.py 的兜底字符集保持一致
const FALLBACK := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz .,:;!?+-*/%()[]{}<>|_=#&@'\"`~\\×÷—…、，。！？：；“”‘’（）《》【】·￥$£¥°"


func _initialize() -> void:
	var path := DEFAULT_FONT
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		path = args[0]
	var f: Font = load(path)
	if f == null:
		print("FAIL 字体加载失败: ", path)
		quit(1)
		return
	print("字体名: ", f.get_font_name())
	var chars := _collect_chars()
	var missing := ""
	for i in chars.length():
		var c := chars[i]
		if not f.has_char(c.unicode_at(0)):
			missing += c
	print("项目字符数: ", chars.length())
	if missing != "":
		print("FAIL 缺失字形: ", missing)
		quit(1)
		return
	print("PASS 字形覆盖完整")
	print("标题尺寸(12px): ", f.get_string_size("SCRATCH TO BILLIONS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12))
	quit()


## 收集项目文本里出现过的所有字符（与 tools/subset_font.py 口径一致）
func _collect_chars() -> String:
	var chars := {}
	_add_text(chars, FALLBACK)
	for dir_path in SOURCES:
		_scan_dir(chars, dir_path)
	for file_path in EXTRA_FILES:
		_add_file(chars, file_path)
	var keys := chars.keys()
	keys.sort()
	var out := ""
	for key in keys:
		out += key
	return out


func _scan_dir(chars: Dictionary, dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := dir_path.path_join(name)
		if dir.current_is_dir():
			if not name.begins_with("."):
				_scan_dir(chars, full)
		elif name.get_extension() in EXTENSIONS:
			_add_file(chars, full)
		name = dir.get_next()
	dir.list_dir_end()


func _add_file(chars: Dictionary, file_path: String) -> void:
	if not FileAccess.file_exists(file_path):
		return
	_add_text(chars, FileAccess.get_file_as_string(file_path))


func _add_text(chars: Dictionary, text: String) -> void:
	for i in text.length():
		var c := text[i]
		if c.strip_edges() != "" or c == " ":
			chars[c] = true
