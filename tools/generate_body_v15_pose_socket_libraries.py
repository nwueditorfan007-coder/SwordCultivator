"""Generate first-pass V15 ink rig pose and socket libraries.

These libraries are intentionally data-complete but art-placeholder quality.
They provide stable V14-compatible pose keys and socket keys so implementation
can load V15 while the hidden-side repaint and hand-tuned pose pass continue.
"""
from __future__ import annotations

from copy import deepcopy
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RIG_DIR = ROOT / "resources/flight/rider/body_v15_ink_rig"
MANIFEST = RIG_DIR / "body_v15_ink_rig_manifest.json"
POSE_OUT = RIG_DIR / "body_v15_ink_pose_library.json"
SOCKET_OUT = RIG_DIR / "body_v15_ink_socket_library.json"

PART_ORDER = [
    "torso",
    "hair_back",
    "hair_tail",
    "sash_back_root",
    "sash_back_mid",
    "sash_back_tip",
    "arm_back_upper",
    "arm_back_forearm_sleeve",
    "hand_back",
    "head",
    "pelvis_belt",
    "leg_back",
    "robe_back",
    "arm_front_upper",
    "arm_front_forearm_sleeve",
    "hand_front",
    "leg_front",
    "robe_front",
    "sash_front_root",
    "sash_front_mid",
    "sash_front_tip",
]

Z_ORDER = {
    "sash_back_tip": -11,
    "sash_back_mid": -10,
    "sash_back_root": -9,
    "hair_back": -8,
    "arm_back_upper": -7,
    "arm_back_forearm_sleeve": -6,
    "hand_back": -5,
    "leg_back": -4,
    "robe_back": -3,
    "torso": 0,
    "pelvis_belt": 1,
    "leg_front": 2,
    "robe_front": 3,
    "head": 4,
    "hair_tail": 5,
    "arm_front_upper": 6,
    "arm_front_forearm_sleeve": 7,
    "hand_front": 8,
    "sash_front_root": 9,
    "sash_front_mid": 10,
    "sash_front_tip": 11,
}

# Root is under the feet/flight baseline. Values are pre-scale pixels.
IDLE = {
    "torso": {"position": [20.0, -1010.0], "rotation_degrees": -4.0},
    "pelvis_belt": {"position": [0.0, -720.0], "rotation_degrees": -3.0},
    "head": {"position": [72.0, -1160.0], "rotation_degrees": -2.0},
    "hair_back": {"position": [-18.0, -1240.0], "rotation_degrees": -8.0},
    "hair_tail": {"position": [-210.0, -1100.0], "rotation_degrees": 2.0},
    "arm_back_upper": {"position": [-140.0, -850.0], "rotation_degrees": -14.0},
    "arm_back_forearm_sleeve": {"position": [-20.0, -860.0], "rotation_degrees": 8.0},
    "hand_back": {"position": [70.0, -850.0], "rotation_degrees": -8.0},
    "arm_front_upper": {"position": [155.0, -900.0], "rotation_degrees": 6.0},
    "arm_front_forearm_sleeve": {"position": [330.0, -885.0], "rotation_degrees": 2.0},
    "hand_front": {"position": [440.0, -880.0], "rotation_degrees": 0.0},
    "leg_back": {"position": [-135.0, -390.0], "rotation_degrees": 12.0},
    "leg_front": {"position": [145.0, -470.0], "rotation_degrees": -10.0},
    "robe_back": {"position": [-85.0, -620.0], "rotation_degrees": -8.0},
    "robe_front": {"position": [70.0, -650.0], "rotation_degrees": 4.0},
    "sash_back_root": {"position": [-60.0, -675.0], "rotation_degrees": 8.0},
    "sash_back_mid": {"position": [-260.0, -620.0], "rotation_degrees": 4.0},
    "sash_back_tip": {"position": [-520.0, -620.0], "rotation_degrees": 0.0},
    "sash_front_root": {"position": [-30.0, -660.0], "rotation_degrees": -4.0},
    "sash_front_mid": {"position": [-240.0, -560.0], "rotation_degrees": -2.0},
    "sash_front_tip": {"position": [-500.0, -555.0], "rotation_degrees": 2.0},
}


def with_overrides(base: dict, overrides: dict) -> dict:
    pose = deepcopy(base)
    for name, values in overrides.items():
        pose.setdefault(name, {"position": [0.0, 0.0], "rotation_degrees": 0.0})
        pose[name].update(values)
    return pose


def translate_pose(base: dict, dx: float, dy: float, rot: float = 0.0) -> dict:
    pose = deepcopy(base)
    for name, data in pose.items():
        x, y = data["position"]
        data["position"] = [round(x + dx, 1), round(y + dy, 1)]
        data["rotation_degrees"] = round(float(data.get("rotation_degrees", 0.0)) + rot, 1)
    return pose


MOVE_FORWARD = with_overrides(
    translate_pose(IDLE, 18.0, 18.0, -3.0),
    {
        "hair_back": {"position": [-55.0, -1255.0], "rotation_degrees": -13.0},
        "hair_tail": {"position": [-265.0, -1125.0], "rotation_degrees": -2.0},
        "sash_back_mid": {"position": [-320.0, -642.0], "rotation_degrees": 0.0},
        "sash_back_tip": {"position": [-610.0, -645.0], "rotation_degrees": -2.0},
        "sash_front_mid": {"position": [-300.0, -585.0], "rotation_degrees": -6.0},
        "sash_front_tip": {"position": [-585.0, -582.0], "rotation_degrees": -2.0},
    },
)

MOVE_BACK = with_overrides(
    translate_pose(IDLE, -12.0, -8.0, 4.0),
    {
        "hair_back": {"position": [15.0, -1220.0], "rotation_degrees": -2.0},
        "hair_tail": {"position": [-160.0, -1080.0], "rotation_degrees": 8.0},
        "sash_back_mid": {"position": [-205.0, -600.0], "rotation_degrees": 10.0},
        "sash_back_tip": {"position": [-430.0, -595.0], "rotation_degrees": 8.0},
    },
)

HIGH_SPEED_CROUCH = with_overrides(
    translate_pose(IDLE, 20.0, 75.0, -7.0),
    {
        "head": {"position": [105.0, -1065.0], "rotation_degrees": -8.0},
        "torso": {"position": [48.0, -920.0], "rotation_degrees": -12.0},
        "pelvis_belt": {"position": [0.0, -635.0], "rotation_degrees": -8.0},
        "leg_front": {"position": [160.0, -390.0], "rotation_degrees": -18.0},
        "leg_back": {"position": [-155.0, -300.0], "rotation_degrees": 18.0},
    },
)

TURN_LEAN_LEFT = with_overrides(
    translate_pose(IDLE, -18.0, 10.0, -6.0),
    {
        "head": {"rotation_degrees": -7.0},
        "sash_back_mid": {"position": [-285.0, -600.0], "rotation_degrees": -8.0},
        "sash_front_mid": {"position": [-270.0, -545.0], "rotation_degrees": -10.0},
    },
)

TURN_LEAN_RIGHT = with_overrides(
    translate_pose(IDLE, 18.0, 10.0, 6.0),
    {
        "head": {"rotation_degrees": 3.0},
        "sash_back_mid": {"position": [-215.0, -635.0], "rotation_degrees": 12.0},
        "sash_front_mid": {"position": [-210.0, -580.0], "rotation_degrees": 8.0},
    },
)

SWORD_CONTROL_IDLE = with_overrides(
    IDLE,
    {
        "hand_back": {"position": [66.0, -850.0], "rotation_degrees": -8.0},
        "hand_front": {"position": [440.0, -880.0], "rotation_degrees": 0.0},
    },
)

SWORD_CONTROL_COMMIT = with_overrides(
    SWORD_CONTROL_IDLE,
    {
        "arm_front_upper": {"position": [175.0, -905.0], "rotation_degrees": 12.0},
        "arm_front_forearm_sleeve": {"position": [365.0, -895.0], "rotation_degrees": 6.0},
        "hand_front": {"position": [505.0, -890.0], "rotation_degrees": 2.0},
        "hand_back": {"position": [90.0, -860.0], "rotation_degrees": -12.0},
    },
)

SWORD_RETURN_CATCH = with_overrides(
    SWORD_CONTROL_IDLE,
    {
        "arm_front_upper": {"position": [125.0, -905.0], "rotation_degrees": -10.0},
        "arm_front_forearm_sleeve": {"position": [235.0, -910.0], "rotation_degrees": -18.0},
        "hand_front": {"position": [310.0, -905.0], "rotation_degrees": -20.0},
        "hand_back": {"position": [50.0, -840.0], "rotation_degrees": -4.0},
    },
)

ARRAY_RING_IDLE = with_overrides(
    SWORD_CONTROL_IDLE,
    {
        "arm_front_upper": {"position": [125.0, -900.0], "rotation_degrees": -4.0},
        "arm_front_forearm_sleeve": {"position": [230.0, -865.0], "rotation_degrees": -18.0},
        "hand_front": {"position": [275.0, -850.0], "rotation_degrees": -25.0},
        "hand_back": {"position": [25.0, -860.0], "rotation_degrees": 10.0},
    },
)

ARRAY_FAN_IDLE = with_overrides(
    SWORD_CONTROL_IDLE,
    {
        "arm_front_upper": {"position": [165.0, -900.0], "rotation_degrees": 8.0},
        "arm_front_forearm_sleeve": {"position": [355.0, -870.0], "rotation_degrees": 4.0},
        "hand_front": {"position": [490.0, -850.0], "rotation_degrees": 2.0},
        "arm_back_upper": {"position": [-165.0, -850.0], "rotation_degrees": -20.0},
        "hand_back": {"position": [-55.0, -835.0], "rotation_degrees": -12.0},
    },
)

ARRAY_PIERCE_IDLE = with_overrides(
    SWORD_CONTROL_IDLE,
    {
        "arm_front_upper": {"position": [190.0, -905.0], "rotation_degrees": 14.0},
        "arm_front_forearm_sleeve": {"position": [390.0, -895.0], "rotation_degrees": 6.0},
        "hand_front": {"position": [550.0, -890.0], "rotation_degrees": 0.0},
        "head": {"rotation_degrees": -5.0},
    },
)

ARRAY_HOLD = with_overrides(
    SWORD_CONTROL_IDLE,
    {
        "hand_front": {"position": [420.0, -875.0], "rotation_degrees": -4.0},
        "hand_back": {"position": [58.0, -848.0], "rotation_degrees": -4.0},
    },
)


def finalize(pose: dict) -> dict:
    out = {}
    for name in PART_ORDER:
        data = pose[name]
        out[name] = {
            "position": [round(float(data["position"][0]), 1), round(float(data["position"][1]), 1)],
            "rotation_degrees": round(float(data.get("rotation_degrees", 0.0)), 1),
            "scale": data.get("scale", [1.0, 1.0]),
            "z_index": Z_ORDER[name],
        }
    return out


def socket(root: list[float], chest: list[float], head: list[float], hand_front: list[float], hand_back: list[float], hilt: list[float], aim=(1.0, 0.0)) -> dict:
    return {
        "root": root,
        "chest": chest,
        "head": head,
        "hand_front": hand_front,
        "hand_back": hand_back,
        "hilt": hilt,
        "aim_forward": [float(aim[0]), float(aim[1])],
    }


SOCKET_POSES = {
    "idle": socket([0.0, 0.0], [20.0, -1010.0], [72.0, -1160.0], [440.0, -880.0], [70.0, -850.0], [510.0, -875.0]),
    "move_forward": socket([0.0, 0.0], [38.0, -992.0], [105.0, -1115.0], [460.0, -860.0], [86.0, -830.0], [535.0, -855.0]),
    "move_back": socket([0.0, 0.0], [8.0, -1018.0], [60.0, -1168.0], [420.0, -890.0], [55.0, -860.0], [488.0, -885.0]),
    "high_speed_crouch": socket([0.0, 0.0], [48.0, -920.0], [105.0, -1065.0], [458.0, -800.0], [92.0, -785.0], [540.0, -790.0]),
    "turn_lean_left": socket([0.0, 0.0], [2.0, -1000.0], [54.0, -1150.0], [420.0, -872.0], [48.0, -845.0], [500.0, -870.0]),
    "turn_lean_right": socket([0.0, 0.0], [38.0, -1000.0], [90.0, -1150.0], [465.0, -872.0], [90.0, -845.0], [545.0, -870.0]),
    "sword_control_idle": socket([0.0, 0.0], [20.0, -1010.0], [72.0, -1160.0], [440.0, -880.0], [66.0, -850.0], [510.0, -875.0]),
    "sword_control_commit": socket([0.0, 0.0], [20.0, -1010.0], [72.0, -1160.0], [505.0, -890.0], [90.0, -860.0], [600.0, -888.0]),
    "sword_return_catch": socket([0.0, 0.0], [20.0, -1010.0], [72.0, -1160.0], [310.0, -905.0], [50.0, -840.0], [335.0, -900.0]),
    "array_ring_idle": socket([0.0, 0.0], [20.0, -1010.0], [72.0, -1160.0], [275.0, -850.0], [25.0, -860.0], [315.0, -850.0]),
    "array_fan_idle": socket([0.0, 0.0], [20.0, -1010.0], [72.0, -1160.0], [490.0, -850.0], [-55.0, -835.0], [560.0, -850.0]),
    "array_pierce_idle": socket([0.0, 0.0], [20.0, -1010.0], [72.0, -1160.0], [550.0, -890.0], [66.0, -850.0], [640.0, -890.0]),
    "array_hold": socket([0.0, 0.0], [20.0, -1010.0], [72.0, -1160.0], [420.0, -875.0], [58.0, -848.0], [500.0, -875.0]),
}


def sequence_from_pose(name: str, frames: int, peak_start: int | None = None, peak_end: int | None = None) -> list[dict]:
    base = deepcopy(SOCKET_POSES[name])
    sequence = []
    for frame in range(frames):
        item = deepcopy(base)
        item["frame"] = frame
        if peak_start is not None and peak_end is not None and peak_start <= frame <= peak_end:
            item["phase"] = "peak"
        sequence.append(item)
    return sequence


def blend_sequence(a: str, b: str, frames: int) -> list[dict]:
    start = SOCKET_POSES[a]
    end = SOCKET_POSES[b]
    sequence = []
    for frame in range(frames):
        t = frame / max(1, frames - 1)
        item = {"frame": frame}
        for key in ["root", "chest", "head", "hand_front", "hand_back", "hilt"]:
            item[key] = [round(start[key][0] * (1 - t) + end[key][0] * t, 1), round(start[key][1] * (1 - t) + end[key][1] * t, 1)]
        item["aim_forward"] = [1.0, 0.0]
        sequence.append(item)
    return sequence


def validate_manifest_parts() -> None:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    missing = [name for name in PART_ORDER if name not in manifest.get("parts", {})]
    if missing:
        raise SystemExit(f"manifest missing parts: {missing}")


def main() -> None:
    validate_manifest_parts()
    poses = {
        "idle": IDLE,
        "move_forward": MOVE_FORWARD,
        "move_back": MOVE_BACK,
        "high_speed_crouch": HIGH_SPEED_CROUCH,
        "turn_lean_left": TURN_LEAN_LEFT,
        "turn_lean_right": TURN_LEAN_RIGHT,
        "sword_control_idle": SWORD_CONTROL_IDLE,
        "sword_control_commit": SWORD_CONTROL_COMMIT,
        "sword_return_catch": SWORD_RETURN_CATCH,
        "array_ring_idle": ARRAY_RING_IDLE,
        "array_fan_idle": ARRAY_FAN_IDLE,
        "array_pierce_idle": ARRAY_PIERCE_IDLE,
        "array_hold": ARRAY_HOLD,
    }
    pose_library = {
        "format_version": 1.0,
        "coordinate_system": "pivot offsets in pre-scale pixel units, y-down (Godot)",
        "assembly_scale": 0.18,
        "notes": [
            "First-pass V15 placeholder poses for loader/P0 key coverage.",
            "Requires visual tuning after hidden-side repaint and in-engine preview.",
        ],
        "poses": {name: finalize(pose) for name, pose in poses.items()},
    }
    POSE_OUT.write_text(json.dumps(pose_library, indent=2, ensure_ascii=False), encoding="utf-8")

    socket_library = {
        "format_version": 1.0,
        "coordinate_system": "local pixels before assembly_scale, y-down",
        "notes": [
            "First-pass V15 socket coverage. Sequence root is held stable by design.",
            "Final overlay art should replace these placeholders with frame-accurate sockets.",
        ],
        "poses": SOCKET_POSES,
        "sequences": {
            "array_ring_release_12": sequence_from_pose("array_ring_idle", 12, 4, 8),
            "array_fan_release_12": sequence_from_pose("array_fan_idle", 12, 4, 8),
            "array_pierce_release_12": sequence_from_pose("array_pierce_idle", 12, 4, 8),
            "array_ring_to_fan_12": blend_sequence("array_ring_idle", "array_fan_idle", 12),
            "sword_return_catch_8": sequence_from_pose("sword_return_catch", 8, 2, 5),
        },
    }
    SOCKET_OUT.write_text(json.dumps(socket_library, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"wrote {POSE_OUT} ({len(poses)} poses)")
    print(f"wrote {SOCKET_OUT} ({len(socket_library['poses'])} socket poses, {len(socket_library['sequences'])} sequences)")


if __name__ == "__main__":
    main()
