from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
POSE_PATH = ROOT / "resources/flight/yujian_8way_cruise_generated_v1/prototype_v4_skeleton_pose_overrides.json"
OUT_DIR = ROOT / "resources/flight/yujian_8way_cruise_generated_v1/prototype_v4_skeleton_pose_refs"

CANVAS = 768
MARGIN = 92
SUPERSAMPLE = 3

DIR_VECTORS = [
    (1.0, 0.0),
    (0.7071, -0.7071),
    (0.0, -1.0),
    (-0.7071, -0.7071),
    (-1.0, 0.0),
    (-0.7071, 0.7071),
    (0.0, 1.0),
    (0.7071, 0.7071),
]

DIRECTION_KEYS = [
    "01_right",
    "02_up_right",
    "03_up",
    "04_up_left",
    "05_left",
    "06_down_left",
    "07_down",
    "08_down_right",
]

CARDINAL_BLEND_DIRECTION_INDICES = [0, 6, 4, 2]

JOINT_KEYS = [
    "head_center",
    "shoulder_near",
    "shoulder_far",
    "elbow_near",
    "elbow_far",
    "wrist_near",
    "wrist_far",
    "hip_near",
    "hip_far",
    "knee_near",
    "knee_far",
    "ankle_near",
    "ankle_far",
]

MIRROR_JOINT = {
    "shoulder_near": "shoulder_far",
    "shoulder_far": "shoulder_near",
    "elbow_near": "elbow_far",
    "elbow_far": "elbow_near",
    "wrist_near": "wrist_far",
    "wrist_far": "wrist_near",
    "hip_near": "hip_far",
    "hip_far": "hip_near",
    "knee_near": "knee_far",
    "knee_far": "knee_near",
    "ankle_near": "ankle_far",
    "ankle_far": "ankle_near",
}


def add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def mul(a, scalar):
    return (a[0] * scalar, a[1] * scalar)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1]


def length_sq(a):
    return dot(a, a)


def normalize(a):
    length = math.sqrt(length_sq(a))
    if length <= 0.0001:
        return (1.0, 0.0)
    return (a[0] / length, a[1] / length)


def lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def lerpf(a, b, t):
    return a + (b - a) * t


def signf(value):
    if value > 0.0:
        return 1.0
    if value < 0.0:
        return -1.0
    return 0.0


def smoothstep(edge0, edge1, value):
    if edge0 == edge1:
        return 1.0 if value >= edge1 else 0.0
    t = max(0.0, min(1.0, (value - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)


def direction_vector(index):
    return normalize(DIR_VECTORS[max(0, min(index, len(DIR_VECTORS) - 1))])


def direction_key(index):
    return DIRECTION_KEYS[max(0, min(index, len(DIRECTION_KEYS) - 1))]


def pose_override_vec(value):
    if isinstance(value, list) and len(value) >= 2:
        return (float(value[0]), float(value[1]))
    return (0.0, 0.0)


def apply_pose_overrides(pose_data, pose_name, key, pose):
    direction_data = pose_data.get("poses", {}).get(pose_name, {}).get(key, {})
    if not isinstance(direction_data, dict):
        return
    for joint in JOINT_KEYS:
        if joint in direction_data:
            pose[joint] = add(pose[joint], pose_override_vec(direction_data[joint]))


def head_scale(pose_data, pose_name, key):
    direction_data = pose_data.get("poses", {}).get(pose_name, {}).get(key, {})
    if not isinstance(direction_data, dict):
        return 1.0
    return max(0.35, min(2.0, float(direction_data.get("_head_scale", 1.0))))


def front_side_sign(pose_data, pose_name, key, default_sign):
    direction_data = pose_data.get("poses", {}).get(pose_name, {}).get(key, {})
    if not isinstance(direction_data, dict) or "_front_side_sign" not in direction_data:
        return 1.0 if default_sign >= 0.0 else -1.0
    return 1.0 if float(direction_data["_front_side_sign"]) >= 0.0 else -1.0


def build_direction_pose(pose_data, direction_index, fast_weight, speed_ratio, wind, apply_overrides=True):
    h = direction_vector(direction_index)
    side = (1.0, 0.0)
    near_sign = signf(h[0]) or 1.0
    near = mul(side, near_sign)
    far = mul(near, -1.0)
    key = direction_key(direction_index)
    draw_pose_name = "fast" if fast_weight >= 0.5 else "low"
    front_sign = front_side_sign(pose_data, draw_pose_name, key, near_sign) if apply_overrides else near_sign

    side_profile = abs(h[0])
    front_profile = abs(h[1])
    low_body_lean = mul(h, 5.0)
    side_lean = (0.0, 0.0)
    foot_center_low = (0.0, 76.0)
    foot_center_fast = (0.0, 66.0)
    low_hip = add(add(foot_center_low, (0.0, -88.0)), add(mul(low_body_lean, 0.18), mul(side_lean, 0.18)))
    low_shoulder = add(add(low_hip, (0.0, -52.0)), add(mul(low_body_lean, 0.42), mul(side_lean, 0.42)))
    fast_hip = add(add(foot_center_fast, (0.0, -74.0)), add(mul(h, -32.0), mul(side_lean, 0.26)))
    fast_shoulder = add(add(fast_hip, (0.0, -34.0)), add(mul(h, 72.0), mul(side_lean, 0.72)))

    torso_width_base = lerpf(9.0, 23.0, front_profile)
    torso_width_base *= lerpf(0.56, 0.86, front_profile)
    torso_width_low = torso_width_base
    torso_width_fast = max(torso_width_base * 0.72, 6.0)
    hip_width_base = lerpf(6.0, 15.0, front_profile)
    hip_width_base *= lerpf(0.60, 0.86, front_profile)
    hip_width_low = hip_width_base
    hip_width_fast = max(hip_width_base * 0.72, 4.5)
    if side_profile > 0.65:
        torso_width_low = max(torso_width_low, 8.0)
        torso_width_fast = max(torso_width_fast, 8.0)
        hip_width_low = max(hip_width_low, 5.0)
        hip_width_fast = max(hip_width_fast, 5.0)

    arm_flow = 0.0
    leg_flow = 0.0
    arm_spread = 6.0 + 10.0 * front_profile
    foot_spacing = lerpf(7.0, 14.0, front_profile)
    foot_stagger = 16.0 + 12.0 * side_profile

    shoulder_near_low = add(low_shoulder, mul(near, torso_width_low))
    shoulder_far_low = add(low_shoulder, mul(far, torso_width_low * 0.82))
    hip_near_low = add(low_hip, mul(near, hip_width_low))
    hip_far_low = add(low_hip, mul(far, hip_width_low * 0.86))
    shoulder_near_fast = add(fast_shoulder, mul(near, torso_width_fast))
    shoulder_far_fast = add(fast_shoulder, mul(far, torso_width_fast * 0.82))
    hip_near_fast = add(fast_hip, mul(near, hip_width_fast))
    hip_far_fast = add(fast_hip, mul(far, hip_width_fast * 0.86))

    low_elbow_near = add(add(add(shoulder_near_low, mul(h, 27.0)), mul(near, arm_spread + 5.0)), (0.0, 30.0 + arm_flow))
    low_wrist_near = add(add(add(shoulder_near_low, mul(h, 58.0)), mul(near, arm_spread + 12.0)), (0.0, 40.0 + arm_flow * 1.25))
    low_elbow_far = add(add(add(shoulder_far_low, mul(h, 4.0)), mul(far, arm_spread * 0.55)), (0.0, 35.0 - arm_flow * 0.65))
    low_wrist_far = add(add(add(low_hip, mul(h, 8.0)), mul(near, 5.0)), (0.0, -5.0 - arm_flow))
    fast_elbow_near = add(add(add(shoulder_near_fast, mul(h, -46.0)), mul(near, arm_spread * 0.72 + 7.0)), (0.0, 26.0 + arm_flow))
    fast_wrist_near = add(add(add(shoulder_near_fast, mul(h, -96.0)), mul(near, arm_spread + 10.0)), (0.0, 40.0 + arm_flow * 1.15))
    fast_elbow_far = add(add(add(shoulder_far_fast, mul(h, -51.0)), mul(far, arm_spread * 0.72 + 5.0)), (0.0, 28.0 - arm_flow * 0.55))
    fast_wrist_far = add(add(add(shoulder_far_fast, mul(h, -104.0)), mul(far, arm_spread + 8.0)), (0.0, 42.0 - arm_flow * 0.80))

    low_ankle_near = add(add(foot_center_low, add(mul(near, foot_spacing), mul(h, foot_stagger))), (0.0, leg_flow * 0.45))
    low_ankle_far = sub(add(foot_center_low, add(mul(far, foot_spacing), mul(h, -foot_stagger))), (0.0, leg_flow * 0.35))
    low_knee_near = add(add(lerp(hip_near_low, low_ankle_near, 0.56), mul(near, 4.0)), mul(h, 6.0))
    low_knee_far = add(add(lerp(hip_far_low, low_ankle_far, 0.56), mul(far, 4.0)), mul(h, 3.0))
    fast_knee_near = add(add(add(hip_near_fast, mul(h, 54.0)), mul(near, 12.0)), (0.0, 34.0 + leg_flow))
    fast_ankle_near = add(add(add(hip_near_fast, mul(h, 48.0)), mul(near, 20.0)), (0.0, 76.0 + leg_flow * 1.25))
    fast_knee_far = add(add(add(hip_far_fast, mul(h, -44.0)), mul(far, 6.0)), (0.0, 31.0 - leg_flow * 0.65))
    fast_ankle_far = add(add(add(hip_far_fast, mul(h, -97.0)), mul(far, 10.0)), (0.0, 70.0 - leg_flow))
    low_head = add(add(low_shoulder, (0.0, -30.0)), mul(h, 5.0))
    fast_head = add(add(fast_shoulder, (0.0, -23.0)), mul(h, 27.0))

    low_pose = {
        "head_center": low_head,
        "shoulder_near": shoulder_near_low,
        "shoulder_far": shoulder_far_low,
        "elbow_near": low_elbow_near,
        "elbow_far": low_elbow_far,
        "wrist_near": low_wrist_near,
        "wrist_far": low_wrist_far,
        "hip_near": hip_near_low,
        "hip_far": hip_far_low,
        "knee_near": low_knee_near,
        "knee_far": low_knee_far,
        "ankle_near": low_ankle_near,
        "ankle_far": low_ankle_far,
    }
    high_pose = {
        "head_center": fast_head,
        "shoulder_near": shoulder_near_fast,
        "shoulder_far": shoulder_far_fast,
        "elbow_near": fast_elbow_near,
        "elbow_far": fast_elbow_far,
        "wrist_near": fast_wrist_near,
        "wrist_far": fast_wrist_far,
        "hip_near": hip_near_fast,
        "hip_far": hip_far_fast,
        "knee_near": fast_knee_near,
        "knee_far": fast_knee_far,
        "ankle_near": fast_ankle_near,
        "ankle_far": fast_ankle_far,
    }

    if apply_overrides:
        apply_pose_overrides(pose_data, "low", key, low_pose)
        apply_pose_overrides(pose_data, "fast", key, high_pose)

    low_head_scale = head_scale(pose_data, "low", key) if apply_overrides else 1.0
    fast_head_scale = head_scale(pose_data, "fast", key) if apply_overrides else 1.0
    pose = {
        "heading": h,
        "near_side_sign": near_sign,
        "front_side_sign": front_sign,
        "speed_ratio": speed_ratio,
        "fast_pose": fast_weight,
        "wind": wind,
        "frontness": h[1],
        "foot_center": lerp(foot_center_low, foot_center_fast, fast_weight),
        "head_scale": lerpf(low_head_scale, fast_head_scale, fast_weight),
    }
    for joint in JOINT_KEYS:
        pose[joint] = lerp(low_pose[joint], high_pose[joint], fast_weight)
    recompute_centers(pose)
    return pose


def recompute_centers(pose):
    pose["shoulder_center"] = mul(add(pose["shoulder_near"], pose["shoulder_far"]), 0.5)
    pose["hip_center"] = mul(add(pose["hip_near"], pose["hip_far"]), 0.5)


def cardinal_blend_for_heading(heading):
    safe = normalize(heading)
    segment_size = math.pi * 0.5
    segment_float = (math.atan2(safe[1], safe[0]) % (math.pi * 2.0)) / segment_size
    segment_floor = math.floor(segment_float)
    segment_index = int(segment_floor) % len(CARDINAL_BLEND_DIRECTION_INDICES)
    next_segment_index = (segment_index + 1) % len(CARDINAL_BLEND_DIRECTION_INDICES)
    raw_weight = segment_float - segment_floor
    return (
        CARDINAL_BLEND_DIRECTION_INDICES[segment_index],
        CARDINAL_BLEND_DIRECTION_INDICES[next_segment_index],
        smoothstep(0.0, 1.0, raw_weight),
    )


def source_joint_for_output_side(source_pose, joint, output_near_sign):
    source_near = 1.0 if float(source_pose.get("near_side_sign", 1.0)) >= 0.0 else -1.0
    target_near = 1.0 if output_near_sign >= 0.0 else -1.0
    if source_near == target_near:
        return joint
    return MIRROR_JOINT.get(joint, joint)


def sword_center(boost):
    return (0.0, 68.0 + 4.0 * boost)


def point_to_sword_line_correction(point, heading, center):
    normal = (-heading[1], heading[0])
    distance = dot(sub(point, center), normal)
    return mul(normal, -distance)


def align_blended_feet_to_sword_line(pose, boost):
    h = normalize(pose["heading"])
    diagonal_strength = max(0.0, min(1.0, min(abs(h[0]), abs(h[1])) * 1.41421356237))
    diagonal_strength = smoothstep(0.08, 0.65, diagonal_strength)
    if diagonal_strength <= 0.001:
        return
    center = sword_center(boost)
    for side in ("near", "far"):
        ankle_key = f"ankle_{side}"
        knee_key = f"knee_{side}"
        correction = mul(point_to_sword_line_correction(pose[ankle_key], h, center), diagonal_strength)
        pose[ankle_key] = add(pose[ankle_key], correction)
        pose[knee_key] = add(pose[knee_key], mul(correction, 0.45))
    recompute_centers(pose)


def blend_poses(first, second, weight, boost):
    t = max(0.0, min(1.0, weight))
    heading = normalize(lerp(first["heading"], second["heading"], t))
    near_sign = signf(heading[0]) or 1.0
    pose = {
        "heading": heading,
        "near_side_sign": near_sign,
        "front_side_sign": second.get("front_side_sign", near_sign) if t >= 0.5 else first.get("front_side_sign", near_sign),
        "speed_ratio": lerpf(first.get("speed_ratio", 0.0), second.get("speed_ratio", 0.0), t),
        "fast_pose": lerpf(first.get("fast_pose", 0.0), second.get("fast_pose", 0.0), t),
        "wind": lerpf(first.get("wind", 0.0), second.get("wind", 0.0), t),
        "frontness": heading[1],
        "foot_center": lerp(first["foot_center"], second["foot_center"], t),
        "head_scale": lerpf(first.get("head_scale", 1.0), second.get("head_scale", 1.0), t),
    }
    for joint in JOINT_KEYS:
        first_joint = source_joint_for_output_side(first, joint, near_sign)
        second_joint = source_joint_for_output_side(second, joint, near_sign)
        pose[joint] = lerp(first[first_joint], second[second_joint], t)
    recompute_centers(pose)
    align_blended_feet_to_sword_line(pose, boost)
    return pose


def build_runtime_pose(pose_data, direction_index, fast_weight):
    heading = direction_vector(direction_index)
    speed_ratio = fast_weight
    wind = fast_weight
    boost = fast_weight
    first_index, second_index, blend_weight = cardinal_blend_for_heading(heading)
    first = build_direction_pose(pose_data, first_index, fast_weight, speed_ratio, wind)
    if first_index == second_index or blend_weight <= 0.001:
        return first
    second = build_direction_pose(pose_data, second_index, fast_weight, speed_ratio, wind)
    return blend_poses(first, second, blend_weight, boost)


def pose_bounds(poses):
    points = []
    for pose in poses:
        for joint in JOINT_KEYS:
            points.append(pose[joint])
        head = pose["head_center"]
        radius = 15.0 * pose.get("head_scale", 1.0)
        points.append((head[0] - radius, head[1] - radius))
        points.append((head[0] + radius, head[1] + radius))
    min_x = min(p[0] for p in points)
    max_x = max(p[0] for p in points)
    min_y = min(p[1] for p in points)
    max_y = max(p[1] for p in points)
    return min_x, min_y, max_x, max_y


def transform_factory(pose, scale):
    min_x, min_y, max_x, max_y = pose_bounds([pose])
    center = ((min_x + max_x) * 0.5, (min_y + max_y) * 0.5)

    def tx(point):
        return (
            int(round((CANVAS * 0.5 + (point[0] - center[0]) * scale) * SUPERSAMPLE)),
            int(round((CANVAS * 0.5 + (point[1] - center[1]) * scale) * SUPERSAMPLE)),
        )

    return tx


def draw_segment(draw, tx, points, fill, width):
    scaled_points = [tx(point) for point in points]
    draw.line(scaled_points, fill=fill, width=int(round(width * SUPERSAMPLE)), joint="curve")


def draw_pose(pose, scale):
    image = Image.new("RGB", (CANVAS * SUPERSAMPLE, CANVAS * SUPERSAMPLE), (255, 255, 255))
    draw = ImageDraw.Draw(image)
    tx = transform_factory(pose, scale)

    far = (115, 125, 130)
    near = (20, 24, 28)
    torso = (42, 48, 52)
    joint = (10, 14, 18)

    draw_segment(draw, tx, [pose["shoulder_far"], pose["elbow_far"], pose["wrist_far"]], far, 5.0)
    draw_segment(draw, tx, [pose["hip_far"], pose["knee_far"], pose["ankle_far"]], far, 5.0)

    body_poly = [
        tx(pose["shoulder_near"]),
        tx(pose["shoulder_far"]),
        tx(pose["hip_far"]),
        tx(pose["hip_near"]),
    ]
    draw.polygon(body_poly, outline=torso, fill=(235, 238, 240))
    draw_segment(draw, tx, [pose["shoulder_center"], pose["hip_center"]], torso, 4.0)

    draw_segment(draw, tx, [pose["hip_near"], pose["knee_near"], pose["ankle_near"]], near, 6.0)
    draw_segment(draw, tx, [pose["shoulder_near"], pose["elbow_near"], pose["wrist_near"]], near, 6.0)
    draw_segment(draw, tx, [pose["shoulder_center"], pose["head_center"]], torso, 4.0)

    head_center = tx(pose["head_center"])
    head_radius = int(round(15.0 * pose.get("head_scale", 1.0) * scale * SUPERSAMPLE))
    draw.ellipse(
        [
            head_center[0] - head_radius,
            head_center[1] - head_radius,
            head_center[0] + head_radius,
            head_center[1] + head_radius,
        ],
        fill=(235, 238, 240),
        outline=near,
        width=max(2, int(round(3.0 * SUPERSAMPLE))),
    )

    for name in JOINT_KEYS:
        x, y = tx(pose[name])
        radius = int(round((5.0 if name.startswith(("ankle", "wrist")) else 4.2) * SUPERSAMPLE))
        draw.ellipse([x - radius, y - radius, x + radius, y + radius], fill=joint)

    return image.resize((CANVAS, CANVAS), Image.Resampling.LANCZOS)


def make_contact_sheet(images):
    cell = 320
    gutter = 24
    sheet = Image.new("RGB", (cell * 4 + gutter * 5, cell * 2 + gutter * 3), (255, 255, 255))
    for index, image in enumerate(images):
        thumb = image.resize((cell, cell), Image.Resampling.LANCZOS)
        x = gutter + (index % 4) * (cell + gutter)
        y = gutter + (index // 4) * (cell + gutter)
        sheet.paste(thumb, (x, y))
    return sheet


def main():
    pose_data = json.loads(POSE_PATH.read_text(encoding="utf-8"))
    pose_sets = {
        "low": [build_runtime_pose(pose_data, index, 0.0) for index in range(8)],
        "fast": [build_runtime_pose(pose_data, index, 1.0) for index in range(8)],
    }
    bounds = pose_bounds([pose for poses in pose_sets.values() for pose in poses])
    scale = min((CANVAS - MARGIN * 2) / max(1.0, bounds[2] - bounds[0]), (CANVAS - MARGIN * 2) / max(1.0, bounds[3] - bounds[1]))

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for pose_name, poses in pose_sets.items():
        pose_dir = OUT_DIR / pose_name
        pose_dir.mkdir(parents=True, exist_ok=True)
        rendered = []
        for key, pose in zip(DIRECTION_KEYS, poses):
            image = draw_pose(pose, scale)
            image.save(pose_dir / f"{key}.png")
            rendered.append(image)
        make_contact_sheet(rendered).save(OUT_DIR / f"v4_skeleton_{pose_name}_8way_contact_sheet.png")

    print(f"wrote {OUT_DIR}")


if __name__ == "__main__":
    main()
