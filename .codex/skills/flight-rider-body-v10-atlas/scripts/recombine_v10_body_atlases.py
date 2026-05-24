#!/usr/bin/env python3
"""Recombine SwordCultivator flight rider body V10 atlases from source strips."""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Dict, Iterable, List, Sequence, Tuple

from PIL import Image


FRAME_WIDTH = 256
FRAME_HEIGHT = 256
FRAME_COUNT = 8
ROW_WIDTH = FRAME_WIDTH * FRAME_COUNT

FrameRef = Tuple[str, int]


MAIN_RECIPES: Dict[str, Sequence[FrameRef]] = {
    "idle": tuple(("idle", i) for i in range(8)),
    "forward": (("forward", 0), ("forward", 1), ("forward", 2), ("forward", 3), ("forward", 4), ("forward", 3), ("forward", 2), ("forward", 1)),
    "back": tuple(("back", i) for i in range(8)),
    "parry": tuple(("parry", i) for i in range(8)),
    "sword_control_idle": (("unsheath", 4), ("unsheath", 5), ("unsheath", 6), ("unsheath", 7), ("unsheath", 6), ("unsheath", 5), ("unsheath", 4), ("unsheath", 5)),
    # Sustained array states must read as held postures, not repeated morphing.
    "array_ring_idle": (("array_morph", 0), ("array_morph", 0), ("array_morph", 0), ("array_morph", 7), ("array_morph", 0), ("array_morph", 0), ("array_morph", 0), ("array_morph", 7)),
    "array_fan_idle": (("array_morph", 2), ("array_morph", 2), ("array_morph", 2), ("array_morph", 2), ("array_morph", 2), ("array_morph", 2), ("array_morph", 2), ("array_morph", 2)),
    "array_pierce_idle": (("array_morph", 3), ("array_morph", 3), ("array_morph", 3), ("array_morph", 3), ("array_morph", 3), ("array_morph", 3), ("array_morph", 3), ("array_morph", 3)),
    "array_ring_release": (("array_morph", 0), ("array_release", 1), ("array_release", 2), ("array_release", 3), ("array_release", 4), ("array_release", 5), ("array_release", 6), ("array_morph", 0)),
    "array_fan_release": (("array_morph", 2), ("array_release", 2), ("array_release", 3), ("array_release", 4), ("array_release", 5), ("array_release", 6), ("array_release", 3), ("array_morph", 2)),
    "array_pierce_release": (("array_morph", 3), ("array_release", 3), ("array_release", 4), ("array_release", 5), ("array_release", 6), ("array_release", 5), ("array_release", 4), ("array_morph", 3)),
}


TRANSITION_RECIPES: Dict[str, Sequence[FrameRef]] = {
    "idle_to_sword_control": (("idle", 0), ("idle", 1), ("idle", 2), ("idle", 3), ("unsheath", 4), ("unsheath", 5), ("unsheath", 6), ("unsheath", 4)),
    "sword_control_to_idle": (("unsheath", 4), ("unsheath", 5), ("unsheath", 6), ("unsheath", 7), ("idle", 4), ("idle", 5), ("idle", 6), ("idle", 0)),
    "idle_to_array_ring": (("idle", 0), ("idle", 1), ("idle", 2), ("idle", 3), ("array_morph", 0), ("array_morph", 0), ("array_morph", 0), ("array_morph", 0)),
    "array_ring_to_idle": (("array_morph", 0), ("array_morph", 0), ("array_morph", 7), ("array_morph", 0), ("idle", 4), ("idle", 5), ("idle", 6), ("idle", 0)),
    "idle_to_array_fan": (("idle", 0), ("idle", 1), ("idle", 2), ("idle", 3), ("array_morph", 0), ("array_morph", 1), ("array_morph", 2), ("array_morph", 2)),
    "array_fan_to_idle": (("array_morph", 2), ("array_morph", 2), ("array_morph", 1), ("array_morph", 0), ("idle", 4), ("idle", 5), ("idle", 6), ("idle", 0)),
    "idle_to_array_pierce": (("idle", 0), ("idle", 1), ("idle", 2), ("idle", 3), ("array_morph", 2), ("array_morph", 3), ("array_morph", 3), ("array_morph", 3)),
    "array_pierce_to_idle": (("array_morph", 3), ("array_morph", 3), ("array_morph", 2), ("array_morph", 0), ("idle", 4), ("idle", 5), ("idle", 6), ("idle", 0)),
    "array_ring_to_fan": (("array_morph", 0), ("array_morph", 0), ("array_morph", 7), ("array_morph", 1), ("array_morph", 2), ("array_morph", 2), ("array_morph", 2), ("array_morph", 2)),
    "array_fan_to_ring": (("array_morph", 2), ("array_morph", 2), ("array_morph", 2), ("array_morph", 1), ("array_morph", 7), ("array_morph", 0), ("array_morph", 0), ("array_morph", 0)),
    "array_fan_to_pierce": (("array_morph", 2), ("array_morph", 2), ("array_morph", 2), ("array_morph", 2), ("array_morph", 3), ("array_morph", 3), ("array_morph", 3), ("array_morph", 3)),
    "array_pierce_to_fan": (("array_morph", 3), ("array_morph", 3), ("array_morph", 3), ("array_morph", 3), ("array_morph", 2), ("array_morph", 2), ("array_morph", 2), ("array_morph", 2)),
    "array_pierce_to_ring": (("array_morph", 3), ("array_morph", 3), ("array_morph", 5), ("array_morph", 7), ("array_morph", 0), ("array_morph", 0), ("array_morph", 0), ("array_morph", 0)),
    "array_ring_to_pierce": (("array_morph", 0), ("array_morph", 0), ("array_morph", 1), ("array_morph", 2), ("array_morph", 3), ("array_morph", 3), ("array_morph", 3), ("array_morph", 3)),
}


def source_path(source_dir: Path, action: str) -> Path:
    return source_dir / f"body_v9_main_{action}_8.png"


def load_source_frames(source_dir: Path, actions: Iterable[str]) -> Dict[str, List[Image.Image]]:
    loaded: Dict[str, List[Image.Image]] = {}
    for action in sorted(set(actions)):
        path = source_path(source_dir, action)
        if not path.exists():
            raise SystemExit(f"Missing source strip: {path}")
        image = Image.open(path).convert("RGBA")
        if image.size != (ROW_WIDTH, FRAME_HEIGHT):
            raise SystemExit(f"{path}: expected {ROW_WIDTH}x{FRAME_HEIGHT}, got {image.size[0]}x{image.size[1]}")
        loaded[action] = [
            image.crop((index * FRAME_WIDTH, 0, (index + 1) * FRAME_WIDTH, FRAME_HEIGHT))
            for index in range(FRAME_COUNT)
        ]
    return loaded


def actions_used(recipes: Dict[str, Sequence[FrameRef]]) -> List[str]:
    return [action for row in recipes.values() for action, _frame in row]


def build_atlas(recipes: Dict[str, Sequence[FrameRef]], frames: Dict[str, List[Image.Image]]) -> Image.Image:
    atlas = Image.new("RGBA", (ROW_WIDTH, FRAME_HEIGHT * len(recipes)), (0, 0, 0, 0))
    for row_index, (row_name, recipe) in enumerate(recipes.items()):
        if len(recipe) != FRAME_COUNT:
            raise SystemExit(f"{row_name}: expected {FRAME_COUNT} frame refs, got {len(recipe)}")
        for frame_index, (source_action, source_frame_index) in enumerate(recipe):
            if source_frame_index < 0 or source_frame_index >= FRAME_COUNT:
                raise SystemExit(f"{row_name} frame {frame_index}: invalid source frame {source_frame_index}")
            atlas.paste(frames[source_action][source_frame_index], (frame_index * FRAME_WIDTH, row_index * FRAME_HEIGHT))
    return atlas


def save_atlas(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    print(f"Wrote {path} ({image.size[0]}x{image.size[1]})")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, default=Path("resources/flight/rider/body_v9_sources"))
    parser.add_argument("--out-main", type=Path, default=Path("resources/flight/rider/flight_rider_body_v10_sheet.png"))
    parser.add_argument("--out-transitions", type=Path, default=Path("resources/flight/rider/flight_rider_body_v10_transitions.png"))
    parser.add_argument("--main-only", action="store_true")
    parser.add_argument("--transitions-only", action="store_true")
    args = parser.parse_args()

    if args.main_only and args.transitions_only:
        raise SystemExit("Choose at most one of --main-only or --transitions-only.")

    selected_recipes: List[Dict[str, Sequence[FrameRef]]] = []
    if not args.transitions_only:
        selected_recipes.append(MAIN_RECIPES)
    if not args.main_only:
        selected_recipes.append(TRANSITION_RECIPES)

    needed_actions = [action for recipes in selected_recipes for action in actions_used(recipes)]
    frames = load_source_frames(args.source_dir, needed_actions)

    if not args.transitions_only:
        save_atlas(build_atlas(MAIN_RECIPES, frames), args.out_main)
    if not args.main_only:
        save_atlas(build_atlas(TRANSITION_RECIPES, frames), args.out_transitions)


if __name__ == "__main__":
    main()
