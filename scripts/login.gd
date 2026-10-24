extends Control
## Log in / sign up. Accounts live on our game server (autoload/accounts.gd).
## Sign up also picks the character (male / female) everyone will see.
## "Play offline" skips the account (LAN games).

const UI := preload("res://scripts/ui/ui_theme.gd")
const Characters := preload("res://scripts/characters.gd")
const BG := preload("res://assets/ui/splash_bg.jpg")
const PORTRAITS := [preload("res://assets/ui/portrait_male.png"), preload("res://assets/ui/portrait_female.png")]
const LOBBY_SCENE := "res://scenes/main_menu.tscn"

var _sign_up := false
var _character := Characters.MALE
var _panel: PanelContainer
var _form: VBoxContainer
var _name_edit: LineEdit
var _pass_edit: LineEdit
var _ip_edit: LineEdit
var _status: Label
var _submit: Button
var _tabs: Array[Button] = []
var _cards: Array[Button] = []
var _pick_box: Control


func _ready() -> void:
	theme = UI.make()
	_build_background()
	_build_logo()
	_panel = PanelContainer.new()
	UI.glass(_panel)
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -520
	_panel.offset_right = -48
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)
	if Settings.account != "":
		_build_welcome()
	else:
		_build_form()
	Accounts.finished.connect(_on_finished)
	modulate = Color.BLACK
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.5)


func _build_background() -> void:
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	var bg := TextureRect.new()
	bg.texture = BG
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(0.75, 0.75, 0.75)
	add_child(bg)
	# Black fades from the right (behind the form) and the bottom
	for fill in [[Vector2(0.35, 0), Vector2(1, 0)], [Vector2(0, 0.55), Vector2(0, 1)]]:
		var shade := TextureRect.new()
		var grad := GradientTexture2D.new()
		grad.gradient = Gradient.new()
		grad.gradient.set_color(0, Color(0, 0, 0, 0))
		grad.gradient.set_color(1, Color(0, 0, 0, 0.9))
		grad.fill_from = fill[0]
		grad.fill_to = fill[1]
		shade.texture = grad
		shade.stretch_mode = TextureRect.STRETCH_SCALE
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(shade)


func _build_logo() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -14)
	col.anchor_top = 1.0
	col.anchor_bottom = 1.0
	col.offset_left = 56
	col.offset_top = -230
	col.offset_right = 700
	col.offset_bottom = -40
	add_child(col)
	var logo := UI.title("KANKI", 120, UI.ACCENT)
	logo.add_theme_constant_override("outline_size", 0)
	col.add_child(logo)
	col.add_child(UI.label("TEAM DEATHMATCH  ·  5 v 5", 24, Color(1, 1, 1, 0.8)))


func _clear_panel() -> void:
	for c in _panel.get_children():
		c.queue_free()
	_tabs.clear()
	_cards.clear()


## Remembered account: one tap to the lobby.
func _build_welcome() -> void:
	_clear_panel()
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	_panel.add_child(col)
	col.add_child(UI.label("WELCOME BACK", 20, UI.TEXT_DIM))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	col.add_child(row)
	var face := TextureRect.new()
	face.texture = PORTRAITS[clampi(Settings.character, 0, 1)]
	face.custom_minimum_size = Vector2(96, 96)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	row.add_child(face)
	row.add_child(UI.title(Settings.account, 64))
	col.add_child(UI.primary_button("TAP TO START", _go_lobby, 84, 44))
	var other := Button.new()
	other.text = "Switch account"
	other.flat = true
	other.pressed.connect(func() -> void:
		Settings.account = ""
		Settings.save_settings()
		_build_form())
	col.add_child(other)


func _build_form() -> void:
	_clear_panel()
	_form = VBoxContainer.new()
	_form.add_theme_constant_override("separation", 12)
	_panel.add_child(_form)

	var tabs := HBoxContainer.new()
	_form.add_child(tabs)
	for i in 2:
		var tab := UI.button(["LOG IN", "SIGN UP"][i], _set_mode.bind(i == 1), 48)
		tab.toggle_mode = true
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(tab)
		_tabs.append(tab)

	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Player name"
	_name_edit.max_length = 16
	_name_edit.text = Settings.player_name if Settings.player_name != "Player" else ""
	_name_edit.custom_minimum_size.y = 54
	_form.add_child(_name_edit)
	_pass_edit = LineEdit.new()
	_pass_edit.placeholder_text = "Password"
	_pass_edit.secret = true
	_pass_edit.custom_minimum_size.y = 54
	_pass_edit.text_submitted.connect(func(_t: String) -> void: _submit_form())
	_form.add_child(_pass_edit)

	# Character choice (sign up only)
	var pick := VBoxContainer.new()
	pick.add_child(UI.label("CHOOSE YOUR CHARACTER", 18, UI.TEXT_DIM))
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	pick.add_child(cards)
	for i in 2:
		var card := Button.new()
		card.toggle_mode = true
		card.custom_minimum_size = Vector2(0, 170)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.icon = PORTRAITS[i]
		card.expand_icon = true
		card.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		card.text = Characters.NAMES[i]
		card.pressed.connect(_pick.bind(i))
		cards.add_child(card)
		_cards.append(card)
	_pick_box = pick
	_form.add_child(pick)

	var server := HBoxContainer.new()
	server.add_child(UI.label("Server", 18, UI.TEXT_DIM))
	_ip_edit = LineEdit.new()
	_ip_edit.text = Settings.server_ip
	_ip_edit.placeholder_text = "Server IP"
	_ip_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	server.add_child(_ip_edit)
	_form.add_child(server)

	_submit = UI.primary_button("LOG IN", _submit_form)
	_form.add_child(_submit)
	_status = UI.label("", 18, Color("ff6b5e"))
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	_form.add_child(_status)
	var offline := Button.new()
	offline.text = "Play offline (LAN)"
	offline.flat = true
	offline.pressed.connect(_go_lobby)
	_form.add_child(offline)
	_set_mode(false)
	_pick(Settings.character)


func _set_mode(sign_up: bool) -> void:
	_sign_up = sign_up
	_tabs[0].button_pressed = not sign_up
	_tabs[1].button_pressed = sign_up
	_pick_box.visible = sign_up
	_submit.text = "CREATE ACCOUNT" if sign_up else "LOG IN"
	_status.text = ""


func _pick(character: int) -> void:
	_character = clampi(character, 0, 1)
	for i in _cards.size():
		_cards[i].button_pressed = i == _character


func _submit_form() -> void:
	var user := _name_edit.text.strip_edges()
	if user.length() < 3:
		_status.text = "Enter your player name (3-16 letters)."
		return
	if _pass_edit.text.length() < 4:
		_status.text = "Password: at least 4 characters."
		return
	Settings.server_ip = _ip_edit.text.strip_edges()
	Settings.save_settings()
	_status.add_theme_color_override("font_color", UI.TEXT_DIM)
	_status.text = "Connecting..."
	_submit.disabled = true
	Accounts.request(Settings.server_ip, Settings.server_port, user, _pass_edit.text, _sign_up, _character)


func _on_finished(ok: bool, message: String) -> void:
	if ok:
		_go_lobby()
		return
	_submit.disabled = false
	_status.add_theme_color_override("font_color", Color("ff6b5e"))
	_status.text = message


func _go_lobby() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate", Color.BLACK, 0.35)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file(LOBBY_SCENE))
