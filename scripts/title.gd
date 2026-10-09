extends Node2D
## 标题页：摊位夜景 + 主菜单。

const VERSION := "v0.1 DEMO"

var _buttons: Array[Button] = []
var _music_button: Button
var _lanterns: Array[Sprite2D] = []
var _lantern_base: Array[Vector2] = []
var _time := 0.0
var _selected := 0
var _shot := ""
var _version_label: Label
var _debug_panel: DebugPanel


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot"):
			_shot = arg
	_build_background()
	_build_logo()
	_build_menu()
	_build_ambience()
	Ui.ignore_decorative(self)
	# 调试面板：桌面按 ` / F1，移动端连点版本号 5 次
	_debug_panel = DebugPanel.attach(self, _shot == "--shot-debug")
	DebugPanel.bind_secret_toggle(_version_label, _debug_panel)
	Music.play("title")
	if _shot != "":
		DisplayServer.window_move_to_foreground()
		_run_shot()


func _process(delta: float) -> void:
	_time += delta
	for i in _lanterns.size():
		var sprite := _lanterns[i]
		var base := _lantern_base[i]
		sprite.position.x = round(base.x + sin(_time * 1.2 + float(i) * 1.7) * 2.0)


func _input(event: InputEvent) -> void:
	if SceneDirector.is_busy():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_UP:
				_step(-1)
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				_step(1)
				get_viewport().set_input_as_handled()
			KEY_L:
				_on_language()
				get_viewport().set_input_as_handled()
			KEY_M:
				_on_music()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				get_tree().quit()


func _step(dir: int) -> void:
	var n := _buttons.size()
	if n == 0:
		return
	var i := _selected
	for _k in n:
		i = ((i + dir) % n + n) % n
		if not _buttons[i].disabled:
			break
	_select(i)


func _select(index: int) -> void:
	var n := _buttons.size()
	if n == 0:
		return
	_selected = ((index % n) + n) % n
	if _buttons[_selected].disabled:
		return
	_buttons[_selected].grab_focus()


func _build_background() -> void:
	var bg := TextureRect.new()
	bg.texture = ImageTexture.create_from_image(SceneArt.stall_background(false))
	bg.size = Vector2(640, 360)
	add_child(bg)
	for i in 3:
		var sprite := Sprite2D.new()
		sprite.texture = ImageTexture.create_from_image(SceneArt.lantern_image())
		var base := Vector2(200.0 + float(i) * 120.0, 240.0)
		sprite.position = base
		add_child(sprite)
		_lanterns.append(sprite)
		_lantern_base.append(base)


func _build_logo() -> void:
	var title := Ui.make_label(self, tr("SCRATCH TO BILLIONS"), Vector2(0, 26), 36, PixelArt.C_GOLD_LIGHT)
	title.size = Vector2(640, 46)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	var sub := Ui.make_label(self, tr("EVERY FORTUNE STARTS WITH ONE SCRATCH"), Vector2(0, 76), 12, PixelArt.C_PAPER)
	sub.size = Vector2(640, 16)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_version_label = Ui.make_label(self, tr(VERSION), Vector2(0, 336), 12, Color8(122, 127, 137))
	_version_label.size = Vector2(620, 16)
	_version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _build_menu() -> void:
	Ui.panel(self, Rect2(216, 92, 208, 252), Color8(26, 20, 26), PixelArt.C_GOLD_DARK)
	_add_button(tr("NEW GAME"), 100.0, _on_new_game)
	_add_button(tr("CONTINUE"), 148.0, _on_continue)
	_add_button(tr("LANGUAGE: %s") % _locale_name(), 196.0, _on_language)
	_music_button = _add_button(_music_label(), 244.0, _on_music)
	_add_button(tr("QUIT"), 292.0, _on_quit)
	_buttons[1].disabled = not GameState.has_save()
	_select(0)


func _locale_name() -> String:
	return "中文" if GameState.locale.begins_with("zh") else "EN"


func _music_label() -> String:
	return tr("MUSIC: %s") % (tr("ON") if Music.enabled else tr("OFF"))


func _on_music() -> void:
	GameState.music_on = Music.toggle()
	GameState.save()
	if _music_button:
		_music_button.text = _music_label()


func _on_language() -> void:
	if SceneDirector.is_busy():
		return
	GameState.toggle_locale()
	SceneDirector.goto_scene("res://scenes/title.tscn")


func _add_button(text: String, y: float, callback: Callable) -> Button:
	var b := Ui.make_button(self, text, Vector2(232, y), Vector2(176, 40))
	b.pressed.connect(callback)
	b.focus_entered.connect(_on_focus.bind(_buttons.size()))
	_buttons.append(b)
	return b


func _on_focus(index: int) -> void:
	if not _buttons[index].disabled:
		_selected = index


func _build_ambience() -> void:
	var px := Image.create_empty(2, 2, false, Image.FORMAT_RGBA8)
	px.fill(PixelArt.C_GOLD_LIGHT)
	var coins := CPUParticles2D.new()
	coins.texture = ImageTexture.create_from_image(px)
	coins.amount = 18
	coins.lifetime = 6.0
	coins.preprocess = 5.0
	coins.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	coins.emission_rect_extents = Vector2(280, 8)
	coins.position = Vector2(320, 374)
	coins.direction = Vector2(0, -1)
	coins.spread = 24.0
	coins.initial_velocity_min = 8.0
	coins.initial_velocity_max = 26.0
	coins.gravity = Vector2(0, -4)
	coins.scale_amount_min = 1.0
	coins.scale_amount_max = 2.0
	coins.color = PixelArt.C_GOLD_LIGHT
	add_child(coins)


func _on_new_game() -> void:
	GameState.new_game()
	SceneDirector.play_cutscene(Story.prologue(), "res://scenes/game.tscn")


func _on_continue() -> void:
	if not GameState.load_save():
		return
	SceneDirector.goto_scene("res://scenes/game.tscn")


func _on_quit() -> void:
	print("TITLE quit")
	get_tree().quit()


## 截图自检：--shot-title 拍标题页，--shot-intro 进过场，其余交给游戏场景
func _run_shot() -> void:
	await get_tree().create_timer(0.6).timeout
	match _shot:
		"--shot-title":
			await SceneDirector.save_shot("title")
		"--shot-intro":
			SceneDirector.play_cutscene(Story.prologue(), "res://scenes/game.tscn")
		"--shot-flow":
			print("FLOW: title -> new game")
			_on_new_game()
		"--shot-skills":
			SceneDirector.goto_scene("res://scenes/skills.tscn")
		"--shot-almanac":
			SceneDirector.goto_scene("res://scenes/almanac.tscn")
		_:
			SceneDirector.goto_scene("res://scenes/game.tscn")
