"""Builds the game character (.glb) from our Mixamo-ready model plus Mixamo
animation files.

  python tools/mixamo/build_character.py base.fbx anims_dir out.glb [Clip=game_name ...]

- base.fbx: the model we uploaded to Mixamo (mixamo/male_upload.fbx, made by
  make_mixamo_rig.py), T-pose, Mixamo skeleton with fingers.
- anims_dir: Mixamo downloads (FBX, Without Skin). They can come from the
  other character: every bone's rotation away from the T-pose is copied in
  world space, so different body sizes still work.
- Clip=game_name: which files to use and what the game calls them (file name
  without .fbx). With no pairs, every file is used under its own name.
  Clip@N=game_name keeps only frame N (still pose; -1 = last frame).
- Clips that walk away (not "In Place") are put back on the spot: the hips'
  steady sideways/forward drift is removed, the up/down bob stays.
Bones lose their "mixamorig:" prefix (Hips, Spine1, LeftHand, ...).
"""
import glob
import os
import sys

import bpy
from mathutils import Matrix, Vector

PREFIX = "mixamorig:"


def log(*args):
    print("[build]", *args, flush=True)


def import_fbx(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=path, automatic_bone_orientation=False)
    new = [o for o in bpy.data.objects if o not in before]
    return next(o for o in new if o.type == "ARMATURE"), new


def strip(name):
    return name[len(PREFIX):] if name.startswith(PREFIX) else name


def rest_world(arm):
    return {strip(b.name): arm.matrix_world @ b.matrix_local for b in arm.data.bones}


def bake_clip(target, src, clip_name, rest_t, rest_s, hip_ratio, still=None):
    """Copies src's action onto target as a new action called clip_name.
    still = a frame number: only that pose, held for one second."""
    scene = bpy.context.scene
    act_src = src.animation_data.action
    f0, f1 = (int(round(v)) for v in act_src.frame_range)
    order = [b.name for b in target.data.bones]  # parents come before children
    frames = list(range(f0, f1 + 1))
    if still is not None:
        f = frames[still]
        frames = [f, f]
    hips_world = []
    world = {}
    for f in frames:
        scene.frame_set(f)
        w = {}
        for pb in src.pose.bones:
            w[strip(pb.name)] = src.matrix_world @ pb.matrix
        world[f] = w
        hips_world.append(w["Hips"].to_translation())

    # Drift: straight line from the first to the last hips position (x, y)
    start, end = hips_world[0], hips_world[-1]
    span = max(len(frames) - 1, 1)

    action = bpy.data.actions.new(clip_name)
    target.animation_data_create()
    target.animation_data.action = action
    tw = target.matrix_world
    tw_inv = tw.inverted()
    for i, f in enumerate(frames):
        new_world = {}
        for name in order:
            if name not in world[f] or name not in rest_s:
                continue
            # world rotation change from the T-pose, applied to our rest
            delta = world[f][name].to_quaternion() @ rest_s[name].to_quaternion().inverted()
            rot = (delta @ rest_t[name].to_quaternion()).to_matrix().to_4x4()
            bone = target.data.bones[name]
            if bone.parent is None:
                # hips: movement away from the rest position, drift removed,
                # scaled to our body size
                offset = world[f][name].to_translation() - rest_s[name].to_translation()
                offset.x -= (end.x - start.x) * i / span + (start.x - rest_s[name].to_translation().x)
                offset.y -= (end.y - start.y) * i / span + (start.y - rest_s[name].to_translation().y)
                pos = rest_t[name].to_translation() + offset * hip_ratio
            else:
                parent_w = new_world[bone.parent.name]
                pos = parent_w @ (bone.parent.matrix_local.inverted() @ bone.matrix_local).to_translation()
            new_world[name] = Matrix.Translation(pos) @ rot
        for name, w in new_world.items():
            bone = target.data.bones[name]
            pb = target.pose.bones[name]
            arm_space = tw_inv @ w
            if bone.parent is None:
                local = bone.matrix_local.inverted() @ arm_space
            else:
                parent_arm = tw_inv @ new_world[bone.parent.name]
                local = (bone.parent.matrix_local.inverted() @ bone.matrix_local).inverted() @ parent_arm.inverted() @ arm_space
            pb.rotation_mode = "QUATERNION"
            pb.rotation_quaternion = local.to_quaternion()
            key = i * 30 if still is not None else f - f0
            pb.keyframe_insert("rotation_quaternion", frame=key)
            if bone.parent is None:
                pb.location = local.to_translation()
                pb.keyframe_insert("location", frame=key)
    target.animation_data.action = None
    track = target.animation_data.nla_tracks.new()
    track.name = clip_name
    track.strips.new(clip_name, 0, action)
    log("%-14s <- %d frames" % (clip_name, len(frames)))


def main(base, anim_dir, out, pairs):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    target, _ = import_fbx(base)
    for b in target.data.bones:
        b.name = strip(b.name)
    rest_t = rest_world(target)
    files = {os.path.splitext(os.path.basename(p))[0]: p for p in glob.glob(os.path.join(anim_dir, "*.fbx"))}
    clips = pairs or {k: k for k in sorted(files)}
    for src_name, clip_name in clips.items():
        still = None
        if "@" in src_name:
            src_name, still = src_name.split("@")
            still = int(still)
        src, new = import_fbx(files[src_name])
        rest_s = rest_world(src)
        hip_ratio = rest_t["Hips"].to_translation().z / rest_s["Hips"].to_translation().z
        bake_clip(target, src, clip_name, rest_t, rest_s, hip_ratio, still)
        for o in new:
            bpy.data.objects.remove(o)
    for pb in target.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_animation_mode="NLA_TRACKS",
                              export_image_format="JPEG", export_jpeg_quality=90,
                              export_def_bones=False, export_optimize_animation_size=True)
    log("wrote", out)


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    if len(args) < 3:
        sys.exit(__doc__)
    pairs = dict(a.split("=", 1) for a in args[3:])
    main(args[0], args[1], args[2], pairs)
