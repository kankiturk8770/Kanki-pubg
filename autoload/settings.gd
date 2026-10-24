extends Node
## Player preferences, saved on the device (name, server address,
## sensitivity, and the layout of the on-screen buttons).

signal changed

const PATH := "user://settings.cfg"

var player_name := "Player"
var server_ip := "127.0.0.1"
var server_port := 7777

var look_sensitivity := 1.0   # finger drag on screen
var ads_sensitivity := 0.6    # multiplier while aiming down sights
var mouse_sensitivity := 1.0  # PC mouse
var button_opacity := 0.75

## id -> {"pos": Vector2 (0..1 of the screen), "scale": float}
var layout := {}


func _ready() -> void:
	_setup_input_map()
	load_settings()
	_maybe_take_screenshot()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	player_name = cfg.get_value("player", "name", player_name)
	server_ip = cfg.get_value("network", "ip", server_ip)
	server_port = cfg.get_value("network", "port", server_port)
	look_sensitivity = cfg.get_value("controls", "look_sensitivity", look_sensitivity)
	ads_sensitivity = cfg.get_value("controls", "ads_sensitivity", ads_sensitivity)
	mouse_sensitivity = cfg.get_value("controls", "mouse_sensitivity", mouse_sensitivity)
	button_opacity = cfg.get_value("controls", "button_opacity", button_opacity)
	layout = cfg.get_value("controls", "layout", {})


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "name", player_name)
	cfg.set_value("network", "ip", server_ip)
	cfg.set_value("network", "port", server_port)
	cfg.set_value("controls", "look_sensitivity", look_sensitivity)
	cfg.set_value("controls", "ads_sensitivity", ads_sensitivity)
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("controls", "button_opacity", button_opacity)
	cfg.set_value("controls", "layout", layout)
	cfg.save(PATH)
	changed.emit()


## True on phones/tablets. Start the game with "-- --touch" to test touch UI on PC.
func use_touch_controls() -> bool:
	return OS.has_feature("mobile") or "--touch" in OS.get_cmdline_user_args()


## Keyboard and mouse bindings for playing (and testing) on PC.
func _setup_input_map() -> void:
	_add_key("move_forward", KEY_W)
	_add_key("move_back", KEY_S)
	_add_key("move_left", KEY_A)
	_add_key("move_right", KEY_D)
	_add_key("jump", KEY_SPACE)
	_add_key("crouch", KEY_C)
	_add_key("reload", KEY_R)
	_add_key("scoreboard", KEY_TAB)
	_add_mouse("fire", MOUSE_BUTTON_LEFT)
	_add_mouse("aim", MOUSE_BUTTON_RIGHT)


func _add_key(action: StringName, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action, ev)


func _add_mouse(action: StringName, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


## Developer helper: "-- --screenshot=out.png --shot-delay=8" saves a picture and quits.
func _maybe_take_screenshot() -> void:
	var path := ""
	var wait := 5.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			path = arg.get_slice("=", 1)
		elif arg.begins_with("--shot-delay="):
			wait = float(arg.get_slice("=", 1))
	if path == "":
		return
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
