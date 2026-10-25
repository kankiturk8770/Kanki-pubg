extends Control
## Lobby: the player's character stands in a hangar holding the chosen gun
## (drag to turn it). Glass panels: profile bar at the top, loadout
## (character + weapon) on the left, START at the bottom-left.
##
## Command line options (put them after "--"):
##   --server            run as dedicated server (also automatic with --headless)
##   --port=7777         server port
##   --join=1.2.3.4      join a server straight away (used for testing)
##   --name=Ali          player name for --join
##   --character=1       character for --join (0 male, 1 female)
##   --weapon=akm        weapon for --join (m416, akm, ump45)
##   --lobby             skip the splash and login screens

const UI := preload("res://scripts/ui/ui_theme.gd")
const TouchControls := preload("res://scripts/hud/touch_controls.gd")
const LayoutEditor := preload("res://scripts/hud/layout_editor.gd")
const SettingsPanel := preload("res://scripts/ui/settings_panel.gd")
const Characters := preload("res://scripts/characters.gd")
const Weapons := preload("res://scripts/weapons.gd")
const WeaponHolder := preload("res://scripts/weapon_holder.gd")
const HandGrip := preload("res://scripts/hand_grip.gd")
const BG := preload("res://assets/ui/lobby_bg.jpg")
const PORTRAITS := [preload("res://assets/ui/portrait_male.png"), preload("res://assets/ui/portrait_female.png")]
const GAME_SCENE := "res://scenes/game.tscn"
const LOGIN_SCENE := "res://scenes/login.tscn"

var name_edit: LineEdit
var ip_edit: LineEdit
var status_label: Label
var _soldier: Node3D
var _stage: Node3D
var _avatar: TextureRect
var _character_buttons: Array[Button] = []
var _weapon_cards := {}


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
	modulate = Color.BLACK
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.4)


func _build_ui() -> void:
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	var bg := TextureRect.new()
	bg.texture = BG
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_build_stage()
	# Deep black at the top, left and bottom edges: panels stay readable
	for fill in [[Vector2(0, 0), Vector2(0.5, 0)], [Vector2(0, 1), Vector2(0, 0.55)], [Vector2(0, 0), Vector2(0, 0.22)]]:
		_shade(fill[0], fill[1])

	_build_top_bar()
	_build_loadout()
	_build_start_area()
	var hint := UI.label("Drag to rotate", 16, Color(1, 1, 1, 0.45))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor(hint, 0.62, 1, Rect2(-150, -36, 300, 28))
	add_child(hint)


func _shade(from: Vector2, to: Vector2) -> void:
	var shade := TextureRect.new()
	var grad := GradientTexture2D.new()
	grad.gradient = Gradient.new()
	grad.gradient.set_color(0, Color(0, 0, 0, 0.85))
	grad.gradient.set_color(1, Color(0, 0, 0, 0))
	grad.fill_from = from
	grad.fill_to = to
	shade.texture = grad
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


## The character in 3D over the hangar picture (transparent viewport).
func _build_stage() -> void:
	var holder := SubViewportContainer.new()
	holder.stretch = true
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	holder.add_child(vp)

	var stage := Node3D.new()
	vp.add_child(stage)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.64, 0.72)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	stage.add_child(we)

	# Cool ceiling LEDs from above, amber accent from the back like the picture
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-50, 20, 0)
	key.light_energy = 1.1
	key.light_color = Color(0.92, 0.95, 1.0)
	stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-15, 160, 0)
	rim.light_color = Color(1.0, 0.75, 0.45)
	rim.light_energy = 1.2
	stage.add_child(rim)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-10, -120, 0)
	fill.light_color = Color(0.45, 0.6, 1.0)
	fill.light_energy = 0.6
	stage.add_child(fill)

	# Soft contact shadow on the glossy floor
	var blob := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.6, 1.0)
	var grad := GradientTexture2D.new()
	grad.gradient = Gradient.new()
	grad.gradient.set_color(0, Color(0, 0, 0, 0.75))
	grad.gradient.set_color(1, Color(0, 0, 0, 0))
	grad.fill = GradientTexture2D.FILL_RADIAL
	grad.fill_from = Vector2(0.5, 0.5)
	grad.fill_to = Vector2(1, 0.5)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = grad
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad.material = mat
	blob.mesh = quad
	blob.rotation_degrees.x = -90
	blob.position.y = 0.01
	stage.add_child(blob)

	_stage = stage
	_show_character()

	var cam := Camera3D.new()
	cam.fov = 34
	stage.add_child(cam)
	cam.look_at_from_position(Vector3(-0.55, 1.35, 4.6), Vector3(-0.55, 0.95, 0))


## Puts the player's character on the stage, holding the chosen gun.
func _show_character() -> void:
	var yaw := deg_to_rad(35)   # gun across the body: both hands on it in view
	if _soldier:
		yaw = _soldier.rotation.y
		_soldier.queue_free()
	_soldier = Characters.make(Settings.character, 0, true)
	_soldier.rotation.y = yaw
	_stage.add_child(_soldier)
	var ap: AnimationPlayer = _soldier.find_child("AnimationPlayer", true, false)
	var skeleton: Skeleton3D = _soldier.find_child("Skeleton3D", true, false)
	var holder := WeaponHolder.new()
	holder.setup(skeleton, Settings.weapon, ap)
	var grip := HandGrip.new()
	skeleton.add_child(grip)
	grip.setup(holder, Settings.character, Settings.weapon)
	ap.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
	ap.play("idle")
	if _avatar:
		_avatar.texture = PORTRAITS[clampi(Settings.character, 0, 1)]


func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	UI.glass(bar)
	_anchor(bar, 0, 0, Rect2(16, 14, 470, 84))
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bar.add_child(row)
	_avatar = TextureRect.new()
	_avatar.texture = PORTRAITS[clampi(Settings.character, 0, 1)]
	_avatar.custom_minimum_size = Vector2(60, 60)
	_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	row.add_child(_avatar)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	name_edit = LineEdit.new()
	name_edit.text = Settings.player_name
	name_edit.max_length = 16
	name_edit.flat = true
	name_edit.add_theme_font_override("font", UI.FONT_TITLE)
	name_edit.add_theme_font_size_override("font_size", 34)
	# Logged-in players keep their account name; offline players can rename
	name_edit.editable = Settings.account == ""
	name_edit.add_theme_color_override("font_uneditable_color", Color.WHITE)
	col.add_child(name_edit)
	var online := Settings.account != ""
	col.add_child(UI.label("ONLINE ACCOUNT" if online else "OFFLINE  ·  tap name to edit", 16,
			Color("6fe39a") if online else UI.TEXT_DIM))

	var side := HBoxContainer.new()
	side.add_theme_constant_override("separation", 10)
	_anchor(side, 1, 0, Rect2(-470, 22, 454, 60))
	side.alignment = BoxContainer.ALIGNMENT_END
	add_child(side)
	for item in [["CONTROLS", _on_controls], ["SETTINGS", _on_settings], ["LOG OUT", _on_logout]]:
		var b := UI.button(item[0], item[1], 54)
		b.custom_minimum_size.x = 140
		UI.glass(b)
		side.add_child(b)


## Character and weapon choice.
func _build_loadout() -> void:
	var panel := PanelContainer.new()
	UI.glass(panel)
	_anchor(panel, 0, 0, Rect2(16, 140, 380, 310))
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	col.add_child(UI.title("LOADOUT", 30, UI.ACCENT))

	var pick := HBoxContainer.new()
	col.add_child(pick)
	for i in Characters.NAMES.size():
		var b := UI.button(Characters.NAMES[i], _pick_character.bind(i), 44)
		b.toggle_mode = true
		b.button_pressed = i == Settings.character
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pick.add_child(b)
		_character_buttons.append(b)

	for id in Weapons.ORDER:
		var info: Dictionary = Weapons.LIST[id]
		var card := Button.new()
		card.toggle_mode = true
		card.custom_minimum_size = Vector2(0, 66)
		# Selected card: gold frame (a gold fill would hide the white text)
		var picked := UI._box(Color(0.1, 0.08, 0.02, 0.75), UI.ACCENT)
		picked.set_border_width_all(2)
		card.add_theme_stylebox_override("pressed", picked)
		card.add_theme_stylebox_override("hover_pressed", picked)
		card.pressed.connect(_pick_weapon.bind(id))
		col.add_child(card)
		_weapon_cards[id] = card
		var pic := TextureRect.new()
		pic.texture = load("res://assets/ui/weapon_%s.png" % id)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pic.offset_left = 150
		pic.offset_right = -8
		card.add_child(pic)
		var text := VBoxContainer.new()
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.add_theme_constant_override("separation", -6)
		text.position = Vector2(14, 0)
		card.add_child(text)
		text.add_child(UI.title(info["name"], 30))
		var rpm := roundi(60.0 / info["fire_interval"])
		text.add_child(UI.label("DMG %d  ·  %d RPM" % [info["body_damage"], rpm], 15, UI.TEXT_DIM))
	_mark_weapon()


func _build_start_area() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_anchor(box, 0, 1, Rect2(16, -238, 380, 214))
	add_child(box)

	status_label = UI.label("", 18, Color("ff6b5e"))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(status_label)

	var mode := PanelContainer.new()
	UI.glass(mode)
	box.add_child(mode)
	var mode_col := VBoxContainer.new()
	mode_col.add_theme_constant_override("separation", 2)
	mode.add_child(mode_col)
	mode_col.add_child(UI.label("TEAM DEATHMATCH  ·  WAREHOUSE  ·  TPP", 18, UI.ACCENT))
	var ip_row := HBoxContainer.new()
	mode_col.add_child(ip_row)
	ip_row.add_child(UI.label("Server", 18, UI.TEXT_DIM))
	ip_edit = LineEdit.new()
	ip_edit.placeholder_text = "Server IP (example: 185.10.20.30)"
	ip_edit.text = Settings.server_ip
	ip_edit.flat = true
	ip_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ip_row.add_child(ip_edit)
	var host := Button.new()
	host.text = "HOST (LAN)"
	host.flat = true
	host.pressed.connect(_on_host)
	ip_row.add_child(host)

	box.add_child(UI.primary_button("START", _on_join, 86, 56))


func _pick_character(character: int) -> void:
	Settings.character = character
	Settings.save_settings()
	for i in _character_buttons.size():
		_character_buttons[i].button_pressed = i == character
	_show_character()


func _pick_weapon(id: String) -> void:
	Settings.weapon = id
	Settings.save_settings()
	_mark_weapon()
	_show_character()


func _mark_weapon() -> void:
	for id in _weapon_cards:
		_weapon_cards[id].button_pressed = id == Settings.weapon


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
	_start()


func _on_host() -> void:
	_save_fields()
	Network.mode = Network.Mode.HOST
	_start()


func _start() -> void:
	Network.player_name = Settings.player_name
	Network.character = Settings.character
	Network.weapon = Settings.weapon
	_go_to_game()


func _on_logout() -> void:
	Settings.account = ""
	Settings.save_settings()
	get_tree().change_scene_to_file(LOGIN_SCENE)


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
