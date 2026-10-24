extends Control
## On-screen controls for phones: joystick on the left, fire/aim/jump/...
## buttons on the right. Every finger is tracked separately, so you can
## move, look around and shoot at the same time.
## Dragging a finger on the empty right side of the screen (or from the
## fire button) turns the camera, like in PUBG Mobile.
##
## In edit_mode the buttons can be dragged to new places and resized.

signal action_pressed(id: String)
signal selection_changed(element: Control)

## Default places. "pos" is a fraction of the screen (0..1), "size" in pixels.
const DEFAULTS := {
	"joystick": {"pos": Vector2(0.14, 0.7), "size": 230.0, "label": "MOVE"},
	"fire": {"pos": Vector2(0.83, 0.6), "size": 130.0, "label": "FIRE"},
	"fire_left": {"pos": Vector2(0.08, 0.34), "size": 95.0, "label": "FIRE"},
	"aim": {"pos": Vector2(0.94, 0.4), "size": 88.0, "label": "AIM"},
	"jump": {"pos": Vector2(0.94, 0.78), "size": 88.0, "label": "JUMP"},
	"crouch": {"pos": Vector2(0.82, 0.88), "size": 88.0, "label": "CROUCH"},
	"reload": {"pos": Vector2(0.7, 0.88), "size": 76.0, "label": "RELOAD"},
}
const HOLD_IDS := ["fire", "fire_left"]

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
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id in DEFAULTS:
		var e := TouchElement.new()
		e.id = id
		e.label = DEFAULTS[id]["label"]
		e.is_joystick = id == "joystick"
		e.is_fire = id in HOLD_IDS
		add_child(e)
		elements[id] = e
	get_viewport().size_changed.connect(apply_layout)
	Settings.changed.connect(apply_layout)
	apply_layout.call_deferred()


func apply_layout() -> void:
	var vs := get_viewport_rect().size
	for id in elements:
		var saved: Dictionary = Settings.layout.get(id, {})
		var e: TouchElement = elements[id]
		e.scale_factor = saved.get("scale", 1.0)
		e.set_layout(saved.get("pos", DEFAULTS[id]["pos"]) * vs, DEFAULTS[id]["size"] * e.scale_factor)
	modulate.a = Settings.button_opacity


func save_layout() -> void:
	var vs := get_viewport_rect().size
	var layout := {}
	for id in elements:
		var e: TouchElement = elements[id]
		layout[id] = {"pos": e.center / vs, "scale": e.scale_factor}
	Settings.layout = layout


func reset_layout() -> void:
	var vs := get_viewport_rect().size
	for id in elements:
		var e: TouchElement = elements[id]
		e.scale_factor = 1.0
		e.set_layout(DEFAULTS[id]["pos"] * vs, DEFAULTS[id]["size"])


func set_selected_scale(value: float) -> void:
	if selected:
		selected.scale_factor = value
		selected.set_layout(selected.center, DEFAULTS[selected.id]["size"] * value)


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


## Edit mode works with the mouse (on phones the first finger acts as mouse).
func _edit_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			_dragging = false
			return
		if blocker and blocker.get_global_rect().has_point(event.position):
			return
		var el := _element_at(event.position)
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
		get_viewport().set_input_as_handled()


func _element_at(pos: Vector2) -> TouchElement:
	var best: TouchElement = null
	var best_dist := INF
	for id in elements:
		var e: TouchElement = elements[id]
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


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_release_all()


## One round button (or the joystick). Draws itself.
class TouchElement extends Control:
	var id := ""
	var label := ""
	var is_joystick := false
	var is_fire := false
	var pressed := false
	var highlighted := false
	var knob := Vector2.ZERO  # joystick direction, length 0..1
	var center := Vector2.ZERO
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
		return p.distance_to(center) <= diameter * (0.65 if is_joystick else 0.55)

	func touch_down(p: Vector2) -> void:
		pressed = true
		touch_move(p)
		queue_redraw()

	func touch_move(p: Vector2) -> void:
		if is_joystick:
			knob = ((p - center) / (diameter * 0.3)).limit_length(1.0)
			queue_redraw()

	func touch_up() -> void:
		pressed = false
		knob = Vector2.ZERO
		queue_redraw()

	func _draw() -> void:
		var r := diameter / 2
		var c := size / 2
		var fill := Color(1, 1, 1, 0.3 if pressed else 0.14)
		if is_fire:
			fill = Color(0.9, 0.25, 0.2, 0.55 if pressed else 0.32)
		draw_circle(c, r, fill)
		draw_arc(c, r - 1.5, 0, TAU, 48, Color(1, 1, 1, 0.75), 3.0, true)
		if highlighted:
			draw_arc(c, r + 5, 0, TAU, 48, Color("f2b632"), 4.0, true)
		if is_joystick:
			draw_circle(c + knob * r * 0.55, r * 0.33, Color(1, 1, 1, 0.6))
			return
		var font := ThemeDB.fallback_font
		var fs := int(clampf(r * 0.3, 11, 28))
		var ts := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(font, c + Vector2(-ts.x / 2, fs * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
