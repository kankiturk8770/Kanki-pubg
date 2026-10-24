extends RefCounted
## The guns. Models from Meshy (docs/ASSETS.md step 4, tools/meshy/prepare_model.py).
## Every model lies along X with the muzzle at -X, the stock at +X and the
## top at +Y, about 1.9 units long; `length` scales it to real size.
## Points are in model units (read off tools/render_ui_images.gd pictures):
## `grip` = middle of the pistol grip (right palm), `support` = under the
## handguard (left palm), `muzzle` = end of the barrel.

const ORDER := ["m416", "akm", "ump45"]
const LIST := {
	"m416": {
		"name": "M416", "scene": preload("res://assets/weapons/m416.glb"), "length": 0.84,
		"grip": Vector3(0.33, -0.08, 0.0), "support": Vector3(-0.35, 0.1, 0.0),
		"muzzle": Vector3(-0.95, 0.17, 0.0),
		"fire_interval": 0.086, "body_damage": 22, "head_damage": 48,
	},
	"akm": {
		"name": "AKM", "scene": preload("res://assets/weapons/akm.glb"), "length": 0.88,
		"grip": Vector3(0.38, 0.02, 0.0), "support": Vector3(-0.3, 0.12, 0.0),
		"muzzle": Vector3(-0.95, 0.2, 0.0),
		"fire_interval": 0.1, "body_damage": 26, "head_damage": 56,
	},
	"ump45": {
		"name": "UMP45", "scene": preload("res://assets/weapons/ump45.glb"), "length": 0.69,
		"grip": Vector3(0.17, -0.05, 0.0), "support": Vector3(-0.5, 0.12, 0.0),
		"muzzle": Vector3(-0.95, 0.24, 0.0),
		"fire_interval": 0.092, "body_damage": 19, "head_damage": 40,
	},
}


static func get_info(id: String) -> Dictionary:
	return LIST.get(id, LIST["m416"])
