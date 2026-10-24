extends Control
## Toolbar shown while customizing the on-screen buttons:
## drag a button to move it, then use the slider to resize it.

signal closed

const UI := preload("res://scripts/ui/ui_theme.gd")

var controls: Control  # touch_controls.gd

var _size_slider: HSlider
var _opacity_slider: HSlider
var _hint: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UI.make()
	controls.visible = true
	controls.edit_mode = true

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -330
	panel.offset_right = 330
	panel.offset_top = 8
	add_child(panel)
	controls.blocker = panel

	var box := VBoxContainer.new()
	panel.add_child(box)
	_hint = UI.label("Drag a button to move it. Tap a button, then change its size.", 18)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_hint)

	var sliders := HBoxContainer.new()
	sliders.add_theme_constant_override("separation", 10)
	box.add_child(sliders)
	sliders.add_child(UI.label("Size", 18))
	_size_slider = _slider(0.5, 2.0, 1.0, controls.set_selected_scale)
	sliders.add_child(_size_slider)
	sliders.add_child(UI.label("Opacity", 18))
	_opacity_slider = _slider(0.2, 1.0, Settings.button_opacity, func(v): controls.modulate.a = v)
	sliders.add_child(_opacity_slider)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)
	for b in [UI.button("RESET", _reset, 48), UI.button("CANCEL", _cancel, 48), UI.button("SAVE", _save, 48)]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons.add_child(b)

	controls.selection_changed.connect(_on_selected)


func _slider(min_v: float, max_v: float, value: float, callback: Callable) -> HSlider:
	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(180, 40)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(callback)
	return s


func _on_selected(element: Control) -> void:
	_size_slider.set_value_no_signal(element.scale_factor)
	_hint.text = "Selected: %s" % element.label


func _reset() -> void:
	controls.reset_layout()
	_opacity_slider.value = 0.75
	_size_slider.set_value_no_signal(1.0)


func _cancel() -> void:
	controls.apply_layout()
	_close()


func _save() -> void:
	controls.save_layout()
	Settings.button_opacity = _opacity_slider.value
	Settings.save_settings()
	_close()


func _close() -> void:
	controls.deselect()
	controls.edit_mode = false
	controls.blocker = null
	closed.emit()
	queue_free()
