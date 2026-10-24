"""Builds a game-ready character GLB from two Meshy downloads.

  python3 tools/meshy/merge_animations.py [--max-texture=2048] rigged.glb animations.glb [more.glb ...] out.glb

- rigged.glb      Meshy Rigging result (mesh + full PBR textures, no clips)
- animations.glb  Meshy Animation results made with several action_ids
                  (same skeleton, but only a base color texture). One
                  request takes at most 10 actions, so pass several files.

The output is the rigged model with the clips copied in and renamed to the
names the game plays (see CLIP_NAMES). A still "crouch_idle" clip is made
from the first frame of the crouch walk, because Meshy has no crouch idle.
A GLB is just JSON + one binary buffer. Only --max-texture (shrinks bigger
textures, so the model fits phone memory) needs Pillow.
"""
import io
import json
import struct
import sys

# Meshy action name -> name used in scripts/player.gd
CLIP_NAMES = {
    "Idle_9": "idle",
    "Idle_3": "lobby_idle",
    "run_fast_9": "run",
    "Lean_Forward_Sprint_inplace": "sprint",
    "Walk_Backward_inplace": "walk_back",
    "Cautious_Crouch_Walk_Forward_inplace": "crouch_walk",
    "Regular_Jump": "jump",
    "Standing_Reload": "reload",
    "Hit_Reaction": "hit",
    "dying_backwards": "death",
    "victory": "lobby_pose",
    # Rifle poses: scripts/weapon_pose.gd takes the arms from these
    "Combat_Idle_Turn_Left": "rifle_idle",
    "Walk_Forward_While_Shooting": "rifle_aim",
    "Walk_Backward_with_Gun_1": "rifle_back",
}
STILL_CLIPS = {"crouch_idle": "crouch_walk"}  # new clip -> made from frame 0 of
# Clips that walk forward (no "_inplace" version in the library): the hips'
# steady forward/sideways drift is removed so they play on the spot.
MAKE_IN_PLACE = {"run_fast_9"}
ROOT_BONE = "Hips"
# Meshy's normal maps put hard creases on the face (even when weakened), and
# the colour texture already has the cloth detail: leave them out.
DROP_NORMAL_MAPS = True
# The crouch walk holds the arms out wide and the jump throws them over the
# head (both look odd without a weapon). These clips get their arm bones from
# the first frame of ARM_SOURCE instead.
ARMS_FROM_IDLE = {"crouch_walk", "crouch_idle", "jump"}
ARM_SOURCE = "idle"
ARM_BONES = {side + part for side in ("Left", "Right") for part in ("Shoulder", "Arm", "ForeArm", "Hand")}


TINY_PNG = bytes.fromhex(
    "89504e470d0a1a0a0000000d4948445200000001000000010802000000907753de"
    "0000000c49444154789c636868f80f000383020000a5fb890000000049454e44ae426082")


def drop_normal_maps(gltf, binary):
    """Removes normal maps from the materials; their images become 1x1 pixel."""
    dropped = {}
    for material in gltf.get("materials", []):
        normal = material.pop("normalTexture", None)
        if normal is not None:
            image = gltf["images"][gltf["textures"][normal["index"]]["source"]]
            dropped[image["bufferView"]] = TINY_PNG
            image["mimeType"] = "image/png"
    return replace_buffer_views(gltf, binary, dropped)


def replace_buffer_views(gltf, binary, new_bytes):
    """Returns a new buffer with some buffer views' data swapped out."""
    if not new_bytes:
        return binary
    rebuilt = bytearray()
    for index, view in enumerate(gltf["bufferViews"]):
        start = view.get("byteOffset", 0)
        data = new_bytes.get(index, bytes(binary[start:start + view["byteLength"]]))
        rebuilt.extend(b"\0" * (-len(rebuilt) % 4))
        view["byteOffset"] = len(rebuilt)
        view["byteLength"] = len(data)
        rebuilt.extend(data)
    return rebuilt


def shrink_textures(gltf, binary, max_size):
    """Returns a new buffer where every image bigger than max_size is scaled down."""
    from PIL import Image
    new_bytes = {}
    for image in gltf.get("images", []):
        view = gltf["bufferViews"][image["bufferView"]]
        start = view.get("byteOffset", 0)
        img = Image.open(io.BytesIO(bytes(binary[start:start + view["byteLength"]])))
        if max(img.size) <= max_size:
            continue
        print("texture", img.size, "->", max_size)
        img = img.resize((max_size, max_size * img.size[1] // img.size[0]), Image.LANCZOS)
        out = io.BytesIO()
        if image.get("mimeType") == "image/png":
            img.save(out, "PNG", optimize=True)
        else:
            img.convert("RGB").save(out, "JPEG", quality=92)
        new_bytes[image["bufferView"]] = out.getvalue()
    return replace_buffer_views(gltf, binary, new_bytes)


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


def _is_root_translation(gltf, anim, sampler):
    index = anim["samplers"].index(sampler)
    return any(c["sampler"] == index and c["target"]["path"] == "translation"
               and gltf["nodes"][c["target"]["node"]].get("name") == ROOT_BONE
               for c in anim["channels"])


def remove_drift(times_raw, values_raw):
    """Takes the straight line from the first to the last key off X and Z
    (keeps the up/down bounce on Y), so the clip loops on the spot."""
    times = struct.unpack("<%df" % (len(times_raw) // 4), times_raw)
    v = list(struct.unpack("<%df" % (len(values_raw) // 4), values_raw))
    span = (times[-1] - times[0]) or 1.0
    for axis in (0, 2):
        first, last = v[axis], v[-3 + axis]
        for i, t in enumerate(times):
            v[i * 3 + axis] -= (last - first) * (t - times[0]) / span
    return struct.pack("<%df" % len(v), *v)


def copy_clips(model, model_bin, anims_path, first_frames):
    clips, clips_bin = read_glb(anims_path)
    if [n.get("name") for n in model["nodes"]] != [n.get("name") for n in clips["nodes"]]:
        sys.exit(anims_path + " has a different skeleton - was it made from the same rig task?")
    for anim in clips["animations"]:
        # A request with a single action names its clip "Armature|<action>|baselayer"
        action = anim["name"].split("|")[1] if "|" in anim["name"] else anim["name"]
        name = CLIP_NAMES.get(action)
        if name is None:
            print("skipped clip", anim["name"])
            continue
        samplers = []
        still = []
        for s in anim["samplers"]:
            in_acc, in_raw, _ = accessor_bytes(clips, clips_bin, s["input"])
            out_acc, out_raw, width = accessor_bytes(clips, clips_bin, s["output"])
            if action in MAKE_IN_PLACE and _is_root_translation(clips, anim, s):
                out_raw = remove_drift(in_raw, out_raw)
                out_acc = {k: v for k, v in out_acc.items() if k not in ("min", "max")}
            samplers.append({
                "input": add_accessor(model, model_bin, in_acc, in_raw),
                "output": add_accessor(model, model_bin, out_acc, out_raw),
                "interpolation": s.get("interpolation", "LINEAR"),
            })
            still.append((out_acc, out_raw[:width]))
        model["animations"].append({"name": name, "channels": anim["channels"], "samplers": samplers})
        first_frames[name] = (anim["channels"], still)


def still_sampler(model, model_bin, out_acc, value):
    """A two-key sampler (t=0 and t=1) that holds one value."""
    time_acc = {"componentType": 5126, "count": 2, "type": "SCALAR", "min": [0.0], "max": [1.0]}
    acc = {k: v for k, v in out_acc.items() if k not in ("min", "max")}
    acc["count"] = 2
    return {"input": add_accessor(model, model_bin, time_acc, struct.pack("<ff", 0.0, 1.0)),
            "output": add_accessor(model, model_bin, acc, value * 2), "interpolation": "LINEAR"}


def replace_arms(model, model_bin, first_frames):
    channels, still = first_frames[ARM_SOURCE]
    held = {}  # (node, path) -> (accessor, first value)
    for c in channels:
        if model["nodes"][c["target"]["node"]].get("name") in ARM_BONES:
            held[(c["target"]["node"], c["target"]["path"])] = still[c["sampler"]]
    for anim in model["animations"]:
        if anim["name"] not in ARMS_FROM_IDLE:
            continue
        for c in anim["channels"]:
            key = (c["target"]["node"], c["target"]["path"])
            if key in held:
                anim["samplers"].append(still_sampler(model, model_bin, *held[key]))
                c["sampler"] = len(anim["samplers"]) - 1


def main(rigged_path, anims_paths, out_path, max_texture=None):
    model, model_bin = read_glb(rigged_path)
    if DROP_NORMAL_MAPS:
        model_bin = drop_normal_maps(model, model_bin)
    if max_texture:
        model_bin = shrink_textures(model, model_bin, max_texture)
    model["animations"] = []
    first_frames = {}
    for anims_path in anims_paths:
        copy_clips(model, model_bin, anims_path, first_frames)

    for name, source in STILL_CLIPS.items():
        channels, still = first_frames[source]
        samplers = [still_sampler(model, model_bin, acc, value) for acc, value in still]
        model["animations"].append({"name": name, "channels": channels, "samplers": samplers})

    replace_arms(model, model_bin, first_frames)
    write_glb(out_path, model, model_bin)
    print("wrote", out_path, "clips:", [a["name"] for a in model["animations"]])


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--max-texture=")]
    sizes = [int(a.split("=")[1]) for a in sys.argv[1:] if a.startswith("--max-texture=")]
    if len(args) < 3:
        sys.exit(__doc__)
    main(args[0], args[1:-1], args[-1], sizes[0] if sizes else None)
