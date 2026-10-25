"""Turns a Meshy rigged character into a Mixamo-ready one, with finger bones.

  python tools/mixamo/make_mixamo_rig.py rigged.glb out.fbx      (Python with the `bpy` package)

Mixamo's auto-rigger needs markers dragged onto the body, which does not
work on phones. A character that already has Mixamo's skeleton skips that
step: upload it, pick animations, download. This script:
  1. renames Meshy's bones to Mixamo's (mixamorig:Hips, ...),
  2. finds the five fingers in each hand's mesh and adds Mixamo's finger
     bones (Thumb/Index/Middle/Ring/Pinky 1-4), so animations can close
     the hands around a gun,
  3. moves the finger skin from the hand bone to the finger bones,
  4. makes T-pose the rest pose (what Mixamo expects) and exports FBX.
Works best on models with open hands and spread fingers.
"""
import math
import sys

import bpy
import numpy as np
from mathutils import Matrix, Vector

# Meshy bone -> Mixamo bone. Note Meshy counts the spine top-down.
RENAME = {
    "Hips": "Hips", "Spine02": "Spine", "Spine01": "Spine1", "Spine": "Spine2",
    "neck": "Neck", "Head": "Head", "head_end": "HeadTop_End",
    "LeftShoulder": "LeftShoulder", "LeftArm": "LeftArm", "LeftForeArm": "LeftForeArm", "LeftHand": "LeftHand",
    "RightShoulder": "RightShoulder", "RightArm": "RightArm", "RightForeArm": "RightForeArm", "RightHand": "RightHand",
    "LeftUpLeg": "LeftUpLeg", "LeftLeg": "LeftLeg", "LeftFoot": "LeftFoot", "LeftToeBase": "LeftToeBase",
    "RightUpLeg": "RightUpLeg", "RightLeg": "RightLeg", "RightFoot": "RightFoot", "RightToeBase": "RightToeBase",
    "LeftToe_End": "LeftToe_End", "RightToe_End": "RightToe_End",
}
FINGERS = ["Thumb", "Index", "Middle", "Ring", "Pinky"]
PREFIX = "mixamorig:"


def log(*args):
    print("[mixamo-rig]", *args, flush=True)


def load(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    for o in list(bpy.data.objects):
        if o.type == "MESH" and o.parent is None:  # importer's bone-shape sphere
            bpy.data.objects.remove(o)
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    mesh = next(o for o in bpy.data.objects if o.type == "MESH")
    # Bake the armature's 0.01 scale into the data: everything in metres
    bpy.ops.object.select_all(action="DESELECT")
    for o in (arm, mesh):
        o.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return arm, mesh


def mesh_arrays(mesh):
    co = np.array([v.co[:] for v in mesh.data.vertices])
    weights = {g.name: np.zeros(len(co)) for g in mesh.vertex_groups}
    names = {g.index: g.name for g in mesh.vertex_groups}
    for v in mesh.data.vertices:
        for g in v.groups:
            weights[names[g.group]][v.index] = g.weight
    return co, weights


def kmeans(points, k, iters=40):
    # deterministic start: spread along the first axis
    order = np.argsort(points[:, 0])
    centers = points[order[np.linspace(0, len(points) - 1, k).astype(int)]].copy()
    for _ in range(iters):
        labels = np.argmin(((points[:, None, :] - centers[None]) ** 2).sum(-1), axis=1)
        for i in range(k):
            if np.any(labels == i):
                centers[i] = points[labels == i].mean(0)
    return labels, centers


def find_fingers(co, hand_w, wrist, elbow, side):
    """Finger chains (base -> tip points) found in the hand's vertices."""
    pts = co[hand_w > 0.5]
    a = pts.mean(0) - wrist
    a /= np.linalg.norm(a)  # wrist -> palm direction
    rel = pts - wrist
    t = rel @ a
    flat = rel - np.outer(t, a)
    # palm width direction = main spread of the hand across `a`
    _, _, vt = np.linalg.svd(flat - flat.mean(0), full_matrices=False)
    lat = vt[0]
    nrm = np.cross(a, lat)
    reach = t.max()
    log(side, "hand length %.3f m, %d vertices" % (reach, len(pts)))
    # fingers live in the outer part of the hand (thumb starts lower)
    outer = t > reach * 0.42
    feat = np.stack([rel[outer] @ lat, rel[outer] @ nrm * 0.6, t[outer] * 0.15], 1)
    labels, centers = kmeans(feat, 5)
    chains = []
    for i in range(5):
        sel = rel[outer][labels == i]
        if len(sel) < 10:
            continue
        ts = sel @ a
        base_t, tip_t = np.percentile(ts, 3), np.percentile(ts, 99.5)
        def along(tt, sel=sel, ts=ts):
            near = sel[np.abs(ts - tt) < (tip_t - base_t) * 0.12]
            return wrist + (near.mean(0) if len(near) else sel.mean(0))
        chains.append({"base": along(base_t), "tip": along(tip_t), "lat": float(centers[i][0]),
                       "low": float(base_t), "depth": float(np.mean(sel @ nrm))})
    # thumb = the chain that starts lowest on the hand; the rest by width
    chains.sort(key=lambda c: c["low"])
    thumb, others = chains[0], chains[1:]
    # index is next to the thumb
    others.sort(key=lambda c: abs(c["lat"] - thumb["lat"]))
    named = [thumb] + others
    out = {}
    for name, c in zip(FINGERS, named):
        base, tip = Vector(c["base"]), Vector(c["tip"])
        out[name] = [base.lerp(tip, f) for f in (0.0, 0.45, 0.75, 1.0)]
    # Only the outer half of the thumb is in its cluster (its root is in the
    # palm), so its joints are placed like a real thumb's: the root bone
    # starts near the wrist on the thumb side, then knuckle, joint, tip
    # (proportions of the hand's length)
    tip, base = Vector(thumb["tip"]), Vector(thumb["base"])
    out_dir = (tip - base).normalized()
    side_dir = Vector(lat) * (1.0 if thumb["lat"] > 0 else -1.0)
    finger_depth = np.mean([c["depth"] for c in others])
    palm_dir = Vector(nrm) * (1.0 if thumb["depth"] > finger_depth else -1.0)
    joint = tip - out_dir * reach * 0.15
    knuckle = joint - out_dir * reach * 0.17
    root = Vector(wrist) + Vector(a) * reach * 0.12 + side_dir * reach * 0.07 + palm_dir * reach * 0.04
    out["Thumb"] = [root, knuckle, joint, tip]
    log(side, "thumb bones %.3f %.3f %.3f m" % ((knuckle - root).length, (joint - knuckle).length,
                                                (tip - joint).length))
    return out, a


def add_finger_bones(arm, co, weights):
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.data.edit_bones
    made = {}
    for side in ("Left", "Right"):
        hand = eb[side + "Hand"]
        wrist = np.array(hand.head[:])
        elbow = np.array(eb[side + "ForeArm"].head[:])
        fingers, a = find_fingers(co, weights[side + "Hand"], wrist, elbow, side)
        # the hand bone points at the middle finger's knuckle
        hand.tail = fingers["Middle"][0]
        for name, pts in fingers.items():
            parent = hand
            for j in range(3):
                b = eb.new("%s%s%d" % (side, "Hand" + name, j + 1))
                b.head, b.tail = pts[j], pts[j + 1]
                b.parent = parent
                b.use_connect = j > 0
                b.roll = hand.roll
                parent = b
                made[b.name] = (np.array(pts[j][:]), np.array(pts[j + 1][:]))
            end = eb.new("%sHand%s4" % (side, name))
            end.head = pts[3]
            end.tail = pts[3] + (pts[3] - pts[2]) * 0.5
            end.parent = parent
            end.use_connect = True
        # Mixamo also has a leaf bone past each toe
        toe = eb[side + "ToeBase"]
        ahead = toe.head - eb[side + "Foot"].head
        ahead.z = 0
        tip = eb.new(side + "Toe_End")
        tip.head = toe.head + ahead.normalized() * 0.07
        tip.tail = tip.head + ahead.normalized() * 0.03
        tip.parent = toe
        toe.tail = tip.head
    bpy.ops.object.mode_set(mode="OBJECT")
    return made


def seg_dist(p, a, b):
    ab = b - a
    t = np.clip(((p - a) @ ab) / max(ab @ ab, 1e-9), 0, 1)
    return np.linalg.norm(p - (a + np.outer(t, ab)), axis=1)


def skin_fingers(mesh, co, weights, finger_bones, arm):
    """Splits each hand bone's weight between the palm and the finger bones
    by distance (closest bone wins, smooth near joints)."""
    for side in ("Left", "Right"):
        hw = weights[side + "Hand"]
        idx = np.where(hw > 0.001)[0]
        p = co[idx]
        hb = arm.data.bones[side + "Hand"]
        palm = seg_dist(p, np.array(hb.head_local[:]), np.array(hb.tail_local[:]))
        names = [n for n in finger_bones if n.startswith(side)]
        d = np.stack([palm] + [seg_dist(p, *finger_bones[n]) for n in names], 1)
        inv = 1.0 / np.maximum(d, 0.002) ** 6
        share = inv / inv.sum(1, keepdims=True)
        groups = [mesh.vertex_groups[side + "Hand"]] + [mesh.vertex_groups.new(name=n) for n in names]
        for col, g in enumerate(groups):
            w = share[:, col] * hw[idx]
            for vi, wv in zip(idx, w):
                if wv > 0.002:
                    g.add([int(vi)], float(wv), "REPLACE")
                elif col == 0:
                    g.remove([int(vi)])


def merge_group(mesh, src, dst):
    if src not in mesh.vertex_groups:
        return
    s, d = mesh.vertex_groups[src], mesh.vertex_groups[dst]
    for v in mesh.data.vertices:
        for g in v.groups:
            if g.group == s.index:
                d.add([v.index], g.weight, "ADD")
    mesh.vertex_groups.remove(s)


def to_t_pose(arm, mesh):
    """Arms straight out to the sides (+X / -X), then that becomes the rest pose."""
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    for side, out in (("Left", Vector((1, 0, 0))), ("Right", Vector((-1, 0, 0)))):
        for bone in ("Arm", "ForeArm", "Hand"):
            pb = arm.pose.bones[side + bone]
            bpy.context.view_layer.update()
            head = arm.matrix_world @ pb.head
            nxt = {"Arm": "ForeArm", "ForeArm": "Hand", "Hand": None}[bone]
            tail = arm.matrix_world @ (arm.pose.bones[side + nxt].head if nxt else pb.tail)
            cur = (tail - head).normalized()
            rot = cur.rotation_difference(out)
            mat = pb.matrix.copy()
            loc = mat.to_translation()
            pb.matrix = Matrix.Translation(loc) @ rot.to_matrix().to_4x4() @ Matrix.Translation(-loc) @ mat
            bpy.context.view_layer.update()
    bpy.ops.object.mode_set(mode="OBJECT")
    # bake the posed mesh, then make the pose the new rest
    bpy.context.view_layer.objects.active = mesh
    mod = next(m for m in mesh.modifiers if m.type == "ARMATURE")
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.armature_apply(selected=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    m = mesh.modifiers.new("Armature", "ARMATURE")
    m.object = arm


def lighten_textures(max_size=2048):
    """Smaller upload: no normal map (we drop it in the game too), textures
    at most 2K."""
    for mat in bpy.data.materials:
        if not mat.use_nodes:
            continue
        for node in list(mat.node_tree.nodes):
            if node.type == "NORMAL_MAP":
                mat.node_tree.nodes.remove(node)
    for img in bpy.data.images:
        if img.size[0] > max_size:
            img.scale(max_size, max_size * img.size[1] // img.size[0])


def main(src, out):
    arm, mesh = load(src)
    lighten_textures()
    co, weights = mesh_arrays(mesh)
    merge_group(mesh, "headfront", "Head")
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    arm.data.edit_bones.remove(arm.data.edit_bones["headfront"])
    bpy.ops.object.mode_set(mode="OBJECT")
    finger_bones = add_finger_bones(arm, co, weights)
    skin_fingers(mesh, co, weights, finger_bones, arm)
    to_t_pose(arm, mesh)
    # Mixamo names (vertex groups follow bone renames)
    for b in arm.data.bones:
        b.name = PREFIX + RENAME.get(b.name, b.name)
    arm.name = "Armature"
    arm.data.name = "Armature"
    mesh.name = "Body"
    log("bones:", len(arm.data.bones))
    bpy.ops.export_scene.fbx(filepath=out, use_selection=False, object_types={"ARMATURE", "MESH"},
                             add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True,
                             mesh_smooth_type="FACE")
    log("wrote", out)


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    if len(args) != 2:
        sys.exit(__doc__)
    main(*args)
