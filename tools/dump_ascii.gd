extends SceneTree
## 把截图的指定区域转成 ASCII 字符画，便于文本环境核对渲染。
## 用法：Godot --headless --path . --script res://tools/dump_ascii.gd -- res://debug/win.png 360 230 560 90 6
## 后续参数：图片路径 x y w h step(默认6)

const COLOR_CHARS := [
	{"c": Color8(20, 22, 28), "ch": "#"},      # 墨
	{"c": Color8(26, 27, 34), "ch": "#"},      # 顶栏底
	{"c": Color8(125, 28, 34), "ch": "-"},     # 深红
	{"c": Color8(200, 16, 46), "ch": "-"},     # 正红
	{"c": Color8(232, 92, 74), "ch": "-"},     # 亮红
	{"c": Color8(232, 163, 61), "ch": "o"},    # 金
	{"c": Color8(166, 106, 31), "ch": "o"},    # 暗金
	{"c": Color8(255, 216, 102), "ch": "*"},   # 亮金
	{"c": Color8(255, 243, 196), "ch": "*"},   # 金高光
	{"c": Color8(244, 246, 248), "ch": "s"},   # 银亮
	{"c": Color8(201, 205, 211), "ch": "s"},   # 银
	{"c": Color8(150, 156, 165), "ch": "s"},   # 银暗
	{"c": Color8(98, 103, 111), "ch": "s"},    # 银深
	{"c": Color8(250, 246, 236), "ch": "."},   # 纸白
	{"c": Color8(228, 217, 192), "ch": "."},   # 暗纸
	{"c": Color8(47, 169, 140), "ch": "j"},    # 青
	{"c": Color8(138, 158, 180), "ch": "x"},   # 钢
	{"c": Color8(214, 228, 240), "ch": "X"},   # 钢亮
	{"c": Color8(242, 200, 158), "ch": "f"},   # 肤
	{"c": Color8(198, 150, 108), "ch": "f"},   # 肤暗
]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var path := "res://debug/win.png" if args.is_empty() else args[0]
	var rect := Rect2i(0, 0, 640, 360)
	if args.size() >= 5:
		rect = Rect2i(int(args[1]), int(args[2]), int(args[3]), int(args[4]))
	var step := 6
	if args.size() >= 6:
		step = int(args[5])
	var img := Image.load_from_file(path)
	if img == null:
		print("FAIL 无法加载 ", path)
		quit(1)
		return
	var y1 := mini(rect.position.y + rect.size.y, img.get_height())
	var x1 := mini(rect.position.x + rect.size.x, img.get_width())
	for y in range(rect.position.y, y1, step):
		var line := ""
		for x in range(rect.position.x, x1, step):
			line += _char_for(img.get_pixel(x, y))
		print(line)
	quit()


func _char_for(c: Color) -> String:
	var best_ch := ""
	var best_d := 999.0
	for entry in COLOR_CHARS:
		var p: Color = entry.c
		var d := Vector3(c.r - p.r, c.g - p.g, c.b - p.b).length()
		if d < best_d:
			best_d = d
			best_ch = entry.ch
	if best_d < 0.08:
		return best_ch
	# 未匹配：按明暗粗略归类
	var lum := (c.r + c.g + c.b) / 3.0
	if lum < 0.3:
		return "#"
	if lum > 0.85:
		return "."
	return "+"
