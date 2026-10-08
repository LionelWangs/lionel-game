class_name ScratchCard
extends Node2D
## 一张票：票面底层 + 银色涂层 + 4x4 像素块擦除。支持 1x1 ~ 9x9 网格。

signal scratch_progress(ratio: float)
signal reveal_finished(result: Dictionary)

const W := 160
const H := 240
const BLOCK := 4
const GRID_W := W / BLOCK
const GRID_H := H / BLOCK
const REVEAL_THRESHOLD := 0.45
const AREA := Rect2i(12, 40, 136, 136)

static var _base_cache: Dictionary = {}
static var _coat_cache: Image = null
static var _symbol_cache: Dictionary = {}

var result: Dictionary = {}
var revealed := false
var scratching := false
var progress := 0.0
var brush_radius := 7.0
var auto_rate := 0.0
var auto_instant := false

var _grid := 3
var _cells: Array = []
var _win_line: Dictionary = {}
var _auto_acc := 0.0
var _instant_done := false

var _base_img: Image
var _coat_img: Image
var _base_tex: ImageTexture
var _coat_tex: ImageTexture
var _mask := PackedByteArray()
var _scratched_count := 0
var _coat_dirty := false

var _auto_reveal := false
var _auto_queue: Array[int] = []

var _noise_player: AudioStreamPlayer
var _drag_speed := 0.0


func setup(board: Dictionary, radius := 7.0, auto_speed := 0.0, instant := false) -> void:
	result = board
	brush_radius = radius
	auto_rate = auto_speed
	auto_instant = instant
	_grid = int(board.get("grid", 3))
	_cells = board.get("cells", [])
	_win_line = board.get("line", {})

	_mask.resize(GRID_W * GRID_H)
	_mask.fill(0)

	_base_img = base_template(_grid).duplicate()
	_draw_face()
	_coat_img = coat_template().duplicate()

	_base_tex = ImageTexture.create_from_image(_base_img)
	_coat_tex = ImageTexture.create_from_image(_coat_img)

	var base_sprite := Sprite2D.new()
	base_sprite.texture = _base_tex
	base_sprite.centered = false
	add_child(base_sprite)

	var coat_sprite := Sprite2D.new()
	coat_sprite.texture = _coat_tex
	coat_sprite.centered = false
	add_child(coat_sprite)

	_noise_player = AudioStreamPlayer.new()
	_noise_player.stream = AudioFactory.make_scratch_loop()
	_noise_player.volume_db = -60.0
	add_child(_noise_player)
	_noise_player.play()


func _process(delta: float) -> void:
	if _coat_dirty:
		_coat_tex.update(_coat_img)
		_coat_dirty = false

	if _auto_reveal and not _auto_queue.is_empty():
		var per_frame := maxi(1, _auto_queue.size() / 14)
		for i in per_frame:
			if _auto_queue.is_empty():
				break
			var idx: int = _auto_queue.pop_back()
			var bx := idx % GRID_W
			var by := int(idx / GRID_W)
			_erase_block(bx, by, true)
		progress = float(_scratched_count) / float(GRID_W * GRID_H)
		scratch_progress.emit(progress)
		if _auto_queue.is_empty():
			_finish_reveal()

	if not revealed and not _auto_reveal:
		if auto_instant and not _instant_done:
			_instant_done = true
			_begin_auto_reveal()
		elif auto_rate > 0.0:
			_auto_acc += auto_rate / 100.0 * float(GRID_W * GRID_H) * delta
			var block_count := int(_auto_acc)
			if block_count > 0:
				_auto_acc -= float(block_count)
				var changed := false
				for _i in block_count:
					changed = _erase_block(randi_range(0, GRID_W - 1), randi_range(0, GRID_H - 1)) or changed
				if changed:
					_after_erase()

	if _noise_player:
		var target_db := -60.0
		if scratching and not _auto_reveal and _drag_speed > 0.8:
			target_db = -20.0 + clampf(_drag_speed, 0.0, 24.0) * 0.5
		_noise_player.volume_db = lerpf(_noise_player.volume_db, target_db, clampf(delta * 12.0, 0.0, 1.0))
		_noise_player.pitch_scale = clampf(0.85 + _drag_speed * 0.025, 0.85, 1.8)
	_drag_speed = lerpf(_drag_speed, 0.0, clampf(delta * 9.0, 0.0, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if revealed or _auto_reveal:
		return
	# 触摸屏：手指按下 / 拖动 / 抬起
	if event is InputEventScreenTouch:
		if event.pressed:
			var tp := to_local(event.position)
			if _hit(tp):
				scratching = true
				erase_at(tp)
		else:
			scratching = false
	elif event is InputEventScreenDrag:
		if scratching:
			_drag_speed = event.relative.length()
			erase_at(to_local(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var p := to_local(event.position)
			if _hit(p):
				scratching = true
				erase_at(p)
		else:
			scratching = false
	elif event is InputEventMouseMotion and scratching:
		_drag_speed = event.relative.length()
		erase_at(to_local(event.position))


func erase_at(p: Vector2) -> void:
	var radius := brush_radius
	var bx0 := int(floor((p.x - radius) / BLOCK))
	var bx1 := int(floor((p.x + radius) / BLOCK))
	var by0 := int(floor((p.y - radius) / BLOCK))
	var by1 := int(floor((p.y + radius) / BLOCK))
	var changed := false
	for by in range(by0, by1 + 1):
		for bx in range(bx0, bx1 + 1):
			if bx < 0 or by < 0 or bx >= GRID_W or by >= GRID_H:
				continue
			var center := Vector2(bx * BLOCK + BLOCK * 0.5, by * BLOCK + BLOCK * 0.5)
			if center.distance_to(p) <= radius and randf() < 0.92:
				changed = _erase_block(bx, by) or changed
	if changed:
		_after_erase()


## 供截图验证 / 调试使用
func debug_scratch(ratio: float) -> void:
	var target := int(GRID_W * GRID_H * ratio)
	var guard := 0
	while _scratched_count < target and guard < 40000:
		guard += 1
		_erase_block(randi_range(2, GRID_W - 3), randi_range(2, GRID_H - 3))
	_after_erase()


## 跳过逐帧清屏动画，立即结算（供截图使用）
func debug_reveal_now() -> void:
	_auto_queue.clear()
	for idx in GRID_W * GRID_H:
		if _mask[idx] == 0:
			_erase_block(idx % GRID_W, int(idx / GRID_W), true)
	_auto_reveal = false
	progress = 1.0
	scratch_progress.emit(1.0)
	_finish_reveal()


func _erase_block(bx: int, by: int, clean := false) -> bool:
	var idx := by * GRID_W + bx
	if _mask[idx] == 1:
		return false
	_mask[idx] = 1
	_scratched_count += 1
	for py in range(by * BLOCK, by * BLOCK + BLOCK):
		for px in range(bx * BLOCK, bx * BLOCK + BLOCK):
			# 留一点碎屑，刮痕不至于太干净
			if not clean and (px * 7 + py * 13) % 23 == 0:
				continue
			_coat_img.set_pixel(px, py, Color(0, 0, 0, 0))
	_coat_dirty = true
	return true


func _after_erase() -> void:
	progress = float(_scratched_count) / float(GRID_W * GRID_H)
	scratch_progress.emit(progress)
	if not _auto_reveal and progress >= REVEAL_THRESHOLD:
		_begin_auto_reveal()


func _begin_auto_reveal() -> void:
	_auto_reveal = true
	scratching = false
	_auto_queue.clear()
	for idx in GRID_W * GRID_H:
		if _mask[idx] == 0:
			_auto_queue.append(idx)
	_auto_queue.shuffle()
	if _auto_queue.is_empty():
		_finish_reveal()


func _finish_reveal() -> void:
	if revealed:
		return
	revealed = true
	progress = 1.0
	scratch_progress.emit(1.0)
	if _noise_player:
		_noise_player.stop()
	reveal_finished.emit(result)


func _hit(p: Vector2) -> bool:
	return p.x >= -6.0 and p.y >= -6.0 and p.x <= float(W) + 6.0 and p.y <= float(H) + 6.0


## 网格单元位置（含间距，整体居中）
static func cell_rects(n: int) -> Array[Rect2i]:
	var gap := 4
	if n >= 7:
		gap = 2
	elif n >= 5:
		gap = 3
	var cell := int(floor(float(AREA.size.x - gap * (n - 1)) / float(n)))
	var total := cell * n + gap * (n - 1)
	var ox := AREA.position.x + int((AREA.size.x - total) / 2.0)
	var oy := AREA.position.y + int((AREA.size.y - total) / 2.0)
	var rects: Array[Rect2i] = []
	for r in n:
		for c in n:
			rects.append(Rect2i(ox + c * (cell + gap), oy + r * (cell + gap), cell, cell))
	return rects


func _draw_face() -> void:
	var rects := cell_rects(_grid)
	var cell := rects[0].size.x
	var margin := 2 if cell >= 24 else 1
	var sym_size := maxi(3, cell - margin * 2)
	for i in rects.size():
		var rect: Rect2i = rects[i]
		var sym := int(_cells[i]) if i < _cells.size() else -1
		var pos := rect.position + Vector2i(int((cell - sym_size) / 2.0), int((cell - sym_size) / 2.0))
		if sym >= 0:
			var art := symbol_art(sym, sym_size)
			_base_img.blend_rect(art, Rect2i(0, 0, sym_size, sym_size), pos)
		elif _grid <= 1:
			# 1x1 没中：一格空白加短横
			_fill_rect(_base_img, Rect2i(rect.position.x + cell / 2 - 8, rect.position.y + cell / 2, 16, 3), PixelArt.C_INK)
	if not _win_line.is_empty():
		for idx in _win_line.cells:
			_frame(_base_img, rects[int(idx)], PixelArt.C_GOLD_HI)
			_frame(_base_img, Rect2i(rects[int(idx)].position.x + 1, rects[int(idx)].position.y + 1, rects[int(idx)].size.x - 2, rects[int(idx)].size.y - 2), PixelArt.C_GOLD_HI)


## 把 16x16 图案缩放到指定边长（最近邻）
static func symbol_art(sym: int, size: int) -> Image:
	var key := "%d_%d" % [sym, size]
	if _symbol_cache.has(key):
		return _symbol_cache[key]
	var img := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	PixelArt.draw_sprite(img, PixelArt.SYMBOLS[sym], 0, 0)
	img.resize(size, size, Image.INTERPOLATE_NEAREST)
	_symbol_cache[key] = img
	return img


## 票面底图（供过场卡片特写复用）
static func base_image() -> Image:
	return base_template(3)


static func base_template(grid: int) -> Image:
	if _base_cache.has(grid):
		return _base_cache[grid]
	var img := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	img.fill(PixelArt.C_RED_DEEP)
	_fill_rect(img, Rect2i(2, 2, W - 4, H - 4), PixelArt.C_PAPER)
	_frame(img, Rect2i(4, 4, W - 8, H - 8), PixelArt.C_GOLD)

	# 票头
	_fill_rect(img, Rect2i(10, 10, W - 20, 20), PixelArt.C_RED)
	_frame(img, Rect2i(10, 10, W - 20, 20), PixelArt.C_GOLD_LIGHT)
	for x in range(20, W - 20, 8):
		img.set_pixel(x, 20, PixelArt.C_GOLD_HI)
	_fill_rect(img, Rect2i(10, 34, W - 20, 1), PixelArt.C_GOLD)

	# 刮奖格
	for rect in cell_rects(grid):
		_frame(img, rect, PixelArt.C_INK)
		_frame(img, Rect2i(rect.position.x + 1, rect.position.y + 1, rect.size.x - 2, rect.size.y - 2), PixelArt.C_GOLD_DARK)

	# 底部：奖级缩略图 + 条码
	_fill_rect(img, Rect2i(10, 184, W - 20, 1), PixelArt.C_GOLD)
	for i in 7:
		var ox := 10 + i * 20
		PixelArt.draw_sprite_shrunk(img, PixelArt.SYMBOLS[i], ox, 192, 2)
		_fill_rect(img, Rect2i(ox, 204, 8, 3), PixelArt.C_GOLD_DARK)
	for x in range(12, W - 12, 3):
		if (x * 7) % 5 < 2:
			_fill_rect(img, Rect2i(x, 216, 1, 14), PixelArt.C_INK)
	_base_cache[grid] = img
	return img


static func coat_template() -> Image:
	if _coat_cache != null:
		return _coat_cache
	var img := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var h := int((x * 73856093) ^ (y * 19349663)) % 1000
			var checker := (x + y) % 2 == 0
			var c: Color
			if h < 90:
				c = PixelArt.C_SILVER_4
			elif h < 280:
				c = PixelArt.C_SILVER_3
			elif checker:
				c = PixelArt.C_SILVER_1
			else:
				c = PixelArt.C_SILVER_2
			img.set_pixel(x, y, c)
	_coat_cache = img
	return img


static func _fill_rect(img: Image, rect: Rect2i, color: Color) -> void:
	var target := rect.intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if target.size.x <= 0 or target.size.y <= 0:
		return
	img.fill_rect(target, color)


static func _frame(img: Image, rect: Rect2i, color: Color) -> void:
	_fill_rect(img, Rect2i(rect.position.x, rect.position.y, rect.size.x, 1), color)
	_fill_rect(img, Rect2i(rect.position.x, rect.position.y + rect.size.y - 1, rect.size.x, 1), color)
	_fill_rect(img, Rect2i(rect.position.x, rect.position.y, 1, rect.size.y), color)
	_fill_rect(img, Rect2i(rect.position.x + rect.size.x - 1, rect.position.y, 1, rect.size.y), color)
