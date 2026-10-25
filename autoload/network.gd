extends Node
## Holds how this copy of the game is connected:
##   SERVER - dedicated server on the VPS (no player, no graphics)
##   HOST   - server + player on the same device (for testing on LAN)
##   CLIENT - normal player joining a server

enum Mode { NONE, CLIENT, HOST, SERVER }

const DEFAULT_PORT := 7777
const MAX_CLIENTS := 10

var mode := Mode.NONE
var address := "127.0.0.1"
var port := DEFAULT_PORT
var player_name := "Player"
var character := 0  # scripts/characters.gd: MALE / FEMALE
var weapon := "m416"  # scripts/weapons.gd
## AI soldiers the server adds when the match starts (practice without other players).
var bots := 0

## Shown in the main menu after we get kicked back there.
var last_error := ""


func start() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := OK
	if mode == Mode.CLIENT:
		err = peer.create_client(address, port)
	else:
		err = peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK


func stop() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	mode = Mode.NONE


func is_dedicated() -> bool:
	return mode == Mode.SERVER
