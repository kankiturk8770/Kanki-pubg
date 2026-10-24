extends RefCounted
## Small visual/sound effects made in code (no asset files needed yet).

static var _shot_sound: AudioStreamWAV


## Short "bang": a burst of noise with a low thump, generated once.
static func shot_sound() -> AudioStreamWAV:
	if _shot_sound:
		return _shot_sound
	var rate := 22050
	var count := int(rate * 0.2)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / rate
		var noise := randf_range(-1.0, 1.0) * exp(-t * 30.0)
		var thump := sin(t * TAU * 85.0) * exp(-t * 35.0)
		var s := clampf(noise * 0.6 + thump * 0.7, -1.0, 1.0)
		data.encode_s16(i * 2, int(s * 32000.0))
	_shot_sound = AudioStreamWAV.new()
	_shot_sound.format = AudioStreamWAV.FORMAT_16_BITS
	_shot_sound.mix_rate = rate
	_shot_sound.data = data
	return _shot_sound


## Bright line from the gun to where the bullet landed, plus a spark.
static func tracer(world: Node3D, from: Vector3, to: Vector3) -> void:
	var length := from.distance_to(to)
	if length < 0.2:
		return
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.85, 0.45)

	var line := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.025, 0.025, length)
	box.material = mat
	line.mesh = box
	line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(line)
	var dir := (to - from).normalized()
	var up := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	line.global_transform = Transform3D(Basis.looking_at(dir, up), (from + to) * 0.5)

	var spark := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.06
	sphere.height = 0.12
	sphere.material = mat
	spark.mesh = sphere
	spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(spark)
	spark.global_position = to

	var tween := line.create_tween()
	tween.tween_interval(0.05)
	tween.tween_callback(line.queue_free)
	var tween2 := spark.create_tween()
	tween2.tween_interval(0.1)
	tween2.tween_callback(spark.queue_free)
