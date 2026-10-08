extends SceneTree
## 按行统计指定颜色的像素数量，用于定位 UI 元素的实际位置。
## 用法：Godot --headless --path . --script res://tools/row_hist.gd -- res://debug/jackpot.png FFF3C4 40
## 参数：图片路径 颜色hex 阈值(默认20)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("用法: -- res://debug/x.png FFF3C4 [阈值]")
		quit(1)
		return
	var img := Image.load_from_file(args[0])
	if img == null:
		print("FAIL 无法加载 ", args[0])
		quit(1)
		return
	var target := Color(args[1])
	var threshold := 20
	if args.size() >= 3:
		threshold = int(args[2])
	print("目标色 #", args[1], "  阈值 ", threshold)
	for y in range(0, img.get_height(), 2):
		var count := 0
		var xs := PackedInt32Array()
		for x in range(0, img.get_width(), 2):
			var c := img.get_pixel(x, y)
			if absf(c.r - target.r) < 0.03 and absf(c.g - target.g) < 0.03 and absf(c.b - target.b) < 0.03:
				count += 1
				xs.append(x)
		if count >= threshold:
			print("y=%4d  count=%4d  x范围 %d..%d" % [y, count, xs[0], xs[-1]])
	quit()
