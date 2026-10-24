"""Builds the map props with Blender and saves each one as a .glb file.

Run:  python tools/blender/make_props.py   (or blender --background --python ...)

Output in assets/props/:
  container_<color>.glb  20ft shipping container  6.06 x 2.59 x 2.44 m  (long side = X)
  crate.glb              wooden crate             1.2 m cube
  barrel.glb             oil barrel               0.6 m wide, 0.9 m tall
  barrier.glb            concrete jersey barrier  2.0 x 0.8 x 0.6 m   (long side = X)
  pillar.glb             steel I-beam pillar      0.5 x 7 x 0.5 m
Every prop sits on the ground (y = 0) and is centred on X/Z.
"""

import math
import os

import bpy  # must come before bmesh/mathutils
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(ROOT, "assets", "props")


def srgb(hex_color):
    h = hex_color.lstrip("#")
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255.0
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return tuple(out)


def material(name, hex_color, rough=0.8, metal=0.0):
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*srgb(hex_color), 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    return m


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def box(center, size, mat, bevel=0.0, rot=(0, 0, 0)):
    """Blender coordinates: X right, Y depth, Z up."""
    bpy.ops.mesh.primitive_cube_add(size=1, location=center, rotation=rot)
    o = bpy.context.active_object
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    if bevel > 0:
        mod = o.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    o.data.materials.append(mat)
    return o


def cylinder(center, radius, depth, mat, verts=24, rot=(0, 0, 0), smooth=True):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth, location=center, rotation=rot)
    o = bpy.context.active_object
    o.data.materials.append(mat)
    if smooth:
        for p in o.data.polygons:
            p.use_smooth = abs(p.normal.z) < 0.5
    return o


def export(name):
    for o in bpy.context.scene.objects:
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
    bpy.ops.object.convert(target="MESH")
    bpy.ops.object.join()
    path = os.path.join(OUT_DIR, name + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True, export_yup=True)
    tris = sum(len(p.vertices) - 2 for p in bpy.context.active_object.data.polygons)
    print("Saved %s (%d triangles)" % (path, tris))


# ------------------------------------------------------------------ container

def container(name, paint_hex):
    reset()
    L, W, H = 6.06, 2.44, 2.59
    paint = material("Paint_" + name, paint_hex, 0.65, 0.3)
    dark = material("ContainerDark", "#2a2a2a", 0.6, 0.6)
    rust = material("Rust", "#5b3a26", 0.9, 0.2)
    floor = material("ContainerFloor", "#3a2f25", 0.9)

    # corner posts and top/bottom rails (the steel frame)
    for x in (-L / 2 + 0.08, L / 2 - 0.08):
        for y in (-W / 2 + 0.08, W / 2 - 0.08):
            box((x, y, H / 2), (0.16, 0.16, H), dark, 0.01)
    for z in (0.08, H - 0.08):
        for y in (-W / 2 + 0.06, W / 2 - 0.06):
            box((0, y, z), (L, 0.12, 0.16), dark, 0.01)
        for x in (-L / 2 + 0.06, L / 2 - 0.06):
            box((x, 0, z), (0.12, W, 0.16), dark, 0.01)
    # corrugated long walls: alternating in/out panels
    panels = 36
    pw = (L - 0.32) / panels
    for side in (-1, 1):
        for i in range(panels):
            x = -L / 2 + 0.16 + pw * (i + 0.5)
            depth = 0.06 if i % 2 == 0 else 0.03
            box((x, side * (W / 2 - depth / 2 - 0.01), H / 2), (pw * 1.02, depth, H - 0.3), paint)
    # end walls: one corrugated, one with doors
    for i in range(12):
        y = -W / 2 + 0.16 + (W - 0.32) / 12 * (i + 0.5)
        depth = 0.06 if i % 2 == 0 else 0.03
        box((-L / 2 + depth / 2 + 0.02, y, H / 2), (depth, (W - 0.32) / 12 * 1.02, H - 0.3), paint)
    for y in (-W / 4, W / 4):
        box((L / 2 - 0.05, y, H / 2), (0.05, W / 2 - 0.2, H - 0.3), paint, 0.01)
        for j in range(4):  # door ribs
            box((L / 2 - 0.02, y - W / 8 + j * W / 12 + 0.05, H / 2), (0.03, 0.04, H - 0.4), paint)
        for z in (0.6, H - 0.6):  # hinges
            box((L / 2, y + (W / 4 - 0.12) * (1 if y > 0 else -1), z), (0.06, 0.1, 0.12), dark)
        for k in (-0.15, 0.15):  # locking bars
            cylinder((L / 2 + 0.01, y + k, H / 2), 0.018, H - 0.35, dark, verts=8)
    # roof and floor
    box((0, 0, H - 0.04), (L - 0.2, W - 0.2, 0.05), paint)
    box((0, 0, 0.12), (L - 0.2, W - 0.2, 0.04), floor)
    # rust stains near the bottom
    for x in (-1.9, -0.3, 1.4, 2.4):
        box((x, -W / 2 - 0.0, 0.32), (0.5, 0.008, 0.35), rust)
        box((x + 0.3, W / 2 + 0.0, 0.3), (0.4, 0.008, 0.3), rust)
    # rotate so the long side is X in Godot too (Blender X -> Godot X)
    export(name)


# ------------------------------------------------------------------ crate

def crate():
    reset()
    S = 1.2
    wood = material("Wood", "#8a6740", 0.85)
    wood_dark = material("WoodDark", "#5e4428", 0.9)
    box((0, 0, S / 2), (S - 0.06, S - 0.06, S - 0.06), wood_dark)
    # planks on every side
    for side in (-1, 1):
        for i in range(5):
            z = 0.12 + i * (S - 0.12) / 5 + 0.1
            box((0, side * (S / 2 - 0.02), z), (S - 0.2, 0.04, 0.2), wood, 0.008)
            box((side * (S / 2 - 0.02), 0, z), (0.04, S - 0.2, 0.2), wood, 0.008)
    for i in range(5):
        x = -S / 2 + 0.12 + i * (S - 0.24) / 4
        box((x, 0, S - 0.02), (0.2, S - 0.16, 0.04), wood, 0.008)
    # frame edges
    for x in (-S / 2 + 0.05, S / 2 - 0.05):
        for y in (-S / 2 + 0.05, S / 2 - 0.05):
            box((x, y, S / 2), (0.1, 0.1, S), wood_dark, 0.01)
    for z in (0.05, S - 0.05):
        for y in (-S / 2 + 0.05, S / 2 - 0.05):
            box((0, y, z), (S, 0.1, 0.1), wood_dark, 0.01)
        for x in (-S / 2 + 0.05, S / 2 - 0.05):
            box((x, 0, z), (0.1, S, 0.1), wood_dark, 0.01)
    # diagonal braces
    for side in (-1, 1):
        box((0, side * (S / 2 + 0.005), S / 2), (S * 1.25, 0.04, 0.12), wood_dark, 0.005, rot=(0, math.radians(45), 0))
        box((side * (S / 2 + 0.005), 0, S / 2), (0.04, S * 1.25, 0.12), wood_dark, 0.005, rot=(math.radians(45), 0, 0))
    export("crate")


# ------------------------------------------------------------------ barrel

def barrel():
    reset()
    paint = material("BarrelPaint", "#2f5d8a", 0.55, 0.4)
    dark = material("BarrelDark", "#1e1e1e", 0.5, 0.7)
    cylinder((0, 0, 0.45), 0.29, 0.88, paint, verts=28)
    for z in (0.03, 0.3, 0.6, 0.87):
        cylinder((0, 0, z), 0.3, 0.04, dark, verts=28)
    cylinder((0.12, 0.05, 0.895), 0.04, 0.02, dark, verts=12)
    export("barrel")


# ------------------------------------------------------------------ concrete barrier

def barrier():
    reset()
    concrete = material("Concrete", "#9c9a92", 0.95)
    stripe = material("Stripe", "#d9b130", 0.7)
    L = 2.0
    box((0, 0, 0.12), (L, 0.6, 0.24), concrete, 0.02)
    box((0, 0, 0.3), (L, 0.42, 0.14), concrete, 0.02)
    box((0, 0, 0.58), (L, 0.22, 0.44), concrete, 0.03)
    for i in range(3):
        box((-0.6 + i * 0.6, -0.112, 0.62), (0.22, 0.01, 0.12), stripe, rot=(0, math.radians(30), 0))
        box((-0.6 + i * 0.6, 0.112, 0.62), (0.22, 0.01, 0.12), stripe, rot=(0, math.radians(30), 0))
    export("barrier")


# ------------------------------------------------------------------ pillar

def pillar():
    reset()
    steel = material("SteelBeam", "#55606a", 0.5, 0.7)
    base = material("Concrete", "#9c9a92", 0.95)
    H = 7.0
    box((0, 0, H / 2), (0.5, 0.06, H), steel)          # web
    box((0, -0.22, H / 2), (0.5, 0.04, H), steel)      # flanges
    box((0, 0.22, H / 2), (0.5, 0.04, H), steel)
    box((0, 0, 0.2), (0.7, 0.7, 0.4), base, 0.03)      # concrete foot
    for z in (1.5, 3.5, 5.5):
        box((0, 0, z), (0.5, 0.48, 0.03), steel)
    export("pillar")


os.makedirs(OUT_DIR, exist_ok=True)
for color_name, hex_color in (("blue", "#1f4f7a"), ("orange", "#b35a1f"), ("green", "#2f5e35"), ("red", "#7f2420")):
    container("container_" + color_name, hex_color)
crate()
barrel()
barrier()
pillar()
