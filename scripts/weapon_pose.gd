extends SkeletonModifier3D
## Upper-body layer: after the body animation plays, the spine, arms, hands,
## fingers (and head) can take their pose from another clip instead, e.g.
## the legs run while the upper body reloads or aims. The player sets
## `clip` + `time` every frame; `influence` blends it in or out.
##
## Mixamo skeleton (tools/mixamo): bone names without the "mixamorig:" prefix.

const ROOT_BONE := "Spine"  # this bone and everything under it

var clip: Animation
var time := 0.0
var _bones: Array[int] = []
var _tracks: Array[int] = []   # rotation track of each bone in `clip`, -1 = none
var _for_clip: Animation


## Call after adding it as a child of the Skeleton3D.
func setup() -> void:
	var skeleton := get_parent() as Skeleton3D
	var root := skeleton.find_bone(ROOT_BONE)
	for bone in skeleton.get_bone_count():
		var b := bone
		while b >= 0 and b != root:
			b = skeleton.get_bone_parent(b)
		if b == root:
			_bones.append(bone)


func _map_tracks() -> void:
	var skeleton := get_skeleton()
	_tracks.clear()
	var by_bone := {}
	for track in clip.get_track_count():
		if clip.track_get_type(track) == Animation.TYPE_ROTATION_3D:
			by_bone[skeleton.find_bone(clip.track_get_path(track).get_concatenated_subnames())] = track
	for bone in _bones:
		_tracks.append(by_bone.get(bone, -1))
	_for_clip = clip


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null or clip == null:
		return
	if clip != _for_clip:
		_map_tracks()
	var t := fposmod(time, clip.length) if clip.loop_mode != Animation.LOOP_NONE else clampf(time, 0, clip.length)
	for i in _bones.size():
		if _tracks[i] >= 0:
			skeleton.set_bone_pose_rotation(_bones[i], clip.rotation_track_interpolate(_tracks[i], t))
