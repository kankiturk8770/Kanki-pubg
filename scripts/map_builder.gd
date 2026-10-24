extends RefCounted
## Builds the "Warehouse" TDM arena out of simple boxes.
## The map is point-symmetric: one half is built, then the same half
## is built again rotated 180 degrees, so both teams get the same cover.
## Blue (team 0) spawns at the -Z end, Red (team 1) at the +Z end.

const SIZE_X := 56.0
const SIZE_Z := 44.0
const WALL_H := 7.0

const C_FLOOR := Color(0.3, 0.3, 0.29)
const C_WALL := Color(0.62, 0.57, 0.48)
const C_CRATE := Color(0.55, 0.4, 0.22)
const C_CONCRETE := Color(0.55, 0.55, 0.53)
const C_CONTAINERS := [Color(0.18, 0.36, 0.55), Color(0.72, 0.36, 0.12), Color(0.24, 0.45, 0.25), Color(0.55, 0.15, 0.13)]


static func build(root: Node3D) -> void:
	_environment(root)

	_box(root, Vector3(0, -0.5, 0), Vector3(SIZE_X + 2, 1, SIZE_Z + 2), C_FLOOR)
	# Outer walls
	_box(root, Vector3(0, WALL_H / 2, -SIZE_Z / 2 - 0.5), Vector3(SIZE_X + 2, WALL_H, 1), C_WALL)
	_box(root, Vector3(0, WALL_H / 2, SIZE_Z / 2 + 0.5), Vector3(SIZE_X + 2, WALL_H, 1), C_WALL)
	_box(root, Vector3(-SIZE_X / 2 - 0.5, WALL_H / 2, 0), Vector3(1, WALL_H, SIZE_Z), C_WALL)
	_box(root, Vector3(SIZE_X / 2 + 0.5, WALL_H / 2, 0), Vector3(1, WALL_H, SIZE_Z), C_WALL)

	for i in 2:
		var half := Node3D.new()
		half.name = "Half%d" % i
		half.rotation.y = PI * i
		root.add_child(half)
		_build_half(half, i)

	# Middle: centre wall, painted line, and spawn zone markings
	_box(root, Vector3(0, 1.0, 0), Vector3(7, 2.0, 1.0), C_CONCRETE)
	_paint(root, Vector3(0, 0.01, 0), Vector3(SIZE_X, 0.02, 0.15), Color(0.9, 0.8, 0.2))
	_paint(root, Vector3(0, 0.01, -17.5), Vector3(22, 0.02, 4), Color(0.24, 0.42, 0.75, 0.6))
	_paint(root, Vector3(0, 0.01, 17.5), Vector3(22, 0.02, 4), Color(0.75, 0.25, 0.22, 0.6))


## Random spot inside the team's spawn zone (feet position).
static func spawn_point(team: int) -> Vector3:
	var p := Vector3(randf_range(-10.0, 10.0), 0.1, randf_range(-18.5, -16.5))
	return p if team == 0 else Vector3(-p.x, p.y, -p.z)


static func _build_half(h: Node3D, i: int) -> void:
	# Spawn cover
	_box(h, Vector3(-6, 0.6, -13), Vector3(4, 1.2, 0.6), C_CONCRETE)
	_box(h, Vector3(6, 0.6, -13), Vector3(4, 1.2, 0.6), C_CONCRETE)
	# Shipping containers
	_box(h, Vector3(-18, 1.3, -12), Vector3(2.5, 2.6, 7), C_CONTAINERS[i * 2])
	_box(h, Vector3(17, 1.3, -8), Vector3(7, 2.6, 2.5), C_CONTAINERS[1 + i * 2])
	_box(h, Vector3(-9, 1.3, -6), Vector3(6, 2.6, 2.5), C_CONTAINERS[(2 + i) % 4])
	_box(h, Vector3(12, 1.3, 2.5), Vector3(2.5, 2.6, 6), C_CONTAINERS[(3 + i) % 4])
	# Crates
	_box(h, Vector3(-3, 0.6, -8.5), Vector3(1.2, 1.2, 1.2), C_CRATE)
	_box(h, Vector3(-1.7, 0.6, -8.5), Vector3(1.2, 1.2, 1.2), C_CRATE)
	_box(h, Vector3(-2.35, 1.8, -8.5), Vector3(1.2, 1.2, 1.2), C_CRATE)
	_box(h, Vector3(9, 0.6, -14), Vector3(1.2, 1.2, 1.2), C_CRATE)
	_box(h, Vector3(4, 0.75, -3.5), Vector3(1.5, 1.5, 1.5), C_CRATE)
	_box(h, Vector3(-22, 0.6, -3), Vector3(1.2, 1.2, 1.2), C_CRATE)
	_box(h, Vector3(22, 0.6, -15), Vector3(1.2, 1.2, 1.2), C_CRATE)
	_box(h, Vector3(-5, 0.6, -1.5), Vector3(1.2, 1.2, 1.2), C_CRATE)
	# Pillars
	_box(h, Vector3(8, WALL_H / 2, -8), Vector3(1, WALL_H, 1), C_WALL)
	_box(h, Vector3(-14, WALL_H / 2, 3), Vector3(1, WALL_H, 1), C_WALL)
	# Raised platform with a ramp (high ground on the side lane)
	_box(h, Vector3(-24, 1.25, 4), Vector3(6, 2.5, 8), C_CONCRETE)
	var ramp_len := sqrt(6.0 * 6.0 + 2.5 * 2.5)
	var ramp := _box(h, Vector3(-24, 1.1, -3), Vector3(4, 0.4, ramp_len), C_CONCRETE.darkened(0.15))
	ramp.rotation.x = -atan2(2.5, 6.0)


static func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	box_mesh.material = mat
	mesh.mesh = box_mesh
	body.add_child(mesh)
	parent.add_child(body)
	return body


static func _paint(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	box_mesh.material = mat
	mesh.mesh = box_mesh
	mesh.position = pos
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)


static func _environment(root: Node3D) -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 0.9
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
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	root.add_child(world_env)
