#!/usr/bin/env python3
"""Build SwordCultivator flight rider body V13.1 atlases from 4x4 chroma sources."""

from __future__ import annotations

import argparse
import subprocess
import sys
from collections import deque
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


CELL_SIZE = 256
FRAME_COUNT = 16
GRID_COLS = 4
GRID_ROWS = 4
KEY_COLOR = "#ff00ff"

MAIN_ROWS = [
    "idle",
    "forward",
    "back",
    "parry",
    "sword_control_idle",
    "array_ring_idle",
    "array_fan_idle",
    "array_pierce_idle",
    "array_ring_release",
    "array_fan_release",
    "array_pierce_release",
]

TRANSITION_ROWS = [
    "idle_to_sword_control",
    "sword_control_to_idle",
    "idle_to_array_ring",
    "array_ring_to_idle",
    "idle_to_array_fan",
    "array_fan_to_idle",
    "idle_to_array_pierce",
    "array_pierce_to_idle",
    "array_ring_to_fan",
    "array_fan_to_ring",
    "array_fan_to_pierce",
    "array_pierce_to_fan",
    "array_pierce_to_ring",
    "array_ring_to_pierce",
]

TRANSITION_ENDPOINTS = {
    "idle_to_sword_control": ("idle", "sword_control"),
    "sword_control_to_idle": ("sword_control", "idle"),
    "idle_to_array_ring": ("idle", "array_ring"),
    "array_ring_to_idle": ("array_ring", "idle"),
    "idle_to_array_fan": ("idle", "array_fan"),
    "array_fan_to_idle": ("array_fan", "idle"),
    "idle_to_array_pierce": ("idle", "array_pierce"),
    "array_pierce_to_idle": ("array_pierce", "idle"),
    "array_ring_to_fan": ("array_ring", "array_fan"),
    "array_fan_to_ring": ("array_fan", "array_ring"),
    "array_fan_to_pierce": ("array_fan", "array_pierce"),
    "array_pierce_to_fan": ("array_pierce", "array_fan"),
    "array_pierce_to_ring": ("array_pierce", "array_ring"),
    "array_ring_to_pierce": ("array_ring", "array_pierce"),
}

STATE_MAIN_ROWS = {
    "idle": "idle",
    "sword_control": "sword_control_idle",
    "array_ring": "array_ring_idle",
    "array_fan": "array_fan_idle",
    "array_pierce": "array_pierce_idle",
}

TARGET_HEIGHTS = {
    "idle": 168,
    "forward": 152,
    "back": 156,
    "parry": 166,
    "sword_control_idle": 166,
    "array_ring_idle": 166,
    "array_fan_idle": 166,
    "array_pierce_idle": 166,
    "array_ring_release": 166,
    "array_fan_release": 166,
    "array_pierce_release": 166,
}

TRANSITION_TARGET_HEIGHT = 166


@dataclass(frozen=True)
class RowBuild:
    name: str
    source: Path
    alpha: Path
    strip: Path
    target_height: int


def alpha_bbox(img: Image.Image, threshold: int = 16) -> tuple[int, int, int, int] | None:
    alpha = img.getchannel("A")
    mask = alpha.point(lambda value: 255 if value > threshold else 0)
    return mask.getbbox()


def visible_anchor_x(img: Image.Image, bbox: tuple[int, int, int, int]) -> int:
    alpha = img.getchannel("A")
    pixels = alpha.load()
    bottom = bbox[3] - 1
    band_top = max(bbox[1], bottom - 14)
    xs: list[int] = []
    for y in range(band_top, bottom + 1):
        for x in range(bbox[0], bbox[2]):
            if pixels[x, y] > 32:
                xs.append(x)
    if xs:
        return round(sum(xs) / len(xs))
    return (bbox[0] + bbox[2]) // 2


def bbox_distance(a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> int:
    dx = max(0, max(a[0], b[0]) - min(a[2], b[2]))
    dy = max(0, max(a[1], b[1]) - min(a[3], b[3]))
    return max(dx, dy)


def extract_alpha_components(img: Image.Image, threshold: int = 16) -> list[tuple[int, int, int, int, int, list[tuple[int, int]]]]:
    width, height = img.size
    alpha = img.getchannel("A")
    pixels = alpha.load()
    visited = bytearray(width * height)
    components: list[tuple[int, int, int, int, int, list[tuple[int, int]]]] = []

    for y in range(height):
        for x in range(width):
            idx = y * width + x
            if visited[idx] or pixels[x, y] <= threshold:
                continue

            queue = deque([(x, y)])
            visited[idx] = 1
            min_x = max_x = x
            min_y = max_y = y
            coords: list[tuple[int, int]] = []

            while queue:
                cx, cy = queue.popleft()
                coords.append((cx, cy))
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

            components.append((min_x, min_y, max_x + 1, max_y + 1, len(coords), coords))

    return components


def clean_tile(tile: Image.Image) -> Image.Image:
    components = extract_alpha_components(tile)
    if len(components) <= 1:
        return tile

    components.sort(key=lambda item: item[4], reverse=True)
    largest = components[0]
    largest_bbox = largest[:4]
    largest_area = largest[4]
    keep_coords: set[tuple[int, int]] = set()

    for component in components:
        bbox = component[:4]
        area = component[4]
        width = bbox[2] - bbox[0]
        height = bbox[3] - bbox[1]
        if component is largest:
            keep = True
        elif height <= 8 and area < 400:
            keep = False
        elif width <= 8 and area < 400:
            keep = False
        elif area < 80:
            keep = False
        elif area >= largest_area * 0.045:
            keep = True
        elif bbox_distance(bbox, largest_bbox) <= 56 and area >= 140:
            keep = True
        elif width >= 28 and height >= 6 and bbox_distance(bbox, largest_bbox) <= 88:
            keep = True
        else:
            keep = False

        if keep:
            keep_coords.update(component[5])

    if not keep_coords:
        return tile

    cleaned = Image.new("RGBA", tile.size, (0, 0, 0, 0))
    src_pixels = tile.load()
    dst_pixels = cleaned.load()
    for x, y in keep_coords:
        dst_pixels[x, y] = src_pixels[x, y]
    return cleaned


def remove_chroma(helper: Path, source: Path, out: Path, force: bool) -> None:
    if not source.exists():
        raise FileNotFoundError(source)
    if out.exists() and not force and out.stat().st_mtime >= source.stat().st_mtime:
        return
    out.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        sys.executable,
        str(helper),
        "--input",
        str(source),
        "--out",
        str(out),
        "--key-color",
        KEY_COLOR,
        "--soft-matte",
        "--transparent-threshold",
        "55",
        "--opaque-threshold",
        "210",
        "--despill",
        "--force",
    ]
    subprocess.run(cmd, check=True)


def normalize_4x4_grid(
    source: Path,
    out: Path,
    target_height: int,
    anchor_x: int,
    anchor_y: int,
    horizontal_margin: int,
) -> list[str]:
    img = Image.open(source).convert("RGBA")
    width, height = img.size
    if width < GRID_COLS or height < GRID_ROWS:
        raise ValueError(f"{source}: too small for a {GRID_COLS}x{GRID_ROWS} grid")

    strip = Image.new("RGBA", (FRAME_COUNT * CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
    report: list[str] = []

    for index in range(FRAME_COUNT):
        col = index % GRID_COLS
        row = index // GRID_COLS
        x0 = round(col * width / GRID_COLS)
        x1 = round((col + 1) * width / GRID_COLS)
        y0 = round(row * height / GRID_ROWS)
        y1 = round((row + 1) * height / GRID_ROWS)

        tile = img.crop((x0, y0, x1, y1))
        tile = clean_tile(tile)
        bbox = alpha_bbox(tile)
        if not bbox:
            raise ValueError(f"{source}: frame {index + 1} is empty")

        crop = tile.crop(bbox)
        crop_bbox = alpha_bbox(crop)
        if not crop_bbox:
            raise ValueError(f"{source}: frame {index + 1} has no visible pixels after crop")
        crop = crop.crop(crop_bbox)

        crop_width, crop_height = crop.size
        new_width = max(1, round(crop_width * target_height / crop_height))
        pose = crop.resize((new_width, target_height), Image.Resampling.NEAREST)
        pose_bbox = alpha_bbox(pose)
        if not pose_bbox:
            raise ValueError(f"{source}: frame {index + 1} disappeared after resize")

        local_anchor_x = visible_anchor_x(pose, pose_bbox)
        local_paste_x = anchor_x - local_anchor_x
        frame_left = local_paste_x + pose_bbox[0]
        frame_right = local_paste_x + pose_bbox[2]
        if frame_left < horizontal_margin:
            local_paste_x += horizontal_margin - frame_left
        frame_right = local_paste_x + pose_bbox[2]
        if frame_right > CELL_SIZE - horizontal_margin:
            local_paste_x -= frame_right - (CELL_SIZE - horizontal_margin)

        bottom = pose_bbox[3] - 1
        paste_y = anchor_y - bottom
        paste_x = index * CELL_SIZE + local_paste_x
        strip.alpha_composite(pose, (paste_x, paste_y))

        cell = strip.crop((index * CELL_SIZE, 0, (index + 1) * CELL_SIZE, CELL_SIZE))
        cell_bbox = alpha_bbox(cell)
        if cell_bbox:
            report.append(
                f"{index + 1:02d}: bbox={cell_bbox} height={cell_bbox[3] - cell_bbox[1]} bottom={cell_bbox[3] - 1}"
            )

    out.parent.mkdir(parents=True, exist_ok=True)
    strip.save(out)
    return report


def stitch(rows: list[Path], out: Path) -> None:
    sheet = Image.new("RGBA", (FRAME_COUNT * CELL_SIZE, len(rows) * CELL_SIZE), (0, 0, 0, 0))
    for row_index, row_path in enumerate(rows):
        row_img = Image.open(row_path).convert("RGBA")
        expected_size = (FRAME_COUNT * CELL_SIZE, CELL_SIZE)
        if row_img.size != expected_size:
            raise ValueError(f"{row_path}: expected {expected_size}, got {row_img.size}")
        sheet.alpha_composite(row_img, (0, row_index * CELL_SIZE))
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)


def strip_cells(strip_path: Path) -> list[Image.Image]:
    strip = Image.open(strip_path).convert("RGBA")
    expected_size = (FRAME_COUNT * CELL_SIZE, CELL_SIZE)
    if strip.size != expected_size:
        raise ValueError(f"{strip_path}: expected {expected_size}, got {strip.size}")
    return [
        strip.crop((index * CELL_SIZE, 0, (index + 1) * CELL_SIZE, CELL_SIZE))
        for index in range(FRAME_COUNT)
    ]


def write_strip(cells: list[Image.Image], out: Path) -> None:
    if len(cells) != FRAME_COUNT:
        raise ValueError(f"{out}: expected {FRAME_COUNT} cells, got {len(cells)}")
    strip = Image.new("RGBA", (FRAME_COUNT * CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
    for index, cell in enumerate(cells):
        if cell.size != (CELL_SIZE, CELL_SIZE):
            raise ValueError(f"{out}: cell {index + 1} has size {cell.size}")
        strip.alpha_composite(cell, (index * CELL_SIZE, 0))
    out.parent.mkdir(parents=True, exist_ok=True)
    strip.save(out)


def compose_transition_cells(source: list[Image.Image], target: list[Image.Image]) -> list[Image.Image]:
    source_indices = [0, 1, 2, 4, 6, 8]
    target_indices = [0, 1, 2, 3, 4, 5, 6, 8, 10, 12]
    return [source[index].copy() for index in source_indices] + [target[index].copy() for index in target_indices]


def build_transition_rows_from_main(sources_dir: Path, transitions_dir: Path) -> list[Path]:
    state_cells: dict[str, list[Image.Image]] = {}
    for state, main_row in STATE_MAIN_ROWS.items():
        row_path = sources_dir / f"body_v13_1_main_{main_row}_16.png"
        state_cells[state] = strip_cells(row_path)

    built: list[Path] = []
    for name in TRANSITION_ROWS:
        source_state, target_state = TRANSITION_ENDPOINTS[name]
        cells = compose_transition_cells(state_cells[source_state], state_cells[target_state])
        out = transitions_dir / f"body_v13_1_transition_{name}_16.png"
        write_strip(cells, out)
        built.append(out)
        print(f"Wrote {out} from main rows: {STATE_MAIN_ROWS[source_state]} -> {STATE_MAIN_ROWS[target_state]}")
    return built


def make_preview(sheet_path: Path, out: Path, rows: int) -> None:
    sheet = Image.open(sheet_path).convert("RGBA")
    preview_scale = 0.25
    preview = sheet.resize(
        (round(sheet.width * preview_scale), round(sheet.height * preview_scale)),
        Image.Resampling.NEAREST,
    )
    out.parent.mkdir(parents=True, exist_ok=True)
    preview.save(out)


def build_rows(rows: list[RowBuild], helper: Path, force: bool, skip_chroma: bool) -> list[Path]:
    built: list[Path] = []
    for row in rows:
        if not skip_chroma:
            remove_chroma(helper, row.source, row.alpha, force=force)
        if not row.alpha.exists():
            raise FileNotFoundError(row.alpha)
        report = normalize_4x4_grid(
            row.alpha,
            row.strip,
            target_height=row.target_height,
            anchor_x=128,
            anchor_y=219,
            horizontal_margin=4,
        )
        print(f"Wrote {row.strip}")
        for line in report:
            print(f"  {line}")
        built.append(row.strip)
    return built


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", type=Path, default=Path.cwd())
    parser.add_argument("--helper", type=Path, default=Path("C:/Users/A/.codex/skills/.system/imagegen/scripts/remove_chroma_key.py"))
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--skip-chroma", action="store_true")
    parser.add_argument("--main-only", action="store_true")
    parser.add_argument("--transitions-only", action="store_true")
    args = parser.parse_args()

    project = args.project
    rider_dir = project / "resources" / "flight" / "rider"
    sources_dir = rider_dir / "body_v13_1_sources"
    transitions_dir = rider_dir / "body_v13_1_transitions"

    main_builds = [
        RowBuild(
            name=name,
            source=sources_dir / f"body_v13_1_main_{name}_16_chroma.png",
            alpha=sources_dir / f"body_v13_1_main_{name}_16_alpha_raw.png",
            strip=sources_dir / f"body_v13_1_main_{name}_16.png",
            target_height=TARGET_HEIGHTS[name],
        )
        for name in MAIN_ROWS
    ]
    transition_builds = [
        RowBuild(
            name=name,
            source=transitions_dir / f"body_v13_1_transition_{name}_16_chroma.png",
            alpha=transitions_dir / f"body_v13_1_transition_{name}_16_alpha_raw.png",
            strip=transitions_dir / f"body_v13_1_transition_{name}_16.png",
            target_height=TRANSITION_TARGET_HEIGHT,
        )
        for name in TRANSITION_ROWS
    ]

    if args.main_only and args.transitions_only:
        raise SystemExit("Use at most one of --main-only or --transitions-only")

    if not args.transitions_only:
        main_strips = build_rows(main_builds, args.helper, force=args.force, skip_chroma=args.skip_chroma)
        main_sheet = rider_dir / "flight_rider_body_v13_1_sheet.png"
        stitch(main_strips, main_sheet)
        make_preview(main_sheet, project / "tmp" / "v13_1_main_sheet_preview.png", rows=len(MAIN_ROWS))
        print(f"Wrote {main_sheet}")

    if not args.main_only:
        if all(row.source.exists() for row in transition_builds):
            transition_strips = build_rows(transition_builds, args.helper, force=args.force, skip_chroma=args.skip_chroma)
        else:
            print("No complete transition chroma source set found; composing V13.1 transitions from main rows for identity consistency.")
            transition_strips = build_transition_rows_from_main(sources_dir, transitions_dir)
        transition_sheet = rider_dir / "flight_rider_body_v13_1_transitions.png"
        stitch(transition_strips, transition_sheet)
        make_preview(transition_sheet, project / "tmp" / "v13_1_transition_sheet_preview.png", rows=len(TRANSITION_ROWS))
        print(f"Wrote {transition_sheet}")


if __name__ == "__main__":
    main()
