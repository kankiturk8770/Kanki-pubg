extends SceneTree
## Records a gameplay video: splash, login, lobby (character and gun
## picks), then a match against AI bots where the player shows what it can
## do: run, sprint, jump, strafe, crouch, aim, shoot, peek, reload, kills.
## Taps are drawn as white circles, like a phone screen recording.
##   godot --path . --script tools/record_demo.gd --write-movie demo.avi \
##       --fixed-fps 30 --resolution 1280x720 -- --touch
##   ffmpeg -i demo.avi -c:v libx264 -crf 20 -pix_fmt yuv420p -c:a aac demo.mp4
## (Movie Maker renders every frame, however slow the computer, so the
## video plays smoothly.)

const TEAMMATES := 2
const ENEMIES := 3
const MATCH_SECONDS := 62.0

var _taps: Control
var _tap_marks := []   # [position, age]
var _game: Node
var _me: CharacterBody3D
var _touch: Control
var _look := Vector2.ZERO   # wanted camera (yaw, pitch); the camera turns to it smoothly
var _steer := false         # the driver turns the camera
var _fighting := false
var _peeked := false
var _stuck_left := 0.0
var _stuck_side := 1.0


func _init() -> void:
	await process_frame
	seed(7)   # same spawns every time
	var settings = get_root().get_node("Settings")
	settings.show_fps = false
	settings.quality = settings.Quality.HIGH
	var layer := CanvasLayer.new()
	layer.layer = 100
	get_root().add_child(layer)
	_taps = Control.new()
	_taps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_taps.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_taps.draw.connect(_draw_taps)
	layer.add_child(_taps)
	process_frame.connect(_every_frame)

	# Splash and login
	change_scene_to_file("res://scenes/splash.tscn")
	await _wait(5.6)
	await _tap_button("TAP TO START")
	await _wait(2.2)

	# Lobby: try the characters and guns
	await _tap_button("FEMALE")
	await _wait(2.2)
	await _tap_weapon("akm")
	await _wait(1.8)
	await _tap_weapon("ump45")
	await _wait(1.8)
	await _tap_button("MALE")
	await _wait(1.8)
	await _tap_weapon("m416")
	await _wait(1.8)
	get_root().get_node("Network").bots = 0   # added below, when the show needs them
	await _tap_button("HOST (LAN)")

	# The match
	while current_scene == null or not current_scene.has_method("add_bot") or current_scene.local_player == null:
		await process_frame
	_game = current_scene
	_me = _game.local_player
	_touch = _game.hud.touch
	for i in TEAMMATES:
		_game.add_bot(_me.team)
	_look = Vector2(_open_direction(), 0.0)
	_steer = true
	await _wait(1.0)
	await _show_moves()
	for i in ENEMIES:
		_game.add_bot(1 - _me.team)
	_fighting = true
	await _wait(MATCH_SECONDS)
	_fighting = false
	_stick(Vector2.ZERO)
	_hold_fire(false)
	if _me.aiming:
		await _tap("aim")
	await _wait(0.8)
	await _tap_button("SCORE")
	await _wait(3.5)
	await _tap_button("SCORE")
	await _wait(1.0)
	quit()


## Movement: look around, walk, run, sprint (locked), jump, turn and run
## sideways, crouch, then aim down the sight and peek both ways.
func _show_moves() -> void:
	var front := _look.x
	_look.x = front + 0.6
	await _wait(1.2)
	_look.x = front - 0.5
	await _wait(1.2)
	_look.x = front
	_stick(Vector2(0, -0.4))   # a little push: walk
	await _wait(2.0)
	_stick(Vector2(0, -0.9))   # run
	await _wait(1.6)
	await _sprint_lock()       # push past the ring: sprint, thumb off
	await _wait(1.8)
	await _tap("jump")
	await _wait(1.0)
	_touch.elements["joystick"].stop_sprint_lock()
	_stick(Vector2(-0.9, 0))
	await _wait(1.3)
	_stick(Vector2(0.9, 0))
	await _wait(1.3)
	_stick(Vector2.ZERO)
	await _tap("crouch")
	_stick(Vector2(0, -0.8))
	await _wait(1.6)
	_stick(Vector2.ZERO)
	await _wait(0.5)
	await _tap("crouch")
	await _wait(0.4)
	await _tap("aim")
	_look.x = front + 0.3
	await _wait(1.2)
	await _tap("peek_right")
	await _wait(1.2)
	await _tap("peek_left")
	await _wait(1.2)
	await _tap("peek_left")
	_look.x = front
	await _wait(0.8)
	await _tap("aim")
	await _wait(0.4)


func _sprint_lock() -> void:
	var e = _touch.elements["joystick"]
	_mark(e.center + Vector2(0, -e.diameter * 0.6))
	e.pressed = true
	e.knob = Vector2(0, -1)
	e.sprint_lock = true
	e.queue_redraw()
	await _wait(0.3)
	e.touch_up()


## The way (near the enemy's side) with the most open ground ahead, so the
## moves are not shown against a wall.
func _open_direction() -> float:
	var best := _me.rotation.y
	var best_room := 0.0
	var space := _me.get_world_3d().direct_space_state
	for i in range(-6, 7):
		var yaw := _me.rotation.y + i * 0.12
		var ahead := Vector3(-sin(yaw), 0, -cos(yaw))
		var from := _me.global_position + Vector3(0, 1.0, 0)
		var q := PhysicsRayQueryParameters3D.create(from, from + ahead * 30.0)
		q.exclude = [_me.get_rid()]
		var hit := space.intersect_ray(q)
		var room: float = from.distance_to(hit.position) if hit else 30.0
		room -= absf(i) * 0.4   # rather straight ahead
		if room > best_room:
			best_room = room
			best = yaw
	return best


## Every frame: turn the camera smoothly; in the fight, play like a person.
func _every_frame() -> void:
	var dt := get_root().get_process_delta_time()
	for m in _tap_marks:
		m[1] += dt
	_tap_marks = _tap_marks.filter(func(m): return m[1] < 0.45)
	_taps.queue_redraw()
	if _me == null or not is_instance_valid(_me) or not _steer:
		return
	if _fighting:
		_fight(dt)
	var k := 1.0 - exp(-6.0 * dt)
	if not _me.dead:
		_me.rotation.y = lerp_angle(_me.rotation.y, _look.x, k)
		_me.pitch = lerpf(_me.pitch, _look.y, k)


func _fight(dt: float) -> void:
	if _me.dead:
		_stick(Vector2.ZERO)
		_hold_fire(false)
		_look = Vector2(_me.rotation.y, 0.0)
		return
	var cam: Vector3 = _me.camera.global_position
	var target: Node3D = null
	var nearest: Node3D = null
	for p in _game.players_root.get_children():
		if p.team == _me.team or p.dead:
			continue
		var at: Vector3 = p.global_position + Vector3(0, 0.95 if p.crouching else 1.35, 0)
		if nearest == null or _me.global_position.distance_to(p.global_position) < _me.global_position.distance_to(nearest.global_position):
			nearest = p
		var q := PhysicsRayQueryParameters3D.create(_me.global_position + Vector3(0, 1.5, 0), at)
		q.exclude = [_me.get_rid()]
		var hit := _me.get_world_3d().direct_space_state.intersect_ray(q)
		if hit and hit.collider == p:
			if target == null or cam.distance_to(at) < cam.distance_to(target.global_position):
				target = p
	if target:
		var at: Vector3 = target.global_position + Vector3(0, 0.95 if target.crouching else 1.35, 0)
		var to := at - cam
		_look = Vector2(atan2(-to.x, -to.z), atan2(to.y, Vector2(to.x, to.z).length()))
		var dist := Vector2(to.x, to.z).length()
		# Look through the sight unless the enemy is close, peek once, step sideways
		if dist > 6.0 and not _me.aiming:
			_tap("aim")
		if _me.aiming and not _peeked and _me.ammo < 22:
			_peeked = true
			_tap("peek_right")
			create_timer(1.6).timeout.connect(func(): _tap("peek_right"))
		var on_target := absf(angle_difference(_me.rotation.y, _look.x)) < 0.05
		_hold_fire(on_target and not _me.reloading)
		_stick(Vector2(0.45 * sin(_game.time_left * 1.7), 0))   # step from side to side
	else:
		_hold_fire(false)
		if _me.aiming:
			_tap("aim")
		if _me.ammo < 18 and not _me.reloading:
			_tap("reload")
		if nearest:
			var to: Vector3 = nearest.global_position - _me.global_position
			_look = Vector2(atan2(-to.x, -to.z), 0.0)
			# Walk round walls and crates in the way
			_stuck_left -= dt
			if _me.is_on_wall() and _stuck_left <= 0.0:
				_stuck_left = 1.0
				_stuck_side = [-1.0, 1.0].pick_random()
			_stick(Vector2(_stuck_side * 0.9, -0.3) if _stuck_left > 0.0 else Vector2(0, -0.8))
		else:
			_stick(Vector2.ZERO)


# ---------------------------------------------------------------- touches

func _stick(v: Vector2) -> void:
	var e = _touch.elements["joystick"]
	if e.sprint_lock:
		return
	e.pressed = v != Vector2.ZERO
	if e.knob != v:
		e.knob = v
		e.queue_redraw()


func _hold_fire(on: bool) -> void:
	var e = _touch.elements["fire"]
	if e.pressed != on:
		e.pressed = on
		e.queue_redraw()
		if on:
			_mark(e.global_position + e.size / 2)


## Taps an on-screen game button (jump, crouch, aim, reload, peek...).
func _tap(id: String) -> void:
	var e = _touch.elements[id]
	_mark(e.global_position + e.size / 2)
	e.pressed = true
	e.queue_redraw()
	_touch.action_pressed.emit(id)
	await _wait(0.15)
	e.pressed = false
	e.queue_redraw()


func _tap_button(text: String) -> void:
	for b in get_root().find_children("*", "BaseButton", true, false):
		if b is Button and b.text == text and b.is_visible_in_tree():
			_mark(b.global_position + b.size / 2)
			await _wait(0.2)
			b.pressed.emit()
			return
	push_warning("button not found: " + text)


func _tap_weapon(id: String) -> void:
	var lobby = current_scene
	var card: Button = lobby._weapon_cards[id]
	_mark(card.global_position + card.size / 2)
	await _wait(0.2)
	card.button_pressed = true
	card.pressed.emit()


func _mark(at: Vector2) -> void:
	_tap_marks.append([at, 0.0])


func _draw_taps() -> void:
	for m in _tap_marks:
		var t: float = m[1] / 0.45
		_taps.draw_circle(m[0], 22.0 + 14.0 * t, Color(1, 1, 1, 0.45 * (1.0 - t)))
		_taps.draw_arc(m[0], 22.0 + 14.0 * t, 0, TAU, 32, Color(1, 1, 1, 0.9 * (1.0 - t)), 3.0)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
