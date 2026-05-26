extends Node2D
class_name HumanoidEightWaySkeletonVisual

const DIR_VECTORS := [
	Vector2(1.0, 0.0),
	Vector2(0.7071, -0.7071),
	Vector2(0.0, -1.0),
	Vector2(-0.7071, -0.7071),
	Vector2(-1.0, 0.0),
	Vector2(-0.7071, 0.7071),
	Vector2(0.0, 1.0),
	Vector2(0.7071, 0.7071),
]

const EDIT_DIRECTION_KEYS := [
	"01_right",
	"02_up_right",
	"03_up",
	"04_up_left",
	"05_left",
	"06_down_left",
	"07_down",
	"08_down_right",
]
const EDIT_CARDINAL_DIRECTION_INDICES := [0, 2, 4, 6]
const CARDINAL_BLEND_DIRECTION_INDICES := [0, 6, 4, 2]
const OUTLINE := Color(0.035, 0.045, 0.055, 0.94)
const JOINT := Color(0.94, 0.98, 1.0, 0.96)
const HEAD := Color(0.92, 0.76, 0.50, 1.0)
const TORSO := Color(0.34, 0.66, 0.76, 1.0)
const UPPER_ARM := Color(0.78, 0.89, 0.88, 1.0)
const FOREARM := Color(0.62, 0.82, 0.86, 1.0)
const THIGH := Color(0.25, 0.48, 0.58, 1.0)
const CALF := Color(0.20, 0.36, 0.48, 1.0)
const ROBE_LIGHT := Color(0.76, 0.90, 0.88, 1.0)
const ROBE_SHADOW := Color(0.16, 0.30, 0.40, 1.0)
const ROBE_TRIM := Color(0.90, 0.82, 0.47, 0.96)
const SASH := Color(0.82, 0.28, 0.25, 0.96)
const BOOT := Color(0.11, 0.13, 0.20, 1.0)
const JADE := Color(0.64, 1.0, 0.86, 0.98)
const SWORD := Color(0.62, 0.96, 1.0, 0.88)
const SWORD_CORE := Color(0.96, 1.0, 0.98, 0.98)
const FACE_DARK := Color(0.06, 0.07, 0.08, 0.92)
const FLIGHT_SPEED_POSE_REFERENCE := 1950.0
const POSE_OVERRIDE_PATH := "res://resources/flight/yujian_8way_cruise_generated_v1/prototype_v4_skeleton_pose_overrides.json"
const EDIT_JOINT_KEYS := [
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
const EDIT_DRAW_LAYER_KEYS := [
	"far_arm",
	"far_leg",
	"torso",
	"head",
	"near_leg",
	"near_arm",
]
const EDIT_DRAW_LAYER_LABELS := [
	"远侧手臂",
	"远侧腿",
	"躯干",
	"头",
	"近侧腿",
	"近侧手臂",
]
const EDIT_BONE_LENGTH_KEYS := [
	"torso",
	"upper_arm",
	"forearm",
	"thigh",
	"calf",
]
const EDIT_BONE_LENGTH_LABELS := [
	"躯干",
	"大臂",
	"小臂",
	"大腿",
	"小腿",
]
const EDIT_DIRECTION_LABELS := [
	"01 right / 右",
	"03 up / 上",
	"05 left / 左",
	"07 down / 下",
]

var _direction_index := 0
var _heading := Vector2.RIGHT
var _velocity := Vector2.ZERO
var _boost := 0.0
var _turn := 0.0
var _carve := 0.0
var _throttle := 0.0
var _time := 0.0
var _switch_flash := 0.0
var _pose_overrides := {"low": {}, "fast": {}}
var _bone_lengths := {}
var _editor_active := false
var _editor_pose := "low"
var _editor_direction_index := 0
var _editor_selected_joint := "wrist_near"
var _editor_selected_layer := "near_arm"
var _editor_selected_bone_length := "forearm"
var _editor_lock_bone_length := false
var _editor_dragging := false
var _editor_last_local_mouse := Vector2.ZERO
var _editor_updating_controls := false
var _editor_layer: CanvasLayer
var _editor_panel: PanelContainer
var _editor_pose_option: OptionButton
var _editor_direction_option: OptionButton
var _editor_front_side_option: OptionButton
var _editor_joint_option: OptionButton
var _editor_offset_x_spin: SpinBox
var _editor_offset_y_spin: SpinBox
var _editor_head_scale_spin: SpinBox
var _editor_layer_option: OptionButton
var _editor_bone_length_option: OptionButton
var _editor_bone_length_spin: SpinBox
var _editor_lock_bone_checkbox: CheckBox
var _editor_status_label: Label


func _ready() -> void:
	_load_pose_overrides()
	_create_editor_panel()
	set_process_input(true)


func is_pose_editor_active() -> bool:
	return _editor_active


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F4:
		_toggle_editor()
		get_viewport().set_input_as_handled()
		return
	if not _editor_active:
		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if _is_pointer_over_editor_panel(mouse_button.position):
			return
		if mouse_button.pressed:
			var local_mouse := to_local(mouse_button.position)
			_editor_dragging = _select_nearest_joint(local_mouse)
			_editor_last_local_mouse = local_mouse
		else:
			_editor_dragging = false
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and _editor_dragging:
		var motion := event as InputEventMouseMotion
		if _is_pointer_over_editor_panel(motion.position):
			return
		var local_mouse := to_local(motion.position)
		_add_selected_joint_offset(local_mouse - _editor_last_local_mouse)
		_editor_last_local_mouse = local_mouse
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if _editor_panel != null:
			var focus := get_viewport().gui_get_focus_owner()
			if focus != null and _editor_panel.is_ancestor_of(focus):
				return
		var step := 5.0 if key_event.shift_pressed else 1.0
		match key_event.keycode:
			KEY_LEFT:
				_add_selected_joint_offset(Vector2(-step, 0.0))
			KEY_RIGHT:
				_add_selected_joint_offset(Vector2(step, 0.0))
			KEY_UP:
				_add_selected_joint_offset(Vector2(0.0, -step))
			KEY_DOWN:
				_add_selected_joint_offset(Vector2(0.0, step))
			KEY_DELETE, KEY_BACKSPACE:
				_set_selected_joint_offset(Vector2.ZERO)
			KEY_S:
				if key_event.ctrl_pressed or key_event.meta_pressed:
					_save_pose_overrides()
				else:
					return
			_:
				return
		get_viewport().set_input_as_handled()


func set_flight_pose(
		p_direction_index: int,
		p_heading: Vector2,
		p_velocity: Vector2,
		p_boost: float,
		p_turn: float,
		p_carve: float,
		p_throttle: float,
		p_delta: float
) -> void:
	var safe_index := clampi(p_direction_index, 0, DIR_VECTORS.size() - 1)
	if safe_index != _direction_index:
		_direction_index = safe_index
		_switch_flash = 1.0
	else:
		_switch_flash = maxf(_switch_flash - maxf(p_delta, 0.0) / 0.12, 0.0)
	_heading = p_heading.normalized() if p_heading.length_squared() > 0.0001 else _direction_vector(_direction_index)
	_velocity = p_velocity
	_boost = clampf(p_boost, 0.0, 1.0)
	_turn = clampf(p_turn, 0.0, 1.0)
	_carve = clampf(p_carve, 0.0, 1.0)
	_throttle = clampf(p_throttle, 0.0, 1.0)
	_time += maxf(p_delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var pose := _build_flight_pose()
	var h: Vector2 = pose["heading"]
	var speed_ratio: float = pose["speed_ratio"]
	_draw_sword(h, speed_ratio)
	for layer_key in _front_side_adjusted_draw_order(pose.get("draw_order", EDIT_DRAW_LAYER_KEYS), pose):
		_draw_body_layer(String(layer_key), pose)
	_draw_joints(pose)


func _build_flight_pose(apply_overrides := true) -> Dictionary:
	var pose_boost := _boost
	var pose_throttle := _throttle
	var speed_ratio := clampf(_velocity.length() / FLIGHT_SPEED_POSE_REFERENCE, 0.0, 1.0)
	if _editor_active:
		if _editor_pose == "fast":
			pose_boost = 1.0
			pose_throttle = 1.0
			speed_ratio = 1.0
		else:
			pose_boost = 0.0
			pose_throttle = 0.0
			speed_ratio = 0.0
	var fast_weight := smoothstep(0.28, 0.82, maxf(speed_ratio, pose_boost * 0.92 + pose_throttle * 0.18))
	if _editor_active:
		fast_weight = 1.0 if _editor_pose == "fast" else 0.0
	elif fast_weight > 0.975:
		fast_weight = 1.0
	var wind := clampf(speed_ratio + pose_boost * 0.65 + _carve * 0.5, 0.0, 1.6)
	if _editor_active:
		return _build_direction_flight_pose(_editor_direction_index, fast_weight, speed_ratio, wind, apply_overrides)

	var blend_info := _cardinal_blend_for_heading(_heading)
	var first_index := int(blend_info["from_index"])
	var second_index := int(blend_info["to_index"])
	var blend_weight := float(blend_info["weight"])
	var first_pose := _build_direction_flight_pose(first_index, fast_weight, speed_ratio, wind, apply_overrides)
	if first_index == second_index or blend_weight <= 0.001:
		return first_pose
	var second_pose := _build_direction_flight_pose(second_index, fast_weight, speed_ratio, wind, apply_overrides)
	return _blend_flight_poses(first_pose, second_pose, blend_weight)


func _build_direction_flight_pose(
		direction_index: int,
		fast_weight: float,
		speed_ratio: float,
		wind: float,
		apply_overrides: bool
) -> Dictionary:
	var h := _direction_vector(direction_index)
	var side := Vector2(1.0, 0.0)
	var near_sign := signf(h.x)
	if near_sign == 0.0:
		near_sign = 1.0
	var near := side * near_sign
	var far := -near
	var direction_key := _direction_key(direction_index)
	var draw_pose_name: String = "fast" if fast_weight >= 0.5 else "low"
	var front_side_sign := _get_front_side_sign(draw_pose_name, direction_key, near_sign) if apply_overrides else near_sign
	var side_profile := absf(h.x)
	var front_profile := absf(h.y)
	var low_body_lean := h * 5.0
	var side_lean := Vector2.ZERO
	var foot_center_low := Vector2(0.0, 76.0)
	var foot_center_fast := Vector2(0.0, 66.0)
	var low_hip := foot_center_low + Vector2(0.0, -88.0) + low_body_lean * 0.18 + side_lean * 0.18
	var low_shoulder := low_hip + Vector2(0.0, -52.0) + low_body_lean * 0.42 + side_lean * 0.42
	var fast_hip := foot_center_fast + Vector2(0.0, -74.0) - h * 32.0 + side_lean * 0.26
	var fast_shoulder := fast_hip + Vector2(0.0, -34.0) + h * 72.0 + side_lean * 0.72
	var torso_width_base := lerpf(9.0, 23.0, front_profile)
	torso_width_base *= lerpf(0.56, 0.86, front_profile)
	var torso_width_low := torso_width_base
	var torso_width_fast := maxf(torso_width_base * 0.72, 6.0)
	var hip_width_base := lerpf(6.0, 15.0, front_profile)
	hip_width_base *= lerpf(0.60, 0.86, front_profile)
	var hip_width_low := hip_width_base
	var hip_width_fast := maxf(hip_width_base * 0.72, 4.5)
	if side_profile > 0.65:
		torso_width_low = maxf(torso_width_low, 8.0)
		torso_width_fast = maxf(torso_width_fast, 8.0)
		hip_width_low = maxf(hip_width_low, 5.0)
		hip_width_fast = maxf(hip_width_fast, 5.0)
	var arm_flow := 0.0
	var leg_flow := 0.0
	var arm_spread := 6.0 + 10.0 * front_profile
	var foot_spacing := lerpf(7.0, 14.0, front_profile)
	var foot_stagger := 16.0 + 12.0 * side_profile

	var shoulder_near_low := low_shoulder + near * torso_width_low
	var shoulder_far_low := low_shoulder + far * torso_width_low * 0.82
	var hip_near_low := low_hip + near * hip_width_low
	var hip_far_low := low_hip + far * hip_width_low * 0.86
	var shoulder_near_fast := fast_shoulder + near * torso_width_fast
	var shoulder_far_fast := fast_shoulder + far * torso_width_fast * 0.82
	var hip_near_fast := fast_hip + near * hip_width_fast
	var hip_far_fast := fast_hip + far * hip_width_fast * 0.86

	var low_elbow_near := shoulder_near_low + h * 27.0 + near * (arm_spread + 5.0) + Vector2(0.0, 30.0 + arm_flow)
	var low_wrist_near := shoulder_near_low + h * 58.0 + near * (arm_spread + 12.0) + Vector2(0.0, 40.0 + arm_flow * 1.25)
	var low_elbow_far := shoulder_far_low + h * 4.0 + far * (arm_spread * 0.55) + Vector2(0.0, 35.0 - arm_flow * 0.65)
	var low_wrist_far := low_hip + h * 8.0 + near * 5.0 + Vector2(0.0, -5.0 - arm_flow)
	var fast_elbow_near := shoulder_near_fast - h * 46.0 + near * (arm_spread * 0.72 + 7.0) + Vector2(0.0, 26.0 + arm_flow)
	var fast_wrist_near := shoulder_near_fast - h * 96.0 + near * (arm_spread + 10.0) + Vector2(0.0, 40.0 + arm_flow * 1.15)
	var fast_elbow_far := shoulder_far_fast - h * 51.0 + far * (arm_spread * 0.72 + 5.0) + Vector2(0.0, 28.0 - arm_flow * 0.55)
	var fast_wrist_far := shoulder_far_fast - h * 104.0 + far * (arm_spread + 8.0) + Vector2(0.0, 42.0 - arm_flow * 0.80)

	var low_ankle_near := foot_center_low + near * foot_spacing + h * foot_stagger + Vector2(0.0, leg_flow * 0.45)
	var low_ankle_far := foot_center_low + far * foot_spacing - h * foot_stagger - Vector2(0.0, leg_flow * 0.35)
	var low_knee_near := hip_near_low.lerp(low_ankle_near, 0.56) + near * 4.0 + h * 6.0
	var low_knee_far := hip_far_low.lerp(low_ankle_far, 0.56) + far * 4.0 + h * 3.0
	var fast_knee_near := hip_near_fast + h * 54.0 + near * 12.0 + Vector2(0.0, 34.0 + leg_flow)
	var fast_ankle_near := hip_near_fast + h * 48.0 + near * 20.0 + Vector2(0.0, 76.0 + leg_flow * 1.25)
	var fast_knee_far := hip_far_fast - h * 44.0 + far * 6.0 + Vector2(0.0, 31.0 - leg_flow * 0.65)
	var fast_ankle_far := hip_far_fast - h * 97.0 + far * 10.0 + Vector2(0.0, 70.0 - leg_flow)
	var low_head := low_shoulder + Vector2(0.0, -30.0) + h * 5.0
	var fast_head := fast_shoulder + Vector2(0.0, -23.0) + h * 27.0

	var low_pose := {
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
	var high_pose := {
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
		_apply_pose_overrides("low", direction_key, low_pose)
		_apply_pose_overrides("fast", direction_key, high_pose)
	var low_head_scale := _get_head_scale("low", direction_key) if apply_overrides else 1.0
	var fast_head_scale := _get_head_scale("fast", direction_key) if apply_overrides else 1.0

	var pose := {
		"heading": h,
		"side": side,
		"near": near,
		"far": far,
		"near_side_sign": near_sign,
		"front_side_sign": front_side_sign,
		"speed_ratio": speed_ratio,
		"fast_pose": fast_weight,
		"wind": wind,
		"frontness": h.y,
		"foot_center": foot_center_low.lerp(foot_center_fast, fast_weight),
		"torso_width": lerpf(torso_width_low, torso_width_fast, fast_weight),
		"hip_width": lerpf(hip_width_low, hip_width_fast, fast_weight),
		"head_scale": lerpf(low_head_scale, fast_head_scale, fast_weight),
		"draw_order": _get_draw_order(draw_pose_name, direction_key) if apply_overrides else EDIT_DRAW_LAYER_KEYS,
	}
	for key in EDIT_JOINT_KEYS:
		var low_point: Vector2 = low_pose[key]
		var high_point: Vector2 = high_pose[key]
		pose[key] = low_point.lerp(high_point, fast_weight)
	var shoulder_near: Vector2 = pose["shoulder_near"]
	var shoulder_far: Vector2 = pose["shoulder_far"]
	var hip_near: Vector2 = pose["hip_near"]
	var hip_far: Vector2 = pose["hip_far"]
	pose["shoulder_center"] = (shoulder_near + shoulder_far) * 0.5
	pose["hip_center"] = (hip_near + hip_far) * 0.5
	return pose


func _blend_flight_poses(first_pose: Dictionary, second_pose: Dictionary, weight: float) -> Dictionary:
	var t := clampf(weight, 0.0, 1.0)
	var first_heading: Vector2 = first_pose["heading"]
	var second_heading: Vector2 = second_pose["heading"]
	var heading := first_heading.lerp(second_heading, t)
	if heading.length_squared() <= 0.0001:
		heading = _heading if _heading.length_squared() > 0.0001 else Vector2.RIGHT
	heading = heading.normalized()
	var side := Vector2(1.0, 0.0)
	var near_sign := signf(heading.x)
	if near_sign == 0.0:
		near_sign = 1.0
	var near := side * near_sign
	var far := -near
	var output_near_side_sign := near_sign
	var first_foot_center: Vector2 = first_pose["foot_center"]
	var second_foot_center: Vector2 = second_pose["foot_center"]
	var chosen_front_pose: Dictionary = second_pose if t >= 0.5 else first_pose
	var chosen_draw_order := _draw_order_for_output_side(chosen_front_pose, output_near_side_sign)
	var chosen_source_near_side_sign := float(chosen_front_pose.get("near_side_sign", near_sign))
	var chosen_front_side_sign := float(chosen_front_pose.get("front_side_sign", chosen_source_near_side_sign))
	var pose := {
		"heading": heading,
		"side": side,
		"near": near,
		"far": far,
		"near_side_sign": output_near_side_sign,
		"front_side_sign": chosen_front_side_sign,
		"speed_ratio": lerpf(float(first_pose.get("speed_ratio", 0.0)), float(second_pose.get("speed_ratio", 0.0)), t),
		"fast_pose": lerpf(float(first_pose.get("fast_pose", 0.0)), float(second_pose.get("fast_pose", 0.0)), t),
		"wind": lerpf(float(first_pose.get("wind", 0.0)), float(second_pose.get("wind", 0.0)), t),
		"frontness": heading.y,
		"foot_center": first_foot_center.lerp(second_foot_center, t),
		"torso_width": lerpf(float(first_pose.get("torso_width", 0.0)), float(second_pose.get("torso_width", 0.0)), t),
		"hip_width": lerpf(float(first_pose.get("hip_width", 0.0)), float(second_pose.get("hip_width", 0.0)), t),
		"head_scale": lerpf(float(first_pose.get("head_scale", 1.0)), float(second_pose.get("head_scale", 1.0)), t),
		"draw_order": _sanitized_draw_order(chosen_draw_order),
	}
	for key in EDIT_JOINT_KEYS:
		var first_point := _pose_joint_for_output_side(first_pose, String(key), output_near_side_sign)
		var second_point := _pose_joint_for_output_side(second_pose, String(key), output_near_side_sign)
		pose[key] = first_point.lerp(second_point, t)
	var shoulder_near: Vector2 = pose["shoulder_near"]
	var shoulder_far: Vector2 = pose["shoulder_far"]
	var hip_near: Vector2 = pose["hip_near"]
	var hip_far: Vector2 = pose["hip_far"]
	pose["shoulder_center"] = (shoulder_near + shoulder_far) * 0.5
	pose["hip_center"] = (hip_near + hip_far) * 0.5
	return pose


func _pose_joint_for_output_side(source_pose: Dictionary, joint_key: String, output_near_side_sign: float) -> Vector2:
	var source_joint_key := _joint_key_for_output_side(source_pose, joint_key, output_near_side_sign)
	var point: Vector2 = source_pose[source_joint_key]
	return point


func _joint_key_for_output_side(source_pose: Dictionary, joint_key: String, output_near_side_sign: float) -> String:
	var source_near_side_sign := 1.0 if float(source_pose.get("near_side_sign", 1.0)) >= 0.0 else -1.0
	var target_near_side_sign := 1.0 if output_near_side_sign >= 0.0 else -1.0
	if is_equal_approx(source_near_side_sign, target_near_side_sign):
		return joint_key
	return _mirror_joint_key(joint_key)


func _draw_order_for_output_side(source_pose: Dictionary, output_near_side_sign: float) -> Array:
	var order := _sanitized_draw_order(source_pose.get("draw_order", EDIT_DRAW_LAYER_KEYS))
	var source_near_side_sign := 1.0 if float(source_pose.get("near_side_sign", 1.0)) >= 0.0 else -1.0
	var target_near_side_sign := 1.0 if output_near_side_sign >= 0.0 else -1.0
	if is_equal_approx(source_near_side_sign, target_near_side_sign):
		return order
	var remapped_order: Array = []
	for layer_key_variant in order:
		remapped_order.append(_mirror_layer_key(String(layer_key_variant)))
	return _sanitized_draw_order(remapped_order)


func _draw_sword(h: Vector2, speed_ratio: float) -> void:
	var back := -h * (78.0 + 14.0 * _boost)
	var front := h * (74.0 + 12.0 * _boost)
	var drop := Vector2(0.0, 68.0 + 4.0 * _boost)
	var width := 5.0 + 3.0 * _boost
	draw_line(back + drop, front + drop, Color(0.08, 0.18, 0.20, 0.84), width + 5.0, true)
	draw_line(back + drop, front + drop, SWORD, width, true)
	draw_line(front + drop, front + h * 22.0 + drop, SWORD_CORE, 2.0 + speed_ratio * 2.0, true)
	var guard_axis := h.rotated(PI * 0.5)
	var guard_center := back + h * 20.0 + drop
	draw_line(guard_center - guard_axis * 8.0, guard_center + guard_axis * 8.0, OUTLINE, 3.0, true)
	draw_line(guard_center - guard_axis * 6.0, guard_center + guard_axis * 6.0, ROBE_TRIM, 1.7, true)
	draw_circle(back + h * 9.0 + drop, 3.0, OUTLINE)
	draw_circle(back + h * 9.0 + drop, 2.0, JADE)
	var glow := Color(0.58, 0.95, 1.0, 0.10 + 0.10 * _boost + 0.08 * _switch_flash)
	draw_line(back - h * 28.0 + drop, front + h * 12.0 + drop, glow, 18.0 + 10.0 * _boost, true)


func _draw_torso(pose: Dictionary) -> void:
	var shoulder_near: Vector2 = pose["shoulder_near"]
	var shoulder_far: Vector2 = pose["shoulder_far"]
	var hip_near: Vector2 = pose["hip_near"]
	var hip_far: Vector2 = pose["hip_far"]
	var shoulder_center: Vector2 = pose["shoulder_center"]
	var hip_center: Vector2 = pose["hip_center"]
	var h: Vector2 = pose["heading"]
	var side: Vector2 = pose["side"]
	var points := PackedVector2Array([
		shoulder_near,
		shoulder_far,
		hip_far,
		hip_near,
	])
	draw_colored_polygon(_expand_polygon(points, 3.5), OUTLINE)
	draw_colored_polygon(points, TORSO)
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, Color(0.58, 0.78, 0.86, 0.86), 1.4, true)
	var robe_drop := Vector2(0.0, 17.0 + 5.0 * clampf(float(pose.get("fast_pose", 0.0)), 0.0, 1.0))
	var skirt_points := PackedVector2Array([
		hip_near,
		hip_far,
		hip_far + robe_drop - side * 3.0 - h * 3.0,
		hip_center + robe_drop + Vector2(0.0, 8.0),
		hip_near + robe_drop + side * 3.0 - h * 3.0,
	])
	draw_colored_polygon(_expand_polygon(skirt_points, 2.6), OUTLINE)
	draw_colored_polygon(skirt_points, ROBE_SHADOW)
	var collar_left := shoulder_center.lerp(shoulder_near, 0.56)
	var collar_right := shoulder_center.lerp(shoulder_far, 0.56)
	var collar_bottom := hip_center + h * 3.0 + Vector2(0.0, -3.0)
	draw_line(collar_left, collar_bottom, ROBE_LIGHT, 3.0, true)
	draw_line(collar_right, collar_bottom, ROBE_LIGHT, 3.0, true)
	draw_line(collar_left, collar_bottom, ROBE_TRIM, 1.2, true)
	draw_line(collar_right, collar_bottom, ROBE_TRIM, 1.2, true)
	draw_line(hip_near, hip_far, OUTLINE, 6.2, true)
	draw_line(hip_near, hip_far, SASH, 3.8, true)
	draw_circle(hip_center + h * 2.0, 3.0, OUTLINE)
	draw_circle(hip_center + h * 2.0, 2.0, JADE)
	draw_line(shoulder_near, shoulder_far, ROBE_TRIM, 1.4, true)


func _draw_body_layer(layer_key: String, pose: Dictionary) -> void:
	match layer_key:
		"far_arm":
			var far_arm_front := _is_front_body_layer(layer_key, pose)
			_draw_robed_arm(pose["shoulder_far"], pose["elbow_far"], pose["wrist_far"], far_arm_front)
		"far_leg":
			var far_leg_front := _is_front_body_layer(layer_key, pose)
			_draw_robed_leg(pose["hip_far"], pose["knee_far"], pose["ankle_far"], far_leg_front)
		"torso":
			_draw_torso(pose)
		"head":
			_draw_head(pose)
		"near_leg":
			var near_leg_front := _is_front_body_layer(layer_key, pose)
			_draw_robed_leg(pose["hip_near"], pose["knee_near"], pose["ankle_near"], near_leg_front)
		"near_arm":
			var near_arm_front := _is_front_body_layer(layer_key, pose)
			_draw_robed_arm(pose["shoulder_near"], pose["elbow_near"], pose["wrist_near"], near_arm_front)


func _draw_robed_arm(shoulder: Vector2, elbow: Vector2, wrist: Vector2, is_front: bool) -> void:
	var alpha := 1.0 if is_front else 0.56
	_draw_capsule(shoulder, elbow, 12.5 if is_front else 11.0, UPPER_ARM, alpha)
	_draw_capsule(elbow, wrist, 10.5 if is_front else 9.0, FOREARM, alpha)
	_draw_sleeve_cuff(elbow, wrist, alpha)
	var fold_dir := (wrist - shoulder)
	if fold_dir.length_squared() > 0.0001:
		var normal := fold_dir.normalized().rotated(PI * 0.5)
		var fold_start := elbow.lerp(wrist, 0.18)
		var fold_end := elbow.lerp(wrist, 0.76)
		draw_line(fold_start + normal * 2.0, fold_end + normal * 2.0, Color(0.96, 1.0, 0.94, 0.24 * alpha), 1.2, true)


func _draw_robed_leg(hip: Vector2, knee: Vector2, ankle: Vector2, is_front: bool) -> void:
	var alpha := 1.0 if is_front else 0.58
	_draw_capsule(hip, knee, 15.0 if is_front else 13.8, THIGH, alpha)
	_draw_capsule(knee, ankle, 12.0 if is_front else 10.8, CALF, alpha)
	var leg_dir := ankle - knee
	if leg_dir.length_squared() > 0.0001:
		var boot_top := knee.lerp(ankle, 0.58)
		_draw_capsule(boot_top, ankle, 10.2 if is_front else 9.2, BOOT, alpha)
	_draw_boot_tip(knee, ankle, alpha)


func _draw_sleeve_cuff(elbow: Vector2, wrist: Vector2, alpha: float) -> void:
	var dir := wrist - elbow
	if dir.length_squared() <= 0.0001:
		return
	var cuff_center := elbow.lerp(wrist, 0.82)
	var normal := dir.normalized().rotated(PI * 0.5)
	draw_line(cuff_center - normal * 5.0, cuff_center + normal * 5.0, OUTLINE, 4.2, true)
	draw_line(cuff_center - normal * 4.2, cuff_center + normal * 4.2, ROBE_TRIM, 2.0 * alpha, true)


func _draw_boot_tip(knee: Vector2, ankle: Vector2, alpha: float) -> void:
	var dir := ankle - knee
	if dir.length_squared() <= 0.0001:
		return
	var forward := dir.normalized()
	var normal := forward.rotated(PI * 0.5)
	var boot_tip := PackedVector2Array([
		ankle + forward * 7.0,
		ankle - forward * 2.0 + normal * 4.2,
		ankle - forward * 4.0 - normal * 3.4,
	])
	draw_colored_polygon(_expand_polygon(boot_tip, 1.5), OUTLINE)
	var boot_color := BOOT
	boot_color.a *= alpha
	draw_colored_polygon(boot_tip, boot_color)


func _is_front_body_layer(layer_key: String, pose: Dictionary) -> bool:
	var near_side_sign := 1.0 if float(pose.get("near_side_sign", 1.0)) >= 0.0 else -1.0
	var front_side_sign := 1.0 if float(pose.get("front_side_sign", near_side_sign)) >= 0.0 else -1.0
	match layer_key:
		"near_arm", "near_leg":
			return is_equal_approx(front_side_sign, near_side_sign)
		"far_arm", "far_leg":
			return not is_equal_approx(front_side_sign, near_side_sign)
		_:
			return true


func _front_side_adjusted_draw_order(value: Variant, pose: Dictionary) -> Array:
	var order := _sanitized_draw_order(value)
	var near_side_sign := 1.0 if float(pose.get("near_side_sign", 1.0)) >= 0.0 else -1.0
	var front_side_sign := 1.0 if float(pose.get("front_side_sign", near_side_sign)) >= 0.0 else -1.0
	var near_is_front := is_equal_approx(front_side_sign, near_side_sign)
	_move_layer_after(order, "near_arm" if near_is_front else "far_arm", "far_arm" if near_is_front else "near_arm")
	_move_layer_after(order, "near_leg" if near_is_front else "far_leg", "far_leg" if near_is_front else "near_leg")
	if float(pose.get("frontness", 0.0)) > 0.42:
		for body_layer in ["torso", "far_leg", "near_leg", "far_arm", "near_arm"]:
			_move_layer_after(order, "head", String(body_layer))
	return order


func _move_layer_after(order: Array, moved_layer: String, anchor_layer: String) -> void:
	var moved_index := order.find(moved_layer)
	var anchor_index := order.find(anchor_layer)
	if moved_index < 0 or anchor_index < 0 or moved_index > anchor_index:
		return
	order.remove_at(moved_index)
	anchor_index = order.find(anchor_layer)
	order.insert(clampi(anchor_index + 1, 0, order.size()), moved_layer)


func _draw_head(pose: Dictionary) -> void:
	var head_center: Vector2 = pose["head_center"]
	var h: Vector2 = pose["heading"]
	var side: Vector2 = pose["side"]
	var head_scale: float = pose.get("head_scale", 1.0)
	var radius := (17.0 + absf(h.y) * 3.0) * head_scale
	draw_circle(head_center, radius + 2.5, OUTLINE)
	draw_circle(head_center, radius, HEAD)
	var frontness: float = pose["frontness"]
	if frontness > 0.42:
		draw_line(head_center - side * 8.0 * head_scale - h * 3.0 * head_scale, head_center + side * 8.0 * head_scale - h * 3.0 * head_scale, ROBE_TRIM, 1.8 * head_scale, true)
		draw_circle(head_center + side * 5.5 * head_scale + h * 3.0 * head_scale, 2.1 * head_scale, FACE_DARK)
		draw_circle(head_center - side * 5.5 * head_scale + h * 3.0 * head_scale, 2.1 * head_scale, FACE_DARK)
		draw_line(head_center + h * 5.0 * head_scale, head_center + h * 10.0 * head_scale, Color(0.42, 0.27, 0.16, 0.9), 1.6 * head_scale, true)
		draw_circle(head_center - h * 2.0 * head_scale, 2.0 * head_scale, OUTLINE)
		draw_circle(head_center - h * 2.0 * head_scale, 1.2 * head_scale, JADE)
	elif frontness < -0.42:
		draw_line(head_center - side * 8.0 * head_scale + h * 2.0 * head_scale, head_center + side * 8.0 * head_scale + h * 2.0 * head_scale, ROBE_TRIM, 1.8 * head_scale, true)
		draw_circle(head_center - h * 5.0 * head_scale, 2.0 * head_scale, JADE)
	else:
		draw_line(head_center - h * 2.0 * head_scale - side * 5.5 * head_scale, head_center - h * 2.0 * head_scale + side * 4.5 * head_scale, ROBE_TRIM, 1.6 * head_scale, true)
		draw_circle(head_center + h * 7.5 * head_scale, 2.2 * head_scale, FACE_DARK)
		draw_line(head_center + h * 7.0 * head_scale, head_center + h * 14.0 * head_scale + side * 2.0 * head_scale, Color(0.42, 0.27, 0.16, 0.9), 1.8 * head_scale, true)
		draw_circle(head_center + h * 1.0 * head_scale, 1.5 * head_scale, JADE)
	if _switch_flash > 0.0:
		draw_arc(head_center, radius + 8.0 + _switch_flash * 8.0, 0.0, TAU, 32, Color(0.72, 1.0, 1.0, 0.16 * _switch_flash), 2.0, true)


func _draw_capsule(a: Vector2, b: Vector2, width: float, color: Color, alpha: float) -> void:
	var outline_width := width + 4.0
	draw_line(a, b, OUTLINE, outline_width, true)
	draw_circle(a, outline_width * 0.5, OUTLINE)
	draw_circle(b, outline_width * 0.5, OUTLINE)
	var c := color
	c.a *= alpha
	draw_line(a, b, c, width, true)
	draw_circle(a, width * 0.5, c)
	draw_circle(b, width * 0.5, c)


func _draw_joints(pose: Dictionary) -> void:
	for key in EDIT_JOINT_KEYS:
		var point: Vector2 = pose[key]
		var selected: bool = _editor_active and String(key) == _editor_selected_joint
		draw_circle(point, 7.0 if selected else 4.0, OUTLINE)
		draw_circle(point, 4.4 if selected else 2.6, Color(1.0, 0.92, 0.34, 1.0) if selected else JOINT)
	if _editor_active:
		var selected_point: Vector2 = pose[_editor_selected_joint]
		draw_arc(selected_point, 12.0, 0.0, TAU, 28, Color(0.45, 1.0, 1.0, 0.72), 1.8, true)


func _expand_polygon(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= maxf(float(points.size()), 1.0)
	var out := PackedVector2Array()
	for point in points:
		var dir := point - center
		if dir.length_squared() > 0.0001:
			out.append(point + dir.normalized() * amount)
		else:
			out.append(point)
	return out


func _direction_vector(index: int) -> Vector2:
	var dir: Vector2 = DIR_VECTORS[clampi(index, 0, DIR_VECTORS.size() - 1)]
	return dir.normalized()


func _direction_key(index: int) -> String:
	return String(EDIT_DIRECTION_KEYS[clampi(index, 0, EDIT_DIRECTION_KEYS.size() - 1)])


func _is_edit_cardinal_direction_index(index: int) -> bool:
	return EDIT_CARDINAL_DIRECTION_INDICES.has(clampi(index, 0, EDIT_DIRECTION_KEYS.size() - 1))


func _nearest_edit_cardinal_direction_index(heading: Vector2) -> int:
	var safe_heading := heading
	if safe_heading.length_squared() <= 0.0001:
		safe_heading = _direction_vector(_direction_index)
	else:
		safe_heading = safe_heading.normalized()
	var best_index := int(EDIT_CARDINAL_DIRECTION_INDICES[0])
	var best_dot := -9999.0
	for index_variant in EDIT_CARDINAL_DIRECTION_INDICES:
		var direction_index := int(index_variant)
		var dot_value := safe_heading.dot(_direction_vector(direction_index))
		if dot_value > best_dot:
			best_dot = dot_value
			best_index = direction_index
	return best_index


func _canonical_edit_direction_index(index: int) -> int:
	var safe_index := clampi(index, 0, EDIT_DIRECTION_KEYS.size() - 1)
	if _is_edit_cardinal_direction_index(safe_index):
		return safe_index
	return _nearest_edit_cardinal_direction_index(_direction_vector(safe_index))


func _editor_direction_option_index_for_direction(direction_index: int) -> int:
	var canonical_index := _canonical_edit_direction_index(direction_index)
	for option_index in range(EDIT_CARDINAL_DIRECTION_INDICES.size()):
		if int(EDIT_CARDINAL_DIRECTION_INDICES[option_index]) == canonical_index:
			return option_index
	return 0


func _cardinal_blend_for_heading(heading: Vector2) -> Dictionary:
	var safe_heading := heading
	if safe_heading.length_squared() <= 0.0001:
		safe_heading = _direction_vector(_direction_index)
	else:
		safe_heading = safe_heading.normalized()
	var segment_size := PI * 0.5
	var segment_float := fposmod(safe_heading.angle(), TAU) / segment_size
	var segment_floor := floorf(segment_float)
	var segment_index := int(segment_floor) % CARDINAL_BLEND_DIRECTION_INDICES.size()
	var next_segment_index := (segment_index + 1) % CARDINAL_BLEND_DIRECTION_INDICES.size()
	var raw_weight := segment_float - segment_floor
	var smooth_weight := smoothstep(0.0, 1.0, raw_weight)
	return {
		"from_index": int(CARDINAL_BLEND_DIRECTION_INDICES[segment_index]),
		"to_index": int(CARDINAL_BLEND_DIRECTION_INDICES[next_segment_index]),
		"weight": smooth_weight,
	}


func _toggle_editor() -> void:
	_editor_active = not _editor_active
	if _editor_active:
		_editor_direction_index = _nearest_edit_cardinal_direction_index(_heading)
		_editor_pose = "fast" if _velocity.length() > 520.0 or _boost > 0.5 else "low"
	if _editor_panel != null:
		_fit_editor_panel_to_viewport()
		_editor_panel.visible = _editor_active
	_refresh_editor_controls()
	queue_redraw()


func _editor_panel_size() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var max_height := maxf(viewport_size.y - 116.0, 420.0)
	return Vector2(392.0, minf(max_height, 780.0))


func _editor_scroll_size() -> Vector2:
	var panel_size := _editor_panel_size()
	return Vector2(panel_size.x - 26.0, maxf(panel_size.y - 62.0, 340.0))


func _fit_editor_panel_to_viewport() -> void:
	if _editor_panel == null:
		return
	var panel_size := _editor_panel_size()
	_editor_panel.custom_minimum_size = panel_size
	_editor_panel.size = panel_size


func _create_editor_panel() -> void:
	_editor_layer = CanvasLayer.new()
	_editor_layer.name = "V4SkeletonPoseEditorLayer"
	_editor_layer.layer = 92
	add_child(_editor_layer)

	_editor_panel = PanelContainer.new()
	_editor_panel.name = "V4SkeletonPoseEditorPanel"
	_editor_panel.position = Vector2(24.0, 92.0)
	_editor_panel.custom_minimum_size = _editor_panel_size()
	_editor_panel.size = _editor_panel_size()
	_editor_panel.visible = false
	_editor_layer.add_child(_editor_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	_editor_panel.add_child(root)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	root.add_child(title_row)

	var title := Label.new()
	title.text = "V4 四向骨骼姿态编辑  F4"
	title.add_theme_font_size_override("font_size", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var top_save_button := Button.new()
	top_save_button.text = "保存 JSON"
	top_save_button.pressed.connect(Callable(self, "_on_editor_save_pressed"))
	title_row.add_child(top_save_button)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = _editor_scroll_size()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	root = content

	_editor_pose_option = OptionButton.new()
	_editor_pose_option.add_item("低速 low", 0)
	_editor_pose_option.add_item("高速 fast", 1)
	_editor_pose_option.item_selected.connect(Callable(self, "_on_editor_pose_selected"))
	root.add_child(_make_editor_row("姿态", _editor_pose_option))

	_editor_direction_option = OptionButton.new()
	for index in range(EDIT_DIRECTION_LABELS.size()):
		_editor_direction_option.add_item(String(EDIT_DIRECTION_LABELS[index]), int(EDIT_CARDINAL_DIRECTION_INDICES[index]))
	_editor_direction_option.item_selected.connect(Callable(self, "_on_editor_direction_selected"))
	root.add_child(_make_editor_row("主方向", _editor_direction_option))

	_editor_front_side_option = OptionButton.new()
	_editor_front_side_option.add_item("默认前侧", 0)
	_editor_front_side_option.add_item("右侧骨骼在前", 1)
	_editor_front_side_option.add_item("左侧骨骼在前", 2)
	_editor_front_side_option.item_selected.connect(Callable(self, "_on_editor_front_side_selected"))
	root.add_child(_make_editor_row("前景侧", _editor_front_side_option))

	_editor_joint_option = OptionButton.new()
	for index in range(EDIT_JOINT_KEYS.size()):
		_editor_joint_option.add_item(String(EDIT_JOINT_KEYS[index]), index)
	_editor_joint_option.item_selected.connect(Callable(self, "_on_editor_joint_selected"))
	root.add_child(_make_editor_row("关节", _editor_joint_option))

	_editor_lock_bone_checkbox = CheckBox.new()
	_editor_lock_bone_checkbox.text = "锁骨长"
	_editor_lock_bone_checkbox.button_pressed = _editor_lock_bone_length
	_editor_lock_bone_checkbox.toggled.connect(Callable(self, "_on_editor_lock_bone_toggled"))
	root.add_child(_editor_lock_bone_checkbox)

	_editor_bone_length_option = OptionButton.new()
	for index in range(EDIT_BONE_LENGTH_KEYS.size()):
		_editor_bone_length_option.add_item("%s %s" % [
			String(EDIT_BONE_LENGTH_KEYS[index]),
			String(EDIT_BONE_LENGTH_LABELS[index]),
		], index)
	_editor_bone_length_option.item_selected.connect(Callable(self, "_on_editor_bone_length_selected"))
	root.add_child(_make_editor_row("骨段", _editor_bone_length_option))

	_editor_bone_length_spin = _make_editor_spin(6.0, 180.0, 0.5)
	_editor_bone_length_spin.value_changed.connect(Callable(self, "_on_editor_bone_length_changed"))
	root.add_child(_make_editor_row("标准骨长", _editor_bone_length_spin))

	_editor_offset_x_spin = _make_editor_spin(-240.0, 240.0, 0.5)
	_editor_offset_x_spin.value_changed.connect(Callable(self, "_on_editor_offset_x_changed"))
	root.add_child(_make_editor_row("X 偏移", _editor_offset_x_spin))

	_editor_offset_y_spin = _make_editor_spin(-240.0, 240.0, 0.5)
	_editor_offset_y_spin.value_changed.connect(Callable(self, "_on_editor_offset_y_changed"))
	root.add_child(_make_editor_row("Y 偏移", _editor_offset_y_spin))

	_editor_head_scale_spin = _make_editor_spin(0.45, 1.80, 0.02)
	_editor_head_scale_spin.value_changed.connect(Callable(self, "_on_editor_head_scale_changed"))
	root.add_child(_make_editor_row("头大小", _editor_head_scale_spin))

	_editor_layer_option = OptionButton.new()
	for index in range(EDIT_DRAW_LAYER_KEYS.size()):
		_editor_layer_option.add_item("%s %s" % [
			String(EDIT_DRAW_LAYER_KEYS[index]),
			String(EDIT_DRAW_LAYER_LABELS[index]),
		], index)
	_editor_layer_option.item_selected.connect(Callable(self, "_on_editor_layer_selected"))
	root.add_child(_make_editor_row("层级", _editor_layer_option))

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 6)
	root.add_child(button_row)

	var reset_joint_button := Button.new()
	reset_joint_button.text = "重置点"
	reset_joint_button.pressed.connect(Callable(self, "_on_editor_reset_joint_pressed"))
	button_row.add_child(reset_joint_button)

	var reset_direction_button := Button.new()
	reset_direction_button.text = "重置方向"
	reset_direction_button.pressed.connect(Callable(self, "_on_editor_reset_direction_pressed"))
	button_row.add_child(reset_direction_button)

	var fit_bone_button := Button.new()
	fit_bone_button.text = "校正骨长"
	fit_bone_button.pressed.connect(Callable(self, "_on_editor_fit_bone_length_pressed"))
	button_row.add_child(fit_bone_button)

	var bone_length_row := HBoxContainer.new()
	bone_length_row.add_theme_constant_override("separation", 6)
	root.add_child(bone_length_row)

	var capture_bone_button := Button.new()
	capture_bone_button.text = "取当前骨长"
	capture_bone_button.pressed.connect(Callable(self, "_on_editor_capture_bone_length_pressed"))
	bone_length_row.add_child(capture_bone_button)

	var reset_bone_button := Button.new()
	reset_bone_button.text = "重置骨长"
	reset_bone_button.pressed.connect(Callable(self, "_on_editor_reset_bone_length_pressed"))
	bone_length_row.add_child(reset_bone_button)

	var layer_row := HBoxContainer.new()
	layer_row.add_theme_constant_override("separation", 6)
	root.add_child(layer_row)

	var layer_back_button := Button.new()
	layer_back_button.text = "后移"
	layer_back_button.pressed.connect(Callable(self, "_on_editor_layer_back_pressed"))
	layer_row.add_child(layer_back_button)

	var layer_front_button := Button.new()
	layer_front_button.text = "前移"
	layer_front_button.pressed.connect(Callable(self, "_on_editor_layer_front_pressed"))
	layer_row.add_child(layer_front_button)

	var layer_top_button := Button.new()
	layer_top_button.text = "置顶"
	layer_top_button.pressed.connect(Callable(self, "_on_editor_layer_top_pressed"))
	layer_row.add_child(layer_top_button)

	var batch_row := HBoxContainer.new()
	batch_row.add_theme_constant_override("separation", 6)
	root.add_child(batch_row)

	var copy_opposite_button := Button.new()
	copy_opposite_button.text = "复制对向"
	copy_opposite_button.pressed.connect(Callable(self, "_on_editor_copy_opposite_pressed"))
	batch_row.add_child(copy_opposite_button)

	var mirror_horizontal_button := Button.new()
	mirror_horizontal_button.text = "左右镜像"
	mirror_horizontal_button.pressed.connect(Callable(self, "_on_editor_mirror_horizontal_pressed"))
	batch_row.add_child(mirror_horizontal_button)

	var apply_all_button := Button.new()
	apply_all_button.text = "应用全部"
	apply_all_button.pressed.connect(Callable(self, "_on_editor_apply_all_pressed"))
	batch_row.add_child(apply_all_button)

	var pose_json_row := HBoxContainer.new()
	pose_json_row.add_theme_constant_override("separation", 6)
	root.add_child(pose_json_row)

	var copy_pose_json_button := Button.new()
	copy_pose_json_button.text = "复制姿态JSON"
	copy_pose_json_button.pressed.connect(Callable(self, "_on_editor_copy_pose_json_pressed"))
	pose_json_row.add_child(copy_pose_json_button)

	var import_pose_json_button := Button.new()
	import_pose_json_button.text = "导入姿态JSON"
	import_pose_json_button.pressed.connect(Callable(self, "_on_editor_import_pose_json_pressed"))
	pose_json_row.add_child(import_pose_json_button)

	_editor_status_label = Label.new()
	_editor_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_editor_status_label.add_theme_font_size_override("font_size", 12)
	root.add_child(_editor_status_label)

	_fit_editor_panel_to_viewport()
	_refresh_editor_controls()


func _make_editor_row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(74.0, 0.0)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


func _make_editor_spin(min_value: float, max_value: float, step: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.allow_greater = true
	spin.allow_lesser = true
	return spin


func _load_pose_overrides() -> void:
	_pose_overrides = {"low": {}, "fast": {}}
	_bone_lengths = {}
	if not FileAccess.file_exists(POSE_OVERRIDE_PATH):
		return
	var text := FileAccess.get_file_as_string(POSE_OVERRIDE_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_warning("Invalid V4 skeleton pose override JSON: %s" % POSE_OVERRIDE_PATH)
		return
	var data: Dictionary = parsed
	var bone_data: Variant = data.get("bone_lengths", {})
	if bone_data is Dictionary:
		for key_variant in Dictionary(bone_data).keys():
			var key := String(key_variant)
			if EDIT_BONE_LENGTH_KEYS.has(key):
				_bone_lengths[key] = float(Dictionary(bone_data)[key_variant])
	var poses: Variant = data.get("poses", data)
	if not (poses is Dictionary):
		return
	for pose_name in ["low", "fast"]:
		var pose_data: Variant = Dictionary(poses).get(pose_name, {})
		_pose_overrides[pose_name] = pose_data if pose_data is Dictionary else {}


func _save_pose_overrides() -> void:
	_cleanup_pose_overrides()
	var global_path := ProjectSettings.globalize_path(POSE_OVERRIDE_PATH)
	var global_dir := ProjectSettings.globalize_path(POSE_OVERRIDE_PATH.get_base_dir())
	DirAccess.make_dir_recursive_absolute(global_dir)
	var file := FileAccess.open(global_path, FileAccess.WRITE)
	if file == null:
		_set_editor_status("保存失败: %s" % error_string(FileAccess.get_open_error()))
		return
	var data := {
		"bone_lengths": _bone_lengths,
		"format_version": 1,
		"poses": _pose_overrides,
	}
	file.store_string(JSON.stringify(data, "\t"))
	_set_editor_status("已保存 %s" % POSE_OVERRIDE_PATH)


func _apply_pose_overrides(pose_name: String, direction_key: String, pose: Dictionary) -> void:
	var direction_data := _get_direction_overrides(pose_name, direction_key, false)
	for key in direction_data.keys():
		if not pose.has(key):
			continue
		var point: Vector2 = pose[key]
		pose[key] = point + _variant_to_vector2(direction_data[key])


func _get_direction_overrides(pose_name: String, direction_key: String, create := false) -> Dictionary:
	if not _pose_overrides.has(pose_name) or not (_pose_overrides[pose_name] is Dictionary):
		if not create:
			return {}
		_pose_overrides[pose_name] = {}
	var pose_data: Dictionary = _pose_overrides[pose_name]
	if not pose_data.has(direction_key) or not (pose_data[direction_key] is Dictionary):
		if not create:
			return {}
		pose_data[direction_key] = {}
	return pose_data[direction_key]


func _get_head_scale(pose_name: String, direction_key: String) -> float:
	var direction_data := _get_direction_overrides(pose_name, direction_key, false)
	return clampf(float(direction_data.get("_head_scale", 1.0)), 0.35, 2.0)


func _default_front_side_sign_for_direction_index(direction_index: int) -> float:
	var h := _direction_vector(direction_index)
	var sign_value := signf(h.x)
	return 1.0 if sign_value == 0.0 else sign_value


func _get_front_side_sign(pose_name: String, direction_key: String, default_sign: float = 1.0) -> float:
	var direction_data := _get_direction_overrides(pose_name, direction_key, false)
	if not direction_data.has("_front_side_sign"):
		return 1.0 if default_sign >= 0.0 else -1.0
	return 1.0 if float(direction_data.get("_front_side_sign", default_sign)) >= 0.0 else -1.0


func _has_current_front_side_override() -> bool:
	var direction_data := _get_direction_overrides(_editor_pose, _direction_key(_editor_direction_index), false)
	return direction_data.has("_front_side_sign")


func _current_front_side_sign() -> float:
	var default_sign := _default_front_side_sign_for_direction_index(_editor_direction_index)
	return _get_front_side_sign(_editor_pose, _direction_key(_editor_direction_index), default_sign)


func _current_front_side_option_id() -> int:
	if not _has_current_front_side_override():
		return 0
	return 1 if _current_front_side_sign() >= 0.0 else 2


func _set_current_front_side_option(option_id: int) -> void:
	var direction_key := _direction_key(_editor_direction_index)
	var direction_data := _get_direction_overrides(_editor_pose, direction_key, true)
	if option_id == 0:
		direction_data.erase("_front_side_sign")
	else:
		direction_data["_front_side_sign"] = -1.0 if option_id == 2 else 1.0
	_cleanup_empty_direction(_editor_pose, direction_key)
	_refresh_editor_controls()
	queue_redraw()


func _front_side_label(sign_value: float) -> String:
	return "右侧前" if sign_value >= 0.0 else "左侧前"


func _current_head_scale() -> float:
	return _get_head_scale(_editor_pose, _direction_key(_editor_direction_index))


func _set_current_head_scale(scale: float) -> void:
	var direction_key := _direction_key(_editor_direction_index)
	var direction_data := _get_direction_overrides(_editor_pose, direction_key, true)
	var safe_scale := clampf(scale, 0.35, 2.0)
	if absf(safe_scale - 1.0) <= 0.001:
		direction_data.erase("_head_scale")
	else:
		direction_data["_head_scale"] = roundf(safe_scale * 100.0) / 100.0
	_cleanup_empty_direction(_editor_pose, direction_key)
	_refresh_editor_controls()
	queue_redraw()


func _get_draw_order(pose_name: String, direction_key: String) -> Array:
	var direction_data := _get_direction_overrides(pose_name, direction_key, false)
	return _sanitized_draw_order(direction_data.get("_draw_order", EDIT_DRAW_LAYER_KEYS))


func _current_draw_order() -> Array:
	return _get_draw_order(_editor_pose, _direction_key(_editor_direction_index))


func _set_current_draw_order(order: Array) -> void:
	var direction_key := _direction_key(_editor_direction_index)
	var direction_data := _get_direction_overrides(_editor_pose, direction_key, true)
	var safe_order := _sanitized_draw_order(order)
	if _string_arrays_equal(safe_order, EDIT_DRAW_LAYER_KEYS):
		direction_data.erase("_draw_order")
	else:
		direction_data["_draw_order"] = safe_order
	_cleanup_empty_direction(_editor_pose, direction_key)
	_refresh_editor_controls()
	queue_redraw()


func _sanitized_draw_order(value: Variant) -> Array:
	var order: Array = []
	if value is Array:
		for layer_variant in value:
			var layer_key := String(layer_variant)
			if EDIT_DRAW_LAYER_KEYS.has(layer_key) and not order.has(layer_key):
				order.append(layer_key)
	for layer_key in EDIT_DRAW_LAYER_KEYS:
		if not order.has(layer_key):
			order.append(layer_key)
	return order


func _string_arrays_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for index in range(a.size()):
		if String(a[index]) != String(b[index]):
			return false
	return true


func _move_selected_layer(delta: int) -> void:
	var order := _current_draw_order()
	var index := order.find(_editor_selected_layer)
	if index < 0:
		return
	var next_index := clampi(index + delta, 0, order.size() - 1)
	if next_index == index:
		return
	order.remove_at(index)
	order.insert(next_index, _editor_selected_layer)
	_set_current_draw_order(order)


func _move_selected_layer_to(index: int) -> void:
	var order := _current_draw_order()
	var current_index := order.find(_editor_selected_layer)
	if current_index < 0:
		return
	order.remove_at(current_index)
	order.insert(clampi(index, 0, order.size()), _editor_selected_layer)
	_set_current_draw_order(order)


func _bone_parent_for_joint(joint_key: String) -> String:
	match joint_key:
		"shoulder_near":
			return "hip_near"
		"shoulder_far":
			return "hip_far"
		"hip_near":
			return "shoulder_near"
		"hip_far":
			return "shoulder_far"
		"elbow_near":
			return "shoulder_near"
		"elbow_far":
			return "shoulder_far"
		"wrist_near":
			return "elbow_near"
		"wrist_far":
			return "elbow_far"
		"knee_near":
			return "hip_near"
		"knee_far":
			return "hip_far"
		"ankle_near":
			return "knee_near"
		"ankle_far":
			return "knee_far"
		_:
			return ""


func _bone_length_key_for_joint(joint_key: String) -> String:
	match joint_key:
		"shoulder_near", "shoulder_far", "hip_near", "hip_far":
			return "torso"
		"elbow_near", "elbow_far":
			return "upper_arm"
		"wrist_near", "wrist_far":
			return "forearm"
		"knee_near", "knee_far":
			return "thigh"
		"ankle_near", "ankle_far":
			return "calf"
		_:
			return ""


func _representative_joint_for_bone_length(bone_key: String) -> String:
	match bone_key:
		"torso":
			return "shoulder_near"
		"upper_arm":
			return "elbow_near"
		"forearm":
			return "wrist_near"
		"thigh":
			return "knee_near"
		"calf":
			return "ankle_near"
		_:
			return ""


func _default_bone_length_for_key(bone_key: String) -> float:
	var joint_key := _representative_joint_for_bone_length(bone_key)
	if joint_key.is_empty():
		return 0.0
	return _base_bone_length_for_joint(joint_key)


func _base_bone_length_for_joint(joint_key: String) -> float:
	var parent_key := _bone_parent_for_joint(joint_key)
	if parent_key.is_empty():
		return 0.0
	var base_pose := _build_flight_pose(false)
	var child: Vector2 = base_pose[joint_key]
	var parent: Vector2 = base_pose[parent_key]
	return child.distance_to(parent)


func _bone_length_for_key(bone_key: String) -> float:
	if _bone_lengths.has(bone_key):
		return clampf(float(_bone_lengths[bone_key]), 1.0, 300.0)
	return _default_bone_length_for_key(bone_key)


func _set_bone_length_for_key(bone_key: String, length: float) -> void:
	if not EDIT_BONE_LENGTH_KEYS.has(bone_key):
		return
	_bone_lengths[bone_key] = roundf(clampf(length, 1.0, 300.0) * 100.0) / 100.0
	_refresh_editor_controls()
	queue_redraw()


func _reset_bone_length_for_key(bone_key: String) -> void:
	_bone_lengths.erase(bone_key)
	_refresh_editor_controls()
	queue_redraw()


func _actual_bone_length_for_key(bone_key: String) -> float:
	var joint_key := _editor_selected_joint
	if _bone_length_key_for_joint(joint_key) != bone_key:
		joint_key = _representative_joint_for_bone_length(bone_key)
	var parent_key := _bone_parent_for_joint(joint_key)
	if parent_key.is_empty():
		return 0.0
	var pose := _build_flight_pose(true)
	var child: Vector2 = pose[joint_key]
	var parent: Vector2 = pose[parent_key]
	return child.distance_to(parent)


func _target_bone_length(joint_key: String) -> float:
	var bone_key := _bone_length_key_for_joint(joint_key)
	if bone_key.is_empty():
		return 0.0
	return _bone_length_for_key(bone_key)


func _constrain_joint_offset_to_bone_length(joint_key: String, offset: Vector2) -> Vector2:
	var parent_key := _bone_parent_for_joint(joint_key)
	if parent_key.is_empty():
		return offset
	var target_length := _target_bone_length(joint_key)
	if target_length <= 0.001:
		return offset
	var base_pose := _build_flight_pose(false)
	var current_pose := _build_flight_pose(true)
	var base_child: Vector2 = base_pose[joint_key]
	var parent: Vector2 = current_pose[parent_key]
	var candidate := base_child + offset
	var direction := candidate - parent
	if direction.length_squared() <= 0.0001:
		var fallback_child: Vector2 = current_pose[joint_key]
		direction = fallback_child - parent
	if direction.length_squared() <= 0.0001:
		var base_parent: Vector2 = base_pose[parent_key]
		direction = base_child - base_parent
	if direction.length_squared() <= 0.0001:
		return offset
	var constrained_child := parent + direction.normalized() * target_length
	return constrained_child - base_child


func _fit_selected_joint_to_bone_length() -> bool:
	if _bone_parent_for_joint(_editor_selected_joint).is_empty():
		_set_editor_status("%s 没有可锁定的父骨骼" % _editor_selected_joint)
		return false
	var constrained_offset := _constrain_joint_offset_to_bone_length(_editor_selected_joint, _current_joint_offset())
	var old_lock := _editor_lock_bone_length
	_editor_lock_bone_length = false
	_set_selected_joint_offset(constrained_offset)
	_editor_lock_bone_length = old_lock
	_refresh_editor_controls()
	var target_length := _target_bone_length(_editor_selected_joint)
	_set_editor_status("%s 骨长 %.1f 已校正" % [_editor_selected_joint, target_length])
	return true


func _variant_to_vector2(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	if value is Dictionary:
		return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))
	return Vector2.ZERO


func _offset_to_array(offset: Vector2) -> Array:
	return [
		roundf(offset.x * 100.0) / 100.0,
		roundf(offset.y * 100.0) / 100.0,
	]


func _copy_current_pose_json_to_clipboard() -> void:
	var pose := _build_flight_pose(true)
	var joints: Dictionary = {}
	for key in EDIT_JOINT_KEYS:
		var point: Vector2 = pose[key]
		joints[key] = _offset_to_array(point)
	var data := {
		"format_version": 1,
		"kind": "v4_skeleton_resolved_pose",
		"source_pose": _editor_pose,
		"source_direction": _direction_key(_editor_direction_index),
		"joints": joints,
		"head_scale": _current_head_scale(),
		"front_side_sign": _current_front_side_sign(),
		"draw_order": _current_draw_order(),
		"bone_lengths": _bone_lengths,
	}
	DisplayServer.clipboard_set(JSON.stringify(data, "\t"))
	_set_editor_status("已复制 %s / %s 的姿态 JSON" % [_editor_pose, _direction_key(_editor_direction_index)])


func _import_pose_json_from_clipboard() -> void:
	var text := DisplayServer.clipboard_get()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		_set_editor_status("剪贴板不是有效姿态 JSON")
		return
	var data: Dictionary = parsed
	var joints_variant: Variant = data.get("joints", {})
	if not (joints_variant is Dictionary):
		_set_editor_status("姿态 JSON 缺少 joints")
		return
	var joints: Dictionary = joints_variant
	var direction_key := _direction_key(_editor_direction_index)
	var direction_data := _get_direction_overrides(_editor_pose, direction_key, true)
	var base_pose := _build_flight_pose(false)
	for key in EDIT_JOINT_KEYS:
		if not joints.has(key):
			continue
		var target_point := _variant_to_vector2(joints[key])
		var base_point: Vector2 = base_pose[key]
		var offset := target_point - base_point
		if offset.length_squared() <= 0.0001:
			direction_data.erase(key)
		else:
			direction_data[key] = _offset_to_array(offset)
	if data.has("head_scale"):
		var head_scale := clampf(float(data["head_scale"]), 0.35, 2.0)
		if absf(head_scale - 1.0) <= 0.001:
			direction_data.erase("_head_scale")
		else:
			direction_data["_head_scale"] = roundf(head_scale * 100.0) / 100.0
	if data.has("front_side_sign"):
		direction_data["_front_side_sign"] = 1.0 if float(data["front_side_sign"]) >= 0.0 else -1.0
	if data.has("draw_order"):
		var draw_order := _sanitized_draw_order(data["draw_order"])
		if _string_arrays_equal(draw_order, EDIT_DRAW_LAYER_KEYS):
			direction_data.erase("_draw_order")
		else:
			direction_data["_draw_order"] = draw_order
	if data.has("bone_lengths") and data["bone_lengths"] is Dictionary:
		for bone_key_variant in Dictionary(data["bone_lengths"]).keys():
			var bone_key := String(bone_key_variant)
			if EDIT_BONE_LENGTH_KEYS.has(bone_key):
				_bone_lengths[bone_key] = roundf(clampf(float(Dictionary(data["bone_lengths"])[bone_key_variant]), 1.0, 300.0) * 100.0) / 100.0
	_cleanup_empty_direction(_editor_pose, direction_key)
	_refresh_editor_controls()
	queue_redraw()
	_set_editor_status("已导入到 %s / %s" % [_editor_pose, direction_key])


func _copy_direction_data(source_data: Dictionary) -> Dictionary:
	var copied: Dictionary = {}
	for key_variant in source_data.keys():
		var key := String(key_variant)
		if EDIT_JOINT_KEYS.has(key):
			var offset := _variant_to_vector2(source_data[key_variant])
			if offset.length_squared() > 0.0001:
				copied[key] = _offset_to_array(offset)
		elif key == "_head_scale":
			copied[key] = roundf(float(source_data[key_variant]) * 100.0) / 100.0
		elif key == "_front_side_sign":
			copied[key] = 1.0 if float(source_data[key_variant]) >= 0.0 else -1.0
		elif key == "_draw_order":
			copied[key] = _sanitized_draw_order(source_data[key_variant])
	return copied


func _mirror_direction_data_horizontal(source_data: Dictionary) -> Dictionary:
	var mirrored: Dictionary = {}
	for key_variant in source_data.keys():
		var key := String(key_variant)
		if EDIT_JOINT_KEYS.has(key):
			var offset := _variant_to_vector2(source_data[key_variant])
			if offset.length_squared() > 0.0001:
				var mirrored_key := _mirror_joint_key(key)
				mirrored[mirrored_key] = _offset_to_array(Vector2(-offset.x, offset.y))
		elif key == "_head_scale":
			mirrored[key] = roundf(float(source_data[key_variant]) * 100.0) / 100.0
		elif key == "_front_side_sign":
			mirrored[key] = -1.0 if float(source_data[key_variant]) >= 0.0 else 1.0
		elif key == "_draw_order":
			var mirrored_order: Array = []
			for layer_key in _sanitized_draw_order(source_data[key_variant]):
				mirrored_order.append(_mirror_layer_key(String(layer_key)))
			mirrored[key] = _sanitized_draw_order(mirrored_order)
	return mirrored


func _opposite_direction_index(index: int) -> int:
	return (clampi(index, 0, EDIT_DIRECTION_KEYS.size() - 1) + 4) % EDIT_DIRECTION_KEYS.size()


func _horizontal_mirror_direction_index(index: int) -> int:
	match clampi(index, 0, EDIT_DIRECTION_KEYS.size() - 1):
		0:
			return 4
		1:
			return 3
		3:
			return 1
		4:
			return 0
		5:
			return 7
		7:
			return 5
		_:
			return index


func _mirror_joint_key(key: String) -> String:
	match key:
		"shoulder_near":
			return "shoulder_far"
		"shoulder_far":
			return "shoulder_near"
		"elbow_near":
			return "elbow_far"
		"elbow_far":
			return "elbow_near"
		"wrist_near":
			return "wrist_far"
		"wrist_far":
			return "wrist_near"
		"hip_near":
			return "hip_far"
		"hip_far":
			return "hip_near"
		"knee_near":
			return "knee_far"
		"knee_far":
			return "knee_near"
		"ankle_near":
			return "ankle_far"
		"ankle_far":
			return "ankle_near"
		_:
			return key


func _mirror_layer_key(key: String) -> String:
	match key:
		"near_arm":
			return "far_arm"
		"far_arm":
			return "near_arm"
		"near_leg":
			return "far_leg"
		"far_leg":
			return "near_leg"
		_:
			return key


func _current_joint_offset() -> Vector2:
	var direction_data := _get_direction_overrides(_editor_pose, _direction_key(_editor_direction_index), false)
	if not direction_data.has(_editor_selected_joint):
		return Vector2.ZERO
	return _variant_to_vector2(direction_data[_editor_selected_joint])


func _set_selected_joint_offset(offset: Vector2) -> void:
	var direction_key := _direction_key(_editor_direction_index)
	var direction_data := _get_direction_overrides(_editor_pose, direction_key, true)
	var safe_offset := _constrain_joint_offset_to_bone_length(_editor_selected_joint, offset) if _editor_lock_bone_length else offset
	if offset.length_squared() <= 0.0001:
		direction_data.erase(_editor_selected_joint)
	else:
		direction_data[_editor_selected_joint] = _offset_to_array(safe_offset)
	_cleanup_empty_direction(_editor_pose, direction_key)
	_refresh_editor_controls()
	queue_redraw()


func _add_selected_joint_offset(delta: Vector2) -> void:
	if delta.length_squared() <= 0.0001:
		return
	_set_selected_joint_offset(_current_joint_offset() + delta)


func _select_nearest_joint(local_mouse: Vector2) -> bool:
	var pose := _build_flight_pose()
	var best_key := _editor_selected_joint
	var best_distance := 999999.0
	for key in EDIT_JOINT_KEYS:
		var point: Vector2 = pose[key]
		var distance := point.distance_to(local_mouse)
		if distance < best_distance:
			best_distance = distance
			best_key = key
	if best_distance > 28.0:
		return false
	_editor_selected_joint = best_key
	var bone_key := _bone_length_key_for_joint(_editor_selected_joint)
	if not bone_key.is_empty():
		_editor_selected_bone_length = bone_key
	_refresh_editor_controls()
	queue_redraw()
	return true


func _refresh_editor_controls() -> void:
	if _editor_pose_option == null:
		return
	_editor_updating_controls = true
	_editor_pose_option.select(1 if _editor_pose == "fast" else 0)
	_editor_direction_index = _canonical_edit_direction_index(_editor_direction_index)
	_editor_direction_option.select(_editor_direction_option_index_for_direction(_editor_direction_index))
	if _editor_front_side_option != null:
		var front_option_id := _current_front_side_option_id()
		for item_index in range(_editor_front_side_option.get_item_count()):
			if _editor_front_side_option.get_item_id(item_index) == front_option_id:
				_editor_front_side_option.select(item_index)
				break
	_editor_joint_option.select(maxi(EDIT_JOINT_KEYS.find(_editor_selected_joint), 0))
	if _editor_lock_bone_checkbox != null:
		_editor_lock_bone_checkbox.button_pressed = _editor_lock_bone_length
	if _editor_bone_length_option != null:
		_editor_bone_length_option.select(maxi(EDIT_BONE_LENGTH_KEYS.find(_editor_selected_bone_length), 0))
	if _editor_bone_length_spin != null:
		_editor_bone_length_spin.value = _bone_length_for_key(_editor_selected_bone_length)
	if _editor_head_scale_spin != null:
		_editor_head_scale_spin.value = _current_head_scale()
	if _editor_layer_option != null:
		_editor_layer_option.select(maxi(EDIT_DRAW_LAYER_KEYS.find(_editor_selected_layer), 0))
	var offset := _current_joint_offset()
	_editor_offset_x_spin.value = offset.x
	_editor_offset_y_spin.value = offset.y
	_editor_updating_controls = false
	var bone_length := _target_bone_length(_editor_selected_joint)
	var bone_custom := "custom" if _bone_lengths.has(_editor_selected_bone_length) else "default"
	_set_editor_status("%s / %s / %s  offset %.1f, %.1f  bone %.1f  %s %.1f %s  lock %s  front %s  head %.2f  layer %s" % [
		_editor_pose,
		_direction_key(_editor_direction_index),
		_editor_selected_joint,
		offset.x,
		offset.y,
		bone_length,
		_editor_selected_bone_length,
		_bone_length_for_key(_editor_selected_bone_length),
		bone_custom,
		"on" if _editor_lock_bone_length else "off",
		_front_side_label(_current_front_side_sign()),
		_current_head_scale(),
		",".join(_current_draw_order()),
	])


func _cleanup_empty_direction(pose_name: String, direction_key: String) -> void:
	if not _pose_overrides.has(pose_name) or not (_pose_overrides[pose_name] is Dictionary):
		return
	var pose_data: Dictionary = _pose_overrides[pose_name]
	if not pose_data.has(direction_key) or not (pose_data[direction_key] is Dictionary):
		return
	var direction_data: Dictionary = pose_data[direction_key]
	if direction_data.is_empty():
		pose_data.erase(direction_key)


func _cleanup_pose_overrides() -> void:
	for pose_name in ["low", "fast"]:
		if not _pose_overrides.has(pose_name) or not (_pose_overrides[pose_name] is Dictionary):
			_pose_overrides[pose_name] = {}
			continue
		var pose_data: Dictionary = _pose_overrides[pose_name]
		for direction_key in pose_data.keys():
			if not (pose_data[direction_key] is Dictionary) or Dictionary(pose_data[direction_key]).is_empty():
				pose_data.erase(direction_key)


func _is_pointer_over_editor_panel(screen_position: Vector2) -> bool:
	return _editor_panel != null and _editor_panel.visible and _editor_panel.get_global_rect().has_point(screen_position)


func _set_editor_status(text: String) -> void:
	if _editor_status_label != null:
		_editor_status_label.text = text


func _on_editor_pose_selected(index: int) -> void:
	if _editor_updating_controls:
		return
	_editor_pose = "fast" if index == 1 else "low"
	_refresh_editor_controls()
	queue_redraw()


func _on_editor_direction_selected(index: int) -> void:
	if _editor_updating_controls:
		return
	_editor_direction_index = _canonical_edit_direction_index(_editor_direction_option.get_item_id(index))
	_refresh_editor_controls()
	queue_redraw()


func _on_editor_front_side_selected(index: int) -> void:
	if _editor_updating_controls:
		return
	_set_current_front_side_option(_editor_front_side_option.get_item_id(index))


func _on_editor_joint_selected(index: int) -> void:
	if _editor_updating_controls:
		return
	_editor_selected_joint = String(EDIT_JOINT_KEYS[clampi(index, 0, EDIT_JOINT_KEYS.size() - 1)])
	var bone_key := _bone_length_key_for_joint(_editor_selected_joint)
	if not bone_key.is_empty():
		_editor_selected_bone_length = bone_key
	_refresh_editor_controls()
	queue_redraw()


func _on_editor_lock_bone_toggled(enabled: bool) -> void:
	if _editor_updating_controls:
		return
	_editor_lock_bone_length = enabled
	_refresh_editor_controls()
	queue_redraw()


func _on_editor_bone_length_selected(index: int) -> void:
	if _editor_updating_controls:
		return
	_editor_selected_bone_length = String(EDIT_BONE_LENGTH_KEYS[clampi(index, 0, EDIT_BONE_LENGTH_KEYS.size() - 1)])
	_refresh_editor_controls()
	queue_redraw()


func _on_editor_bone_length_changed(value: float) -> void:
	if _editor_updating_controls:
		return
	_set_bone_length_for_key(_editor_selected_bone_length, value)


func _on_editor_offset_x_changed(value: float) -> void:
	if _editor_updating_controls:
		return
	var offset := _current_joint_offset()
	offset.x = value
	_set_selected_joint_offset(offset)


func _on_editor_offset_y_changed(value: float) -> void:
	if _editor_updating_controls:
		return
	var offset := _current_joint_offset()
	offset.y = value
	_set_selected_joint_offset(offset)


func _on_editor_head_scale_changed(value: float) -> void:
	if _editor_updating_controls:
		return
	_set_current_head_scale(value)


func _on_editor_layer_selected(index: int) -> void:
	if _editor_updating_controls:
		return
	_editor_selected_layer = String(EDIT_DRAW_LAYER_KEYS[clampi(index, 0, EDIT_DRAW_LAYER_KEYS.size() - 1)])
	_refresh_editor_controls()
	queue_redraw()


func _on_editor_layer_back_pressed() -> void:
	_move_selected_layer(-1)


func _on_editor_layer_front_pressed() -> void:
	_move_selected_layer(1)


func _on_editor_layer_top_pressed() -> void:
	_move_selected_layer_to(EDIT_DRAW_LAYER_KEYS.size() - 1)


func _on_editor_fit_bone_length_pressed() -> void:
	_fit_selected_joint_to_bone_length()


func _on_editor_capture_bone_length_pressed() -> void:
	var length := _actual_bone_length_for_key(_editor_selected_bone_length)
	if length <= 0.001:
		_set_editor_status("%s 当前没有可读取骨长" % _editor_selected_bone_length)
		return
	_set_bone_length_for_key(_editor_selected_bone_length, length)
	_set_editor_status("%s 标准骨长已设为 %.1f" % [_editor_selected_bone_length, length])


func _on_editor_reset_bone_length_pressed() -> void:
	var bone_key := _editor_selected_bone_length
	_reset_bone_length_for_key(bone_key)
	_set_editor_status("%s 标准骨长已恢复默认 %.1f" % [bone_key, _bone_length_for_key(bone_key)])


func _on_editor_reset_joint_pressed() -> void:
	_set_selected_joint_offset(Vector2.ZERO)


func _on_editor_reset_direction_pressed() -> void:
	var pose_data: Dictionary = _pose_overrides.get(_editor_pose, {})
	pose_data.erase(_direction_key(_editor_direction_index))
	_refresh_editor_controls()
	queue_redraw()


func _on_editor_copy_opposite_pressed() -> void:
	var source_key: String = _direction_key(_editor_direction_index)
	var source_data: Dictionary = _get_direction_overrides(_editor_pose, source_key, false)
	if source_data.is_empty():
		_set_editor_status("%s 没有可复制的偏移" % source_key)
		return
	var target_index: int = _opposite_direction_index(_editor_direction_index)
	var target_key: String = _direction_key(target_index)
	var pose_data: Dictionary = _get_direction_overrides(_editor_pose, target_key, true)
	var copied_data: Dictionary = _copy_direction_data(source_data)
	pose_data.clear()
	for key in copied_data.keys():
		pose_data[key] = copied_data[key]
	_editor_direction_index = target_index
	_refresh_editor_controls()
	_set_editor_status("已复制 %s 到 %s" % [source_key, target_key])
	queue_redraw()


func _on_editor_mirror_horizontal_pressed() -> void:
	var source_key: String = _direction_key(_editor_direction_index)
	var source_data: Dictionary = _get_direction_overrides(_editor_pose, source_key, false)
	if source_data.is_empty():
		_set_editor_status("%s 没有可镜像的偏移" % source_key)
		return
	var target_index: int = _horizontal_mirror_direction_index(_editor_direction_index)
	var target_key: String = _direction_key(target_index)
	var pose_data: Dictionary = _get_direction_overrides(_editor_pose, target_key, true)
	var mirrored_data: Dictionary = _mirror_direction_data_horizontal(source_data)
	pose_data.clear()
	for key in mirrored_data.keys():
		pose_data[key] = mirrored_data[key]
	_editor_direction_index = target_index
	_refresh_editor_controls()
	_set_editor_status("已左右镜像 %s 到 %s" % [source_key, target_key])
	queue_redraw()


func _on_editor_apply_all_pressed() -> void:
	var source_key: String = _direction_key(_editor_direction_index)
	var source_data: Dictionary = _get_direction_overrides(_editor_pose, source_key, false)
	if source_data.is_empty():
		_set_editor_status("%s 没有可应用的偏移" % source_key)
		return
	var copied_data: Dictionary = _copy_direction_data(source_data)
	var pose_data: Dictionary = _pose_overrides.get(_editor_pose, {})
	if not _pose_overrides.has(_editor_pose) or not (_pose_overrides[_editor_pose] is Dictionary):
		_pose_overrides[_editor_pose] = {}
		pose_data = _pose_overrides[_editor_pose]
	for index_variant in EDIT_CARDINAL_DIRECTION_INDICES:
		var target_key := _direction_key(int(index_variant))
		pose_data[target_key] = _copy_direction_data(copied_data)
	_refresh_editor_controls()
	_set_editor_status("已将 %s 应用到四个主方向" % source_key)
	queue_redraw()


func _on_editor_copy_pose_json_pressed() -> void:
	_copy_current_pose_json_to_clipboard()


func _on_editor_import_pose_json_pressed() -> void:
	_import_pose_json_from_clipboard()


func _on_editor_save_pressed() -> void:
	_save_pose_overrides()
