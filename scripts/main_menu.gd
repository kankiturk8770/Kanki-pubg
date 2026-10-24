extends Control
## Lobby: the soldier stands in the middle (drag to turn him around),
## profile at the top-left, START at the bottom-left.
##
## Command line options (put them after "--"):
##   --server            run as dedicated server (also automatic with --headless)
##   --port=7777         server port
##   --join=1.2.3.4      join a server straight away (used for testing)
##   --name=Ali          player name for --join
##   --character=1       character for --join (0 male, 1 female)
##   --weapon=akm        weapon for --join (m416, akm, ump45)

const UI := preload("res://scripts/ui/ui_theme.gd")
const TouchControls := preload("res://scripts/hud/touch_controls.gd")
const LayoutEditor := preload("res://scripts/hud/layout_editor.gd")
const SettingsPanel := preload("res://scripts/ui/settings_panel.gd")
const Characters := preload("res://scripts/characters.gd")
const GAME_SCENE := "res://scenes/game.tscn"
const START_YELLOW := Color("f6c21c")

var name_edit: LineEdit
var ip_edit: LineEdit
var status_label: Label
var _soldier: Node3D
var _stage: Node3D
var _character_buttons: Array[Button] = []


func _ready() -> void:
	var opts := _parse_args()
	if opts.has("port"):
		Network.port = int(opts["port"])
	else:
		Network.port = Settings.server_port

	if opts.has("join"):
		Network.mode = Network.Mode.CLIENT
		Network.address = opts["join"]
		Network.player_name = opts.get("name", "Tester")
		Network.character = int(opts.get("character", "0"))
		Network.weapon = opts.get("weapon", "m416")
		_go_to_game()
		return
	if opts.has("server") or DisplayServer.get_name() == "headless":
		Network.mode = Network.Mode.SERVER
		_go_to_game()
		return

	theme = UI.make()
	_build_ui()
	if Network.last_error != "":
		status_label.text = Network.last_error
		Network.last_error = ""


func _build_ui() -> void:
	_build_stage()

	# Dark gradient at the left and bottom so text stays readable
	var shade := TextureRect.new()
	var grad := GradientTexture2D.new()
	grad.gradient = Gradient.new()
	grad.gradient.set_color(0, Color(0, 0, 0, 0.75))
	grad.gradient.set_color(1, Color(0, 0, 0, 0))
	grad.fill_to = Vector2(0.55, 0)
	shade.texture = grad
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	_build_profile()
	_build_start_area()
	_build_side_buttons()

	var title := UI.label("KANKI TDM", 30, UI.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor(title, 0.5, 0, Rect2(-200, 12, 400, 40))
	add_child(title)
	var hint := UI.label("Drag to rotate", 16, Color(1, 1, 1, 0.55))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor(hint, 0.5, 1, Rect2(-150, -40, 300, 30))
	add_child(hint)


## 3D background: the soldier on a platform.
func _build_stage() -> void:
	var holder := SubViewportContainer.new()
	holder.stretch = true
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	var vp := SubViewport.new()
	vp.msaa_3d = Viewport.MSAA_2X
	holder.add_child(vp)

	var stage := Node3D.new()
	vp.add_child(stage)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.13, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	# Neutral light so skin and clothes keep their real colours
	env.ambient_light_color = Color(0.66, 0.66, 0.68)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	stage.add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, 25, 0)
	key.light_energy = 1.25
	key.light_color = Color(1.0, 0.96, 0.9)
	key.shadow_enabled = true
	stage.add_child(key)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-1.5, 2.5, -2.0)
	rim.light_color = Color(0.8, 0.88, 1.0)
	rim.light_energy = 1.5
	rim.omni_range = 6.0
	stage.add_child(rim)

	# Back wall with light strips (hangar look)
	_stage_box(stage, Vector3(0, 3, -4), Vector3(14, 6, 0.2), Color(0.16, 0.19, 0.24))
	for x in [-4.5, -1.5, 1.5, 4.5]:
		_stage_box(stage, Vector3(x, 3.2, -3.85), Vector3(0.12, 4.5, 0.05), Color(0.6, 0.8, 1.0), true)
	_stage_box(stage, Vector3(0, -0.05, 0), Vector3(14, 0.1, 10), Color(0.2, 0.22, 0.26))
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.1
	cyl.bottom_radius = 1.15
	cyl.height = 0.12
	var disc_mat := StandardMaterial3D.new()
	disc_mat.albedo_color = Color(0.3, 0.33, 0.38)
	disc_mat.metallic = 0.7
	disc_mat.roughness = 0.35
	cyl.material = disc_mat
	disc.mesh = cyl
	disc.position.y = 0.06
	stage.add_child(disc)

	_stage = stage
	_show_character()

	var cam := Camera3D.new()
	cam.fov = 40
	stage.add_child(cam)
	cam.look_at_from_position(Vector3(0.35, 1.25, 4.3), Vector3(0.35, 1.0, 0))


## Puts the character picked in the profile on the stage (blue uniform).
func _show_character() -> void:
	var yaw := deg_to_rad(-20)
	if _soldier:
		yaw = _soldier.rotation.y
		_soldier.queue_free()
	_soldier = Characters.make(Settings.character, 0)
	_soldier.position.y = 0.12
	_soldier.rotation.y = yaw
	_stage.add_child(_soldier)
	var ap: AnimationPlayer = _soldier.find_child("AnimationPlayer", true, false)
	ap.get_animation("lobby_idle").loop_mode = Animation.LOOP_LINEAR
	ap.play("lobby_idle")


func _pick_character(character: int) -> void:
	Settings.character = character
	Settings.save_settings()
	for i in _character_buttons.size():
		_character_buttons[i].button_pressed = i == character
	_show_character()


func _stage_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, glow := false) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.8
	bm.material = mat
	mi.mesh = bm
	mi.position = pos
	parent.add_child(mi)


func _build_profile() -> void:
	var panel := PanelContainer.new()
	_anchor(panel, 0, 0, Rect2(16, 16, 340, 150))
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var avatar := PanelContainer.new()
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = UI.ACCENT.darkened(0.3)
	avatar_style.set_corner_radius_all(6)
	avatar.add_theme_stylebox_override("panel", avatar_style)
	avatar.custom_minimum_size = Vector2(64, 64)
	var initial := UI.label(Settings.player_name.left(1).to_upper(), 36)
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(initial)
	row.add_child(avatar)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Your name"
	name_edit.text = Settings.player_name
	name_edit.max_length = 16
	name_edit.text_changed.connect(func(t): initial.text = t.left(1).to_upper())
	col.add_child(name_edit)
	col.add_child(UI.label("Tap the name to change it", 14, Color(1, 1, 1, 0.6)))

	# Character: everyone plays the one they pick here (team only changes the uniform colour)
	var pick := HBoxContainer.new()
	col.add_child(pick)
	for i in Characters.NAMES.size():
		var b := UI.button(Characters.NAMES[i], _pick_character.bind(i), 40)
		b.toggle_mode = true
		b.button_pressed = i == Settings.character
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pick.add_child(b)
		_character_buttons.append(b)


func _build_start_area() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_anchor(box, 0, 1, Rect2(16, -250, 360, 234))
	add_child(box)

	status_label = UI.label("", 18, Color("ff6b5e"))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(status_label)

	var mode := PanelContainer.new()
	box.add_child(mode)
	var mode_col := VBoxContainer.new()
	mode.add_child(mode_col)
	mode_col.add_child(UI.label("Team Deathmatch  -  Warehouse  -  TPP", 18, UI.ACCENT))
	var ip_row := HBoxContainer.new()
	mode_col.add_child(ip_row)
	ip_row.add_child(UI.label("Server", 18))
	ip_edit = LineEdit.new()
	ip_edit.placeholder_text = "Server IP (example: 185.10.20.30)"
	ip_edit.text = Settings.server_ip
	ip_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ip_row.add_child(ip_edit)

	var start := Button.new()
	start.text = "START"
	start.custom_minimum_size.y = 84
	start.add_theme_font_size_override("font_size", 44)
	for state in ["normal", "hover", "pressed", "focus"]:
		var st := StyleBoxFlat.new()
		st.bg_color = START_YELLOW.darkened(0.15) if state == "pressed" else START_YELLOW
		if state == "hover":
			st.bg_color = START_YELLOW.lightened(0.1)
		st.set_corner_radius_all(4)
		start.add_theme_stylebox_override(state, st)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		start.add_theme_color_override(c, Color(0.1, 0.08, 0.02))
	start.pressed.connect(_on_join)
	box.add_child(start)


func _build_side_buttons() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_anchor(col, 1, 0.5, Rect2(-200, -110, 184, 220))
	add_child(col)
	col.add_child(UI.button("CONTROLS", _on_controls))
	col.add_child(UI.button("SETTINGS", _on_settings))
	col.add_child(UI.button("HOST (LAN)", _on_host))


func _anchor(c: Control, ax: float, ay: float, rect: Rect2) -> void:
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = rect.position.x
	c.offset_top = rect.position.y
	c.offset_right = rect.end.x
	c.offset_bottom = rect.end.y


## Drag anywhere on the empty part of the screen to turn the soldier.
## (On phones a finger drag also arrives as a mouse drag.)
func _unhandled_input(event: InputEvent) -> void:
	if _soldier and event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_soldier.rotation.y += event.relative.x * 0.01


func _save_fields() -> void:
	var n := name_edit.text.strip_edges()
	Settings.player_name = n if n != "" else "Player"
	Settings.server_ip = ip_edit.text.strip_edges()
	Settings.save_settings()


func _on_join() -> void:
	_save_fields()
	if Settings.server_ip == "":
		status_label.text = "Enter the server IP first."
		return
	Network.mode = Network.Mode.CLIENT
	Network.address = Settings.server_ip
	Network.player_name = Settings.player_name
	Network.character = Settings.character
	Network.weapon = Settings.weapon
	_go_to_game()


func _on_host() -> void:
	_save_fields()
	Network.mode = Network.Mode.HOST
	Network.player_name = Settings.player_name
	Network.character = Settings.character
	Network.weapon = Settings.weapon
	_go_to_game()


func _on_controls() -> void:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.25, 0.3, 0.27)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(bg)
	var controls := TouchControls.new()
	screen.add_child(controls)
	var editor := LayoutEditor.new()
	editor.controls = controls
	editor.closed.connect(screen.queue_free)
	screen.add_child(editor)
	add_child(screen)


func _on_settings() -> void:
	var panel := SettingsPanel.new()
	panel.edit_controls_requested.connect(_on_controls)
	add_child(panel)


func _go_to_game() -> void:
	get_tree().change_scene_to_file.call_deferred(GAME_SCENE)


func _parse_args() -> Dictionary:
	var opts := {}
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var parts := arg.trim_prefix("--").split("=", true, 1)
		opts[parts[0]] = parts[1] if parts.size() > 1 else ""
	return opts
