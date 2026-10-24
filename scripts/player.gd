extends CharacterBody3D
## One soldier. Created by game.gd for every connected player.
##
## Who decides what:
##   - The owner (the player's own device) moves the character and aims.
##     Position/rotation are sent to everyone by the MultiplayerSynchronizer.
##   - The server decides hits, damage, deaths and respawns, so a player
##     can't just say "I hit you" - the server checks the shot itself.

const UI := preload("res://scripts/ui/ui_theme.gd")
const Fx := preload("res://scripts/fx.gd")
const AimModifier := preload("res://scripts/aim_modifier.gd")
const SOLDIER_SCENE := preload("res://assets/characters/soldier.glb")
const LOOPING_ANIMS := ["idle", "run", "crouch_idle", "crouch_walk", "jump"]

const WALK_SPEED := 5.0
const ADS_SPEED := 3.2
const CROUCH_SPEED := 2.4
const JUMP_VELOCITY := 4.6
const ACCEL := 40.0
const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.35

const MAX_HEALTH := 100
const BODY_DAMAGE := 22
const HEAD_DAMAGE := 48
const FIRE_INTERVAL := 0.09   # ~660 rounds per minute
const MAG_SIZE := 30
const RELOAD_TIME := 2.1
const RANGE := 150.0

const HIP_FOV := 75.0
const ADS_FOV := 42.0
const ARM_LENGTH := 2.6
const ADS_ARM_LENGTH := 1.1

var peer_id := 0
var player_name := ""
var team := 0
var is_local := false
var game: Node3D

# Sent from the owner to everyone (MultiplayerSynchronizer)
var net_position := Vector3.ZERO
var net_yaw := 0.0
var net_pitch := 0.0
var crouching := false

# Decided by the server (sent with RPCs)
var health := MAX_HEALTH
var dead := false

# Only used on the owner's device
var pitch := 0.0
var aiming := false
var ammo := MAG_SIZE
var reloading := false
var _reload_left := 0.0
var _fire_cooldown := 0.0
var _want_jump := false
var _mouse_delta := Vector2.ZERO
var _bot := false  # "--bot" test mode: plays by itself (for testing the server)
var _bot_sidestep := 0.0
var _bot_side := 1.0

var _server_last_fire := 0.0
var _last_pos := Vector3.ZERO
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var capsule: CapsuleShape3D
var shape: CollisionShape3D
var model: Node3D
var anim: AnimationPlayer
var aim_mod: SkeletonModifier3D
var muzzle: Node3D
var flash: MeshInstance3D
var name_tag: Label3D
var shot_audio: AudioStreamPlayer3D
var cam_pivot: Node3D
var spring: SpringArm3D
var camera: Camera3D


## Called by the spawner before the node enters the scene tree.
func setup(data: Dictionary, local_id: int, game_ref: Node3D) -> void:
	game = game_ref
	peer_id = data["id"]
	name = str(peer_id)
	player_name = data["name"]
	team = data["team"]
	is_local = peer_id == local_id
	position = data["pos"]
	rotation.y = _spawn_yaw()
	net_position = position
	net_yaw = rotation.y
	_last_pos = position

	collision_layer = 2
	collision_mask = 1 | 2
	_build_body()
	_build_sync()
	if is_local:
		_build_camera()
		_bot = "--bot" in OS.get_cmdline_user_args()
	set_multiplayer_authority(peer_id)


func _ready() -> void:
	if is_local:
		camera.make_current()


# ---------------------------------------------------------------- building

func _build_body() -> void:
	capsule = CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = STAND_HEIGHT
	shape = CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = STAND_HEIGHT / 2
	add_child(shape)

	var team_color: Color = UI.TEAM_COLORS[team]

	# The soldier model (made with tools/blender/make_soldier.py).
	# It faces +Z, the game uses -Z as forward, so turn it around.
	model = SOLDIER_SCENE.instantiate()
	model.rotation.y = PI
	add_child(model)
	anim = model.find_child("AnimationPlayer", true, false)
	for anim_name in LOOPING_ANIMS:
		if anim.has_animation(anim_name):
			anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	anim.play("idle")

	var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false)
	aim_mod = AimModifier.new()
	skeleton.add_child(aim_mod)
	muzzle = BoneAttachment3D.new()
	muzzle.bone_name = "muzzle"
	skeleton.add_child(muzzle)

	# Team colour on the vest
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i) as StandardMaterial3D
			if mat and mat.resource_name == "Vest":
				var tinted := mat.duplicate() as StandardMaterial3D
				tinted.albedo_color = mat.albedo_color.lerp(team_color, 0.5)
				mi.set_surface_override_material(i, tinted)

	flash = MeshInstance3D.new()
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.09
	flash_mesh.height = 0.18
	var flash_mat := StandardMaterial3D.new()
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_mat.albedo_color = Color(1.0, 0.8, 0.3)
	flash_mesh.material = flash_mat
	flash.mesh = flash_mesh
	flash.visible = false
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	muzzle.add_child(flash)

	name_tag = Label3D.new()
	name_tag.text = player_name
	name_tag.position.y = 2.15
	name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_tag.no_depth_test = true
	name_tag.pixel_size = 0.004
	name_tag.font_size = 40
	name_tag.outline_size = 10
	name_tag.modulate = team_color.lightened(0.3)
	name_tag.visible = false
	add_child(name_tag)

	shot_audio = AudioStreamPlayer3D.new()
	shot_audio.stream = Fx.shot_sound()
	shot_audio.unit_size = 8.0
	shot_audio.max_polyphony = 4
	muzzle.add_child(shot_audio)


func _build_sync() -> void:
	var cfg := SceneReplicationConfig.new()
	for prop in ["net_position", "net_yaw", "net_pitch", "crouching"]:
		var path := NodePath(".:" + prop)
		cfg.add_property(path)
		cfg.property_set_spawn(path, true)
		var mode := SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE if prop == "crouching" \
				else SceneReplicationConfig.REPLICATION_MODE_ALWAYS
		cfg.property_set_replication_mode(path, mode)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	sync.replication_config = cfg
	sync.replication_interval = 1.0 / 30.0
	add_child(sync)


func _build_camera() -> void:
	cam_pivot = Node3D.new()
	cam_pivot.position = Vector3(0, 1.6, 0)
	add_child(cam_pivot)
	spring = SpringArm3D.new()
	spring.position = Vector3(0.55, 0, 0)  # over the right shoulder
	spring.spring_length = ARM_LENGTH
	spring.collision_mask = 1
	spring.margin = 0.2
	var probe := SphereShape3D.new()
	probe.radius = 0.2
	spring.shape = probe
	spring.add_excluded_object(get_rid())
	cam_pivot.add_child(spring)
	camera = Camera3D.new()
	camera.fov = HIP_FOV
	camera.near = 0.05
	spring.add_child(camera)


# ---------------------------------------------------------------- update

func _physics_process(delta: float) -> void:
	if is_local:
		_owner_update(delta)
	else:
		_remote_update(delta)
	_animate(delta)


func _owner_update(delta: float) -> void:
	var hud = game.hud
	var can_act: bool = not dead and game.is_playing()

	# Looking around: finger drag (pixels) and/or mouse
	var look := Vector2.ZERO
	var ads_mult := Settings.ads_sensitivity if aiming else 1.0
	if hud:
		var screen_w := get_viewport().get_visible_rect().size.x
		look += hud.take_look_delta() / screen_w * PI * Settings.look_sensitivity * ads_mult
	look += _mouse_delta * 0.0025 * Settings.mouse_sensitivity * ads_mult
	_mouse_delta = Vector2.ZERO
	if not dead:
		rotation.y -= look.x
		pitch = clampf(pitch - look.y, deg_to_rad(-75), deg_to_rad(70))

	# Moving
	var input := Vector2.ZERO
	if can_act:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if hud:
			input += hud.get_move()
		input = input.limit_length(1.0)
	var dir := global_basis * Vector3(input.x, 0, input.y)
	dir.y = 0
	dir = dir.normalized() * input.length()
	var speed := CROUCH_SPEED if crouching else (ADS_SPEED if aiming else WALK_SPEED)
	velocity.x = move_toward(velocity.x, dir.x * speed, ACCEL * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, ACCEL * delta)
	if not is_on_floor():
		velocity.y -= _gravity * delta
	if _want_jump and can_act and is_on_floor():
		if crouching:
			set_crouch(false)
		else:
			velocity.y = JUMP_VELOCITY
	_want_jump = false
	if not dead:
		move_and_slide()

	# Shooting
	_fire_cooldown -= delta
	if reloading:
		_reload_left -= delta
		if _reload_left <= 0:
			reloading = false
			ammo = MAG_SIZE
	var firing := Input.is_action_pressed("fire") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if hud and hud.is_firing():
		firing = true
	if _bot and can_act:
		firing = _bot_think()
	if firing and can_act and not reloading and _fire_cooldown <= 0:
		if ammo > 0:
			_shoot()
		else:
			start_reload()

	# Camera follows aim
	cam_pivot.rotation.x = pitch
	cam_pivot.position.y = 1.1 if crouching else 1.6
	var t := clampf(delta * 12.0, 0, 1)
	spring.spring_length = lerpf(spring.spring_length, ADS_ARM_LENGTH if aiming else ARM_LENGTH, t)
	spring.position.x = lerpf(spring.position.x, 0.45 if aiming else 0.55, t)
	camera.fov = lerpf(camera.fov, ADS_FOV if aiming else HIP_FOV, t)

	net_position = global_position
	net_yaw = rotation.y
	net_pitch = pitch


func _remote_update(delta: float) -> void:
	if dead:
		return
	var t := clampf(delta * 15.0, 0, 1)
	if global_position.distance_to(net_position) > 4.0:
		global_position = net_position
	else:
		global_position = global_position.lerp(net_position, t)
	rotation.y = lerp_angle(rotation.y, net_yaw, t)
	pitch = lerpf(pitch, net_pitch, t)
	if (capsule.height < STAND_HEIGHT) != crouching:
		_apply_crouch()
	var me = game.local_player
	name_tag.visible = me != null and me.team == team


func _animate(delta: float) -> void:
	var moved := global_position - _last_pos
	_last_pos = global_position
	var vertical := moved.y / maxf(delta, 0.001)
	moved.y = 0
	var speed := moved.length() / maxf(delta, 0.001)
	aim_mod.pitch = 0.0 if dead else pitch

	var in_air := not is_on_floor() if is_local else absf(vertical) > 1.5
	var want := "idle"
	var rate := 1.0
	if dead:
		want = "death"
	elif in_air:
		want = "jump"
	elif crouching:
		want = "crouch_walk" if speed > 0.4 else "crouch_idle"
		rate = clampf(speed / CROUCH_SPEED, 0.6, 1.5) if speed > 0.4 else 1.0
	elif speed > 0.4:
		want = "run"
		rate = clampf(speed / WALK_SPEED * 1.3, 0.6, 1.4)
	if anim.current_animation != want:
		anim.play(want, 0.15)
	anim.speed_scale = rate


# ---------------------------------------------------------------- actions

## Called by keyboard/mouse.
func _unhandled_input(event: InputEvent) -> void:
	if not is_local:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_delta += event.relative
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if not Settings.use_touch_controls() and not (game.hud and game.hud.menu_open):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("jump"):
		on_action("jump")
	elif event.is_action_pressed("crouch"):
		on_action("crouch")
	elif event.is_action_pressed("reload"):
		on_action("reload")
	elif event.is_action("aim") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		aiming = event.is_pressed()  # PC: hold right mouse button


## Called by the on-screen buttons (and keyboard above).
func on_action(id: String) -> void:
	if dead:
		return
	match id:
		"jump":
			_want_jump = true
		"crouch":
			set_crouch(not crouching)
		"reload":
			start_reload()
		"aim":
			aiming = not aiming


func set_crouch(value: bool) -> void:
	crouching = value
	_apply_crouch()


func _apply_crouch() -> void:
	capsule.height = CROUCH_HEIGHT if crouching else STAND_HEIGHT
	shape.position.y = capsule.height / 2


func start_reload() -> void:
	if reloading or ammo == MAG_SIZE or dead:
		return
	reloading = true
	_reload_left = RELOAD_TIME


## Spread in degrees - bigger when moving/jumping, small when aiming.
func current_spread() -> float:
	var s := 0.3 if aiming else 1.6
	if Vector2(velocity.x, velocity.z).length() > 1.0:
		s += 0.8
	if not is_on_floor():
		s += 2.0
	if crouching:
		s *= 0.7
	return s


func _shoot() -> void:
	_fire_cooldown = FIRE_INTERVAL
	ammo -= 1
	var origin := camera.global_position
	var dir := _apply_spread(-camera.global_basis.z, deg_to_rad(current_spread()))
	server_fire.rpc_id(1, origin, dir)

	# Show the shot right away on our screen (the server decides the hit).
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * RANGE)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var end: Vector3 = hit.position if hit else origin + dir * RANGE
	_shot_effects(end)

	# Recoil kicks the aim up a little
	pitch = minf(pitch + deg_to_rad(0.45 if aiming else 0.75), deg_to_rad(70))
	rotation.y += randf_range(-0.004, 0.004)


## Test bot: turn towards the nearest enemy, walk closer, shoot if visible.
func _bot_think() -> bool:
	var target: Node3D = null
	for p in get_parent().get_children():
		if p != self and p.team != team and not p.dead:
			if target == null or global_position.distance_to(p.global_position) < global_position.distance_to(target.global_position):
				target = p
	if target == null:
		return false
	var to := target.global_position + Vector3(0, 1.2, 0) - camera.global_position
	rotation.y = atan2(-to.x, -to.z)
	pitch = atan2(to.y, Vector2(to.x, to.z).length())
	var q := PhysicsRayQueryParameters3D.create(camera.global_position, target.global_position + Vector3(0, 1.2, 0))
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var visible_target: bool = hit and hit.collider == target
	if not visible_target or to.length() > 18.0:
		var step := Vector3(to.x, 0, to.z).normalized()
		_bot_sidestep -= get_physics_process_delta_time()
		if is_on_wall() and _bot_sidestep <= 0:
			_bot_sidestep = randf_range(0.8, 2.0)
			_bot_side = [-1.0, 1.0].pick_random()
		if _bot_sidestep > 0:
			step = step.rotated(Vector3.UP, PI / 2 * _bot_side)
		velocity.x = step.x * WALK_SPEED
		velocity.z = step.z * WALK_SPEED
		move_and_slide()
	return visible_target


func _apply_spread(dir: Vector3, spread: float) -> Vector3:
	var right := dir.cross(Vector3.UP)
	right = right.normalized() if right.length() > 0.01 else Vector3.RIGHT
	var up := right.cross(dir).normalized()
	var k := tan(spread)
	return (dir + right * randf_range(-k, k) + up * randf_range(-k, k)).normalized()


func _shot_effects(end: Vector3) -> void:
	Fx.tracer(game, muzzle.global_position, end)
	shot_audio.play()
	flash.visible = true
	flash.rotation.z = randf() * TAU
	get_tree().create_timer(0.04).timeout.connect(func(): flash.visible = false)


# ---------------------------------------------------------------- server side

@rpc("any_peer", "call_local", "reliable")
func server_fire(origin: Vector3, dir: Vector3) -> void:
	if not multiplayer.is_server() or multiplayer.get_remote_sender_id() != peer_id:
		return
	if dead or not game.is_playing():
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _server_last_fire < FIRE_INTERVAL * 0.7:
		return
	_server_last_fire = now

	var eye := global_position + Vector3(0, 1.6, 0)
	if origin.distance_to(eye) > 5.0:
		origin = eye
	dir = dir.normalized()
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * RANGE)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var end := origin + dir * RANGE
	if hit:
		end = hit.position
		var target = hit.collider
		if target.has_method("server_take_damage") and target.team != team and not target.dead:
			var head_hit: bool = end.y > target.global_position.y + target.capsule.height - 0.35
			target.server_take_damage(HEAD_DAMAGE if head_hit else BODY_DAMAGE, peer_id, head_hit)
			hit_confirm.rpc_id(peer_id, head_hit)
	fx_shot.rpc(end)


func server_take_damage(amount: int, attacker_id: int, head_hit: bool) -> void:
	health = maxi(0, health - amount)
	sync_health.rpc(health, attacker_id)
	if health == 0:
		dead = true
		set_dead.rpc()
		game.on_player_killed(peer_id, attacker_id, head_hit)
		get_tree().create_timer(game.RESPAWN_DELAY).timeout.connect(server_respawn)


func server_respawn() -> void:
	if not is_inside_tree():
		return
	health = MAX_HEALTH
	dead = false
	do_respawn.rpc(game.get_spawn_point(team), _spawn_yaw())


func _spawn_yaw() -> float:
	return PI if team == 0 else 0.0


func _from_server() -> bool:
	return multiplayer.get_remote_sender_id() == 1


# ---------------------------------------------------------------- server -> clients

@rpc("any_peer", "call_local", "unreliable")
func fx_shot(end: Vector3) -> void:
	if not _from_server() or is_local or Network.is_dedicated():
		return
	_shot_effects(end)


@rpc("any_peer", "call_local", "reliable")
func hit_confirm(head_hit: bool) -> void:
	if _from_server() and game.hud:
		game.hud.show_hitmarker(head_hit)


@rpc("any_peer", "call_local", "reliable")
func sync_health(value: int, attacker_id: int) -> void:
	if not _from_server():
		return
	var took_damage := value < health
	health = value
	if is_local and took_damage and game.hud:
		game.hud.on_damaged(attacker_id)


@rpc("any_peer", "call_local", "reliable")
func set_dead() -> void:
	if not _from_server():
		return
	dead = true
	health = 0
	shape.set_deferred("disabled", true)
	name_tag.visible = false
	aiming = false
	if is_local and game.hud:
		game.hud.on_local_death(game.RESPAWN_DELAY)


@rpc("any_peer", "call_local", "reliable")
func do_respawn(pos: Vector3, yaw: float) -> void:
	if not _from_server():
		return
	dead = false
	health = MAX_HEALTH
	shape.set_deferred("disabled", false)
	anim.play("idle")
	global_position = pos
	net_position = pos
	_last_pos = pos
	velocity = Vector3.ZERO
	rotation.y = yaw
	net_yaw = yaw
	if is_local:
		pitch = 0
		ammo = MAG_SIZE
		reloading = false
		aiming = false
		set_crouch(false)
