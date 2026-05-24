"""Generate V15 visible-shape rig parts from the locked ink master image.

This is an intentionally conservative bridge step for V15:

- Keep visual identity locked to ``body_v15_ink_master_full.png``.
- Extract only visible pixels from the master instead of asking image generation
  to invent a new exploded-parts sheet.
- Produce the 21 V14-compatible part names, a manifest, and a pivot guide.

The output is not the final hidden-side repaint. Some pieces are visibly partial
because they were occluded in the master pose. That is preferable to a drifting
character design while we establish pivots, naming, and loader compatibility.
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
RIG_DIR = ROOT / "resources/flight/rider/body_v15_ink_rig"
SOURCE_DIR = RIG_DIR / "source"
PARTS_DIR = RIG_DIR / "parts"

MASTER = SOURCE_DIR / "body_v15_ink_master_full.png"
EXPLODED = SOURCE_DIR / "body_v15_ink_exploded_parts_clean.png"
EXPLODED_CHROMA = SOURCE_DIR / "body_v15_ink_exploded_parts_clean_chroma.png"
EXPLODED_ALPHA = SOURCE_DIR / "body_v15_ink_exploded_parts_clean_alpha_raw.png"
PIVOT_GUIDE = SOURCE_DIR / "body_v15_ink_pivot_guide.png"
MANIFEST = RIG_DIR / "body_v15_ink_rig_manifest.json"

SHEET_SIZE = (2048, 2048)
PADDING = 4


# name, source box in the master image, polygon mask in master coordinates,
# max size on exploded sheet, anchor on exploded sheet, pivot normalized in part PNG
PARTS: list[dict] = [
    {
        "name": "torso",
        "box": (940, 315, 1285, 610),
        "poly": [(1078, 330), (1180, 332), (1280, 392), (1250, 585), (1125, 605), (1010, 560), (945, 475), (995, 385)],
        "erase": [
            [(960, 458), (1095, 450), (1168, 492), (1135, 550), (970, 535)],
            [(1085, 400), (1224, 426), (1212, 540), (1090, 536)],
        ],
        "max_size": (330, 300),
        "anchor": (90, 80),
        "pivot": (0.52, 0.22),
        "rgb_scale": 0.94,
        "status": "hidden_repaint_pass1",
        "note": "Visible torso includes the back-control forearm crossing the chest; final repaint should remove arm overlap.",
    },
    {
        "name": "hair_back",
        "box": (765, 115, 1230, 275),
        "poly": [(770, 150), (875, 125), (995, 185), (1115, 125), (1220, 150), (1168, 226), (1000, 250), (870, 205), (780, 190)],
        "max_size": (460, 180),
        "anchor": (815, 70),
        "pivot": (0.86, 0.38),
        "note": "Visible flowing rear hair strip from locked master.",
    },
    {
        "name": "hair_tail",
        "box": (570, 215, 1115, 320),
        "poly": [(575, 285), (680, 225), (820, 235), (950, 275), (1110, 292), (980, 312), (810, 285), (650, 300)],
        "max_size": (560, 125),
        "anchor": (1395, 90),
        "pivot": (0.92, 0.42),
        "note": "Long trailing hair/sash-like visible strip; final art may split from hair_back root more cleanly.",
    },
    {
        "name": "sash_back_root",
        "box": (990, 535, 1135, 620),
        "poly": [(1045, 535), (1128, 552), (1110, 610), (1000, 604), (1020, 565)],
        "max_size": (170, 110),
        "anchor": (445, 438),
        "pivot": (0.72, 0.32),
        "note": "Root knot/short visible sash fragment near pelvis.",
    },
    {
        "name": "sash_back_mid",
        "box": (510, 555, 1060, 665),
        "poly": [(510, 605), (675, 560), (865, 580), (1060, 600), (1000, 640), (810, 640), (650, 615), (520, 630)],
        "max_size": (580, 130),
        "anchor": (760, 430),
        "pivot": (0.85, 0.36),
        "note": "Long visible back sash middle strip.",
    },
    {
        "name": "sash_back_tip",
        "box": (250, 515, 635, 635),
        "poly": [(255, 535), (410, 560), (540, 510), (630, 535), (520, 620), (360, 615)],
        "max_size": (390, 140),
        "anchor": (1485, 430),
        "pivot": (0.82, 0.40),
        "note": "Visible far trailing sash tip.",
    },
    {
        "name": "arm_back_upper",
        "box": (770, 430, 1055, 555),
        "poly": [(790, 485), (900, 425), (1038, 445), (1015, 535), (895, 560), (785, 530)],
        "max_size": (320, 150),
        "anchor": (80, 710),
        "pivot": (0.78, 0.26),
        "note": "Back arm sleeve/upper visible sweep; final repaint should separate upper arm from sleeve volume.",
    },
    {
        "name": "arm_back_forearm_sleeve",
        "box": (980, 445, 1165, 555),
        "poly": [(990, 490), (1090, 455), (1162, 485), (1132, 542), (1018, 528)],
        "max_size": (220, 130),
        "anchor": (450, 710),
        "pivot": (0.30, 0.42),
        "note": "Back control forearm/sleeve visible crossing torso.",
    },
    {
        "name": "hand_back",
        "box": (1088, 410, 1218, 535),
        "poly": [(1105, 455), (1145, 420), (1212, 455), (1195, 520), (1125, 528), (1088, 492)],
        "max_size": (160, 150),
        "anchor": (785, 710),
        "pivot": (0.26, 0.68),
        "note": "Back two-finger control hand; strongest operational anchor.",
    },
    {
        "name": "head",
        "box": (1145, 145, 1375, 365),
        "poly": [(1200, 175), (1298, 160), (1362, 225), (1335, 323), (1275, 355), (1188, 325), (1152, 245)],
        "max_size": (250, 250),
        "anchor": (470, 70),
        "pivot": (0.52, 0.86),
        "note": "Head profile from locked master.",
    },
    {
        "name": "pelvis_belt",
        "box": (1015, 530, 1215, 625),
        "poly": [(1035, 555), (1125, 535), (1210, 570), (1188, 615), (1068, 612), (1018, 585)],
        "max_size": (260, 110),
        "anchor": (100, 440),
        "pivot": (0.50, 0.42),
        "note": "Visible belt and knot from master.",
    },
    {
        "name": "leg_back",
        "box": (665, 720, 900, 980),
        "poly": [(690, 820), (785, 720), (900, 810), (840, 930), (700, 970), (665, 900)],
        "max_size": (250, 280),
        "anchor": (90, 1045),
        "pivot": (0.62, 0.18),
        "status": "hidden_repaint_pass1",
        "note": "Back leg is partially occluded and includes sword/foot contact; needs final cleanup before production rig.",
    },
    {
        "name": "robe_back",
        "box": (495, 625, 980, 790),
        "poly": [(500, 780), (600, 690), (795, 625), (980, 670), (875, 775), (705, 785), (600, 730)],
        "max_size": (500, 180),
        "anchor": (455, 1045),
        "pivot": (0.84, 0.24),
        "status": "hidden_repaint_pass1",
        "note": "Visible back robe flap.",
    },
    {
        "name": "arm_front_upper",
        "box": (1225, 382, 1510, 505),
        "poly": [(1230, 392), (1390, 400), (1505, 422), (1440, 505), (1280, 480)],
        "max_size": (320, 150),
        "anchor": (1120, 710),
        "pivot": (0.18, 0.36),
        "note": "Front pointing upper arm/sleeve from master.",
    },
    {
        "name": "arm_front_forearm_sleeve",
        "box": (1450, 405, 1600, 470),
        "poly": [(1455, 420), (1545, 405), (1598, 425), (1585, 462), (1488, 470)],
        "max_size": (190, 90),
        "anchor": (1510, 720),
        "pivot": (0.18, 0.54),
        "note": "Front forearm sleeve from pointing arm.",
    },
    {
        "name": "hand_front",
        "box": (1560, 405, 1695, 462),
        "poly": [(1565, 418), (1655, 405), (1694, 420), (1678, 454), (1580, 462)],
        "max_size": (170, 80),
        "anchor": (1765, 725),
        "pivot": (0.18, 0.52),
        "note": "Front pointing hand; strongest aim_forward anchor.",
    },
    {
        "name": "leg_front",
        "box": (1175, 590, 1385, 880),
        "poly": [(1205, 720), (1270, 595), (1375, 625), (1370, 790), (1288, 875), (1180, 830)],
        "max_size": (250, 300),
        "anchor": (1040, 1025),
        "pivot": (0.42, 0.16),
        "status": "hidden_repaint_pass1",
        "note": "Front crouched leg from master.",
    },
    {
        "name": "robe_front",
        "box": (955, 565, 1200, 850),
        "poly": [(1085, 565), (1190, 625), (1180, 760), (1010, 850), (955, 735), (1030, 620)],
        "max_size": (270, 320),
        "anchor": (1405, 1015),
        "pivot": (0.54, 0.18),
        "status": "hidden_repaint_pass1",
        "note": "Front robe flap, visible lower body mass.",
    },
    {
        "name": "sash_front_root",
        "box": (1018, 545, 1142, 626),
        "poly": [(1040, 545), (1138, 565), (1120, 620), (1025, 610)],
        "max_size": (160, 100),
        "anchor": (85, 1510),
        "pivot": (0.62, 0.30),
        "note": "Front sash root visible near belt.",
    },
    {
        "name": "sash_front_mid",
        "box": (490, 585, 1010, 720),
        "poly": [(490, 620), (640, 595), (830, 625), (1010, 615), (900, 690), (700, 715), (540, 670)],
        "max_size": (540, 150),
        "anchor": (480, 1510),
        "pivot": (0.86, 0.34),
        "note": "Front sash middle strip.",
    },
    {
        "name": "sash_front_tip",
        "box": (250, 528, 610, 632),
        "poly": [(250, 540), (395, 565), (510, 530), (610, 555), (505, 630), (340, 620)],
        "max_size": (370, 125),
        "anchor": (1230, 1515),
        "pivot": (0.84, 0.42),
        "note": "Front sash tip from far trailing strip.",
    },
]


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("empty alpha bbox")
    return bbox


def threshold_tiny_alpha(image: Image.Image) -> None:
    pixels = image.load()
    width, height = image.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a < 18:
                pixels[x, y] = (0, 0, 0, 0)


def cut_from_master(master: Image.Image, spec: dict) -> Image.Image:
    box = spec["box"]
    crop = master.crop(box)
    mask = Image.new("L", crop.size, 0)
    shifted = [(x - box[0], y - box[1]) for x, y in spec["poly"]]
    ImageDraw.Draw(mask).polygon(shifted, fill=255)
    for erase_poly in spec.get("erase", []):
        shifted_erase = [(x - box[0], y - box[1]) for x, y in erase_poly]
        ImageDraw.Draw(mask).polygon(shifted_erase, fill=0)
    mask = ImageChops.multiply(mask, crop.getchannel("A"))
    crop.putalpha(mask)
    threshold_tiny_alpha(crop)
    bbox = alpha_bbox(crop)
    return crop.crop(bbox)


def make_alpha_raw(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    return Image.merge("RGBA", (alpha, alpha, alpha, alpha))


def scale_rgb(image: Image.Image, factor: float) -> Image.Image:
    if factor == 1.0:
        return image
    r, g, b, a = image.split()
    table = [max(0, min(255, round(i * factor))) for i in range(256)]
    return Image.merge("RGBA", (r.point(table), g.point(table), b.point(table), a))


def draw_antialiased_polygon(
    layer: Image.Image,
    points: list[tuple[float, float]],
    fill: tuple[int, int, int, int],
    *,
    outline: tuple[int, int, int, int] | None = None,
    width: int = 1,
    scale: int = 4,
) -> None:
    large = Image.new("RGBA", (layer.width * scale, layer.height * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(large)
    scaled_points = [(round(x * scale), round(y * scale)) for x, y in points]
    draw.polygon(scaled_points, fill=fill)
    if outline is not None:
        draw.line(scaled_points + [scaled_points[0]], fill=outline, width=max(1, width * scale), joint="curve")
    layer.alpha_composite(large.resize(layer.size, Image.Resampling.LANCZOS))


def draw_antialiased_line(
    layer: Image.Image,
    points: list[tuple[float, float]],
    fill: tuple[int, int, int, int],
    *,
    width: int = 1,
    scale: int = 4,
) -> None:
    large = Image.new("RGBA", (layer.width * scale, layer.height * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(large)
    scaled_points = [(round(x * scale), round(y * scale)) for x, y in points]
    draw.line(scaled_points, fill=fill, width=max(1, width * scale), joint="curve")
    layer.alpha_composite(large.resize(layer.size, Image.Resampling.LANCZOS))


def erase_antialiased_polygon(
    image: Image.Image,
    points: list[tuple[float, float]],
    *,
    scale: int = 4,
) -> None:
    mask = Image.new("L", (image.width * scale, image.height * scale), 0)
    draw = ImageDraw.Draw(mask)
    scaled_points = [(round(x * scale), round(y * scale)) for x, y in points]
    draw.polygon(scaled_points, fill=255)
    mask = mask.resize(image.size, Image.Resampling.LANCZOS)
    pixels = image.load()
    mask_pixels = mask.load()
    for y in range(image.height):
        for x in range(image.width):
            m = mask_pixels[x, y]
            if m == 0:
                continue
            r, g, b, a = pixels[x, y]
            new_alpha = max(0, round(a * (1.0 - m / 255.0)))
            pixels[x, y] = (r, g, b, new_alpha)


def composite_repair_under(image: Image.Image, repair: Image.Image) -> Image.Image:
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    out.alpha_composite(repair)
    out.alpha_composite(image)
    return out


def repair_torso(image: Image.Image) -> Image.Image:
    repair = Image.new("RGBA", image.size, (0, 0, 0, 0))
    # Hidden chest/abdomen cloth behind the erased control arm.
    draw_antialiased_polygon(
        repair,
        [(54, 88), (137, 54), (292, 84), (282, 212), (175, 238), (74, 214), (38, 150)],
        (13, 13, 13, 245),
        outline=(30, 45, 48, 150),
        width=1,
    )
    draw_antialiased_polygon(
        repair,
        [(137, 55), (201, 78), (160, 231), (111, 222), (128, 130)],
        (19, 19, 18, 210),
    )
    draw_antialiased_polygon(
        repair,
        [(207, 78), (286, 92), (275, 207), (200, 222), (174, 155)],
        (16, 16, 15, 215),
    )
    # Keep the robe construction readable without turning torso into a bright-line part.
    draw_antialiased_line(repair, [(142, 60), (198, 150), (172, 226)], (86, 108, 112, 135), width=1)
    draw_antialiased_line(repair, [(222, 67), (197, 145), (220, 214)], (78, 100, 104, 120), width=1)
    draw_antialiased_line(repair, [(72, 217), (178, 226), (276, 210)], (84, 103, 105, 130), width=1)
    return composite_repair_under(image, repair)


def repair_leg_back(image: Image.Image) -> Image.Image:
    # Remove foot-contact remnants from the riding sword. Preserve the boot and ankle.
    erase_antialiased_polygon(image, [(0, 221), (250, 203), (250, 263), (0, 263)])
    erase_antialiased_polygon(image, [(110, 199), (250, 188), (250, 230), (120, 230)])
    erase_antialiased_polygon(image, [(0, 202), (70, 195), (58, 225), (0, 230)])
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            brightness = max(r, g, b)
            if (x > 116 and y > 197 and brightness > 34) or (x > 112 and y > 221):
                pixels[x, y] = (r, g, b, 0)
    repair = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw_antialiased_polygon(
        repair,
        [(44, 179), (93, 165), (139, 180), (132, 219), (92, 234), (49, 224), (30, 205)],
        (8, 8, 8, 240),
        outline=(62, 82, 86, 150),
        width=1,
    )
    draw_antialiased_line(repair, [(45, 221), (102, 228), (137, 214)], (72, 92, 96, 110), width=1)
    out = composite_repair_under(image, repair)
    pixels = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            brightness = max(r, g, b)
            if x > 132 and y > 186:
                pixels[x, y] = (r, g, b, 0)
            elif x > 92 and y > 205 and brightness > 30:
                pixels[x, y] = (r, g, b, 0)
    return out


def repair_robe_back(image: Image.Image) -> Image.Image:
    repair = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw_antialiased_polygon(
        repair,
        [(0, 122), (124, 48), (319, 10), (500, 31), (468, 118), (280, 156), (88, 156)],
        (13, 13, 13, 225),
        outline=(60, 81, 86, 120),
        width=1,
    )
    draw_antialiased_polygon(
        repair,
        [(120, 72), (314, 26), (472, 44), (355, 135), (174, 150)],
        (20, 20, 19, 175),
    )
    draw_antialiased_line(repair, [(94, 134), (260, 82), (448, 40)], (74, 92, 96, 130), width=1)
    return composite_repair_under(image, repair)


def repair_robe_front(image: Image.Image) -> Image.Image:
    repair = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw_antialiased_polygon(
        repair,
        [(72, 18), (160, 0), (251, 34), (270, 176), (222, 307), (80, 320), (0, 286), (17, 128)],
        (13, 13, 13, 235),
        outline=(65, 84, 88, 120),
        width=1,
    )
    draw_antialiased_polygon(
        repair,
        [(95, 30), (172, 5), (224, 64), (176, 300), (62, 310), (44, 150)],
        (23, 23, 22, 155),
    )
    draw_antialiased_line(repair, [(112, 18), (92, 112), (54, 292)], (82, 101, 106, 125), width=1)
    draw_antialiased_line(repair, [(172, 10), (218, 106), (230, 260)], (73, 91, 96, 110), width=1)
    return composite_repair_under(image, repair)


def repair_leg_front(image: Image.Image) -> Image.Image:
    repair = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw_antialiased_polygon(
        repair,
        [(40, 7), (138, 6), (196, 70), (177, 194), (112, 294), (33, 276), (0, 178), (18, 64)],
        (11, 11, 11, 200),
        outline=(56, 75, 80, 110),
        width=1,
    )
    return composite_repair_under(image, repair)


def repair_part(name: str, image: Image.Image) -> Image.Image:
    if name == "torso":
        return repair_torso(image)
    if name == "leg_back":
        return repair_leg_back(image)
    if name == "robe_back":
        return repair_robe_back(image)
    if name == "robe_front":
        return repair_robe_front(image)
    if name == "leg_front":
        return repair_leg_front(image)
    return image


def normalize_dark_ink_mean(image: Image.Image, target_mean: float = 23.5) -> Image.Image:
    pixels = image.load()
    total = 0.0
    count = 0
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a > 50:
                total += (r + g + b) / 3.0
                count += 1
    if count == 0:
        return image
    mean = total / count
    if mean <= target_mean:
        return image
    return scale_rgb(image, target_mean / mean)


def main() -> None:
    master = Image.open(MASTER).convert("RGBA")
    PARTS_DIR.mkdir(parents=True, exist_ok=True)

    sheet = Image.new("RGBA", SHEET_SIZE, (0, 0, 0, 0))
    placed: list[dict] = []

    for spec in PARTS:
        part = cut_from_master(master, spec)
        scale = min(
            spec["max_size"][0] / part.width,
            spec["max_size"][1] / part.height,
            1.4,
        )
        if scale != 1.0:
            part = part.resize(
                (max(1, round(part.width * scale)), max(1, round(part.height * scale))),
                Image.Resampling.LANCZOS,
            )
            threshold_tiny_alpha(part)
        part = scale_rgb(part, float(spec.get("rgb_scale", 1.0)))
        part = repair_part(spec["name"], part)
        threshold_tiny_alpha(part)
        if spec["name"] != "hand_front":
            part = normalize_dark_ink_mean(part)
        anchor_x, anchor_y = spec["anchor"]
        sheet.alpha_composite(part, (anchor_x, anchor_y))
        placed.append(
            {
                **spec,
                "placed_size": part.size,
                "placed_bbox": [anchor_x, anchor_y, anchor_x + part.width, anchor_y + part.height],
            }
        )

    sheet.save(EXPLODED)
    chroma = Image.new("RGBA", SHEET_SIZE, (0, 255, 0, 255))
    chroma.alpha_composite(sheet)
    chroma.convert("RGB").save(EXPLODED_CHROMA)
    make_alpha_raw(sheet).save(EXPLODED_ALPHA)

    manifest: dict = {
        "source": "source/body_v15_ink_exploded_parts_clean.png",
        "source_size": list(SHEET_SIZE),
        "padding": PADDING,
        "notes": [
            "Visible-shape extraction from body_v15_ink_master_full.png.",
            "Some parts are partial where the locked master pose occludes hidden geometry.",
            "Use this as the style-locked calibration pass before hidden-side repainting.",
        ],
        "parts": {},
    }

    pivot_guide_image = Image.new("RGBA", SHEET_SIZE, (24, 24, 24, 255))
    pivot_guide_image.alpha_composite(sheet)
    draw = ImageDraw.Draw(pivot_guide_image)
    notes: dict[str, str] = {}

    for spec in placed:
        x0, y0, x1, y1 = spec["placed_bbox"]
        padded_bbox = [
            max(0, x0 - PADDING),
            max(0, y0 - PADDING),
            min(SHEET_SIZE[0], x1 + PADDING),
            min(SHEET_SIZE[1], y1 + PADDING),
        ]
        crop = sheet.crop(tuple(padded_bbox))
        part_bbox = alpha_bbox(crop)
        crop = crop.crop(part_bbox)
        threshold_tiny_alpha(crop)

        part_path = PARTS_DIR / f"{spec['name']}.png"
        crop.save(part_path)

        w, h = crop.size
        source_bbox = [
            padded_bbox[0] + part_bbox[0],
            padded_bbox[1] + part_bbox[1],
            padded_bbox[0] + part_bbox[2],
            padded_bbox[1] + part_bbox[3],
        ]
        # Pivot is relative to the saved crop, not the unpadded placed region.
        unpadded_w, unpadded_h = spec["placed_size"]
        pivot_unpadded = (spec["pivot"][0] * unpadded_w, spec["pivot"][1] * unpadded_h)
        pivot_x = pivot_unpadded[0] + (x0 - padded_bbox[0]) - part_bbox[0]
        pivot_y = pivot_unpadded[1] + (y0 - padded_bbox[1]) - part_bbox[1]
        pivot_x = max(0.0, min(float(w), float(pivot_x)))
        pivot_y = max(0.0, min(float(h), float(pivot_y)))

        manifest["parts"][spec["name"]] = {
            "file": f"parts/{spec['name']}.png",
            "size": [w, h],
            "pivot": [round(pivot_x, 1), round(pivot_y, 1)],
            "source_bbox": source_bbox,
            "status": spec.get("status", "visible_extract_needs_hidden_repaint"),
        }
        notes[spec["name"]] = spec["note"]

        pivot_sheet_x = source_bbox[0] + part_bbox[0] + pivot_x
        pivot_sheet_y = source_bbox[1] + part_bbox[1] + pivot_y
        draw.rectangle(source_bbox, outline=(80, 160, 255, 220), width=2)
        draw.line((pivot_sheet_x - 12, pivot_sheet_y, pivot_sheet_x + 12, pivot_sheet_y), fill=(255, 60, 60, 255), width=2)
        draw.line((pivot_sheet_x, pivot_sheet_y - 12, pivot_sheet_x, pivot_sheet_y + 12), fill=(255, 60, 60, 255), width=2)
        draw.ellipse((pivot_sheet_x - 4, pivot_sheet_y - 4, pivot_sheet_x + 4, pivot_sheet_y + 4), fill=(255, 230, 60, 255))
        draw.text((source_bbox[0], max(0, source_bbox[1] - 16)), spec["name"], fill=(255, 255, 255, 255))

    pivot_guide_image.save(PIVOT_GUIDE)
    MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    (SOURCE_DIR / "body_v15_ink_visible_extract_notes.json").write_text(
        json.dumps(notes, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    print(f"wrote {EXPLODED}")
    print(f"wrote {len(PARTS)} parts to {PARTS_DIR}")
    print(f"wrote {MANIFEST}")
    print(f"wrote {PIVOT_GUIDE}")


if __name__ == "__main__":
    main()
