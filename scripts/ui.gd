class_name Ui
extends RefCounted
## 统一的像素 UI 工厂：标签、按钮、面板。

## 由 GameState 在启动时注入，避免 Ui 直接依赖 autoload
static var ui_font: Font


static func font() -> Font:
	if ui_font == null:
		return ThemeDB.fallback_font
	return ui_font


static func make_label(parent: Node, text: String, pos: Vector2, size: int, color: Color) -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(l)
	return l


static func make_button(parent: Node, text: String, pos: Vector2, dims: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = dims
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_stylebox_override("normal", sb(PixelArt.C_GOLD, PixelArt.C_INK))
	b.add_theme_stylebox_override("hover", sb(PixelArt.C_GOLD_LIGHT, PixelArt.C_INK))
	b.add_theme_stylebox_override("pressed", sb(PixelArt.C_GOLD_DARK, PixelArt.C_INK))
	b.add_theme_stylebox_override("disabled", sb(Color8(90, 92, 98), Color8(50, 52, 58)))
	b.add_theme_stylebox_override("focus", sb(PixelArt.C_GOLD_HI, PixelArt.C_INK))
	b.add_theme_color_override("font_color", PixelArt.C_INK)
	b.add_theme_color_override("font_hover_color", PixelArt.C_INK)
	b.add_theme_color_override("font_pressed_color", PixelArt.C_INK)
	b.add_theme_color_override("font_focus_color", PixelArt.C_INK)
	b.add_theme_color_override("font_disabled_color", Color8(160, 162, 168))
	parent.add_child(b)
	return b


static func panel(parent: Node, rect: Rect2, bg: Color, border: Color) -> void:
	var outer := ColorRect.new()
	outer.position = rect.position
	outer.size = rect.size
	outer.color = border
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(outer)
	var inner := ColorRect.new()
	inner.position = rect.position + Vector2(2, 2)
	inner.size = rect.size - Vector2(4, 4)
	inner.color = bg
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(inner)


## 装饰性控件不吞输入：除按钮外全部设为 IGNORE，
## 让刮卡手势（触摸或鼠标）能穿透到 ScratchCard。
static func ignore_decorative(root: Node) -> void:
	for child in root.get_children():
		if child is Button:
			continue
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		ignore_decorative(child)


static func sb(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(0)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


static func group(v: int) -> String:
	var s := str(v)
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	return out


## 金额统一 100.000.00 格式
static func money(v: int) -> String:
	return group(v) + ".00"
