extends Node2D
## 图鉴与生涯统计场景。

const CARD_W := 140.0
const CARD_H := 96.0
const GAP_X := 12.0
const GAP_Y := 8.0
const ORIGIN := Vector2(16, 48)

var _shot := ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot"):
			_shot = arg
	if _shot != "":
		# 截图自检数据，不写存档
		GameState.tickets = maxi(GameState.tickets, 42)
		GameState.total_won = maxi(GameState.total_won, 3250)
		GameState.best_win = maxi(GameState.best_win, 2000)
		GameState.level = maxi(GameState.level, 9)
		GameState.jackpots = maxi(GameState.jackpots, 1)
		GameState.near_miss_count = maxi(GameState.near_miss_count, 9)
		GameState.symbol_wins = {1: 12, 2: 6, 3: 3, 5: 1, 6: 1}
	_build()
	Ui.ignore_decorative(self)
	if _shot != "":
		DisplayServer.window_move_to_foreground()
		_run_shot()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color8(30, 22, 30)
	bg.size = Vector2(640, 360)
	add_child(bg)

	var title := Ui.make_label(self, tr("ALMANAC"), Vector2(0, 8), 24, PixelArt.C_GOLD_LIGHT)
	title.size = Vector2(640, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var back := Ui.make_button(self, tr("BACK"), Vector2(536, 8), Vector2(92, 28))
	back.pressed.connect(_back)

	for i in Prize.SYMBOL_NAMES.size():
		var col := i % 4
		var row := i / 4
		var pos := ORIGIN + Vector2(float(col) * (CARD_W + GAP_X), float(row) * (CARD_H + GAP_Y))
		var won := int(GameState.symbol_wins.get(i, 0))
		Ui.panel(self, Rect2(pos, Vector2(CARD_W, CARD_H)), Color8(40, 32, 42), PixelArt.C_GOLD_DARK)

		var icon := TextureRect.new()
		icon.texture = _symbol_texture(i)
		icon.position = pos + Vector2(10, 10)
		icon.size = Vector2(32, 32)
		if won == 0:
			icon.modulate = Color(0.35, 0.3, 0.34)
		add_child(icon)

		Ui.make_label(self, tr(Prize.SYMBOL_NAMES[i]), pos + Vector2(50, 12), 12, PixelArt.C_GOLD_LIGHT)
		var mult_text := tr("TOP") if i >= Tickets.LADDER_MULT.size() else "x%.0f" % Tickets.LADDER_MULT[i]
		Ui.make_label(self, mult_text, pos + Vector2(50, 32), 12, PixelArt.C_PAPER)
		var status := tr("WON x%d") % won if won > 0 else tr("NOT WON YET")
		var status_color := PixelArt.C_JADE if won > 0 else Color8(122, 127, 137)
		Ui.make_label(self, status, pos + Vector2(10, 72), 12, status_color)

	Ui.panel(self, Rect2(16, 264, 608, 80), Color8(40, 32, 42), PixelArt.C_GOLD_DARK)
	Ui.make_label(self, tr("CAREER"), Vector2(28, 272), 12, PixelArt.C_GOLD_LIGHT)
	var stats := Ui.make_label(self, "", Vector2(28, 292), 12, PixelArt.C_PAPER)
	stats.add_theme_constant_override("line_spacing", 4)
	stats.text = tr("SCRATCHED %d    TOTAL WON %s    BEST WIN %s    LEVEL %d\nJACKPOTS %d    NEAR MISSES %d    JACKPOT POOL %s") % [
		GameState.tickets,
		Ui.money(GameState.total_won),
		Ui.money(GameState.best_win),
		GameState.level,
		GameState.jackpots,
		GameState.near_miss_count,
		Ui.money(GameState.pool(GameState.ticket_grid)),
	]


func _symbol_texture(id: int) -> ImageTexture:
	var img := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	PixelArt.draw_sprite(img, PixelArt.SYMBOLS[id], 0, 0)
	img.resize(32, 32, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


func _back() -> void:
	if SceneDirector.is_busy():
		return
	if _shot == "":
		GameState.save()
	SceneDirector.goto_scene("res://scenes/game.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_back()


func _run_shot() -> void:
	await get_tree().create_timer(0.4).timeout
	await SceneDirector.save_shot("almanac")
