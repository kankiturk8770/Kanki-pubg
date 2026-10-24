extends Node3D
## Keeps a gun in the character's right hand. The Mixamo rifle animations
## hold an (invisible) rifle, so the gun is fixed to the right hand: where
## it sits is measured once from the "idle" pose (pistol grip in the right
## palm, handguard on the left palm), then it simply follows the hand.
## Add it with setup() before playing any other animation.

const Weapons := preload("res://scripts/weapons.gd")

## End of the barrel, for muzzle flash, tracers and the shot sound.
var muzzle := Node3D.new()

var _skeleton: Skeleton3D
var _right := -1
var _left := -1
var _right_mid := -1   # middle finger roots: palm = halfway from the wrist
var _left_mid := -1
var _grip := Vector3.ZERO
var _support := Vector3.ZERO
var _model: Node3D
var _in_hand := Transform3D()   # gun relative to the right hand


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
	muzzle.position = info["muzzle"] * k
	add_child(muzzle)
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
	_in_hand = right.orthonormalized().affine_inverse() * Transform3D(basis, right_palm - basis * _grip)


func _palm(hand: int, middle: int) -> Vector3:
	var to_world := _skeleton.global_transform if _skeleton.is_inside_tree() else Transform3D()
	var wrist := to_world * _skeleton.get_bone_global_pose(hand).origin
	if middle < 0:
		return wrist
	return wrist.lerp(to_world * _skeleton.get_bone_global_pose(middle).origin, 0.55)


func _follow() -> void:
	if not is_inside_tree():
		return
	var right := _skeleton.global_transform * _skeleton.get_bone_global_pose(_right)
	global_transform = right.orthonormalized() * _in_hand
