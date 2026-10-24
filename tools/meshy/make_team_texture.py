"""Makes the red-team colour texture of a character.

  python3 tools/meshy/make_team_texture.py model.glb out_red.jpg

Takes the model's base colour texture and turns the navy blue cloth into dark
red. Skin, hair, the black vest, gloves and boots are not blue, so they stay
as they are. The game swaps this texture in for red team players.
Needs Pillow and numpy.
"""
import io
import json
import struct
import sys

import numpy as np
from PIL import Image

BLUE_HUE = (0.53, 0.75)   # hue range (0..1) counted as "uniform blue"
MIN_SATURATION = 0.18     # greys and blacks are left alone
RED_HUE = 0.995


def base_color_image(path):
    data = open(path, "rb").read()
    json_len = struct.unpack_from("<I", data, 12)[0]
    gltf = json.loads(data[20:20 + json_len])
    binary = data[20 + json_len + 8:]
    texture = gltf["materials"][0]["pbrMetallicRoughness"]["baseColorTexture"]["index"]
    view = gltf["bufferViews"][gltf["images"][gltf["textures"][texture]["source"]]["bufferView"]]
    start = view.get("byteOffset", 0)
    return Image.open(io.BytesIO(binary[start:start + view["byteLength"]])).convert("RGB")


def to_red(img):
    hsv = np.asarray(img.convert("HSV")).astype(np.float32) / 255.0
    h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
    blue = (h >= BLUE_HUE[0]) & (h <= BLUE_HUE[1]) & (s >= MIN_SATURATION)
    # soft edge so seams between cloth and other parts don't show a hard line
    weight = np.clip((s - MIN_SATURATION) / 0.08, 0, 1) * blue
    h2 = np.where(weight > 0, RED_HUE, h)
    s2 = s * (1 - weight) + np.minimum(s * 1.15, 1.0) * weight
    v2 = v * (1 - weight) + np.minimum(v * 1.1, 1.0) * weight
    out = np.stack([h2, s2, v2], axis=-1)
    red = Image.fromarray((out * 255).astype(np.uint8), "HSV").convert("RGB")
    # blend by weight, so pixels that only partly count as blue mix smoothly
    w = Image.fromarray((weight * 255).astype(np.uint8), "L")
    return Image.composite(red, img, w)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    to_red(base_color_image(sys.argv[1])).save(sys.argv[2], quality=92)
    print("wrote", sys.argv[2])
