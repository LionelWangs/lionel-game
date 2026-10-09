extends SceneTree
## 无头自检：刮擦工具的档位映射、图案差异与贴图缓存。

var _done := false


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true

	var ok := true
	ok = _check(ok, PixelArt.TOOLS.size() == 7, "工具档位共 %d 个" % PixelArt.TOOLS.size())
	ok = _check(ok, PixelArt.TOOL_NAMES.size() == PixelArt.TOOLS.size(), "名称数量与档位一致")
	ok = _check(ok, PixelArt.TOOL_ANCHORS.size() == PixelArt.TOOLS.size(), "着力点数量与档位一致")

	var shapes := {}
	for level in PixelArt.TOOLS.size():
		var name := PixelArt.tool_name_key(level)
		ok = _check(ok, PixelArt.tool_index(level) == level, "等级 %d -> %s" % [level, name])

		var img := PixelArt.tool_image(level)
		var opaque := 0
		var raw := ""
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.0:
					opaque += 1
				raw += "%02x%02x%02x%02x" % [
					int(c.r * 255.0), int(c.g * 255.0), int(c.b * 255.0), int(c.a * 255.0),
				]
		ok = _check(ok, opaque >= 24, "%s 有 %d 个可见像素" % [name, opaque])
		ok = _check(ok, not shapes.has(raw), "%s 图案与其他档位不同" % name)
		shapes[raw] = true

		var anchor := PixelArt.tool_anchor(level)
		ok = _check(ok, anchor.x >= 0.0 and anchor.x < 16.0 and anchor.y >= 0.0 and anchor.y < 16.0,
			"%s 着力点 %s 在贴图内" % [name, anchor])

	ok = _check(ok, PixelArt.tool_index(-3) == 0, "低于 0 级回落到手指")
	ok = _check(ok, PixelArt.tool_index(99) == 6, "超过满级回落到金铲子")
	ok = _check(ok, PixelArt.tool_texture(2) == PixelArt.tool_texture(2), "同一档位贴图命中缓存")
	ok = _check(ok, PixelArt.tool_texture(2) != PixelArt.tool_texture(3), "不同档位贴图不同")

	var last_size := 0
	for level in PixelArt.TOOLS.size():
		var name := PixelArt.tool_name_key(level)
		var scale := PixelArt.tool_cursor_scale(level)
		var cursor := PixelArt.tool_cursor_texture(level)
		var size := cursor.get_width()
		ok = _check(ok, size == 16 * scale, "%s 光标 %dx%d（x%d）" % [name, size, size, scale])
		ok = _check(ok, size >= last_size, "%s 光标不小于上一档" % name)
		last_size = size

		var hotspot := PixelArt.tool_cursor_hotspot(level)
		ok = _check(ok, hotspot.x >= 0.0 and hotspot.x < float(size)
			and hotspot.y >= 0.0 and hotspot.y < float(size),
			"%s 光标热点 %s 在贴图内" % [name, hotspot])
		ok = _check(ok, PixelArt.tool_touch_scale(level) >= 2,
			"%s 触屏贴图放大 %d 倍" % [name, PixelArt.tool_touch_scale(level)])

	ok = _check(ok, PixelArt.tool_cursor_texture(6).get_width() >= 64,
		"满级光标足够大：%dpx" % PixelArt.tool_cursor_texture(6).get_width())

	print("工具阶梯: " + " -> ".join(PixelArt.TOOL_NAMES))
	print("PASS 刮擦工具自检" if ok else "FAIL 刮擦工具自检")
	quit(0 if ok else 1)
	return true


func _check(ok: bool, condition: bool, label: String) -> bool:
	print("%s %s" % ["OK  " if condition else "BAD ", label])
	return ok and condition
