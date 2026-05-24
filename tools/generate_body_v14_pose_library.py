"""生成 body_v14_pose_library.json，覆盖 V14 第一版 5 个 pose。

坐标约定：
- 每个 part 的 position 是其 pivot 点相对于 root（角色脚下锚点）的偏移。
- Godot Y 轴向下为正，所以 head 位于负 Y。
- 单位为部件原始像素（cut 出来的 PNG 自带尺寸），渲染时由 assembly 节点统一 scale 缩到屏幕尺寸。
- z_index 越大越在前。

姿态思路（任务包 line 472-484）：
- idle：放松站立，参照 master_full 自然组装位
- sword_control_idle：右键御剑手诀，前侧臂抬起、指尖朝上
- array_ring_idle：怀抱守圆，双臂内合
- array_fan_idle：扇面控面，双臂外展
- array_pierce_idle：单指凝线，前侧臂前指
"""
from __future__ import annotations

import json
from copy import deepcopy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "resources/flight/rider/body_v14_rig/body_v14_pose_library.json"

# z_index 从后到前
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

# 基础 idle 位置（pivot 在 root 坐标系下的位置），rotation_degrees=0
IDLE = {
    "torso":                    {"position": [0, -1080], "rotation_degrees": 0},
    "pelvis_belt":              {"position": [-5, -640], "rotation_degrees": 0},
    "head":                     {"position": [0, -1180], "rotation_degrees": 0},
    "hair_back":                {"position": [-25, -1280], "rotation_degrees": 0},
    "hair_tail":                {"position": [15, -1280], "rotation_degrees": -8},
    "arm_back_upper":           {"position": [-70, -990], "rotation_degrees": 4},
    "arm_back_forearm_sleeve":  {"position": [-105, -700], "rotation_degrees": 0},
    "hand_back":                {"position": [-120, -360], "rotation_degrees": 0},
    "arm_front_upper":          {"position": [60, -990], "rotation_degrees": -4},
    "arm_front_forearm_sleeve": {"position": [100, -700], "rotation_degrees": 0},
    "hand_front":               {"position": [115, -360], "rotation_degrees": 0},
    "leg_back":                 {"position": [-55, -540], "rotation_degrees": 2},
    "leg_front":                {"position": [40, -540], "rotation_degrees": -2},
    "robe_back":                {"position": [0, -580], "rotation_degrees": 0},
    "robe_front":               {"position": [0, -580], "rotation_degrees": 0},
    "sash_back_root":           {"position": [-65, -610], "rotation_degrees": 12},
    "sash_back_mid":            {"position": [-90, -380], "rotation_degrees": 16},
    "sash_back_tip":            {"position": [-110, -180], "rotation_degrees": 20},
    "sash_front_root":          {"position": [65, -610], "rotation_degrees": -10},
    "sash_front_mid":           {"position": [80, -380], "rotation_degrees": -8},
    "sash_front_tip":           {"position": [95, -180], "rotation_degrees": -6},
}


def with_overrides(base, overrides):
    pose = deepcopy(base)
    for k, v in overrides.items():
        if k not in pose:
            pose[k] = {"position": [0, 0], "rotation_degrees": 0}
        pose[k] = {**pose[k], **v}
    return pose


# 御剑手诀：前侧臂抬起朝前上，hand_front 在胸前
SWORD_CONTROL = with_overrides(IDLE, {
    "arm_front_upper":          {"position": [55, -990], "rotation_degrees": -35},
    "arm_front_forearm_sleeve": {"position": [165, -880], "rotation_degrees": -75},
    "hand_front":               {"position": [205, -1000], "rotation_degrees": -90},
    # 后臂略微回收
    "arm_back_upper":           {"position": [-65, -990], "rotation_degrees": 10},
    "arm_back_forearm_sleeve":  {"position": [-95, -680], "rotation_degrees": 6},
    "hand_back":                {"position": [-105, -350], "rotation_degrees": 4},
    # 披帛轻微前飘
    "sash_front_root":          {"position": [70, -610], "rotation_degrees": -16},
    "sash_front_mid":           {"position": [90, -380], "rotation_degrees": -14},
    "sash_front_tip":           {"position": [110, -180], "rotation_degrees": -12},
})

# 怀抱守圆：双臂内合，手在胸前合抱
ARRAY_RING = with_overrides(IDLE, {
    "arm_front_upper":          {"position": [50, -990], "rotation_degrees": -28},
    "arm_front_forearm_sleeve": {"position": [120, -820], "rotation_degrees": -68},
    "hand_front":               {"position": [80, -880], "rotation_degrees": -100},
    "arm_back_upper":           {"position": [-55, -990], "rotation_degrees": 28},
    "arm_back_forearm_sleeve":  {"position": [-120, -820], "rotation_degrees": 68},
    "hand_back":                {"position": [-80, -880], "rotation_degrees": 100},
    # 头微低
    "head":                     {"position": [-2, -1175], "rotation_degrees": 3},
})

# 扇面控面：双臂展开
ARRAY_FAN = with_overrides(IDLE, {
    "arm_front_upper":          {"position": [70, -990], "rotation_degrees": 35},
    "arm_front_forearm_sleeve": {"position": [180, -720], "rotation_degrees": 60},
    "hand_front":               {"position": [240, -460], "rotation_degrees": 55},
    "arm_back_upper":           {"position": [-80, -990], "rotation_degrees": -35},
    "arm_back_forearm_sleeve":  {"position": [-180, -720], "rotation_degrees": -60},
    "hand_back":                {"position": [-240, -460], "rotation_degrees": -55},
})

# 单指凝线：前侧臂前指
ARRAY_PIERCE = with_overrides(IDLE, {
    "arm_front_upper":          {"position": [60, -1000], "rotation_degrees": 75},
    "arm_front_forearm_sleeve": {"position": [240, -930], "rotation_degrees": 85},
    "hand_front":               {"position": [390, -930], "rotation_degrees": 90},
    "arm_back_upper":           {"position": [-65, -990], "rotation_degrees": -6},
    "arm_back_forearm_sleeve":  {"position": [-90, -680], "rotation_degrees": -4},
    "hand_back":                {"position": [-95, -360], "rotation_degrees": -2},
    "head":                     {"position": [4, -1180], "rotation_degrees": -2},
})


def finalize(pose: dict) -> dict:
    """补充 z_index 和默认 scale。"""
    out = {}
    for name, data in pose.items():
        out[name] = {
            "position": data["position"],
            "rotation_degrees": data.get("rotation_degrees", 0),
            "scale": data.get("scale", [1.0, 1.0]),
            "z_index": Z_ORDER.get(name, 0),
        }
    return out


def main() -> None:
    library = {
        "format_version": 1,
        "coordinate_system": "pivot offsets in pre-scale pixel units, y-down (Godot)",
        "assembly_scale": 0.18,
        "poses": {
            "idle":                finalize(IDLE),
            "sword_control_idle":  finalize(SWORD_CONTROL),
            "array_ring_idle":     finalize(ARRAY_RING),
            "array_fan_idle":      finalize(ARRAY_FAN),
            "array_pierce_idle":   finalize(ARRAY_PIERCE),
        },
    }
    OUT.write_text(json.dumps(library, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"wrote {OUT} with {len(library['poses'])} poses")


if __name__ == "__main__":
    main()
