extends RefCounted
## Shared look: AMOLED black and frosted glass panels, gold accent,
## big finger-friendly buttons. Fonts: Rajdhani (text), Teko (titles).

const ACCENT := Color("f5b82e")
const BG := Color(0.02, 0.025, 0.03, 0.6)        # glass tint
const GLASS_BORDER := Color(1, 1, 1, 0.14)
const TEXT_DIM := Color(1, 1, 1, 0.6)
const TEAM_COLORS := [Color("3d8bfd"), Color("e2483d")]
const TEAM_NAMES := ["BLUE", "RED"]

const FONT := preload("res://assets/fonts/Rajdhani-SemiBold.ttf")
const FONT_BOLD := preload("res://assets/fonts/Rajdhani-Bold.ttf")
const FONT_TITLE := preload("res://assets/fonts/Teko-Variable.ttf")
const GLASS_SHADER := preload("res://scripts/ui/glass.gdshader")

static var _glass: ShaderMaterial


static func make() -> Theme:
	var t := Theme.new()
	t.default_font = FONT
	t.default_font_size = 24

	var normal := _box(Color(0.03, 0.035, 0.045, 0.62), GLASS_BORDER)
	var hover := _box(Color(0.07, 0.08, 0.1, 0.7), ACCENT)
	var pressed := _box(ACCENT, ACCENT)
	for state in ["normal", "focus"]:
		t.set_stylebox(state, "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("hover_pressed", "Button", pressed)
	t.set_font("font", "Button", FONT_BOLD)
	t.set_color("font_pressed_color", "Button", Color.BLACK)
	t.set_color("font_hover_pressed_color", "Button", Color.BLACK)

	var edit := _box(Color(0, 0, 0, 0.55), GLASS_BORDER)
	t.set_stylebox("normal", "LineEdit", edit)
	t.set_stylebox("focus", "LineEdit", _box(Color(0, 0, 0, 0.65), ACCENT))
	t.set_color("font_placeholder_color", "LineEdit", Color(1, 1, 1, 0.35))
	t.set_color("caret_color", "LineEdit", ACCENT)

	t.set_stylebox("panel", "PanelContainer", _box(BG, GLASS_BORDER, 16, 20))
	return t


## Frosted-glass look for a panel (blurs what is behind it).
static func glass(node: CanvasItem) -> CanvasItem:
	if _glass == null:
		_glass = ShaderMaterial.new()
		_glass.shader = GLASS_SHADER
	node.material = _glass
	return node


static func _box(bg: Color, border: Color, radius := 10, margin := 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.6
	s.content_margin_bottom = margin * 0.6
	s.anti_aliasing = true
	return s


static func label(text: String, size := 24, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 3)
	return l


## Big condensed title text (Teko).
static func title(text: String, size := 48, color := Color.WHITE) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", FONT_TITLE)
	return l


static func button(text: String, callback: Callable, min_height := 56) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = min_height
	b.pressed.connect(callback)
	return b


## The big gold call-to-action button (START, LOG IN...).
static func primary_button(text: String, callback: Callable, min_height := 76, font_size := 40) -> Button:
	var b := button(text, callback, min_height)
	b.add_theme_font_override("font", FONT_TITLE)
	b.add_theme_font_size_override("font_size", font_size)
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		var st := StyleBoxFlat.new()
		st.bg_color = ACCENT.lightened(0.08) if state == "hover" else ACCENT
		if state.contains("pressed"):
			st.bg_color = ACCENT.darkened(0.15)
		st.set_corner_radius_all(10)
		st.shadow_color = Color(ACCENT, 0.35)
		st.shadow_size = 14
		st.anti_aliasing = true
		b.add_theme_stylebox_override(state, st)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, Color(0.08, 0.06, 0.0))
	return b
