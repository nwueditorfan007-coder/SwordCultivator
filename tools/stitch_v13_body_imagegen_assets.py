#!/usr/bin/env python3
"""Stitch normalized V13 body strips into runtime atlases."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


FRAME_WIDTH = 256
FRAME_HEIGHT = 256
FRAME_COUNT = 16

MAIN_ROWS = (
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
)

TRANSITION_ROWS = (
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
)


def load_strip(path: Path) -> Image.Image:
    if not path.exists():
        raise SystemExit(f"missing strip: {path}")
    img = Image.open(path).convert("RGBA")
    expected = (FRAME_WIDTH * FRAME_COUNT, FRAME_HEIGHT)
    if img.size != expected:
        raise SystemExit(f"{path} size is {img.size}, expected {expected}")
    return img


def stitch(paths: list[Path], out: Path) -> None:
    atlas = Image.new("RGBA", (FRAME_WIDTH * FRAME_COUNT, FRAME_HEIGHT * len(paths)), (0, 0, 0, 0))
    for row, path in enumerate(paths):
        atlas.alpha_composite(load_strip(path), (0, row * FRAME_HEIGHT))
    out.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(out)
    print(f"Wrote {out} ({atlas.size[0]}x{atlas.size[1]})")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, default=Path("resources/flight/rider/body_v13_sources"))
    parser.add_argument("--transition-dir", type=Path, default=Path("resources/flight/rider/body_v13_transitions"))
    parser.add_argument("--out-main", type=Path, default=Path("resources/flight/rider/flight_rider_body_v13_sheet.png"))
    parser.add_argument(
        "--out-transitions",
        type=Path,
        default=Path("resources/flight/rider/flight_rider_body_v13_transitions.png"),
    )
    args = parser.parse_args()

    main_paths = [args.source_dir / f"body_v13_main_{name}_16.png" for name in MAIN_ROWS]
    transition_paths = [
        args.transition_dir / f"body_v13_transition_{name}_16.png"
        for name in TRANSITION_ROWS
    ]

    stitch(main_paths, args.out_main)
    stitch(transition_paths, args.out_transitions)


if __name__ == "__main__":
    main()
