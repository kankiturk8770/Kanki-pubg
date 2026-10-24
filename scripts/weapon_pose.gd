extends SkeletonModifier3D
## Holds the rifle: after the body animation (idle, run, crouch...) plays,
## the upper body (spine, head, arms) is set to the shooting pose taken from
## the "rifle_aim" clip. When not aiming the arms are lowered (low ready);
## `aim` (0..1) raises the rifle to the shoulder.
## Turn it off (influence 0) when a clip should move the arms itself (death).

const UPPER_BODY := ["Spine", "Spine01", "Spine02", "neck", "Head",
		"LeftShoulder", "LeftArm", "LeftForeArm", "LeftHand",
		"RightShoulder", "RightArm", "RightForeArm", "RightHand"]
const POSE_CLIP := "rifle_aim"
const POSE_TIME := 1.5
const LOWER := deg_to_rad(28.0)  # how far the arms drop when not aiming

var aim := 0.0
## true = neck and head keep the body animation (they look ahead instead of
## down the gun); set before setup()
var head_from_animation := false
var _bones: Array[int] = []
var _pose: Array[Quaternion] = []
var _arms: Array[int] = []


## Call after adding it as a child of the Skeleton3D.
func setup(anim: AnimationPlayer) -> void:
	var skeleton := get_parent() as Skeleton3D
	for bone_name in UPPER_BODY:
		if head_from_animation and bone_name in ["neck", "Head"]:
			continue
		_bones.append(skeleton.find_bone(bone_name))
	_arms = [skeleton.find_bone("LeftArm"), skeleton.find_bone("RightArm")]
	var clip := anim.get_animation(POSE_CLIP)
	for bone in _bones:
		_pose.append(skeleton.get_bone_pose_rotation(bone) if bone >= 0 else Quaternion())
	for track in clip.get_track_count():
		if clip.track_get_type(track) != Animation.TYPE_ROTATION_3D:
			continue
		var i := _bones.find(skeleton.find_bone(clip.track_get_path(track).get_concatenated_subnames()))
		if i >= 0:
			_pose[i] = clip.rotation_track_interpolate(track, POSE_TIME)


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null or _pose.is_empty():
		return
	for i in _bones.size():
		if _bones[i] >= 0:
			skeleton.set_bone_pose_rotation(_bones[i], _pose[i])
	# Low ready: turn both upper arms down around the body's left-right axis
	var lower := LOWER * (1.0 - aim)
	if lower > 0.001:
		for bone in _arms:
			var to_bone := skeleton.get_bone_global_pose(bone).basis.orthonormalized().inverse()
			var axis := (to_bone * Vector3.RIGHT).normalized()
			skeleton.set_bone_pose_rotation(bone, skeleton.get_bone_pose_rotation(bone) * Quaternion(axis, lower))
