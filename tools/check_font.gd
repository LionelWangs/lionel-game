extends SceneTree
## 校验像素字体的中文字形覆盖。
## 用法：Godot --headless --path . --script res://tools/check_font.gd

func _initialize() -> void:
	var path := "res://assets/fonts/fusion_pixel_12px_zh_cn.ttf"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		path = args[0]
	var f: Font = load(path)
	if f == null:
		print("FAIL 字体加载失败: ", path)
		quit(1)
		return
	var sets := {
		"中文": "刮成百亿富翁余额本期头奖池已张累计中最大单笔票面元概率返还率",
		"英文与符号": "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!?.,:;/-_%()|+&#'\" ",
	}
	print("字体名: ", f.get_font_name())
	for key in sets:
		var missing := ""
		var chars: String = sets[key]
		for i in chars.length():
			if not f.has_char(chars[i].unicode_at(0)):
				missing += chars[i]
		print("%s 缺失字形: %s" % [key, missing if missing != "" else "无"])
	print("标题尺寸(12px): ", f.get_string_size("SCRATCH TO BILLIONS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12))
	quit()
