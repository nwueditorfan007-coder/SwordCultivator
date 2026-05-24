from __future__ import annotations

from math import sqrt
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = PROJECT_ROOT / "resources" / "flight" / "yujian_8way_cruise_generated_v1" / "accepted"
OUTPUT_DIR = PROJECT_ROOT / "resources" / "flight" / "yujian_8way_cruise_generated_v1" / "prototype_v3_face"

CANVAS_SIZE = 768
SAFE_MARGIN = 24
TARGET_FACE_GEOM = 66.0

SOURCE_SPECS = {
    "01_right": ("01_right.png", (948, 228, 1048, 350)),
    "02_up_right": ("02_up_right.png", (705, 270, 785, 365)),
    "03_up": ("03_up.png", (590, 388, 690, 495)),
    "04_up_left": ("04_up_left_candidate_v1.png", (390, 195, 485, 300)),
    "05_left": ("05_left.png", (430, 232, 530, 338)),
    "06_down_left": ("06_down_left_candidate_v1.png", (425, 345, 518, 455)),
    "07_down": ("07_down.png", (578, 340, 672, 455)),
    "08_down_right": ("08_down_right.png", (698, 345, 790, 455)),
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


def paste_normalized_sprite(
    image: Image.Image,
    foreground_bbox: tuple[int, int, int, int],
    face_core_bbox: tuple[int, int, int, int],
) -> tuple[Image.Image, float]:
    foreground_width = foreground_bbox[2] - foreground_bbox[0]
    foreground_height = foreground_bbox[3] - foreground_bbox[1]
    face_width = face_core_bbox[2] - face_core_bbox[0]
    face_height = face_core_bbox[3] - face_core_bbox[1]
    face_geom = sqrt(max(float(face_width * face_height), 1.0))

    scale_by_face = TARGET_FACE_GEOM / face_geom
    scale_by_fit = min(
        (CANVAS_SIZE - SAFE_MARGIN * 2) / max(float(foreground_width), 1.0),
        (CANVAS_SIZE - SAFE_MARGIN * 2) / max(float(foreground_height), 1.0),
    )
    scale = min(scale_by_face, scale_by_fit)

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
        round(CANVAS_SIZE * 0.5 - foreground_center[0]),
        round(CANVAS_SIZE * 0.5 - foreground_center[1]),
    )

    canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(resized, paste_position)
    return canvas, scale


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

    sheet.save(OUTPUT_DIR / "prototype_v3_face_contact_sheet.png")


def alpha_edge_margin(image: Image.Image) -> int:
    bbox = image.getchannel("A").point(lambda value: 255 if value > 4 else 0).getbbox()
    if bbox == None:
        return -1
    return min(bbox[0], bbox[1], CANVAS_SIZE - bbox[2], CANVAS_SIZE - bbox[3])


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    output_paths: list[Path] = []

    for output_name, (source_name, face_core_bbox) in SOURCE_SPECS.items():
        source_path = SOURCE_DIR / source_name
        image, foreground_bbox = make_rgba_source(source_path)
        sprite, scale = paste_normalized_sprite(image, foreground_bbox, face_core_bbox)
        output_path = OUTPUT_DIR / f"{output_name}.png"
        sprite.save(output_path)
        output_paths.append(output_path)

        face_width = (face_core_bbox[2] - face_core_bbox[0]) * scale
        face_height = (face_core_bbox[3] - face_core_bbox[1]) * scale
        print(
            f"{output_name}: source={source_name} scale={scale:.3f} "
            f"face={face_width:.1f}x{face_height:.1f}px "
            f"face_geom={sqrt(face_width * face_height):.1f}px "
            f"edge={alpha_edge_margin(sprite)}px"
        )

    save_contact_sheet(output_paths)
    print(f"saved {len(output_paths)} sprites to {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
