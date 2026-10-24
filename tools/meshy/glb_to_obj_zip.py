"""Packs a Meshy model as OBJ + texture in a .zip, the format Mixamo's
"Upload Character" accepts (it does not take .glb).

  python3 tools/meshy/glb_to_obj_zip.py model.glb out.zip [max_texture]

Uses the first mesh and its base colour texture. Needs Pillow.
"""
import io
import struct
import sys
import zipfile

from PIL import Image

from merge_animations import read_glb


def floats(gltf, binary, index, width):
    acc = gltf["accessors"][index]
    view = gltf["bufferViews"][acc["bufferView"]]
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    vals = struct.unpack_from("<%df" % (acc["count"] * width), binary, start)
    return [vals[i:i + width] for i in range(0, len(vals), width)]


def indices(gltf, binary, index):
    acc = gltf["accessors"][index]
    view = gltf["bufferViews"][acc["bufferView"]]
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    fmt = {5121: "B", 5123: "H", 5125: "I"}[acc["componentType"]]
    return struct.unpack_from("<%d%s" % (acc["count"], fmt), binary, start)


def main(src, out, max_texture=2048):
    gltf, binary = read_glb(src)
    prim = gltf["meshes"][0]["primitives"][0]
    pos = floats(gltf, binary, prim["attributes"]["POSITION"], 3)
    nrm = floats(gltf, binary, prim["attributes"]["NORMAL"], 3)
    uv = floats(gltf, binary, prim["attributes"]["TEXCOORD_0"], 2)
    idx = indices(gltf, binary, prim["indices"])
    lines = ["mtllib character.mtl", "o character"]
    lines += ["v %.6f %.6f %.6f" % p for p in pos]
    lines += ["vt %.6f %.6f" % (t[0], 1 - t[1]) for t in uv]
    lines += ["vn %.6f %.6f %.6f" % n for n in nrm]
    lines.append("usemtl skin")
    for i in range(0, len(idx), 3):
        a, b, c = idx[i] + 1, idx[i + 1] + 1, idx[i + 2] + 1
        lines.append("f %d/%d/%d %d/%d/%d %d/%d/%d" % (a, a, a, b, b, b, c, c, c))
    mat = gltf["materials"][prim.get("material", 0)]
    tex = mat["pbrMetallicRoughness"]["baseColorTexture"]["index"]
    view = gltf["bufferViews"][gltf["images"][gltf["textures"][tex]["source"]]["bufferView"]]
    start = view.get("byteOffset", 0)
    img = Image.open(io.BytesIO(bytes(binary[start:start + view["byteLength"]]))).convert("RGB")
    if max(img.size) > max_texture:
        img = img.resize((max_texture, max_texture), Image.LANCZOS)
    jpg = io.BytesIO()
    img.save(jpg, "JPEG", quality=90)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("character.obj", "\n".join(lines) + "\n")
        z.writestr("character.mtl", "newmtl skin\nKd 1 1 1\nmap_Kd character.jpg\n")
        z.writestr("character.jpg", jpg.getvalue())
    print("wrote", out, len(pos), "vertices", len(idx) // 3, "triangles")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 2048)
