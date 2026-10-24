extends SceneTree
## Renders the menu pictures (transparent background):
##   godot --path . --script tools/render_ui_images.gd
## - assets/ui/portrait_male.png, portrait_female.png (sign up, lobby)
## - assets/ui/weapon_<id>.png (lobby loadout cards)

const Characters := preload("res://scripts/characters.gd")
const Weapons := preload("res://scripts/weapons.gd")


func _init() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(512, 640)
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(vp)
	var root := Node3D.new()
	vp.add_child(root)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.72)
	env.environment.ambient_light_energy = 0.5
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	root.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-20, 35, 0)
	key.light_color = Color(1.0, 0.95, 0.88)
	root.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-10, 200, 0)
	rim.light_color = Color(0.6, 0.75, 1.0)
	rim.light_energy = 1.4
	root.add_child(rim)
	var cam := Camera3D.new()
	cam.fov = 26
	root.add_child(cam)
	cam.make_current()
	for c in [Characters.MALE, Characters.FEMALE]:
		var model := Characters.make(c, 0)
		model.rotation_degrees.y = -18
		root.add_child(model)
		var ap: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
		ap.play("idle")
		ap.seek(1.0, true)
		ap.pause()
		var eye := 1.58 if c == Characters.MALE else 1.5
		cam.look_at_from_position(Vector3(0.05, eye + 0.02, 1.45), Vector3(0, eye - 0.12, 0))
		for i in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var name: String = Characters.NAMES[c].to_lower()
		vp.get_texture().get_image().save_png("res://assets/ui/portrait_%s.png" % name)
		model.queue_free()
		await process_frame

	# Weapons: side view, muzzle to the right
	vp.size = Vector2i(640, 280)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	key.rotation_degrees = Vector3(-35, 20, 0)
	for id in Weapons.ORDER:
		var info: Dictionary = Weapons.LIST[id]
		var gun := (info["scene"] as PackedScene).instantiate() as Node3D
		gun.scale = Vector3.ONE * info["length"] / 1.9
		gun.rotation_degrees.y = 180  # muzzle (-X) to the right of the picture
		root.add_child(gun)
		cam.size = info["length"] * 0.46
		cam.look_at_from_position(Vector3(0, 0, 2), Vector3.ZERO)
		for i in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png("res://assets/ui/weapon_%s.png" % id)
		gun.queue_free()
		await process_frame
	quit()
