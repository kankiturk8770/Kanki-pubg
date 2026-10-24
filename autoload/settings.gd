extends Node
## Player preferences, saved on the device: name, server address,
## sensitivity (per scope, like PUBG), gyroscope, graphics and the layout
## of the on-screen buttons.

signal changed

const PATH := "user://settings.cfg"

## Scopes in the order they are shown. "tpp" = no scope (normal camera).
const SCOPES := ["tpp", "red_dot", "2x", "3x", "4x", "6x", "8x"]
const SCOPE_NAMES := {
	"tpp": "No scope (TPP)", "red_dot": "Red dot / Holo", "2x": "2x scope",
	"3x": "3x scope", "4x": "4x scope", "6x": "6x scope", "8x": "8x scope",
}
## Default sensitivity in percent (100% = normal).
const DEFAULT_DRAG := {"tpp": 100, "red_dot": 55, "2x": 35, "3x": 25, "4x": 20, "6x": 14, "8x": 10}
const DEFAULT_GYRO := {"tpp": 300, "red_dot": 300, "2x": 250, "3x": 200, "4x": 160, "6x": 110, "8x": 80}

enum Gyro { OFF, SCOPE_ONLY, ALWAYS }
enum Quality { LOW, MEDIUM, HIGH }
const FPS_OPTIONS := [30, 60, 90, 120]

var player_name := "Player"
var account := ""  # logged-in account name ("" = not logged in / offline)
var character := 0  # scripts/characters.gd: MALE / FEMALE
var weapon := "m416"  # scripts/weapons.gd
var server_ip := "127.0.0.1"
var server_port := 7777

var drag_sensitivity := DEFAULT_DRAG.duplicate()
var gyro_sensitivity := DEFAULT_GYRO.duplicate()
var gyro_mode := Gyro.SCOPE_ONLY
var gyro_invert_x := false
var gyro_invert_y := false
var mouse_sensitivity := 1.0
var auto_sprint := true

var quality := Quality.MEDIUM
var fps_limit := 60
var show_fps := false

var button_opacity := 0.75
## id -> {"pos": Vector2 (0..1 of the screen), "scale": float}
var layout := {}


func _ready() -> void:
	_setup_input_map()
	load_settings()
	apply_graphics()
	_maybe_take_screenshot()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	player_name = cfg.get_value("player", "name", player_name)
	account = cfg.get_value("player", "account", account)
	character = cfg.get_value("player", "character", character)
	weapon = cfg.get_value("player", "weapon", weapon)
	server_ip = cfg.get_value("network", "ip", server_ip)
	server_port = cfg.get_value("network", "port", server_port)
	drag_sensitivity.merge(cfg.get_value("controls", "drag_sensitivity", {}), true)
	gyro_sensitivity.merge(cfg.get_value("controls", "gyro_sensitivity", {}), true)
	gyro_mode = cfg.get_value("controls", "gyro_mode", gyro_mode)
	gyro_invert_x = cfg.get_value("controls", "gyro_invert_x", gyro_invert_x)
	gyro_invert_y = cfg.get_value("controls", "gyro_invert_y", gyro_invert_y)
	mouse_sensitivity = cfg.get_value("controls", "mouse_sensitivity", mouse_sensitivity)
	auto_sprint = cfg.get_value("controls", "auto_sprint", auto_sprint)
	button_opacity = cfg.get_value("controls", "button_opacity", button_opacity)
	layout = cfg.get_value("controls", "layout", {})
	quality = cfg.get_value("graphics", "quality", quality)
	fps_limit = cfg.get_value("graphics", "fps_limit", fps_limit)
	show_fps = cfg.get_value("graphics", "show_fps", show_fps)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "name", player_name)
	cfg.set_value("player", "account", account)
	cfg.set_value("player", "character", character)
	cfg.set_value("player", "weapon", weapon)
	cfg.set_value("network", "ip", server_ip)
	cfg.set_value("network", "port", server_port)
	cfg.set_value("controls", "drag_sensitivity", drag_sensitivity)
	cfg.set_value("controls", "gyro_sensitivity", gyro_sensitivity)
	cfg.set_value("controls", "gyro_mode", gyro_mode)
	cfg.set_value("controls", "gyro_invert_x", gyro_invert_x)
	cfg.set_value("controls", "gyro_invert_y", gyro_invert_y)
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("controls", "auto_sprint", auto_sprint)
	cfg.set_value("controls", "button_opacity", button_opacity)
	cfg.set_value("controls", "layout", layout)
	cfg.set_value("graphics", "quality", quality)
	cfg.set_value("graphics", "fps_limit", fps_limit)
	cfg.set_value("graphics", "show_fps", show_fps)
	cfg.save(PATH)
	apply_graphics()
	changed.emit()


## Finger-drag sensitivity for a scope, as a multiplier (1.0 = 100%).
func drag_factor(scope: String) -> float:
	return drag_sensitivity.get(scope, 100) / 100.0


## Gyroscope sensitivity for a scope (0 when the gyro is off for it).
func gyro_factor(scope: String) -> float:
	if gyro_mode == Gyro.OFF or (gyro_mode == Gyro.SCOPE_ONLY and scope == "tpp"):
		return 0.0
	return gyro_sensitivity.get(scope, 100) / 100.0


func reset_sensitivity() -> void:
	drag_sensitivity = DEFAULT_DRAG.duplicate()
	gyro_sensitivity = DEFAULT_GYRO.duplicate()


## FPS limit, physics rate, resolution, shadows and anti-aliasing.
func apply_graphics() -> void:
	var dedicated := DisplayServer.get_name() == "headless"
	Engine.max_fps = 0 if dedicated else fps_limit
	# Movement runs in physics steps: match the frame rate so 90/120 FPS are smooth.
	Engine.physics_ticks_per_second = 60 if dedicated else maxi(60, fps_limit)
	if dedicated:
		return
	DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if fps_limit <= 60 else DisplayServer.VSYNC_DISABLED)
	var root := get_tree().root
	match quality:
		Quality.LOW:
			root.scaling_3d_scale = 0.7
			root.msaa_3d = Viewport.MSAA_DISABLED
		Quality.MEDIUM:
			root.scaling_3d_scale = 0.85
			root.msaa_3d = Viewport.MSAA_DISABLED
		Quality.HIGH:
			root.scaling_3d_scale = 1.0
			root.msaa_3d = Viewport.MSAA_2X
	for sun in get_tree().get_nodes_in_group("sun"):
		sun.shadow_enabled = quality != Quality.LOW


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
	_add_key("sprint", KEY_SHIFT)
	_add_key("peek_left", KEY_Q)
	_add_key("peek_right", KEY_E)
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
