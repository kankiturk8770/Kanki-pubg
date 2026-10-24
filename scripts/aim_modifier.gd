extends SkeletonModifier3D
## Bends the soldier's spine and chest after the animation plays:
##   pitch - up/down, so the rifle points where the player aims
##   lean  - sideways, for peeking left/right

var pitch := 0.0
var lean := 0.0
var _bones: Array[int] = []
var _pitch_axes: Array[Vector3] = []
var _lean_axes: Array[Vector3] = []


func _ready() -> void:
	var skeleton := get_skeleton()
	# Blender soldier: "spine"/"chest". Meshy skins: "Spine01"/"Spine02".
	var names := ["spine", "chest"] if skeleton.find_bone("spine") >= 0 else ["Spine01", "Spine02"]
	for bone_name in names:
		var bone := skeleton.find_bone(bone_name)
		if bone < 0:
			continue
		_bones.append(bone)
		if bone_name == "spine" or bone_name == "chest":
			# Bone X axis = left/right axis, bone Z axis = front/back axis.
			_pitch_axes.append(Vector3.RIGHT)
			_lean_axes.append(Vector3.BACK)
		else:
			# Other rigs: turn the model's left/right and front/back axes
			# into the bone's own axes (signs picked to bend the same way
			# as the Blender soldier).
			var to_bone := skeleton.get_bone_global_rest(bone).basis.inverse()
			_pitch_axes.append((to_bone * Vector3.RIGHT).normalized())
			_lean_axes.append((to_bone * Vector3.FORWARD).normalized())


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	# Each bone takes half of the angle.
	for i in _bones.size():
		var bend := Quaternion(_pitch_axes[i], -pitch * 0.5) * Quaternion(_lean_axes[i], lean * 0.5)
		skeleton.set_bone_pose_rotation(_bones[i], skeleton.get_bone_pose_rotation(_bones[i]) * bend)
