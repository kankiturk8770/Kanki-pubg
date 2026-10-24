"""Makes a Meshy model (prop, weapon...) ready for the game.

  python3 tools/meshy/prepare_model.py [--max-texture=1024] [--keep-normal-map] [--fit=X,Y,Z] in.glb out.glb

Shrinks big textures (phones have little graphics memory) and by default
drops Meshy's normal map, like tools/meshy/merge_animations.py does for
characters. --fit scales the model to that size in metres, stands it on
the floor (y = 0) and centres it, so map props match their colliders.
Needs Pillow.
"""
import sys

from merge_animations import drop_normal_maps, read_glb, shrink_textures, write_glb

def fit(gltf, size):
    """Puts the scene's root nodes under one node that scales and moves the
    model's bounding box to `size`, bottom at y = 0, centred on x and z.
    (Meshy props are one untransformed mesh node, so the box is the mesh's.)"""
    lo = [min(gltf["accessors"][p["attributes"]["POSITION"]]["min"][i]
              for m in gltf["meshes"] for p in m["primitives"]) for i in range(3)]
    hi = [max(gltf["accessors"][p["attributes"]["POSITION"]]["max"][i]
              for m in gltf["meshes"] for p in m["primitives"]) for i in range(3)]
    scale = [size[i] / (hi[i] - lo[i]) for i in range(3)]
    move = [-(lo[i] + hi[i]) / 2 * scale[i] for i in range(3)]
    move[1] = -lo[1] * scale[1]
    scene = gltf["scenes"][gltf.get("scene", 0)]
    gltf["nodes"].append({"name": "fit", "scale": scale, "translation": move, "children": scene["nodes"]})
    scene["nodes"] = [len(gltf["nodes"]) - 1]


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    if len(args) != 2:
        sys.exit(__doc__)
    sizes = [int(f.split("=")[1]) for f in flags if f.startswith("--max-texture=")]
    gltf, binary = read_glb(args[0])
    if "--keep-normal-map" not in flags:
        binary = drop_normal_maps(gltf, binary)
    binary = shrink_textures(gltf, binary, sizes[0] if sizes else 1024)
    fits = [f.split("=")[1] for f in flags if f.startswith("--fit=")]
    if fits:
        fit(gltf, [float(v) for v in fits[0].split(",")])
    write_glb(args[1], gltf, binary)
    print("wrote", args[1])
