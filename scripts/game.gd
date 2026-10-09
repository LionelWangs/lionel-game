extends Node2D
## 游戏主场景：手刮一张 100 元金鲤票，含涂层、粒子、开奖演出与奖池。

const PRICE := 100
const CARD_POS := Vector2(240, 44)
const WARMUP := ["coin", "star", "bell"]

const SFX_SMALL := "res://assets/audio/sfx/sfx-scratch.ogg"
const SFX_MEDIUM := "res://assets/audio/sfx/sfx-win-medium.ogg"
const SFX_JACKPOT := "res://assets/audio/sfx/sfx-win-jackpot.ogg"
const SFX_NEAR := "res://assets/audio/sfx/sfx-win-near.ogg"

var _display_money := 5000.0
var _rng := RandomNumberGenerator.new()
var _warmup_index := 0
var _force_next := ""
var _shake := 0.0
var _shot := ""
var _mobile := false

var _world: Node2D
var _card_holder: Node2D
var _card: ScratchCard
var _burst: CPUParticles2D
var _money_label: Label
var _stat_label: Label
var _jackpot_label: Label
var _info_label: Label
var _banner: Label
var _banner_tween: Tween
var _toast: Label
var _toast_tween: Tween
var _info2_label: Label
var _xp_fill: ColorRect
var _buy_button: Button
var _menu_button: Button
var _skills_button: Button
var _almanac_button: Button
var _shelf_button: Button
var _shelf_root: Node2D
var _shelf_cells: Array[Button] = []
var _shelf_infos: Array[Label] = []
var _ticket_label: Label
var _prize_label: Label
var _tool_icon: TextureRect
var _tool_label: Label
var _sfx_small: AudioStreamPlayer
var _sfx_medium: AudioStreamPlayer
var _sfx_jackpot: AudioStreamPlayer
var _sfx_near: AudioStreamPlayer
var _sfx_lose: AudioStreamPlayer
var _debug_panel: DebugPanel


func _ready() -> void:
	if "--shot-flow" in OS.get_cmdline_user_args():
		print("FLOW: game scene ready")
	_rng.randomize()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot"):
			_shot = arg
	_mobile = OS.has_feature("mobile") or ("--mobile" in OS.get_cmdline_user_args())

	_world = Node2D.new()
	add_child(_world)
	_build_background()
	_build_card_area()
	_build_hud()
	_build_effects()
	_build_audio()
	Ui.ignore_decorative(self)
	_build_shelf()
	_debug_panel = DebugPanel.attach(self, _shot == "--shot-debug")
	_debug_panel.notice.connect(func(text: String) -> void:
		_show_banner(text, PixelArt.C_GOLD_LIGHT, 0.9)
	)
	Music.play("game")

	if _shot == "--shot-jackpot":
		_force_next = "jackpot"
	if _shot == "--shot-tool" or _shot == "--shot-toolmax":
		# 工具截图：3 级展示小铲子，6 级展示金铲子
		GameState.skills["edge"] = 3 if _shot == "--shot-tool" else 6
	if _shot == "--shot-tier1" or _shot == "--shot-tier9":
		GameState.ticket_grid = 1 if _shot == "--shot-tier1" else 9
		GameState.money = maxi(GameState.money, Tickets.price_of(GameState.ticket_grid) * 3)
		_force_next = "star"
	_display_money = float(GameState.money)
	_start_ticket()
	_refresh_hud()

	if _shot != "":
		DisplayServer.window_move_to_foreground()
		_run_shot()


func _process(delta: float) -> void:
	_display_money = lerpf(_display_money, float(GameState.money), clampf(delta * 6.0, 0.0, 1.0))
	if absf(_display_money - float(GameState.money)) < 0.6:
		_display_money = float(GameState.money)
	_money_label.text = tr("BALANCE %s") % Ui.money(int(round(_display_money)))

	if _shake > 0.05:
		_shake = maxf(0.0, _shake - delta * 18.0)
		var s := int(ceil(_shake))
		_world.position = Vector2(randi_range(-s, s), randi_range(-s, s))
	else:
		_world.position = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				if not _buy_button.disabled:
					_start_ticket()
			KEY_ESCAPE:
				if _shelf_root.visible:
					_close_shelf()
				else:
					_back_to_title()
			KEY_J:
				_force_next = "jackpot"
				_show_banner(tr("DEBUG: NEXT = JACKPOT"), PixelArt.C_GOLD, 0.8)
			KEY_K:
				_force_next = "near_miss"
				_show_banner(tr("DEBUG: NEXT = NEAR MISS"), Color8(255, 140, 90), 0.8)


func _back_to_title() -> void:
	if SceneDirector.is_busy():
		return
	GameState.save()
	SceneDirector.goto_scene("res://scenes/title.tscn")


func _open_skills() -> void:
	if SceneDirector.is_busy():
		return
	GameState.save()
	SceneDirector.goto_scene("res://scenes/skills.tscn")


func _open_almanac() -> void:
	if SceneDirector.is_busy():
		return
	GameState.save()
	SceneDirector.goto_scene("res://scenes/almanac.tscn")


## ---------- 票种货架 ----------

func _build_shelf() -> void:
	_shelf_root = Node2D.new()
	_shelf_root.visible = false
	_shelf_root.z_index = 20
	_world.add_child(_shelf_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.size = Vector2(640, 360)
	_shelf_root.add_child(dim)

	Ui.panel(_shelf_root, Rect2(54, 64, 532, 232), Color8(30, 22, 30), PixelArt.C_GOLD_DARK)
	var title := Ui.make_label(_shelf_root, tr("TICKET SHELF"), Vector2(66, 72), 12, PixelArt.C_GOLD_LIGHT)
	title.size = Vector2(300, 16)
	var close := Ui.make_button(_shelf_root, tr("CLOSE"), Vector2(500, 68), Vector2(78, 24))
	close.pressed.connect(_close_shelf)

	for grid in range(1, Tickets.MAX_GRID + 1):
		var col := (grid - 1) % 3
		var row := (grid - 1) / 3
		var pos := Vector2(66 + float(col) * 172.0, 94 + float(row) * 66.0)
		Ui.panel(_shelf_root, Rect2(pos, Vector2(164, 60)), Color8(42, 34, 44), PixelArt.C_GOLD_DARK)
		Ui.make_label(_shelf_root, Tickets.name_of(grid), pos + Vector2(8, 4), 12, PixelArt.C_GOLD_LIGHT)
		var tag := Ui.make_label(_shelf_root, "%dx%d" % [grid, grid], pos + Vector2(8, 4), 12, PixelArt.C_PAPER)
		tag.size = Vector2(148, 16)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var info := Ui.make_label(_shelf_root, "", pos + Vector2(8, 20), 12, PixelArt.C_SILVER_2)
		var pick := Ui.make_button(_shelf_root, tr("PICK"), pos + Vector2(8, 36), Vector2(148, 20))
		pick.pressed.connect(_select_tier.bind(grid))
		_shelf_infos.append(info)
		_shelf_cells.append(pick)
	_refresh_shelf()


func _refresh_shelf() -> void:
	var current := GameState.ticket_grid
	var unlocked := GameState.max_unlocked_grid()
	for i in _shelf_cells.size():
		var grid := i + 1
		var chance := (Tickets.base_win_chance(grid) + SkillTree.luck_points(GameState.skills)) * 100.0
		var info := _shelf_infos[i]
		var pick := _shelf_cells[i]
		if grid > unlocked:
			info.text = tr("LOCKED · SHELF Lv %d") % (grid - 1)
			pick.text = tr("LOCKED")
			pick.disabled = true
		else:
			info.text = "%s  %s" % [Ui.money(Tickets.price_of(grid)), tr("WIN %.1f%%") % chance]
			if grid == current:
				pick.text = tr("SELECTED")
				pick.disabled = true
			else:
				pick.text = tr("PICK")
				pick.disabled = false


func _open_shelf() -> void:
	if _buy_button.disabled:
		return
	_refresh_shelf()
	_shelf_root.visible = true
	_refresh_hud()


func _close_shelf() -> void:
	_shelf_root.visible = false
	_refresh_hud()


func _select_tier(grid: int) -> void:
	if grid > GameState.max_unlocked_grid():
		return
	GameState.ticket_grid = grid
	GameState.save()
	_close_shelf()


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	_toast.position.y = 180.0
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.set_parallel(true)
	_toast_tween.tween_property(_toast, "position:y", 162.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.8).set_delay(0.6)


func _start_ticket() -> void:
	var grid := GameState.ticket_grid
	var price := GameState.ticket_price()
	if GameState.money < price:
		# 兜底：没钱也能继续刮，游戏永远有下一步
		_show_banner(tr("FREE TICKET"), Color8(255, 200, 120), 0.9)
	else:
		GameState.money -= price
		GameState.add_pool(grid, int(price * 0.05) + SkillTree.feed_bonus(GameState.skills) * grid)
	GameState.tickets += 1
	GameState.save()

	var force := _force_next
	_force_next = ""
	if force == "":
		force = GameState.consume_forced_result()
	if force == "" and grid == 1 and _warmup_index < WARMUP.size():
		force = WARMUP[_warmup_index]
		_warmup_index += 1
	if force == "" and GameState.loss_streak >= 7:
		# 保底：连输 7 张必回一张小奖
		force = "cherry"
	var board := Prize.make_board(_rng, grid, force, SkillTree.luck_points(GameState.skills))

	for child in _card_holder.get_children():
		if child is ScratchCard:
			child.queue_free()
	_card = ScratchCard.new()
	_card.position = CARD_POS
	_card_holder.add_child(_card)
	_card.setup(
		board,
		SkillTree.brush_radius(GameState.skills),
		SkillTree.auto_rate(GameState.skills),
		SkillTree.auto_instant(GameState.skills),
		SkillTree.level(GameState.skills, "edge"),
	)
	_card.reveal_finished.connect(_on_reveal)

	_buy_button.disabled = true
	_refresh_hud()


func _on_reveal(result: Dictionary) -> void:
	var payout: int = result.get("payout", 0)
	var symbol: int = result.get("win_symbol", -1)
	var grid: int = result.get("grid", GameState.ticket_grid)
	var is_jackpot: bool = result.get("top", false)
	if payout > 0:
		payout = int(round(float(payout) * SkillTree.payout_mult(GameState.skills)))
		if is_jackpot:
			payout = GameState.pool(grid)
		GameState.money += payout
		GameState.total_won += payout
		GameState.best_win = maxi(GameState.best_win, payout)
		GameState.register_win(symbol)
		GameState.loss_streak = 0
		if is_jackpot:
			GameState.jackpots += 1
		GameState.save()
		_burst.color = PixelArt.C_GOLD_LIGHT
		_burst.emitting = false
		_burst.restart()
		_burst.emitting = true
		if is_jackpot:
			GameState.reset_pool(grid)
			_shake = 7.0
			_sfx_jackpot.play()
			_sfx_small.play()
			_show_banner(tr("JACKPOT! %s") % Ui.money(payout), PixelArt.C_GOLD_LIGHT, 2.4)
		elif payout >= 500:
			_shake = 4.0
			_sfx_medium.play()
			_show_banner(tr("WIN %s") % Ui.money(payout), PixelArt.C_GOLD_LIGHT, 1.4)
		else:
			_shake = 2.0
			_sfx_small.play()
			_show_banner(tr("WIN %s") % Ui.money(payout), PixelArt.C_GOLD, 1.0)
	else:
		GameState.loss_streak += 1
		if result.get("near_miss", false):
			GameState.near_miss_count += 1
			var consolation := SkillTree.consolation(GameState.skills)
			GameState.money += consolation
			_shake = 1.5
			_sfx_near.play()
			if consolation > 0:
				_show_banner(tr("SO CLOSE! +%s") % Ui.money(consolation), Color8(255, 140, 90), 1.2)
			else:
				_show_banner(tr("SO CLOSE!"), Color8(255, 140, 90), 1.0)
		else:
			_sfx_lose.play()
			_show_banner(tr("NO PRIZE"), Color8(150, 155, 165), 0.8)
		GameState.save()
	var gained := GameState.add_xp(GameState.xp_per_ticket())
	if gained > 0:
			_show_toast(tr("LEVEL UP!  Lv %d  +%d SP") % [GameState.level, gained * GameState.SP_PER_LEVEL])
	_buy_button.disabled = false
	_refresh_hud()


func _refresh_hud() -> void:
	var grid := GameState.ticket_grid
	_jackpot_label.text = tr("JACKPOT POOL %s") % Ui.money(GameState.pool(grid))
	_ticket_label.text = "%s  %dx%d" % [Tickets.name_of(grid), grid, grid]
	var edge := SkillTree.level(GameState.skills, "edge")
	_tool_icon.texture = PixelArt.tool_texture(edge)
	_tool_label.text = tr("TOOL: %s") % tr(PixelArt.tool_name_key(edge))
	_stat_label.text = tr("TICKETS %d") % GameState.tickets
	_info_label.text = "\n".join([
		tr("LEVEL %d    SP %d") % [GameState.level, GameState.skill_points],
		tr("XP %d/%d") % [GameState.xp, GameState.xp_needed(GameState.level)],
		tr("PRICE %s") % Ui.money(GameState.ticket_price()),
		tr("TOP PRIZE %s") % Ui.money(Tickets.top_prize(grid)),
		tr("WIN RATE %.1f%%") % ((Tickets.base_win_chance(grid) + SkillTree.luck_points(GameState.skills)) * 100.0),
		tr("LUCK +%.1f%%") % (SkillTree.luck_points(GameState.skills) * 100.0),
	])
	_info2_label.text = "\n".join([
		tr("SCRATCHED %d") % GameState.tickets,
		tr("TOTAL WON %s") % Ui.money(GameState.total_won),
		tr("BEST WIN %s") % Ui.money(GameState.best_win),
		tr("PITY %d/7") % mini(GameState.loss_streak, 7),
	])
	var rows := PackedStringArray()
	for slot in Prize.SYMBOL_NAMES.size():
		var amount := GameState.pool(grid) if slot == 6 else Tickets.prize_amount(grid, slot)
		rows.append("%s %s" % [tr(Prize.SYMBOL_NAMES[slot]), Ui.money(amount)])
	_prize_label.text = "\n".join(rows)
	_xp_fill.size.x = maxf(1.0, 202.0 * GameState.xp_progress())
	_buy_button.text = tr("NEXT TICKET %s") % Ui.money(GameState.ticket_price())
	_shelf_button.disabled = not _buy_button.disabled or _shelf_root.visible


func _show_banner(text: String, color: Color, hold := 1.0) -> void:
	if _shot != "":
		hold = 30.0
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.modulate.a = 1.0
	_banner.scale = Vector2(0.6, 0.6)
	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "scale", Vector2(1.15, 1.15), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_property(_banner, "scale", Vector2.ONE, 0.08)
	_banner_tween.tween_interval(hold)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.25)


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color8(74, 48, 30)
	bg.size = Vector2(640, 360)
	_world.add_child(bg)

	var tile := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var c := Color8(74, 48, 30)
			if y % 8 == 0:
				c = Color8(58, 36, 22)
			elif y % 8 == 7:
				c = Color8(88, 58, 36)
			if (x * 374761393 + y * 668265263) % 11 == 0:
				c = c.darkened(0.12)
			tile.set_pixel(x, y, c)
	var wood := TextureRect.new()
	wood.texture = ImageTexture.create_from_image(tile)
	wood.size = Vector2(640, 360)
	wood.stretch_mode = TextureRect.STRETCH_TILE
	wood.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_world.add_child(wood)


func _build_card_area() -> void:
	_card_holder = Node2D.new()
	_world.add_child(_card_holder)

	var mat := ColorRect.new()
	mat.color = Color8(96, 26, 34)
	mat.position = CARD_POS + Vector2(-10, -10)
	mat.size = Vector2(180, 260)
	_card_holder.add_child(mat)

	var shadow := ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.35)
	shadow.position = CARD_POS + Vector2(4, 4)
	shadow.size = Vector2(160, 240)
	_card_holder.add_child(shadow)


func _build_hud() -> void:
	var top := ColorRect.new()
	top.color = Color8(26, 27, 34)
	top.size = Vector2(640, 28)
	_world.add_child(top)
	var top_line := ColorRect.new()
	top_line.color = PixelArt.C_GOLD_DARK
	top_line.position = Vector2(0, 26)
	top_line.size = Vector2(640, 2)
	_world.add_child(top_line)

	_money_label = Ui.make_label(_world, tr("BALANCE %s") % Ui.money(5000), Vector2(10, 6), 12, PixelArt.C_GOLD_LIGHT)
	_jackpot_label = Ui.make_label(_world, tr("JACKPOT POOL %s") % Ui.money(1000000), Vector2(200, 6), 12, Color8(255, 106, 94))
	_jackpot_label.size = Vector2(240, 16)
	_jackpot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stat_label = Ui.make_label(_world, tr("TICKETS %d") % 0, Vector2(470, 6), 12, PixelArt.C_SILVER_2)
	_stat_label.size = Vector2(160, 16)
	_stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	Ui.panel(_world, Rect2(8, 36, 224, 252), Color8(34, 30, 38), PixelArt.C_GOLD_DARK)
	_ticket_label = Ui.make_label(_world, "", Vector2(18, 42), 12, PixelArt.C_GOLD_LIGHT)
	_shelf_button = Ui.make_button(_world, tr("TICKET SHELF"), Vector2(18, 60), Vector2(120, 26))
	_shelf_button.pressed.connect(_open_shelf)
	_tool_icon = TextureRect.new()
	_tool_icon.position = Vector2(418, 92)
	_tool_icon.size = Vector2(16, 16)
	_tool_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tool_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.add_child(_tool_icon)
	_tool_label = Ui.make_label(_world, "", Vector2(438, 94), 12, PixelArt.C_SILVER_2)
	_info_label = Ui.make_label(_world, "", Vector2(18, 92), 12, PixelArt.C_PAPER)
	_info_label.add_theme_constant_override("line_spacing", 4)

	var xp_bg := ColorRect.new()
	xp_bg.color = Color8(58, 52, 64)
	xp_bg.position = Vector2(18, 194)
	xp_bg.size = Vector2(204, 8)
	_world.add_child(xp_bg)
	_xp_fill = ColorRect.new()
	_xp_fill.color = PixelArt.C_GOLD
	_xp_fill.position = Vector2(20, 196)
	_xp_fill.size = Vector2(1, 4)
	_world.add_child(_xp_fill)

	_info2_label = Ui.make_label(_world, "", Vector2(18, 208), 12, PixelArt.C_SILVER_2)
	_info2_label.add_theme_constant_override("line_spacing", 4)

	Ui.panel(_world, Rect2(408, 36, 224, 252), Color8(34, 30, 38), PixelArt.C_GOLD_DARK)
	Ui.make_label(_world, tr("PRIZE TABLE"), Vector2(418, 44), 12, PixelArt.C_GOLD_LIGHT)
	_prize_label = Ui.make_label(_world, "", Vector2(418, 68), 12, PixelArt.C_PAPER)
	_prize_label.add_theme_constant_override("line_spacing", 4)

	var bottom := ColorRect.new()
	bottom.color = Color8(26, 27, 34)
	bottom.position = Vector2(0, 296)
	bottom.size = Vector2(640, 64)
	_world.add_child(bottom)
	var bottom_line := ColorRect.new()
	bottom_line.color = PixelArt.C_GOLD_DARK
	bottom_line.position = Vector2(0, 296)
	bottom_line.size = Vector2(640, 2)
	_world.add_child(bottom_line)

	if _mobile:
		Ui.make_label(_world, tr("TOUCH AND DRAG TO SCRATCH"), Vector2(16, 310), 12, PixelArt.C_PAPER)
		Ui.make_label(_world, tr("TAP MENU FOR SKILLS AND ALMANAC"), Vector2(16, 332), 12, Color8(122, 127, 137))
	else:
		Ui.make_label(_world, tr("HOLD AND DRAG TO SCRATCH"), Vector2(16, 310), 12, PixelArt.C_PAPER)
		Ui.make_label(_world, tr("SPACE: NEXT | J / K / ` : DEBUG"), Vector2(16, 332), 12, Color8(122, 127, 137))

	_menu_button = Ui.make_button(_world, tr("MENU"), Vector2(204, 306), Vector2(64, 40))
	_menu_button.pressed.connect(_back_to_title)
	_skills_button = Ui.make_button(_world, tr("SKILLS"), Vector2(276, 306), Vector2(72, 40))
	_skills_button.pressed.connect(_open_skills)
	_almanac_button = Ui.make_button(_world, tr("ALMANAC"), Vector2(356, 306), Vector2(88, 40))
	_almanac_button.pressed.connect(_open_almanac)
	_buy_button = Ui.make_button(_world, tr("NEXT TICKET %s") % Ui.money(100), Vector2(452, 306), Vector2(172, 40))
	_buy_button.pressed.connect(_on_buy_pressed)

	_toast = Ui.make_label(_world, "", Vector2(160, 176), 12, PixelArt.C_GOLD_LIGHT)
	_toast.size = Vector2(320, 20)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	_toast.z_index = 10

	_banner = Ui.make_label(_world, "", Vector2(160, 116), 24, PixelArt.C_GOLD_LIGHT)
	_banner.size = Vector2(320, 44)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.pivot_offset = Vector2(160, 22)
	_banner.modulate.a = 0.0
	_banner.z_index = 10


func _on_buy_pressed() -> void:
	if _buy_button.disabled:
		return
	_start_ticket()


func _build_effects() -> void:
	var px := Image.create_empty(2, 2, false, Image.FORMAT_RGBA8)
	px.fill(Color.WHITE)
	_burst = CPUParticles2D.new()
	_burst.texture = ImageTexture.create_from_image(px)
	_burst.amount = 32
	_burst.lifetime = 0.9
	_burst.one_shot = true
	_burst.explosiveness = 1.0
	_burst.direction = Vector2(0, -1)
	_burst.spread = 180.0
	_burst.initial_velocity_min = 40.0
	_burst.initial_velocity_max = 150.0
	_burst.gravity = Vector2(0, 380)
	_burst.scale_amount_min = 1.0
	_burst.scale_amount_max = 2.0
	_burst.color = PixelArt.C_GOLD_LIGHT
	_burst.emitting = false
	_burst.position = CARD_POS + Vector2(80, 120)
	_world.add_child(_burst)


func _build_audio() -> void:
	_sfx_small = _make_player(SFX_SMALL, AudioFactory.make_ding())
	_sfx_medium = _make_player(SFX_MEDIUM, AudioFactory.make_fanfare())
	_sfx_jackpot = _make_player(SFX_JACKPOT, AudioFactory.make_fanfare())
	_sfx_near = _make_player(SFX_NEAR, AudioFactory.make_thud())
	_sfx_lose = _make_player("", AudioFactory.make_thud())


func _make_player(path: String, fallback: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	if path != "" and ResourceLoader.exists(path):
		p.stream = load(path)
	else:
		p.stream = fallback
	_world.add_child(p)
	return p


## 截图自检：--shot-mid / --shot-win / --shot-jackpot
func _run_shot() -> void:
	print("FLOW: game run_shot mode=", _shot)
	await get_tree().create_timer(0.5).timeout
	print("HUD money=[%s] jackpot=[%s] stat=[%s]" % [_money_label.text, _jackpot_label.text, _stat_label.text])
	print("HUD button=[%s]" % _buy_button.text)
	if _shot == "--shot-shelf":
		_refresh_shelf()
		_shelf_root.visible = true
		_refresh_hud()
		await get_tree().create_timer(0.2).timeout
		await SceneDirector.save_shot("shelf")
		return
	if _shot == "--shot-tier1" or _shot == "--shot-tier9":
		_card.debug_scratch(0.46)
		_card.debug_reveal_now()
		await get_tree().create_timer(0.45).timeout
		await SceneDirector.save_shot("tier1" if _shot == "--shot-tier1" else "tier9")
		return
	if _shot == "--shot-touch":
		await _simulate_touch_scratch()
		await get_tree().create_timer(0.2).timeout
		print("TOUCH 进度=%.2f 正在刮=%s" % [_card.progress, _card.scratching])
		await SceneDirector.save_shot("touch")
		return
	if _shot == "--shot-mouse":
		await _simulate_mouse_scratch()
		await get_tree().create_timer(0.2).timeout
		print("MOUSE 进度=%.2f 正在刮=%s" % [_card.progress, _card.scratching])
		await SceneDirector.save_shot("mouse")
		return
	if _shot == "--shot-flow":
		await get_tree().create_timer(0.2).timeout
		await SceneDirector.save_shot("flow")
		return
	if _shot == "--shot-debug":
		print("DEBUG 面板 open=%s 按钮=%d" % [_debug_panel.is_open(), _debug_panel.buttons().size()])
		await get_tree().create_timer(0.2).timeout
		await SceneDirector.save_shot("debug")
		return
	if _shot == "--shot-tool" or _shot == "--shot-toolmax":
		# 只刮一点点，避免触发自动清屏把工具收起来
		var p := CARD_POS + Vector2(56, 56)
		_send_mouse_button(p, true)
		await get_tree().process_frame
		for step in 4:
			p += Vector2(14.0, 9.0)
			_send_mouse_motion(p, Vector2(14.0, 9.0))
			await get_tree().process_frame
		print("TOOL 光标 level=%d name=%s 进度=%.2f" % [
			_card.tool_level, PixelArt.tool_name_key(_card.tool_level), _card.progress,
		])
		await get_tree().create_timer(0.2).timeout
		await SceneDirector.save_shot("tool" if _shot == "--shot-tool" else "toolmax")
		return
	if _shot == "--shot-mid":
		_card.debug_scratch(0.28)
		await get_tree().create_timer(0.15).timeout
		await SceneDirector.save_shot("mid")
	else:
		_card.debug_scratch(0.46)
		_card.debug_reveal_now()
		await get_tree().create_timer(0.45).timeout
		print("BANNER [%s]" % _banner.text)
		await SceneDirector.save_shot("win" if _shot == "--shot-win" else "jackpot")


## 模拟手指刮卡，用于移动端输入链路自检
func _simulate_touch_scratch() -> void:
	if _card == null:
		return
	var pts := _shot_drag_path()
	_send_touch(pts[0], true)
	await get_tree().process_frame
	for p in pts:
		_send_drag(p, Vector2(4.0, 3.0))
		await get_tree().process_frame
	_send_touch(pts[pts.size() - 1], false)


## 模拟鼠标拖动刮卡，验证桌面输入链路
func _simulate_mouse_scratch() -> void:
	if _card == null:
		return
	var pts := _shot_drag_path()
	_send_mouse_button(pts[0], true)
	await get_tree().process_frame
	for p in pts:
		_send_mouse_motion(p, Vector2(4.0, 3.0))
		await get_tree().process_frame
	_send_mouse_button(pts[pts.size() - 1], false)


## 蛇形路径覆盖卡面
func _shot_drag_path() -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for i in 160:
		var t := float(i) / 160.0
		var seg := int(t * 8.0)
		var f := fmod(t * 8.0, 1.0)
		var x := 10.0 + (f * 140.0 if seg % 2 == 0 else (1.0 - f) * 140.0)
		pts.append(CARD_POS + Vector2(x, 10.0 + t * 220.0))
	return pts


func _send_touch(canvas_pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.pressed = pressed
	ev.position = _to_window(canvas_pos)
	Input.parse_input_event(ev)


func _send_drag(canvas_pos: Vector2, rel: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = 0
	ev.position = _to_window(canvas_pos)
	ev.relative = rel
	Input.parse_input_event(ev)


func _send_mouse_button(canvas_pos: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = _to_window(canvas_pos)
	Input.parse_input_event(ev)


func _send_mouse_motion(canvas_pos: Vector2, rel: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = _to_window(canvas_pos)
	ev.relative = rel
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(ev)


func _to_window(canvas_pos: Vector2) -> Vector2:
	return get_viewport().get_final_transform() * canvas_pos
