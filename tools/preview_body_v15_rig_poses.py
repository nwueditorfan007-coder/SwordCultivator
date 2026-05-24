"""Render offline previews for the V15 ink body rig poses.

This mirrors the Godot rig loader closely enough to inspect pivots, z-order,
pose positions, and socket placement without launching the editor.
"""
from __future__ import annotations

import json
from math import ceil
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
RIG_DIR = ROOT / "resources/flight/rider/body_v15_ink_rig"
MANIFEST_PATH = RIG_DIR / "body_v15_ink_rig_manifest.json"
POSE_PATH = RIG_DIR / "body_v15_ink_pose_library.json"
SOCKET_PATH = RIG_DIR / "body_v15_ink_socket_library.json"
OUT_DIR = RIG_DIR / "preview"

PREVIEW_SIZE = (640, 500)
CONTACT_COLUMNS = 3
PREVIEW_SCALE = 0.24
ROOT_SCREEN = (250, 420)


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def load_parts(manifest: dict) -> dict[str, Image.Image]:
    parts = {}
    for name, part in manifest["parts"].items():
        parts[name] = Image.open(RIG_DIR / part["file"]).convert("RGBA")
    return parts


def resize_part(image: Image.Image, scale: float) -> Image.Image:
    return image.resize(
        (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
        Image.Resampling.LANCZOS,
    )


def paste_rotated(
    canvas: Image.Image,
    part: Image.Image,
    *,
    pivot: tuple[float, float],
    position: tuple[float, float],
    rotation_degrees: float,
) -> None:
    max_dim = max(part.width, part.height)
    margin = max(64, max_dim)
    temp_size = (part.width + margin * 2, part.height + margin * 2)
    center = (margin + pivot[0], margin + pivot[1])
    temp = Image.new("RGBA", temp_size, (0, 0, 0, 0))
    temp.alpha_composite(part, (margin, margin))
    # Godot 2D positive rotation is visually clockwise in this project preview.
    rotated = temp.rotate(-rotation_degrees, resample=Image.Resampling.BICUBIC, center=center, expand=False)
    paste_x = round(position[0] - center[0])
    paste_y = round(position[1] - center[1])
    canvas.alpha_composite(rotated, (paste_x, paste_y))


def draw_cross(draw: ImageDraw.ImageDraw, x: float, y: float, color: tuple[int, int, int, int], radius: int = 5) -> None:
    draw.line((x - radius, y, x + radius, y), fill=color, width=2)
    draw.line((x, y - radius, x, y + radius), fill=color, width=2)


def render_pose(
    pose_name: str,
    pose: dict,
    manifest: dict,
    socket_data: dict | None,
    parts: dict[str, Image.Image],
) -> Image.Image:
    bg = Image.new("RGBA", PREVIEW_SIZE, (25, 25, 25, 255))
    draw = ImageDraw.Draw(bg)
    root_x, root_y = ROOT_SCREEN
    draw.line((0, root_y, PREVIEW_SIZE[0], root_y), fill=(70, 70, 70, 255), width=1)
    draw_cross(draw, root_x, root_y, (255, 220, 70, 255), 6)

    ordered = sorted(pose.items(), key=lambda item: int(item[1].get("z_index", 0)))
    for part_name, transform in ordered:
        if part_name not in parts:
            continue
        part_def = manifest["parts"][part_name]
        pivot = part_def["pivot"]
        scaled = resize_part(parts[part_name], PREVIEW_SCALE)
        pivot_scaled = (float(pivot[0]) * PREVIEW_SCALE, float(pivot[1]) * PREVIEW_SCALE)
        pos = transform["position"]
        screen_pos = (
            root_x + float(pos[0]) * PREVIEW_SCALE,
            root_y + float(pos[1]) * PREVIEW_SCALE,
        )
        paste_rotated(
            bg,
            scaled,
            pivot=pivot_scaled,
            position=screen_pos,
            rotation_degrees=float(transform.get("rotation_degrees", 0.0)),
        )

    draw = ImageDraw.Draw(bg)
    draw.text((12, 10), pose_name, fill=(235, 235, 235, 255))
    if socket_data:
        colors = {
            "chest": (90, 210, 255, 255),
            "head": (180, 130, 255, 255),
            "hand_front": (255, 245, 90, 255),
            "hand_back": (255, 170, 90, 255),
            "hilt": (110, 255, 185, 255),
        }
        for key, color in colors.items():
            if key not in socket_data:
                continue
            x = root_x + float(socket_data[key][0]) * PREVIEW_SCALE
            y = root_y + float(socket_data[key][1]) * PREVIEW_SCALE
            draw_cross(draw, x, y, color, 5)
        if "hilt" in socket_data and "aim_forward" in socket_data:
            hx = root_x + float(socket_data["hilt"][0]) * PREVIEW_SCALE
            hy = root_y + float(socket_data["hilt"][1]) * PREVIEW_SCALE
            ax = hx + float(socket_data["aim_forward"][0]) * 48
            ay = hy + float(socket_data["aim_forward"][1]) * 48
            draw.line((hx, hy, ax, ay), fill=(110, 255, 185, 255), width=2)
    return bg


def make_contact_sheet(images: list[tuple[str, Image.Image]]) -> Image.Image:
    rows = ceil(len(images) / CONTACT_COLUMNS)
    sheet = Image.new(
        "RGBA",
        (PREVIEW_SIZE[0] * CONTACT_COLUMNS, PREVIEW_SIZE[1] * rows),
        (18, 18, 18, 255),
    )
    for index, (_, image) in enumerate(images):
        x = (index % CONTACT_COLUMNS) * PREVIEW_SIZE[0]
        y = (index // CONTACT_COLUMNS) * PREVIEW_SIZE[1]
        sheet.alpha_composite(image, (x, y))
    return sheet


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    manifest = load_json(MANIFEST_PATH)
    pose_library = load_json(POSE_PATH)
    socket_library = load_json(SOCKET_PATH)
    parts = load_parts(manifest)

    rendered: list[tuple[str, Image.Image]] = []
    for pose_name, pose in pose_library["poses"].items():
        image = render_pose(
            pose_name,
            pose,
            manifest,
            socket_library.get("poses", {}).get(pose_name),
            parts,
        )
        image.save(OUT_DIR / f"{pose_name}.png")
        rendered.append((pose_name, image))

    contact = make_contact_sheet(rendered)
    contact.save(OUT_DIR / "body_v15_ink_pose_contact_sheet.png")
    print(f"wrote {len(rendered)} pose previews to {OUT_DIR}")
    print(f"wrote {OUT_DIR / 'body_v15_ink_pose_contact_sheet.png'}")


if __name__ == "__main__":
    main()
