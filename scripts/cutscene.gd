extends Node2D
## 数据驱动的过场：章节卡片 + 打字机字幕 + 轻微镜头漂移。

const TYPE_SPEED := 36.0

var _beats: Array = []
var _index := -1
var _typing := false
var _revealed := 0.0
var _tick_acc := 0.0
var _time := 0.0
var _pan_t := 0.0
var _pan_to := Vector2.ZERO
var _shot := ""
var _auto := false
var _auto_t := 0.0

var _bg: TextureRect
var _panel: ColorRect
var _text: Label
var _chapter_big: Label
var _chapter_sub: Label
var _arrow: Sprite2D
var _tick: AudioStreamPlayer


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot"):
			_shot = arg
	if _shot != "":
		print("CUTSCENE ready (shot)")
	_beats = SceneDirector.cutscene_beats
	if _beats.is_empty():
		_beats = Story.prologue()
	_build()
	Ui.ignore_decorative(self)
	if _shot == "--shot-flow":
		print("FLOW: cutscene start, beats=", _beats.size())
		_auto = true
		DisplayServer.window_move_to_foreground()
		_next_beat()
	elif _shot != "":
		DisplayServer.window_move_to_foreground()
		_shot_run()
	else:
		_next_beat()


func _build() -> void:
	_bg = TextureRect.new()
	_bg.size = Vector2(640, 360)
	add_child(_bg)

	var top := ColorRect.new()
	top.color = Color8(10, 8, 12)
	top.size = Vector2(640, 44)
	add_child(top)

	_panel = ColorRect.new()
	_panel.color = Color8(16, 12, 18, 0.94)
	_panel.position = Vector2(0, 248)
	_panel.size = Vector2(640, 112)
	add_child(_panel)

	_text = Ui.make_label(self, "", Vector2(28, 262), 24, PixelArt.C_PAPER)
	_text.size = Vector2(584, 88)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_constant_override("line_spacing", 6)

	_chapter_big = Ui.make_label(self, "", Vector2(0, 128), 36, PixelArt.C_GOLD_LIGHT)
	_chapter_big.size = Vector2(640, 48)
	_chapter_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_big.add_theme_constant_override("shadow_offset_x", 2)
	_chapter_big.add_theme_constant_override("shadow_offset_y", 2)

	_chapter_sub = Ui.make_label(self, "", Vector2(0, 186), 24, PixelArt.C_PAPER)
	_chapter_sub.size = Vector2(640, 32)
	_chapter_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_arrow = Sprite2D.new()
	_arrow.texture = ImageTexture.create_from_image(_arrow_image())
	_arrow.position = Vector2(596, 340)
	_arrow.visible = false
	add_child(_arrow)

	var skip := Ui.make_button(self, tr("SKIP"), Vector2(540, 8), Vector2(88, 30))
	skip.pressed.connect(_finish)

	_tick = AudioStreamPlayer.new()
	_tick.stream = AudioFactory.make_tick()
	_tick.volume_db = -20.0
	add_child(_tick)

	_set_chapter_visible(false)


func _process(delta: float) -> void:
	_time += delta
	_pan_t = minf(1.0, _pan_t + delta / 5.0)
	_bg.position = (_pan_to * _pan_t).round()
	if _typing:
		_revealed += TYPE_SPEED * delta
		var total := _text.text.length()
		_text.visible_characters = int(_revealed)
		if int(_revealed) >= total:
			_typing = false
			_arrow.visible = true
		else:
			_tick_acc += delta
			if _tick_acc >= 0.09:
				_tick_acc = 0.0
				_tick.play()
	if _arrow.visible:
		_arrow.modulate.a = 0.35 + 0.65 * (0.5 + 0.5 * sin(_time * 6.0))
	if _auto and not SceneDirector.is_busy():
		_auto_t += delta
		if _auto_t >= 0.25:
			_auto_t = 0.0
			_advance()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_finish()
		elif event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_advance()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
	elif event is InputEventScreenTouch and event.pressed:
		_advance()


func _advance() -> void:
	if SceneDirector.is_busy():
		return
	if _typing:
		_typing = false
		_text.visible_characters = -1
		_arrow.visible = true
		return
	_next_beat()


func _next_beat() -> void:
	_index += 1
	if _shot != "":
		print("FLOW: beat ", _index)
	if _index >= _beats.size():
		_finish()
		return
	var beat: Dictionary = _beats[_index]
	_bg.texture = ImageTexture.create_from_image(SceneArt.by_id(beat.get("art", "dark")))
	_bg.position = Vector2.ZERO
	_pan_t = 0.0
	_pan_to = Vector2(randi_range(-6, 6), randi_range(-6, 0))
	if beat.get("kind", "line") == "chapter":
		_set_chapter_visible(true)
		_chapter_big.text = tr(beat.get("chapter", ""))
		_chapter_sub.text = tr(beat.get("title", ""))
		_text.text = ""
		_typing = false
		_arrow.visible = true
	else:
		_set_chapter_visible(false)
		_text.text = tr(beat.get("text", ""))
		_text.visible_characters = 0
		_revealed = 0.0
		_tick_acc = 0.0
		_typing = true
		_arrow.visible = false


func _set_chapter_visible(visible_now: bool) -> void:
	_chapter_big.visible = visible_now
	_chapter_sub.visible = visible_now
	_panel.visible = not visible_now
	_text.visible = not visible_now


func _finish() -> void:
	if SceneDirector.is_busy():
		return
	if _shot != "":
		print("FLOW: cutscene finish")
	_auto = false
	SceneDirector.finish_cutscene()


func _arrow_image() -> Image:
	var img := Image.create_empty(10, 6, false, Image.FORMAT_RGBA8)
	for y in 6:
		var w := 10 - y * 2
		if w <= 0:
			continue
		var x0 := (10 - w) / 2
		for x in range(x0, x0 + w):
			img.set_pixel(x, y, PixelArt.C_GOLD_LIGHT)
	return img


## 截图自检：直接跳到第一条正文并完整显示
func _shot_run() -> void:
	await get_tree().create_timer(0.5).timeout
	_next_beat()
	await get_tree().create_timer(0.15).timeout
	_next_beat()
	_typing = false
	_text.visible_characters = -1
	_arrow.visible = true
	await get_tree().create_timer(0.35).timeout
	await SceneDirector.save_shot("intro")
