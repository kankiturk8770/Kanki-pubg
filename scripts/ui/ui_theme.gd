extends RefCounted
## Shared look for menus and panels (big, finger-friendly buttons).

const ACCENT := Color("f2b632")
const BG := Color(0.08, 0.1, 0.13, 0.92)
const TEAM_COLORS := [Color("3d8bfd"), Color("e2483d")]
const TEAM_NAMES := ["BLUE", "RED"]


static func make() -> Theme:
	var t := Theme.new()
	t.default_font_size = 24

	var normal := _box(Color(0.16, 0.19, 0.24), Color(0.3, 0.34, 0.4))
	var hover := _box(Color(0.22, 0.26, 0.32), ACCENT)
	var pressed := _box(ACCENT.darkened(0.2), ACCENT)
	for state in ["normal", "focus"]:
		t.set_stylebox(state, "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_color("font_pressed_color", "Button", Color.BLACK)

	var edit := _box(Color(0.05, 0.06, 0.08), Color(0.3, 0.34, 0.4))
	t.set_stylebox("normal", "LineEdit", edit)
	t.set_stylebox("focus", "LineEdit", _box(Color(0.05, 0.06, 0.08), ACCENT))

	t.set_stylebox("panel", "PanelContainer", _box(BG, Color(0.3, 0.34, 0.4), 12, 20))
	return t


static func _box(bg: Color, border: Color, radius := 8, margin := 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.6
	s.content_margin_bottom = margin * 0.6
	return s


static func label(text: String, size := 24, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	return l


static func button(text: String, callback: Callable, min_height := 56) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = min_height
	b.pressed.connect(callback)
	return b
