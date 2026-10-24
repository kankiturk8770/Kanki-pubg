"""Builds the soldier character with Blender and saves it as a .glb file.

Run (needs Blender 4.2+ or the "bpy" Python package):
    blender --background --python tools/blender/make_soldier.py
    # or:  python tools/blender/make_soldier.py

Output: assets/characters/soldier.glb
  - one skinned mesh, one skeleton
  - animations: idle, run, crouch_idle, crouch_walk, jump, death
  - bone "muzzle" marks the end of the rifle barrel (for bullet effects)
  - material "Vest" is tinted per team inside the game

The character stands at the origin, faces -Y (Blender front), 1.8 m tall.
"""

import math
import os

import bpy  # must come before bmesh/mathutils
import bmesh
from mathutils import Matrix, Quaternion, Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "characters", "soldier.glb")
FPS = 30

# ------------------------------------------------------------------ helpers

MATERIALS = {}


def material(name, color, rough=0.8, metal=0.0):
    if name in MATERIALS:
        return MATERIALS[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    MATERIALS[name] = m
    return m


def srgb(hex_color):
    """Hex colour -> linear RGB tuple (Blender works in linear)."""
    h = hex_color.lstrip("#")
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255.0
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return tuple(out)


PARTS = []  # (object, bone name)


def _finish(obj, bone, mat, smooth=True, subdiv=0, bevel=0.0):
    if bevel > 0:
        mod = obj.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    if subdiv > 0:
        mod = obj.modifiers.new("subd", "SUBSURF")
        mod.levels = subdiv
        mod.render_levels = subdiv
    obj.data.materials.append(mat)
    if smooth:
        for p in obj.data.polygons:
            p.use_smooth = True
    PARTS.append((obj, bone))
    return obj


def box(name, center, size, bone, mat, rot=(0, 0, 0), bevel=0.01, subdiv=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    return _finish(o, bone, mat, smooth=subdiv > 0, subdiv=subdiv, bevel=bevel)


def ball(name, center, radii, bone, mat, segments=20, rings=12, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1, location=center, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = radii
    bpy.ops.object.transform_apply(scale=True)
    return _finish(o, bone, mat)


def tube(name, a, b, ra, rb, bone, mat, sides=14, rings=4, squash=1.0, caps=True):
    """Tapered tube from point a (radius ra) to point b (radius rb)."""
    a, b = Vector(a), Vector(b)
    axis = (b - a).normalized()
    helper = Vector((0, 0, 1)) if abs(axis.z) < 0.9 else Vector((0, 1, 0))
    u = axis.cross(helper).normalized()
    v = axis.cross(u).normalized()
    bm = bmesh.new()
    loops = []
    for i in range(rings + 1):
        t = i / rings
        c = a.lerp(b, t)
        # slightly fuller in the middle, like a muscle/padded sleeve
        r = ra + (rb - ra) * t
        r *= 1.0 + 0.08 * math.sin(math.pi * t)
        loop = []
        for s in range(sides):
            ang = 2 * math.pi * s / sides
            loop.append(bm.verts.new(c + u * math.cos(ang) * r + v * math.sin(ang) * r * squash))
        loops.append(loop)
    for i in range(rings):
        for s in range(sides):
            s2 = (s + 1) % sides
            bm.faces.new((loops[i][s], loops[i][s2], loops[i + 1][s2], loops[i + 1][s]))
    if caps:
        bm.faces.new(list(reversed(loops[0])))
        bm.faces.new(loops[-1])
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    return _finish(o, bone, mat)


def cylinder(name, a, b, r, bone, mat, sides=16):
    return tube(name, a, b, r, r, bone, mat, sides=sides, rings=1)


# ------------------------------------------------------------------ scene

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.fps = FPS

SKIN = material("Skin", srgb("#c58c68"), 0.6)
CLOTH = material("Uniform", srgb("#4a4f3a"), 0.95)      # olive combat shirt/pants
CLOTH_DARK = material("UniformDark", srgb("#33372a"), 0.95)
VEST = material("Vest", srgb("#5a5f4c"), 0.85)          # tinted per team in game
GEAR = material("Gear", srgb("#2b2b27"), 0.75)          # pouches, belt, straps
BOOT = material("Boots", srgb("#2a211b"), 0.7)
GLOVE = material("Gloves", srgb("#1d1d1d"), 0.7)
HELMET = material("Helmet", srgb("#4b5040"), 0.6)
MASK = material("Mask", srgb("#2e2f2c"), 0.9)
LENS = material("Lens", srgb("#20262b"), 0.1, 0.6)
METAL = material("GunMetal", srgb("#1b1c1e"), 0.35, 0.8)
POLYMER = material("GunPolymer", srgb("#2a2b2c"), 0.6)
TAN = material("GunTan", srgb("#8b7a5c"), 0.6)

# ------------------------------------------------------------------ skeleton
# Rest pose = holding the rifle at the shoulder (arms never need IK).

J = {
    "hips": ((0, 0, 0.95), (0, 0, 1.05)),
    "spine": ((0, 0, 1.05), (0, 0, 1.28)),
    "chest": ((0, 0, 1.28), (0, 0, 1.5)),
    "neck": ((0, 0, 1.5), (0, 0, 1.6)),
    "head": ((0, 0, 1.6), (0, 0, 1.85)),
    # right arm (character's right is -X): hand on the pistol grip
    "upper_arm.R": ((-0.2, 0.0, 1.44), (-0.27, -0.06, 1.2)),
    "forearm.R": ((-0.27, -0.06, 1.2), (-0.14, -0.2, 1.27)),
    "hand.R": ((-0.14, -0.2, 1.27), (-0.12, -0.27, 1.27)),
    # left arm: hand on the handguard
    "upper_arm.L": ((0.2, 0.0, 1.44), (0.17, -0.22, 1.24)),
    "forearm.L": ((0.17, -0.22, 1.24), (-0.07, -0.45, 1.3)),
    "hand.L": ((-0.07, -0.45, 1.3), (-0.1, -0.52, 1.31)),
    "thigh.L": ((0.1, 0, 0.94), (0.1, -0.01, 0.52)),
    "shin.L": ((0.1, -0.01, 0.52), (0.1, 0.02, 0.1)),
    "foot.L": ((0.1, 0.02, 0.1), (0.1, -0.13, 0.03)),
    "thigh.R": ((-0.1, 0, 0.94), (-0.1, -0.01, 0.52)),
    "shin.R": ((-0.1, -0.01, 0.52), (-0.1, 0.02, 0.1)),
    "foot.R": ((-0.1, 0.02, 0.1), (-0.1, -0.13, 0.03)),
    "muzzle": ((-0.12, -0.86, 1.385), (-0.12, -0.92, 1.385)),
}
PARENT = {
    "spine": "hips", "chest": "spine", "neck": "chest", "head": "neck",
    "upper_arm.R": "chest", "forearm.R": "upper_arm.R", "hand.R": "forearm.R",
    "upper_arm.L": "chest", "forearm.L": "upper_arm.L", "hand.L": "forearm.L",
    "thigh.L": "hips", "shin.L": "thigh.L", "foot.L": "shin.L",
    "thigh.R": "hips", "shin.R": "thigh.R", "foot.R": "shin.R",
    "muzzle": "chest",
}

arm_data = bpy.data.armatures.new("SoldierRig")
rig = bpy.data.objects.new("Soldier", arm_data)
bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
for name, (h, t) in J.items():
    eb = arm_data.edit_bones.new(name)
    eb.head = h
    eb.tail = t
    eb.roll = 0
for name, parent in PARENT.items():
    eb = arm_data.edit_bones[name]
    eb.parent = arm_data.edit_bones[parent]
    eb.use_connect = False
bpy.ops.object.mode_set(mode="OBJECT")


def P(name, t=1.0):
    h, tl = J[name]
    return Vector(h).lerp(Vector(tl), t)


# ------------------------------------------------------------------ body

# Legs: trousers, knee pads, boots
for s, side in ((1, "L"), (-1, "R")):
    th = "thigh." + side
    sh = "shin." + side
    ft = "foot." + side
    tube("Thigh" + side, P(th, 0) + Vector((0, 0, 0.04)), P(th, 1), 0.095, 0.07, th, CLOTH, squash=1.1)
    ball("Knee" + side, P(sh, 0), (0.07, 0.07, 0.07), th, CLOTH)
    tube("Shin" + side, P(sh, 0), P(sh, 1) + Vector((0, 0, 0.05)), 0.066, 0.052, sh, CLOTH)
    box("KneePad" + side, P(sh, 0.06) + Vector((0, -0.065, 0)), (0.1, 0.05, 0.13), sh, GEAR, bevel=0.02)
    # thigh pocket (cargo)
    box("Cargo" + side, P(th, 0.55) + Vector((s * 0.085, -0.01, 0)), (0.035, 0.12, 0.14), th, CLOTH_DARK, bevel=0.012)
    # boot: ankle + foot
    tube("Ankle" + side, P(sh, 0.82), P(sh, 1) + Vector((0, 0, -0.05)), 0.058, 0.062, sh, BOOT)
    box("Boot" + side, P(ft, 0.45) + Vector((0, 0.0, -0.005)), (0.11, 0.29, 0.085), ft, BOOT, bevel=0.03)
    box("Sole" + side, P(ft, 0.45) + Vector((0, 0.0, -0.045)), (0.115, 0.3, 0.02), ft, GEAR, bevel=0.005)

# Pelvis, belt and pouches
box("Pelvis", (0, 0.0, 0.95), (0.34, 0.21, 0.2), "hips", CLOTH, bevel=0.06, subdiv=1)
box("Belt", (0, 0.0, 1.04), (0.36, 0.23, 0.06), "hips", GEAR, bevel=0.015)
box("BeltBuckle", (0, -0.118, 1.04), (0.07, 0.01, 0.045), "hips", METAL, bevel=0.004)
for x in (-0.15, 0.15):
    box("HipPouch", (x, 0.04, 0.98), (0.07, 0.12, 0.12), "hips", GEAR, bevel=0.015)
box("Holster", (-0.19, 0.0, 0.88), (0.05, 0.1, 0.2), "hips", GEAR, bevel=0.015)

# Torso: shirt, tactical vest, pouches, backpack
box("Waist", (0, 0, 1.17), (0.32, 0.2, 0.25), "spine", CLOTH, bevel=0.07, subdiv=1)
box("Chest", (0, 0, 1.37), (0.4, 0.23, 0.3), "chest", CLOTH, bevel=0.08, subdiv=1)
box("Vest", (0, -0.005, 1.29), (0.38, 0.27, 0.34), "chest", VEST, bevel=0.03)
box("VestCollar", (0, 0.02, 1.47), (0.3, 0.2, 0.06), "chest", VEST, bevel=0.02)
for x in (-0.11, 0.0, 0.11):
    box("MagPouch", (x, -0.155, 1.2), (0.085, 0.05, 0.13), "chest", GEAR, bevel=0.012)
    box("MagPouchFlap", (x, -0.158, 1.27), (0.09, 0.055, 0.025), "chest", VEST, bevel=0.006)
box("RadioPouch", (0.15, -0.14, 1.37), (0.06, 0.05, 0.11), "chest", GEAR, bevel=0.01)
box("Antenna", (0.16, -0.14, 1.5), (0.008, 0.008, 0.16), "chest", METAL, bevel=0.0)
box("Patch", (-0.13, -0.142, 1.38), (0.08, 0.01, 0.06), "chest", CLOTH_DARK, bevel=0.004)
for x in (-0.13, 0.13):
    box("Strap", (x, 0.0, 1.47), (0.06, 0.29, 0.02), "chest", GEAR, bevel=0.005)
box("Pack", (0, 0.2, 1.28), (0.32, 0.14, 0.4), "chest", GEAR, bevel=0.04, subdiv=1)
box("PackTop", (0, 0.2, 1.5), (0.28, 0.13, 0.06), "chest", CLOTH_DARK, bevel=0.025)
box("PackPouch", (0, 0.285, 1.22), (0.22, 0.05, 0.18), "chest", VEST, bevel=0.02)

# Neck and head: balaclava, goggles, helmet with NVG mount
tube("Neck", P("neck", 0) - Vector((0, 0, 0.03)), P("neck", 1), 0.068, 0.062, "neck", MASK)
ball("Head", (0, -0.01, 1.7), (0.105, 0.118, 0.13), "head", MASK, segments=24, rings=16)
ball("Nose", (0, -0.115, 1.69), (0.022, 0.02, 0.03), "head", MASK)
ball("EyeSkin", (0, -0.09, 1.728), (0.088, 0.05, 0.036), "head", SKIN)
box("GogglesFrame", (0, -0.1, 1.735), (0.17, 0.035, 0.05), "head", GEAR, bevel=0.012)
box("GogglesLens", (0, -0.118, 1.735), (0.15, 0.01, 0.038), "head", LENS, bevel=0.006)
box("GogglesBand", (0, 0.0, 1.74), (0.205, 0.22, 0.025), "head", GEAR, bevel=0.01)
ball("Helmet", (0, 0.0, 1.765), (0.128, 0.142, 0.11), "head", HELMET, segments=28, rings=16)
box("HelmetRim", (0, 0.005, 1.74), (0.25, 0.28, 0.03), "head", HELMET, bevel=0.012, subdiv=1)
box("NVGMount", (0, -0.13, 1.81), (0.05, 0.03, 0.04), "head", METAL, bevel=0.006)
for x in (-0.115, 0.115):
    box("HelmetRail", (x, -0.02, 1.775), (0.02, 0.12, 0.022), "head", GEAR, bevel=0.005)
box("HelmetLight", (0.12, 0.03, 1.79), (0.025, 0.05, 0.025), "head", METAL, bevel=0.005)
box("EarPro", (-0.105, 0.005, 1.7), (0.03, 0.07, 0.08), "head", GEAR, bevel=0.015)
box("EarPro", (0.105, 0.005, 1.7), (0.03, 0.07, 0.08), "head", GEAR, bevel=0.015)

# Arms: shoulder pads, sleeves, elbow pads, gloves
for side in ("L", "R"):
    ua = "upper_arm." + side
    fa = "forearm." + side
    hd = "hand." + side
    ball("Shoulder" + side, P(ua, 0), (0.075, 0.075, 0.075), "chest", CLOTH)
    tube("UpperArm" + side, P(ua, 0), P(ua, 1), 0.063, 0.05, ua, CLOTH)
    ball("Elbow" + side, P(fa, 0), (0.05, 0.05, 0.05), ua, CLOTH)
    box("ElbowPad" + side, P(fa, 0.05) + (P(ua, 0.8) - P(fa, 0.3)).normalized() * 0.03,
        (0.07, 0.07, 0.07), ua, GEAR, bevel=0.02)
    tube("Forearm" + side, P(fa, 0), P(fa, 1), 0.05, 0.04, fa, CLOTH)
    tube("Cuff" + side, P(fa, 0.85), P(fa, 1.0) + (P(fa, 1) - P(fa, 0)).normalized() * 0.01,
         0.044, 0.042, fa, GLOVE)
    ball("Hand" + side, P(hd, 0.4), (0.045, 0.05, 0.035), hd, GLOVE, rot=(0.4, 0, 0))

# Rifle (an original carbine design - receiver, rails, red dot, magazine, stock)
GX, GZ = -0.12, 1.385
box("Receiver", (GX, -0.3, GZ), (0.055, 0.34, 0.085), "chest", METAL, bevel=0.006)
box("TopRail", (GX, -0.36, GZ + 0.05), (0.03, 0.42, 0.015), "chest", METAL, bevel=0.002)
box("Handguard", (GX, -0.6, GZ + 0.005), (0.06, 0.26, 0.07), "chest", TAN, bevel=0.012)
for i in range(6):
    box("Vent", (GX - 0.031, -0.5 - i * 0.04, GZ + 0.005), (0.004, 0.022, 0.035), "chest", METAL, bevel=0.0)
    box("Vent", (GX + 0.031, -0.5 - i * 0.04, GZ + 0.005), (0.004, 0.022, 0.035), "chest", METAL, bevel=0.0)
cylinder("Barrel", (GX, -0.72, GZ + 0.01), (GX, -0.83, GZ + 0.01), 0.013, "chest", METAL)
cylinder("MuzzleBrake", (GX, -0.82, GZ + 0.01), (GX, -0.87, GZ + 0.01), 0.02, "chest", METAL)
box("Magazine", (GX, -0.3, GZ - 0.11), (0.035, 0.08, 0.17), "chest", POLYMER, rot=(-0.25, 0, 0), bevel=0.008)
box("Grip", (GX, -0.2, GZ - 0.085), (0.035, 0.05, 0.11), "chest", POLYMER, rot=(0.35, 0, 0), bevel=0.01)
box("TriggerGuard", (GX, -0.25, GZ - 0.06), (0.012, 0.06, 0.012), "chest", METAL, bevel=0.0)
box("ForeGrip", (GX, -0.56, GZ - 0.07), (0.03, 0.03, 0.08), "chest", POLYMER, bevel=0.008)
box("Buffer", (GX, -0.08, GZ + 0.005), (0.035, 0.12, 0.035), "chest", METAL, bevel=0.005)
box("Stock", (GX, 0.02, GZ - 0.015), (0.045, 0.13, 0.09), "chest", TAN, bevel=0.015)
box("ButtPad", (GX, 0.09, GZ - 0.015), (0.05, 0.015, 0.1), "chest", POLYMER, bevel=0.005)
box("RedDotBase", (GX, -0.33, GZ + 0.07), (0.035, 0.06, 0.025), "chest", METAL, bevel=0.004)
cylinder("RedDot", (GX, -0.36, GZ + 0.1), (GX, -0.3, GZ + 0.1), 0.022, "chest", METAL)
box("ChargingHandle", (GX, -0.15, GZ + 0.045), (0.05, 0.02, 0.012), "chest", METAL, bevel=0.002)
box("Sling", (GX + 0.03, -0.25, GZ - 0.02), (0.008, 0.5, 0.02), "chest", GEAR, bevel=0.0)

# ------------------------------------------------------------------ skin & join

bpy.ops.object.select_all(action="DESELECT")
for obj, bone in PARTS:
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    for mod in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.select_set(False)
    vg = obj.vertex_groups.new(name=bone)
    vg.add([v.index for v in obj.data.vertices], 1.0, "REPLACE")

for obj, _ in PARTS:
    obj.select_set(True)
body = PARTS[0][0]
bpy.context.view_layer.objects.active = body
bpy.ops.object.join()
body.name = "SoldierMesh"
body.data.name = "SoldierMesh"
body.parent = rig
mod = body.modifiers.new("Armature", "ARMATURE")
mod.object = rig

# ------------------------------------------------------------------ animation

pose = rig.pose
rig.rotation_mode = "XYZ"


def local_axis(bone_name, world_axis):
    m = rig.data.bones[bone_name].matrix_local.to_3x3()
    return (m.inverted() @ Vector(world_axis)).normalized()


def rot_x(bone_name, deg):
    """Rotation of a bone around the character's left-right axis.
    Positive = leg/arm swings backwards, spine leans forwards."""
    return Quaternion(local_axis(bone_name, (1, 0, 0)), math.radians(deg))


def loc(bone_name, world_offset):
    m = rig.data.bones[bone_name].matrix_local.to_3x3()
    return m.inverted() @ Vector(world_offset)


ANIM_BONES = ["hips", "spine", "chest", "neck", "head",
              "thigh.L", "shin.L", "foot.L", "thigh.R", "shin.R", "foot.R"]


def make_action(name, keys, loop=True):
    """keys: {frame: {bone: {"x": degrees, "loc": (x, y, z)}}}"""
    act = bpy.data.actions.new(name)
    rig.animation_data_create()
    rig.animation_data.action = act
    frames = sorted(keys)
    for f in frames:
        for b in ANIM_BONES:
            pb = pose.bones[b]
            pb.rotation_mode = "QUATERNION"
            spec = keys[f].get(b, {})
            pb.rotation_quaternion = rot_x(b, spec.get("x", 0.0))
            pb.location = loc(b, spec.get("loc", (0, 0, 0)))
            pb.keyframe_insert("rotation_quaternion", frame=f, group=b)
            pb.keyframe_insert("location", frame=f, group=b)
    track = rig.animation_data.nla_tracks.new()
    track.name = name
    strip = track.strips.new(name, int(frames[0]), act)
    strip.name = name
    rig.animation_data.action = None
    return act


def legs(tl, sl, fl, tr, sr, fr):
    return {
        "thigh.L": {"x": tl}, "shin.L": {"x": sl}, "foot.L": {"x": fl},
        "thigh.R": {"x": tr}, "shin.R": {"x": sr}, "foot.R": {"x": fr},
    }


def pose_keys(base, **extra):
    d = dict(base)
    d.update(extra)
    return d


# idle: slow breathing
make_action("idle", {
    1: pose_keys(legs(-4, 6, -2, 3, 4, -7), hips={"loc": (0, 0, -0.01)}, chest={"x": 0}),
    31: pose_keys(legs(-4, 7, -3, 3, 5, -8), hips={"loc": (0, 0, -0.018)}, chest={"x": 1.5}),
    61: pose_keys(legs(-4, 6, -2, 3, 4, -7), hips={"loc": (0, 0, -0.01)}, chest={"x": 0}),
})

# run: 20 frames per two steps
lean = {"spine": {"x": 8}, "chest": {"x": 4}}
make_action("run", {
    1: pose_keys(legs(-32, 15, 10, 28, 25, -5), hips={"loc": (0, 0, -0.04)}, **lean),
    6: pose_keys(legs(-5, 25, -5, 5, 85, -10), hips={"loc": (0, 0, 0.0)}, **lean),
    11: pose_keys(legs(28, 25, -5, -32, 15, 10), hips={"loc": (0, 0, -0.04)}, **lean),
    16: pose_keys(legs(5, 85, -10, -5, 25, -5), hips={"loc": (0, 0, 0.0)}, **lean),
    21: pose_keys(legs(-32, 15, 10, 28, 25, -5), hips={"loc": (0, 0, -0.04)}, **lean),
})

# crouch: hips 35 cm lower, knees bent forward, feet flat
crouch_lean = {"spine": {"x": 14}, "chest": {"x": 6}, "neck": {"x": -12}}
make_action("crouch_idle", {
    1: pose_keys(legs(-72, 104, -32, -55, 115, -60), hips={"loc": (0, 0.05, -0.36)}, **crouch_lean),
    41: pose_keys(legs(-72, 106, -34, -55, 117, -62), hips={"loc": (0, 0.05, -0.37)}, **crouch_lean),
    81: pose_keys(legs(-72, 104, -32, -55, 115, -60), hips={"loc": (0, 0.05, -0.36)}, **crouch_lean),
})
make_action("crouch_walk", {
    1: pose_keys(legs(-85, 100, -15, -45, 115, -70), hips={"loc": (0, 0.05, -0.34)}, **crouch_lean),
    13: pose_keys(legs(-65, 120, -55, -70, 95, -25), hips={"loc": (0, 0.05, -0.36)}, **crouch_lean),
    25: pose_keys(legs(-45, 115, -70, -85, 100, -15), hips={"loc": (0, 0.05, -0.34)}, **crouch_lean),
    37: pose_keys(legs(-70, 95, -25, -65, 120, -55), hips={"loc": (0, 0.05, -0.36)}, **crouch_lean),
    49: pose_keys(legs(-85, 100, -15, -45, 115, -70), hips={"loc": (0, 0.05, -0.34)}, **crouch_lean),
})

# jump: legs tucked
make_action("jump", {
    1: pose_keys(legs(-45, 80, -10, -20, 60, 0), spine={"x": 6}),
    11: pose_keys(legs(-50, 90, -10, -25, 70, 0), spine={"x": 8}),
})

# death: knees give way, then falls on the back
make_action("death", {
    1: pose_keys(legs(0, 0, 0, 0, 0, 0)),
    8: pose_keys(legs(-30, 60, 0, -10, 50, 0), hips={"loc": (0, 0.05, -0.25)}, spine={"x": -10}, head={"x": 10}),
    20: pose_keys(legs(-35, 45, 10, -20, 35, 5), hips={"x": -60, "loc": (0, 0.35, -0.6)},
                  spine={"x": -10}, head={"x": -15}),
    30: pose_keys(legs(-8, 10, 25, -16, 14, 20), hips={"x": -88, "loc": (0, 0.55, -0.8)},
                  spine={"x": -2}, head={"x": -25}),
    60: pose_keys(legs(-8, 10, 25, -16, 14, 20), hips={"x": -88, "loc": (0, 0.55, -0.8)},
                  spine={"x": -2}, head={"x": -25}),
}, loop=False)

for b in pose.bones:
    b.rotation_quaternion = Quaternion()
    b.location = Vector()

# ------------------------------------------------------------------ export

os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(
    filepath=OUT,
    export_format="GLB",
    use_selection=True,
    export_animations=True,
    export_animation_mode="NLA_TRACKS",
    export_force_sampling=True,
    export_frame_range=False,
    export_apply=False,
    export_yup=True,
)
tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
print("Saved %s (%d triangles)" % (OUT, tris))
