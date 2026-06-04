#!/usr/bin/env python3
"""Normalize an image-generated Yujian hover row into 512x512 animation cells."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


def alpha_bbox(image: Image.Image, threshold: int) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A")
    mask = alpha.point(lambda value: 255 if value > threshold else 0)
    return mask.getbbox()


def checkerboard(size: tuple[int, int], tile: int = 16) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size, (28, 28, 28, 255))
    light = (66, 66, 66, 255)
    dark = (38, 38, 38, 255)
    pixels = image.load()
    for y in range(height):
        for x in range(width):
            pixels[x, y] = light if ((x // tile + y // tile) % 2) else dark
    return image


def normalize_row(
    source: Path,
    out_dir: Path,
    cells: int,
    cell_size: int,
    target_height: int,
    anchor_y: int,
    alpha_threshold: int,
    padding: int,
) -> None:
    src = Image.open(source).convert("RGBA")
    frames_dir = out_dir / "frames"
    frames_dir.mkdir(parents=True, exist_ok=True)

    sheet = Image.new("RGBA", (cell_size * cells, cell_size), (0, 0, 0, 0))
    preview_cell = cell_size // 2
    preview = checkerboard((preview_cell * 4, preview_cell * 2))
    report: list[dict[str, object]] = []

    for index in range(cells):
        x0 = round(index * src.width / cells)
        x1 = round((index + 1) * src.width / cells)
        tile = src.crop((x0, 0, x1, src.height))
        bbox = alpha_bbox(tile, alpha_threshold)
        if bbox is None:
            raise SystemExit(f"{source}: slice {index} is empty")

        left = max(0, bbox[0] - padding)
        top = max(0, bbox[1] - padding)
        right = min(tile.width, bbox[2] + padding)
        bottom = min(tile.height, bbox[3] + padding)
        crop = tile.crop((left, top, right, bottom))
        crop_bbox = alpha_bbox(crop, alpha_threshold)
        if crop_bbox is None:
            raise SystemExit(f"{source}: slice {index} crop is empty")
        crop = crop.crop(crop_bbox)

        new_width = max(1, round(crop.width * target_height / crop.height))
        pose = crop.resize((new_width, target_height), Image.Resampling.LANCZOS)
        pose_bbox = alpha_bbox(pose, alpha_threshold)
        if pose_bbox is None:
            raise SystemExit(f"{source}: slice {index} resized crop is empty")

        paste_x = index * cell_size + (cell_size - pose.width) // 2
        paste_y = anchor_y - (pose_bbox[3] - 1)
        paste_y = min(max(paste_y, 0), cell_size - pose.height)
        sheet.alpha_composite(pose, (paste_x, paste_y))

        cell = sheet.crop((index * cell_size, 0, (index + 1) * cell_size, cell_size))
        frame_path = frames_dir / f"01_right_hover_idle_imagegen_{index:02d}.png"
        cell.save(frame_path)

        preview_frame = cell.resize((preview_cell, preview_cell), Image.Resampling.LANCZOS)
        preview.alpha_composite(preview_frame, ((index % 4) * preview_cell, (index // 4) * preview_cell))

        cell_bbox = alpha_bbox(cell, alpha_threshold)
        report.append(
            {
                "frame": index,
                "source_slice": [x0, 0, x1, src.height],
                "source_bbox": [x0 + left + crop_bbox[0], top + crop_bbox[1], x0 + left + crop_bbox[2], top + crop_bbox[3]],
                "cell_bbox": list(cell_bbox) if cell_bbox else None,
                "frame_path": str(frame_path).replace("\\", "/"),
            }
        )

    sheet_path = out_dir / "01_right_hover_idle_imagegen_8f_512.png"
    preview_path = out_dir / "01_right_hover_idle_imagegen_preview.png"
    metadata_path = out_dir / "01_right_hover_idle_imagegen_8f_512.json"
    sheet.save(sheet_path)
    preview.save(preview_path)
    metadata = {
        "asset": "01_right_hover_idle_imagegen",
        "direction": "01_right",
        "frame_count": cells,
        "cell_size": cell_size,
        "sheet": str(sheet_path).replace("\\", "/"),
        "preview": str(preview_path).replace("\\", "/"),
        "source": str(source).replace("\\", "/"),
        "target_height": target_height,
        "anchor_y": anchor_y,
        "frames": report,
    }
    metadata_path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {sheet_path}")
    print(f"Wrote {preview_path}")
    print(f"Wrote {metadata_path}")
    for item in report:
        print(f"{item['frame']}: cell_bbox={item['cell_bbox']}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--out-dir", required=True, type=Path)
    parser.add_argument("--cells", type=int, default=8)
    parser.add_argument("--cell-size", type=int, default=512)
    parser.add_argument("--target-height", type=int, default=340)
    parser.add_argument("--anchor-y", type=int, default=392)
    parser.add_argument("--alpha-threshold", type=int, default=12)
    parser.add_argument("--padding", type=int, default=8)
    args = parser.parse_args()
    normalize_row(
        source=args.source,
        out_dir=args.out_dir,
        cells=args.cells,
        cell_size=args.cell_size,
        target_height=args.target_height,
        anchor_y=args.anchor_y,
        alpha_threshold=args.alpha_threshold,
        padding=args.padding,
    )


if __name__ == "__main__":
    main()
