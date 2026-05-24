"""按 body_v14_pose_library.json 的 pose 数据，在 Python 里把 parts 组装并渲染。

输出 tmp/body_v14_layering_preview.png：5 列对应 5 个 pose。
用于在进 Godot 前先校验位置/z_index 是否合理。
"""
from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
RIG_DIR = ROOT / "resources/flight/rider/body_v14_rig"
MANIFEST = RIG_DIR / "body_v14_rig_manifest.json"
POSES = RIG_DIR / "body_v14_pose_library.json"
OUT = ROOT / "tmp/body_v14_layering_preview.png"

CELL = 360  # 每格像素宽高（屏幕渲染尺寸）
BG_COLOR = (40, 44, 52, 255)


def rotate_about_pivot(img: Image.Image, pivot: tuple[float, float], degrees: float):
    """绕 pivot 旋转返回新图与新 pivot 位置。"""
    if abs(degrees) < 1e-3:
        return img, pivot
    rotated = img.rotate(-degrees, resample=Image.BICUBIC, expand=True)
    # 旋转后新图 pivot 需要重新计算
    rad = math.radians(-degrees)
    cx, cy = pivot
    # 原图中心
    ow, oh = img.size
    # 旋转坐标变换
    dx = cx - ow / 2
    dy = cy - oh / 2
    rx = dx * math.cos(rad) - dy * math.sin(rad)
    ry = dx * math.sin(rad) + dy * math.cos(rad)
    new_pivot = (rotated.size[0] / 2 + rx, rotated.size[1] / 2 + ry)
    return rotated, new_pivot


def render_pose(parts: dict, pose: dict, scale: float, anchor: tuple[int, int], canvas: Image.Image) -> None:
    # 按 z_index 排序
    items = sorted(pose.items(), key=lambda kv: kv[1]["z_index"])
    for name, data in items:
        if name not in parts:
            continue
        part_def = parts[name]
        img = Image.open(RIG_DIR / part_def["file"]).convert("RGBA")
        pivot = tuple(part_def["pivot"])
        # 旋转
        rotated, new_pivot = rotate_about_pivot(img, pivot, data["rotation_degrees"])
        # 缩放
        sx, sy = data["scale"]
        ux = sx * scale
        uy = sy * scale
        sw = max(1, int(rotated.size[0] * ux))
        sh = max(1, int(rotated.size[1] * uy))
        scaled = rotated.resize((sw, sh), Image.BICUBIC)
        scaled_pivot = (new_pivot[0] * ux, new_pivot[1] * uy)
        # 放置：part 的 pivot 应该落在 (anchor.x + pos.x*scale, anchor.y + pos.y*scale)
        pos = data["position"]
        target_x = anchor[0] + pos[0] * scale
        target_y = anchor[1] + pos[1] * scale
        paste_x = int(round(target_x - scaled_pivot[0]))
        paste_y = int(round(target_y - scaled_pivot[1]))
        canvas.alpha_composite(scaled, (paste_x, paste_y))


def main() -> None:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    poses = json.loads(POSES.read_text(encoding="utf-8"))
    scale = poses["assembly_scale"]
    parts = manifest["parts"]
    pose_names = ["idle", "sword_control_idle", "array_ring_idle", "array_fan_idle", "array_pierce_idle"]
    sheet = Image.new("RGBA", (CELL * len(pose_names), CELL), BG_COLOR)
    for i, pn in enumerate(pose_names):
        cell = Image.new("RGBA", (CELL, CELL), BG_COLOR)
        # 锚点放在 cell 底部中间偏上
        anchor = (CELL // 2, CELL - 40)
        render_pose(parts, poses["poses"][pn], scale, anchor, cell)
        sheet.paste(cell, (i * CELL, 0), cell)
        # 写标签
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print(f"wrote {OUT}  ({sheet.size[0]}x{sheet.size[1]})")


if __name__ == "__main__":
    main()
