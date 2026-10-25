extends Control
## On-screen controls for phones, laid out and drawn like PUBG Mobile: dark
## see-through round buttons with white icons, a big fire button top
## right, scope / jump / crouch / reload on the right, peek and a second
## fire button on the left. The joystick floats: it appears where the left
## thumb lands. Push it up past its ring to lock sprinting (tap it again
## to stop). Every finger is tracked separately, so you can move, look
## around and shoot at the same time. Dragging a finger on the empty right
## side of the screen (or from any button) turns the camera.
##
## In edit_mode the buttons can be dragged to new places and resized.

signal action_pressed(id: String)
signal selection_changed(element: Control)

## Saved layouts made for older button sets are dropped.
const LAYOUT_VERSION := 2
## Default places. "pos" is a fraction of the screen (0..1), "size" in pixels.
const DEFAULTS := {
	"joystick": {"pos": Vector2(0.15, 0.72), "size": 220.0, "label": "MOVE"},
	"fire": {"pos": Vector2(0.84, 0.3), "size": 150.0, "label": "FIRE"},
	"fire_left": {"pos": Vector2(0.24, 0.42), "size": 92.0, "label": "FIRE"},
	"aim": {"pos": Vector2(0.955, 0.5), "size": 88.0, "label": "AIM"},
	"jump": {"pos": Vector2(0.93, 0.72), "size": 88.0, "label": "JUMP"},
	"crouch": {"pos": Vector2(0.82, 0.9), "size": 86.0, "label": "CROUCH"},
	"reload": {"pos": Vector2(0.71, 0.9), "size": 78.0, "label": "RELOAD"},
	"peek_left": {"pos": Vector2(0.05, 0.45), "size": 72.0, "label": "PEEK L"},
	"peek_right": {"pos": Vector2(0.13, 0.45), "size": 72.0, "label": "PEEK R"},
}
const HOLD_IDS := ["fire", "fire_left"]
const ICONS := {
	"fire": preload("res://assets/ui/icons/fire.svg"),
	"fire_left": preload("res://assets/ui/icons/fire.svg"),
	"aim": preload("res://assets/ui/icons/aim.svg"),
	"jump": preload("res://assets/ui/icons/jump.svg"),
	"crouch": preload("res://assets/ui/icons/crouch.svg"),
	"reload": preload("res://assets/ui/icons/reload.svg"),
	"peek_left": preload("res://assets/ui/icons/peek_left.svg"),
	"peek_right": preload("res://assets/ui/icons/peek_right.svg"),
}
## The joystick can be started anywhere in this part of the screen (left
## side, below the top bar).
const JOYSTICK_ZONE := Rect2(0.0, 0.5, 0.42, 0.5)

var edit_mode := false:
	set(value):
		edit_mode = value
		_release_all()
var elements := {}
var selected: Control = null
## Area (e.g. the editor toolbar) where edit-mode clicks are ignored.
var blocker: Control = null

var _look_delta := Vector2.ZERO
var _touches := {}  # finger index -> {"el": element or null, "last": Vector2}
var _dragging := false
var _drag_offset := Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id in DEFAULTS:
		var e := TouchElement.new()
		e.id = id
		e.label = DEFAULTS[id]["label"]
		e.icon = ICONS.get(id)
		e.is_joystick = id == "joystick"
		e.is_fire = id in HOLD_IDS
		add_child(e)
		elements[id] = e
	get_viewport().size_changed.connect(apply_layout)
	Settings.changed.connect(apply_layout)
	apply_layout.call_deferred()


func apply_layout() -> void:
	var vs := get_viewport_rect().size
	var saved_layout: Dictionary = Settings.layout if Settings.layout.get("version", 1) == LAYOUT_VERSION else {}
	for id in elements:
		var saved: Dictionary = saved_layout.get(id, {})
		var e: TouchElement = elements[id]
		e.scale_factor = saved.get("scale", 1.0)
		e.set_layout(saved.get("pos", DEFAULTS[id]["pos"]) * vs, DEFAULTS[id]["size"] * e.scale_factor)
		e.home = e.center
	modulate.a = Settings.button_opacity


func save_layout() -> void:
	var vs := get_viewport_rect().size
	var layout := {"version": LAYOUT_VERSION}
	for id in elements:
		var e: TouchElement = elements[id]
		layout[id] = {"pos": e.home / vs if e.is_joystick else e.center / vs, "scale": e.scale_factor}
	Settings.layout = layout


func reset_layout() -> void:
	var vs := get_viewport_rect().size
	for id in elements:
		var e: TouchElement = elements[id]
		e.scale_factor = 1.0
		e.set_layout(DEFAULTS[id]["pos"] * vs, DEFAULTS[id]["size"])
		e.home = e.center


func set_selected_scale(value: float) -> void:
	if selected:
		selected.scale_factor = value
		selected.set_layout(selected.center, DEFAULTS[selected.id]["size"] * value)
		selected.home = selected.center


func deselect() -> void:
	if selected:
		selected.highlighted = false
		selected.queue_redraw()
	selected = null


# ---------------------------------------------------------------- reading input

func take_look_delta() -> Vector2:
	var d := _look_delta
	_look_delta = Vector2.ZERO
	return d


func get_move() -> Vector2:
	return elements["joystick"].knob


func is_firing() -> bool:
	for id in HOLD_IDS:
		if elements[id].pressed:
			return true
	return false


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if edit_mode:
		_edit_input(event)
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			var el := _element_at(event.position)
			if el == null and _in_joystick_zone(event.position) and not _joystick_busy():
				el = elements["joystick"]
				el.float_to(event.position, get_viewport_rect().size)
			if el:
				_touches[event.index] = {"el": el, "last": event.position}
				el.touch_down(event.position)
				if not el.is_joystick and not el.is_fire:
					action_pressed.emit(el.id)
				get_viewport().set_input_as_handled()
			elif event.position.x > get_viewport_rect().size.x * 0.35 and event.position.y > 90:
				_touches[event.index] = {"el": null, "last": event.position}
		elif _touches.has(event.index):
			var t: Dictionary = _touches[event.index]
			if t["el"]:
				t["el"].touch_up()
			_touches.erase(event.index)
	elif event is InputEventScreenDrag and _touches.has(event.index):
		var t: Dictionary = _touches[event.index]
		if t["el"] and t["el"].is_joystick:
			t["el"].touch_move(event.position)
		else:
			_look_delta += event.position - t["last"]
		t["last"] = event.position


func _in_joystick_zone(p: Vector2) -> bool:
	var vs := get_viewport_rect().size
	return Rect2(JOYSTICK_ZONE.position * vs, JOYSTICK_ZONE.size * vs).has_point(p)


func _joystick_busy() -> bool:
	for t in _touches.values():
		if t["el"] == elements["joystick"]:
			return true
	return false


## Edit mode works with the mouse (on phones the first finger acts as mouse).
func _edit_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			_dragging = false
			return
		if blocker and blocker.get_global_rect().has_point(event.position):
			return
		var el := _element_at(event.position, true)
		if el:
			deselect()
			selected = el
			el.highlighted = true
			el.queue_redraw()
			selection_changed.emit(el)
			_dragging = true
			_drag_offset = el.center - event.position
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging and selected:
		var c: Vector2 = (event.position + _drag_offset).clamp(Vector2.ZERO, get_viewport_rect().size)
		selected.set_layout(c, selected.diameter)
		selected.home = c
		get_viewport().set_input_as_handled()


## Button under `pos` (the joystick only when editing: in play it floats).
func _element_at(pos: Vector2, with_joystick := false) -> TouchElement:
	var best: TouchElement = null
	var best_dist := INF
	for id in elements:
		var e: TouchElement = elements[id]
		if e.is_joystick and not with_joystick:
			continue
		var d := pos.distance_to(e.center)
		if e.contains(pos) and d < best_dist:
			best = e
			best_dist = d
	return best


func _release_all() -> void:
	for t in _touches.values():
		if t["el"]:
			t["el"].touch_up()
	_touches.clear()
	_look_delta = Vector2.ZERO
	if elements.has("joystick"):
		elements["joystick"].stop_sprint_lock()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_release_all()


## One round button (or the joystick). Draws itself.
class TouchElement extends Control:
	const GOLD := Color(0.98, 0.76, 0.2)
	const SPRINT_ICON := preload("res://assets/ui/icons/sprint.svg")
	var id := ""
	var label := ""
	var icon: Texture2D
	var is_joystick := false
	var is_fire := false
	var pressed := false
	var highlighted := false
	var active := false  # toggled state (aim, peek on) or sprinting on the joystick
	var knob := Vector2.ZERO  # joystick direction, length 0..1
	var sprint_lock := false  # joystick pushed past its ring: keeps running
	var center := Vector2.ZERO
	var home := Vector2.ZERO  # where the joystick rests when nobody touches it
	var diameter := 100.0
	var scale_factor := 1.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_layout(c: Vector2, d: float) -> void:
		center = c
		diameter = d
		size = Vector2(d, d)
		position = c - size / 2
		queue_redraw()

	func contains(p: Vector2) -> bool:
		return p.distance_to(center) <= diameter * (0.65 if is_joystick else 0.58)

	## The joystick comes to the thumb (kept fully on screen).
	func float_to(p: Vector2, screen: Vector2) -> void:
		var r := diameter / 2
		set_layout(p.clamp(Vector2(r, r), screen - Vector2(r, r)), diameter)

	func touch_down(p: Vector2) -> void:
		pressed = true
		if is_joystick:
			stop_sprint_lock()
		touch_move(p)
		queue_redraw()

	func touch_move(p: Vector2) -> void:
		if is_joystick:
			var raw := (p - center) / (diameter * 0.3)
			knob = raw.limit_length(1.0)
			# past the ring, straight up: lock sprint
			if raw.y < -1.7 and absf(raw.x) < 0.9:
				sprint_lock = true
			elif raw.length() < 1.2:
				sprint_lock = false
			queue_redraw()

	func touch_up() -> void:
		pressed = false
		if is_joystick:
			if sprint_lock:
				knob = Vector2(0, -1)   # keeps running forward
			else:
				knob = Vector2.ZERO
				set_layout(home, diameter)
		queue_redraw()

	func stop_sprint_lock() -> void:
		if sprint_lock:
			sprint_lock = false
			if not pressed:
				knob = Vector2.ZERO
				set_layout(home, diameter)
			queue_redraw()

	func _draw() -> void:
		var r := diameter / 2
		var c := size / 2
		if is_joystick:
			_draw_joystick(c, r)
			return
		var fill := Color(0, 0, 0, 0.42 if pressed else 0.3)
		if pressed:
			fill = Color(1, 1, 1, 0.22)
		draw_circle(c, r, fill)
		draw_arc(c, r - 1.0, 0, TAU, 48, Color(1, 1, 1, 0.35), 2.0, true)
		if active:
			draw_arc(c, r - 3.0, 0, TAU, 48, GOLD, 4.0, true)
		if highlighted:
			draw_arc(c, r + 5, 0, TAU, 48, GOLD, 4.0, true)
		if icon:
			var s := Vector2.ONE * diameter * (0.62 if is_fire else 0.56)
			var tint := GOLD if active else Color(1, 1, 1, 0.92)
			draw_texture_rect(icon, Rect2(c - s / 2, s), false, tint)

	func _draw_joystick(c: Vector2, r: float) -> void:
		var idle := not pressed and not sprint_lock
		draw_circle(c, r, Color(0, 0, 0, 0.12 if idle else 0.22))
		draw_arc(c, r - 1.5, 0, TAU, 64, Color(1, 1, 1, 0.3 if idle else 0.55), 2.5, true)
		draw_circle(c + knob * r * 0.55, r * 0.3, Color(1, 1, 1, 0.35 if idle else 0.6))
		# sprint: running man above the ring, gold while running
		var at := c + Vector2(0, -r - 34)
		var running := active or sprint_lock
		draw_circle(at, 26, Color(0, 0, 0, 0.35) if running else Color(0, 0, 0, 0.0))
		if running or pressed:
			var s := Vector2(40, 40)
			draw_texture_rect(SPRINT_ICON, Rect2(at - s / 2, s), false,
					GOLD if running else Color(1, 1, 1, 0.45))


## Shows on/off states (aim, peek buttons, running man on the joystick).
func set_active(id: String, value: bool) -> void:
	var e: TouchElement = elements.get(id)
	if e and e.active != value:
		e.active = value
		e.queue_redraw()
