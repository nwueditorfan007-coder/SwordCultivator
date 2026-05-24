"""把 exploded_parts_clean 切成 21 个独立 PNG，并生成 body_v14_rig_manifest.json。

由于 AI 出图与 V14 任务包 21 件清单不完全对齐（例如 torso 实为完整上身、缺 hair_tail
独立部件、披帛段数过多），本脚本做一次"将就映射"（参见 First Prototype A 方案）：

- 大部分件按面积+位置做最合理映射。
- hair_tail 用 sash 系列中一段顶替（先保证 rig 21 槽位齐全）。
- 每件 pivot 用启发式估算（多数件的 pivot 在 bbox 顶部中点附近，hand/foot 例外）。
- 输出文件位于 resources/flight/rider/body_v14_rig/parts/*.png
- manifest 同时写到 resources/flight/rider/body_v14_rig/body_v14_rig_manifest.json
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "resources/flight/rider/body_v14_rig/source/body_v14_rig_exploded_parts_clean.png"
LAYOUT = ROOT / "tmp/body_v14_parts_layout.json"
PARTS_DIR = ROOT / "resources/flight/rider/body_v14_rig/parts"
MANIFEST = ROOT / "resources/flight/rider/body_v14_rig/body_v14_rig_manifest.json"

# component index -> part name + pivot 启发式
# pivot 用 bbox 内部归一坐标 (px, py) ∈ [0,1]
# pivot anchor 含义：part 在 Godot 里旋转/位移的轴点，会成为 Sprite2D 的 offset
PART_MAP: list[tuple[int, str, tuple[float, float]]] = [
    # idx, part_name, (pivot_x_in_bbox, pivot_y_in_bbox)
    (0,  "torso",                    (0.50, 0.18)),   # 上身大件，pivot 接颈下
    (1,  "hair_back",                (0.50, 0.05)),   # 长发，pivot 顶端
    (2,  "sash_back_root",           (0.55, 0.05)),   # 长披帛，根部在顶
    (3,  "arm_back_upper",           (0.55, 0.10)),   # 后侧上臂，pivot 肩
    (4,  "arm_back_forearm_sleeve",  (0.55, 0.10)),   # 后侧前臂，pivot 肘
    (5,  "head",                     (0.50, 0.85)),   # 头，pivot 颈
    (6,  "pelvis_belt",              (0.50, 0.10)),   # 腰带，pivot 顶
    (7,  "arm_front_upper",          (0.50, 0.10)),   # 前侧上臂
    (8,  "leg_back",                 (0.50, 0.05)),   # 后腿
    (9,  "robe_front",               (0.45, 0.10)),   # 前衣摆
    (10, "arm_front_forearm_sleeve", (0.50, 0.10)),   # 前侧前臂
    (11, "leg_front",                (0.50, 0.05)),   # 前腿
    (12, "hand_front",               (0.50, 0.15)),   # 前手，pivot 腕
    (13, "hand_back",                (0.50, 0.15)),   # 后手
    (14, "robe_back",                (0.50, 0.05)),   # 后衣摆
    (15, "sash_back_mid",            (0.55, 0.05)),
    (16, "sash_front_root",          (0.55, 0.05)),
    (17, "sash_front_mid",           (0.55, 0.05)),
    (18, "hair_tail",                (0.55, 0.05)),   # 占位用，原图中是披帛末段
    (19, "sash_front_tip",           (0.55, 0.05)),
    (20, "sash_back_tip",            (0.55, 0.05)),
]

PADDING = 4  # 切图四周留点透明边，避免硬边


def main() -> None:
    boxes = json.loads(LAYOUT.read_text(encoding="utf-8"))
    img = Image.open(SRC).convert("RGBA")
    PARTS_DIR.mkdir(parents=True, exist_ok=True)
    manifest: dict[str, dict] = {
        "source": "body_v14_rig_exploded_parts_clean.png",
        "source_size": [img.size[0], img.size[1]],
        "padding": PADDING,
        "parts": {},
    }
    for idx, part_name, (pivot_nx, pivot_ny) in PART_MAP:
        b = boxes[idx]
        x0, y0, x1, y1 = b["bbox"]
        # 加 padding
        x0p = max(0, x0 - PADDING)
        y0p = max(0, y0 - PADDING)
        x1p = min(img.size[0], x1 + PADDING)
        y1p = min(img.size[1], y1 + PADDING)
        crop = img.crop((x0p, y0p, x1p, y1p))
        out_path = PARTS_DIR / f"{part_name}.png"
        crop.save(out_path)
        w = x1p - x0p
        h = y1p - y0p
        pivot_x = pivot_nx * w
        pivot_y = pivot_ny * h
        manifest["parts"][part_name] = {
            "file": f"parts/{part_name}.png",
            "size": [w, h],
            "pivot": [round(pivot_x, 1), round(pivot_y, 1)],
            "source_bbox": [x0p, y0p, x1p, y1p],
        }
        print(f"  {part_name:30s} {w}x{h}  pivot=({pivot_x:.1f},{pivot_y:.1f})")
    MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"wrote {len(PART_MAP)} parts to {PARTS_DIR}")
    print(f"wrote manifest to {MANIFEST}")


if __name__ == "__main__":
    main()
