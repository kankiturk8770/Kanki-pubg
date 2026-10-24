extends Node3D
## Keeps a gun in the character's hands: the pistol grip sits in the right
## hand and the barrel points at the left hand, whatever the animation does.
## Add it as a child of the Skeleton3D; it moves after every pose update.

const Weapons := preload("res://scripts/weapons.gd")

## End of the barrel, for muzzle flash, tracers and the shot sound.
var muzzle := Node3D.new()

var _skeleton: Skeleton3D
var _right := -1
var _left := -1
var _grip := Vector3.ZERO
var _model: Node3D


func setup(skeleton: Skeleton3D, weapon_id: String) -> void:
	_skeleton = skeleton
	_right = skeleton.find_bone("RightHand")
	_left = skeleton.find_bone("LeftHand")
	var info := Weapons.get_info(weapon_id)
	var k: float = info["length"] / 1.9
	_model = (info["scene"] as PackedScene).instantiate() as Node3D
	_model.scale = Vector3.ONE * k
	add_child(_model)
	_grip = info["grip"] * k
	muzzle.position = info["muzzle"] * k
	add_child(muzzle)
	# Placed in world space: Meshy skeletons are scaled (bones in centimetres)
	top_level = true
	skeleton.add_child(self)
	skeleton.skeleton_updated.connect(_follow)


func _follow() -> void:
	if not is_inside_tree():
		return
	var to_world := _skeleton.global_transform
	var right := to_world * _skeleton.get_bone_global_pose(_right).origin
	var left := to_world * _skeleton.get_bone_global_pose(_left).origin
	# The barrel (model -X) points from the right hand to the left hand
	var to_left := left - right
	if to_left.length() < 0.05:
		return
	var x := -to_left.normalized()
	var y := (Vector3.UP - x * x.dot(Vector3.UP)).normalized()
	var basis := Basis(x, y, x.cross(y))
	global_transform = Transform3D(basis, right - basis * _grip)
