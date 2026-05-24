#!/usr/bin/env python3
"""Normalize a chroma-keyed 4x4 sprite grid into a 16-frame body strip."""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image


FRAME_WIDTH = 256
FRAME_HEIGHT = 256


def extract_components(
    img: Image.Image,
    min_area: int,
    alpha_threshold: int,
) -> list[tuple[int, int, int, int, int]]:
    width, height = img.size
    alpha = img.getchannel("A")
    pixels = alpha.load()
    visited = bytearray(width * height)
    components: list[tuple[int, int, int, int, int]] = []

    for y in range(height):
        for x in range(width):
            idx = y * width + x
            if visited[idx] or pixels[x, y] <= alpha_threshold:
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
                        if not visited[nidx] and pixels[nx, ny] > alpha_threshold:
                            visited[nidx] = 1
                            queue.append((nx, ny))

            if area >= min_area:
                components.append((min_x, min_y, max_x + 1, max_y + 1, area))

    return components


def ordered_components(
    components: list[tuple[int, int, int, int, int]],
    count: int,
    columns: int,
) -> list[tuple[int, int, int, int, int]]:
    if len(components) < count:
        raise SystemExit(f"expected at least {count} sprite components, found {len(components)}")

    largest = sorted(components, key=lambda box: box[4], reverse=True)[:count]
    rows = [
        largest[index : index + columns]
        for index in range(0, count, columns)
    ]
    rows = sorted(rows, key=lambda row: sum((box[1] + box[3]) / 2 for box in row) / len(row))
    ordered: list[tuple[int, int, int, int, int]] = []
    for row in rows:
        ordered.extend(sorted(row, key=lambda box: (box[0] + box[2]) / 2))
    return ordered


def local_bottom_anchor_x(pose: Image.Image, bbox: tuple[int, int, int, int]) -> int:
    alpha = pose.getchannel("A")
    pixels = alpha.load()
    bottom = bbox[3] - 1
    band_top = max(bbox[1], bottom - 14)
    xs: list[int] = []
    for yy in range(band_top, bottom + 1):
        for xx in range(bbox[0], bbox[2]):
            if pixels[xx, yy] > 32:
                xs.append(xx)
    if xs:
        return round(sum(xs) / len(xs))
    return (bbox[0] + bbox[2]) // 2


def normalize_grid(
    source: Path,
    out: Path,
    count: int,
    columns: int,
    target_height: int,
    anchor_x: int,
    anchor_y: int,
    min_area: int,
    alpha_threshold: int,
    padding: int,
    horizontal_margin: int,
) -> None:
    img = Image.open(source).convert("RGBA")
    components = ordered_components(
        extract_components(img, min_area=min_area, alpha_threshold=alpha_threshold),
        count=count,
        columns=columns,
    )

    sheet = Image.new("RGBA", (FRAME_WIDTH * count, FRAME_HEIGHT), (0, 0, 0, 0))
    report = []

    for index, component in enumerate(components):
        x0, y0, x1, y1, _area = component
        x0 = max(0, x0 - padding)
        y0 = max(0, y0 - padding)
        x1 = min(img.width, x1 + padding)
        y1 = min(img.height, y1 + padding)

        crop = img.crop((x0, y0, x1, y1))
        bbox = crop.getchannel("A").getbbox()
        if not bbox:
            continue
        crop = crop.crop(bbox)

        crop_width, crop_height = crop.size
        new_width = max(1, round(crop_width * target_height / crop_height))
        pose = crop.resize((new_width, target_height), Image.Resampling.LANCZOS)
        pose_bbox = pose.getchannel("A").getbbox()
        if not pose_bbox:
            continue

        bottom = pose_bbox[3] - 1
        local_anchor_x = local_bottom_anchor_x(pose, pose_bbox)
        paste_x = index * FRAME_WIDTH + anchor_x - local_anchor_x
        local_paste_x = paste_x - index * FRAME_WIDTH
        frame_left = local_paste_x + pose_bbox[0]
        frame_right = local_paste_x + pose_bbox[2]
        if frame_left < horizontal_margin:
            local_paste_x += horizontal_margin - frame_left
        frame_right = local_paste_x + pose_bbox[2]
        if frame_right > FRAME_WIDTH - horizontal_margin:
            local_paste_x -= frame_right - (FRAME_WIDTH - horizontal_margin)
        paste_x = index * FRAME_WIDTH + local_paste_x
        paste_y = anchor_y - bottom
        sheet.alpha_composite(pose, (paste_x, paste_y))

        cell = sheet.crop((index * FRAME_WIDTH, 0, (index + 1) * FRAME_WIDTH, FRAME_HEIGHT))
        cell_bbox = cell.getchannel("A").getbbox()
        if cell_bbox:
            report.append((index + 1, cell_bbox, cell_bbox[3] - cell_bbox[1], cell_bbox[3] - 1))

    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"Wrote {out}")
    for frame, bbox, height, bottom in report:
        print(f"{frame}: bbox={bbox} height={height} bottom={bottom}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--count", type=int, default=16)
    parser.add_argument("--columns", type=int, default=4)
    parser.add_argument("--target-height", type=int, required=True)
    parser.add_argument("--anchor-x", type=int, default=128)
    parser.add_argument("--anchor-y", type=int, default=219)
    parser.add_argument("--min-area", type=int, default=3000)
    parser.add_argument("--alpha-threshold", type=int, default=16)
    parser.add_argument("--padding", type=int, default=4)
    parser.add_argument("--horizontal-margin", type=int, default=0)
    args = parser.parse_args()

    normalize_grid(
        source=args.source,
        out=args.out,
        count=args.count,
        columns=args.columns,
        target_height=args.target_height,
        anchor_x=args.anchor_x,
        anchor_y=args.anchor_y,
        min_area=args.min_area,
        alpha_threshold=args.alpha_threshold,
        padding=args.padding,
        horizontal_margin=args.horizontal_margin,
    )


if __name__ == "__main__":
    main()
