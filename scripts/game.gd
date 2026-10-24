extends Node3D
## The match. Same scene runs on the server and on every player.
## The server owns the rules: teams, score, timer, win and restart.

const MapBuilder := preload("res://scripts/map_builder.gd")
const PlayerScript := preload("res://scripts/player.gd")
const HudScript := preload("res://scripts/hud/hud.gd")
const MENU_SCENE := "res://scenes/main_menu.tscn"

const KILL_TARGET := 40
const MATCH_TIME := 600.0
const RESPAWN_DELAY := 3.0
const NEXT_MATCH_DELAY := 10.0

enum State { PLAYING, ENDED }

var players_root: Node3D
var spawner: MultiplayerSpawner
var hud: CanvasLayer = null
var local_player: CharacterBody3D = null

# Sent by the server to everyone
var state := State.PLAYING
var score := [0, 0]
var time_left := MATCH_TIME
var info := {}  # peer id -> {"name", "team", "kills", "deaths"}

var _sync_timer := 0.0
var _leaving := false


func _ready() -> void:
	MapBuilder.build(self)
	Settings.apply_graphics()

	players_root = Node3D.new()
	players_root.name = "Players"
	add_child(players_root)
	spawner = MultiplayerSpawner.new()
	spawner.name = "PlayerSpawner"
	spawner.spawn_path = NodePath("../Players")
	spawner.spawn_function = _spawn_player
	add_child(spawner)

	if not Network.is_dedicated():
		hud = HudScript.new()
		hud.game = self
		add_child(hud)

	var err := Network.start()
	if err != OK:
		var what := "connect to the server" if Network.mode == Network.Mode.CLIENT else "start the server"
		_back_to_menu("Could not %s (error %d)." % [what, err])
		return

	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		print("[server] Kanki TDM listening on UDP port %d" % Network.port)
		if Network.mode == Network.Mode.HOST:
			_add_player(1, Network.player_name)
	else:
		multiplayer.connected_to_server.connect(_on_connected)
		multiplayer.connection_failed.connect(_back_to_menu.bind(
				"Could not connect to %s:%d" % [Network.address, Network.port]))
		multiplayer.server_disconnected.connect(_back_to_menu.bind("Lost connection to the server."))
		hud.show_message("Connecting to %s ..." % Network.address)


func _process(delta: float) -> void:
	if _leaving or multiplayer.multiplayer_peer == null:
		return
	if state == State.PLAYING:
		time_left = maxf(0.0, time_left - delta)
	if not multiplayer.is_server():
		return
	if state == State.PLAYING and time_left <= 0.0:
		_end_match()
	_sync_timer -= delta
	if _sync_timer <= 0.0:
		_sync_timer = 1.0
		_broadcast_match()


func is_playing() -> bool:
	return state == State.PLAYING


func get_spawn_point(team: int) -> Vector3:
	return MapBuilder.spawn_point(team)


func leave_match() -> void:
	_back_to_menu("")


func _back_to_menu(message: String) -> void:
	if _leaving:
		return
	_leaving = true
	Network.stop()
	if Network.is_dedicated() or DisplayServer.get_name() == "headless":
		printerr(message)
		get_tree().quit(1)
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Network.last_error = message
	get_tree().change_scene_to_file.call_deferred(MENU_SCENE)


# ---------------------------------------------------------------- joining

func _on_connected() -> void:
	register_player.rpc_id(1, Network.player_name)


@rpc("any_peer", "reliable")
func register_player(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if not info.has(id):
		_add_player(id, player_name)


func _add_player(id: int, player_name: String) -> void:
	player_name = player_name.strip_edges().left(16)
	if player_name == "":
		player_name = "Player%d" % (info.size() + 1)
	var team := 0 if _team_size(0) <= _team_size(1) else 1
	info[id] = {"name": player_name, "team": team, "kills": 0, "deaths": 0}
	spawner.spawn({"id": id, "name": player_name, "team": team, "pos": get_spawn_point(team)})
	print("[server] %s joined team %s (%d players)" % [player_name, ["BLUE", "RED"][team], info.size()])
	_broadcast_info()
	_broadcast_match()


func _spawn_player(data: Dictionary) -> Node:
	var p := PlayerScript.new()
	p.setup(data, multiplayer.get_unique_id(), self)
	if p.is_local:
		local_player = p
		if hud:
			hud.set_player(p)
	return p


func _on_peer_disconnected(id: int) -> void:
	if info.has(id):
		print("[server] %s left" % info[id]["name"])
		info.erase(id)
	var node := players_root.get_node_or_null(str(id))
	if node:
		node.queue_free()
	_broadcast_info()


func _team_size(team: int) -> int:
	var n := 0
	for id in info:
		if info[id]["team"] == team:
			n += 1
	return n


# ---------------------------------------------------------------- rules (server)

func on_player_killed(victim_id: int, killer_id: int, head_hit: bool) -> void:
	if state != State.PLAYING:
		return
	var victim: Dictionary = info.get(victim_id, {})
	var killer: Dictionary = info.get(killer_id, {})
	if not victim.is_empty():
		victim["deaths"] += 1
	if not killer.is_empty() and killer_id != victim_id:
		killer["kills"] += 1
		score[killer["team"]] += 1
	print("[server] %s killed %s%s  (BLUE %d - %d RED)" % [killer.get("name", "?"), victim.get("name", "?"),
			" (headshot)" if head_hit else "", score[0], score[1]])
	kill_feed.rpc(killer.get("name", "?"), killer.get("team", 0), victim.get("name", "?"),
			victim.get("team", 1), head_hit, killer_id)
	_broadcast_info()
	_broadcast_match()
	if not killer.is_empty() and score[killer["team"]] >= KILL_TARGET:
		_end_match()


func _end_match() -> void:
	state = State.ENDED
	var winner := -1
	if score[0] != score[1]:
		winner = 0 if score[0] > score[1] else 1
	print("[server] match over, score %d - %d" % score)
	match_ended.rpc(winner)
	_broadcast_match()
	get_tree().create_timer(NEXT_MATCH_DELAY).timeout.connect(_restart_match)


func _restart_match() -> void:
	score = [0, 0]
	time_left = MATCH_TIME
	for id in info:
		info[id]["kills"] = 0
		info[id]["deaths"] = 0
	state = State.PLAYING
	for p in players_root.get_children():
		p.server_respawn()
	_broadcast_info()
	_broadcast_match()


func _broadcast_match() -> void:
	sync_match.rpc(state, score, time_left)


func _broadcast_info() -> void:
	sync_info.rpc(info)


# ---------------------------------------------------------------- server -> clients

@rpc("authority", "call_local", "reliable")
func sync_match(new_state: int, new_score: Array, new_time: float) -> void:
	state = new_state as State
	score = new_score
	time_left = new_time
	if hud:
		hud.update_match()


@rpc("authority", "call_local", "reliable")
func sync_info(new_info: Dictionary) -> void:
	info = new_info
	if hud:
		hud.update_scoreboard()


@rpc("authority", "call_local", "reliable")
func kill_feed(killer: String, killer_team: int, victim: String, victim_team: int, head_hit: bool, killer_id: int) -> void:
	if hud:
		hud.add_kill(killer, killer_team, victim, victim_team, head_hit, killer_id == multiplayer.get_unique_id())


@rpc("authority", "call_local", "reliable")
func match_ended(winner: int) -> void:
	if hud:
		hud.show_match_end(winner, NEXT_MATCH_DELAY)
