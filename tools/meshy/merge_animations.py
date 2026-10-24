"""Builds a game-ready character GLB from two Meshy downloads.

  python3 tools/meshy/merge_animations.py rigged.glb animations.glb [more.glb ...] out.glb

- rigged.glb      Meshy Rigging result (mesh + full PBR textures, no clips)
- animations.glb  Meshy Animation results made with several action_ids
                  (same skeleton, but only a base color texture). One
                  request takes at most 10 actions, so pass several files.

The output is the rigged model with the clips copied in and renamed to the
names the game plays (see CLIP_NAMES). A still "crouch_idle" clip is made
from the first frame of the crouch walk, because Meshy has no crouch idle.
No libraries needed - a GLB is just JSON + one binary buffer.
"""
import json
import struct
import sys

# Meshy action name -> name used in scripts/player.gd
CLIP_NAMES = {
    "Idle_9": "idle",
    "Idle_3": "lobby_idle",
    "Rifle_Charge_inplace": "run",
    "Lean_Forward_Sprint_inplace": "sprint",
    "Walk_Backward_inplace": "walk_back",
    "Cautious_Crouch_Walk_Forward_inplace": "crouch_walk",
    "Regular_Jump": "jump",
    "Standing_Reload": "reload",
    "Hit_Reaction": "hit",
    "dying_backwards": "death",
    "victory": "lobby_pose",
}
STILL_CLIPS = {"crouch_idle": "crouch_walk"}  # new clip -> made from frame 0 of


def read_glb(path):
    data = open(path, "rb").read()
    json_len = struct.unpack_from("<I", data, 12)[0]
    gltf = json.loads(data[20:20 + json_len])
    bin_start = 20 + json_len + 8
    bin_len = struct.unpack_from("<I", data, 20 + json_len)[0]
    return gltf, bytearray(data[bin_start:bin_start + bin_len])


def write_glb(path, gltf, binary):
    gltf["buffers"] = [{"byteLength": len(binary)}]
    js = json.dumps(gltf, separators=(",", ":")).encode()
    js += b" " * (-len(js) % 4)
    binary = bytes(binary) + b"\0" * (-len(binary) % 4)
    total = 12 + 8 + len(js) + 8 + len(binary)
    with open(path, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
        f.write(struct.pack("<II", len(binary), 0x004E4942) + binary)


def accessor_bytes(gltf, binary, index):
    acc = gltf["accessors"][index]
    view = gltf["bufferViews"][acc["bufferView"]]
    width = {"SCALAR": 1, "VEC3": 3, "VEC4": 4}[acc["type"]] * 4  # float32 only
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    return acc, bytes(binary[start:start + acc["count"] * width]), width


def add_accessor(gltf, binary, acc, raw):
    binary.extend(b"\0" * (-len(binary) % 4))
    gltf["bufferViews"].append({"buffer": 0, "byteOffset": len(binary), "byteLength": len(raw)})
    binary.extend(raw)
    new = {k: v for k, v in acc.items() if k not in ("bufferView", "byteOffset")}
    new["bufferView"] = len(gltf["bufferViews"]) - 1
    gltf["accessors"].append(new)
    return len(gltf["accessors"]) - 1


def copy_clips(model, model_bin, anims_path, first_frames):
    clips, clips_bin = read_glb(anims_path)
    if [n.get("name") for n in model["nodes"]] != [n.get("name") for n in clips["nodes"]]:
        sys.exit(anims_path + " has a different skeleton - was it made from the same rig task?")
    for anim in clips["animations"]:
        name = CLIP_NAMES.get(anim["name"])
        if name is None:
            print("skipped clip", anim["name"])
            continue
        samplers = []
        still = []
        for s in anim["samplers"]:
            in_acc, in_raw, _ = accessor_bytes(clips, clips_bin, s["input"])
            out_acc, out_raw, width = accessor_bytes(clips, clips_bin, s["output"])
            samplers.append({
                "input": add_accessor(model, model_bin, in_acc, in_raw),
                "output": add_accessor(model, model_bin, out_acc, out_raw),
                "interpolation": s.get("interpolation", "LINEAR"),
            })
            still.append((out_acc, out_raw[:width]))
        model["animations"].append({"name": name, "channels": anim["channels"], "samplers": samplers})
        first_frames[name] = (anim["channels"], still)


def main(rigged_path, anims_paths, out_path):
    model, model_bin = read_glb(rigged_path)
    model["animations"] = []
    first_frames = {}
    for anims_path in anims_paths:
        copy_clips(model, model_bin, anims_path, first_frames)

    for name, source in STILL_CLIPS.items():
        channels, still = first_frames[source]
        times = struct.pack("<ff", 0.0, 1.0)
        time_acc = {"componentType": 5126, "count": 2, "type": "SCALAR", "min": [0.0], "max": [1.0]}
        time_index = add_accessor(model, model_bin, time_acc, times)
        samplers = []
        for out_acc, value in still:
            acc = {k: v for k, v in out_acc.items() if k not in ("min", "max")}
            acc["count"] = 2
            samplers.append({"input": time_index, "output": add_accessor(model, model_bin, acc, value * 2),
                             "interpolation": "LINEAR"})
        model["animations"].append({"name": name, "channels": channels, "samplers": samplers})

    write_glb(out_path, model, model_bin)
    print("wrote", out_path, "clips:", [a["name"] for a in model["animations"]])


if __name__ == "__main__":
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2:-1], sys.argv[-1])
