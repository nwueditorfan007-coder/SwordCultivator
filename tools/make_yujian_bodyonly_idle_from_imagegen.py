#!/usr/bin/env python3
"""Make a body-only anchored Yujian hover idle from one image-generated frame."""

from __future__ import annotations

import argparse
import json
import math
from collections import deque
from pathlib import Path

from PIL import Image


def smoothstep(edge0: float, edge1: float, value: float) -> float:
    if edge1 == edge0:
        return 1.0 if value >= edge1 else 0.0
    t = max(0.0, min(1.0, (value - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)


def alpha_bbox(image: Image.Image, threshold: int = 8) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A")
    mask = alpha.point(lambda value: 255 if value > threshold else 0)
    return mask.getbbox()


def is_sword_cyan(r: int, g: int, b: int, y: int) -> bool:
    if y < 300:
        return False
    return g >= 118 and b >= 126 and (g + b - r) >= 150


def remove_cyan_sword(image: Image.Image) -> Image.Image:
    out = image.copy().convert("RGBA")
    pixels = out.load()
    width, height = out.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a <= 4:
                continue
            if is_sword_cyan(r, g, b, y):
                pixels[x, y] = (0, 0, 0, 0)
    return out


def components(image: Image.Image, threshold: int) -> list[tuple[int, int, int, int, int]]:
    width, height = image.size
    alpha = image.getchannel("A")
    pixels = alpha.load()
    visited = bytearray(width * height)
    found: list[tuple[int, int, int, int, int]] = []
    for y in range(height):
        for x in range(width):
            idx = y * width + x
            if visited[idx] or pixels[x, y] <= threshold:
                continue
            queue = deque([(x, y)])
            visited[idx] = 1
            min_x = max_x = x
            min_y = max_y = y
            area = 0
            while queue:
                cx, cy = queue.popleft()
                area += 1
                min_x = min(min_x, cx)
                max_x = max(max_x, cx)
                min_y = min(min_y, cy)
                max_y = max(max_y, cy)
                for ny in (cy - 1, cy, cy + 1):
                    if ny < 0 or ny >= height:
                        continue
                    base = ny * width
                    for nx in (cx - 1, cx, cx + 1):
                        if nx < 0 or nx >= width or (nx == cx and ny == cy):
                            continue
                        nidx = base + nx
                        if not visited[nidx] and pixels[nx, ny] > threshold:
                            visited[nidx] = 1
                            queue.append((nx, ny))
            found.append((min_x, min_y, max_x + 1, max_y + 1, area))
    return found


def remove_sword_remnant_components(image: Image.Image, threshold: int = 8) -> Image.Image:
    out = image.copy().convert("RGBA")
    pixels = out.load()
    for x0, y0, x1, y1, area in components(out, threshold):
        width = x1 - x0
        height = y1 - y0
        center_x = (x0 + x1) * 0.5
        bottom_only = y0 >= 315
        separated_from_body_feet = center_x < 218 or center_x > 314
        long_flat = width > height * 1.8 and y0 >= 300
        tiny_bottom = area < 2200 and y1 >= 335
        if bottom_only and (separated_from_body_feet or long_flat or tiny_bottom):
            for y in range(y0, y1):
                for x in range(x0, x1):
                    r, g, b, a = pixels[x, y]
                    if a > threshold:
                        pixels[x, y] = (0, 0, 0, 0)
    return out


def anchor_body(image: Image.Image, cell_size: int, anchor_y: int) -> Image.Image:
    bbox = alpha_bbox(image)
    if bbox is None:
        raise SystemExit("source body is empty after sword removal")
    crop = image.crop(bbox)
    crop_bbox = alpha_bbox(crop)
    if crop_bbox is None:
        raise SystemExit("source body crop is empty")
    crop = crop.crop(crop_bbox)
    crop_bbox = alpha_bbox(crop)
    if crop_bbox is None:
        raise SystemExit("source body recrop is empty")
    out = Image.new("RGBA", (cell_size, cell_size), (0, 0, 0, 0))
    paste_x = (cell_size - crop.width) // 2
    paste_y = anchor_y - (crop_bbox[3] - 1)
    paste_y = max(0, min(cell_size - crop.height, paste_y))
    out.alpha_composite(crop, (paste_x, paste_y))
    return out


def warp_idle(master: Image.Image, frame_index: int, frame_count: int) -> Image.Image:
    bbox = alpha_bbox(master)
    if bbox is None:
        raise SystemExit("master is empty")
    width, height = master.size
    src = master.load()
    out = Image.new("RGBA", master.size, (0, 0, 0, 0))
    dst = out.load()
    x0, y0, x1, y1 = bbox
    body_height = max(1, y1 - y0)
    center_x = (x0 + x1) * 0.5
    phase = math.tau * frame_index / frame_count
    breath = math.sin(phase)
    lag = math.sin(phase - 0.85)
    hair_lag = math.sin(phase - 1.35)
    for y in range(y0, y1):
        t = (y - y0) / body_height
        foot_lock = smoothstep(0.80, 0.98, t)
        upper_weight = 1.0 - foot_lock
        for x in range(x0, x1):
            r, g, b, a = src[x, y]
            if a <= 0:
                continue
            left_trail = max(0.0, min(1.0, (center_x - x) / 135.0))
            hair_region = 1.0 if y < y0 + body_height * 0.48 and x < center_x + 8 else 0.0
            robe_region = 1.0 if y > y0 + body_height * 0.45 and x < center_x + 4 else 0.0
            dy = int(round(-3.0 * breath * upper_weight))
            dx = int(round(1.4 * breath * upper_weight))
            dx += int(round(-3.2 * hair_lag * left_trail * hair_region))
            dx += int(round(-2.2 * lag * left_trail * robe_region * (1.0 - foot_lock)))
            nx = x + dx
            ny = y + dy
            if 0 <= nx < width and 0 <= ny < height:
                old = dst[nx, ny]
                if a >= old[3]:
                    dst[nx, ny] = (r, g, b, a)
    return out


def checkerboard(size: tuple[int, int], tile: int = 16) -> Image.Image:
    image = Image.new("RGBA", size, (28, 28, 28, 255))
    pixels = image.load()
    for y in range(size[1]):
        for x in range(size[0]):
            pixels[x, y] = (66, 66, 66, 255) if ((x // tile + y // tile) % 2) else (38, 38, 38, 255)
    return image


def make_idle(source: Path, out_dir: Path, cells: int, cell_size: int, anchor_y: int) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    frames_dir = out_dir / "frames"
    frames_dir.mkdir(parents=True, exist_ok=True)
    source_image = Image.open(source).convert("RGBA")
    no_cyan = remove_cyan_sword(source_image)
    body_only = remove_sword_remnant_components(no_cyan)
    master = anchor_body(body_only, cell_size, anchor_y)
    master_path = out_dir / "01_right_hover_idle_bodyonly_master.png"
    master.save(master_path)
    sheet = Image.new("RGBA", (cell_size * cells, cell_size), (0, 0, 0, 0))
    preview_cell = cell_size // 2
    preview = checkerboard((preview_cell * 4, preview_cell * 2))
    frame_report: list[dict[str, object]] = []
    for index in range(cells):
        frame = warp_idle(master, index, cells)
        frame_path = frames_dir / f"01_right_hover_idle_bodyonly_{index:02d}.png"
        frame.save(frame_path)
        sheet.alpha_composite(frame, (index * cell_size, 0))
        preview_frame = frame.resize((preview_cell, preview_cell), Image.Resampling.LANCZOS)
        preview.alpha_composite(preview_frame, ((index % 4) * preview_cell, (index // 4) * preview_cell))
        frame_report.append(
            {
                "frame": index,
                "bbox": list(alpha_bbox(frame) or ()),
                "frame_path": str(frame_path).replace("\\", "/"),
            }
        )
    sheet_path = out_dir / "01_right_hover_idle_bodyonly_8f_512.png"
    preview_path = out_dir / "01_right_hover_idle_bodyonly_preview.png"
    metadata_path = out_dir / "01_right_hover_idle_bodyonly_8f_512.json"
    sheet.save(sheet_path)
    preview.save(preview_path)
    metadata = {
        "asset": "01_right_hover_idle_bodyonly",
        "direction": "01_right",
        "frame_count": cells,
        "cell_size": cell_size,
        "source": str(source).replace("\\", "/"),
        "master": str(master_path).replace("\\", "/"),
        "sheet": str(sheet_path).replace("\\", "/"),
        "preview": str(preview_path).replace("\\", "/"),
        "anchor_y": anchor_y,
        "notes": "Generated from an image_gen source frame. Visible sword pixels removed locally; feet/low body remain anchored while upper body, hair, and robe receive scripted idle micro-motion.",
        "frames": frame_report,
    }
    metadata_path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {master_path}")
    print(f"Wrote {sheet_path}")
    print(f"Wrote {preview_path}")
    print(f"Wrote {metadata_path}")
    for item in frame_report:
        print(f"{item['frame']}: bbox={item['bbox']}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--out-dir", required=True, type=Path)
    parser.add_argument("--cells", type=int, default=8)
    parser.add_argument("--cell-size", type=int, default=512)
    parser.add_argument("--anchor-y", type=int, default=392)
    args = parser.parse_args()
    make_idle(args.source, args.out_dir, args.cells, args.cell_size, args.anchor_y)


if __name__ == "__main__":
    main()
