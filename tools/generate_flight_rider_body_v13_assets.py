#!/usr/bin/env python3
"""Generate V13 flight rider body sprites from one locked character template."""

from __future__ import annotations

import argparse
import math
from copy import deepcopy
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw


FRAME_WIDTH = 256
FRAME_HEIGHT = 256
FRAME_COUNT = 16
ANCHOR_Y = 219
SCALE = 4

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

PALETTE = {
    "outline": (8, 13, 18, 255),
    "hair": (14, 17, 22, 255),
    "skin": (236, 196, 154, 255),
    "skin_shadow": (171, 112, 82, 255),
    "robe_dark": (10, 42, 51, 255),
    "robe_mid": (16, 80, 92, 255),
    "robe_light": (39, 131, 145, 255),
    "inner": (224, 239, 238, 255),
    "inner_shadow": (145, 177, 177, 255),
    "pants": (21, 30, 41, 255),
    "gold": (210, 164, 69, 255),
    "gold_dark": (113, 78, 31, 255),
    "ribbon": (70, 190, 255, 255),
    "ribbon_core": (206, 246, 255, 255),
}

Point = tuple[float, float]
State = dict[str, object]


def smoothstep(t: float) -> float:
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)


def wave(phase: float) -> float:
    return math.sin(phase * math.tau)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def lerp_point(a: Point, b: Point, t: float) -> Point:
    return (lerp(a[0], b[0], t), lerp(a[1], b[1], t))


def scaled_point(point: Point) -> tuple[int, int]:
    return (round(point[0] * SCALE), round(point[1] * SCALE))


def scaled_points(points: Iterable[Point]) -> list[tuple[int, int]]:
    return [scaled_point(point) for point in points]


def offset(point: Point, dx: float = 0.0, dy: float = 0.0) -> Point:
    return (point[0] + dx, point[1] + dy)


def line(draw: ImageDraw.ImageDraw, points: Iterable[Point], fill: tuple[int, int, int, int], width: float) -> None:
    draw.line(scaled_points(points), fill=fill, width=max(1, round(width * SCALE)))


def polygon(
    draw: ImageDraw.ImageDraw,
    points: Iterable[Point],
    fill: tuple[int, int, int, int],
    outline: tuple[int, int, int, int] | None = None,
    outline_width: float = 1.0,
) -> None:
    point_list = list(points)
    draw.polygon(scaled_points(point_list), fill=fill)
    if outline:
        closed = point_list + [point_list[0]]
        line(draw, closed, outline, outline_width)


def ellipse(
    draw: ImageDraw.ImageDraw,
    center: Point,
    radius_x: float,
    radius_y: float,
    fill: tuple[int, int, int, int],
    outline: tuple[int, int, int, int] | None = None,
    outline_width: float = 1.0,
) -> None:
    x, y = center
    box = (
        round((x - radius_x) * SCALE),
        round((y - radius_y) * SCALE),
        round((x + radius_x) * SCALE),
        round((y + radius_y) * SCALE),
    )
    draw.ellipse(box, fill=fill)
    if outline:
        draw.ellipse(box, outline=outline, width=max(1, round(outline_width * SCALE)))


def state_template() -> State:
    return {
        "head": (137.0, 65.0),
        "neck": (132.0, 82.0),
        "shoulder": (126.0, 101.0),
        "belt": (124.0, 139.0),
        "pelvis": (124.0, 164.0),
        "foot_l": (108.0, 219.0),
        "knee_l": (114.0, 187.0),
        "foot_r": (145.0, 219.0),
        "knee_r": (140.0, 187.0),
        "robe_back": (88.0, 207.0),
        "robe_front": (154.0, 211.0),
        "hair_wind": 0.0,
        "back_arm": ((114.0, 102.0), (103.0, 126.0), (108.0, 148.0)),
        "front_arm": ((136.0, 103.0), (145.0, 126.0), (140.0, 148.0)),
    }


def pose_state(name: str) -> State:
    st = state_template()
    if name == "idle":
        return st
    if name == "forward":
        st.update(
            {
                "head": (160.0, 82.0),
                "neck": (156.0, 99.0),
                "shoulder": (150.0, 116.0),
                "belt": (139.0, 152.0),
                "pelvis": (131.0, 166.0),
                "foot_l": (101.0, 219.0),
                "knee_l": (116.0, 190.0),
                "foot_r": (173.0, 219.0),
                "knee_r": (158.0, 186.0),
                "robe_back": (88.0, 205.0),
                "robe_front": (168.0, 210.0),
                "hair_wind": 2.0,
                "back_arm": ((137.0, 117.0), (129.0, 141.0), (119.0, 157.0)),
                "front_arm": ((162.0, 118.0), (171.0, 142.0), (181.0, 155.0)),
            }
        )
        return st
    if name == "back":
        st.update(
            {
                "head": (111.0, 75.0),
                "neck": (115.0, 92.0),
                "shoulder": (116.0, 109.0),
                "belt": (122.0, 148.0),
                "pelvis": (130.0, 166.0),
                "foot_l": (96.0, 219.0),
                "knee_l": (110.0, 188.0),
                "foot_r": (160.0, 219.0),
                "knee_r": (145.0, 190.0),
                "robe_back": (95.0, 209.0),
                "robe_front": (163.0, 207.0),
                "hair_wind": -1.4,
                "back_arm": ((104.0, 110.0), (95.0, 134.0), (102.0, 153.0)),
                "front_arm": ((128.0, 110.0), (135.0, 134.0), (129.0, 153.0)),
            }
        )
        return st
    if name == "sword_control_idle":
        st.update(
            {
                "foot_l": (105.0, 219.0),
                "foot_r": (151.0, 219.0),
                "knee_l": (113.0, 187.0),
                "knee_r": (142.0, 187.0),
                "back_arm": ((114.0, 102.0), (119.0, 126.0), (126.0, 141.0)),
                "front_arm": ((136.0, 103.0), (155.0, 121.0), (170.0, 129.0)),
            }
        )
        return st
    if name == "array_ring_idle":
        st.update(
            {
                "foot_l": (103.0, 219.0),
                "foot_r": (151.0, 219.0),
                "knee_l": (112.0, 187.0),
                "knee_r": (143.0, 188.0),
                "back_arm": ((114.0, 102.0), (113.0, 127.0), (126.0, 142.0)),
                "front_arm": ((136.0, 103.0), (143.0, 126.0), (132.0, 143.0)),
                "robe_back": (87.0, 207.0),
                "robe_front": (157.0, 211.0),
            }
        )
        return st
    if name == "array_fan_idle":
        st.update(
            {
                "foot_l": (102.0, 219.0),
                "foot_r": (152.0, 219.0),
                "knee_l": (112.0, 187.0),
                "knee_r": (144.0, 187.0),
                "back_arm": ((114.0, 102.0), (96.0, 117.0), (82.0, 130.0)),
                "front_arm": ((136.0, 103.0), (158.0, 113.0), (182.0, 123.0)),
                "robe_back": (85.0, 206.0),
                "robe_front": (160.0, 210.0),
                "hair_wind": 0.9,
            }
        )
        return st
    if name == "array_pierce_idle":
        st.update(
            {
                "foot_l": (103.0, 219.0),
                "foot_r": (152.0, 219.0),
                "knee_l": (112.0, 187.0),
                "knee_r": (143.0, 187.0),
                "back_arm": ((114.0, 102.0), (121.0, 124.0), (128.0, 139.0)),
                "front_arm": ((136.0, 103.0), (160.0, 111.0), (187.0, 116.0)),
                "robe_front": (161.0, 210.0),
                "hair_wind": 1.2,
            }
        )
        return st
    if name == "parry_ready":
        st = pose_state("array_ring_idle")
        st["shoulder"] = (124.0, 105.0)
        st["head"] = (135.0, 67.0)
        st["back_arm"] = ((113.0, 106.0), (111.0, 128.0), (122.0, 145.0))
        st["front_arm"] = ((136.0, 106.0), (148.0, 126.0), (160.0, 138.0))
        return st
    if name == "parry_peak":
        st = pose_state("array_fan_idle")
        st["shoulder"] = (134.0, 106.0)
        st["head"] = (143.0, 68.0)
        st["back_arm"] = ((122.0, 107.0), (102.0, 117.0), (90.0, 132.0))
        st["front_arm"] = ((145.0, 107.0), (168.0, 120.0), (191.0, 138.0))
        st["robe_front"] = (166.0, 210.0)
        st["hair_wind"] = 2.0
        return st
    if name == "parry_follow":
        st = pose_state("sword_control_idle")
        st["shoulder"] = (135.0, 105.0)
        st["head"] = (143.0, 68.0)
        st["front_arm"] = ((145.0, 106.0), (164.0, 129.0), (175.0, 154.0))
        st["back_arm"] = ((122.0, 106.0), (116.0, 133.0), (125.0, 152.0))
        st["robe_front"] = (163.0, 211.0)
        st["hair_wind"] = 1.5
        return st
    if name == "ring_release_peak":
        st = pose_state("array_ring_idle")
        st["back_arm"] = ((114.0, 102.0), (104.0, 125.0), (92.0, 143.0))
        st["front_arm"] = ((136.0, 103.0), (153.0, 124.0), (171.0, 141.0))
        st["robe_front"] = (164.0, 210.0)
        return st
    if name == "fan_release_peak":
        st = pose_state("array_fan_idle")
        st["back_arm"] = ((114.0, 102.0), (93.0, 110.0), (73.0, 119.0))
        st["front_arm"] = ((136.0, 103.0), (165.0, 110.0), (196.0, 119.0))
        st["robe_front"] = (166.0, 210.0)
        st["hair_wind"] = 1.9
        return st
    if name == "pierce_release_peak":
        st = pose_state("array_pierce_idle")
        st["shoulder"] = (136.0, 102.0)
        st["head"] = (145.0, 65.0)
        st["front_arm"] = ((146.0, 103.0), (174.0, 108.0), (202.0, 111.0))
        st["back_arm"] = ((123.0, 103.0), (119.0, 126.0), (127.0, 142.0))
        st["robe_front"] = (166.0, 210.0)
        st["hair_wind"] = 2.1
        return st
    raise ValueError(f"Unknown pose state: {name}")


def mix_value(a: object, b: object, t: float) -> object:
    if isinstance(a, tuple) and len(a) == 2 and isinstance(a[0], (int, float)):
        return lerp_point(a, b, t)  # type: ignore[arg-type]
    if isinstance(a, tuple) and a and isinstance(a[0], tuple):
        return tuple(mix_value(a_item, b_item, t) for a_item, b_item in zip(a, b))  # type: ignore[arg-type]
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        return lerp(float(a), float(b), t)
    return deepcopy(b if t >= 0.5 else a)


def mix_state(a: State, b: State, t: float) -> State:
    return {key: mix_value(a[key], b[key], t) for key in a.keys()}


def apply_motion(st: State, phase: float, amount: float = 1.0, robe_bias: float = 0.0) -> State:
    result = deepcopy(st)
    breath = wave(phase)
    sway = wave(phase + 0.18)
    for arm_key in ("back_arm", "front_arm"):
        shoulder, elbow, hand = result[arm_key]  # type: ignore[misc]
        result[arm_key] = (
            shoulder,
            offset(elbow, 0.0, -breath * amount),
            offset(hand, sway * amount * 0.7, -breath * amount * 1.2),
        )
    result["robe_back"] = offset(result["robe_back"], -sway * amount * 0.7 - robe_bias, breath * amount * 0.8)  # type: ignore[arg-type]
    result["robe_front"] = offset(result["robe_front"], sway * amount * 0.7 + robe_bias, -breath * amount * 0.5)  # type: ignore[arg-type]
    result["hair_wind"] = float(result["hair_wind"]) + sway * amount * 0.7
    return result


def release_state(mode: str, progress: float) -> State:
    base = pose_state(f"array_{mode}_idle")
    peak = pose_state(f"{mode}_release_peak")
    if progress < 0.18:
        return apply_motion(base, progress, 0.35)
    if progress > 0.86:
        return apply_motion(base, progress, 0.35)
    pulse = math.sin((progress - 0.18) / 0.68 * math.pi)
    return apply_motion(mix_state(base, peak, smoothstep(pulse)), progress, 0.45, robe_bias=pulse * 1.5)


def parry_state(progress: float) -> State:
    idle = pose_state("array_ring_idle")
    ready = pose_state("parry_ready")
    peak = pose_state("parry_peak")
    follow = pose_state("parry_follow")
    if progress < 0.2:
        return mix_state(idle, ready, smoothstep(progress / 0.2))
    if progress < 0.48:
        return mix_state(ready, peak, smoothstep((progress - 0.2) / 0.28))
    if progress < 0.70:
        return mix_state(peak, follow, smoothstep((progress - 0.48) / 0.22))
    return mix_state(follow, ready, smoothstep((progress - 0.70) / 0.30))


def action_state(action: str, index: int) -> State:
    phase = index / float(FRAME_COUNT - 1)
    if action in {"idle", "sword_control_idle", "array_ring_idle", "array_fan_idle", "array_pierce_idle"}:
        amount = 0.45 if action == "idle" else 0.65
        return apply_motion(pose_state(action), phase, amount)
    if action == "forward":
        return apply_motion(pose_state("forward"), phase, 0.8, robe_bias=1.8)
    if action == "back":
        return apply_motion(pose_state("back"), phase, 0.65, robe_bias=-1.0)
    if action == "parry":
        return apply_motion(parry_state(phase), phase, 0.35)
    if action == "array_ring_release":
        return release_state("ring", phase)
    if action == "array_fan_release":
        return release_state("fan", phase)
    if action == "array_pierce_release":
        return release_state("pierce", phase)
    raise ValueError(f"Unknown action: {action}")


def transition_state(source: str, target: str, index: int) -> State:
    phase = index / float(FRAME_COUNT - 1)
    source_state = action_state(source, min(index, 2))
    target_state = action_state(target, max(0, index - (FRAME_COUNT - 3)))
    q = smoothstep((phase - 0.15) / 0.70)
    return apply_motion(mix_state(source_state, target_state, q), phase, 0.35)


def draw_limb(draw: ImageDraw.ImageDraw, limb: tuple[Point, Point, Point], front: bool) -> None:
    shoulder, elbow, hand = limb
    sleeve_width = 14 if front else 12
    line(draw, (shoulder, elbow, hand), PALETTE["outline"], sleeve_width + 2)
    line(draw, (shoulder, elbow, hand), PALETTE["robe_mid"], sleeve_width)
    line(draw, (elbow, hand), PALETTE["robe_light"], max(4, sleeve_width - 6))
    ellipse(draw, hand, 4.0, 4.6, PALETTE["skin"], PALETTE["outline"], 0.8)
    ellipse(draw, lerp_point(elbow, hand, 0.80), 4.2, 3.2, PALETTE["gold"], PALETTE["gold_dark"], 0.8)


def draw_ribbons(draw: ImageDraw.ImageDraw, head: Point, wind: float) -> None:
    base = (head[0] - 8.0, head[1] - 4.0)
    ribbon_sets = (
        ((base), (base[0] - 20.0 - wind * 2.0, base[1] + 2.0), (base[0] - 47.0 - wind * 5.0, base[1] + 6.0)),
        ((base[0], base[1] + 6.0), (base[0] - 22.0 - wind * 2.2, base[1] + 16.0), (base[0] - 50.0 - wind * 5.0, base[1] + 20.0)),
        ((base[0] - 2.0, base[1] + 13.0), (base[0] - 25.0 - wind * 2.0, base[1] + 26.0), (base[0] - 55.0 - wind * 4.5, base[1] + 32.0)),
    )
    for points in ribbon_sets:
        line(draw, points, PALETTE["outline"], 4.0)
        line(draw, points, PALETTE["ribbon"], 2.0)
        line(draw, points, PALETTE["ribbon_core"], 0.8)


def draw_character(state: State) -> Image.Image:
    canvas = Image.new("RGBA", (FRAME_WIDTH * SCALE, FRAME_HEIGHT * SCALE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas, "RGBA")

    head: Point = state["head"]  # type: ignore[assignment]
    neck: Point = state["neck"]  # type: ignore[assignment]
    shoulder: Point = state["shoulder"]  # type: ignore[assignment]
    belt: Point = state["belt"]  # type: ignore[assignment]
    pelvis: Point = state["pelvis"]  # type: ignore[assignment]
    foot_l: Point = state["foot_l"]  # type: ignore[assignment]
    foot_r: Point = state["foot_r"]  # type: ignore[assignment]
    knee_l: Point = state["knee_l"]  # type: ignore[assignment]
    knee_r: Point = state["knee_r"]  # type: ignore[assignment]
    robe_back: Point = state["robe_back"]  # type: ignore[assignment]
    robe_front: Point = state["robe_front"]  # type: ignore[assignment]
    hair_wind = float(state["hair_wind"])

    left_shoulder = offset(shoulder, -15.5, 0.0)
    right_shoulder = offset(shoulder, 15.5, 1.0)
    left_waist = offset(belt, -20.0, 0.5)
    right_waist = offset(belt, 20.0, 0.5)

    draw_ribbons(draw, head, hair_wind)
    draw_limb(draw, state["back_arm"], front=False)  # type: ignore[arg-type]

    line(draw, (pelvis, knee_l, foot_l), PALETTE["outline"], 8.0)
    line(draw, (pelvis, knee_l, foot_l), PALETTE["pants"], 6.0)
    line(draw, (pelvis, knee_r, foot_r), PALETTE["outline"], 8.0)
    line(draw, (pelvis, knee_r, foot_r), PALETTE["pants"], 6.0)
    line(draw, (offset(foot_l, -6.0, 0.0), offset(foot_l, 9.0, 0.0)), PALETTE["gold"], 2.0)
    line(draw, (offset(foot_r, -6.0, 0.0), offset(foot_r, 9.0, 0.0)), PALETTE["gold"], 2.0)

    coat = (
        left_shoulder,
        right_shoulder,
        right_waist,
        robe_front,
        offset(pelvis, 0.0, 42.0),
        robe_back,
        left_waist,
    )
    polygon(draw, coat, PALETTE["robe_dark"], PALETTE["outline"], 1.3)
    polygon(
        draw,
        (offset(neck, -3.0, 3.0), offset(belt, -7.0, 3.0), offset(pelvis, -5.0, 50.0), offset(belt, 9.0, 3.0), offset(neck, 8.0, 4.0)),
        PALETTE["inner"],
        PALETTE["inner_shadow"],
        0.8,
    )
    line(draw, (offset(left_shoulder, -2.0, 7.0), offset(robe_back, 2.0, -4.0)), PALETTE["robe_light"], 2.0)
    line(draw, (offset(right_shoulder, 0.0, 6.0), offset(robe_front, -2.0, -4.0)), PALETTE["robe_light"], 2.0)
    line(draw, (left_waist, right_waist), PALETTE["outline"], 8.0)
    line(draw, (left_waist, right_waist), PALETTE["gold"], 5.0)
    ellipse(draw, belt, 5.5, 5.0, PALETTE["gold"], PALETTE["gold_dark"], 0.8)

    draw_limb(draw, state["front_arm"], front=True)  # type: ignore[arg-type]

    ellipse(draw, offset(head, -3.0, -1.5), 11.5, 10.0, PALETTE["hair"], PALETTE["outline"], 1.0)
    ellipse(draw, head, 9.2, 10.8, PALETTE["skin"], PALETTE["outline"], 1.0)
    polygon(
        draw,
        (offset(head, -9.0, -12.0), offset(head, 4.0, -13.0), offset(head, 10.0, -4.0), offset(head, -6.0, 0.0)),
        PALETTE["hair"],
        PALETTE["outline"],
        0.8,
    )
    ellipse(draw, offset(head, -3.5, -8.5), 4.0, 4.0, PALETTE["hair"], PALETTE["outline"], 0.6)
    line(draw, (offset(head, 6.0, -2.0), offset(head, 10.0, -1.0)), PALETTE["outline"], 1.0)
    line(draw, (offset(head, 4.0, 5.0), offset(head, 8.0, 6.0)), PALETTE["skin_shadow"], 1.0)

    image = canvas.resize((FRAME_WIDTH, FRAME_HEIGHT), Image.Resampling.LANCZOS)
    return anchor_bottom(image)


def anchor_bottom(image: Image.Image) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if not bbox:
        return image
    dy = ANCHOR_Y - (bbox[3] - 1)
    if dy == 0:
        return image
    result = Image.new("RGBA", image.size, (0, 0, 0, 0))
    result.alpha_composite(image, (0, dy))
    return result


def make_action_frames(action: str) -> list[Image.Image]:
    return [draw_character(action_state(action, index)) for index in range(FRAME_COUNT)]


def transition_parts(name: str) -> tuple[str, str]:
    source, target = name.split("_to_")
    return source, target


def normalize_transition_action(name: str) -> str:
    if name in {"idle", "forward", "back", "sword_control_idle", "array_ring_idle", "array_fan_idle", "array_pierce_idle"}:
        return name
    if name == "sword_control":
        return "sword_control_idle"
    if name in {"ring", "fan", "pierce"}:
        return f"array_{name}_idle"
    if name in {"array_ring", "array_fan", "array_pierce"}:
        return f"{name}_idle"
    return name


def make_transition_frames(name: str) -> list[Image.Image]:
    source_raw, target_raw = transition_parts(name)
    source = normalize_transition_action(source_raw)
    target = normalize_transition_action(target_raw)
    return [draw_character(transition_state(source, target, index)) for index in range(FRAME_COUNT)]


def save_strip(frames: list[Image.Image], path: Path) -> None:
    strip = Image.new("RGBA", (FRAME_WIDTH * FRAME_COUNT, FRAME_HEIGHT), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        strip.alpha_composite(frame, (index * FRAME_WIDTH, 0))
    path.parent.mkdir(parents=True, exist_ok=True)
    strip.save(path)
    print(f"Wrote {path}")


def save_atlas(row_frames: Iterable[list[Image.Image]], path: Path) -> None:
    rows = list(row_frames)
    atlas = Image.new("RGBA", (FRAME_WIDTH * FRAME_COUNT, FRAME_HEIGHT * len(rows)), (0, 0, 0, 0))
    for row_index, frames in enumerate(rows):
        for frame_index, frame in enumerate(frames):
            atlas.alpha_composite(frame, (frame_index * FRAME_WIDTH, row_index * FRAME_HEIGHT))
    path.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(path)
    print(f"Wrote {path} ({atlas.size[0]}x{atlas.size[1]})")


def save_master_reference(path: Path) -> None:
    pose_names = (
        "idle",
        "forward",
        "back",
        "sword_control_idle",
        "array_ring_idle",
        "array_fan_idle",
        "array_pierce_idle",
    )
    image = Image.new("RGBA", (FRAME_WIDTH * len(pose_names), FRAME_HEIGHT), (0, 0, 0, 0))
    for index, pose_name in enumerate(pose_names):
        image.alpha_composite(draw_character(pose_state(pose_name)), (index * FRAME_WIDTH, 0))
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    print(f"Wrote {path}")


def save_motion_bible(path: Path) -> None:
    states = (
        pose_state("idle"),
        pose_state("forward"),
        pose_state("back"),
        pose_state("parry_ready"),
        pose_state("parry_peak"),
        pose_state("sword_control_idle"),
        pose_state("array_ring_idle"),
        pose_state("array_fan_idle"),
        pose_state("array_pierce_idle"),
        mix_state(pose_state("array_ring_idle"), pose_state("array_fan_idle"), 0.5),
        mix_state(pose_state("array_fan_idle"), pose_state("array_pierce_idle"), 0.5),
        mix_state(pose_state("array_pierce_idle"), pose_state("array_ring_idle"), 0.5),
        pose_state("ring_release_peak"),
        pose_state("fan_release_peak"),
        pose_state("pierce_release_peak"),
        pose_state("idle"),
    )
    image = Image.new("RGBA", (FRAME_WIDTH * 4, FRAME_HEIGHT * 4), (0, 0, 0, 0))
    for index, state in enumerate(states):
        x = (index % 4) * FRAME_WIDTH
        y = (index // 4) * FRAME_HEIGHT
        image.alpha_composite(draw_character(state), (x, y))
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    print(f"Wrote {path}")


def build_assets(args: argparse.Namespace) -> None:
    main_frames = {name: make_action_frames(name) for name in MAIN_ROWS}
    transition_frames = {name: make_transition_frames(name) for name in TRANSITION_ROWS}

    save_master_reference(args.out_source_dir / "body_v13_master_reference.png")
    save_motion_bible(args.out_source_dir / "body_v13_motion_bible.png")

    for name in MAIN_ROWS:
        save_strip(main_frames[name], args.out_source_dir / f"body_v13_main_{name}_16.png")
    for name in TRANSITION_ROWS:
        save_strip(transition_frames[name], args.out_transition_dir / f"body_v13_transition_{name}_16.png")

    save_atlas((main_frames[name] for name in MAIN_ROWS), args.out_main)
    save_atlas((transition_frames[name] for name in TRANSITION_ROWS), args.out_transitions)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-source-dir", type=Path, default=Path("resources/flight/rider/body_v13_sources"))
    parser.add_argument("--out-transition-dir", type=Path, default=Path("resources/flight/rider/body_v13_transitions"))
    parser.add_argument("--out-main", type=Path, default=Path("resources/flight/rider/flight_rider_body_v13_sheet.png"))
    parser.add_argument("--out-transitions", type=Path, default=Path("resources/flight/rider/flight_rider_body_v13_transitions.png"))
    args = parser.parse_args()
    build_assets(args)


if __name__ == "__main__":
    main()
