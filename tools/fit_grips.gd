extends SceneTree
## Fits every character's hands to every gun. Run it again after changing a
## character or a gun model:
##   godot --headless --path . --script tools/fit_grips.gd [-- 0/m416 1/akm ...]
## (with pairs after "--": fit only those, keep the others as they are)
## It writes scripts/grip_data.gd (read by scripts/hand_grip.gd):
## - shift: moves the gun in the right hand so the pistol grip lies against
##   the palm instead of going through it,
## - left: where the left hand holds the handguard,
## - curl: how far each finger joint bends.
## The gun is its real mesh turned into solid 5 mm cubes (the meshes are
## not closed everywhere: the M416's grip is open at the back). The hand is
## its real skin: a part of the hand goes into the gun when the line from
## its bone to one of its skin vertices meets a solid cube (skin is soft:
## the last few millimetres may). Each finger takes the most closed pose
## that does not go into the gun (so it closes round it), with the knuckle
## and middle joints bending together like a real hand's. The right palm
## sits on the pistol grip; the left hand tries many ways of holding the
## handguard and keeps the one where most fingers rest on the gun, the thumb
## lies along its left side and the wrist bends least.

const Characters := preload("res://scripts/characters.gd")
const Weapons := preload("res://scripts/weapons.gd")
const WeaponHolder := preload("res://scripts/weapon_holder.gd")
const HandGrip := preload("res://scripts/hand_grip.gd")
const GripData := preload("res://scripts/grip_data.gd")
const OUT := "res://scripts/grip_data.gd"

## Most each joint may bend, degrees (joints 1-3)
const MAX_BEND := {
	"Thumb": [45.0, 50.0, 60.0], "Index": [90.0, 100.0, 70.0], "Middle": [90.0, 100.0, 70.0],
	"Ring": [90.0, 100.0, 70.0], "Pinky": [90.0, 100.0, 70.0],
}
## The right index finger is the trigger finger: it curls only as far as
## the trigger, not into a fist
const TRIGGER_BEND := [60.0, 75.0, 45.0]
## Finger bends tried, every so many degrees (search, final)
const SEARCH_STEP := 15.0
const STEP := 5.0
## Skin is soft: how deep the gun may press into the palm and the fingers
const PALM_GIVE := 0.008
const FINGER_GIVE := 0.003
## Ways to hold the handguard (degrees, metres): fingers turned towards the
## muzzle, palm turned towards the gun's right side, hand rolled, and how
## far the palm sits sideways from the middle of the handguard
const YAWS := [0.0, 20.0, 40.0, 60.0]
const PITCHES := [0.0, 20.0, 40.0, 60.0]
const ROLLS := [-30.0, -15.0, 0.0, 15.0, 30.0]
const SIDEWAYS := [-0.03, -0.015, 0.0, 0.015, 0.03, 0.045, 0.06]

## Solid cubes of the gun (see _voxelize)
const VOXEL := 0.005
## Most cubes in a slice of a pistol grip (bigger: receiver, magazine well)
const GRIP_MOST := 220

var _origin := Vector3.ZERO
var _dims := Vector3i.ZERO
var _solid := PackedByteArray()
var _space: PhysicsDirectSpaceState3D
var _ray := PhysicsRayQueryParameters3D.new()
var _sk: Skeleton3D
var _joints: Array


func _init() -> void:
	await process_frame   # the scene tree must be running for global transforms
	_ray.hit_back_faces = true
	var body := StaticBody3D.new()
	var gun_shape := CollisionShape3D.new()
	body.add_child(gun_shape)
	get_root().add_child(body)
	var text := "extends RefCounted\n## Made by tools/fit_grips.gd: run it again after changing a character or a\n" \
			+ "## gun model. Per \"character/gun\": `shift` moves the gun in the right palm\n" \
			+ "## (gun's frame), `left` = left hand bone in the gun's frame, `curl` = bend\n" \
			+ "## of each finger joint in degrees (order of HandGrip.finger_joints()).\n" \
			+ "const FITS := {\n"
	var only := OS.get_cmdline_user_args()
	var fits: Dictionary = GripData.FITS.duplicate(true)
	for character in Characters.SCENES.size():
		var model := Characters.make(character, 0, true)
		get_root().add_child(model)
		_sk = model.find_child("Skeleton3D", true, false)
		var anim: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
		_joints = HandGrip.finger_joints(_sk)
		var hands := {"Right": _measure(model, "Right"), "Left": _measure(model, "Left")}
		for id in Weapons.ORDER:
			var key := "%d/%s" % [character, id]
			if not only.is_empty() and key not in only:
				continue
			var faces := _gun_faces(id)
			var trimesh := ConcavePolygonShape3D.new()
			trimesh.backface_collision = true
			trimesh.set_faces(faces)
			gun_shape.shape = trimesh
			await physics_frame
			await physics_frame
			_space = get_root().find_world_3d().direct_space_state
			_voxelize(faces)
			# Where the gun sits in the right hand (idle pose), as in the game
			anim.active = true
			var holder := WeaponHolder.new()
			holder.setup(_sk, id, anim)
			var in_hand: Transform3D = holder.in_hand
			var to_world := _sk.global_transform
			var gun := (to_world * _sk.get_bone_global_pose(_sk.find_bone("RightHand"))).orthonormalized() * in_hand
			var arm := []
			for bone in ["LeftArm", "LeftForeArm", "LeftHand"]:
				arm.append(gun.affine_inverse() * (to_world * _sk.get_bone_global_pose(_sk.find_bone(bone)).origin))
			anim.stop()
			anim.active = false
			_sk.reset_bone_poses()
			var fit := _fit(hands, in_hand, holder._grip, holder.support_point, arm)
			holder.free()
			print("%s/%s  %s" % [Characters.NAMES[character], id, fit["report"]])
			if not fit["curl"].is_empty():
				fits[key] = fit
		model.free()
	for key in fits:
		var fit: Dictionary = fits[key]
		text += "\t\"%s\": {\n\t\t\"shift\": %s,\n\t\t\"left\": %s,\n\t\t\"curl\": %s,\n\t},\n" % [
			key, _vec(fit["shift"]), _xform(fit["left"]), _list(fit["curl"])]
	text += "}\n"
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	file.store_string(text)
	print("wrote ", OUT)
	quit()


func _fit(hands: Dictionary, in_hand: Transform3D, grip: Vector3, support: Vector3, arm: Array) -> Dictionary:
	# Right hand (the gun keeps its angle in the hand, which the animations
	# aim with; only where it sits in the hand changes): the pistol grip lies
	# in the palm, its front by the knuckles, the middle finger a third of
	# the way down it. Then small moves around that, keeping the one where
	# the palm does not go into the gun and the fingers close round it best.
	var right: Dictionary = hands["Right"]
	var axes: Basis = in_hand.basis.inverse() * (right["frame"]["axes"] as Basis)   # hand axes, gun frame
	var levels := _grip_levels(grip)
	if levels.is_empty():
		push_error("pistol grip not found")
		return {"curl": [], "report": "no grip"}
	var level: Dictionary = levels[int(levels.size() * 0.35)]
	var mid: Vector3 = level["centre"]
	var out_n := 0.0
	var out_a := 0.0
	for q in level["points"]:
		out_n = maxf(out_n, (q - mid).dot(axes.y))
		out_a = maxf(out_a, (q - mid).dot(axes.x))
	var palm: Vector3 = mid - axes.y * (out_n + right["palm_depth"] - PALM_GIVE) \
			+ axes.x * (out_a + 0.005 - right["knuckle"])
	var start: Vector3 = palm - in_hand.affine_inverse() * (right["frame"]["centre"] as Vector3)
	var best_right := {"score": -INF}
	for out in [0.0, 0.005, 0.01, 0.015, 0.02, 0.025, 0.03, 0.035, 0.04]:
		for slide in [-0.01, 0.0, 0.01]:
			for reach in [-0.01, 0.0, 0.01]:
				var move: Vector3 = start - axes.y * out + axes.z * slide + axes.x * reach
				var c := _try_right(right, in_hand, move, SEARCH_STEP)
				c["score"] -= out * 200.0 + (absf(slide) + absf(reach)) * 150.0
				if c["score"] > best_right["score"]:
					best_right = c
	if not best_right.has("move"):
		push_error("right hand does not fit the grip")
		return {"curl": [], "report": "right hand does not fit"}
	best_right = _try_right(right, in_hand, best_right["move"], STEP)
	var shift: Vector3 = -(best_right["move"] as Vector3)
	var fingers := {"Right": best_right["fingers"], "Left": {}}
	var report := "grip %d levels, shift %.1fcm  right %s" % [levels.size(), shift.length() * 100.0,
			_touches(fingers["Right"])]

	# Left hand: try many ways of holding the handguard, keep the best
	var shifted := []
	for p in arm:
		shifted.append(p - shift)
	var left: Dictionary = hands["Left"]
	var centre := _handguard_middle(support)
	var tried := []
	for yaw in YAWS:
		for pitch in PITCHES:
			for roll in ROLLS:
				for side in SIDEWAYS:
					var c := _try_left(left, [yaw, pitch, roll, side], centre, shifted, SEARCH_STEP)
					if c["score"] > -INF:
						tried.append(c)
	tried.sort_custom(func(x, y): return x["score"] > y["score"])
	var best := {"score": -INF}
	for c in tried.slice(0, 8):
		var full := _try_left(left, c["params"], centre, shifted, STEP)
		if full["score"] > best["score"]:
			best = full
	if best["score"] == -INF:
		push_error("no way to hold the handguard found")
		return {"shift": shift, "left": Transform3D(), "curl": [], "report": report}
	fingers["Left"] = best["fingers"]
	report += "  left %s score %.0f wrist %.0f° %s" % [str(best["params"]), best["score"], best["wrist"],
			_touches(fingers["Left"])]
	var curl := []
	for j in _joints:
		curl.append(rad_to_deg(fingers[j["side"]][j["finger"]]["angles"][j["joint"]]))
	return {"shift": shift, "left": best["hand"], "curl": curl, "report": report}


## The right hand moved by `move` (gun's frame) from where the animation
## holds it: how well it holds the grip (-INF: the palm is in the gun).
func _try_right(hand: Dictionary, in_hand: Transform3D, move: Vector3, step: float) -> Dictionary:
	var placed := Transform3D(Basis(), move) * in_hand.affine_inverse()
	if _part_hits(hand["palm"], placed, PALM_GIVE):
		return {"score": -INF}
	var score := 0.0
	var fingers := {}
	for finger in HandGrip.FINGERS:
		var most: Array = TRIGGER_BEND if finger == "Index" else MAX_BEND[finger]
		var r := _close(hand["chains"][finger], placed * hand["to_hand"], most, step)
		fingers[finger] = r
		if r["touch"] == -2:
			score -= 30.0
		elif r["touch"] >= 0:
			score += 10.0 if finger in ["Middle", "Ring", "Pinky"] else 5.0
			score += r["bend"] / 40.0   # wrapped further round the grip
	return {"score": score, "move": move, "fingers": fingers}


## The pistol grip, slice by slice from under `start` down to its bottom
## (slices too big for a grip, like the receiver's, are skipped at the
## top): the middle and the solid cubes of each slice.
func _grip_levels(start: Vector3) -> Array:
	var levels := []
	var centre := start
	var top := _cell(start).y
	for y in range(top, maxi(top - 40, 0), -1):
		var near := _cell(centre)
		var cells := _flood(Vector3i(0, 1, 0), Vector3i(near.x, y, near.z))
		if cells.is_empty() or cells.size() > GRIP_MOST:
			if levels.is_empty():
				continue
			break
		var points := []
		var mid := Vector3.ZERO
		for c in cells:
			points.append(_at(c))
			mid += _at(c)
		mid /= points.size()
		levels.append({"centre": mid, "points": points})
		centre = mid
	return levels


## Solid cubes joined to the one nearest `near` (within 2.5 cm), in the
## slice across `across` (one axis of the gun), at most GRIP_MOST * 2.
func _flood(across: Vector3i, near: Vector3i) -> Array:
	var u := Vector3i(across.y + across.z, across.x, 0)   # the two axes of the slice
	var v := Vector3i(0, across.z, across.x + across.y)
	var seed := Vector3i(-1, -1, -1)
	var nearest := 1000
	for i in range(-5, 6):
		for j in range(-5, 6):
			var q := near + u * i + v * j
			if _solid_cell(q) and i * i + j * j < nearest:
				nearest = i * i + j * j
				seed = q
	if nearest == 1000:
		return []
	var seen := {seed: true}
	var todo := [seed]
	var cells := []
	while not todo.is_empty() and cells.size() <= GRIP_MOST * 2:
		var q: Vector3i = todo.pop_back()
		cells.append(q)
		for d in [u, -u, v, -v]:
			if not seen.has(q + d) and _solid_cell(q + d):
				seen[q + d] = true
				todo.append(q + d)
	return cells


## Middle of the handguard's cross-section at the left palm's point.
func _handguard_middle(support: Vector3) -> Vector3:
	var cells := _flood(Vector3i(1, 0, 0), _cell(support))
	if cells.is_empty():
		return support + Vector3(0.0, 0.03, 0.0)
	var mid := Vector3.ZERO
	for c in cells:
		mid += _at(c)
	return mid / cells.size()


## The gun as solid cubes: cubes the surface goes through, and cubes from
## which at most one of six rays gets away without meeting the gun.
func _voxelize(faces: PackedVector3Array) -> void:
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for p in faces:
		lo = lo.min(p)
		hi = hi.max(p)
	_origin = lo - Vector3.ONE * VOXEL
	_dims = Vector3i((hi - lo) / VOXEL) + Vector3i(3, 3, 3)
	_solid = PackedByteArray()
	_solid.resize(_dims.x * _dims.y * _dims.z)
	for t in range(0, faces.size(), 3):
		var a := faces[t]
		var ab := faces[t + 1] - a
		var ac := faces[t + 2] - a
		var n := maxi(1, ceili(maxf(ab.length(), ac.length()) / (VOXEL * 0.5)))
		for i in n + 1:
			for j in n + 1 - i:
				var c := _cell(a + ab * (float(i) / n) + ac * (float(j) / n))
				_solid[(c.x * _dims.y + c.y) * _dims.z + c.z] = 1
	var surface := _solid.duplicate()
	var away_dirs := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.FORWARD, Vector3.BACK]
	for x in _dims.x:
		for y in _dims.y:
			for z in _dims.z:
				var i := (x * _dims.y + y) * _dims.z + z
				if surface[i]:
					continue
				var p := _at(Vector3i(x, y, z))
				var away := 0
				for d in away_dirs:
					_ray.from = p
					_ray.to = p + d * 0.5
					if _space.intersect_ray(_ray).is_empty():
						away += 1
						if away > 1:
							break
				if away <= 1:
					_solid[i] = 1


func _cell(p: Vector3) -> Vector3i:
	var q := (p - _origin) / VOXEL
	return Vector3i(floori(q.x), floori(q.y), floori(q.z))


func _at(c: Vector3i) -> Vector3:
	return _origin + (Vector3(c) + Vector3.ONE * 0.5) * VOXEL


func _solid_cell(c: Vector3i) -> bool:
	if c.x < 0 or c.y < 0 or c.z < 0 or c.x >= _dims.x or c.y >= _dims.y or c.z >= _dims.z:
		return false
	return _solid[(c.x * _dims.y + c.y) * _dims.z + c.z] != 0


## One way of holding the handguard: the palm comes up to it along the palm's
## direction until it touches, then the fingers close on it.
func _try_left(hand: Dictionary, params: Array, centre: Vector3, arm: Array, step: float) -> Dictionary:
	var yaw := deg_to_rad(params[0])
	var pitch := deg_to_rad(params[1])
	var a0 := Vector3(-sin(yaw), 0.0, -cos(yaw))   # gun frame: muzzle -X, top +Y, right side -Z
	var a := a0 * cos(pitch) - Vector3.UP * sin(pitch)
	var n := (Vector3.UP * cos(pitch) + a0 * sin(pitch)).rotated(a, deg_to_rad(params[2]))
	var basis := Basis(a, n, a.cross(n)) * (hand["frame"]["axes"] as Basis).inverse()
	var across := n.cross(Vector3.RIGHT).normalized()
	var placed := Transform3D()
	var touching := false
	for i in 60:
		var palm: Vector3 = centre + across * params[3] - n * (0.18 - i * 0.003)
		var t := Transform3D(basis, palm - basis * (hand["frame"]["centre"] as Vector3))
		if _part_hits(hand["palm"], t, PALM_GIVE):
			touching = true
			break
		placed = t
	if not touching:
		return {"score": -INF}
	# The arm must reach it (as in the idle pose); the wrist should bend little
	var s: Vector3 = arm[0]
	var e: Vector3 = arm[1]
	var upper := s.distance_to(e)
	var lower := e.distance_to(arm[2])
	var wrist := placed.origin
	var d := s.distance_to(wrist)
	if d > upper + lower - 0.01:
		return {"score": -INF}
	var dir := (wrist - s) / d
	var bend := ((e - s) - dir * (e - s).dot(dir)).normalized()
	var cos_a := clampf((upper * upper + d * d - lower * lower) / (2.0 * upper * d), -1.0, 1.0)
	var elbow := s + dir * upper * cos_a + bend * upper * sqrt(1.0 - cos_a * cos_a)
	var wrist_bend := rad_to_deg((wrist - elbow).normalized().angle_to(a))
	var score := -maxf(wrist_bend - 30.0, 0.0) * 0.4 - absf(params[3]) * 20.0
	var fingers := {}
	for finger in HandGrip.FINGERS:
		var r := _close(hand["chains"][finger], placed * hand["to_hand"], MAX_BEND[finger], step)
		if r["touch"] == -2:
			return {"score": -INF}
		fingers[finger] = r
		if r["touch"] >= 0:
			score += 10.0
		if finger == "Thumb":
			score += 6.0 if r["tip"].z > 0.01 else 0.0
		elif r["tip"].z < -0.005:
			score += 2.0
	return {"score": score, "params": params, "hand": placed, "fingers": fingers, "wrist": wrist_bend}


## Most closed pose of a finger that does not go into the gun, whatever way
## the hand came onto it: the knuckle and middle joints try every bend from
## a little bent back to `most` (the end joint bends with the middle one, as
## in real fingers). touch: 1 = rests on the gun, -1 = closed on nothing,
## -2 = in the gun however it bends.
func _close(chain: Dictionary, to_gun: Transform3D, most: Array, step: float) -> Dictionary:
	var poses: Array[Vector2] = []
	# (the thumb can swing well out from the palm, the fingers bend back a little)
	var least := -45 if most == MAX_BEND["Thumb"] else -20
	for a in range(least, int(most[0]) + 1, int(step)):
		for b in range(0, int(most[1]) + 1, int(step)):
			poses.append(Vector2(a, b))
	# most closed first; knuckle and middle joint bending together looks natural
	var closed := func(p: Vector2) -> float:
		return p.x + p.y - 0.3 * absf(p.x - 0.8 * p.y)
	poses.sort_custom(func(p: Vector2, q: Vector2) -> bool: return closed.call(p) > closed.call(q))
	for p in poses:
		var angles := [deg_to_rad(p.x), deg_to_rad(p.y), deg_to_rad(p.y * most[2] / most[1])]
		if _first_hit(chain, angles, to_gun) < 0:
			var tip := to_gun * _sk.get_bone_global_pose(chain["bones"][3]).origin
			var all_the_way: bool = p.x + step > most[0] and p.y + step > most[1]
			return {"angles": angles, "touch": -1 if all_the_way else 1, "tip": tip, "bend": p.x + p.y}
	return {"angles": [0.0, 0.0, 0.0], "touch": -2, "tip": Vector3.ZERO, "bend": 0.0}


func _pose(chain: Dictionary, angles: Array) -> void:
	for k in 3:
		var j: Dictionary = _joints[chain["joints"][k]]
		_sk.set_bone_pose_rotation(j["bone"], HandGrip.joint_rotation(j, angles[k]))


## First part of the finger (0-2) that is in the gun, -1 none.
func _first_hit(chain: Dictionary, angles: Array, to_gun: Transform3D) -> int:
	_pose(chain, angles)
	for k in 3:
		var bone: int = chain["bones"][k]
		if _part_hits(chain["parts"][k], to_gun * _sk.get_bone_global_pose(bone)):
			return k
	return -1


## A part of the hand (skin vertices + the nearest points on its bone, in
## the bone's space) is in the gun if the line from the bone to its skin
## meets a solid cube (all but the last `give` of it).
func _part_hits(part: Dictionary, bone_in_gun: Transform3D, give := FINGER_GIVE) -> bool:
	var skin: PackedVector3Array = part["skin"]
	var from: PackedVector3Array = part["from"]
	for i in skin.size():
		var o := bone_in_gun * from[i]
		var out := bone_in_gun * skin[i] - o
		var deep := out.length() - give   # how far out the line is tested
		var steps := maxi(1, ceili(deep / VOXEL))
		for k in steps + 1:
			if _solid_cell(_cell(o + out.normalized() * maxf(deep, 0.0) * k / steps)):
				return true
	return false


## The hand's skin, bone by bone, from the character's mesh (rest pose).
func _measure(model: Node3D, side: String) -> Dictionary:
	var frame := HandGrip.hand_frame(_sk, side)
	var hand := _sk.find_bone(side + "Hand")
	var axis_ends := {hand: [_sk.get_bone_global_rest(hand).origin,
			_sk.get_bone_global_rest(_sk.find_bone(side + "HandMiddle1")).origin]}
	var chains := {}
	for finger in HandGrip.FINGERS:
		var chain := {"joints": [], "bones": [], "parts": []}
		for j in 4:
			chain["bones"].append(_sk.find_bone("%sHand%s%d" % [side, finger, j + 1]))
		for i in _joints.size():
			if _joints[i]["side"] == side and _joints[i]["finger"] == finger:
				chain["joints"].append(i)
		for j in 3:
			axis_ends[chain["bones"][j]] = [_sk.get_bone_global_rest(chain["bones"][j]).origin,
					_sk.get_bone_global_rest(chain["bones"][j + 1]).origin]
		chains[finger] = chain
	var skins := {}
	for bone in axis_ends:
		skins[bone] = [PackedVector3Array(), PackedVector3Array()]
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var skin: Skin = mi.skin
		if skin == null:
			continue
		var binds := []
		for i in skin.get_bind_count():
			var b := skin.get_bind_bone(i)
			binds.append(b if b >= 0 else _sk.find_bone(skin.get_bind_name(i)))
		for si in mi.mesh.get_surface_count():
			var arrays: Array = mi.mesh.surface_get_arrays(si)
			if arrays[Mesh.ARRAY_BONES] == null:
				continue
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var per := bones.size() / verts.size()
			for v in verts.size():
				var top := -1
				var top_weight := 0.0
				for q in per:
					if weights[v * per + q] > top_weight:
						top_weight = weights[v * per + q]
						top = bones[v * per + q]
				if top < 0 or top_weight < 0.5 or not skins.has(binds[top]):
					continue
				var bone: int = binds[top]
				var rest := _sk.get_bone_global_rest(bone)
				var p := rest * skin.get_bind_pose(top) * verts[v]
				var ends: Array = axis_ends[bone]
				var seg: Vector3 = ends[1] - ends[0]
				var on_axis: Vector3 = ends[0] + seg * clampf((p - ends[0]).dot(seg) / seg.length_squared(), 0.0, 1.0)
				var to_bone := rest.affine_inverse()
				skins[bone][0].append(to_bone * p)
				skins[bone][1].append(to_bone * on_axis)
	var counts := ""
	for finger in HandGrip.FINGERS:
		for j in 3:
			var bone: int = chains[finger]["bones"][j]
			chains[finger]["parts"].append({"skin": skins[bone][0], "from": skins[bone][1]})
			counts += "%d " % skins[bone][0].size()
	print("%s hand: palm %d skin vertices, fingers %s" % [side, skins[hand][0].size(), counts])
	# how far the palm's skin stands out from the bone in the middle of the
	# palm, and how far ahead the knuckles are
	var axes: Basis = frame["axes"]
	var to_hand := _sk.get_bone_global_rest(hand).orthonormalized().affine_inverse()
	var depth := []
	for v in skins[hand][0]:
		var q: Vector3 = axes.inverse() * (v - frame["centre"])
		if absf(q.x) < 0.015 and absf(q.z) < 0.015:
			depth.append(q.y)
	depth.sort()
	var knuckle: Vector3 = to_hand * _sk.get_bone_global_rest(_sk.find_bone(side + "HandMiddle1")).origin
	return {
		"frame": frame, "chains": chains, "palm": {"skin": skins[hand][0], "from": skins[hand][1]},
		"to_hand": _sk.get_bone_global_rest(hand).affine_inverse(),
		"palm_depth": depth[int(depth.size() * 0.9)] if depth.size() > 0 else 0.015,
		"knuckle": (axes.inverse() * (knuckle - frame["centre"])).x,
	}


## The gun's triangles in its frame (metres; muzzle -X, top +Y).
func _gun_faces(id: String) -> PackedVector3Array:
	var info := Weapons.get_info(id)
	var root := Node3D.new()
	var model := (info["scene"] as PackedScene).instantiate() as Node3D
	model.scale = Vector3.ONE * (info["length"] / 1.9)
	root.add_child(model)
	get_root().add_child(root)
	var faces := PackedVector3Array()
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var xf: Transform3D = root.global_transform.affine_inverse() * mi.global_transform
		for v in mi.mesh.get_faces():
			faces.append(xf * v)
	root.free()
	return faces


func _touches(fingers: Dictionary) -> String:
	var s := ""
	for finger in HandGrip.FINGERS:
		var t: int = fingers[finger]["touch"]
		s += "%s:%s " % [finger.substr(0, 2), "in" if t == -2 else ("open" if t < 0 else "%d°" % fingers[finger]["bend"])]
	return s


func _vec(v: Vector3) -> String:
	return "Vector3(%.5f, %.5f, %.5f)" % [v.x, v.y, v.z]


## (Godot 4.3 hangs parsing the 12-number form var_to_str() writes)
func _xform(t: Transform3D) -> String:
	return "Transform3D(%s, %s, %s, %s)" % [_vec(t.basis.x), _vec(t.basis.y), _vec(t.basis.z), _vec(t.origin)]


func _list(values: Array) -> String:
	var parts := PackedStringArray()
	for v in values:
		parts.append("%.1f" % v)
	return "[" + ", ".join(parts) + "]"
