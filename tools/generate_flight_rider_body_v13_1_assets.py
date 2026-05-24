#!/usr/bin/env python3
"""Build SwordCultivator flight rider body V13.1 strips and atlases.

V13.1 is kept separate from V13 so parallel art passes can be compared without
overwriting each other. This generator redraws the rider from a single locked
proportion model inspired by the V13.1 master reference: dark teal-black robe,
antique-gold belt/cuffs, pale cyan-white scarf, black topknot, and a consistent
side-view adult sword cultivator silhouette.
"""

from __future__ import annotations

import argparse
import math
from pathlib import Path
from typing import Any, Iterable

from PIL import Image, ImageDraw


FRAME_WIDTH = 256
FRAME_HEIGHT = 256
FRAME_COUNT = 16
ROW_WIDTH = FRAME_WIDTH * FRAME_COUNT
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

COLORS = {
    "outline": (4, 9, 11, 255),
    "outline_soft": (12, 24, 29, 255),
    "robe_dark": (13, 38, 42, 255),
    "robe": (18, 58, 63, 255),
    "robe_mid": (26, 77, 82, 255),
    "robe_light": (48, 116, 119, 255),
    "inner": (221, 246, 243, 255),
    "inner_shadow": (143, 197, 196, 255),
    "scarf": (203, 244, 242, 255),
    "scarf_shadow": (103, 177, 183, 255),
    "scarf_edge": (30, 86, 91, 255),
    "gold_dark": (121, 76, 29, 255),
    "gold": (190, 137, 55, 255),
    "gold_light": (236, 188, 94, 255),
    "skin": (239, 172, 146, 255),
    "skin_shadow": (157, 88, 75, 255),
    "hair": (8, 15, 21, 255),
    "hair_light": (34, 45, 57, 255),
    "boot": (5, 19, 22, 255),
    "boot_light": (102, 175, 174, 255),
}

Point = tuple[float, float]
Pose = dict[str, Any]


def pt(x: float, y: float) -> Point:
    return (float(x), float(y))


def ease(t: float) -> float:
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)


def sin01(frame: int, offset: float = 0.0) -> float:
    return math.sin((frame / FRAME_COUNT + offset) * math.tau)


def clone_pose(pose: Pose) -> Pose:
    result: Pose = {}
    for key, value in pose.items():
        if isinstance(value, dict):
            result[key] = clone_pose(value)
        elif isinstance(value, list):
            result[key] = [tuple(item) if isinstance(item, tuple) else item for item in value]
        elif isinstance(value, tuple):
            result[key] = tuple(value)
        else:
            result[key] = value
    return result


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def lerp_value(a: Any, b: Any, t: float) -> Any:
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        return lerp(float(a), float(b), t)
    if isinstance(a, tuple) and isinstance(b, tuple):
        return tuple(lerp_value(x, y, t) for x, y in zip(a, b))
    if isinstance(a, list) and isinstance(b, list):
        return [lerp_value(x, y, t) for x, y in zip(a, b)]
    if isinstance(a, dict) and isinstance(b, dict):
        return {key: lerp_value(a[key], b[key], t) for key in a.keys()}
    return b if t >= 0.5 else a


def lerp_pose(a: Pose, b: Pose, t: float) -> Pose:
    return {key: lerp_value(a[key], b[key], t) for key in a.keys()}


def offset_point(p: Point, dx: float = 0.0, dy: float = 0.0) -> Point:
    return (p[0] + dx, p[1] + dy)


def offset_arm(points: list[Point], dx: float = 0.0, dy: float = 0.0) -> list[Point]:
    return [offset_point(p, dx, dy) for p in points]


def base_poses() -> dict[str, Pose]:
    idle: Pose = {
        "head": pt(126, 74),
        "neck": pt(126, 91),
        "shoulder_l": pt(111, 94),
        "shoulder_r": pt(139, 94),
        "waist_l": pt(111, 132),
        "waist_r": pt(141, 132),
        "hip": pt(126, 158),
        "front_knee": pt(141, 181),
        "back_knee": pt(111, 181),
        "front_foot": pt(145, ANCHOR_Y),
        "back_foot": pt(106, ANCHOR_Y),
        "back_arm": [pt(112, 97), pt(107, 124), pt(111, 151)],
        "front_arm": [pt(139, 98), pt(146, 124), pt(149, 151)],
        "robe_left": pt(97, 206),
        "robe_right": pt(151, 207),
        "front_hem": pt(139, 214),
        "back_hem": pt(103, 214),
        "scarf_tail": [pt(113, 98), pt(82, 121), pt(56, 154), pt(42, 184)],
        "scarf_tip": pt(39, 197),
    }
    forward: Pose = {
        "head": pt(150, 89),
        "neck": pt(145, 105),
        "shoulder_l": pt(126, 110),
        "shoulder_r": pt(153, 108),
        "waist_l": pt(112, 142),
        "waist_r": pt(143, 139),
        "hip": pt(128, 163),
        "front_knee": pt(153, 181),
        "back_knee": pt(104, 181),
        "front_foot": pt(176, ANCHOR_Y),
        "back_foot": pt(89, ANCHOR_Y),
        "back_arm": [pt(127, 112), pt(114, 134), pt(102, 151)],
        "front_arm": [pt(152, 111), pt(134, 135), pt(115, 154)],
        "robe_left": pt(82, 203),
        "robe_right": pt(154, 207),
        "front_hem": pt(150, 215),
        "back_hem": pt(91, 215),
        "scarf_tail": [pt(133, 110), pt(96, 94), pt(68, 98), pt(48, 116)],
        "scarf_tip": pt(46, 124),
    }
    back: Pose = {
        "head": pt(108, 84),
        "neck": pt(113, 102),
        "shoulder_l": pt(101, 108),
        "shoulder_r": pt(129, 106),
        "waist_l": pt(112, 144),
        "waist_r": pt(142, 142),
        "hip": pt(128, 164),
        "front_knee": pt(147, 181),
        "back_knee": pt(104, 184),
        "front_foot": pt(166, ANCHOR_Y),
        "back_foot": pt(93, ANCHOR_Y),
        "back_arm": [pt(103, 110), pt(102, 136), pt(109, 158)],
        "front_arm": [pt(129, 110), pt(140, 135), pt(144, 158)],
        "robe_left": pt(91, 206),
        "robe_right": pt(153, 205),
        "front_hem": pt(143, 215),
        "back_hem": pt(97, 215),
        "scarf_tail": [pt(120, 108), pt(151, 119), pt(173, 136), pt(190, 153)],
        "scarf_tip": pt(198, 160),
    }
    parry_ready = clone_pose(idle)
    parry_ready.update(
        {
            "head": pt(126, 79),
            "neck": pt(126, 96),
            "shoulder_l": pt(108, 104),
            "shoulder_r": pt(139, 103),
            "waist_l": pt(107, 143),
            "waist_r": pt(142, 143),
            "front_knee": pt(151, 183),
            "back_knee": pt(101, 184),
            "front_foot": pt(166, ANCHOR_Y),
            "back_foot": pt(91, ANCHOR_Y),
            "back_arm": [pt(109, 106), pt(105, 130), pt(116, 148)],
            "front_arm": [pt(139, 106), pt(151, 127), pt(162, 145)],
            "robe_left": pt(86, 207),
            "robe_right": pt(156, 208),
            "back_hem": pt(94, 215),
            "front_hem": pt(151, 215),
            "scarf_tail": [pt(114, 106), pt(80, 109), pt(57, 130), pt(43, 154)],
            "scarf_tip": pt(43, 165),
        }
    )
    parry_peak = lerp_pose(parry_ready, forward, 0.28)
    parry_peak.update(
        {
            "head": pt(136, 78),
            "neck": pt(135, 96),
            "shoulder_l": pt(111, 104),
            "shoulder_r": pt(146, 101),
            "back_arm": [pt(113, 106), pt(122, 124), pt(138, 133)],
            "front_arm": [pt(146, 103), pt(166, 110), pt(184, 118)],
            "robe_left": pt(84, 206),
            "robe_right": pt(165, 208),
            "scarf_tail": [pt(122, 104), pt(83, 98), pt(55, 108), pt(38, 130)],
            "scarf_tip": pt(38, 139),
        }
    )
    sword_control = clone_pose(idle)
    sword_control.update(
        {
            "head": pt(128, 74),
            "back_arm": [pt(113, 98), pt(124, 119), pt(137, 125)],
            "front_arm": [pt(140, 98), pt(151, 117), pt(160, 125)],
            "scarf_tail": [pt(113, 99), pt(82, 109), pt(59, 134), pt(47, 164)],
            "scarf_tip": pt(48, 177),
        }
    )
    ring = lerp_pose(parry_ready, idle, 0.35)
    ring.update(
        {
            "head": pt(126, 78),
            "back_arm": [pt(111, 101), pt(121, 119), pt(135, 126)],
            "front_arm": [pt(139, 101), pt(139, 119), pt(130, 127)],
            "scarf_tail": [pt(113, 103), pt(83, 111), pt(59, 139), pt(48, 169)],
            "scarf_tip": pt(48, 181),
        }
    )
    fan = clone_pose(parry_ready)
    fan.update(
        {
            "head": pt(128, 77),
            "back_arm": [pt(110, 103), pt(96, 112), pt(82, 123)],
            "front_arm": [pt(142, 103), pt(160, 110), pt(178, 121)],
            "scarf_tail": [pt(114, 104), pt(80, 104), pt(54, 124), pt(38, 151)],
            "scarf_tip": pt(39, 162),
        }
    )
    pierce = clone_pose(parry_ready)
    pierce.update(
        {
            "head": pt(129, 77),
            "back_arm": [pt(111, 103), pt(121, 121), pt(133, 136)],
            "front_arm": [pt(142, 102), pt(160, 104), pt(184, 104)],
            "scarf_tail": [pt(115, 104), pt(82, 101), pt(56, 116), pt(40, 143)],
            "scarf_tip": pt(40, 154),
        }
    )
    ring_push = clone_pose(ring)
    ring_push.update(
        {
            "back_arm": [pt(111, 101), pt(97, 112), pt(84, 126)],
            "front_arm": [pt(140, 101), pt(159, 113), pt(176, 128)],
            "shoulder_l": pt(106, 103),
            "shoulder_r": pt(145, 102),
        }
    )
    fan_push = clone_pose(fan)
    fan_push.update(
        {
            "back_arm": [pt(110, 103), pt(91, 106), pt(72, 112)],
            "front_arm": [pt(143, 103), pt(169, 105), pt(194, 112)],
            "shoulder_l": pt(105, 103),
            "shoulder_r": pt(148, 102),
        }
    )
    pierce_push = clone_pose(pierce)
    pierce_push.update(
        {
            "head": pt(136, 78),
            "neck": pt(134, 96),
            "shoulder_l": pt(113, 104),
            "shoulder_r": pt(149, 101),
            "waist_l": pt(108, 143),
            "waist_r": pt(145, 141),
            "front_arm": [pt(149, 102), pt(174, 99), pt(203, 96)],
            "back_arm": [pt(114, 104), pt(124, 120), pt(138, 132)],
            "scarf_tail": [pt(121, 104), pt(85, 96), pt(56, 104), pt(38, 128)],
            "scarf_tip": pt(38, 139),
        }
    )
    return {
        "idle": idle,
        "forward": forward,
        "back": back,
        "parry_ready": parry_ready,
        "parry_peak": parry_peak,
        "sword_control_idle": sword_control,
        "array_ring_idle": ring,
        "array_fan_idle": fan,
        "array_pierce_idle": pierce,
        "array_ring_release_peak": ring_push,
        "array_fan_release_peak": fan_push,
        "array_pierce_release_peak": pierce_push,
    }


POSES = base_poses()


def sequence_pose(keyframes: list[tuple[float, str]], progress: float) -> Pose:
    progress = max(0.0, min(1.0, progress))
    for index in range(len(keyframes) - 1):
        t0, pose0 = keyframes[index]
        t1, pose1 = keyframes[index + 1]
        if progress <= t1 or index == len(keyframes) - 2:
            local = 0.0 if t1 == t0 else (progress - t0) / (t1 - t0)
            return lerp_pose(POSES[pose0], POSES[pose1], ease(local))
    return clone_pose(POSES[keyframes[-1][1]])


def apply_breath(pose: Pose, frame: int, amplitude: float = 1.0, scarf_gain: float = 1.0) -> Pose:
    p = clone_pose(pose)
    wave = sin01(frame)
    sleeve = sin01(frame, 0.18)
    scarf = sin01(frame, 0.33)
    arm_nudge = sleeve * amplitude
    p["back_arm"] = [p["back_arm"][0], offset_point(p["back_arm"][1], 0, -arm_nudge * 0.45), offset_point(p["back_arm"][2], 0, -arm_nudge)]
    p["front_arm"] = [p["front_arm"][0], offset_point(p["front_arm"][1], 0, arm_nudge * 0.35), offset_point(p["front_arm"][2], 0, arm_nudge * 0.85)]
    p["robe_left"] = offset_point(p["robe_left"], wave * 0.8 * amplitude, 0)
    p["robe_right"] = offset_point(p["robe_right"], -wave * 0.5 * amplitude, 0)
    p["front_hem"] = offset_point(p["front_hem"], 0, min(0.0, wave) * amplitude)
    p["back_hem"] = offset_point(p["back_hem"], 0, max(0.0, wave) * amplitude)
    p["scarf_tail"] = [
        offset_point(point, scarf * (idx + 1) * 0.7 * scarf_gain, math.cos((frame / FRAME_COUNT + idx * 0.08) * math.tau) * 1.2 * scarf_gain)
        for idx, point in enumerate(p["scarf_tail"])
    ]
    p["scarf_tip"] = offset_point(p["scarf_tip"], scarf * 2.0 * scarf_gain, math.cos(frame / FRAME_COUNT * math.tau) * 1.4 * scarf_gain)
    return p


def pose_for_main(action: str, frame: int) -> Pose:
    progress = frame / float(FRAME_COUNT - 1)
    if action == "idle":
        return apply_breath(POSES["idle"], frame, amplitude=0.65, scarf_gain=0.75)
    if action == "forward":
        bob = math.sin(progress * math.tau)
        pose = clone_pose(POSES["forward"])
        pose["head"] = offset_point(pose["head"], bob * 1.5, 0.0)
        pose["scarf_tail"] = [offset_point(point, -idx * 1.0, bob * (idx + 1) * 0.45) for idx, point in enumerate(pose["scarf_tail"])]
        pose["scarf_tip"] = offset_point(pose["scarf_tip"], -2.0, bob * 1.5)
        return apply_breath(pose, frame, amplitude=0.45, scarf_gain=1.35)
    if action == "back":
        bob = math.sin(progress * math.tau)
        pose = clone_pose(POSES["back"])
        pose["head"] = offset_point(pose["head"], -bob * 1.1, -abs(bob) * 0.5)
        pose["scarf_tail"] = [offset_point(point, idx * 0.8, bob * (idx + 1) * 0.35) for idx, point in enumerate(pose["scarf_tail"])]
        return apply_breath(pose, frame, amplitude=0.4, scarf_gain=1.1)
    if action == "parry":
        return apply_breath(
            sequence_pose(
                [
                    (0.0, "parry_ready"),
                    (0.28, "parry_ready"),
                    (0.55, "parry_peak"),
                    (0.74, "parry_peak"),
                    (1.0, "parry_ready"),
                ],
                progress,
            ),
            frame,
            amplitude=0.25,
            scarf_gain=1.25,
        )
    if action in ("sword_control_idle", "array_ring_idle", "array_fan_idle", "array_pierce_idle"):
        return apply_breath(POSES[action], frame, amplitude=0.65, scarf_gain=0.9)
    if action == "array_ring_release":
        return apply_breath(
            sequence_pose([(0.0, "array_ring_idle"), (0.33, "array_ring_idle"), (0.62, "array_ring_release_peak"), (1.0, "array_ring_idle")], progress),
            frame,
            amplitude=0.25,
            scarf_gain=1.1,
        )
    if action == "array_fan_release":
        return apply_breath(
            sequence_pose([(0.0, "array_fan_idle"), (0.34, "array_fan_idle"), (0.62, "array_fan_release_peak"), (1.0, "array_fan_idle")], progress),
            frame,
            amplitude=0.25,
            scarf_gain=1.25,
        )
    if action == "array_pierce_release":
        return apply_breath(
            sequence_pose([(0.0, "array_pierce_idle"), (0.34, "array_pierce_idle"), (0.62, "array_pierce_release_peak"), (1.0, "array_pierce_idle")], progress),
            frame,
            amplitude=0.25,
            scarf_gain=1.2,
        )
    raise KeyError(action)


def state_to_pose_key(name: str) -> str:
    if name == "idle":
        return "idle"
    if name == "sword_control":
        return "sword_control_idle"
    if name in ("ring", "fan", "pierce"):
        return f"array_{name}_idle"
    if name.startswith("array_"):
        return f"{name}_idle"
    return name


def pose_for_transition(name: str, frame: int) -> Pose:
    source, target = name.split("_to_")
    source_key = state_to_pose_key(source)
    target_key = state_to_pose_key(target)
    progress = ease(frame / float(FRAME_COUNT - 1))
    pose = lerp_pose(POSES[source_key], POSES[target_key], progress)
    return apply_breath(pose, frame, amplitude=0.25, scarf_gain=1.0)


def poly_int(points: Iterable[Point]) -> list[tuple[int, int]]:
    return [(round(x), round(y)) for x, y in points]


def draw_poly(draw: ImageDraw.ImageDraw, points: Iterable[Point], fill: tuple[int, int, int, int], outline: bool = True) -> None:
    pts = poly_int(points)
    if outline:
        draw.polygon(pts, fill=COLORS["outline"])
    draw.polygon(pts, fill=fill)


def draw_layered_line(draw: ImageDraw.ImageDraw, points: list[Point], width: int, fill: tuple[int, int, int, int], outline_width: int = 3) -> None:
    pts = poly_int(points)
    draw.line(pts, fill=COLORS["outline"], width=width + outline_width, joint="curve")
    draw.line(pts, fill=fill, width=width, joint="curve")


def draw_scarf(draw: ImageDraw.ImageDraw, pose: Pose) -> None:
    tail = [pose["neck"], *pose["scarf_tail"], pose["scarf_tip"]]
    draw_layered_line(draw, tail, 8, COLORS["scarf_edge"], outline_width=4)
    draw_layered_line(draw, tail, 5, COLORS["scarf_shadow"], outline_width=1)
    draw.line(poly_int(tail), fill=COLORS["scarf"], width=2, joint="curve")
    neck = pose["neck"]
    loop = [
        offset_point(neck, -19, -5),
        offset_point(neck, 5, -8),
        offset_point(neck, 21, 4),
        offset_point(neck, 15, 15),
        offset_point(neck, -11, 14),
        offset_point(neck, -22, 4),
    ]
    draw_poly(draw, loop, COLORS["scarf_shadow"])
    inner_loop = [
        offset_point(neck, -16, -4),
        offset_point(neck, 4, -6),
        offset_point(neck, 17, 3),
        offset_point(neck, 12, 11),
        offset_point(neck, -10, 11),
        offset_point(neck, -18, 3),
    ]
    draw_poly(draw, inner_loop, COLORS["scarf"], outline=False)
    draw.line(poly_int([offset_point(neck, -14, 7), offset_point(neck, 11, 9)]), fill=COLORS["inner"], width=2)


def draw_boot(draw: ImageDraw.ImageDraw, foot: Point, facing: int) -> None:
    x, y = foot
    toe = 16 * facing
    pts = [(x - 8, y - 18), (x + 7, y - 18), (x + 8, y - 7), (x + toe, y - 2), (x + toe + 8 * facing, y), (x - 9, y)]
    draw.polygon(poly_int(pts), fill=COLORS["outline"])
    inner = [(x - 6, y - 16), (x + 5, y - 16), (x + 5, y - 6), (x + toe, y - 4), (x + toe + 4 * facing, y - 2), (x - 7, y - 2)]
    draw.polygon(poly_int(inner), fill=COLORS["boot"])
    draw.line(poly_int([(x + 2, y - 4), (x + toe + 2 * facing, y - 4)]), fill=COLORS["boot_light"], width=2)


def draw_leg(draw: ImageDraw.ImageDraw, hip: Point, knee: Point, foot: Point, back: bool) -> None:
    fill = COLORS["robe_dark"] if back else COLORS["robe"]
    draw_layered_line(draw, [hip, knee, offset_point(foot, -2 if foot[0] > hip[0] else 2, -13)], 13, fill, outline_width=4)
    cuff_y = foot[1] - 22
    draw.rectangle([round(foot[0] - 8), round(cuff_y - 3), round(foot[0] + 8), round(cuff_y + 2)], fill=COLORS["gold_dark"])
    draw.line([(round(foot[0] - 6), round(cuff_y - 1)), (round(foot[0] + 6), round(cuff_y - 1))], fill=COLORS["gold_light"], width=1)


def draw_arm(draw: ImageDraw.ImageDraw, arm: list[Point], front: bool) -> None:
    fill = COLORS["robe_mid"] if front else COLORS["robe_dark"]
    draw_layered_line(draw, arm[:3], 15, fill, outline_width=4)
    hand = arm[-1]
    elbow = arm[-2]
    angle = math.atan2(hand[1] - elbow[1], hand[0] - elbow[0])
    cuff_center = offset_point(hand, -math.cos(angle) * 6, -math.sin(angle) * 6)
    draw.ellipse(
        [
            round(cuff_center[0] - 8),
            round(cuff_center[1] - 7),
            round(cuff_center[0] + 8),
            round(cuff_center[1] + 7),
        ],
        fill=COLORS["outline"],
    )
    draw.ellipse(
        [
            round(cuff_center[0] - 6),
            round(cuff_center[1] - 5),
            round(cuff_center[0] + 6),
            round(cuff_center[1] + 5),
        ],
        fill=COLORS["gold"],
    )
    draw.ellipse(
        [round(hand[0] - 5), round(hand[1] - 5), round(hand[0] + 5), round(hand[1] + 5)],
        fill=COLORS["outline"],
    )
    draw.ellipse(
        [round(hand[0] - 4), round(hand[1] - 4), round(hand[0] + 4), round(hand[1] + 4)],
        fill=COLORS["skin"],
    )


def draw_head(draw: ImageDraw.ImageDraw, pose: Pose) -> None:
    hx, hy = pose["head"]
    draw.ellipse([round(hx - 15), round(hy - 18), round(hx + 12), round(hy + 14)], fill=COLORS["outline"])
    draw.ellipse([round(hx - 12), round(hy - 15), round(hx + 11), round(hy + 13)], fill=COLORS["skin"])
    hair_back = [(hx - 15, hy - 17), (hx + 5, hy - 21), (hx + 14, hy - 6), (hx + 8, hy + 1), (hx - 3, hy - 8), (hx - 10, hy + 7), (hx - 17, hy + 5)]
    draw.polygon(poly_int(hair_back), fill=COLORS["hair"])
    draw.ellipse([round(hx - 9), round(hy - 23), round(hx + 9), round(hy - 13)], fill=COLORS["outline"])
    draw.ellipse([round(hx - 7), round(hy - 22), round(hx + 7), round(hy - 15)], fill=COLORS["hair"])
    draw.rectangle([round(hx - 5), round(hy - 24), round(hx + 5), round(hy - 21)], fill=COLORS["gold"])
    topknot = [(hx - 1, hy - 21), (hx - 10, hy - 23), (hx - 2, hy - 24), (hx + 8, hy - 23), (hx + 6, hy - 21)]
    draw.polygon(poly_int(topknot), fill=COLORS["outline"])
    draw.polygon(poly_int([(x, y + 2) for x, y in topknot]), fill=COLORS["hair_light"])
    draw.line(poly_int([(hx + 2, hy - 4), (hx + 10, hy - 5)]), fill=COLORS["outline"], width=2)
    draw.rectangle([round(hx + 8), round(hy - 4), round(hx + 10), round(hy - 2)], fill=COLORS["skin_shadow"])
    draw.line(poly_int([(hx + 3, hy + 8), (hx + 10, hy + 8)]), fill=COLORS["skin_shadow"], width=1)


def draw_body(draw: ImageDraw.ImageDraw, pose: Pose) -> None:
    hip = pose["hip"]
    draw_leg(draw, hip, pose["back_knee"], pose["back_foot"], back=True)
    draw_leg(draw, hip, pose["front_knee"], pose["front_foot"], back=False)
    draw_boot(draw, pose["back_foot"], -1)
    draw_boot(draw, pose["front_foot"], 1)

    draw_arm(draw, pose["back_arm"], front=False)

    shoulder_l = pose["shoulder_l"]
    shoulder_r = pose["shoulder_r"]
    waist_l = pose["waist_l"]
    waist_r = pose["waist_r"]
    robe_left = pose["robe_left"]
    robe_right = pose["robe_right"]
    back_hem = pose["back_hem"]
    front_hem = pose["front_hem"]

    skirt = [waist_l, waist_r, robe_right, front_hem, hip, back_hem, robe_left]
    draw.polygon(poly_int(skirt), fill=COLORS["outline"])
    draw.polygon(poly_int([(x + 1, y - 1) for x, y in skirt]), fill=COLORS["robe_dark"])
    draw.polygon(poly_int([waist_l, waist_r, offset_point(robe_right, -7, -3), front_hem, hip, offset_point(robe_left, 8, -3)]), fill=COLORS["robe"])
    inner_panel = [offset_point(shoulder_l, 13, -2), offset_point(shoulder_r, -8, 0), offset_point(waist_r, -9, 2), offset_point(front_hem, -15, -6), offset_point(hip, 2, -5), offset_point(waist_l, 13, 2)]
    draw.polygon(poly_int(inner_panel), fill=COLORS["outline"])
    draw.polygon(poly_int([(x, y + 1) for x, y in inner_panel]), fill=COLORS["inner_shadow"])
    draw.polygon(poly_int([offset_point(shoulder_l, 15, 0), offset_point(shoulder_r, -10, 1), offset_point(waist_r, -13, 6), offset_point(front_hem, -17, -10), offset_point(hip, 0, -10), offset_point(waist_l, 15, 6)]), fill=COLORS["inner"])

    torso = [shoulder_l, shoulder_r, waist_r, waist_l]
    draw.polygon(poly_int(torso), fill=COLORS["outline"])
    draw.polygon(poly_int([offset_point(shoulder_l, 2, 2), offset_point(shoulder_r, -1, 2), offset_point(waist_r, -2, -1), offset_point(waist_l, 2, -1)]), fill=COLORS["robe"])
    draw.line(poly_int([offset_point(shoulder_l, 5, 9), offset_point(waist_l, 9, -2)]), fill=COLORS["robe_light"], width=2)
    draw.line(poly_int([offset_point(shoulder_r, -4, 8), offset_point(waist_r, -6, -2)]), fill=COLORS["outline_soft"], width=2)

    belt = [offset_point(waist_l, -3, -1), offset_point(waist_r, 3, -1), offset_point(waist_r, 5, 11), offset_point(waist_l, -5, 11)]
    draw.polygon(poly_int(belt), fill=COLORS["outline"])
    draw.polygon(poly_int([offset_point(waist_l, -1, 1), offset_point(waist_r, 1, 1), offset_point(waist_r, 2, 8), offset_point(waist_l, -2, 8)]), fill=COLORS["gold"])
    draw.line(poly_int([offset_point(waist_l, 4, 4), offset_point(waist_r, -3, 4)]), fill=COLORS["gold_dark"], width=2)
    draw.line(poly_int([offset_point(waist_l, 8, 2), offset_point(waist_r, -8, 2)]), fill=COLORS["gold_light"], width=1)

    draw_arm(draw, pose["front_arm"], front=True)


def draw_character(pose: Pose) -> Image.Image:
    image = Image.new("RGBA", (FRAME_WIDTH, FRAME_HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")
    draw_scarf(draw, pose)
    draw_body(draw, pose)
    draw_head(draw, pose)
    return image


def strip_from_frames(frames: Iterable[Image.Image]) -> Image.Image:
    sheet = Image.new("RGBA", (ROW_WIDTH, FRAME_HEIGHT), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, (index * FRAME_WIDTH, 0))
    return sheet


def save_strip(frames: list[Image.Image], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    strip_from_frames(frames).save(path)
    print(f"Wrote {path}")


def save_atlas(rows: Iterable[list[Image.Image]], path: Path) -> None:
    row_list = list(rows)
    atlas = Image.new("RGBA", (ROW_WIDTH, FRAME_HEIGHT * len(row_list)), (0, 0, 0, 0))
    for row_index, frames in enumerate(row_list):
        for frame_index, frame in enumerate(frames):
            atlas.alpha_composite(frame, (frame_index * FRAME_WIDTH, row_index * FRAME_HEIGHT))
    path.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(path)
    print(f"Wrote {path} ({atlas.size[0]}x{atlas.size[1]})")


def build_master_reference(out_source_dir: Path) -> None:
    names = (
        "idle",
        "forward",
        "back",
        "sword_control_idle",
        "array_ring_idle",
        "array_fan_idle",
        "array_pierce_idle",
    )
    frames = [draw_character(apply_breath(POSES[name], 0, amplitude=0.0)) for name in names]
    strip = Image.new("RGBA", (FRAME_WIDTH * len(frames), FRAME_HEIGHT), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        strip.alpha_composite(frame, (index * FRAME_WIDTH, 0))
    path = out_source_dir / "body_v13_1_master_reference.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    strip.save(path)
    print(f"Wrote {path}")


def build_motion_bible(out_source_dir: Path) -> None:
    pose_names = (
        "idle",
        "forward",
        "back",
        "parry_ready",
        "parry_peak",
        "sword_control_idle",
        "array_ring_idle",
        "array_fan_idle",
        "array_pierce_idle",
        "array_fan_idle",
        "array_pierce_idle",
        "array_ring_idle",
        "array_ring_release_peak",
        "array_fan_release_peak",
        "array_pierce_release_peak",
        "idle",
    )
    grid = Image.new("RGBA", (FRAME_WIDTH * 4, FRAME_HEIGHT * 4), (0, 0, 0, 0))
    for index, name in enumerate(pose_names):
        frame = draw_character(apply_breath(POSES[name], index, amplitude=0.0))
        grid.alpha_composite(frame, ((index % 4) * FRAME_WIDTH, (index // 4) * FRAME_HEIGHT))
    path = out_source_dir / "body_v13_1_motion_bible.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    grid.save(path)
    print(f"Wrote {path}")


def build_assets(out_source_dir: Path, out_transition_dir: Path, out_main: Path, out_transitions: Path) -> None:
    build_master_reference(out_source_dir)
    build_motion_bible(out_source_dir)

    main_rows: dict[str, list[Image.Image]] = {}
    for name in MAIN_ROWS:
        frames = [draw_character(pose_for_main(name, frame)) for frame in range(FRAME_COUNT)]
        main_rows[name] = frames
        save_strip(frames, out_source_dir / f"body_v13_1_main_{name}_16.png")

    transition_rows: dict[str, list[Image.Image]] = {}
    for name in TRANSITION_ROWS:
        frames = [draw_character(pose_for_transition(name, frame)) for frame in range(FRAME_COUNT)]
        transition_rows[name] = frames
        save_strip(frames, out_transition_dir / f"body_v13_1_transition_{name}_16.png")

    save_atlas((main_rows[name] for name in MAIN_ROWS), out_main)
    save_atlas((transition_rows[name] for name in TRANSITION_ROWS), out_transitions)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-source-dir", type=Path, default=Path("resources/flight/rider/body_v13_1_sources"))
    parser.add_argument("--out-transition-dir", type=Path, default=Path("resources/flight/rider/body_v13_1_transitions"))
    parser.add_argument("--out-main", type=Path, default=Path("resources/flight/rider/flight_rider_body_v13_1_sheet.png"))
    parser.add_argument("--out-transitions", type=Path, default=Path("resources/flight/rider/flight_rider_body_v13_1_transitions.png"))
    args = parser.parse_args()
    build_assets(args.out_source_dir, args.out_transition_dir, args.out_main, args.out_transitions)


if __name__ == "__main__":
    main()
