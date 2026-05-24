"""分析 body_v14_rig_exploded_parts_clean.png 的部件分布。

通过 alpha 通道的连通域，找出每个部件的 bounding box 与质心。
输出供后续 cut_body_v14_rig_parts.py 使用的坐标参考。
"""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "resources/flight/rider/body_v14_rig/source/body_v14_rig_exploded_parts_clean.png"

# Alpha 阈值：低于此值视为透明
ALPHA_THRESHOLD = 24
# 连通域间最小间距（像素），小于此值的小碎块直接忽略
MIN_AREA = 800


def flood_components(mask: np.ndarray) -> list[tuple[int, int, int, int, int]]:
    """返回 [(x0,y0,x1,y1,area), ...] 的连通域列表。"""
    h, w = mask.shape
    visited = np.zeros_like(mask, dtype=bool)
    comps: list[tuple[int, int, int, int, int]] = []
    for sy in range(h):
        row = mask[sy]
        for sx in range(w):
            if not row[sx] or visited[sy, sx]:
                continue
            stack = [(sy, sx)]
            visited[sy, sx] = True
            min_x = max_x = sx
            min_y = max_y = sy
            area = 0
            while stack:
                y, x = stack.pop()
                area += 1
                if x < min_x: min_x = x
                if x > max_x: max_x = x
                if y < min_y: min_y = y
                if y > max_y: max_y = y
                if y > 0 and mask[y - 1, x] and not visited[y - 1, x]:
                    visited[y - 1, x] = True
                    stack.append((y - 1, x))
                if y + 1 < h and mask[y + 1, x] and not visited[y + 1, x]:
                    visited[y + 1, x] = True
                    stack.append((y + 1, x))
                if x > 0 and mask[y, x - 1] and not visited[y, x - 1]:
                    visited[y, x - 1] = True
                    stack.append((y, x - 1))
                if x + 1 < w and mask[y, x + 1] and not visited[y, x + 1]:
                    visited[y, x + 1] = True
                    stack.append((y, x + 1))
            if area >= MIN_AREA:
                comps.append((min_x, min_y, max_x + 1, max_y + 1, area))
    return comps


def merge_close(boxes: list[tuple[int, int, int, int, int]], gap: int = 16) -> list[tuple[int, int, int, int, int]]:
    """把距离很近的小块合并成一块，处理 AI 出图边界有断裂的情形。"""
    boxes = sorted(boxes, key=lambda b: (b[1], b[0]))
    merged: list[list[int]] = []
    for box in boxes:
        bx0, by0, bx1, by1, ba = box
        placed = False
        for m in merged:
            mx0, my0, mx1, my1, ma = m
            if (
                bx0 <= mx1 + gap
                and mx0 <= bx1 + gap
                and by0 <= my1 + gap
                and my0 <= by1 + gap
            ):
                m[0] = min(mx0, bx0)
                m[1] = min(my0, by0)
                m[2] = max(mx1, bx1)
                m[3] = max(my1, by1)
                m[4] = ma + ba
                placed = True
                break
        if not placed:
            merged.append(list(box))
    if len(merged) == len(boxes):
        return [tuple(m) for m in merged]
    return merge_close([tuple(m) for m in merged], gap)


def main() -> None:
    img = Image.open(SRC).convert("RGBA")
    arr = np.array(img)
    alpha = arr[:, :, 3]
    mask = alpha > ALPHA_THRESHOLD
    comps = flood_components(mask)
    comps = merge_close(comps, gap=12)
    comps.sort(key=lambda b: (b[1] // 80, b[0]))
    print(f"detected {len(comps)} components")
    for idx, (x0, y0, x1, y1, area) in enumerate(comps):
        print(f"  [{idx:02d}] bbox=({x0},{y0})-({x1},{y1}) size={x1-x0}x{y1-y0} area={area}")
    out_json = ROOT / "tmp/body_v14_parts_layout.json"
    out_json.parent.mkdir(parents=True, exist_ok=True)
    payload = [
        {"index": idx, "bbox": [x0, y0, x1, y1], "size": [x1 - x0, y1 - y0], "area": area}
        for idx, (x0, y0, x1, y1, area) in enumerate(comps)
    ]
    out_json.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(f"wrote {out_json}")


if __name__ == "__main__":
    main()
