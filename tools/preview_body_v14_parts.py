"""把 21 个连通域裁出小图并写到 tmp/parts_preview/，方便人眼对名。"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "resources/flight/rider/body_v14_rig/source/body_v14_rig_exploded_parts_clean.png"
LAYOUT = ROOT / "tmp/body_v14_parts_layout.json"
OUT_DIR = ROOT / "tmp/parts_preview"


def main() -> None:
    boxes = json.loads(LAYOUT.read_text(encoding="utf-8"))
    img = Image.open(SRC).convert("RGBA")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    # 拼一张总览
    cols = 7
    rows = (len(boxes) + cols - 1) // cols
    cell = 280
    sheet = Image.new("RGBA", (cols * cell, rows * cell), (40, 40, 40, 255))
    for i, b in enumerate(boxes):
        x0, y0, x1, y1 = b["bbox"]
        crop = img.crop((x0, y0, x1, y1))
        # 等比缩放放进 cell
        w, h = crop.size
        s = min((cell - 20) / w, (cell - 20) / h)
        nw, nh = max(1, int(w * s)), max(1, int(h * s))
        crop_resized = crop.resize((nw, nh), Image.NEAREST)
        cx = (i % cols) * cell + (cell - nw) // 2
        cy = (i // cols) * cell + (cell - nh) // 2
        sheet.paste(crop_resized, (cx, cy), crop_resized)
        # 单张
        crop.save(OUT_DIR / f"part_{i:02d}.png")
    sheet.save(OUT_DIR / "_grid.png")
    print(f"wrote {len(boxes)} parts + grid to {OUT_DIR}")


if __name__ == "__main__":
    main()
