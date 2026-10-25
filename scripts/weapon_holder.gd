extends Node3D
## Keeps a gun in the character's right hand. The Mixamo rifle animations
## hold an (invisible) rifle, so the gun is fixed to the right hand: where
## it sits is measured once from the "idle" pose (pistol grip in the right
## palm, handguard on the left palm), then it simply follows the hand.
## Every gun gets a red dot sight on top, high enough to see over the iron
## sights. While aiming down the sight (`ads`), the gun turns about the
## sight to point exactly where the player looks (`aim_basis`), so the red
## dot is where the bullets go; the camera sits at `eye_point`.
## Add it with setup() before playing any other animation.

const Weapons := preload("res://scripts/weapons.gd")

## End of the barrel, for muzzle flash, tracers and the shot sound.
var muzzle := Node3D.new()
## Gun relative to the right hand bone, and the left palm's spot under the
## handguard in the gun's frame (scripts/hand_grip.gd uses both).
var in_hand := Transform3D()
var support_point := Vector3.ZERO
## Aiming down the sight: 0..1, and where the gun should point then
## (world basis of the gun's frame: muzzle -X, top +Y)
var ads := 0.0
var aim_basis := Basis()
## Where the eye is when aiming down the sight (gun's frame)
var eye_point := Vector3.ZERO

## Red dot sight per gun: where it stands and how high its window is
static var _sight_cache := {}

var _skeleton: Skeleton3D
var _right := -1
var _left := -1
var _right_mid := -1   # middle finger roots: palm = halfway from the wrist
var _left_mid := -1
var _grip := Vector3.ZERO
var _support := Vector3.ZERO
var _model: Node3D


func setup(skeleton: Skeleton3D, weapon_id: String, anim: AnimationPlayer) -> void:
	_skeleton = skeleton
	_right = skeleton.find_bone("RightHand")
	_left = skeleton.find_bone("LeftHand")
	_right_mid = skeleton.find_bone("RightHandMiddle1")
	_left_mid = skeleton.find_bone("LeftHandMiddle1")
	var info := Weapons.get_info(weapon_id)
	var k: float = info["length"] / 1.9
	_model = (info["scene"] as PackedScene).instantiate() as Node3D
	_model.scale = Vector3.ONE * k
	add_child(_model)
	_grip = info["grip"] * k
	_support = info["support"] * k
	support_point = _support
	muzzle.position = info["muzzle"] * k
	add_child(muzzle)
	_add_red_dot(weapon_id)
	# Placed in world space (skeletons can be scaled)
	top_level = true
	skeleton.add_child(self)
	skeleton.skeleton_updated.connect(_follow)
	# Measure on the idle pose, whatever the caller plays next
	anim.play("idle")
	anim.seek(0.0, true)
	calibrate()


## Measures where the gun sits in the right hand, from the pose the
## skeleton has right now (call while a two-handed pose like "idle" plays).
func calibrate() -> void:
	# (not in the tree yet: measure in the skeleton's own space)
	var to_world := _skeleton.global_transform if _skeleton.is_inside_tree() else Transform3D()
	var right := to_world * _skeleton.get_bone_global_pose(_right)
	var right_palm := _palm(_right, _right_mid)
	var left_palm := _palm(_left, _left_mid)
	# Gun frame: e1 = grip -> support, e2 = "up" in the gun's side view
	var e1 := (_support - _grip).normalized()
	var e2 := e1.cross(Vector3.BACK).normalized()
	var gun_axes := Basis(e1, e2, e1.cross(e2))
	# Same frame in the world: right palm -> left palm, as upright as possible
	var f1 := (left_palm - right_palm).normalized()
	var f2 := (Vector3.UP - f1 * f1.dot(Vector3.UP)).normalized()
	var basis := Basis(f1, f2, f1.cross(f2)) * gun_axes.transposed()
	in_hand = right.orthonormalized().affine_inverse() * Transform3D(basis, right_palm - basis * _grip)


func _palm(hand: int, middle: int) -> Vector3:
	var to_world := _skeleton.global_transform if _skeleton.is_inside_tree() else Transform3D()
	var wrist := to_world * _skeleton.get_bone_global_pose(hand).origin
	if middle < 0:
		return wrist
	return wrist.lerp(to_world * _skeleton.get_bone_global_pose(middle).origin, 0.55)


## Where the gun is for a right hand (world) transform: in the hand, or
## turned about the sight to point where the player aims.
func gun_transform(right_hand: Transform3D) -> Transform3D:
	var held := right_hand.orthonormalized() * in_hand
	if ads <= 0.001:
		return held
	var eye := held * eye_point
	var aimed := Transform3D(aim_basis, eye - aim_basis * eye_point)
	return held.interpolate_with(aimed, ads)


func _follow() -> void:
	if not is_inside_tree():
		return
	global_transform = gun_transform(_skeleton.global_transform * _skeleton.get_bone_global_pose(_right))


## A red dot sight on the gun's top, above the receiver, its window high
## enough to look over the iron sights.
func _add_red_dot(weapon_id: String) -> void:
	if not _sight_cache.has(weapon_id):
		var mount_x := _grip.x - 0.13
		var mount_top := -INF
		var clear := -INF
		for mi in _model.find_children("*", "MeshInstance3D", true, false):
			var xf := _model.transform
			var chain: Array[Node3D] = []
			var n: Node = mi
			while n != _model:
				chain.push_front(n)
				n = n.get_parent()
			for node in chain:
				xf = xf * node.transform
			for v in mi.mesh.get_faces():
				var p: Vector3 = xf * v
				if absf(p.z) > 0.02:
					continue
				if absf(p.x - mount_x) < 0.02 and absf(p.z) < 0.015:
					mount_top = maxf(mount_top, p.y)
				if p.x > muzzle.position.x + 0.05 and p.x < mount_x + 0.25:
					clear = maxf(clear, p.y)
		_sight_cache[weapon_id] = {"x": mount_x, "base": mount_top, "axis": maxf(clear + 0.012, mount_top + 0.035)}
	var fit: Dictionary = _sight_cache[weapon_id]
	var x: float = fit["x"]
	var base: float = fit["base"]
	var axis: float = fit["axis"]
	eye_point = Vector3(x + 0.21, axis, 0.0)

	var sight := Node3D.new()
	sight.name = "RedDot"
	add_child(sight)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.09, 0.09, 0.1)
	metal.metallic = 0.6
	metal.roughness = 0.45
	var bottom := axis - 0.018
	var parts := [
		[Vector3(0.026, bottom - base, 0.012), Vector3(x, (base + bottom) / 2, 0)],  # riser
		[Vector3(0.014, 0.0035, 0.04), Vector3(x, axis + 0.0182, 0)],               # window: top
		[Vector3(0.014, 0.0035, 0.04), Vector3(x, bottom, 0)],                      # bottom
		[Vector3(0.014, 0.036, 0.0035), Vector3(x, axis, 0.0183)],                  # sides
		[Vector3(0.014, 0.036, 0.0035), Vector3(x, axis, -0.0183)],
	]
	for part in parts:
		var box := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = part[0]
		mesh.material = metal
		box.mesh = mesh
		box.position = part[1]
		sight.add_child(box)
	var lens := MeshInstance3D.new()
	var glass := QuadMesh.new()
	glass.size = Vector2(0.034, 0.034)
	var tint := StandardMaterial3D.new()
	tint.albedo_color = Color(0.55, 0.85, 1.0, 0.12)
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tint.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass.material = tint
	lens.mesh = glass
	lens.position = Vector3(x - 0.005, axis, 0)
	lens.rotation.y = PI / 2
	lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sight.add_child(lens)
	var dot := MeshInstance3D.new()
	var bead := SphereMesh.new()
	bead.radius = 0.0016
	bead.height = 0.0032
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(1.0, 0.12, 0.08)
	red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bead.material = red
	dot.mesh = bead
	dot.position = Vector3(x - 0.004, axis, 0)
	dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sight.add_child(dot)
