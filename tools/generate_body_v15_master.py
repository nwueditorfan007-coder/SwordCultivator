import os
from pathlib import Path
from PIL import Image
import numpy as np

# Define paths
ROOT = Path(__file__).resolve().parents[1]
INPUT_IMAGE = Path(r"C:\Users\A\.gemini\antigravity\brain\3fea88b2-1065-479f-bb40-0f67c28adcc0\media__1779296728443.jpg")
OUTPUT_DIR = ROOT / "resources/flight/rider/body_v15_ink_rig/source"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

MASTER_PATH = OUTPUT_DIR / "body_v15_ink_master_full.png"
CHROMA_PATH = OUTPUT_DIR / "body_v15_ink_master_full_chroma.png"
ALPHA_PATH = OUTPUT_DIR / "body_v15_ink_master_full_alpha_raw.png"

# Magenta Chroma color used in the project
CHROMA_COLOR = (233, 12, 224)  # RGB [233, 12, 224]

def main():
    print(f"Loading input image: {INPUT_IMAGE}")
    if not INPUT_IMAGE.exists():
        print(f"Error: Input image does not exist at {INPUT_IMAGE}")
        return

    # 1. Background removal using soft intensity mapping
    img = Image.open(INPUT_IMAGE).convert("RGB")
    arr = np.array(img)
    gray = np.mean(arr, axis=2)

    # Thresholds for ink-wash edge preservation
    t_low = 60.0
    t_high = 210.0

    alpha = np.zeros_like(gray, dtype=np.uint8)
    mask_opaque = gray <= t_low
    mask_trans = gray >= t_high
    mask_mid = (gray > t_low) & (gray < t_high)

    alpha[mask_opaque] = 255
    alpha[mask_trans] = 0
    alpha[mask_mid] = (255 * (t_high - gray[mask_mid]) / (t_high - t_low)).astype(np.uint8)

    # Construct RGBA
    rgba = np.zeros((img.size[1], img.size[0], 4), dtype=np.uint8)
    rgba[:, :, 0:3] = arr
    rgba[:, :, 3] = alpha
    rgba_img = Image.fromarray(rgba, "RGBA")

    # 2. Find bounding box to crop the character tightly
    coords = np.argwhere(alpha > 0)
    y_min, x_min = coords.min(axis=0)
    y_max, x_max = coords.max(axis=0)

    tight_w = x_max - x_min + 1
    tight_h = y_max - y_min + 1
    print(f"Tight bounding box: {tight_w}x{tight_h} at ({x_min},{y_min})")

    cropped = rgba_img.crop((x_min, y_min, x_max + 1, y_max + 1))

    # 3. Canvas fitting (512x512)
    # The character's height in the 512x512 canvas must be exactly 338 pixels.
    target_h = 338
    scale = target_h / tight_h
    target_w = int(round(tight_w * scale))
    print(f"Scaling to height {target_h} (width: {target_w}, scale: {scale:.4f})")

    # Resize using high-quality Lanzcos interpolation
    try:
        resample_filter = Image.Resampling.LANCZOS
    except AttributeError:
        # Fallback for older Pillow versions
        resample_filter = Image.ANTIALIAS

    resized_char = cropped.resize((target_w, target_h), resample_filter)

    # Create the 512x512 transparent canvas
    canvas_w, canvas_h = 512, 512
    master_canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))

    # Placement coordinates:
    # y_max (bottom-most opaque pixel) must be exactly at y=438
    # y_min = 438 - target_h + 1
    # x_center = 256
    paste_y = 438 - target_h + 1
    paste_x = 256 - target_w // 2

    # Paste onto canvas. Since target_w is 589 and canvas_w is 512, some parts of the
    # sashes and sword tip will naturally overflow outside the 512 width boundaries,
    # which is perfectly fine and expected for wide dynamic poses.
    master_canvas.alpha_composite(resized_char, (paste_x, paste_y))

    # 4. Save transparent master
    master_canvas.save(MASTER_PATH)
    print(f"Saved transparent master to {MASTER_PATH}")

    # 5. Create and save chroma version
    # The chroma image is RGB with CHROMA_COLOR as flat background
    chroma_canvas = Image.new("RGB", (canvas_w, canvas_h), CHROMA_COLOR)
    # Paste RGBA master onto chroma using master's alpha channel as mask
    chroma_canvas.paste(master_canvas, (0, 0), master_canvas)
    chroma_canvas.save(CHROMA_PATH)
    print(f"Saved chroma master to {CHROMA_PATH}")

    # 6. Create and save alpha raw version
    # The alpha raw image is a grayscale (L mode) image representing the alpha channel
    alpha_raw = master_canvas.split()[3]
    alpha_raw.save(ALPHA_PATH)
    print(f"Saved alpha raw to {ALPHA_PATH}")

    print("V15 Character Master Asset generation completed successfully!")

if __name__ == "__main__":
    main()
