extends SkeletonModifier3D
## Meshy skins: the auto-rig keeps the arms a little away from the body and
## the palms turned forward in every clip. This brings the upper arms closer
## to the body and turns the palms towards the legs, after the animation plays.
## Only meant for standing still: player.gd fades `influence` out otherwise.

const ARM_DOWN := deg_to_rad(7.0)
const PALM_IN := deg_to_rad(55.0)

var _sides: Array = []  # [upper arm bone, forearm bone, side sign]


func _ready() -> void:
	var skeleton := get_skeleton()
	for side in [["LeftArm", "LeftForeArm", 1.0], ["RightArm", "RightForeArm", -1.0]]:
		var arm := skeleton.find_bone(side[0])
		var fore := skeleton.find_bone(side[1])
		if arm >= 0 and fore >= 0:
			_sides.append([arm, fore, side[2]])


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	for side in _sides:
		var sign: float = side[2]
		# Upper arm: turn around the model's front/back axis, towards the body.
		_turn(skeleton, side[0], Vector3.BACK, -ARM_DOWN * sign)
		# Forearm: twist around its own length, palm towards the leg.
		var fore_global := skeleton.get_bone_global_pose(side[1]).basis
		_turn(skeleton, side[1], fore_global.y.normalized(), PALM_IN * sign)


## Rotates a bone by `angle` around `axis` given in skeleton space.
func _turn(skeleton: Skeleton3D, bone: int, axis: Vector3, angle: float) -> void:
	var to_bone := skeleton.get_bone_global_pose(bone).basis.orthonormalized().inverse()
	var local_axis := (to_bone * axis).normalized()
	skeleton.set_bone_pose_rotation(bone, skeleton.get_bone_pose_rotation(bone) * Quaternion(local_axis, angle))
