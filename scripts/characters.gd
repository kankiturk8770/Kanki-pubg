extends RefCounted
## The playable characters. Each player picks one in the lobby (saved in
## Settings.character); the team only changes the uniform colour.
## Models: docs/ASSETS.md step 1 (Meshy) + tools/meshy/merge_animations.py.
## Red uniforms: tools/meshy/make_team_texture.py.

const ArmRelax := preload("res://scripts/arm_relax.gd")

enum { MALE, FEMALE }
const NAMES := ["MALE", "FEMALE"]
const SCENES := [
	preload("res://assets/characters/skins/male.glb"),
	preload("res://assets/characters/skins/female.glb"),
]
## Colour texture per team, null = the model's own (blue) texture.
const TEAM_TEXTURES := [
	[null, preload("res://assets/characters/team_colors/male_red.jpg")],
	[null, preload("res://assets/characters/team_colors/female_red.jpg")],
]


## Makes the character's model in its team's uniform, with the arm fix added.
static func make(character: int, team: int) -> Node3D:
	character = clampi(character, 0, SCENES.size() - 1)
	var model := (SCENES[character] as PackedScene).instantiate() as Node3D
	var texture: Texture2D = TEAM_TEXTURES[character][team]
	if texture and DisplayServer.get_name() != "headless":
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			for i in mi.mesh.get_surface_count():
				var mat := mi.mesh.surface_get_material(i) as StandardMaterial3D
				if mat:
					mat = mat.duplicate()
					mat.albedo_texture = texture
					mi.set_surface_override_material(i, mat)
	var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false)
	skeleton.add_child(ArmRelax.new())
	return model


## The arm fix of a model made by make().
static func arm_relax(model: Node3D) -> SkeletonModifier3D:
	var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false)
	for child in skeleton.get_children():
		if child.get_script() == ArmRelax:
			return child
	return null
