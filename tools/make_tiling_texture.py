"""Turns a texture photo into a seamless tiling texture plus a normal map.

  python3 tools/make_tiling_texture.py [--as-is] photo.png out_name [size] [strength]

Writes out_name.jpg (colour) and out_name_normal.png (OpenGL style, for
Godot). The photo is shifted by half its size and the seams are blended
away (--as-is skips that for photos that already tile, like brick or
block walls, where blending would smear the joints); the normal map comes
from the brightness (dark cracks = deeper).
Needs Pillow and numpy.
"""
import sys

import numpy as np
from PIL import Image, ImageFilter


def make_seamless(img):
    a = np.asarray(img).astype(np.float32)
    h, w = a.shape[:2]
    shifted = np.roll(np.roll(a, h // 2, axis=0), w // 2, axis=1)
    # weight: 1 in the middle of the original, 0 at its edges
    y = 1 - np.abs(np.linspace(-1, 1, h))[:, None]
    x = 1 - np.abs(np.linspace(-1, 1, w))[None, :]
    wgt = np.clip(np.minimum(x, y) * 3, 0, 1)[..., None]
    return Image.fromarray((a * wgt + shifted * (1 - wgt)).astype(np.uint8))


def normal_map(img, strength):
    g = np.asarray(img.convert("L").filter(ImageFilter.GaussianBlur(1.2))).astype(np.float32) / 255
    dx = (np.roll(g, -1, axis=1) - np.roll(g, 1, axis=1)) * strength
    dy = (np.roll(g, -1, axis=0) - np.roll(g, 1, axis=0)) * strength
    n = np.stack([-dx, dy, np.ones_like(g)], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8))


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "--as-is"]
    if len(args) < 2:
        sys.exit(__doc__)
    size = int(args[2]) if len(args) > 2 else 1024
    strength = float(args[3]) if len(args) > 3 else 6.0
    img = Image.open(args[0]).convert("RGB")
    if "--as-is" not in sys.argv:
        img = make_seamless(img)
    img = img.resize((size, size), Image.LANCZOS)
    img.save(args[1] + ".jpg", quality=90)
    normal_map(img, strength).save(args[1] + "_normal.png", optimize=True)
    print("wrote", args[1] + ".jpg", args[1] + "_normal.png")
