extends CharacterBody3D
## One soldier. Created by game.gd for every connected player.
##
## Who decides what:
##   - The owner (the player's own device) moves the character and aims.
##     Position/rotation are sent to everyone by the MultiplayerSynchronizer.
##   - The server decides hits, damage, deaths and respawns, so a player
##     can't just say "I hit you" - the server checks the shot itself.
##   - Bots (AI soldiers, see game.gd add_bot) are moved by the server.

const UI := preload("res://scripts/ui/ui_theme.gd")
const Fx := preload("res://scripts/fx.gd")
const AimModifier := preload("res://scripts/aim_modifier.gd")
const Characters := preload("res://scripts/characters.gd")
const Weapons := preload("res://scripts/weapons.gd")
const WeaponPose := preload("res://scripts/weapon_pose.gd")
const WeaponHolder := preload("res://scripts/weapon_holder.gd")
const HandGrip := preload("res://scripts/hand_grip.gd")
const LOOPING_ANIMS := ["idle", "run", "crouch_idle", "crouch_walk", "jump", "walk_back",
		"strafe_left", "strafe_right", "rifle_low", "rifle_aim", "fire"]
## Body clips whose arms don't hold the rifle: the upper body comes from
## "rifle_low" instead (scripts/weapon_pose.gd)
const UNARMED_CLIPS := ["run", "jump"]

const WALK_SPEED := 5.0     # normal run (joystick fully pushed)
const SLOW_SPEED := 2.2     # walking (joystick pushed a little, like PUBG)
const SLOW_PUSH := 0.6      # joystick push below this walks
const WALK_CLIP_SPEED := 1.4   # "rifle_low" (Walk With Rifle) covers this much a second
const SPRINT_SPEED := 6.4
const ADS_SPEED := 3.0
const CROUCH_SPEED := 2.4
const JUMP_VELOCITY := 4.6
const ACCEL := 22.0          # how fast you speed up (m/s per second)
const DECEL := 30.0          # how fast you stop
const AIR_ACCEL := 5.0
const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.35

const MAX_HEALTH := 100
const MAG_SIZE := 30
const RELOAD_TIME := 2.1
const RANGE := 150.0

## Third person camera, like PUBG Mobile: close behind the right shoulder
const HIP_FOV := 80.0
const ARM_LENGTH := 1.75
const SHOULDER := 0.5
const EYE_HEIGHT := 1.72
const CROUCH_EYE_HEIGHT := 1.25
## Aiming: the camera moves to the red dot sight (first person) this fast
const ADS_TIME := 0.16
## Camera field of view when aiming with each scope.
const SCOPE_FOV := {"red_dot": 58.0, "2x": 36.0, "3x": 26.0, "4x": 19.0, "6x": 13.0, "8x": 9.5}
const PEEK_ANGLE := 0.4      # how far the upper body leans (radians)
const PEEK_SHIFT := 0.5      # how far the camera moves to the peek side
const PEEK_TILT := 0.1       # camera roll while peeking
## Body keeps facing the camera this long after the last shot.
const FACE_CAMERA_AFTER_FIRE := 0.8

var peer_id := 0
var player_name := ""
var team := 0
var character := Characters.MALE
var weapon := "m416"
var weapon_info: Dictionary   # scripts/weapons.gd: damage, fire rate...
var is_local := false        # the player using this device
var is_bot := false          # an AI soldier
var controlled := false      # this device moves it (its owner, or the server for bots)
var game: Node3D

# Sent from the owner to everyone (MultiplayerSynchronizer)
var net_position := Vector3.ZERO
var net_yaw := 0.0
var net_pitch := 0.0
var net_body_yaw := 0.0
var crouching := false
var peek := 0                # -1 left, 0 none, 1 right

# Decided by the server (sent with RPCs)
var health := MAX_HEALTH
var dead := false

# Only used on the owner's device
var pitch := 0.0
var aiming := false
var scope := "red_dot"       # scope on the current gun
var sprinting := false
var body_yaw := 0.0          # where the soldier's body faces (camera yaw is rotation.y)
var _since_fire := 10.0
var _sprint_hold := 0.0
var _lean := 0.0
var _prev_body_yaw := 0.0
var ammo := MAG_SIZE
var reloading := false
var _reload_left := 0.0
var _fire_cooldown := 0.0
var _want_jump := false
var _mouse_delta := Vector2.ZERO
var _bot := false  # the AI plays it: bots, or the local player in "--bot" test mode
var _bot_move := Vector2.ZERO  # AI's joystick
var _bot_fire := false
var _bot_seen := 0.0           # how long the target has been in sight
var _bot_aim_error := Vector2.ZERO
var _bot_error_left := 0.0
var _bot_burst := 0.0
var _bot_sidestep := 0.0
var _bot_strafe_left := 0.0
var _bot_side := 1.0

var _server_last_fire := 0.0
var _last_pos := Vector3.ZERO
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var capsule: CapsuleShape3D
var shape: CollisionShape3D
var model: Node3D
var anim: AnimationPlayer
var aim_mod: SkeletonModifier3D
var weapon_pose: SkeletonModifier3D
var hand_grip: SkeletonModifier3D
var _layer_time := 0.0   # clock for looping upper-body clips (aim, fire)
var muzzle: Node3D
var flash: MeshInstance3D
var name_tag: Label3D
var shot_audio: AudioStreamPlayer3D
var cam_pivot: Node3D
var spring: SpringArm3D
var _tpp_spot: Node3D      # end of the spring arm: the third person camera's place
var camera: Camera3D       # what we look through: third person, or the sight when aiming
var holder: Node3D         # the gun (scripts/weapon_holder.gd)
var _ads := 0.0            # 0 third person .. 1 looking through the sight
var _near_fade := false


## Called by the spawner before the node enters the scene tree.
func setup(data: Dictionary, local_id: int, game_ref: Node3D) -> void:
	game = game_ref
	peer_id = data["id"]
	name = str(peer_id)
	player_name = data["name"]
	team = data["team"]
	character = data.get("character", Characters.MALE)
	weapon = data.get("weapon", "m416")
	weapon_info = Weapons.get_info(weapon)
	is_bot = data.get("bot", false)
	is_local = peer_id == local_id and not is_bot
	var owner_id: int = 1 if is_bot else peer_id
	controlled = owner_id == local_id
	position = data["pos"]
	rotation.y = _spawn_yaw()
	net_position = position
	net_yaw = rotation.y
	body_yaw = rotation.y
	net_body_yaw = body_yaw
	_last_pos = position

	collision_layer = 2
	collision_mask = 1 | 2
	_build_body()
	_build_sync()
	if controlled:
		_build_camera()
		_bot = is_bot or "--bot" in OS.get_cmdline_user_args()
	set_multiplayer_authority(owner_id)


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

	# The character the player picked, in the team's uniform.
	# It faces +Z, the game uses -Z as forward, so turn it around.
	model = Characters.make(character, team, true)
	model.rotation.y = PI
	add_child(model)
	anim = model.find_child("AnimationPlayer", true, false)
	for anim_name in LOOPING_ANIMS:
		if anim.has_animation(anim_name):
			anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	anim.play("idle")

	var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false)
	# Upper-body layer first, then the aim pitch / peek lean on top of it
	weapon_pose = WeaponPose.new()
	skeleton.add_child(weapon_pose)
	weapon_pose.setup()
	weapon_pose.influence = 0.0
	aim_mod = AimModifier.new()
	skeleton.add_child(aim_mod)
	holder = WeaponHolder.new()
	holder.setup(skeleton, weapon, anim)
	# Fingers round the gun, left hand on the handguard (last modifier)
	hand_grip = HandGrip.new()
	skeleton.add_child(hand_grip)
	hand_grip.setup(holder, character, weapon)
	muzzle = holder.muzzle

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
	for prop in ["net_position", "net_yaw", "net_pitch", "net_body_yaw", "crouching", "peek"]:
		var path := NodePath(".:" + prop)
		cfg.add_property(path)
		cfg.property_set_spawn(path, true)
		var mode := SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE if prop in ["crouching", "peek"] \
				else SceneReplicationConfig.REPLICATION_MODE_ALWAYS
		cfg.property_set_replication_mode(path, mode)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	sync.replication_config = cfg
	sync.replication_interval = 1.0 / 30.0
	add_child(sync)


func _build_camera() -> void:
	cam_pivot = Node3D.new()
	cam_pivot.position = Vector3(0, EYE_HEIGHT, 0)
	add_child(cam_pivot)
	spring = SpringArm3D.new()
	spring.position = Vector3(SHOULDER, 0, 0)  # over the right shoulder
	spring.spring_length = ARM_LENGTH
	spring.collision_mask = 1
	spring.margin = 0.2
	var probe := SphereShape3D.new()
	probe.radius = 0.2
	spring.shape = probe
	spring.add_excluded_object(get_rid())
	cam_pivot.add_child(spring)
	camera = Camera3D.new()
	_tpp_spot = Node3D.new()
	spring.add_child(_tpp_spot)
	camera.fov = HIP_FOV
	camera.near = 0.03
	camera.top_level = true
	add_child(camera)
	# The view is placed once the skeleton (and the gun on it) has moved
	model.find_child("Skeleton3D", true, false).skeleton_updated.connect(_update_view)


# ---------------------------------------------------------------- update

func _physics_process(delta: float) -> void:
	if controlled:
		_owner_update(delta)
	else:
		_remote_update(delta)
	if not is_local:
		var me = game.local_player
		name_tag.visible = not dead and me != null and me.team == team
	_animate(delta)


func _owner_update(delta: float) -> void:
	var hud = game.hud if is_local else null
	var can_act: bool = not dead and game.is_playing()
	if _bot and can_act:
		_bot_think(delta)
	var menu_open: bool = hud != null and hud.menu_open
	var sens_key := scope if aiming else "tpp"

	# Looking around: finger drag + gyroscope + mouse
	var look := Vector2.ZERO
	if hud:
		var screen_w := get_viewport().get_visible_rect().size.x
		look += hud.take_look_delta() / screen_w * PI * Settings.drag_factor(sens_key)
	var gyro_k := Settings.gyro_factor(sens_key)
	if is_local and gyro_k > 0.0 and Settings.use_touch_controls() and not menu_open:
		var g := Input.get_gyroscope()
		var gx := -g.y * (-1.0 if Settings.gyro_invert_x else 1.0)
		var gy := -g.x * (-1.0 if Settings.gyro_invert_y else 1.0)
		look += Vector2(gx, gy) * delta * gyro_k
	var mouse_k := 0.0025 * Settings.mouse_sensitivity * (Settings.drag_factor(sens_key) if aiming else 1.0)
	look += _mouse_delta * mouse_k
	_mouse_delta = Vector2.ZERO
	if not dead:
		rotation.y -= look.x
		pitch = clampf(pitch - look.y, deg_to_rad(-75), deg_to_rad(70))

	# Joystick / keys
	var input := Vector2.ZERO
	var stick := Vector2.ZERO
	if can_act:
		if is_local:
			input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if hud:
			stick = hud.get_move()
			input += stick
		if _bot:
			input += _bot_move
		input = input.limit_length(1.0)

	# Sprint: push the joystick all the way forward (or hold Shift)
	var wants_sprint := is_local and Input.is_action_pressed("sprint") and input.y < -0.5
	if Settings.auto_sprint and stick.length() > 0.95 and stick.y < -0.85:
		_sprint_hold += delta
	else:
		_sprint_hold = 0.0
	wants_sprint = wants_sprint or _sprint_hold > 0.25
	sprinting = wants_sprint and not aiming and not crouching and not reloading \
			and _since_fire > 0.3 and is_on_floor()
	if sprinting:
		peek = 0

	var dir := Basis(Vector3.UP, rotation.y) * Vector3(input.x, 0, input.y)
	var speed := WALK_SPEED
	if sprinting:
		speed = SPRINT_SPEED
	elif crouching:
		speed = CROUCH_SPEED
	elif aiming or peek != 0:
		speed = ADS_SPEED
	# A little push walks, more runs (like PUBG's joystick)
	var push := input.length()
	if push < SLOW_PUSH and not sprinting:
		speed = minf(speed, SLOW_SPEED) * push / SLOW_PUSH
	var target := dir.normalized() * speed if push > 0.05 else Vector3.ZERO
	var rate := AIR_ACCEL if not is_on_floor() else (ACCEL if target.length() > 0.1 else DECEL)
	var horizontal := Vector2(velocity.x, velocity.z).move_toward(Vector2(target.x, target.z), rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
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

	# Where the body faces: towards the camera when aiming/shooting/peeking,
	# otherwise it turns smoothly towards the direction you run.
	_since_fire += delta
	var face_camera := aiming or peek != 0 or _since_fire < FACE_CAMERA_AFTER_FIRE or _bot
	var body_target := body_yaw
	if face_camera:
		body_target = rotation.y
	elif dir.length() > 0.1:
		body_target = atan2(-dir.x, -dir.z)
	var turn_speed := 18.0 if face_camera else 11.0
	body_yaw = lerp_angle(body_yaw, body_target, 1.0 - exp(-turn_speed * delta))

	# Shooting
	_fire_cooldown -= delta
	if reloading:
		_reload_left -= delta
		if _reload_left <= 0:
			reloading = false
			ammo = MAG_SIZE
	var firing := is_local and Input.is_action_pressed("fire") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if hud and hud.is_firing():
		firing = true
	if _bot and _bot_fire:
		firing = true
	if firing and can_act and not reloading and _fire_cooldown <= 0:
		if ammo > 0:
			_shoot()
		else:
			start_reload()

	# Camera: over the right shoulder; peeking moves it out to that side
	# and tilts it; aiming moves it into the sight (see _update_view)
	var t := 1.0 - exp(-12.0 * delta)
	cam_pivot.rotation.x = pitch
	cam_pivot.position.y = lerpf(cam_pivot.position.y, CROUCH_EYE_HEIGHT if crouching else EYE_HEIGHT, t)
	cam_pivot.rotation.z = lerpf(cam_pivot.rotation.z, -peek * PEEK_TILT, t)
	spring.position.x = lerpf(spring.position.x, SHOULDER + peek * PEEK_SHIFT, t)
	_ads = move_toward(_ads, 1.0 if aiming and not dead else 0.0, delta / ADS_TIME)
	holder.ads = smoothstep(0.0, 1.0, _ads)
	var view := _look_basis()
	holder.aim_basis = Basis(view.z, view.y, -view.x)   # gun: muzzle -X along the look

	net_position = global_position
	net_yaw = rotation.y
	net_pitch = pitch
	net_body_yaw = body_yaw


## Where the player looks (with the peek tilt), as a camera basis.
func _look_basis() -> Basis:
	return Basis(Vector3.UP, rotation.y) * Basis(Vector3.RIGHT, pitch) * Basis(Vector3.BACK, cam_pivot.rotation.z)


## Puts the camera behind the shoulder, or in the red dot sight when
## aiming (in between while switching, like PUBG's quick zoom).
func _update_view() -> void:
	if camera == null or not is_inside_tree():
		return
	var e: float = holder.ads
	var view := _tpp_spot.global_transform
	if e > 0.0:
		var sight := Transform3D(_look_basis(), holder.global_transform * holder.eye_point)
		view = view.interpolate_with(sight, e)
	camera.global_transform = view
	camera.fov = lerpf(HIP_FOV, SCOPE_FOV.get(scope, 58.0), e)
	# Our own head and shoulders right at the lens fade away (sight view,
	# or the camera pushed in against a wall)
	var near := e > 0.4 or spring.get_hit_length() < 0.7
	if near != _near_fade and is_local:
		_near_fade = near
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			for i in mi.mesh.get_surface_count():
				var mat := mi.get_surface_override_material(i) as StandardMaterial3D
				if mat:
					mat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER if near \
							else BaseMaterial3D.DISTANCE_FADE_DISABLED
					mat.distance_fade_min_distance = 0.22
					mat.distance_fade_max_distance = 0.4


func _remote_update(delta: float) -> void:
	if dead:
		return
	var t := 1.0 - exp(-15.0 * delta)
	if global_position.distance_to(net_position) > 4.0:
		global_position = net_position
	else:
		global_position = global_position.lerp(net_position, t)
	rotation.y = lerp_angle(rotation.y, net_yaw, t)
	body_yaw = lerp_angle(body_yaw, net_body_yaw, t)
	pitch = lerpf(pitch, net_pitch, t)
	if (capsule.height < STAND_HEIGHT) != crouching:
		_apply_crouch()


func _animate(delta: float) -> void:
	var moved := global_position - _last_pos
	_last_pos = global_position
	var vertical := moved.y / maxf(delta, 0.001)
	moved.y = 0
	var speed := moved.length() / maxf(delta, 0.001)

	# Body direction, with a small lean into turns (like a real runner)
	var turn_rate := angle_difference(_prev_body_yaw, body_yaw) / maxf(delta, 0.001)
	_prev_body_yaw = body_yaw
	model.rotation.y = body_yaw - rotation.y + PI
	var lean_target := clampf(-turn_rate * 0.03 * clampf(speed / WALK_SPEED, 0, 1), -0.14, 0.14)
	model.rotation.z = lerpf(model.rotation.z, 0.0 if dead else lean_target, 1.0 - exp(-8.0 * delta))

	# Upper body follows the aim only when facing the camera direction
	var facing := clampf(cos(angle_difference(body_yaw, rotation.y)), 0.0, 1.0)
	aim_mod.pitch = 0.0 if dead else pitch * facing
	_lean = lerpf(_lean, 0.0 if dead else peek * PEEK_ANGLE, 1.0 - exp(-12.0 * delta))
	aim_mod.lean = _lean

	var in_air := not is_on_floor() if controlled else absf(vertical) > 1.5
	var want := "idle"
	var rate := 1.0
	# Movement direction relative to the body: forward, backward or sideways
	var forward := Vector3(sin(body_yaw + PI), 0, cos(body_yaw + PI))
	var right := Vector3(-forward.z, 0, forward.x)
	var dir := moved.normalized()
	var ahead := dir.dot(forward)
	var side := dir.dot(right)
	if dead:
		want = "death"
	elif in_air:
		want = "jump"
	elif crouching:
		want = "crouch_walk" if speed > 0.4 else "crouch_idle"
		rate = clampf(speed / CROUCH_SPEED, 0.6, 1.5) if speed > 0.4 else 1.0
		if speed > 0.4 and ahead < -0.3:
			rate = -rate
	elif speed > 0.4:
		if ahead > 0.5 and speed < 3.2:
			want = "rifle_low"   # walking, rifle ready
			rate = clampf(speed / WALK_CLIP_SPEED, 0.5, 2.2)
		elif ahead > 0.5:
			want = "run"
			rate = clampf(speed / 4.7, 0.5, 1.6)   # Run_Forward covers 4.7 m/s
		elif ahead < -0.5:
			want = "walk_back"
			rate = clampf(speed / 1.8, 0.6, 2.0)
		else:
			want = "strafe_right" if side > 0 else "strafe_left"
			rate = clampf(speed / 1.3, 0.6, 2.2)
	if anim.current_animation != want:
		anim.play(want, 0.2)
	anim.speed_scale = rate

	# Upper body: reload > shooting (recoil) > aiming > rifle held low (for
	# clips whose arms don't hold the rifle) > the body clip itself.
	_layer_time += delta
	var layer := ""
	var t := _layer_time
	if dead:
		layer = ""
	elif reloading:
		layer = "reload"
		var clip_len := anim.get_animation("reload").length
		t = (1.0 - _reload_left / RELOAD_TIME) * clip_len
	elif _since_fire < 0.25:
		layer = "fire"
	elif aiming or _since_fire < FACE_CAMERA_AFTER_FIRE:
		layer = "rifle_aim"
	elif want in UNARMED_CLIPS:
		layer = "rifle_low"
		t = 0.2
	if layer != "":
		weapon_pose.clip = anim.get_animation(layer)
		weapon_pose.time = t
	weapon_pose.influence = lerpf(weapon_pose.influence, 1.0 if layer != "" else 0.0, 1.0 - exp(-12.0 * delta))
	# Left hand leaves the handguard to change the magazine, and when dying
	var left_on_gun := 0.0 if dead or reloading else 1.0
	hand_grip.left_ik = lerpf(hand_grip.left_ik, left_on_gun, 1.0 - exp(-10.0 * delta))


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
	elif event.is_action("peek_left") or event.is_action("peek_right"):
		# PC: hold Q / E
		var dir_peek := -1 if event.is_action("peek_left") else 1
		if event.is_pressed():
			peek = dir_peek
		elif peek == dir_peek:
			peek = 0


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
		"peek_left":
			peek = 0 if peek == -1 else -1
		"peek_right":
			peek = 0 if peek == 1 else 1


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
	var moving := Vector2(velocity.x, velocity.z).length()
	if moving > 1.0:
		s += 0.8 if moving < WALK_SPEED + 0.5 else 2.0
	if not is_on_floor():
		s += 2.0
	if crouching:
		s *= 0.7
	return s


func _shoot() -> void:
	_fire_cooldown = weapon_info["fire_interval"]
	_since_fire = 0.0
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


## AI: picks the nearest enemy and turns towards it like a person (not in
## an instant, the aim wanders a little and settles), walks closer while it
## can't see it, and once it has seen it for a moment shoots in short
## bursts, stepping from side to side. Sets the AI's joystick and trigger.
func _bot_think(delta: float) -> void:
	_bot_move = Vector2.ZERO
	_bot_fire = false
	var target: Node3D = null
	for p in get_parent().get_children():
		if p != self and p.team != team and not p.dead:
			if target == null or global_position.distance_to(p.global_position) < global_position.distance_to(target.global_position):
				target = p
	if target == null:
		_bot_seen = 0.0
		return
	var aim_at: Vector3 = target.global_position + Vector3(0, 0.8 if target.crouching else 1.15, 0)
	var eye := global_position + Vector3(0, 1.5, 0)
	var q := PhysicsRayQueryParameters3D.create(eye, aim_at)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var in_sight: bool = hit and hit.collider == target
	_bot_seen = _bot_seen + delta if in_sight else 0.0

	# Aim (from the camera, where the shots start)
	_bot_error_left -= delta
	if _bot_error_left <= 0.0:
		_bot_error_left = randf_range(0.3, 0.7)
		var shaky := clampf(1.2 - _bot_seen, 0.25, 1.0)
		_bot_aim_error = Vector2(randf_range(-1.0, 1.0), randf_range(-0.5, 0.5)) * deg_to_rad(5.0) * shaky
	var to := aim_at - camera.global_position
	var want_yaw := atan2(-to.x, -to.z) + _bot_aim_error.x
	var want_pitch := atan2(to.y, Vector2(to.x, to.z).length()) + _bot_aim_error.y
	var turn := 1.0 - exp(-(7.0 if in_sight else 4.0) * delta)
	rotation.y = lerp_angle(rotation.y, want_yaw, turn)
	pitch = lerpf(pitch, want_pitch, turn)

	# Move: closer while out of sight, side to side while shooting
	var flat := Vector3(to.x, 0, to.z)
	var go := Vector3.ZERO
	if not in_sight or flat.length() > 20.0:
		go = flat.normalized()
		_bot_sidestep -= delta
		if is_on_wall() and _bot_sidestep <= 0:
			_bot_sidestep = randf_range(0.8, 2.0)
			_bot_side = [-1.0, 1.0].pick_random()
		if _bot_sidestep > 0:
			go = go.rotated(Vector3.UP, PI / 2 * _bot_side)
	else:
		_bot_strafe_left -= delta
		if _bot_strafe_left <= 0:
			_bot_strafe_left = randf_range(0.8, 1.8)
			_bot_side = [-1.0, 0.0, 1.0].pick_random()
		go = flat.normalized().rotated(Vector3.UP, PI / 2) * _bot_side * 0.6
	var local := Basis(Vector3.UP, rotation.y).inverse() * go
	_bot_move = Vector2(local.x, local.z)

	# Short bursts, after a moment to react, when the aim is close
	_bot_burst -= delta
	if _bot_burst < -0.45:
		_bot_burst = randf_range(0.35, 0.8)
	_bot_fire = in_sight and _bot_seen > 0.55 and _bot_burst > 0.0 \
			and absf(angle_difference(rotation.y, want_yaw)) < 0.12


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
	if not multiplayer.is_server() or multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return
	if dead or not game.is_playing():
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _server_last_fire < weapon_info["fire_interval"] * 0.7:
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
			target.server_take_damage(weapon_info["head_damage"] if head_hit else weapon_info["body_damage"], peer_id, head_hit)
			if not is_bot:
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
	if not _from_server() or controlled or Network.is_dedicated():
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
	peek = 0
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
	body_yaw = yaw
	net_body_yaw = yaw
	if controlled:
		peek = 0
		sprinting = false
		pitch = 0
		ammo = MAG_SIZE
		reloading = false
		aiming = false
		set_crouch(false)
