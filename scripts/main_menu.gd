extends Control
## First screen: enter your name and the server IP, then JOIN.
##
## Command line options (put them after "--"):
##   --server            run as dedicated server (also automatic with --headless)
##   --port=7777         server port
##   --join=1.2.3.4      join a server straight away (used for testing)
##   --name=Ali          player name for --join

const UI := preload("res://scripts/ui/ui_theme.gd")
const TouchControls := preload("res://scripts/hud/touch_controls.gd")
const LayoutEditor := preload("res://scripts/hud/layout_editor.gd")
const SettingsPanel := preload("res://scripts/ui/settings_panel.gd")
const GAME_SCENE := "res://scenes/game.tscn"

var name_edit: LineEdit
var ip_edit: LineEdit
var status_label: Label


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
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 460
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var title := UI.label("KANKI TDM", 64, UI.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := UI.label("Team Deathmatch  -  5 vs 5  -  first to 40 kills", 20, Color(0.75, 0.78, 0.82))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Your name"
	name_edit.text = Settings.player_name
	name_edit.max_length = 16
	name_edit.custom_minimum_size.y = 52
	box.add_child(name_edit)

	ip_edit = LineEdit.new()
	ip_edit.placeholder_text = "Server IP (example: 185.10.20.30)"
	ip_edit.text = Settings.server_ip
	ip_edit.custom_minimum_size.y = 52
	box.add_child(ip_edit)

	var join := UI.button("JOIN MATCH", _on_join, 70)
	join.add_theme_font_size_override("font_size", 30)
	box.add_child(join)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	for b in [
		UI.button("HOST (LAN)", _on_host),
		UI.button("CONTROLS", _on_controls),
		UI.button("SETTINGS", _on_settings),
	]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)

	status_label = UI.label("", 20, Color("ff6b5e"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(status_label)


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
	_go_to_game()


func _on_host() -> void:
	_save_fields()
	Network.mode = Network.Mode.HOST
	Network.player_name = Settings.player_name
	_go_to_game()


func _on_controls() -> void:
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.25, 0.3, 0.27)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
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
