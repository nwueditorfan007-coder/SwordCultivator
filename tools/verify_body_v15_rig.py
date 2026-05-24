import os
import json
from pathlib import Path
from PIL import Image
import numpy as np

# Define paths
ROOT = Path(__file__).resolve().parents[1]
V15_DIR = ROOT / "resources/flight/rider/body_v15_ink_rig"
V15_PARTS_DIR = V15_DIR / "parts"
V15_SOURCE_DIR = V15_DIR / "source"

MANIFEST_PATH = V15_DIR / "body_v15_ink_rig_manifest.json"
POSE_LIB_PATH = V15_DIR / "body_v15_ink_pose_library.json"
SOCKET_LIB_PATH = V15_DIR / "body_v15_ink_socket_library.json"

CHROMA_COLOR = (233, 12, 224)  # Magenta RGB [233, 12, 224]

PART_NAMES = [
    "torso", "hair_back", "sash_back_root", "arm_back_upper", "arm_back_forearm_sleeve",
    "head", "pelvis_belt", "arm_front_upper", "leg_back", "robe_front",
    "arm_front_forearm_sleeve", "leg_front", "hand_front", "hand_back", "robe_back",
    "sash_back_mid", "sash_front_root", "sash_front_mid", "hair_tail", "sash_front_tip",
    "sash_back_tip"
]

def verify_rig():
    success = True
    print("==============================================================")
    print("Starting verification of V15 Character Rig Assets...")
    print("==============================================================")

    # 1. Verify existence of directories
    for d in [V15_PARTS_DIR, V15_SOURCE_DIR]:
        if not d.exists():
            print(f"[-] Error: Directory does not exist: {d}")
            success = False
        else:
            print(f"[+] Found directory: {d.name}")

    # 2. Verify existence of JSON libraries
    for p in [MANIFEST_PATH, POSE_LIB_PATH, SOCKET_LIB_PATH]:
        if not p.exists():
            print(f"[-] Error: JSON file does not exist: {p}")
            success = False
        else:
            print(f"[+] Found JSON config: {p.name}")

    if not success:
        return False

    # 3. Read and parse Manifest JSON
    print("\n>>> Validating body_v15_ink_rig_manifest.json ...")
    try:
        with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
            manifest = json.load(f)
        print("[+] Manifest loaded as valid JSON.")
    except Exception as e:
        print(f"[-] Error: Failed to parse manifest JSON: {e}")
        return False

    # Check top-level keys
    required_manifest_keys = ["source", "source_size", "padding", "parts"]
    for k in required_manifest_keys:
        if k not in manifest:
            print(f"[-] Error: Missing key '{k}' in manifest.")
            success = False
        else:
            print(f"[+] Manifest key '{k}' present.")

    if not success:
        return False

    # Check source images existence and metadata
    exploded_clean_path = V15_DIR / manifest["source"]
    exploded_chroma_path = V15_SOURCE_DIR / "body_v15_ink_exploded_parts_clean_chroma.png"
    exploded_alpha_path = V15_SOURCE_DIR / "body_v15_ink_exploded_parts_clean_alpha_raw.png"
    pivot_guide_path = V15_SOURCE_DIR / "body_v15_ink_pivot_guide.png"

    for img_path in [exploded_clean_path, exploded_chroma_path, exploded_alpha_path, pivot_guide_path]:
        if not img_path.exists():
            print(f"[-] Error: Exploded sheet not found at {img_path}")
            success = False
        else:
            try:
                img = Image.open(img_path)
                if img.size != (2048, 2048):
                    print(f"[-] Error: {img_path.name} size is {img.size}, expected (2048, 2048)")
                    success = False
                else:
                    print(f"[+] {img_path.name} loaded successfully (2048 x 2048, mode={img.mode})")
            except Exception as e:
                print(f"[-] Error: Failed to open sheet {img_path.name}: {e}")
                success = False

    # 4. Verify all 21 parts
    print("\n>>> Validating 21 Cut-out Parts & Geometry Specs ...")
    manifest_parts = manifest["parts"]

    # Check count
    if len(manifest_parts) != len(PART_NAMES):
        print(f"[-] Warning/Error: Manifest contains {len(manifest_parts)} parts, expected exactly {len(PART_NAMES)}")
        success = False

    for name in PART_NAMES:
        if name not in manifest_parts:
            print(f"[-] Error: Part '{name}' is missing in manifest!")
            success = False
            continue

        part_data = manifest_parts[name]

        # Check standard properties
        for key in ["file", "size", "pivot", "source_bbox"]:
            if key not in part_data:
                print(f"[-] Error: Part '{name}' is missing property '{key}'")
                success = False

        if not success:
            continue

        part_file_rel = part_data["file"]
        part_file_abs = V15_DIR / part_file_rel

        # Check file existence
        if not part_file_abs.exists():
            print(f"[-] Error: Physical part image not found: {part_file_rel}")
            success = False
            continue

        # Check PIL Image properties
        try:
            part_img = Image.open(part_file_abs)

            # Check size matches actual image
            expected_size = part_data["size"] # [width, height]
            actual_size = list(part_img.size)
            if expected_size != actual_size:
                print(f"[-] Error: Part '{name}' manifest size {expected_size} doesn't match actual image size {actual_size}")
                success = False

            # Check bbox dimensions
            bbox = part_data["source_bbox"] # [x0, y0, x1, y1]
            if len(bbox) != 4:
                print(f"[-] Error: Part '{name}' source_bbox must have 4 coordinates")
                success = False
            else:
                x0, y0, x1, y1 = bbox
                w = x1 - x0
                h = y1 - y0
                if w != actual_size[0] or h != actual_size[1]:
                    print(f"[-] Error: Part '{name}' bbox dimensions ({w}x{h}) do not match actual image size {actual_size}")
                    success = False

                # Check bounding coordinates limits
                if x0 < 0 or y0 < 0 or x1 > 2048 or y1 > 2048:
                    print(f"[-] Error: Part '{name}' bbox coordinates {bbox} exceed 2048x2048 canvas boundary")
                    success = False

            # Check pivot coordinates range (must be reasonably within or near bounds)
            px, py = part_data["pivot"]
            if px < 0 or px > actual_size[0] or py < 0 or py > actual_size[1]:
                print(f"[!] Warning: Part '{name}' pivot [{px}, {py}] lies outside the local image size {actual_size}")

            # Check Hand Front Cold Glow Outline Stylization
            if name == "hand_front":
                arr = np.array(part_img)
                # Ensure it has high-brightness pixels indicating white/light-cyan outline
                rgb = arr[:, :, :3]
                alpha = arr[:, :, 3]
                bright_pixels = (rgb[:, :, 0] > 200) & (rgb[:, :, 1] > 200) & (rgb[:, :, 2] > 200) & (alpha > 0)
                bright_count = np.sum(bright_pixels)
                if bright_count == 0:
                    print("[-] Error: hand_front does not contain hand intention glow (bright white/pale-cyan pixels)")
                    success = False
                else:
                    print(f"[+] hand_front contains {bright_count} high-brightness glow contour pixels.")

            # Check general ink dark silhouette range (RGB base values should be dark)
            if name != "hand_front":
                arr = np.array(part_img)
                alpha = arr[:, :, 3]
                rgb = arr[:, :, :3]
                # Exclude fully transparent pixels
                opaque_rgb = rgb[alpha > 50]
                if len(opaque_rgb) > 0:
                    max_rgb_val = np.max(opaque_rgb)
                    if max_rgb_val > 50:
                        # Some edge anti-aliasing pixels might be slightly higher, but main body should be dark
                        mean_rgb_val = np.mean(opaque_rgb)
                        if mean_rgb_val > 25:
                            print(f"[-] Error: Part '{name}' has average opaque color values {mean_rgb_val} which is too bright for dark ink silhouette")
                            success = False

        except Exception as e:
            print(f"[-] Error: Exception verifying image for {name}: {e}")
            success = False

    # 5. Check Pose Library
    print("\n>>> Validating body_v15_ink_pose_library.json ...")
    try:
        with open(POSE_LIB_PATH, "r", encoding="utf-8") as f:
            pose_data = json.load(f)
        print("[+] Pose library parsed successfully.")
        required_pose_names = [
            "idle",
            "move_forward",
            "move_back",
            "high_speed_crouch",
            "turn_lean_left",
            "turn_lean_right",
            "sword_control_idle",
            "sword_control_commit",
            "sword_return_catch",
            "array_ring_idle",
            "array_fan_idle",
            "array_pierce_idle",
            "array_hold",
        ]
        poses = pose_data.get("poses", {})
        for p_name in required_pose_names:
            if p_name not in poses:
                print(f"[-] Error: Pose library missing required pose '{p_name}'")
                success = False
                continue
            missing_parts = [name for name in PART_NAMES if name not in poses[p_name]]
            if missing_parts:
                print(f"[-] Error: Pose '{p_name}' missing parts: {missing_parts}")
                success = False
    except Exception as e:
        print(f"[-] Error: Failed to parse pose library: {e}")
        success = False

    # 6. Check Socket Library
    print("\n>>> Validating body_v15_ink_socket_library.json ...")
    try:
        with open(SOCKET_LIB_PATH, "r", encoding="utf-8") as f:
            socket_data = json.load(f)
        print("[+] Socket library parsed successfully.")

        # Verify required keys in Socket Library
        required_socket_keys = ["format_version", "coordinate_system", "poses", "sequences"]
        for k in required_socket_keys:
            if k not in socket_data:
                print(f"[-] Error: Socket library missing key '{k}'")
                success = False

        # Validate essential poses
        required_socket_pose_names = [
            "idle",
            "move_forward",
            "move_back",
            "high_speed_crouch",
            "turn_lean_left",
            "turn_lean_right",
            "sword_control_idle",
            "sword_control_commit",
            "sword_return_catch",
            "array_ring_idle",
            "array_fan_idle",
            "array_pierce_idle",
            "array_hold",
        ]
        for p_name in required_socket_pose_names:
            if p_name not in socket_data["poses"]:
                print(f"[-] Error: Socket library missing required pose '{p_name}'")
                success = False
            else:
                p_joints = socket_data["poses"][p_name]
                required_joints = ["root", "chest", "head", "hand_front", "hand_back", "hilt", "aim_forward"]
                for j in required_joints:
                    if j not in p_joints:
                        print(f"[-] Error: Socket pose '{p_name}' missing joint coordinate '{j}'")
                        success = False

        # Validate P0 sequences
        required_sequences = {
            "array_ring_release_12": 12,
            "array_fan_release_12": 12,
            "array_pierce_release_12": 12,
            "array_ring_to_fan_12": 12,
            "sword_return_catch_8": 8,
        }
        for seq_name, expected_len in required_sequences.items():
            if seq_name not in socket_data["sequences"]:
                print(f"[-] Error: Socket library missing '{seq_name}' sequence")
                success = False
                continue
            seq = socket_data["sequences"][seq_name]
            if len(seq) != expected_len:
                print(f"[-] Error: Sequence '{seq_name}' length is {len(seq)}, expected {expected_len}")
                success = False

    except Exception as e:
        print(f"[-] Error: Failed to parse socket library: {e}")
        success = False

    print("\n==============================================================")
    if success:
        print("[SUCCESS] V15 Ink Rig structure verified: parts, manifest, P0 pose keys, and socket keys are present.")
        print("[NOTE] This does not certify final hidden-side repaint quality or in-engine pose tuning.")
        print("==============================================================")
        return True
    else:
        print("[FAILURE] One or more verification checks failed.")
        print("==============================================================")
        return False

if __name__ == "__main__":
    verify_rig()
