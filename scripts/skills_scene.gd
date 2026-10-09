extends Node2D
## 技能树场景：花费技能点升级，直接改变刮卡手感与收益曲线。

const CARD_W := 300.0
const CARD_H := 56.0
const GAP_X := 16.0
const GAP_Y := 6.0
const ORIGIN := Vector2(12, 52)

var _shot := ""
var _header: Label
var _points: Label
var _cards: Dictionary = {}
var _debug_panel: DebugPanel
var _toast: Label


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot"):
			_shot = arg
	if _shot != "":
		# 截图自检时用一组演示数据，不写存档
		GameState.skill_points = maxi(GameState.skill_points, 9)
		GameState.skills = {
			"edge": 3, "auto": 4, "luck": 5, "gold": 2,
			"frugal": 2, "feed": 1, "soft": 3, "mentor": 1,
		}
		GameState.level = maxi(GameState.level, 9)
	_build()
	Ui.ignore_decorative(self)
	_debug_panel = DebugPanel.attach(self, _shot == "--shot-debug")
	_debug_panel.changed.connect(_refresh)
	if _shot != "":
		DisplayServer.window_move_to_foreground()
		_run_shot()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color8(30, 22, 30)
	bg.size = Vector2(640, 360)
	add_child(bg)

	var title := Ui.make_label(self, tr("SKILL TREE"), Vector2(0, 4), 24, PixelArt.C_GOLD_LIGHT)
	title.size = Vector2(640, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_header = Ui.make_label(self, "", Vector2(12, 36), 12, PixelArt.C_PAPER)
	_points = Ui.make_label(self, "", Vector2(0, 36), 12, PixelArt.C_GOLD_LIGHT)
	_points.size = Vector2(628, 16)
	_points.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var back := Ui.make_button(self, tr("BACK"), Vector2(536, 4), Vector2(92, 28))
	back.pressed.connect(_back)

	for i in SkillTree.ORDER.size():
		var id: String = SkillTree.ORDER[i]
		var col := i % 2
		var row := i / 2
		var pos := ORIGIN + Vector2(float(col) * (CARD_W + GAP_X), float(row) * (CARD_H + GAP_Y))
		Ui.panel(self, Rect2(pos, Vector2(CARD_W, CARD_H)), Color8(40, 32, 42), PixelArt.C_GOLD_DARK)
		Ui.make_label(self, SkillTree.name_of(id), pos + Vector2(10, 4), 12, PixelArt.C_GOLD_LIGHT)
		var level_label := Ui.make_label(self, "", pos + Vector2(10, 4), 12, PixelArt.C_PAPER)
		level_label.size = Vector2(CARD_W - 20.0, 16)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		Ui.make_label(self, SkillTree.desc_of(id), pos + Vector2(10, 20), 12, PixelArt.C_SILVER_2)
		var effect := Ui.make_label(self, "", pos + Vector2(10, 36), 12, PixelArt.C_PAPER)
		var button := Ui.make_button(self, "1 SP", pos + Vector2(CARD_W - 94.0, 26), Vector2(84, 26))
		button.pressed.connect(_buy.bind(id))
		var tools := _build_tool_preview(id, pos)
		_cards[id] = {"level": level_label, "effect": effect, "button": button, "tools": tools}

	_toast = Ui.make_label(self, "", Vector2(0, 322), 12, PixelArt.C_GOLD_LIGHT)
	_toast.size = Vector2(640, 18)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	_refresh()


## 锋利刮刀这张卡额外画「当前工具 → 下一档工具」预览
func _build_tool_preview(id: String, pos: Vector2) -> Dictionary:
	if id != "edge":
		return {}
	var current := TextureRect.new()
	current.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	current.position = pos + Vector2(150, 34)
	current.size = Vector2(16, 16)
	current.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(current)
	Ui.make_label(self, ">", pos + Vector2(168, 36), 12, PixelArt.C_SILVER_2)
	var next := TextureRect.new()
	next.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	next.position = pos + Vector2(180, 34)
	next.size = Vector2(16, 16)
	next.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(next)
	return {"current": current, "next": next}


func _refresh() -> void:
	_header.text = tr("LEVEL %d    XP %d/%d") % [GameState.level, GameState.xp, GameState.xp_needed(GameState.level)]
	_points.text = tr("SKILL POINTS %d") % GameState.skill_points
	for id in SkillTree.ORDER:
		var card: Dictionary = _cards[id]
		var lv := SkillTree.level(GameState.skills, id)
		var mx := SkillTree.max_level(id)
		card.level.text = "%d/%d" % [lv, mx]
		card.effect.text = SkillTree.effect_text(GameState.skills, id)
		var button: Button = card.button
		if lv >= mx:
			button.text = tr("MAX")
			button.disabled = true
		else:
			var cost := SkillTree.cost(lv + 1)
			button.text = tr("%d SP") % cost
			button.disabled = GameState.skill_points < cost
		if not card.tools.is_empty():
			var top := PixelArt.TOOLS.size() - 1
			card.tools.current.texture = PixelArt.tool_texture(lv)
			card.tools.next.texture = PixelArt.tool_texture(mini(lv + 1, top))
			card.tools.next.modulate.a = 0.3 if lv >= top else 1.0


func _buy(id: String) -> void:
	if SceneDirector.is_busy():
		return
	if GameState.buy_skill(id):
		_refresh()
		if id == "edge":
			_show_tool_toast()


## 换工具时给个明确反馈，避免「升了级没感觉」
func _show_tool_toast() -> void:
	var edge := SkillTree.level(GameState.skills, "edge")
	_toast.text = tr("SHARP EDGE Lv %d · %s") % [edge, tr(PixelArt.tool_name_key(edge))]
	_toast.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.4)
	tween.tween_property(_toast, "modulate:a", 0.0, 0.4)


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
	await SceneDirector.save_shot("skills")
