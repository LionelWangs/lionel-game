extends SceneTree
## 截图自检：统计关键区域的颜色分布，验证涂层、符号与 UI 渲染。
## 用法：Godot --headless --path . --script res://tools/analyze_shot.gd -- res://debug/mid.png

const COLORS := {
	"银亮": Color8(244, 246, 248),
	"银": Color8(201, 205, 211),
	"银暗": Color8(150, 156, 165),
	"银深": Color8(98, 103, 111),
	"纸白": Color8(250, 246, 236),
	"正红": Color8(200, 16, 46),
	"深红": Color8(125, 28, 34),
	"亮红": Color8(232, 92, 74),
	"金": Color8(232, 163, 61),
	"亮金": Color8(255, 216, 102),
	"金高光": Color8(255, 243, 196),
	"墨": Color8(20, 22, 28),
}

const REGIONS := {
	"整图": Rect2i(0, 0, 1280, 720),
	"卡面": Rect2i(480, 88, 320, 480),
	"横幅": Rect2i(320, 232, 640, 88),
	"顶栏": Rect2i(0, 0, 1280, 56),
	"左面板": Rect2i(16, 72, 448, 504),
	"右面板": Rect2i(816, 72, 448, 504),
	"底栏": Rect2i(0, 592, 1280, 128),
}


func _initialize() -> void:
	var path := "res://debug/mid.png"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		path = args[0]
	var img := Image.load_from_file(path)
	if img == null:
		print("FAIL 无法加载 ", path)
		quit(1)
		return
	print("图: ", path, "  ", img.get_width(), "x", img.get_height())
	for region_name in REGIONS:
		_region(img, region_name, REGIONS[region_name])
	quit()


func _region(img: Image, name: String, rect: Rect2i) -> void:
	var total := 0
	var counts := {}
	var sum := Vector3.ZERO
	var x0 := maxi(rect.position.x, 0)
	var y0 := maxi(rect.position.y, 0)
	var x1 := mini(rect.position.x + rect.size.x, img.get_width())
	var y1 := mini(rect.position.y + rect.size.y, img.get_height())
	for y in range(y0, y1, 2):
		for x in range(x0, x1, 2):
			var c := img.get_pixel(x, y)
			total += 1
			sum += Vector3(c.r, c.g, c.b)
			for key in COLORS:
				var p: Color = COLORS[key]
				if absf(c.r - p.r) < 0.03 and absf(c.g - p.g) < 0.03 and absf(c.b - p.b) < 0.03:
					counts[key] = counts.get(key, 0) + 1
					break
	var avg := sum / float(maxi(total, 1))
	var parts := PackedStringArray()
	for key in COLORS:
		if counts.has(key):
			parts.append("%s %.1f%%" % [key, 100.0 * float(counts[key]) / float(maxi(total, 1))])
	print("  [%s] 平均色 #%02X%02X%02X  %s" % [
		name,
		int(avg.x * 255.0), int(avg.y * 255.0), int(avg.z * 255.0),
		"  ".join(parts),
	])
