extends SceneTree
## Renders the soldier from a few angles into a PNG (for checking the model).
##   godot --path . --script tools/preview_character.gd -- out.png [animation] [time] [angles] [model]
## model defaults to res://assets/characters/soldier.glb

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "preview.png"
	var anim: String = args[1] if args.size() > 1 else "idle"
	var at: float = float(args[2]) if args.size() > 2 else 0.0

	var root := Node3D.new()
	get_root().add_child(root)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.6, 0.66)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.72, 0.78)
	env.environment.ambient_light_energy = 0.6
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.shadow_enabled = true
	root.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	floor_mesh.mesh = plane
	root.add_child(floor_mesh)

	var model: String = args[4] if args.size() > 4 else "res://assets/characters/soldier.glb"
	var scene: PackedScene = load(model)
	var angles: Array = [0.0, 140.0, 90.0, 220.0]
	if args.size() > 3:
		angles = Array(args[3].split(",")).map(func(a): return float(a))
	for i in angles.size():
		var s := scene.instantiate() as Node3D
		s.position = Vector3((i - (angles.size() - 1) / 2.0) * 1.3, 0, 0)
		s.rotation_degrees.y = angles[i]
		root.add_child(s)
		var ap: AnimationPlayer = s.find_child("AnimationPlayer", true, false)
		if ap and ap.has_animation(anim):
			ap.play(anim)
			ap.seek(at, true)
			ap.pause()

	var cam := Camera3D.new()
	cam.fov = 50
	root.add_child(cam)
	cam.look_at_from_position(Vector3(0, 1.1, 4.6), Vector3(0, 0.9, 0))
	cam.make_current()

	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(out)
	quit()
