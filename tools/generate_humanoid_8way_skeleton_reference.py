from __future__ import annotations

import json
import math
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "docs/mockups/humanoid_8way_skeleton_reference"
SVG_OUT = OUT_DIR / "humanoid_8way_skeleton_reference.svg"
PNG_OUT = OUT_DIR / "humanoid_8way_skeleton_reference.png"
JSON_OUT = OUT_DIR / "humanoid_8way_skeleton_rig.json"

MARGIN = 28
HEADER = 84
CELL_W = 260
CELL_H = 360
COLS = 4
ROWS = 2
WIDTH = MARGIN * 2 + CELL_W * COLS
HEIGHT = HEADER + CELL_H * ROWS + MARGIN
ROOT_IN_CELL = (CELL_W * 0.5, 224)

PNG_SCALE = 2

COLORS = {
    "bg": "#101318",
    "panel": "#171d25",
    "panel_alt": "#141920",
    "grid": "#303844",
    "text": "#edf3f8",
    "muted": "#9aa8b6",
    "joint": "#f4f8fb",
    "head": "#e6c08c",
    "torso": "#4e8fb0",
    "upper_arm": "#d38342",
    "forearm": "#efb64c",
    "thigh": "#5aa76d",
    "calf": "#57b8c8",
    "center": "#d9b96f",
    "outline": "#07090c",
}


@dataclass(frozen=True)
class Direction:
    key: str
    label: str
    facing: str
    col: int
    row: int
    sign: int = 1


DIRECTIONS = [
    Direction("down", "下 / 正面", "front", 0, 0),
    Direction("down_right", "右下 / 右前", "front_diag", 1, 0, 1),
    Direction("right", "右 / 侧面", "side", 2, 0, 1),
    Direction("up_right", "右上 / 右后", "back_diag", 3, 0, 1),
    Direction("up", "上 / 背面", "back", 0, 1),
    Direction("up_left", "左上 / 左后", "back_diag", 1, 1, -1),
    Direction("left", "左 / 侧面", "side", 2, 1, -1),
    Direction("down_left", "左下 / 左前", "front_diag", 3, 1, -1),
]


def p(x: float, y: float) -> list[float]:
    return [round(x, 2), round(y, 2)]


def mirror(points: dict[str, list[float]], sign: int) -> dict[str, list[float]]:
    if sign == 1:
        return points
    return {name: p(-value[0], value[1]) for name, value in points.items()}


def make_joints(direction: Direction) -> dict[str, list[float]]:
    if direction.facing == "front":
        return {
            "neck": p(0, -96),
            "head": p(0, -124),
            "shoulder_far": p(-36, -78),
            "elbow_far": p(-55, -28),
            "wrist_far": p(-44, 24),
            "shoulder_near": p(36, -78),
            "elbow_near": p(55, -28),
            "wrist_near": p(44, 24),
            "hip_far": p(-18, 6),
            "knee_far": p(-27, 62),
            "ankle_far": p(-28, 124),
            "hip_near": p(18, 6),
            "knee_near": p(27, 62),
            "ankle_near": p(28, 124),
        }

    if direction.facing == "back":
        return {
            "neck": p(0, -96),
            "head": p(0, -124),
            "shoulder_far": p(-36, -78),
            "elbow_far": p(-52, -25),
            "wrist_far": p(-45, 26),
            "shoulder_near": p(36, -78),
            "elbow_near": p(52, -25),
            "wrist_near": p(45, 26),
            "hip_far": p(-18, 7),
            "knee_far": p(-25, 62),
            "ankle_far": p(-24, 124),
            "hip_near": p(18, 7),
            "knee_near": p(25, 62),
            "ankle_near": p(24, 124),
        }

    if direction.facing == "front_diag":
        base = {
            "neck": p(7, -96),
            "head": p(9, -124),
            "shoulder_far": p(-27, -80),
            "elbow_far": p(-39, -31),
            "wrist_far": p(-29, 20),
            "shoulder_near": p(35, -75),
            "elbow_near": p(51, -25),
            "wrist_near": p(41, 29),
            "hip_far": p(-14, 5),
            "knee_far": p(-22, 58),
            "ankle_far": p(-16, 120),
            "hip_near": p(16, 9),
            "knee_near": p(31, 64),
            "ankle_near": p(31, 126),
        }
        return mirror(base, direction.sign)

    if direction.facing == "side":
        base = {
            "neck": p(7, -96),
            "head": p(11, -124),
            "shoulder_far": p(-7, -79),
            "elbow_far": p(-15, -29),
            "wrist_far": p(-6, 24),
            "shoulder_near": p(14, -76),
            "elbow_near": p(24, -25),
            "wrist_near": p(19, 30),
            "hip_far": p(-6, 7),
            "knee_far": p(-8, 61),
            "ankle_far": p(-2, 122),
            "hip_near": p(8, 10),
            "knee_near": p(18, 66),
            "ankle_near": p(23, 126),
        }
        return mirror(base, direction.sign)

    if direction.facing == "back_diag":
        base = {
            "neck": p(5, -96),
            "head": p(7, -124),
            "shoulder_far": p(-30, -75),
            "elbow_far": p(-44, -24),
            "wrist_far": p(-37, 28),
            "shoulder_near": p(30, -82),
            "elbow_near": p(46, -31),
            "wrist_near": p(39, 22),
            "hip_far": p(-14, 9),
            "knee_far": p(-18, 64),
            "ankle_far": p(-13, 124),
            "hip_near": p(14, 5),
            "knee_near": p(28, 60),
            "ankle_near": p(30, 122),
        }
        return mirror(base, direction.sign)

    raise ValueError(f"unknown facing {direction.facing}")


def make_torso(direction: Direction) -> list[list[float]]:
    if direction.facing in {"front", "back"}:
        return [p(-32, -92), p(32, -92), p(26, -24), p(15, 12), p(-15, 12), p(-26, -24)]
    if direction.facing == "front_diag":
        points = [p(-29, -92), p(33, -86), p(24, -20), p(11, 14), p(-16, 8), p(-25, -24)]
    elif direction.facing == "side":
        points = [p(-12, -90), p(20, -84), p(17, -19), p(7, 16), p(-9, 10), p(-14, -25)]
    elif direction.facing == "back_diag":
        points = [p(-31, -87), p(28, -92), p(23, -22), p(12, 14), p(-16, 10), p(-24, -18)]
    else:
        raise ValueError(f"unknown facing {direction.facing}")
    if direction.sign == -1:
        return [p(-point[0], point[1]) for point in points]
    return points


def make_head(direction: Direction) -> dict:
    head = {
        "center": make_joints(direction)["head"],
        "rx": 21 if direction.facing != "side" else 18,
        "ry": 25,
        "view": direction.facing,
        "sign": direction.sign,
    }
    if direction.facing == "front":
        head["sign"] = 0
    if direction.facing == "back":
        head["sign"] = 0
    return head


def make_pose(direction: Direction) -> dict:
    joints = make_joints(direction)
    torso = make_torso(direction)
    head = make_head(direction)
    parts = {
        "head": {"type": "ellipse", **head},
        "torso": {"type": "polygon", "points": torso},
        "upper_arm_far": {"type": "capsule", "part_type": "upper_arm", "from": joints["shoulder_far"], "to": joints["elbow_far"], "width": 18},
        "forearm_far": {"type": "capsule", "part_type": "forearm", "from": joints["elbow_far"], "to": joints["wrist_far"], "width": 15},
        "upper_arm_near": {"type": "capsule", "part_type": "upper_arm", "from": joints["shoulder_near"], "to": joints["elbow_near"], "width": 19},
        "forearm_near": {"type": "capsule", "part_type": "forearm", "from": joints["elbow_near"], "to": joints["wrist_near"], "width": 16},
        "thigh_far": {"type": "capsule", "part_type": "thigh", "from": joints["hip_far"], "to": joints["knee_far"], "width": 22},
        "calf_far": {"type": "capsule", "part_type": "calf", "from": joints["knee_far"], "to": joints["ankle_far"], "width": 18},
        "thigh_near": {"type": "capsule", "part_type": "thigh", "from": joints["hip_near"], "to": joints["knee_near"], "width": 23},
        "calf_near": {"type": "capsule", "part_type": "calf", "from": joints["knee_near"], "to": joints["ankle_near"], "width": 19},
    }
    return {"joints": joints, "parts": parts}


def hex_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16)


def svg_color(value: str, opacity: float = 1.0) -> str:
    if opacity >= 1.0:
        return value
    r, g, b = hex_rgb(value)
    return f"rgba({r},{g},{b},{opacity:.3f})"


def xml_escape(value: str) -> str:
    return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def transform(cell_x: float, cell_y: float, point: Iterable[float], scale: float = 1.0) -> tuple[float, float]:
    x, y = point
    return cell_x + ROOT_IN_CELL[0] + x * scale, cell_y + ROOT_IN_CELL[1] + y * scale


def line_svg(x1: float, y1: float, x2: float, y2: float, **attrs: str | float) -> str:
    attr = " ".join(f'{key.replace("_", "-")}="{value}"' for key, value in attrs.items())
    return f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" {attr}/>'


def circle_svg(cx: float, cy: float, r: float, **attrs: str | float) -> str:
    attr = " ".join(f'{key.replace("_", "-")}="{value}"' for key, value in attrs.items())
    return f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}" {attr}/>'


def polygon_svg(points: list[tuple[float, float]], **attrs: str | float) -> str:
    attr = " ".join(f'{key.replace("_", "-")}="{value}"' for key, value in attrs.items())
    pts = " ".join(f"{x:.1f},{y:.1f}" for x, y in points)
    return f'<polygon points="{pts}" {attr}/>'


def text_svg(x: float, y: float, text: str, klass: str = "label", anchor: str = "start") -> str:
    return f'<text x="{x:.1f}" y="{y:.1f}" class="{klass}" text-anchor="{anchor}">{xml_escape(text)}</text>'


def render_capsule_svg(cell_x: float, cell_y: float, part: dict, color: str, opacity: float, part_id: str) -> list[str]:
    x1, y1 = transform(cell_x, cell_y, part["from"])
    x2, y2 = transform(cell_x, cell_y, part["to"])
    width = float(part["width"])
    return [
        line_svg(x1, y1, x2, y2, stroke=COLORS["outline"], stroke_width=width + 4, stroke_linecap="round", opacity=0.92),
        line_svg(x1, y1, x2, y2, stroke=color, stroke_width=width, stroke_linecap="round", opacity=opacity, id=part_id),
    ]


def render_head_details_svg(cell_x: float, cell_y: float, head: dict) -> list[str]:
    cx, cy = transform(cell_x, cell_y, head["center"])
    sign = int(head.get("sign", 0))
    view = head["view"]
    out: list[str] = []
    if view in {"front", "front_diag", "side"}:
        if sign == 0:
            out.append(circle_svg(cx - 7, cy - 4, 2.0, fill="#14181d"))
            out.append(circle_svg(cx + 7, cy - 4, 2.0, fill="#14181d"))
            out.append(line_svg(cx, cy - 2, cx, cy + 7, stroke="#7c593b", stroke_width=1.8, stroke_linecap="round"))
        else:
            out.append(circle_svg(cx + sign * 7, cy - 5, 2.1, fill="#14181d"))
            out.append(line_svg(cx + sign * 4, cy - 2, cx + sign * 15, cy + 3, stroke="#7c593b", stroke_width=1.8, stroke_linecap="round"))
            out.append(circle_svg(cx + sign * 19, cy + 2, 2.4, fill="#dfb076", opacity=0.9))
    else:
        out.append(line_svg(cx - 10, cy - 12, cx + 10, cy - 12, stroke="#3d2f2a", stroke_width=3, stroke_linecap="round", opacity=0.78))
        out.append(line_svg(cx, cy - 20, cx, cy + 14, stroke="#3d2f2a", stroke_width=2, stroke_linecap="round", opacity=0.7))
    return out


def render_direction_arrow_svg(cell_x: float, cell_y: float, direction: Direction) -> list[str]:
    vectors = {
        "down": (0, 1),
        "down_right": (0.74, 0.74),
        "right": (1, 0),
        "up_right": (0.74, -0.74),
        "up": (0, -1),
        "up_left": (-0.74, -0.74),
        "left": (-1, 0),
        "down_left": (-0.74, 0.74),
    }
    vx, vy = vectors[direction.key]
    cx = cell_x + CELL_W - 38
    cy = cell_y + 34
    x2 = cx + vx * 20
    y2 = cy + vy * 20
    return [
        circle_svg(cx, cy, 23, fill="#202833", stroke=COLORS["grid"], stroke_width=1),
        line_svg(cx - vx * 10, cy - vy * 10, x2, y2, stroke=COLORS["center"], stroke_width=3, stroke_linecap="round"),
        polygon_svg(
            [
                (x2, y2),
                (x2 - vx * 8 - vy * 4, y2 - vy * 8 + vx * 4),
                (x2 - vx * 8 + vy * 4, y2 - vy * 8 - vx * 4),
            ],
            fill=COLORS["center"],
        ),
    ]


def render_pose_svg(direction: Direction, pose: dict) -> str:
    cell_x = MARGIN + direction.col * CELL_W
    cell_y = HEADER + direction.row * CELL_H
    out: list[str] = []
    out.append(f'<g id="{direction.key}" transform="translate(0,0)">')
    out.append(f'<rect x="{cell_x + 6:.1f}" y="{cell_y + 8:.1f}" width="{CELL_W - 12:.1f}" height="{CELL_H - 16:.1f}" rx="8" fill="{COLORS["panel"]}" stroke="{COLORS["grid"]}" stroke-width="1"/>')
    out.append(text_svg(cell_x + 18, cell_y + 34, direction.label, "label"))
    out.extend(render_direction_arrow_svg(cell_x, cell_y, direction))
    root_x, root_y = transform(cell_x, cell_y, (0, 0))
    out.append(line_svg(cell_x + 28, root_y + 125, cell_x + CELL_W - 28, root_y + 125, stroke="#28313b", stroke_width=1))
    out.append(line_svg(root_x, root_y - 154, root_x, root_y + 132, stroke=COLORS["center"], stroke_width=1.2, stroke_dasharray="4 6", opacity=0.36))

    parts = pose["parts"]
    order = [
        ("thigh_far", 0.58),
        ("calf_far", 0.58),
        ("upper_arm_far", 0.56),
        ("forearm_far", 0.56),
        ("torso", 1.0),
        ("head", 1.0),
        ("thigh_near", 1.0),
        ("calf_near", 1.0),
        ("upper_arm_near", 1.0),
        ("forearm_near", 1.0),
    ]
    for name, opacity in order:
        part = parts[name]
        if part["type"] == "capsule":
            out.extend(render_capsule_svg(cell_x, cell_y, part, COLORS[part["part_type"]], opacity, f"{direction.key}_{name}"))
        elif part["type"] == "polygon":
            pts = [transform(cell_x, cell_y, point) for point in part["points"]]
            out.append(polygon_svg(pts, fill=COLORS["torso"], stroke=COLORS["outline"], stroke_width=4, opacity=0.96))
            out.append(polygon_svg(pts, fill=COLORS["torso"], stroke="#91c2da", stroke_width=1.4, opacity=0.98, id=f"{direction.key}_{name}"))
        elif part["type"] == "ellipse":
            cx, cy = transform(cell_x, cell_y, part["center"])
            out.append(f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{part["rx"] + 2:.1f}" ry="{part["ry"] + 2:.1f}" fill="{COLORS["outline"]}" opacity="0.94"/>')
            out.append(f'<ellipse id="{direction.key}_{name}" cx="{cx:.1f}" cy="{cy:.1f}" rx="{part["rx"]:.1f}" ry="{part["ry"]:.1f}" fill="{COLORS["head"]}" stroke="#ffdfad" stroke-width="1.5"/>')
            out.extend(render_head_details_svg(cell_x, cell_y, part))

    for joint_name, joint in pose["joints"].items():
        x, y = transform(cell_x, cell_y, joint)
        radius = 4.2 if joint_name in {"neck", "head"} else 3.5
        out.append(circle_svg(x, y, radius + 1.4, fill=COLORS["outline"], opacity=0.85))
        out.append(circle_svg(x, y, radius, fill=COLORS["joint"], stroke="#3e5368", stroke_width=1.2, id=f"{direction.key}_{joint_name}"))
    out.append("</g>")
    return "\n".join(out)


def build_svg(poses: dict[str, dict]) -> str:
    out = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}" role="img" aria-labelledby="title desc">',
        '<title id="title">2D humanoid skeleton eight-way reference</title>',
        '<desc id="desc">Program generated eight-way humanoid skeleton reference with separated head, torso, upper arm, forearm, thigh and calf parts.</desc>',
        "<defs>",
        "<style>",
        'text { font-family: "Microsoft YaHei", "Noto Sans CJK SC", Arial, sans-serif; }',
        ".title { font-size: 25px; font-weight: 700; fill: #f4f8fb; }",
        ".subtitle { font-size: 13px; fill: #aeb9c5; }",
        ".label { font-size: 15px; font-weight: 700; fill: #eef4fa; }",
        ".small { font-size: 11px; fill: #9aa8b6; }",
        "</style>",
        "</defs>",
        f'<rect width="{WIDTH}" height="{HEIGHT}" fill="{COLORS["bg"]}"/>',
        text_svg(MARGIN, 36, "2D 骨骼角色八向基准图 - 程序绘制 V1", "title"),
        text_svg(MARGIN, 60, "每格保留独立部件与 pivot：头、躯干、大臂、小臂、大腿、小腿；斜向和侧向使用遮挡层级而不是简单旋转。", "subtitle"),
    ]
    legend_x = WIDTH - 430
    legend_y = 30
    legend = [
        ("头", COLORS["head"]),
        ("躯干", COLORS["torso"]),
        ("大臂", COLORS["upper_arm"]),
        ("小臂", COLORS["forearm"]),
        ("大腿", COLORS["thigh"]),
        ("小腿", COLORS["calf"]),
    ]
    lx = legend_x
    for label, color in legend:
        out.append(f'<rect x="{lx:.1f}" y="{legend_y:.1f}" width="14" height="14" rx="3" fill="{color}"/>')
        out.append(text_svg(lx + 19, legend_y + 12, label, "small"))
        lx += 63
    for direction in DIRECTIONS:
        out.append(render_pose_svg(direction, poses[direction.key]))
    out.append("</svg>")
    return "\n".join(out)


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        Path("C:/Windows/Fonts/msyh.ttc"),
        Path("C:/Windows/Fonts/simhei.ttf"),
        Path("C:/Windows/Fonts/arial.ttf"),
    ]
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size * PNG_SCALE)
    return ImageFont.load_default()


def pil_xy(cell_x: float, cell_y: float, point: Iterable[float]) -> tuple[int, int]:
    x, y = transform(cell_x, cell_y, point)
    return round(x * PNG_SCALE), round(y * PNG_SCALE)


def scaled_rect(rect: tuple[float, float, float, float]) -> tuple[int, int, int, int]:
    return tuple(round(value * PNG_SCALE) for value in rect)  # type: ignore[return-value]


def rgba(value: str, opacity: float = 1.0) -> tuple[int, int, int, int]:
    r, g, b = hex_rgb(value)
    return r, g, b, round(255 * opacity)


def draw_text(draw: ImageDraw.ImageDraw, xy: tuple[float, float], text: str, font: ImageFont.ImageFont, fill: str, anchor: str | None = None) -> None:
    scaled = (round(xy[0] * PNG_SCALE), round(xy[1] * PNG_SCALE))
    draw.text(scaled, text, font=font, fill=rgba(fill), anchor=anchor)


def draw_capsule(canvas: Image.Image, p1: tuple[int, int], p2: tuple[int, int], width: int, color: str, opacity: float) -> None:
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    outline_w = width + 4 * PNG_SCALE
    draw.line((p1[0], p1[1], p2[0], p2[1]), fill=rgba(COLORS["outline"], 0.92), width=outline_w)
    for point in (p1, p2):
        r = outline_w / 2
        draw.ellipse((point[0] - r, point[1] - r, point[0] + r, point[1] + r), fill=rgba(COLORS["outline"], 0.92))
    draw.line((p1[0], p1[1], p2[0], p2[1]), fill=rgba(color, opacity), width=width)
    for point in (p1, p2):
        r = width / 2
        draw.ellipse((point[0] - r, point[1] - r, point[0] + r, point[1] + r), fill=rgba(color, opacity))
    canvas.alpha_composite(overlay)


def draw_polygon(canvas: Image.Image, points: list[tuple[int, int]], fill: str) -> None:
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.polygon(points, fill=rgba(COLORS["outline"], 0.94))
    inset_points = points
    draw.line(points + [points[0]], fill=rgba(COLORS["outline"], 0.94), width=5 * PNG_SCALE, joint="curve")
    draw.polygon(inset_points, fill=rgba(fill, 0.96))
    draw.line(points + [points[0]], fill=rgba("#91c2da", 0.98), width=2 * PNG_SCALE, joint="curve")
    canvas.alpha_composite(overlay)


def draw_head_details(draw: ImageDraw.ImageDraw, cell_x: float, cell_y: float, head: dict) -> None:
    cx, cy = pil_xy(cell_x, cell_y, head["center"])
    sign = int(head.get("sign", 0))
    view = head["view"]
    if view in {"front", "front_diag", "side"}:
        if sign == 0:
            for dx in (-7, 7):
                r = 2.2 * PNG_SCALE
                draw.ellipse((cx + dx * PNG_SCALE - r, cy - 4 * PNG_SCALE - r, cx + dx * PNG_SCALE + r, cy - 4 * PNG_SCALE + r), fill=rgba("#14181d"))
            draw.line((cx, cy - 2 * PNG_SCALE, cx, cy + 7 * PNG_SCALE), fill=rgba("#7c593b"), width=2 * PNG_SCALE)
        else:
            r = 2.2 * PNG_SCALE
            draw.ellipse((cx + sign * 7 * PNG_SCALE - r, cy - 5 * PNG_SCALE - r, cx + sign * 7 * PNG_SCALE + r, cy - 5 * PNG_SCALE + r), fill=rgba("#14181d"))
            draw.line((cx + sign * 4 * PNG_SCALE, cy - 2 * PNG_SCALE, cx + sign * 15 * PNG_SCALE, cy + 3 * PNG_SCALE), fill=rgba("#7c593b"), width=2 * PNG_SCALE)
            nr = 2.4 * PNG_SCALE
            draw.ellipse((cx + sign * 19 * PNG_SCALE - nr, cy + 2 * PNG_SCALE - nr, cx + sign * 19 * PNG_SCALE + nr, cy + 2 * PNG_SCALE + nr), fill=rgba("#dfb076", 0.9))
    else:
        draw.line((cx - 10 * PNG_SCALE, cy - 12 * PNG_SCALE, cx + 10 * PNG_SCALE, cy - 12 * PNG_SCALE), fill=rgba("#3d2f2a", 0.78), width=3 * PNG_SCALE)
        draw.line((cx, cy - 20 * PNG_SCALE, cx, cy + 14 * PNG_SCALE), fill=rgba("#3d2f2a", 0.7), width=2 * PNG_SCALE)


def draw_arrow(draw: ImageDraw.ImageDraw, cell_x: float, cell_y: float, direction: Direction) -> None:
    vectors = {
        "down": (0, 1),
        "down_right": (0.74, 0.74),
        "right": (1, 0),
        "up_right": (0.74, -0.74),
        "up": (0, -1),
        "up_left": (-0.74, -0.74),
        "left": (-1, 0),
        "down_left": (-0.74, 0.74),
    }
    vx, vy = vectors[direction.key]
    cx = round((cell_x + CELL_W - 38) * PNG_SCALE)
    cy = round((cell_y + 34) * PNG_SCALE)
    r = 23 * PNG_SCALE
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=rgba("#202833"), outline=rgba(COLORS["grid"]))
    x1 = cx - vx * 10 * PNG_SCALE
    y1 = cy - vy * 10 * PNG_SCALE
    x2 = cx + vx * 20 * PNG_SCALE
    y2 = cy + vy * 20 * PNG_SCALE
    draw.line((x1, y1, x2, y2), fill=rgba(COLORS["center"]), width=3 * PNG_SCALE)
    tip = [
        (x2, y2),
        (x2 - vx * 8 * PNG_SCALE - vy * 4 * PNG_SCALE, y2 - vy * 8 * PNG_SCALE + vx * 4 * PNG_SCALE),
        (x2 - vx * 8 * PNG_SCALE + vy * 4 * PNG_SCALE, y2 - vy * 8 * PNG_SCALE - vx * 4 * PNG_SCALE),
    ]
    draw.polygon([(round(x), round(y)) for x, y in tip], fill=rgba(COLORS["center"]))


def render_pose_png(canvas: Image.Image, direction: Direction, pose: dict, fonts: dict[str, ImageFont.ImageFont]) -> None:
    draw = ImageDraw.Draw(canvas)
    cell_x = MARGIN + direction.col * CELL_W
    cell_y = HEADER + direction.row * CELL_H
    draw.rounded_rectangle(
        scaled_rect((cell_x + 6, cell_y + 8, cell_x + CELL_W - 6, cell_y + CELL_H - 8)),
        radius=8 * PNG_SCALE,
        fill=rgba(COLORS["panel"]),
        outline=rgba(COLORS["grid"]),
        width=1 * PNG_SCALE,
    )
    draw_text(draw, (cell_x + 18, cell_y + 34), direction.label, fonts["label"], COLORS["text"])
    draw_arrow(draw, cell_x, cell_y, direction)
    root_x, root_y = transform(cell_x, cell_y, (0, 0))
    draw.line(scaled_rect((cell_x + 28, root_y + 125, cell_x + CELL_W - 28, root_y + 125)), fill=rgba("#28313b"), width=1 * PNG_SCALE)
    draw.line(scaled_rect((root_x, root_y - 154, root_x, root_y + 132)), fill=rgba(COLORS["center"], 0.36), width=1 * PNG_SCALE)

    parts = pose["parts"]
    order = [
        ("thigh_far", 0.58),
        ("calf_far", 0.58),
        ("upper_arm_far", 0.56),
        ("forearm_far", 0.56),
        ("torso", 1.0),
        ("head", 1.0),
        ("thigh_near", 1.0),
        ("calf_near", 1.0),
        ("upper_arm_near", 1.0),
        ("forearm_near", 1.0),
    ]
    for name, opacity in order:
        part = parts[name]
        if part["type"] == "capsule":
            draw_capsule(canvas, pil_xy(cell_x, cell_y, part["from"]), pil_xy(cell_x, cell_y, part["to"]), round(part["width"] * PNG_SCALE), COLORS[part["part_type"]], opacity)
        elif part["type"] == "polygon":
            draw_polygon(canvas, [pil_xy(cell_x, cell_y, point) for point in part["points"]], COLORS["torso"])
        elif part["type"] == "ellipse":
            cx, cy = pil_xy(cell_x, cell_y, part["center"])
            rx = part["rx"] * PNG_SCALE
            ry = part["ry"] * PNG_SCALE
            draw.ellipse((cx - rx - 2 * PNG_SCALE, cy - ry - 2 * PNG_SCALE, cx + rx + 2 * PNG_SCALE, cy + ry + 2 * PNG_SCALE), fill=rgba(COLORS["outline"], 0.94))
            draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=rgba(COLORS["head"]), outline=rgba("#ffdfad"), width=2 * PNG_SCALE)
            draw_head_details(draw, cell_x, cell_y, part)

    for joint_name, joint in pose["joints"].items():
        x, y = pil_xy(cell_x, cell_y, joint)
        radius = (4.2 if joint_name in {"neck", "head"} else 3.5) * PNG_SCALE
        draw.ellipse((x - radius - 1.4 * PNG_SCALE, y - radius - 1.4 * PNG_SCALE, x + radius + 1.4 * PNG_SCALE, y + radius + 1.4 * PNG_SCALE), fill=rgba(COLORS["outline"], 0.85))
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=rgba(COLORS["joint"]), outline=rgba("#3e5368"), width=1 * PNG_SCALE)


def build_png(poses: dict[str, dict]) -> Image.Image:
    canvas = Image.new("RGBA", (WIDTH * PNG_SCALE, HEIGHT * PNG_SCALE), rgba(COLORS["bg"]))
    draw = ImageDraw.Draw(canvas)
    fonts = {
        "title": load_font(25),
        "subtitle": load_font(13),
        "label": load_font(15),
        "small": load_font(11),
    }
    draw_text(draw, (MARGIN, 36), "2D 骨骼角色八向基准图 - 程序绘制 V1", fonts["title"], COLORS["text"])
    draw_text(draw, (MARGIN, 60), "每格保留独立部件与 pivot：头、躯干、大臂、小臂、大腿、小腿；斜向和侧向使用遮挡层级而不是简单旋转。", fonts["subtitle"], COLORS["muted"])
    legend_x = WIDTH - 430
    legend_y = 30
    lx = legend_x
    for label, color in [
        ("头", COLORS["head"]),
        ("躯干", COLORS["torso"]),
        ("大臂", COLORS["upper_arm"]),
        ("小臂", COLORS["forearm"]),
        ("大腿", COLORS["thigh"]),
        ("小腿", COLORS["calf"]),
    ]:
        draw.rounded_rectangle(scaled_rect((lx, legend_y, lx + 14, legend_y + 14)), radius=3 * PNG_SCALE, fill=rgba(color))
        draw_text(draw, (lx + 19, legend_y + 12), label, fonts["small"], COLORS["muted"])
        lx += 63

    for direction in DIRECTIONS:
        render_pose_png(canvas, direction, poses[direction.key], fonts)
    return canvas.resize((WIDTH, HEIGHT), Image.Resampling.LANCZOS)


def export_data(poses: dict[str, dict]) -> dict:
    return {
        "version": 1,
        "unit": "local_pixels",
        "part_types": ["head", "torso", "upper_arm", "forearm", "thigh", "calf"],
        "notes": [
            "This is a programmatic reference sheet, not final character art.",
            "near/far limbs are kept separate so the layer order can change per direction.",
            "Joints are local to each direction root; root is drawn under the body baseline.",
        ],
        "directions": [
            {
                "key": direction.key,
                "label": direction.label,
                "facing": direction.facing,
                "grid": [direction.col, direction.row],
                "joints": poses[direction.key]["joints"],
                "parts": poses[direction.key]["parts"],
            }
            for direction in DIRECTIONS
        ],
    }


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    poses = {direction.key: make_pose(direction) for direction in DIRECTIONS}
    SVG_OUT.write_text(build_svg(poses), encoding="utf-8")
    build_png(poses).save(PNG_OUT)
    JSON_OUT.write_text(json.dumps(export_data(poses), ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"wrote {SVG_OUT}")
    print(f"wrote {PNG_OUT}")
    print(f"wrote {JSON_OUT}")


if __name__ == "__main__":
    main()
