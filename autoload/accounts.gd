extends Node
## Player accounts, stored on our own game server (user://accounts.cfg
## there). The login screen connects to the server only to sign up or log
## in, then closes that connection; playing a match is a separate one.
##
## It uses its own port (game port + 1, so 7778) and its own multiplayer
## branch, so logins never mix with the match traffic.
## Passwords are never sent or stored as typed: the client sends
## SHA-256 of name + password, the server stores SHA-256 of salt + that.

signal finished(ok: bool, message: String)

const PATH := "user://accounts.cfg"
const TIMEOUT := 8.0
const NAME_RE := "^[A-Za-z0-9_]{3,16}$"

var _api := SceneMultiplayer.new()
var _peer: ENetMultiplayerPeer
var _busy := false
var _request_id := 0
var _accounts := ConfigFile.new()
var _name_check := RegEx.new()


func _ready() -> void:
	get_tree().set_multiplayer(_api, get_path())
	_api.connected_to_server.connect(_on_connected)
	_api.connection_failed.connect(_finish.bind(false, "Can't reach the server."))
	_name_check.compile(NAME_RE)


static func port_for(game_port: int) -> int:
	return game_port + 1


# ---------------------------------------------------------------- server

## Called by the game server (dedicated or LAN host) when it starts.
func start_server(game_port: int) -> void:
	_accounts.load(PATH)
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(port_for(game_port), 32)
	if err != OK:
		push_warning("Accounts: could not open port %d (error %d)" % [port_for(game_port), err])
		return
	_api.multiplayer_peer = _peer
	print("[server] accounts on UDP port %d (%d accounts)" % [port_for(game_port), _accounts.get_sections().size()])


@rpc("any_peer", "reliable")
func _auth(user: String, digest: String, sign_up: bool, character: int) -> void:
	if not _api.is_server():
		return
	var sender := _api.get_remote_sender_id()
	var key := user.to_lower()
	var ok := false
	var message := ""
	if _name_check.search(user) == null or digest.length() != 64:
		message = "Name: 3-16 letters, numbers or _"
	elif sign_up:
		if _accounts.has_section(key):
			message = "That name is taken."
		else:
			var salt := Crypto.new().generate_random_bytes(16).hex_encode()
			_accounts.set_value(key, "name", user)
			_accounts.set_value(key, "salt", salt)
			_accounts.set_value(key, "hash", (salt + digest).sha256_text())
			_accounts.set_value(key, "character", clampi(character, 0, 1))
			_accounts.set_value(key, "created", Time.get_datetime_string_from_system(true))
			_accounts.save(PATH)
			print("[server] new account: %s" % user)
			ok = true
	elif not _accounts.has_section(key):
		message = "No account with that name."
	else:
		var salt: String = _accounts.get_value(key, "salt")
		ok = (salt + digest).sha256_text() == _accounts.get_value(key, "hash")
		message = "" if ok else "Wrong password."
	var stored_name: String = _accounts.get_value(key, "name", user) if ok else user
	var stored_char: int = _accounts.get_value(key, "character", character) if ok else character
	_result.rpc_id(sender, ok, message, stored_name, stored_char)


# ---------------------------------------------------------------- client

var _request := {}


## Signs up or logs in; emits `finished`. On success the name (as the
## server spells it) and character are saved in Settings.
func request(address: String, game_port: int, user: String, password: String, sign_up: bool, character: int) -> void:
	if _busy:
		return
	_busy = true
	_request = {
		"user": user.strip_edges(), "sign_up": sign_up, "character": character,
		"digest": ("kanki:" + user.strip_edges().to_lower() + ":" + password).sha256_text(),
	}
	_peer = ENetMultiplayerPeer.new()
	if _peer.create_client(address, port_for(game_port)) != OK:
		_finish(false, "Can't reach the server.")
		return
	_api.multiplayer_peer = _peer
	_request_id += 1
	get_tree().create_timer(TIMEOUT).timeout.connect(_on_timeout.bind(_request_id))


func _on_timeout(id: int) -> void:
	if id == _request_id:
		_finish(false, "The server did not answer.")


func _on_connected() -> void:
	if _busy:
		_auth.rpc_id(1, _request["user"], _request["digest"], _request["sign_up"], _request["character"])


@rpc("authority", "reliable")
func _result(ok: bool, message: String, user: String, character: int) -> void:
	if ok:
		Settings.player_name = user
		Settings.character = character
		Settings.account = user
		Settings.save_settings()
	_finish(ok, message)


func _finish(ok: bool, message: String) -> void:
	if not _busy:
		return
	_busy = false
	_request_id += 1
	_api.multiplayer_peer = null
	_peer = null
	finished.emit(ok, message)
