#!/usr/bin/env python3
"""Normalize an imagegen sprite row into 256x256 animation cells."""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image


def extract_components(img: Image.Image, min_area: int) -> list[tuple[int, int, int, int, int]]:
    width, height = img.size
    alpha = img.getchannel("A")
    pixels = alpha.load()
    visited = bytearray(width * height)
    components: list[tuple[int, int, int, int, int]] = []

    for y in range(height):
        for x in range(width):
            idx = y * width + x
            if visited[idx] or pixels[x, y] <= 16:
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
                        if not visited[nidx] and pixels[nx, ny] > 16:
                            visited[nidx] = 1
                            queue.append((nx, ny))

            if area >= min_area:
                components.append((min_x, min_y, max_x + 1, max_y + 1, area))

    return sorted(components, key=lambda box: box[0])


def normalize_row(
    source: Path,
    out: Path,
    cells: int,
    target_height: int,
    anchor_x: int,
    anchor_y: int,
    min_area: int,
    horizontal_margin: int,
    slice_source: bool,
) -> None:
    img = Image.open(source).convert("RGBA")
    if slice_source:
        components = []
        for index in range(cells):
            x0 = round(index * img.width / cells)
            x1 = round((index + 1) * img.width / cells)
            tile = img.crop((x0, 0, x1, img.height))
            bbox = tile.getchannel("A").getbbox()
            if not bbox:
                raise SystemExit(f"{source}: slice {index + 1} is empty")
            components.append((x0 + bbox[0], bbox[1], x0 + bbox[2], bbox[3], (bbox[2] - bbox[0]) * (bbox[3] - bbox[1])))
    else:
        components = extract_components(img, min_area)
        if len(components) < cells:
            raise SystemExit(f"{source}: expected at least {cells} components, found {len(components)}")

        components = sorted(components, key=lambda box: box[4], reverse=True)[:cells]
        components = sorted(components, key=lambda box: box[0])
    sheet = Image.new("RGBA", (cells * 256, 256), (0, 0, 0, 0))

    report = []
    for index, component in enumerate(components):
        x0, y0, x1, y1, _area = component
        crop = img.crop((x0, y0, x1, y1))
        bbox = crop.getchannel("A").getbbox()
        if not bbox:
            continue
        crop = crop.crop(bbox)

        crop_width, crop_height = crop.size
        new_width = max(1, round(crop_width * target_height / crop_height))
        pose = crop.resize((new_width, target_height), Image.Resampling.NEAREST)

        alpha = pose.getchannel("A")
        pose_bbox = alpha.getbbox()
        if not pose_bbox:
            continue

        alpha_pixels = alpha.load()
        bottom = pose_bbox[3] - 1
        band_top = max(pose_bbox[1], bottom - 14)
        xs: list[int] = []
        for yy in range(band_top, bottom + 1):
            for xx in range(pose_bbox[0], pose_bbox[2]):
                if alpha_pixels[xx, yy] > 32:
                    xs.append(xx)

        local_anchor_x = round(sum(xs) / len(xs)) if xs else (pose_bbox[0] + pose_bbox[2]) // 2
        paste_x = index * 256 + anchor_x - local_anchor_x
        local_paste_x = paste_x - index * 256
        frame_left = local_paste_x + pose_bbox[0]
        frame_right = local_paste_x + pose_bbox[2]
        if frame_left < horizontal_margin:
            local_paste_x += horizontal_margin - frame_left
        frame_right = local_paste_x + pose_bbox[2]
        if frame_right > 256 - horizontal_margin:
            local_paste_x -= frame_right - (256 - horizontal_margin)
        paste_x = index * 256 + local_paste_x
        paste_y = anchor_y - bottom
        sheet.alpha_composite(pose, (paste_x, paste_y))

        cell = sheet.crop((index * 256, 0, (index + 1) * 256, 256))
        cell_bbox = cell.getchannel("A").getbbox()
        if cell_bbox:
            report.append((index + 1, cell_bbox, cell_bbox[3] - cell_bbox[1], cell_bbox[3] - 1))

    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"Wrote {out}")
    for frame, bbox, height, bottom in report:
        print(f"{frame}: bbox={bbox} height={height} bottom={bottom}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--cells", type=int, default=8)
    parser.add_argument("--target-height", type=int, required=True)
    parser.add_argument("--anchor-x", type=int, default=128)
    parser.add_argument("--anchor-y", type=int, default=219)
    parser.add_argument("--min-area", type=int, default=3000)
    parser.add_argument("--horizontal-margin", type=int, default=0)
    parser.add_argument("--slice-source", action="store_true")
    args = parser.parse_args()

    normalize_row(
        source=args.source,
        out=args.out,
        cells=args.cells,
        target_height=args.target_height,
        anchor_x=args.anchor_x,
        anchor_y=args.anchor_y,
        min_area=args.min_area,
        horizontal_margin=args.horizontal_margin,
        slice_source=args.slice_source,
    )


if __name__ == "__main__":
    main()
