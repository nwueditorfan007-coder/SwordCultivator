#!/usr/bin/env python3
"""Replace one horizontal sprite-strip row inside a larger atlas.

Rows are 1-based at the command line because production task packages list rows
that way. The script clears the destination row before alpha-compositing the
replacement strip.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sheet", required=True, type=Path, help="Input atlas or runtime sheet PNG.")
    parser.add_argument("--strip", required=True, type=Path, help="Replacement horizontal strip PNG.")
    parser.add_argument("--row", required=True, type=int, help="1-based destination row number.")
    parser.add_argument("--cell-height", type=int, default=256)
    parser.add_argument("--out", type=Path, help="Output PNG. Omit only when using --in-place.")
    parser.add_argument("--in-place", action="store_true", help="Overwrite --sheet.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.row < 1:
        raise SystemExit("--row must be 1-based and greater than zero")
    if args.in_place and args.out:
        raise SystemExit("Use either --in-place or --out, not both")
    if not args.in_place and not args.out:
        raise SystemExit("Provide --out or --in-place")

    sheet = Image.open(args.sheet).convert("RGBA")
    strip = Image.open(args.strip).convert("RGBA")

    if strip.height != args.cell_height:
        raise SystemExit(f"{args.strip}: expected strip height {args.cell_height}, got {strip.height}")
    if sheet.width != strip.width:
        raise SystemExit(f"Width mismatch: sheet {sheet.width}px, strip {strip.width}px")
    if sheet.height % args.cell_height != 0:
        raise SystemExit(f"{args.sheet}: height {sheet.height} is not divisible by {args.cell_height}")

    row_count = sheet.height // args.cell_height
    if args.row > row_count:
        raise SystemExit(f"--row {args.row} is outside sheet row count {row_count}")

    y = (args.row - 1) * args.cell_height
    clear = Image.new("RGBA", (sheet.width, args.cell_height), (0, 0, 0, 0))
    sheet.paste(clear, (0, y))
    sheet.alpha_composite(strip, (0, y))

    out = args.sheet if args.in_place else args.out
    assert out is not None
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"Wrote {out}")
    print(f"Replaced row {args.row}/{row_count} at y={y} with {args.strip}")


if __name__ == "__main__":
    main()
