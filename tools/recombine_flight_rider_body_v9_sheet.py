#!/usr/bin/env python3
"""Recombine Rider Body V9 source strips into the runtime body sheet."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


ROWS = (
    "idle",
    "forward",
    "back",
    "parry",
    "unsheath",
    "array_release",
    "array_morph",
)
FRAME_WIDTH = 256
FRAME_HEIGHT = 256
FRAME_COUNT = 8


def recombine(source_dir: Path, out: Path) -> None:
    row_width = FRAME_WIDTH * FRAME_COUNT
    sheet = Image.new("RGBA", (row_width, FRAME_HEIGHT * len(ROWS)), (0, 0, 0, 0))

    for row_index, row_name in enumerate(ROWS):
        path = source_dir / f"body_v9_main_{row_name}_8.png"
        row = Image.open(path).convert("RGBA")
        if row.size != (row_width, FRAME_HEIGHT):
            raise SystemExit(f"{path}: expected {row_width}x{FRAME_HEIGHT}, got {row.size[0]}x{row.size[1]}")
        sheet.paste(row, (0, row_index * FRAME_HEIGHT))

    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"Wrote {out}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source-dir",
        type=Path,
        default=Path("resources/flight/rider/body_v9_sources"),
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=Path("resources/flight/rider/flight_rider_body_v9_sheet.png"),
    )
    args = parser.parse_args()

    recombine(args.source_dir, args.out)


if __name__ == "__main__":
    main()
