extends Control
## Settings window with tabs, like PUBG:
##   SENSITIVITY - finger-drag sensitivity for each scope
##   GYROSCOPE   - gyro on/off and sensitivity for each scope
##   GRAPHICS    - quality and FPS
##   CONTROLS    - auto sprint, button opacity, edit the button layout

signal edit_controls_requested
signal leave_requested
signal closed

const UI := preload("res://scripts/ui/ui_theme.gd")

var in_game := false

var _drag_sliders := {}
var _gyro_sliders := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.make()

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -480
	panel.offset_right = 480
	panel.offset_top = -330
	panel.offset_bottom = 330
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_size_override("font_size", 22)
	box.add_child(tabs)
	_sensitivity_tab(tabs)
	_gyro_tab(tabs)
	_graphics_tab(tabs)
	_controls_tab(tabs)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)
	if in_game:
		var leave := UI.button("LEAVE MATCH", _on_leave)
		leave.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons.add_child(leave)
	var close_btn := UI.button("SAVE & CLOSE", close)
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(close_btn)


# ---------------------------------------------------------------- tabs

func _page(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	scroll.add_child(col)
	return col


func _sensitivity_tab(tabs: TabContainer) -> void:
	var col := _page(tabs, "SENSITIVITY")
	col.add_child(UI.label("Camera sensitivity when dragging your finger (works for every gun).", 18, Color(1, 1, 1, 0.7)))
	for scope in Settings.SCOPES:
		_drag_sliders[scope] = _row(col, Settings.SCOPE_NAMES[scope], 1, 300, Settings.drag_sensitivity[scope], "%d%%",
				func(v): Settings.drag_sensitivity[scope] = int(v))
	col.add_child(UI.button("RESET TO DEFAULT", _reset_sensitivity, 48))


func _gyro_tab(tabs: TabContainer) -> void:
	var col := _page(tabs, "GYROSCOPE")
	col.add_child(UI.label("Aim by moving your phone.", 18, Color(1, 1, 1, 0.7)))
	var mode_row := HBoxContainer.new()
	col.add_child(mode_row)
	var mode_label := UI.label("Gyroscope", 20)
	mode_label.custom_minimum_size.x = 250
	mode_row.add_child(mode_label)
	var mode := OptionButton.new()
	for item in ["Off", "Scope on (only when aiming)", "Always on"]:
		mode.add_item(item)
	mode.selected = Settings.gyro_mode
	mode.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode.custom_minimum_size.y = 48
	mode.item_selected.connect(func(i): Settings.gyro_mode = i)
	mode_row.add_child(mode)
	_check(col, "Invert left/right", Settings.gyro_invert_x, func(v): Settings.gyro_invert_x = v)
	_check(col, "Invert up/down", Settings.gyro_invert_y, func(v): Settings.gyro_invert_y = v)
	for scope in Settings.SCOPES:
		_gyro_sliders[scope] = _row(col, Settings.SCOPE_NAMES[scope], 0, 400, Settings.gyro_sensitivity[scope], "%d%%",
				func(v): Settings.gyro_sensitivity[scope] = int(v))


func _graphics_tab(tabs: TabContainer) -> void:
	var col := _page(tabs, "GRAPHICS")
	col.add_child(UI.label("Graphics", 22, UI.ACCENT))
	_choice_row(col, ["SMOOTH", "BALANCED", "HD"], Settings.quality, func(i): Settings.quality = i)
	col.add_child(UI.label("Frame rate (FPS)", 22, UI.ACCENT))
	var fps_names := []
	for f in Settings.FPS_OPTIONS:
		fps_names.append(str(f))
	_choice_row(col, fps_names, maxi(0, Settings.FPS_OPTIONS.find(Settings.fps_limit)),
			func(i): Settings.fps_limit = Settings.FPS_OPTIONS[i])
	var note := UI.label("90 and 120 FPS need a phone with a 90/120 Hz screen.\nIf the game gets hot or laggy, use BALANCED or SMOOTH.", 16, Color(1, 1, 1, 0.6))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	col.add_child(note)
	_check(col, "Show FPS on screen", Settings.show_fps, func(v): Settings.show_fps = v)


func _controls_tab(tabs: TabContainer) -> void:
	var col := _page(tabs, "CONTROLS")
	_check(col, "Auto sprint (push the joystick all the way up)", Settings.auto_sprint, func(v): Settings.auto_sprint = v)
	_row(col, "Button opacity", 20, 100, Settings.button_opacity * 100, "%d%%",
			func(v): Settings.button_opacity = v / 100.0)
	_row(col, "Mouse sensitivity (PC)", 10, 300, Settings.mouse_sensitivity * 100, "%d%%",
			func(v): Settings.mouse_sensitivity = v / 100.0)
	col.add_child(UI.button("EDIT BUTTON LAYOUT", _on_edit_controls, 56))


# ---------------------------------------------------------------- widgets

func _row(parent: Control, title: String, min_v: float, max_v: float, value: float, fmt: String, setter: Callable) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var name_label := UI.label(title, 20)
	name_label.custom_minimum_size.x = 250
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = 1
	slider.value = value
	slider.custom_minimum_size = Vector2(300, 44)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var value_label := UI.label(fmt % value, 20)
	value_label.custom_minimum_size.x = 80
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	slider.value_changed.connect(func(v):
		setter.call(v)
		value_label.text = fmt % v)
	return slider


func _check(parent: Control, title: String, value: bool, setter: Callable) -> void:
	var c := CheckButton.new()
	c.text = title
	c.button_pressed = value
	c.custom_minimum_size.y = 48
	c.toggled.connect(setter)
	parent.add_child(c)


## Row of buttons where exactly one is selected (like PUBG's graphics picker).
func _choice_row(parent: Control, names: Array, selected: int, setter: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var group := ButtonGroup.new()
	for i in names.size():
		var b := Button.new()
		b.text = names[i]
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = i == selected
		b.custom_minimum_size.y = 56
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(setter.bind(i))
		row.add_child(b)


func _reset_sensitivity() -> void:
	Settings.reset_sensitivity()
	for scope in Settings.SCOPES:
		_drag_sliders[scope].value = Settings.drag_sensitivity[scope]
		_gyro_sliders[scope].value = Settings.gyro_sensitivity[scope]


func close() -> void:
	Settings.save_settings()
	closed.emit()
	queue_free()


func _on_edit_controls() -> void:
	close()
	edit_controls_requested.emit()


func _on_leave() -> void:
	close()
	leave_requested.emit()
