extends Control
## First screen: cinematic picture, the KANKI logo and a loading bar,
## then the login screen.
## Test/server runs skip it: --server, --join=..., or headless go straight
## to main_menu.gd (which handles them), --lobby goes straight to the lobby.

const UI := preload("res://scripts/ui/ui_theme.gd")
const BG := preload("res://assets/ui/splash_bg.jpg")
const LOGIN_SCENE := "res://scenes/login.tscn"
const LOBBY_SCENE := "res://scenes/main_menu.tscn"
const DURATION := 3.2

var _bar: ColorRect


func _ready() -> void:
	var skip := DisplayServer.get_name() == "headless"
	for arg in OS.get_cmdline_user_args():
		if arg == "--server" or arg.begins_with("--join=") or arg == "--lobby":
			skip = true
	if skip:
		get_tree().change_scene_to_file.call_deferred(LOBBY_SCENE)
		return
	_build()
	_play()


func _build() -> void:
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(black)

	var bg := TextureRect.new()
	bg.name = "Picture"
	bg.texture = BG
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.modulate.a = 0.0
	add_child(bg)

	# Darken the edges and the bottom so the logo stands out (AMOLED black)
	var shade := TextureRect.new()
	var grad := GradientTexture2D.new()
	grad.gradient = Gradient.new()
	grad.gradient.set_color(0, Color(0, 0, 0, 0.0))
	grad.gradient.set_color(1, Color(0, 0, 0, 0.92))
	grad.fill = GradientTexture2D.FILL_RADIAL
	grad.fill_from = Vector2(0.5, 0.42)
	grad.fill_to = Vector2(1.05, 1.05)
	shade.texture = grad
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(shade)

	var col := VBoxContainer.new()
	col.name = "Logo"
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", -18)
	col.modulate.a = 0.0
	add_child(col)
	var logo := UI.title("KANKI", 190, UI.ACCENT)
	var spaced := FontVariation.new()
	spaced.base_font = UI.FONT_TITLE
	spaced.variation_opentype = {"wght": 700}
	spaced.spacing_glyph = 14
	logo.add_theme_font_override("font", spaced)
	logo.add_theme_constant_override("outline_size", 0)
	logo.add_theme_color_override("font_shadow_color", Color(UI.ACCENT, 0.45))
	logo.add_theme_constant_override("shadow_outline_size", 22)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(logo)
	var sub := UI.label("T E A M    D E A T H M A T C H", 28, Color(1, 1, 1, 0.85))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)

	# Thin loading bar at the bottom
	var track := ColorRect.new()
	track.color = Color(1, 1, 1, 0.12)
	track.anchor_left = 0.3
	track.anchor_right = 0.7
	track.anchor_top = 1.0
	track.anchor_bottom = 1.0
	track.offset_top = -70
	track.offset_bottom = -67
	add_child(track)
	_bar = ColorRect.new()
	_bar.color = UI.ACCENT
	_bar.anchor_bottom = 1.0
	track.add_child(_bar)
	var hint := UI.label("LOADING", 18, UI.TEXT_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_top = -60
	hint.offset_bottom = -36
	hint.offset_left = -100
	hint.offset_right = 100
	add_child(hint)


func _play() -> void:
	var pic := get_node("Picture") as TextureRect
	pic.pivot_offset = size / 2
	var t := create_tween().set_parallel()
	t.tween_property(pic, "modulate:a", 0.9, 1.4).set_ease(Tween.EASE_OUT)
	t.tween_property(pic, "scale", Vector2.ONE * 1.08, DURATION + 0.6).from(Vector2.ONE)
	t.tween_property(get_node("Logo"), "modulate:a", 1.0, 0.9).set_delay(0.5)
	t.tween_property(_bar, "anchor_right", 1.0, DURATION - 0.4).from(0.0).set_delay(0.3)
	t.chain().tween_property(self, "modulate", Color.BLACK, 0.45)
	t.chain().tween_callback(func() -> void:
		get_tree().change_scene_to_file(LOGIN_SCENE))
