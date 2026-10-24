extends RefCounted
## Builds the "Warehouse" TDM arena.
## Props (containers, crates, barrels, barriers) are Meshy models made from
## real-looking reference photos (docs/ASSETS.md, tools/meshy/prepare_model.py
## sizes them in metres). Floor and walls use photo textures
## (assets/textures, tools/make_tiling_texture.py). Each prop also gets a
## simple box collider so bullets and players stop at it.
##
## The map is point-symmetric: one half is built, then the same half
## is built again rotated 180 degrees, so both teams get the same cover.
## Blue (team 0) spawns at the -Z end, Red (team 1) at the +Z end.

const SIZE_X := 56.0
const SIZE_Z := 44.0
const WALL_H := 7.0

const CONTAINER := preload("res://assets/props/container.glb")
## Container paint per index: null = the model's own blue
const CONTAINER_COLORS := [
	null,
	preload("res://assets/props/colors/container_orange.jpg"),
	preload("res://assets/props/colors/container_green.jpg"),
	preload("res://assets/props/colors/container_red.jpg"),
]
const CRATE := preload("res://assets/props/crate.glb")
const BARREL := preload("res://assets/props/barrel.glb")
const BARRIER := preload("res://assets/props/barrier.glb")
const PILLAR := preload("res://assets/props/pillar.glb")
const FLOOR_TEX := preload("res://assets/textures/concrete_floor.jpg")
const FLOOR_NORMAL := preload("res://assets/textures/concrete_floor_normal.png")
const WALL_TEX := preload("res://assets/textures/block_wall.jpg")
const WALL_NORMAL := preload("res://assets/textures/block_wall_normal.png")

## Prop sizes in metres (the models are made exactly this size)
const CONTAINER_SIZE := Vector3(6.06, 2.59, 2.44)
const CRATE_SIZE := Vector3(1.5, 1.0, 1.2)
const BARREL_SIZE := Vector3(0.6, 0.9, 0.6)
const BARRIER_SIZE := Vector3(2.0, 0.85, 0.62)

## False on the dedicated server: it only needs the colliders.
static var visual := true
static var _materials := {}


static func build(root: Node3D) -> void:
	visual = DisplayServer.get_name() != "headless"
	if visual:
		_environment(root)

	var floor_mat := _textured("floor", FLOOR_TEX, FLOOR_NORMAL, 1.0 / 3.5, Color(0.58, 0.57, 0.55))
	var wall_mat := _textured("wall", WALL_TEX, WALL_NORMAL, 1.0 / 3.2, Color(0.62, 0.6, 0.57))
	_box(root, Vector3(0, -0.5, 0), Vector3(SIZE_X + 2, 1, SIZE_Z + 2), floor_mat)
	for z in [-SIZE_Z / 2 - 0.5, SIZE_Z / 2 + 0.5]:
		_box(root, Vector3(0, WALL_H / 2, z), Vector3(SIZE_X + 2, WALL_H, 1), wall_mat)
	for x in [-SIZE_X / 2 - 0.5, SIZE_X / 2 + 0.5]:
		_box(root, Vector3(x, WALL_H / 2, 0), Vector3(1, WALL_H, SIZE_Z), wall_mat)

	for i in 2:
		var half := Node3D.new()
		half.name = "Half%d" % i
		half.rotation.y = PI * i
		root.add_child(half)
		_build_half(half, i)

	# Middle: concrete wall and worn painted lines
	_box(root, Vector3(0, 1.0, 0), Vector3(7, 2.0, 1.0), wall_mat)
	_paint(root, Vector3(0, 0.01, 0), Vector3(SIZE_X, 0.02, 0.15), _flat(Color(0.85, 0.7, 0.2, 0.55)))
	_paint(root, Vector3(0, 0.01, -17.5), Vector3(22, 0.02, 4), _flat(Color(0.24, 0.42, 0.75, 0.12)))
	_paint(root, Vector3(0, 0.01, 17.5), Vector3(22, 0.02, 4), _flat(Color(0.75, 0.25, 0.22, 0.12)))


## Random spot inside the team's spawn zone (feet position).
static func spawn_point(team: int) -> Vector3:
	var p := Vector3(randf_range(-10.0, 10.0), 0.1, randf_range(-18.5, -16.5))
	return p if team == 0 else Vector3(-p.x, p.y, -p.z)


static func _build_half(h: Node3D, i: int) -> void:
	# Spawn cover: concrete barriers
	for x in [-7.0, -5.0, 5.0, 7.0]:
		_prop(h, BARRIER, Vector3(x, 0, -13), 0.0, BARRIER_SIZE)
	# Shipping containers (one stacked on top for a high spot)
	_container(h, i * 2, Vector3(-18, 0, -12), PI / 2)
	_container(h, 1 + i * 2, Vector3(17, 0, -8), 0.0)
	_container(h, (2 + i) % 4, Vector3(-9, 0, -6), 0.0)
	_container(h, (3 + i) % 4, Vector3(12, 0, 2.5), PI / 2)
	_container(h, (1 + i) % 4, Vector3(17, CONTAINER_SIZE.y, -8), 0.0)
	# Crates
	_prop(h, CRATE, Vector3(-3.2, 0, -8.5), 0.0, CRATE_SIZE)
	_prop(h, CRATE, Vector3(-1.6, 0, -8.5), 0.1, CRATE_SIZE)
	_prop(h, CRATE, Vector3(-2.4, CRATE_SIZE.y, -8.5), -0.15, CRATE_SIZE)
	_prop(h, CRATE, Vector3(9, 0, -14), 0.3, CRATE_SIZE)
	_prop(h, CRATE, Vector3(4, 0, -3.5), 0.0, CRATE_SIZE * 1.25, 1.25)
	_prop(h, CRATE, Vector3(-22, 0, -3), 0.2, CRATE_SIZE)
	_prop(h, CRATE, Vector3(22, 0, -15), 0.0, CRATE_SIZE)
	_prop(h, CRATE, Vector3(-5, 0, -1.5), -0.25, CRATE_SIZE)
	# Barrels
	for p in [Vector3(20, 0, -3), Vector3(20.65, 0, -3.45), Vector3(20.2, 0, -2.3), Vector3(-25, 0, -17), Vector3(2.5, 0, -15.5)]:
		_prop(h, BARREL, p, randf() * TAU, BARREL_SIZE)
	# Steel pillars holding the roof
	_prop(h, PILLAR, Vector3(8, 0, -8), 0.0, Vector3(0.6, WALL_H, 0.6))
	_prop(h, PILLAR, Vector3(-14, 0, 3), 0.0, Vector3(0.6, WALL_H, 0.6))
	# Raised concrete platform with a ramp (high ground on the side lane)
	var concrete := _textured("block", FLOOR_TEX, FLOOR_NORMAL, 1.0 / 2.5, Color(0.6, 0.6, 0.58))
	_box(h, Vector3(-24, 1.25, 4), Vector3(6, 2.5, 8), concrete)
	var ramp_len := sqrt(6.0 * 6.0 + 2.5 * 2.5)
	var ramp := _box(h, Vector3(-24, 1.1, -3), Vector3(4, 0.4, ramp_len), concrete)
	ramp.rotation.x = -atan2(2.5, 6.0)
	_prop(h, BARRIER, Vector3(-24, 2.5, 7.6), 0.0, BARRIER_SIZE)


## A shipping container in one of the CONTAINER_COLORS.
static func _container(parent: Node3D, color: int, pos: Vector3, rot_y: float) -> void:
	var body := _prop(parent, CONTAINER, pos, rot_y, CONTAINER_SIZE)
	var paint: Texture2D = CONTAINER_COLORS[color]
	if visual and paint:
		for mi in body.find_children("*", "MeshInstance3D", true, false):
			var mat := (mi.mesh.surface_get_material(0) as StandardMaterial3D).duplicate() as StandardMaterial3D
			mat.albedo_texture = paint
			mi.set_surface_override_material(0, mat)


## A prop model plus a box collider. `size` is the collider (x, height, z)
## before rotation; the collider sits on `pos` (which is the prop's floor point).
static func _prop(parent: Node3D, scene: PackedScene, pos: Vector3, rot_y: float, size: Vector3, prop_scale := 1.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	shape.position.y = size.y / 2
	body.add_child(shape)
	if visual:
		var model := scene.instantiate() as Node3D
		model.scale = Vector3.ONE * prop_scale
		body.add_child(model)
	parent.add_child(body)
	return body


static func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	if visual:
		var mesh := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		box_mesh.size = size
		box_mesh.material = mat
		mesh.mesh = box_mesh
		body.add_child(mesh)
	parent.add_child(body)
	return body


static func _paint(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> void:
	if not visual:
		return
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	box_mesh.material = mat
	mesh.mesh = box_mesh
	mesh.position = pos
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)


## Photo material, mapped by world position so it never stretches.
static func _textured(key: String, albedo: Texture2D, normal: Texture2D, uv_scale: float, tint := Color.WHITE) -> Material:
	if not visual:
		return null
	if _materials.has(key):
		return _materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = albedo
	mat.albedo_color = tint
	mat.normal_enabled = true
	mat.normal_texture = normal
	mat.normal_scale = 0.8
	mat.roughness = 0.92
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * uv_scale
	_materials[key] = mat
	return mat


static func _flat(color: Color) -> Material:
	if not visual:
		return null
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat


static func _environment(root: Node3D) -> void:
	# Late afternoon sun: warm, low enough for long soft-edged shadows
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 35, 0)
	sun.light_energy = 1.0
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 60.0
	sun.add_to_group("sun")
	root.add_child(sun)

	# Hazy real-world sky instead of a bright cartoon blue
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.42, 0.55, 0.72)
	sky_mat.sky_horizon_color = Color(0.78, 0.76, 0.72)
	sky_mat.ground_horizon_color = Color(0.5, 0.48, 0.45)
	sky_mat.ground_bottom_color = Color(0.25, 0.24, 0.22)
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.9
	# A little dusty air, so far things fade like in real distance
	env.fog_enabled = true
	env.fog_light_color = Color(0.72, 0.7, 0.66)
	env.fog_density = 0.006
	env.fog_sky_affect = 0.3
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	root.add_child(world_env)
