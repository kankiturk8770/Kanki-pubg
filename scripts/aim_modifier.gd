extends SkeletonModifier3D
## Bends the soldier's spine and chest up/down after the animation plays,
## so the rifle points where the player is aiming.

var pitch := 0.0
var _bones: Array[int] = []


func _ready() -> void:
	var skeleton := get_skeleton()
	for bone in ["spine", "chest"]:
		_bones.append(skeleton.find_bone(bone))


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	# Each bone takes half of the angle. Bone X axis = left/right axis.
	var bend := Quaternion(Vector3.RIGHT, -pitch * 0.5)
	for bone in _bones:
		if bone >= 0:
			skeleton.set_bone_pose_rotation(bone, skeleton.get_bone_pose_rotation(bone) * bend)
