class_name SceneArt
extends RefCounted
## 程序化像素场景：摊位夜景、卡片特写、暗场。

static var _cache: Dictionary = {}


static func by_id(id: String) -> Image:
	if _cache.has(id):
		return _cache[id]
	var img: Image
	match id:
		"stall":
			img = stall_background(true)
		"card":
			img = card_closeup()
		_:
			img = dark_background()
	_cache[id] = img
	return img


static func stall_background(with_lanterns := true) -> Image:
	var img := Image.create_empty(640, 360, false, Image.FORMAT_RGBA8)
	# 夜空与星
	rect(img, 0, 0, 640, 210, Color8(52, 18, 30))
	rect(img, 0, 120, 640, 90, Color8(62, 22, 34))
	for i in 120:
		var x := int(_hash(i * 3 + 1) % 640)
		var y := int(_hash(i * 7 + 5) % 130)
		var c := Color8(255, 243, 196) if _hash(i) % 3 == 0 else Color8(232, 163, 61)
		px(img, x, y, c)
	# 远景楼群
	var bx := -10
	while bx < 650:
		var w := 26 + int(_hash(bx + 7) % 54)
		var h := 26 + int(_hash(bx + 99) % 74)
		rect(img, bx, 210 - h, w, h, Color8(30, 12, 18))
		for wy in range(210 - h + 6, 204, 10):
			for wx in range(bx + 4, bx + w - 4, 8):
				if _hash(wx * 31 + wy * 17) % 5 == 0:
					px(img, wx, wy, Color8(166, 106, 31))
		bx += w + 6
	# 摊位背板与立柱
	rect(img, 150, 232, 340, 128, Color8(44, 22, 28))
	rect(img, 142, 224, 12, 136, Color8(74, 48, 30))
	rect(img, 486, 224, 12, 136, Color8(74, 48, 30))
	# 雨棚条纹
	var stripes := 18
	for i in 18:
		var c := Color8(200, 16, 46) if i % 2 == 0 else Color8(250, 246, 236)
		rect(img, 136 + i * stripes, 196, stripes, 28, c)
	# 雨棚齿边
	for i in 18:
		var sc := Color8(125, 28, 34) if i % 2 == 0 else Color8(228, 217, 192)
		rect(img, 136 + i * stripes + 5, 224, 8, 6, sc)
	# 招牌与吊绳
	rect(img, 232, 138, 176, 44, Color8(34, 12, 16))
	frame(img, 232, 138, 176, 44, Color8(232, 163, 61))
	rect(img, 250, 182, 1, 14, Color8(30, 20, 16))
	rect(img, 389, 182, 1, 14, Color8(30, 20, 16))
	# 柜台
	rect(img, 128, 296, 384, 18, Color8(96, 62, 38))
	rect(img, 128, 314, 384, 46, Color8(64, 38, 26))
	for i in 8:
		rect(img, 134 + i * 48, 314, 2, 46, Color8(44, 26, 18))
	# 票堆
	rect(img, 170, 286, 64, 10, Color8(250, 246, 236))
	rect(img, 176, 278, 54, 8, Color8(228, 217, 192))
	rect(img, 182, 272, 42, 6, Color8(250, 246, 236))
	# 金币
	disc(img, 430, 284, 12, Color8(232, 163, 61))
	disc(img, 430, 284, 9, Color8(255, 216, 102))
	rect(img, 426, 280, 8, 8, Color8(166, 106, 31))
	if with_lanterns:
		for lx in [200, 320, 440]:
			lantern_into(img, lx, 232)
	return img


static func card_closeup() -> Image:
	var img := dark_background()
	rect(img, 166, 6, 324, 354, Color8(10, 8, 12))
	var card := ScratchCard.base_image().duplicate() as Image
	card.resize(320, 480, Image.INTERPOLATE_NEAREST)
	img.blit_rect(card, Rect2i(0, 40, 320, 360), Vector2i(158, 0))
	return img


static func dark_background() -> Image:
	var img := Image.create_empty(640, 360, false, Image.FORMAT_RGBA8)
	rect(img, 0, 0, 640, 360, Color8(26, 18, 24))
	for y in range(0, 360, 2):
		for x in range(0, 640, 2):
			if (x * 7 + y * 13) % 11 == 0:
				px(img, x, y, Color8(34, 22, 30))
			var d := Vector2(x - 320, y - 180).length()
			if d > 300.0 and (x + y) % 3 == 0:
				px(img, x, y, Color8(18, 12, 18))
	return img


static func lantern_image() -> Image:
	var img := Image.create_empty(26, 34, false, Image.FORMAT_RGBA8)
	glow(img, 13, 20, 12, Color8(255, 216, 102), 0.4)
	rect(img, 12, 0, 2, 8, Color8(30, 20, 16))
	rect(img, 7, 6, 12, 3, Color8(20, 22, 28))
	rect(img, 5, 9, 16, 14, Color8(232, 163, 61))
	rect(img, 7, 11, 12, 10, Color8(255, 216, 102))
	rect(img, 7, 23, 12, 3, Color8(166, 106, 31))
	rect(img, 9, 26, 8, 2, Color8(20, 22, 28))
	return img


static func lantern_into(img: Image, cx: int, top: int) -> void:
	glow(img, cx, top + 16, 16, Color8(255, 216, 102), 0.35)
	rect(img, cx - 1, top - 8, 2, 8, Color8(30, 20, 16))
	rect(img, cx - 6, top - 2, 12, 3, Color8(20, 22, 28))
	rect(img, cx - 8, top + 1, 16, 16, Color8(232, 163, 61))
	rect(img, cx - 6, top + 3, 12, 12, Color8(255, 216, 102))
	rect(img, cx - 6, top + 17, 12, 3, Color8(166, 106, 31))
	rect(img, cx - 4, top + 20, 8, 2, Color8(20, 22, 28))


static func glow(img: Image, cx: int, cy: int, radius: int, color: Color, strength: float) -> void:
	for y in range(cy - radius, cy + radius + 1):
		for x in range(cx - radius, cx + radius + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var d := Vector2(x - cx, y - cy).length()
			if d > float(radius):
				continue
			if (x * 3 + y * 5 + int(d * 7.0)) % 6 >= 3:
				continue
			var base := img.get_pixel(x, y)
			var a := (1.0 - d / float(radius)) * strength
			img.set_pixel(x, y, base.lerp(color, a))


static func rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	var target := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if target.size.x <= 0 or target.size.y <= 0:
		return
	img.fill_rect(target, color)


static func frame(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	rect(img, x, y, w, 1, color)
	rect(img, x, y + h - 1, w, 1, color)
	rect(img, x, y, 1, h, color)
	rect(img, x + w - 1, y, 1, h, color)


static func disc(img: Image, cx: int, cy: int, radius: int, color: Color) -> void:
	for y in range(cy - radius, cy + radius + 1):
		for x in range(cx - radius, cx + radius + 1):
			if Vector2(x - cx, y - cy).length() <= float(radius):
				px(img, x, y, color)


static func px(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, color)


static func _hash(n: int) -> int:
	var v := n * 2654435761
	return int(abs(v)) % 1000003
