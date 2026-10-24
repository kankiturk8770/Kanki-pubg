extends CanvasLayer
## Everything drawn on top of the 3D view: score, timer, health, ammo,
## crosshair, kill feed, scoreboard and the touch controls.

const UI := preload("res://scripts/ui/ui_theme.gd")
const TouchControls := preload("res://scripts/hud/touch_controls.gd")
const LayoutEditor := preload("res://scripts/hud/layout_editor.gd")
const SettingsPanel := preload("res://scripts/ui/settings_panel.gd")

var game: Node3D
var player: CharacterBody3D = null
var touch: Control
var menu_open := false

var _root: Control
var _crosshair: Control
var _score_labels: Array[Label] = []
var _timer_label: Label
var _health_bar: ProgressBar
var _ammo_label: Label
var _fps_label: Label
var _kill_feed: VBoxContainer
var _center_label: Label
var _sub_label: Label
var _damage_flash: ColorRect
var _scoreboard: PanelContainer
var _scoreboard_grid: GridContainer
var _scoreboard_pinned := false

var _hit_time := 0.0
var _hit_head := false
var _respawn_left := -1.0
var _next_match_left := -1.0
var _notice_left := 0.0


func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UI.make()
	add_child(_root)

	_damage_flash = ColorRect.new()
	_damage_flash.color = Color(0.8, 0, 0, 0)
	_damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_damage_flash)

	_crosshair = Control.new()
	_crosshair.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair.draw.connect(_draw_crosshair)
	_root.add_child(_crosshair)

	touch = TouchControls.new()
	touch.visible = Settings.use_touch_controls()
	touch.action_pressed.connect(_on_touch_action)
	_root.add_child(touch)

	_build_top_bar()
	_build_bottom()
	_build_messages()
	_build_scoreboard()


# ---------------------------------------------------------------- layout

func _anchor(c: Control, ax: float, ay: float, rect: Rect2) -> void:
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = rect.position.x
	c.offset_top = rect.position.y
	c.offset_right = rect.end.x
	c.offset_bottom = rect.end.y


func _build_top_bar() -> void:
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 6)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor(bar, 0.5, 0, Rect2(-210, 8, 420, 52))
	_root.add_child(bar)
	for team in 2:
		var lbl := _score_box(UI.TEAM_COLORS[team])
		_score_labels.append(lbl)
		if team == 0:
			bar.add_child(lbl.get_parent())
			_timer_label = UI.label("10:00", 30)
			_timer_label.custom_minimum_size.x = 110
			_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bar.add_child(_timer_label)
		else:
			bar.add_child(lbl.get_parent())
	var goal := UI.label("First to %d kills" % game.KILL_TARGET, 16, Color(0.85, 0.85, 0.85))
	goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor(goal, 0.5, 0, Rect2(-150, 60, 300, 24))
	_root.add_child(goal)

	var left := HBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	_anchor(left, 0, 0, Rect2(12, 10, 250, 50))
	_root.add_child(left)
	left.add_child(UI.button("MENU", _open_settings, 48))
	left.add_child(UI.button("SCORE", func(): _scoreboard_pinned = not _scoreboard_pinned, 48))

	_fps_label = UI.label("", 18, Color(0.6, 1.0, 0.6))
	_anchor(_fps_label, 0, 0, Rect2(16, 66, 140, 24))
	_root.add_child(_fps_label)

	_kill_feed = VBoxContainer.new()
	_kill_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kill_feed.alignment = BoxContainer.ALIGNMENT_BEGIN
	_anchor(_kill_feed, 1, 0, Rect2(-430, 10, 420, 200))
	_root.add_child(_kill_feed)


func _score_box(color: Color) -> Label:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 14
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(110, 48)
	var lbl := UI.label("0", 32)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(lbl)
	return lbl


func _build_bottom() -> void:
	_ammo_label = UI.label("30 / 30", 28)
	_ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor(_ammo_label, 0.5, 1, Rect2(-150, -88, 300, 36))
	_root.add_child(_ammo_label)

	_health_bar = ProgressBar.new()
	_health_bar.max_value = 100
	_health_bar.value = 100
	_health_bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.92, 0.92, 0.92)
	fill.set_corner_radius_all(4)
	_health_bar.add_theme_stylebox_override("background", bg)
	_health_bar.add_theme_stylebox_override("fill", fill)
	_anchor(_health_bar, 0.5, 1, Rect2(-180, -46, 360, 20))
	_root.add_child(_health_bar)


func _build_messages() -> void:
	_center_label = UI.label("", 44, UI.ACCENT)
	_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor(_center_label, 0.5, 0.3, Rect2(-400, -30, 800, 60))
	_root.add_child(_center_label)
	_sub_label = UI.label("", 24)
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor(_sub_label, 0.5, 0.3, Rect2(-400, 32, 800, 40))
	_root.add_child(_sub_label)


func _build_scoreboard() -> void:
	_scoreboard = PanelContainer.new()
	_scoreboard.visible = false
	_scoreboard.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor(_scoreboard, 0.5, 0.5, Rect2(-330, -210, 660, 420))
	_root.add_child(_scoreboard)
	_scoreboard_grid = GridContainer.new()
	_scoreboard_grid.columns = 3
	_scoreboard_grid.add_theme_constant_override("h_separation", 30)
	_scoreboard.add_child(_scoreboard_grid)


# ---------------------------------------------------------------- called by player / game

func set_player(p: CharacterBody3D) -> void:
	player = p
	_center_label.text = ""
	_sub_label.text = ""


func take_look_delta() -> Vector2:
	var d: Vector2 = touch.take_look_delta() if touch.visible else Vector2.ZERO
	return Vector2.ZERO if menu_open else d


func get_move() -> Vector2:
	return touch.get_move() if touch.visible and not menu_open else Vector2.ZERO


func is_firing() -> bool:
	return touch.visible and not menu_open and touch.is_firing()


func show_message(text: String) -> void:
	_center_label.text = text


func show_hitmarker(head_hit: bool) -> void:
	_hit_time = 0.3
	_hit_head = head_hit


func on_damaged(_attacker_id: int) -> void:
	_damage_flash.color.a = 0.3


func on_local_death(respawn_delay: float) -> void:
	_respawn_left = respawn_delay


func update_match() -> void:
	for team in 2:
		_score_labels[team].text = str(game.score[team])
	if game.is_playing() and _next_match_left >= 0:
		_next_match_left = -1
		_center_label.text = ""
		_sub_label.text = ""


func show_match_end(winner: int, delay: float) -> void:
	_next_match_left = delay
	if winner < 0:
		_center_label.text = "DRAW"
		_center_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		var won: bool = player != null and player.team == winner
		_center_label.text = ("VICTORY - " if won else "DEFEAT - ") + "%s TEAM WINS" % UI.TEAM_NAMES[winner]
		_center_label.add_theme_color_override("font_color", UI.TEAM_COLORS[winner].lightened(0.2))


func add_kill(killer: String, killer_team: int, victim: String, victim_team: int, head_hit: bool, by_me: bool) -> void:
	var line := RichTextLabel.new()
	line.bbcode_enabled = true
	line.fit_content = true
	line.scroll_active = false
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_font_size_override("normal_font_size", 20)
	line.add_theme_constant_override("outline_size", 4)
	line.add_theme_color_override("font_outline_color", Color.BLACK)
	line.text = "[right][color=#%s]%s[/color]  %s  [color=#%s]%s[/color][/right]" % [
		UI.TEAM_COLORS[killer_team].lightened(0.2).to_html(false), _escape(killer),
		"[color=#ff5555]HEADSHOT[/color]" if head_hit else "killed",
		UI.TEAM_COLORS[victim_team].lightened(0.2).to_html(false), _escape(victim)]
	_kill_feed.add_child(line)
	while _kill_feed.get_child_count() > 5:
		_kill_feed.get_child(0).free()
	get_tree().create_timer(6.0).timeout.connect(line.queue_free)
	if by_me and killer != victim:
		_sub_label.text = "You killed %s" % victim
		_notice_left = 2.0


func update_scoreboard() -> void:
	for c in _scoreboard_grid.get_children():
		c.free()
	for header in ["PLAYER", "KILLS", "DEATHS"]:
		_scoreboard_grid.add_child(UI.label(header, 18, UI.ACCENT))
	var ids: Array = game.info.keys()
	ids.sort_custom(func(a, b):
		var ia: Dictionary = game.info[a]
		var ib: Dictionary = game.info[b]
		if ia["team"] != ib["team"]:
			return ia["team"] < ib["team"]
		return ia["kills"] > ib["kills"])
	for id in ids:
		var i: Dictionary = game.info[id]
		var color: Color = UI.TEAM_COLORS[i["team"]].lightened(0.25)
		var shown_name: String = i["name"] + ("  (you)" if id == multiplayer.get_unique_id() else "")
		_scoreboard_grid.add_child(UI.label(shown_name, 22, color))
		_scoreboard_grid.add_child(UI.label(str(i["kills"]), 22))
		_scoreboard_grid.add_child(UI.label(str(i["deaths"]), 22))


func _escape(text: String) -> String:
	return text.replace("[", "(").replace("]", ")")


# ---------------------------------------------------------------- per frame

func _process(delta: float) -> void:
	var t := int(ceil(game.time_left))
	_timer_label.text = "%d:%02d" % [t / 60, t % 60]

	_fps_label.visible = Settings.show_fps
	if Settings.show_fps:
		_fps_label.text = "%d FPS" % Engine.get_frames_per_second()

	if player:
		touch.set_active("joystick", player.sprinting)
		touch.set_active("peek_left", player.peek == -1)
		touch.set_active("peek_right", player.peek == 1)
		touch.set_active("aim", player.aiming)
		_health_bar.value = player.health
		var fill: StyleBoxFlat = _health_bar.get_theme_stylebox("fill")
		fill.bg_color = Color(0.92, 0.92, 0.92) if player.health > 30 else Color(0.9, 0.2, 0.15)
		_ammo_label.text = "RELOADING..." if player.reloading else "%d / %d" % [player.ammo, player.MAG_SIZE]

	_damage_flash.color.a = move_toward(_damage_flash.color.a, 0.0, delta * 1.2)
	_hit_time = maxf(0.0, _hit_time - delta)
	_crosshair.visible = player != null and not player.dead
	_crosshair.queue_redraw()

	if _notice_left > 0:
		_notice_left -= delta
		if _notice_left <= 0 and _respawn_left < 0 and _next_match_left < 0:
			_sub_label.text = ""

	if _next_match_left >= 0:
		_next_match_left = maxf(0.0, _next_match_left - delta)
		_sub_label.text = "Next match in %d" % ceil(_next_match_left)
	elif _respawn_left >= 0:
		_respawn_left -= delta
		if player and player.dead:
			_center_label.add_theme_color_override("font_color", Color("ff6b5e"))
			_center_label.text = "ELIMINATED"
			_sub_label.text = "Respawning in %d" % ceil(maxf(_respawn_left, 0.0))
		else:
			_respawn_left = -1
			_center_label.text = ""
			_sub_label.text = ""
			_center_label.add_theme_color_override("font_color", UI.ACCENT)

	_scoreboard.visible = _scoreboard_pinned or Input.is_action_pressed("scoreboard") \
			or not game.is_playing()


func _draw_crosshair() -> void:
	var c := _crosshair.size / 2
	var gap: float = 4.0 + (player.current_spread() * 7.0 if player else 10.0)
	var col := Color(1, 1, 1, 0.9)
	for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		_crosshair.draw_line(c + d * gap, c + d * (gap + 10), col, 2.0)
	_crosshair.draw_circle(c, 1.8, col)
	if _hit_time > 0:
		var hc := Color(1, 0.25, 0.2) if _hit_head else Color.WHITE
		hc.a = _hit_time / 0.3
		for d in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
			_crosshair.draw_line(c + d * 7, c + d * 15, hc, 3.0)


# ---------------------------------------------------------------- menus

func _on_touch_action(id: String) -> void:
	if player and not menu_open:
		player.on_action(id)


func _open_settings() -> void:
	if menu_open:
		return
	menu_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var panel := SettingsPanel.new()
	panel.in_game = true
	panel.closed.connect(func(): menu_open = false)
	panel.edit_controls_requested.connect(_open_layout_editor)
	panel.leave_requested.connect(game.leave_match)
	_root.add_child(panel)


func _open_layout_editor() -> void:
	menu_open = true
	var editor := LayoutEditor.new()
	editor.controls = touch
	editor.closed.connect(func():
		menu_open = false
		touch.visible = Settings.use_touch_controls())
	_root.add_child(editor)
