#!/usr/bin/env python3
"""Build SwordCultivator flight rider body V12 source strips and atlases.

This pass keeps the existing character identity and transparent pixel-art style,
then recomposes V12-specific sustained poses, releases, and transitions into the
fixed runtime atlas layout described by the V12 body animation task package.
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path
from typing import Callable, Iterable

from PIL import Image


FRAME_WIDTH = 256
FRAME_HEIGHT = 256
FRAME_COUNT = 8
ROW_WIDTH = FRAME_WIDTH * FRAME_COUNT
ANCHOR_X = 128
ANCHOR_Y = 219

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

BREATH_PHASES = (0, 1, 2, 3, 4, 5, 6, 0)
HAIR_X = (0, -1, -1, -1, 0, 1, 1, 0)
HAIR_Y = (0, 0, -1, -1, 0, 1, 1, 0)
ROBE_X = (0, -1, -1, 0, 0, 1, 1, 0)
ROBE_Y = (0, 0, 1, 1, 0, 0, -1, 0)


FrameFilter = Callable[[int, int, int, int, int, int], bool]


def strip_path(source_dir: Path, version: str, name: str) -> Path:
    return source_dir / f"body_{version}_main_{name}_8.png"


def load_strip(path: Path) -> list[Image.Image]:
    image = Image.open(path).convert("RGBA")
    if image.size != (ROW_WIDTH, FRAME_HEIGHT):
        raise SystemExit(f"{path}: expected {ROW_WIDTH}x{FRAME_HEIGHT}, got {image.size[0]}x{image.size[1]}")
    return [
        image.crop((index * FRAME_WIDTH, 0, (index + 1) * FRAME_WIDTH, FRAME_HEIGHT))
        for index in range(FRAME_COUNT)
    ]


def save_strip(frames: Iterable[Image.Image], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGBA", (ROW_WIDTH, FRAME_HEIGHT), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        if index >= FRAME_COUNT:
            break
        sheet.alpha_composite(anchor_frame(frame), (index * FRAME_WIDTH, 0))
    sheet.save(path)
    print(f"Wrote {path}")


def save_atlas(rows: Iterable[list[Image.Image]], path: Path) -> None:
    row_list = list(rows)
    atlas = Image.new("RGBA", (ROW_WIDTH, FRAME_HEIGHT * len(row_list)), (0, 0, 0, 0))
    for row_index, frames in enumerate(row_list):
        for frame_index, frame in enumerate(frames):
            atlas.alpha_composite(anchor_frame(frame), (frame_index * FRAME_WIDTH, row_index * FRAME_HEIGHT))
    path.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(path)
    print(f"Wrote {path} ({atlas.size[0]}x{atlas.size[1]})")


def blank_frame() -> Image.Image:
    return Image.new("RGBA", (FRAME_WIDTH, FRAME_HEIGHT), (0, 0, 0, 0))


def frame_bounds(frame: Image.Image) -> tuple[int, int, int, int] | None:
    return frame.getchannel("A").getbbox()


def shift_frame(frame: Image.Image, dx: int = 0, dy: int = 0) -> Image.Image:
    shifted = blank_frame()
    shifted.alpha_composite(frame, (dx, dy))
    return shifted


def foot_anchor_x(frame: Image.Image, bbox: tuple[int, int, int, int]) -> int:
    alpha = frame.getchannel("A")
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


def anchor_frame(frame: Image.Image) -> Image.Image:
    image = frame.convert("RGBA")
    bbox = frame_bounds(image)
    if not bbox:
        return image
    dx = ANCHOR_X - foot_anchor_x(image, bbox)
    dy = ANCHOR_Y - (bbox[3] - 1)
    return shift_frame(image, dx, dy)


def make_mask(frame: Image.Image, selector: FrameFilter) -> Image.Image:
    mask = Image.new("L", frame.size, 0)
    source = frame.convert("RGBA")
    pixels = source.load()
    mask_pixels = mask.load()
    for y in range(FRAME_HEIGHT):
        for x in range(FRAME_WIDTH):
            r, g, b, a = pixels[x, y]
            if a > 16 and selector(x, y, r, g, b, a):
                mask_pixels[x, y] = a
    return mask


def shift_region(frame: Image.Image, mask: Image.Image, dx: int, dy: int) -> Image.Image:
    if dx == 0 and dy == 0:
        return frame.copy()
    static = frame.copy()
    static_alpha = static.getchannel("A")
    erase = Image.new("L", frame.size, 0)
    static_alpha = Image.composite(erase, static_alpha, mask)
    static.putalpha(static_alpha)

    moving = frame.copy()
    moving.putalpha(mask)
    shifted_moving = shift_frame(moving, dx, dy)

    result = blank_frame()
    result.alpha_composite(static)
    result.alpha_composite(shifted_moving)
    return result


def is_hair_or_ribbon(_x: int, y: int, r: int, g: int, b: int, _a: int) -> bool:
    if y > 124:
        return False
    blue_ribbon = b > 135 and g > 70 and r < 110
    dark_hair = r < 45 and g < 55 and b < 75
    return blue_ribbon or dark_hair


def is_outer_robe_or_sleeve(x: int, y: int, r: int, g: int, b: int, _a: int) -> bool:
    if y < 96 or y > 205:
        return False
    teal_cloth = b > 58 and g > 48 and r < 55
    outer_edge = x < 96 or x > 148
    return teal_cloth and outer_edge


def subtle_breath(frame: Image.Image, phase: int) -> Image.Image:
    phase = phase % len(BREATH_PHASES)
    image = anchor_frame(frame)
    hair_mask = make_mask(image, is_hair_or_ribbon)
    image = shift_region(image, hair_mask, HAIR_X[phase], HAIR_Y[phase])
    robe_mask = make_mask(image, is_outer_robe_or_sleeve)
    image = shift_region(image, robe_mask, ROBE_X[phase], ROBE_Y[phase])
    return drop_tiny_components(anchor_frame(image), min_area=10)


def breath_loop(base_frame: Image.Image) -> list[Image.Image]:
    return [subtle_breath(base_frame, phase) for phase in BREATH_PHASES]


def drop_tiny_components(frame: Image.Image, min_area: int) -> Image.Image:
    alpha = frame.getchannel("A")
    pixels = alpha.load()
    visited = bytearray(FRAME_WIDTH * FRAME_HEIGHT)
    keep = Image.new("L", frame.size, 0)
    keep_pixels = keep.load()

    for start_y in range(FRAME_HEIGHT):
        for start_x in range(FRAME_WIDTH):
            index = start_y * FRAME_WIDTH + start_x
            if visited[index] or pixels[start_x, start_y] <= 16:
                continue
            queue = deque([(start_x, start_y)])
            component: list[tuple[int, int]] = []
            visited[index] = 1
            while queue:
                x, y = queue.popleft()
                component.append((x, y))
                for next_y in (y - 1, y, y + 1):
                    if next_y < 0 or next_y >= FRAME_HEIGHT:
                        continue
                    base = next_y * FRAME_WIDTH
                    for next_x in (x - 1, x, x + 1):
                        if next_x < 0 or next_x >= FRAME_WIDTH:
                            continue
                        next_index = base + next_x
                        if visited[next_index] or pixels[next_x, next_y] <= 16:
                            continue
                        visited[next_index] = 1
                        queue.append((next_x, next_y))
            if len(component) >= min_area:
                for x, y in component:
                    keep_pixels[x, y] = pixels[x, y]

    result = frame.copy()
    result.putalpha(keep)
    return result


def select_frames(frames: list[Image.Image], indices: Iterable[int]) -> list[Image.Image]:
    return [drop_tiny_components(anchor_frame(frames[index]), min_area=10) for index in indices]


def first_last_locked(first: Image.Image, middle: Iterable[Image.Image], last: Image.Image) -> list[Image.Image]:
    row = [anchor_frame(first)]
    row.extend(anchor_frame(frame) for frame in middle)
    row = row[: FRAME_COUNT - 1]
    while len(row) < FRAME_COUNT - 1:
        row.append(anchor_frame(row[-1]))
    row.append(anchor_frame(last))
    return row


def reverse_transition(frames: list[Image.Image], first: Image.Image, last: Image.Image) -> list[Image.Image]:
    middle = list(reversed(frames[1:-1]))
    return first_last_locked(first, middle, last)


def copy_main_sources(source_dir: Path, fallback_dir: Path) -> dict[str, list[Image.Image]]:
    loaded: dict[str, list[Image.Image]] = {}
    source_map = {
        "idle": "idle",
        "forward": "forward",
        "back": "back",
        "parry": "parry",
        "unsheath": "unsheath",
        "array_morph": "array_morph",
        "array_release": "array_release",
    }
    for output_name, input_name in source_map.items():
        path = strip_path(source_dir, "v11", input_name)
        if not path.exists():
            path = strip_path(fallback_dir, "v9", input_name)
        if not path.exists():
            raise SystemExit(f"Missing source strip for {input_name}: {path}")
        loaded[output_name] = load_strip(path)
    return loaded


def build_assets(source_dir: Path, fallback_dir: Path, out_source_dir: Path, out_transition_dir: Path) -> tuple[dict[str, list[Image.Image]], dict[str, list[Image.Image]]]:
    source = copy_main_sources(source_dir, fallback_dir)

    idle = select_frames(source["idle"], range(FRAME_COUNT))
    forward = select_frames(source["forward"], (0, 1, 2, 3, 4, 3, 2, 1))
    back = select_frames(source["back"], range(FRAME_COUNT))
    parry = select_frames(source["parry"], range(FRAME_COUNT))

    morph = source["array_morph"]
    release = source["array_release"]
    unsheath = source["unsheath"]

    sword_control = breath_loop(unsheath[4])
    ring_idle = breath_loop(morph[0])
    fan_idle = breath_loop(morph[2])
    pierce_idle = breath_loop(morph[3])

    ring_release = first_last_locked(
        ring_idle[0],
        select_frames(release, (0, 1, 2, 3, 2, 1)),
        ring_idle[0],
    )
    fan_release = first_last_locked(
        fan_idle[0],
        select_frames(release, (2, 3, 4, 5, 4, 3)),
        fan_idle[0],
    )
    pierce_release = first_last_locked(
        pierce_idle[0],
        select_frames(release, (3, 4, 5, 6, 5, 4)),
        pierce_idle[0],
    )

    main_rows = {
        "idle": idle,
        "forward": forward,
        "back": back,
        "parry": parry,
        "sword_control_idle": sword_control,
        "array_ring_idle": ring_idle,
        "array_fan_idle": fan_idle,
        "array_pierce_idle": pierce_idle,
        "array_ring_release": ring_release,
        "array_fan_release": fan_release,
        "array_pierce_release": pierce_release,
    }

    for name in MAIN_ROWS:
        save_strip(main_rows[name], out_source_dir / f"body_v12_main_{name}_8.png")

    transitions: dict[str, list[Image.Image]] = {}
    transitions["idle_to_sword_control"] = first_last_locked(
        idle[0],
        [idle[1], idle[2], *select_frames(unsheath, (1, 2, 3, 4))],
        sword_control[0],
    )
    transitions["sword_control_to_idle"] = reverse_transition(
        transitions["idle_to_sword_control"], sword_control[0], idle[0]
    )

    transitions["idle_to_array_ring"] = first_last_locked(
        idle[0], [idle[1], idle[2], *select_frames(morph, (5, 7, 0, 0))], ring_idle[0]
    )
    transitions["array_ring_to_idle"] = reverse_transition(
        transitions["idle_to_array_ring"], ring_idle[0], idle[0]
    )
    transitions["idle_to_array_fan"] = first_last_locked(
        idle[0], [idle[1], idle[2], *select_frames(morph, (0, 1, 2, 2))], fan_idle[0]
    )
    transitions["array_fan_to_idle"] = reverse_transition(
        transitions["idle_to_array_fan"], fan_idle[0], idle[0]
    )
    transitions["idle_to_array_pierce"] = first_last_locked(
        idle[0], [idle[1], idle[2], *select_frames(morph, (1, 2, 3, 3))], pierce_idle[0]
    )
    transitions["array_pierce_to_idle"] = reverse_transition(
        transitions["idle_to_array_pierce"], pierce_idle[0], idle[0]
    )

    transitions["array_ring_to_fan"] = first_last_locked(
        ring_idle[0], [ring_idle[1], *select_frames(morph, (7, 1, 2, 2)), fan_idle[1]], fan_idle[0]
    )
    transitions["array_fan_to_ring"] = first_last_locked(
        fan_idle[0], [fan_idle[1], *select_frames(morph, (2, 1, 7, 0)), ring_idle[1]], ring_idle[0]
    )
    transitions["array_fan_to_pierce"] = first_last_locked(
        fan_idle[0], [fan_idle[1], *select_frames(morph, (2, 2, 3, 3)), pierce_idle[1]], pierce_idle[0]
    )
    transitions["array_pierce_to_fan"] = first_last_locked(
        pierce_idle[0], [pierce_idle[1], *select_frames(morph, (3, 2, 2, 2)), fan_idle[1]], fan_idle[0]
    )
    transitions["array_pierce_to_ring"] = first_last_locked(
        pierce_idle[0], [pierce_idle[1], *select_frames(morph, (3, 5, 7, 0)), ring_idle[1]], ring_idle[0]
    )
    transitions["array_ring_to_pierce"] = first_last_locked(
        ring_idle[0], [ring_idle[1], *select_frames(morph, (7, 1, 2, 3)), pierce_idle[1]], pierce_idle[0]
    )

    for name in TRANSITION_ROWS:
        save_strip(transitions[name], out_transition_dir / f"body_v12_transition_{name}_8.png")

    return main_rows, transitions


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, default=Path("resources/flight/rider/body_v11_sources"))
    parser.add_argument("--fallback-dir", type=Path, default=Path("resources/flight/rider/body_v9_sources"))
    parser.add_argument("--out-source-dir", type=Path, default=Path("resources/flight/rider/body_v12_sources"))
    parser.add_argument("--out-transition-dir", type=Path, default=Path("resources/flight/rider/body_v12_transitions"))
    parser.add_argument("--out-main", type=Path, default=Path("resources/flight/rider/flight_rider_body_v12_sheet.png"))
    parser.add_argument("--out-transitions", type=Path, default=Path("resources/flight/rider/flight_rider_body_v12_transitions.png"))
    args = parser.parse_args()

    main_rows, transitions = build_assets(
        source_dir=args.source_dir,
        fallback_dir=args.fallback_dir,
        out_source_dir=args.out_source_dir,
        out_transition_dir=args.out_transition_dir,
    )
    save_atlas((main_rows[name] for name in MAIN_ROWS), args.out_main)
    save_atlas((transitions[name] for name in TRANSITION_ROWS), args.out_transitions)


if __name__ == "__main__":
    main()
