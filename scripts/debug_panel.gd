class_name DebugPanel
extends Node2D
## 开发调试面板。
## 打开方式：桌面按 ` 或 F1，启动参数加 --debug 直接展开，
## 移动端在标题页连点右下角版本号 5 次。
## 面板操作只改当前存档，随时可以「重置存档」回到初始状态。

signal notice(text: String)
signal changed

const PANEL_RECT := Rect2(8, 68, 232, 184)
const MARGIN := 8.0
const COL_W := 106.0
const BTN_H := 22.0
const ROW_STEP := 26.0
const TOGGLE_KEYS: Array[Key] = [KEY_QUOTELEFT, KEY_F1]

var _open := false
var _start_open := false
var _buttons: Array[Button] = []


## 挂到任意场景上，返回实例；start_open 为 true 时直接展开
static func attach(parent: Node, start_open := false) -> DebugPanel:
	var panel := DebugPanel.new()
	panel._start_open = start_open or GameState.debug
	parent.add_child(panel)
	return panel


## 移动端入口：连点某个控件 5 次打开面板
static func bind_secret_toggle(label: Control, panel: DebugPanel) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	var taps := {"count": 0, "until": 0.0}
	label.gui_input.connect(func(event: InputEvent) -> void:
		var pressed := false
		if event is InputEventMouseButton:
			var mouse := event as InputEventMouseButton
			pressed = mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
		elif event is InputEventScreenTouch:
			pressed = (event as InputEventScreenTouch).pressed
		if not pressed:
			return
		var now := Time.get_ticks_msec() / 1000.0
		taps["count"] = int(taps["count"]) + 1 if now <= float(taps["until"]) else 1
		taps["until"] = now + 1.2
		if int(taps["count"]) >= 5:
			taps["count"] = 0
			panel.open(true)
	)


func _ready() -> void:
	_build()
	open(_start_open)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if (event as InputEventKey).keycode in TOGGLE_KEYS:
		open(not _open)
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _open


func buttons() -> Array[Button]:
	return _buttons


func open(value: bool) -> void:
	_open = value
	visible = value
	if value:
		GameState.debug = true


func _build() -> void:
	Ui.panel(self, PANEL_RECT, Color8(24, 20, 26), PixelArt.C_GOLD_DARK)
	var origin := PANEL_RECT.position + Vector2(MARGIN, 2)

	var title := Ui.make_label(self, tr("DEBUG"), origin, 12, PixelArt.C_GOLD_LIGHT)
	title.size = Vector2(80, 16)
	var hint := Ui.make_label(self, tr("` : TOGGLE"), origin + Vector2(PANEL_RECT.size.x - MARGIN * 2 - 96, 0),
		12, Color8(140, 145, 155))
	hint.size = Vector2(96, 16)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var left := origin.x
	var right := origin.x + COL_W + 4.0
	var full_w := PANEL_RECT.size.x - MARGIN * 2
	var row := origin.y + 22.0

	_add_button(tr("+1 SP"), Vector2(left, row), COL_W, func() -> void: _grant_sp(1))
	_add_button(tr("+10 SP"), Vector2(right, row), COL_W, func() -> void: _grant_sp(10))
	row += ROW_STEP

	_add_button(tr("+1 LEVEL"), Vector2(left, row), full_w, func() -> void: _grant_level())
	row += ROW_STEP

	_add_button(tr("ADD %s") % Ui.money(1000000), Vector2(left, row), full_w,
		func() -> void: _grant_money())
	row += ROW_STEP

	_add_button(tr("SHELF +1"), Vector2(left, row), COL_W, _unlock_tier)
	_add_button(tr("RESET SAVE"), Vector2(right, row), COL_W, _reset_save)
	row += ROW_STEP

	_add_button(tr("JACKPOT"), Vector2(left, row), COL_W,
		func() -> void: _force_next("jackpot"))
	_add_button(tr("NEAR MISS"), Vector2(right, row), COL_W,
		func() -> void: _force_next("near_miss"))
	row += ROW_STEP

	_add_button(tr("CLOSE"), Vector2(left, row), full_w, func() -> void: open(false))


func _add_button(text: String, pos: Vector2, width: float, action: Callable) -> void:
	var button := Ui.make_button(self, text, pos, Vector2(width, BTN_H))
	button.pressed.connect(action)
	_buttons.append(button)


func _announce(text: String) -> void:
	notice.emit(text)
	changed.emit()


func _grant_sp(amount: int) -> void:
	GameState.grant_sp(amount)
	var label := tr("+1 SP") if amount == 1 else tr("+10 SP")
	_announce(tr("DEBUG: %s") % label)


func _grant_level() -> void:
	GameState.grant_levels(1)
	_announce(tr("DEBUG: %s") % tr("+1 LEVEL"))


func _grant_money() -> void:
	GameState.grant_money(1000000)
	_announce(tr("DEBUG: %s") % Ui.money(1000000))


func _unlock_tier() -> void:
	GameState.unlock_next_tier()
	_announce(tr("DEBUG: %s") % tr("SHELF +1"))


func _reset_save() -> void:
	GameState.clear_save()
	_announce(tr("DEBUG: %s") % tr("RESET SAVE"))


func _force_next(kind: String) -> void:
	GameState.force_next_result(kind)
	_announce(tr("DEBUG: %s") % tr("JACKPOT" if kind == "jackpot" else "NEAR MISS"))
