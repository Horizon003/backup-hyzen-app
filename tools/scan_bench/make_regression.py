"""Deterministic pale-paper, off-centre, dense-text and shadow fixtures."""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

out = Path(sys.argv[1])
out.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(42)
gt = {}
for name, bg, paper, quad in [
    ("pale", 220, 240, [(150, 100), (920, 170), (880, 1270), (95, 1190)]),
    ("offcentre", 75, 245, [(45, 80), (505, 110), (480, 800), (20, 750)]),
    ("dense", 110, 245, [(190, 90), (930, 140), (850, 1310), (70, 1210)]),
    ("shadow", 60, 245, [(130, 160), (900, 80), (950, 1190), (160, 1320)]),
]:
    width, height = 1050, 1400
    page = Image.new("RGB", (600, 850), (paper,) * 3)
    draw = ImageDraw.Draw(page)
    for y in range(65, 790, 19 if name == "dense" else 29):
        x = 45
        while x < 500:
            length = int(rng.integers(16, 65))
            draw.rectangle((x, y, min(x + length, 555), y + 5), fill=(35, 35, 35))
            x += length + 12
    matrix, values = [], []
    for (x, y), (u, v) in zip(quad, [(0, 0), (600, 0), (600, 850), (0, 850)]):
        matrix += [[x, y, 1, 0, 0, 0, -u*x, -u*y], [0, 0, 0, x, y, 1, -v*x, -v*y]]
        values += [u, v]
    transform = np.linalg.solve(matrix, values)
    warped = page.transform((width, height), Image.Transform.PERSPECTIVE, transform, Image.Resampling.BICUBIC)
    mask = Image.new("L", page.size, 255).transform((width, height), Image.Transform.PERSPECTIVE, transform)
    photo = Image.composite(warped, Image.new("RGB", (width, height), (bg,) * 3), mask)
    pixels = np.asarray(photo).astype(float)
    if name == "shadow":
        pixels *= np.linspace(.58, 1, width)[None, :, None]
    pixels += rng.normal(0, 1.3, pixels.shape)
    photo = Image.fromarray(np.uint8(pixels.clip(0, 255))).filter(ImageFilter.GaussianBlur(.6))
    filename = f"{name}.jpg"
    photo.save(out / filename, quality=94)
    gt[filename] = [v for x, y in quad for v in (x / width, y / height)]
(out / "gt.json").write_text(json.dumps(gt))
print(f"Created {len(gt)} regression photos")
