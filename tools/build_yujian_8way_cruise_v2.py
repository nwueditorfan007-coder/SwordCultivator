from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = PROJECT_ROOT / "resources" / "flight" / "yujian_8way_cruise_generated_v1" / "accepted"
OUTPUT_DIR = PROJECT_ROOT / "resources" / "flight" / "yujian_8way_cruise_generated_v1" / "prototype_v2"
ADJUSTMENTS_PATH = PROJECT_ROOT / "resources" / "flight" / "yujian_8way_cruise_generated_v1" / "prototype_v2_adjustments.json"

CANVAS_SIZE = 768
SAFE_MARGIN = 32
DEFAULT_TARGET_HEAD_WIDTH = 86.0

SOURCE_SPECS = {
    "01_right": ("01_right.png", (960, 220, 1095, 385)),
    "02_up_right": ("02_up_right.png", (680, 265, 795, 390)),
    "03_up": ("03_up.png", (565, 385, 695, 520)),
    "04_up_left": ("04_up_left_candidate_v1.png", (360, 185, 500, 320)),
    "05_left": ("05_left.png", (420, 215, 565, 350)),
    "06_down_left": ("06_down_left_candidate_v1.png", (395, 295, 550, 500)),
    "07_down": ("07_down.png", (545, 270, 700, 515)),
    "08_down_right": ("08_down_right.png", (670, 315, 800, 505)),
}


def smoothstep(edge0: float, edge1: float, values: np.ndarray) -> np.ndarray:
    t = np.clip((values - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def get_background_color(pixels: np.ndarray) -> np.ndarray:
    corners = np.concatenate(
        [
            pixels[:24, :24, :3].reshape(-1, 3),
            pixels[:24, -24:, :3].reshape(-1, 3),
            pixels[-24:, :24, :3].reshape(-1, 3),
            pixels[-24:, -24:, :3].reshape(-1, 3),
        ],
        axis=0,
    )
    return np.median(corners, axis=0)


def get_foreground_bbox(pixels: np.ndarray, background: np.ndarray) -> tuple[int, int, int, int]:
    distance = np.linalg.norm(pixels[:, :, :3].astype(np.float32) - background.astype(np.float32), axis=2)
    mask = distance > 28.0
    ys, xs = np.where(mask)
    if len(xs) == 0:
        return (0, 0, pixels.shape[1], pixels.shape[0])
    return (int(xs.min()), int(ys.min()), int(xs.max() + 1), int(ys.max() + 1))


def make_rgba_source(path: Path) -> tuple[Image.Image, tuple[int, int, int, int]]:
    image = Image.open(path).convert("RGBA")
    pixels = np.array(image)
    background = get_background_color(pixels)
    distance = np.linalg.norm(pixels[:, :, :3].astype(np.float32) - background.astype(np.float32), axis=2)
    alpha = smoothstep(20.0, 46.0, distance) * 255.0
    alpha[distance <= 18.0] = 0.0
    pixels[:, :, 3] = np.clip(alpha, 0, 255).astype(np.uint8)
    return Image.fromarray(pixels, "RGBA"), get_foreground_bbox(pixels, background)


def load_adjustments() -> dict:
    if not ADJUSTMENTS_PATH.exists():
        return {}
    with ADJUSTMENTS_PATH.open("r", encoding="utf-8") as file:
        return json.load(file)


def get_direction_adjustment(adjustments: dict, output_name: str) -> dict:
    directions = adjustments.get("directions", {})
    if not isinstance(directions, dict):
        return {}
    direction = directions.get(output_name, {})
    return direction if isinstance(direction, dict) else {}


def get_offset(adjustment: dict) -> tuple[float, float]:
    raw_offset = adjustment.get("offset", [0.0, 0.0])
    if not isinstance(raw_offset, list) or len(raw_offset) != 2:
        return (0.0, 0.0)
    return (float(raw_offset[0]), float(raw_offset[1]))


def get_transformed_margin(
    foreground_bbox: tuple[int, int, int, int],
    scale: float,
    paste_position: tuple[int, int],
) -> float:
    left = foreground_bbox[0] * scale + paste_position[0]
    top = foreground_bbox[1] * scale + paste_position[1]
    right = foreground_bbox[2] * scale + paste_position[0]
    bottom = foreground_bbox[3] * scale + paste_position[1]
    return min(left, top, CANVAS_SIZE - right, CANVAS_SIZE - bottom)


def paste_normalized_sprite(
    image: Image.Image,
    foreground_bbox: tuple[int, int, int, int],
    head_bbox: tuple[int, int, int, int],
    target_head_width: float,
    scale_multiplier: float,
    offset: tuple[float, float],
) -> tuple[Image.Image, float, float]:
    foreground_width = foreground_bbox[2] - foreground_bbox[0]
    foreground_height = foreground_bbox[3] - foreground_bbox[1]
    head_width = head_bbox[2] - head_bbox[0]

    scale_by_head = target_head_width / max(float(head_width), 1.0)
    scale_by_fit = min(
        (CANVAS_SIZE - SAFE_MARGIN * 2) / max(float(foreground_width), 1.0),
        (CANVAS_SIZE - SAFE_MARGIN * 2) / max(float(foreground_height), 1.0),
    )
    scale = min(scale_by_head, scale_by_fit) * scale_multiplier

    resized_size = (
        max(1, round(image.width * scale)),
        max(1, round(image.height * scale)),
    )
    resized = image.resize(resized_size, Image.Resampling.LANCZOS)

    foreground_center = (
        (foreground_bbox[0] + foreground_bbox[2]) * 0.5 * scale,
        (foreground_bbox[1] + foreground_bbox[3]) * 0.5 * scale,
    )
    paste_position = (
        round(CANVAS_SIZE * 0.5 - foreground_center[0] + offset[0]),
        round(CANVAS_SIZE * 0.5 - foreground_center[1] + offset[1]),
    )
    frame_margin = get_transformed_margin(foreground_bbox, scale, paste_position)

    canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(resized, paste_position)
    return canvas, scale, frame_margin


def make_checker(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    step = 32
    for y in range(0, size, step):
        for x in range(0, size, step):
            color = (214, 222, 222, 255) if (x // step + y // step) % 2 == 0 else (235, 240, 240, 255)
            draw.rectangle((x, y, x + step - 1, y + step - 1), fill=color)
    return image


def save_contact_sheet(output_paths: list[Path]) -> None:
    thumb_size = 384
    label_height = 28
    columns = 4
    rows = 2
    sheet = Image.new("RGBA", (columns * thumb_size, rows * (thumb_size + label_height)), (235, 235, 235, 255))
    draw = ImageDraw.Draw(sheet)
    checker = make_checker(CANVAS_SIZE)

    for index, path in enumerate(output_paths):
        cell = checker.copy()
        cell.alpha_composite(Image.open(path).convert("RGBA"))
        cell = cell.resize((thumb_size, thumb_size), Image.Resampling.LANCZOS)
        x = (index % columns) * thumb_size
        y = (index // columns) * (thumb_size + label_height)
        sheet.alpha_composite(cell, (x, y))
        draw.text((x + 8, y + thumb_size + 6), path.stem, fill=(20, 20, 20, 255))

    sheet.save(OUTPUT_DIR / "prototype_v2_contact_sheet.png")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    adjustments = load_adjustments()
    target_head_width = float(adjustments.get("target_head_width", DEFAULT_TARGET_HEAD_WIDTH))
    global_scale = float(adjustments.get("global_scale", 1.0))
    output_paths: list[Path] = []

    for output_name, (source_name, head_bbox) in SOURCE_SPECS.items():
        adjustment = get_direction_adjustment(adjustments, output_name)
        scale_multiplier = global_scale * float(adjustment.get("scale", 1.0))
        offset = get_offset(adjustment)
        source_path = SOURCE_DIR / source_name
        image, foreground_bbox = make_rgba_source(source_path)
        sprite, scale, frame_margin = paste_normalized_sprite(
            image,
            foreground_bbox,
            head_bbox,
            target_head_width,
            scale_multiplier,
            offset,
        )
        output_path = OUTPUT_DIR / f"{output_name}.png"
        sprite.save(output_path)
        output_paths.append(output_path)

        head_width = (head_bbox[2] - head_bbox[0]) * scale
        warning = " WARNING: frame edge overflow" if frame_margin < 0.0 else ""
        print(
            f"{output_name}: source={source_name} scale={scale:.3f} "
            f"head_width={head_width:.1f}px multiplier={scale_multiplier:.3f} "
            f"offset=({offset[0]:.0f},{offset[1]:.0f}) frame_margin={frame_margin:.1f}px{warning}"
        )

    save_contact_sheet(output_paths)
    print(f"saved {len(output_paths)} sprites to {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
