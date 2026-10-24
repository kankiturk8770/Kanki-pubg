extends RefCounted
## Builds the "Warehouse" TDM arena.
## Props (containers, crates, barrels...) come from assets/props/*.glb,
## made by tools/blender/make_props.py. Each prop also gets a simple box
## collider so bullets and players stop at it.
##
## The map is point-symmetric: one half is built, then the same half
## is built again rotated 180 degrees, so both teams get the same cover.
## Blue (team 0) spawns at the -Z end, Red (team 1) at the +Z end.

const SIZE_X := 56.0
const SIZE_Z := 44.0
const WALL_H := 7.0

const CONTAINERS := [
	preload("res://assets/props/container_blue.glb"),
	preload("res://assets/props/container_orange.glb"),
	preload("res://assets/props/container_green.glb"),
	preload("res://assets/props/container_red.glb"),
]
const CRATE := preload("res://assets/props/crate.glb")
const BARREL := preload("res://assets/props/barrel.glb")
const BARRIER := preload("res://assets/props/barrier.glb")
const PILLAR := preload("res://assets/props/pillar.glb")

const CONTAINER_SIZE := Vector3(6.06, 2.59, 2.44)

## False on the dedicated server: it only needs the colliders.
static var visual := true
static var _materials := {}


static func build(root: Node3D) -> void:
	visual = DisplayServer.get_name() != "headless"
	if visual:
		_environment(root)

	var floor_mat := _concrete("floor", Color(0.36, 0.36, 0.35), 0.18)
	var wall_mat := _concrete("wall", Color(0.5, 0.49, 0.46), 0.15)
	_box(root, Vector3(0, -0.5, 0), Vector3(SIZE_X + 2, 1, SIZE_Z + 2), floor_mat)
	# Outer walls with a darker skirting at the bottom
	var skirt := _concrete("skirt", Color(0.3, 0.3, 0.29), 0.3)
	for z in [-SIZE_Z / 2 - 0.5, SIZE_Z / 2 + 0.5]:
		_box(root, Vector3(0, WALL_H / 2, z), Vector3(SIZE_X + 2, WALL_H, 1), wall_mat)
		_paint(root, Vector3(0, 0.6, z - signf(z) * 0.52), Vector3(SIZE_X, 1.2, 0.02), skirt)
	for x in [-SIZE_X / 2 - 0.5, SIZE_X / 2 + 0.5]:
		_box(root, Vector3(x, WALL_H / 2, 0), Vector3(1, WALL_H, SIZE_Z), wall_mat)
		_paint(root, Vector3(x - signf(x) * 0.52, 0.6, 0), Vector3(0.02, 1.2, SIZE_Z), skirt)

	for i in 2:
		var half := Node3D.new()
		half.name = "Half%d" % i
		half.rotation.y = PI * i
		root.add_child(half)
		_build_half(half, i)

	# Middle: concrete wall and painted lines
	_box(root, Vector3(0, 1.0, 0), Vector3(7, 2.0, 1.0), _concrete("block", Color(0.55, 0.55, 0.52), 0.4))
	_paint(root, Vector3(0, 0.01, 0), Vector3(SIZE_X, 0.02, 0.15), _flat(Color(0.9, 0.75, 0.15)))
	_paint(root, Vector3(0, 0.01, -17.5), Vector3(22, 0.02, 4), _flat(Color(0.24, 0.42, 0.75, 0.22)))
	_paint(root, Vector3(0, 0.01, 17.5), Vector3(22, 0.02, 4), _flat(Color(0.75, 0.25, 0.22, 0.22)))


## Random spot inside the team's spawn zone (feet position).
static func spawn_point(team: int) -> Vector3:
	var p := Vector3(randf_range(-10.0, 10.0), 0.1, randf_range(-18.5, -16.5))
	return p if team == 0 else Vector3(-p.x, p.y, -p.z)


static func _build_half(h: Node3D, i: int) -> void:
	# Spawn cover: concrete barriers
	for x in [-7.0, -5.0, 5.0, 7.0]:
		_prop(h, BARRIER, Vector3(x, 0, -13), 0.0, Vector3(2.0, 0.8, 0.6))
	# Shipping containers (one stacked on top for a high spot)
	_prop(h, CONTAINERS[i * 2], Vector3(-18, 0, -12), PI / 2, CONTAINER_SIZE)
	_prop(h, CONTAINERS[1 + i * 2], Vector3(17, 0, -8), 0.0, CONTAINER_SIZE)
	_prop(h, CONTAINERS[(2 + i) % 4], Vector3(-9, 0, -6), 0.0, CONTAINER_SIZE)
	_prop(h, CONTAINERS[(3 + i) % 4], Vector3(12, 0, 2.5), PI / 2, CONTAINER_SIZE)
	_prop(h, CONTAINERS[(1 + i) % 4], Vector3(17, CONTAINER_SIZE.y, -8), 0.0, CONTAINER_SIZE)
	# Crates
	_prop(h, CRATE, Vector3(-3, 0, -8.5), 0.0, Vector3.ONE * 1.2)
	_prop(h, CRATE, Vector3(-1.7, 0, -8.5), 0.1, Vector3.ONE * 1.2)
	_prop(h, CRATE, Vector3(-2.35, 1.2, -8.5), -0.15, Vector3.ONE * 1.2)
	_prop(h, CRATE, Vector3(9, 0, -14), 0.3, Vector3.ONE * 1.2)
	_prop(h, CRATE, Vector3(4, 0, -3.5), 0.0, Vector3.ONE * 1.5, 1.25)
	_prop(h, CRATE, Vector3(-22, 0, -3), 0.2, Vector3.ONE * 1.2)
	_prop(h, CRATE, Vector3(22, 0, -15), 0.0, Vector3.ONE * 1.2)
	_prop(h, CRATE, Vector3(-5, 0, -1.5), -0.25, Vector3.ONE * 1.2)
	# Barrels
	for p in [Vector3(20, 0, -3), Vector3(20.65, 0, -3.45), Vector3(20.2, 0, -2.3), Vector3(-25, 0, -17), Vector3(2.5, 0, -15.5)]:
		_prop(h, BARREL, p, randf() * TAU, Vector3(0.6, 0.9, 0.6))
	# Steel pillars holding the roof
	_prop(h, PILLAR, Vector3(8, 0, -8), 0.0, Vector3(0.6, WALL_H, 0.6))
	_prop(h, PILLAR, Vector3(-14, 0, 3), 0.0, Vector3(0.6, WALL_H, 0.6))
	# Raised concrete platform with a ramp (high ground on the side lane)
	var concrete := _concrete("block", Color(0.55, 0.55, 0.52), 0.4)
	_box(h, Vector3(-24, 1.25, 4), Vector3(6, 2.5, 8), concrete)
	var ramp_len := sqrt(6.0 * 6.0 + 2.5 * 2.5)
	var ramp := _box(h, Vector3(-24, 1.1, -3), Vector3(4, 0.4, ramp_len), concrete)
	ramp.rotation.x = -atan2(2.5, 6.0)
	_prop(h, BARRIER, Vector3(-24, 2.5, 7.6), 0.0, Vector3(2.0, 0.8, 0.6))


## A prop model plus a box collider. `size` is the collider (x, height, z)
## before rotation; the collider sits on `pos` (which is the prop's floor point).
static func _prop(parent: Node3D, scene: PackedScene, pos: Vector3, rot_y: float, size: Vector3, prop_scale := 1.0) -> void:
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


## Concrete-like material from generated noise (no image files needed).
static func _concrete(key: String, color: Color, uv_scale: float) -> Material:
	if not visual:
		return null
	if _materials.has(key):
		return _materials[key]
	var noise := FastNoiseLite.new()
	noise.seed = key.hash()
	noise.frequency = 0.05
	noise.fractal_octaves = 5
	var ramp := Gradient.new()
	ramp.set_color(0, color.darkened(0.12))
	ramp.set_color(1, color.lightened(0.05))
	var albedo := NoiseTexture2D.new()
	albedo.noise = noise
	albedo.seamless = true
	albedo.color_ramp = ramp
	var bump := NoiseTexture2D.new()
	bump.noise = noise
	bump.seamless = true
	bump.as_normal_map = true
	bump.bump_strength = 1.5
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = albedo
	mat.normal_enabled = true
	mat.normal_texture = bump
	mat.roughness = 0.95
	mat.uv1_triplanar = true
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
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	root.add_child(sun)

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.35, 0.55, 0.85)
	sky_mat.sky_horizon_color = Color(0.75, 0.8, 0.85)
	sky_mat.ground_horizon_color = Color(0.6, 0.6, 0.6)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.65, 0.75)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	root.add_child(world_env)
