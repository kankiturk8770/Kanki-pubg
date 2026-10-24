extends Control
## Settings window: sensitivity sliders, button opacity, and (in a match)
## buttons to edit the control layout or leave.

signal edit_controls_requested
signal leave_requested
signal closed

const UI := preload("res://scripts/ui/ui_theme.gd")

var in_game := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UI.make()

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 620
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	box.add_child(UI.label("SETTINGS", 34, UI.ACCENT))
	_row(box, "Camera sensitivity", 0.1, 3.0, Settings.look_sensitivity, func(v): Settings.look_sensitivity = v)
	_row(box, "Scope (aim) sensitivity", 0.1, 2.0, Settings.ads_sensitivity, func(v): Settings.ads_sensitivity = v)
	_row(box, "Mouse sensitivity (PC)", 0.1, 3.0, Settings.mouse_sensitivity, func(v): Settings.mouse_sensitivity = v)
	_row(box, "Button opacity", 0.2, 1.0, Settings.button_opacity, func(v): Settings.button_opacity = v)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)
	var list := [UI.button("EDIT CONTROLS", _on_edit_controls)]
	if in_game:
		list.append(UI.button("LEAVE MATCH", _on_leave))
	list.append(UI.button("CLOSE", close))
	for b in list:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons.add_child(b)


func _row(parent: Control, title: String, min_v: float, max_v: float, value: float, setter: Callable) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var name_label := UI.label(title, 20)
	name_label.custom_minimum_size.x = 260
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(220, 44)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var value_label := UI.label("%.2f" % value, 20)
	value_label.custom_minimum_size.x = 60
	row.add_child(value_label)
	slider.value_changed.connect(func(v):
		setter.call(v)
		value_label.text = "%.2f" % v)


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
