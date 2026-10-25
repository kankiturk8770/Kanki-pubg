extends SkeletonModifier3D
## Real grip on the gun, done here instead of taken from the animations
## (Mixamo's finger motion bends our finger bones sideways):
## 1. Left hand IK: the left hand holds the handguard every frame, wherever
##    the right hand and the gun are (off while reloading and dying).
## 2. Fingers: every joint bends around its real bending axis (worked out
##    from the hand's shape in the rest pose), as far as needed to rest on
##    the gun's surface.
## How far each finger bends, where the left hand holds, where the gun sits
## in the right palm and how the right wrist turns to line the hand up with
## the grip are fitted to the real gun and hand meshes by tools/fit_grips.gd
## (scripts/grip_data.gd).
## Add it as the LAST child of the Skeleton3D (after the other modifiers),
## then call setup() with the character's WeaponHolder.

const GripData := preload("res://scripts/grip_data.gd")

const FINGERS := ["Thumb", "Index", "Middle", "Ring", "Pinky"]
## Bend of joints 1-3 in degrees, for a character/gun pair that has not been
## fitted yet. Right hand: pistol grip, index finger by the trigger.
const DEFAULT_RIGHT := {
	"Thumb": [20.0, 25.0, 20.0], "Index": [30.0, 40.0, 25.0], "Middle": [70.0, 95.0, 50.0],
	"Ring": [75.0, 95.0, 50.0], "Pinky": [80.0, 90.0, 45.0],
}
## Left hand: round the handguard.
const DEFAULT_LEFT := {
	"Thumb": [10.0, 15.0, 10.0], "Index": [45.0, 60.0, 35.0], "Middle": [50.0, 65.0, 40.0],
	"Ring": [55.0, 65.0, 40.0], "Pinky": [60.0, 65.0, 40.0],
}
## Share of the hand's twist taken by the forearm, so the wrist does not
## wring like a towel.
const FOREARM_TWIST := 0.6
## The model's fingers are spread apart; holding something they lie side
## by side: share of each finger's spread taken away at its knuckle.
const CLOSE_SPREAD := 0.85

## 1 = left hand on the handguard, 0 = left hand follows the animation.
var left_ik := 1.0

var _holder: Node3D
var _joints: Array = []
var _angles := PackedFloat32Array()   # radians, one per joint
var _left_in_gun := Transform3D()     # left hand bone in the gun's frame
var _wrist := Quaternion()            # right hand turned at the wrist to fit the grip
var _arm := -1
var _forearm := -1
var _hand := -1
var _right_hand := -1
var _wrist_rest := Basis()            # hand relative to forearm in the rest pose


## Every finger joint: bone, its rest rotation and its bending axis in the
## bone's own space (positive angle = towards the palm). Fingers bend round
## the axis across the palm; the thumb closes towards the middle of the palm.
## Knuckles also turn in the palm's plane (`spread`, round `spread_axis`) so
## the fingers lie side by side.
static func finger_joints(skeleton: Skeleton3D) -> Array:
	var joints := []
	for side in ["Left", "Right"]:
		var frame := hand_frame(skeleton, side)
		var normal: Vector3 = frame["global_normal"]
		var palm: Vector3 = frame["global_centre"] + normal * 0.04
		var flat := func(finger: String) -> Vector3:
			var a := skeleton.get_bone_global_rest(skeleton.find_bone("%sHand%s1" % [side, finger])).origin
			var b := skeleton.get_bone_global_rest(skeleton.find_bone("%sHand%s2" % [side, finger])).origin
			return ((b - a) - normal * (b - a).dot(normal)).normalized()
		var middle: Vector3 = flat.call("Middle")
		for finger in FINGERS:
			for j in 3:
				var bone := skeleton.find_bone("%sHand%s%d" % [side, finger, j + 1])
				var tip := skeleton.find_bone("%sHand%s%d" % [side, finger, j + 2])
				if bone < 0 or tip < 0:
					continue
				var rest := skeleton.get_bone_global_rest(bone)
				var along := (skeleton.get_bone_global_rest(tip).origin - rest.origin).normalized()
				var axis: Vector3 = along.cross(normal)
				if finger == "Thumb":
					axis = along.cross((palm - rest.origin).normalized())
				var to_bone := rest.basis.orthonormalized().inverse()
				var spread := 0.0
				if j == 0 and finger != "Thumb":
					spread = (flat.call(finger) as Vector3).signed_angle_to(middle, normal) * CLOSE_SPREAD
				joints.append({
					"bone": bone, "side": side, "finger": finger, "joint": j,
					"rest": skeleton.get_bone_rest(bone).basis.get_rotation_quaternion(),
					"axis": (to_bone * axis.normalized()).normalized(),
					"spread_axis": (to_bone * normal).normalized(), "spread": spread,
				})
	return joints


## A finger joint's pose rotation, bent by `angle` (radians).
static func joint_rotation(j: Dictionary, angle: float) -> Quaternion:
	return (j["rest"] as Quaternion) * Quaternion(j["spread_axis"], j["spread"]) * Quaternion(j["axis"], angle)


## The palm, from the rest pose (palms face down in the T-pose):
## centre = middle of the palm on the bone line, axes = (towards the fingers,
## out of the palm, sideways), both in the hand bone's space; plus the same
## centre and palm direction in skeleton space.
static func hand_frame(skeleton: Skeleton3D, side: String) -> Dictionary:
	var at := func(n: String) -> Vector3:
		return skeleton.get_bone_global_rest(skeleton.find_bone(side + n)).origin
	var wrist: Vector3 = at.call("Hand")
	var knuckle: Vector3 = at.call("HandMiddle1")
	var along := (knuckle - wrist).normalized()
	var normal := along.cross(at.call("HandIndex1") - at.call("HandPinky1")).normalized()
	if normal.dot(Vector3.DOWN) < 0.0:
		normal = -normal
	normal = (normal - along * along.dot(normal)).normalized()
	var hand := skeleton.get_bone_global_rest(skeleton.find_bone(side + "Hand")).orthonormalized()
	var a := hand.basis.inverse() * along
	var n := hand.basis.inverse() * normal
	return {
		"centre": hand.affine_inverse() * wrist.lerp(knuckle, 0.5), "axes": Basis(a, n, a.cross(n)),
		"global_centre": wrist.lerp(knuckle, 0.5), "global_normal": normal,
	}


func setup(holder: Node3D, character: int, weapon_id: String) -> void:
	_holder = holder
	var skeleton := get_parent() as Skeleton3D
	_arm = skeleton.find_bone("LeftArm")
	_forearm = skeleton.find_bone("LeftForeArm")
	_hand = skeleton.find_bone("LeftHand")
	_right_hand = skeleton.find_bone("RightHand")
	_wrist_rest = skeleton.get_bone_global_rest(_forearm).basis.orthonormalized().inverse() \
			* skeleton.get_bone_global_rest(_hand).basis.orthonormalized()
	_joints = finger_joints(skeleton)
	var fit: Dictionary = GripData.FITS.get("%d/%s" % [character, weapon_id], {})
	if fit and (fit["curl"] as Array).size() == _joints.size():
		# The gun stays where the animation holds it; the hand turns round it
		_wrist = fit.get("wrist", Quaternion())
		holder.in_hand = Transform3D(Basis(_wrist.inverse()), Vector3.ZERO) * holder.in_hand \
				* Transform3D(Basis(), fit["shift"])
		_left_in_gun = fit["left"]
		for deg in fit["curl"]:
			_angles.append(deg_to_rad(deg))
	else:
		push_warning("No fitted grip for %d/%s: run tools/fit_grips.gd" % [character, weapon_id])
		_left_in_gun = _default_left(skeleton)
		for j in _joints:
			var table: Dictionary = DEFAULT_RIGHT if j["side"] == "Right" else DEFAULT_LEFT
			_angles.append(deg_to_rad(table[j["finger"]][j["joint"]]))


## Unfitted pair: palm up under the handguard, fingers round its right side.
func _default_left(skeleton: Skeleton3D) -> Transform3D:
	var frame := hand_frame(skeleton, "Left")
	var f := Vector3(-0.3, 0.0, -0.85).normalized()   # gun frame: muzzle -X, top +Y, right -Z
	var basis := Basis(f, Vector3.UP, f.cross(Vector3.UP)) * (frame["axes"] as Basis).inverse()
	var palm: Vector3 = _holder.support_point + Vector3.DOWN * 0.03
	return Transform3D(basis, palm - basis * (frame["centre"] as Vector3))


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null or _holder == null or _joints.is_empty():
		return
	skeleton.set_bone_pose_rotation(_right_hand, skeleton.get_bone_pose_rotation(_right_hand) * _wrist)
	if left_ik > 0.01:
		_left_hand_to_gun(skeleton)
	for i in _joints.size():
		skeleton.set_bone_pose_rotation(_joints[i]["bone"], joint_rotation(_joints[i], _angles[i]))


func _left_hand_to_gun(skeleton: Skeleton3D) -> void:
	# Where the gun is (it follows the right hand), worked out in world space
	# like WeaponHolder does, then brought into the skeleton's space
	var to_world := skeleton.global_transform if skeleton.is_inside_tree() else Transform3D()
	var right := (to_world * skeleton.get_bone_global_pose(_right_hand)).orthonormalized()
	var want: Transform3D = to_world.affine_inverse() * (_holder.gun_transform(right) * _left_in_gun)

	var arm := skeleton.get_bone_global_pose(_arm)
	var forearm := skeleton.get_bone_global_pose(_forearm)
	var hand := skeleton.get_bone_global_pose(_hand)
	var target := hand.origin.lerp(want.origin, left_ik)
	var target_basis := hand.basis.orthonormalized().slerp(want.basis.orthonormalized(), left_ik)

	# Two-bone IK, the elbow stays on the side the animation put it
	var s := arm.origin
	var e := forearm.origin
	var w := hand.origin
	var upper := s.distance_to(e)
	var lower := e.distance_to(w)
	var to_target := target - s
	var d := clampf(to_target.length(), absf(upper - lower) + 0.001, upper + lower - 0.001)
	var dir := to_target.normalized()
	var bend := (e - s) - dir * (e - s).dot(dir)
	if bend.length() < 0.0001:
		bend = Vector3.DOWN - dir * dir.dot(Vector3.DOWN)
	bend = bend.normalized()
	var cos_a := clampf((upper * upper + d * d - lower * lower) / (2.0 * upper * d), -1.0, 1.0)
	var elbow := s + dir * upper * cos_a + bend * upper * sqrt(1.0 - cos_a * cos_a)
	var wrist := s + dir * d

	var q1 := Quaternion((e - s).normalized(), (elbow - s).normalized())
	arm.basis = Basis(q1) * arm.basis
	skeleton.set_bone_global_pose(_arm, arm)
	var moved_wrist := elbow + Basis(q1) * (w - e)
	var q2 := Quaternion((moved_wrist - elbow).normalized(), (wrist - elbow).normalized())
	var forearm_basis := Basis(q2) * Basis(q1) * forearm.basis
	# Turn the forearm with the hand (most of the twist), not just the wrist
	var axis := (wrist - elbow).normalized()
	var turn := Quaternion(target_basis * (forearm_basis.orthonormalized() * _wrist_rest).inverse())
	var twist := wrapf(2.0 * atan2(Vector3(turn.x, turn.y, turn.z).dot(axis), turn.w), -PI, PI)
	forearm.basis = Basis(axis, twist * FOREARM_TWIST) * forearm_basis
	forearm.origin = elbow
	skeleton.set_bone_global_pose(_forearm, forearm)
	skeleton.set_bone_global_pose(_hand, Transform3D(target_basis, wrist))
