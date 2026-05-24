import os
from pathlib import Path
from PIL import Image
import numpy as np

# Define paths
ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "resources/flight/rider/body_v15_ink_rig/source"

MASTER_PATH = OUTPUT_DIR / "body_v15_ink_master_full.png"
CHROMA_PATH = OUTPUT_DIR / "body_v15_ink_master_full_chroma.png"
ALPHA_PATH = OUTPUT_DIR / "body_v15_ink_master_full_alpha_raw.png"

CHROMA_COLOR = (233, 12, 224)  # RGB [233, 12, 224]

def verify():
    success = True
    print("Starting verification of V15 Character Master Assets...")

    # 1. Check existence
    for path in [MASTER_PATH, CHROMA_PATH, ALPHA_PATH]:
        if not path.exists():
            print(f"[-] Error: File not found at {path}")
            success = False
        else:
            print(f"[+] Found: {path.name}")

    if not success:
        return False

    # 2. Check dimensions of all files
    master = Image.open(MASTER_PATH)
    chroma = Image.open(CHROMA_PATH)
    alpha = Image.open(ALPHA_PATH)

    for img, name in [(master, "Master"), (chroma, "Chroma"), (alpha, "Alpha")]:
        if img.size != (512, 512):
            print(f"[-] Error: {name} size is {img.size}, expected (512, 512)")
            success = False
        else:
            print(f"[+] {name} size is correct: {img.size}")

    # 3. Check master formats
    if master.mode != "RGBA":
        print(f"[-] Error: Master image mode is {master.mode}, expected RGBA")
        success = False
    else:
        print("[+] Master mode is correct (RGBA)")

    if chroma.mode != "RGB":
        print(f"[-] Error: Chroma image mode is {chroma.mode}, expected RGB")
        success = False
    else:
        print("[+] Chroma mode is correct (RGB)")

    if alpha.mode not in ["L", "1"]:
        print(f"[-] Error: Alpha image mode is {alpha.mode}, expected L (grayscale)")
        success = False
    else:
        print("[+] Alpha mode is correct (L/Grayscale)")

    # 4. Verify bottom anchor at y=438
    master_arr = np.array(master)
    master_alpha = master_arr[:, :, 3]
    opaque_coords = np.argwhere(master_alpha > 0)

    if len(opaque_coords) == 0:
        print("[-] Error: Master image has no opaque pixels (fully transparent)")
        success = False
    else:
        y_min, x_min = opaque_coords.min(axis=0)
        y_max, x_max = opaque_coords.max(axis=0)
        height = y_max - y_min + 1
        print(f"[+] Character height in canvas: {height} pixels (spec: ~338)")
        print(f"[+] Character vertical span: y={y_min} to y={y_max}")
        if y_max != 438:
            print(f"[-] Error: Bottom-most pixel y-coordinate is {y_max}, expected 438")
            success = False
        else:
            print("[+] Alignment verified: Bottom-most pixel is exactly at y=438")

    # 5. Verify chroma key background color
    chroma_arr = np.array(chroma)
    # Check pixels where master is transparent
    transparent_mask = master_alpha == 0
    bg_pixels = chroma_arr[transparent_mask]

    if len(bg_pixels) > 0:
        incorrect_bg = np.any(bg_pixels != CHROMA_COLOR, axis=1)
        incorrect_count = np.sum(incorrect_bg)
        if incorrect_count > 0:
            print(f"[-] Error: Found {incorrect_count} background pixels in chroma image that do not match {CHROMA_COLOR}")
            success = False
        else:
            print(f"[+] Chroma background color verified: all transparent regions match exact RGB {CHROMA_COLOR}")
    else:
        print("[!] Warning: No fully transparent pixels found to verify background chroma color")

    # 6. Verify alpha raw mapping
    alpha_arr = np.array(alpha)
    if not np.array_equal(alpha_arr, master_alpha):
        diff_count = np.sum(alpha_arr != master_alpha)
        print(f"[-] Error: Alpha raw values differ from master transparent alpha at {diff_count} pixels")
        success = False
    else:
        print("[+] Alpha raw values match the master's transparency mask exactly")

    if success:
        print("\n[SUCCESS] All V15 Character Master Assets successfully verified and are 100% compliant with specifications!")
        return True
    else:
        print("\n[FAILURE] One or more verification checks failed.")
        return False

if __name__ == "__main__":
    verify()
