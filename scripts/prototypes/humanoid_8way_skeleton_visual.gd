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
const SHOW_JOINTS_IN_GAME := false
const CLEAN_BONE := Color(0.070, 0.078, 0.082, 0.98)
const CLEAN_BONE_SOFT := Color(0.70, 0.90, 1.0, 0.14)
const CLEAN_BONE_SHADOW := Color(0.005, 0.007, 0.010, 0.44)
const CLEAN_BONE_HIGHLIGHT := Color(0.92, 0.98, 1.0, 0.46)
const CLEAN_VOLUME := Color(0.040, 0.048, 0.052, 0.76)
const CLEAN_VOLUME_RIM := Color(0.84, 0.92, 0.94, 0.34)
const CLEAN_JOINT := Color(1.0, 1.0, 1.0, 0.94)
const CLEAN_HEAD := Color(0.84, 0.92, 0.94, 0.54)
const CLEAN_HEAD_FILL := Color(0.035, 0.040, 0.044, 0.94)
const HEAD := Color(0.075, 0.078, 0.080, 1.0)
const TORSO := Color(0.105, 0.115, 0.112, 1.0)
const UPPER_ARM := Color(0.145, 0.155, 0.150, 1.0)
const FOREARM := Color(0.075, 0.080, 0.080, 1.0)
const THIGH := Color(0.100, 0.105, 0.104, 1.0)
const CALF := Color(0.060, 0.063, 0.066, 1.0)
const ROBE_LIGHT := Color(0.74, 0.78, 0.76, 0.96)
const ROBE_SHADOW := Color(0.045, 0.048, 0.050, 1.0)
const ROBE_TRIM := Color(0.86, 0.88, 0.80, 0.92)
const SASH := Color(0.025, 0.026, 0.028, 0.98)
const BOOT := Color(0.018, 0.020, 0.026, 1.0)
const JADE := Color(0.66, 0.74, 0.69, 0.86)
const HAIR := Color(0.015, 0.016, 0.018, 0.82)
const HAIR_SOFT := Color(0.060, 0.062, 0.062, 0.38)
const INK_EDGE := Color(0.86, 0.90, 0.86, 0.58)
const INK_RIM_COLD := Color(0.70, 0.98, 1.0, 0.52)
const INK_RIM_WARM := Color(0.96, 0.90, 0.70, 0.36)
const INK_BODY_GLOW := Color(0.58, 0.86, 0.92, 0.11)
const CLOTH_PANEL := Color(0.020, 0.022, 0.024, 0.34)
const CLOTH_WASH := Color(0.22, 0.24, 0.23, 0.26)
const CLOTH_RIM := Color(0.86, 0.88, 0.80, 0.30)
const SWORD := Color(0.62, 0.96, 1.0, 0.88)
const SWORD_CORE := Color(0.96, 1.0, 0.98, 0.98)
const FACE_DARK := Color(0.06, 0.07, 0.08, 0.92)
const FLIGHT_SPEED_POSE_REFERENCE := 1950.0
const POSE_OVERRIDE_PATH := "res://resources/flight/yujian_8way_cruise_generated_v1/prototype_v4_skeleton_pose_overrides.json"
const HAIR_FX_TUNING_PATH := "user://yujian_v4_hair_fx_tuning.json"
const V4_PLUS_DRAW_IMAGE_PARTS := false
const V4_PLUS_RIGHT_FAST_PART_SCALE := 0.43
const V4_PLUS_RIGHT_FAST_TEX_ROBE_BACK := preload("res://resources/flight/yujian_8way_cruise_generated_v1/v4_plus_ink_parts/parts/right_fast_robe_back_panel.png")
const V4_PLUS_RIGHT_FAST_TEX_ROBE_FRONT := preload("res://resources/flight/yujian_8way_cruise_generated_v1/v4_plus_ink_parts/parts/right_fast_robe_front_panel.png")
const V4_PLUS_RIGHT_FAST_TEX_SLEEVE_NEAR := preload("res://resources/flight/yujian_8way_cruise_generated_v1/v4_plus_ink_parts/parts/right_fast_sleeve_near.png")
const V4_PLUS_RIGHT_FAST_TEX_SLEEVE_FAR := preload("res://resources/flight/yujian_8way_cruise_generated_v1/v4_plus_ink_parts/parts/right_fast_sleeve_far.png")
const V4_PLUS_RIGHT_FAST_TEX_HAIR := preload("res://resources/flight/yujian_8way_cruise_generated_v1/v4_plus_ink_parts/parts/right_fast_hair_back_main.png")
const V4_PLUS_RIGHT_FAST_TEX_SASH := preload("res://resources/flight/yujian_8way_cruise_generated_v1/v4_plus_ink_parts/parts/right_fast_sash_streamers.png")
const V4_PLUS_RIGHT_FAST_TEX_SWORD := preload("res://resources/flight/yujian_8way_cruise_generated_v1/v4_plus_ink_parts/parts/right_fast_sword_body_glow.png")
const V4_PLUS_RIGHT_FAST_TEX_FOOT_QI := preload("res://resources/flight/yujian_8way_cruise_generated_v1/v4_plus_ink_parts/parts/right_fast_foot_qi_contact.png")
const V4_PLUS_ANCHOR_ROBE_BACK := Vector2(468.0, 80.0)
const V4_PLUS_ANCHOR_ROBE_FRONT := Vector2(270.0, 82.0)
const V4_PLUS_ANCHOR_SLEEVE_NEAR := Vector2(402.0, 92.0)
const V4_PLUS_ANCHOR_SLEEVE_FAR := Vector2(226.0, 80.0)
const V4_PLUS_ANCHOR_HAIR := Vector2(350.0, 78.0)
const V4_PLUS_ANCHOR_SASH := Vector2(318.0, 90.0)
const V4_PLUS_ANCHOR_SWORD := Vector2(250.0, 48.0)
const V4_PLUS_ANCHOR_FOOT_QI := Vector2(125.0, 61.0)

@export_group("Hair FX")
@export var hair_fx_enabled := true
@export var hair_fx_back_strands := 15
@export var hair_fx_front_strands := 0
@export var hair_fx_width := 0.50
@export var hair_fx_length := 1.00
@export var hair_fx_opacity := 1.00
@export var hair_fx_spread := 3.00
@export var hair_fx_hover_drop := 3.00
@export var hair_fx_sway := 3.00
@export var hair_fx_turn_lag := 3.00
@export var hair_fx_front_cover := 0.00
@export var hair_fx_volume := 1.00
@export var hair_fx_root_ink := 1.00
@export var hair_fx_highlight := 1.00
@export var hair_fx_physics := 1.00
@export var hair_fx_layer_depth := 1.00
@export var hair_fx_material_depth := 1.00
@export var hair_fx_debug_overlay := false

@export_group("V4 Idle Pose FX")
@export var idle_pose_fx_enabled := true
@export_range(0.0, 2.0, 0.01) var idle_pose_breath_strength := 1.0
@export_range(0.0, 2.0, 0.01) var idle_pose_control_strength := 1.0

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
var _cloth_wind := 0.0
var _cloth_turn := 0.0
var _cloth_flow_dir := Vector2.DOWN
var _hair_turn_lag := 0.0
var _hair_layer_lag := 0.0
var _hair_groom_chains := {}
var _idle_recover_energy := 0.0
var _idle_previous_action_pressure := 0.0
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
var _hair_fx_panel: PanelContainer
var _hair_fx_enabled_check: CheckBox
var _hair_fx_debug_check: CheckBox
var _hair_fx_back_strands_slider: HSlider
var _hair_fx_back_strands_spin: SpinBox
var _hair_fx_front_strands_slider: HSlider
var _hair_fx_front_strands_spin: SpinBox
var _hair_fx_width_slider: HSlider
var _hair_fx_width_spin: SpinBox
var _hair_fx_length_slider: HSlider
var _hair_fx_length_spin: SpinBox
var _hair_fx_opacity_slider: HSlider
var _hair_fx_opacity_spin: SpinBox
var _hair_fx_spread_slider: HSlider
var _hair_fx_spread_spin: SpinBox
var _hair_fx_hover_drop_slider: HSlider
var _hair_fx_hover_drop_spin: SpinBox
var _hair_fx_sway_slider: HSlider
var _hair_fx_sway_spin: SpinBox
var _hair_fx_turn_lag_slider: HSlider
var _hair_fx_turn_lag_spin: SpinBox
var _hair_fx_front_cover_slider: HSlider
var _hair_fx_front_cover_spin: SpinBox
var _hair_fx_volume_slider: HSlider
var _hair_fx_volume_spin: SpinBox
var _hair_fx_root_ink_slider: HSlider
var _hair_fx_root_ink_spin: SpinBox
var _hair_fx_highlight_slider: HSlider
var _hair_fx_highlight_spin: SpinBox
var _hair_fx_physics_slider: HSlider
var _hair_fx_physics_spin: SpinBox
var _hair_fx_layer_depth_slider: HSlider
var _hair_fx_layer_depth_spin: SpinBox
var _hair_fx_material_depth_slider: HSlider
var _hair_fx_material_depth_spin: SpinBox
var _hair_fx_status_label: Label
var _hair_fx_updating_controls := false


func _ready() -> void:
	_load_pose_overrides()
	_load_hair_fx_tuning()
	_create_editor_panel()
	_create_hair_fx_panel()
	set_process_input(true)


func is_pose_editor_active() -> bool:
	return _editor_active


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F4:
		_toggle_editor()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F5:
		_toggle_hair_fx_panel()
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
	var safe_delta := maxf(p_delta, 0.0)
	var previous_heading := _heading.normalized() if _heading.length_squared() > 0.0001 else _direction_vector(_direction_index)
	var next_heading := p_heading.normalized() if p_heading.length_squared() > 0.0001 else _direction_vector(safe_index)
	if safe_index != _direction_index:
		_direction_index = safe_index
		_switch_flash = 1.0
	else:
		_switch_flash = maxf(_switch_flash - safe_delta / 0.12, 0.0)
	_heading = next_heading
	_velocity = p_velocity
	_boost = clampf(p_boost, 0.0, 1.0)
	_turn = clampf(p_turn, 0.0, 1.0)
	_carve = clampf(p_carve, 0.0, 1.0)
	_throttle = clampf(p_throttle, 0.0, 1.0)
	var signed_heading_change := clampf(previous_heading.cross(next_heading) * 7.5, -1.0, 1.0)
	var signed_turn_target := signed_heading_change * (0.35 + maxf(_turn, _carve * 0.70) * 0.80)
	_hair_turn_lag = _damp_float(_hair_turn_lag, signed_turn_target, 0.10, safe_delta)
	var layer_impulse := signed_heading_change * (0.28 + maxf(_turn, _carve) * 0.52)
	if absf(layer_impulse) > 0.025:
		_hair_layer_lag = clampf(_hair_layer_lag + layer_impulse, -1.0, 1.0)
	_hair_layer_lag = _damp_float(_hair_layer_lag, signed_turn_target * 0.22, 0.24, safe_delta)
	_update_idle_recover_energy(safe_delta)
	_update_cloth_motion_state(safe_delta)
	_time += safe_delta
	if hair_fx_enabled:
		_update_hair_groom_physics(_build_flight_pose(), safe_delta)
	else:
		_hair_groom_chains.clear()
	queue_redraw()


func _draw() -> void:
	var pose := _build_flight_pose()
	var h: Vector2 = pose["heading"]
	var speed_ratio: float = pose["speed_ratio"]
	var v4_plus_alpha := _v4_plus_right_fast_alpha(pose)
	var image_parts_alpha := v4_plus_alpha if V4_PLUS_DRAW_IMAGE_PARTS else 0.0
	_draw_sword(h, speed_ratio, image_parts_alpha)
	if V4_PLUS_DRAW_IMAGE_PARTS:
		_draw_v4_plus_right_fast_back_parts(pose)
	_draw_v4_hair_fx_back(pose)
	_draw_clean_skeleton(pose)
	_draw_v4_hair_fx_body_front(pose)
	_draw_v4_hair_fx_head_mount(pose)
	_draw_v4_hair_fx_front(pose)
	if V4_PLUS_DRAW_IMAGE_PARTS:
		_draw_v4_plus_right_fast_front_parts(pose)
	_draw_joints(pose)
	_draw_hair_groom_debug_overlay(pose)


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
	var pose: Dictionary
	if first_index == second_index or blend_weight <= 0.001:
		pose = first_pose
	else:
		var second_pose := _build_direction_flight_pose(second_index, fast_weight, speed_ratio, wind, apply_overrides)
		pose = _blend_flight_poses(first_pose, second_pose, blend_weight)
	if apply_overrides:
		_apply_runtime_idle_pose_motion(pose)
	return pose


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


func _apply_runtime_idle_pose_motion(pose: Dictionary) -> void:
	if not idle_pose_fx_enabled or _editor_active:
		return
	var h: Vector2 = pose["heading"]
	if h.length_squared() <= 0.0001:
		h = _heading if _heading.length_squared() > 0.0001 else Vector2.RIGHT
	h = h.normalized()
	var normal := h.rotated(PI * 0.5)
	if normal.y < 0.0:
		normal = -normal
	var speed_ratio := clampf(_velocity.length() / FLIGHT_SPEED_POSE_REFERENCE, 0.0, 1.35)
	var speed_unit := clampf(speed_ratio, 0.0, 1.0)
	var hover_weight := clampf((1.0 - smoothstep(0.06, 0.32, speed_unit)) * (1.0 - _throttle * 0.65), 0.0, 1.0)
	var boost_weight := clampf(smoothstep(0.42, 0.86, maxf(speed_unit, maxf(_boost, _throttle * 0.74))), 0.0, 1.0)
	var turn_weight := clampf(maxf(_turn, _carve), 0.0, 1.0)
	var recover_weight := clampf(_idle_recover_energy, 0.0, 1.0)
	var cruise_weight := clampf(smoothstep(0.10, 0.56, speed_unit) * (1.0 - boost_weight * 0.55) * (1.0 - turn_weight * 0.35), 0.0, 1.0)

	var breath_rate := lerpf(2.05, 4.90, clampf(boost_weight + turn_weight * 0.45, 0.0, 1.0))
	var breath_amplitude := idle_pose_breath_strength * (
		3.15 * hover_weight
		+ 1.45 * cruise_weight
		+ 0.45 * (1.0 - hover_weight) * (1.0 - boost_weight)
	)
	breath_amplitude *= 1.0 - boost_weight * 0.70
	breath_amplitude *= 1.0 - turn_weight * 0.30
	var breath := sin(_time * breath_rate) * breath_amplitude
	var high_speed_tremor := sin(_time * 12.0 + 0.7) * boost_weight * 0.62 * idle_pose_breath_strength
	var recover_bounce := sin(_time * 10.5 + 1.2) * recover_weight * 2.15 * idle_pose_breath_strength

	var lift := Vector2.UP * (breath + high_speed_tremor + recover_bounce * 0.55)
	var boost_pressure := h * boost_weight * (2.40 + _throttle * 1.20)
	var turn_pressure := normal * _hair_turn_lag * (3.10 + turn_weight * 2.40)
	var recover_pressure := h * recover_bounce * 0.80 - normal * recover_weight * _hair_turn_lag * 1.80

	_offset_pose_joint(pose, "hip_near", lift * 0.34 + turn_pressure * 0.18 + recover_pressure * 0.18)
	_offset_pose_joint(pose, "hip_far", lift * 0.30 + turn_pressure * 0.14 + recover_pressure * 0.14)
	_offset_pose_joint(pose, "shoulder_near", lift * 1.00 + boost_pressure + turn_pressure * 0.82 + recover_pressure * 0.72)
	_offset_pose_joint(pose, "shoulder_far", lift * 0.92 + boost_pressure * 0.86 + turn_pressure * 0.64 + recover_pressure * 0.58)
	_offset_pose_joint(pose, "head_center", lift * 1.28 + boost_pressure * 1.12 + turn_pressure * 1.06 + recover_pressure)

	var control_rate := lerpf(2.45, 6.60, clampf(boost_weight + turn_weight * 0.70, 0.0, 1.0))
	var control_wave := sin(_time * control_rate + 1.1)
	var control_side := cos(_time * (control_rate * 0.76) + 0.4)
	var control_amplitude := idle_pose_control_strength * (
		1.25 * hover_weight
		+ 2.15 * cruise_weight
		+ 1.35 * boost_weight
		+ 3.35 * turn_weight
		+ 2.20 * recover_weight
	)
	var near_hand := h * control_wave * control_amplitude + normal * control_side * control_amplitude * 0.42
	var far_hand := -h * control_wave * control_amplitude * 0.42 + normal * control_side * control_amplitude * 0.26
	var steer_push := turn_pressure * 0.62 + recover_pressure * 0.45 + boost_pressure * 0.32
	_offset_pose_joint(pose, "elbow_near", near_hand * 0.38 + steer_push * 0.36)
	_offset_pose_joint(pose, "wrist_near", near_hand + steer_push)
	_offset_pose_joint(pose, "elbow_far", far_hand * 0.35 + steer_push * 0.24)
	_offset_pose_joint(pose, "wrist_far", far_hand * 0.78 + steer_push * 0.55)

	var knee_follow := lift * 0.18 + turn_pressure * 0.12 + recover_pressure * 0.10
	_offset_pose_joint(pose, "knee_near", knee_follow)
	_offset_pose_joint(pose, "knee_far", knee_follow * 0.82)
	_recompute_runtime_pose_centers(pose)


func _offset_pose_joint(pose: Dictionary, joint_key: String, offset: Vector2) -> void:
	if offset.length_squared() <= 0.000001 or not pose.has(joint_key):
		return
	var point: Vector2 = pose[joint_key]
	pose[joint_key] = point + offset


func _recompute_runtime_pose_centers(pose: Dictionary) -> void:
	var shoulder_near: Vector2 = pose["shoulder_near"]
	var shoulder_far: Vector2 = pose["shoulder_far"]
	var hip_near: Vector2 = pose["hip_near"]
	var hip_far: Vector2 = pose["hip_far"]
	pose["shoulder_center"] = (shoulder_near + shoulder_far) * 0.5
	pose["hip_center"] = (hip_near + hip_far) * 0.5


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
	_align_blended_feet_to_sword_line(pose)
	var shoulder_near: Vector2 = pose["shoulder_near"]
	var shoulder_far: Vector2 = pose["shoulder_far"]
	var hip_near: Vector2 = pose["hip_near"]
	var hip_far: Vector2 = pose["hip_far"]
	pose["shoulder_center"] = (shoulder_near + shoulder_far) * 0.5
	pose["hip_center"] = (hip_near + hip_far) * 0.5
	return pose


func _align_blended_feet_to_sword_line(pose: Dictionary) -> void:
	var h: Vector2 = pose["heading"]
	if h.length_squared() <= 0.0001:
		return
	h = h.normalized()
	var diagonal_strength: float = clampf(minf(absf(h.x), absf(h.y)) * 1.41421356237, 0.0, 1.0)
	diagonal_strength = smoothstep(0.08, 0.65, diagonal_strength)
	if diagonal_strength <= 0.001:
		return
	var sword_center: Vector2 = _sword_center()
	_align_blended_foot_to_sword_line(pose, "near", h, sword_center, diagonal_strength)
	_align_blended_foot_to_sword_line(pose, "far", h, sword_center, diagonal_strength)


func _align_blended_foot_to_sword_line(
		pose: Dictionary,
		side_key: String,
		h: Vector2,
		sword_center: Vector2,
		strength: float
) -> void:
	var ankle_key := "ankle_%s" % side_key
	var knee_key := "knee_%s" % side_key
	var ankle: Vector2 = pose[ankle_key]
	var correction: Vector2 = _point_to_sword_line_correction(ankle, h, sword_center) * strength
	pose[ankle_key] = ankle + correction
	var knee: Vector2 = pose[knee_key]
	pose[knee_key] = knee + correction * 0.45


func _point_to_sword_line_correction(point: Vector2, h: Vector2, sword_center: Vector2) -> Vector2:
	var normal: Vector2 = h.rotated(PI * 0.5)
	var distance: float = (point - sword_center).dot(normal)
	return -normal * distance


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


func _draw_sword(h: Vector2, speed_ratio: float, v4_plus_alpha := 0.0) -> void:
	var legacy_alpha := 1.0 - clampf(v4_plus_alpha * 0.86, 0.0, 0.86)
	var back := -h * (78.0 + 14.0 * _boost)
	var front := h * (74.0 + 12.0 * _boost)
	var drop := _sword_center()
	var width := 5.0 + 3.0 * _boost
	draw_line(back + drop, front + drop, Color(0.08, 0.18, 0.20, 0.84 * legacy_alpha), width + 5.0, true)
	draw_line(back + drop, front + drop, Color(SWORD.r, SWORD.g, SWORD.b, SWORD.a * legacy_alpha), width, true)
	draw_line(front + drop, front + h * 22.0 + drop, Color(SWORD_CORE.r, SWORD_CORE.g, SWORD_CORE.b, SWORD_CORE.a * legacy_alpha), 2.0 + speed_ratio * 2.0, true)
	var guard_axis := h.rotated(PI * 0.5)
	var guard_center := back + h * 20.0 + drop
	draw_line(guard_center - guard_axis * 8.0, guard_center + guard_axis * 8.0, Color(OUTLINE.r, OUTLINE.g, OUTLINE.b, OUTLINE.a * legacy_alpha), 3.0, true)
	draw_line(guard_center - guard_axis * 6.0, guard_center + guard_axis * 6.0, Color(ROBE_TRIM.r, ROBE_TRIM.g, ROBE_TRIM.b, ROBE_TRIM.a * legacy_alpha), 1.7, true)
	draw_circle(back + h * 9.0 + drop, 3.0, Color(OUTLINE.r, OUTLINE.g, OUTLINE.b, OUTLINE.a * legacy_alpha))
	draw_circle(back + h * 9.0 + drop, 2.0, Color(JADE.r, JADE.g, JADE.b, JADE.a * legacy_alpha))
	var glow := Color(0.58, 0.95, 1.0, (0.10 + 0.10 * _boost + 0.08 * _switch_flash) * (1.0 - clampf(v4_plus_alpha * 0.96, 0.0, 0.96)))
	if glow.a > 0.002:
		draw_line(back - h * 28.0 + drop, front + h * 12.0 + drop, glow, 18.0 + 10.0 * _boost, true)


func _sword_center() -> Vector2:
	return Vector2(0.0, 68.0 + 4.0 * _boost)


func _v4_plus_right_fast_alpha(pose: Dictionary) -> float:
	var h: Vector2 = pose["heading"]
	if h.length_squared() <= 0.0001:
		return 0.0
	h = h.normalized()
	var rightness := smoothstep(0.42, 0.88, h.x)
	var vertical_penalty := 1.0 - clampf(absf(h.y) * 0.62, 0.0, 0.70)
	var fast: float = clampf(float(pose.get("fast_pose", 0.0)), 0.0, 1.0)
	var fastness := smoothstep(0.50, 0.90, maxf(fast, _boost * 0.95 + _throttle * 0.16))
	return clampf(rightness * vertical_penalty * fastness, 0.0, 1.0)


func _draw_v4_plus_right_fast_back_parts(pose: Dictionary) -> void:
	var alpha := _v4_plus_right_fast_alpha(pose)
	if alpha <= 0.015:
		return
	var h: Vector2 = pose["heading"]
	h = h.normalized()
	var angle := clampf(h.angle(), -0.50, 0.50) * 0.32
	var wind: float = clampf(float(pose.get("wind", 0.0)), 0.0, 1.6)
	var hip_center: Vector2 = pose["hip_center"]
	var head_center: Vector2 = pose["head_center"]
	var wrist_far: Vector2 = pose["wrist_far"]
	var boost_lift := Vector2(0.0, -3.0 * _boost)
	var part_scale := V4_PLUS_RIGHT_FAST_PART_SCALE
	_draw_v4_plus_part(
		V4_PLUS_RIGHT_FAST_TEX_FOOT_QI,
		_sword_center() + Vector2(0.0, 4.0),
		V4_PLUS_ANCHOR_FOOT_QI,
		part_scale * 0.84,
		angle * 0.28,
		alpha * 0.84
	)
	_draw_v4_plus_part(
		V4_PLUS_RIGHT_FAST_TEX_SWORD,
		_sword_center() + Vector2(0.0, 1.0),
		V4_PLUS_ANCHOR_SWORD,
		part_scale * 0.94,
		angle * 0.22,
		alpha * 0.92
	)
	_draw_v4_plus_part(
		V4_PLUS_RIGHT_FAST_TEX_ROBE_BACK,
		hip_center + Vector2(0.0, -4.0) + boost_lift,
		V4_PLUS_ANCHOR_ROBE_BACK,
		part_scale * (0.90 + wind * 0.035),
		angle,
		alpha * 0.74
	)
	_draw_v4_plus_part(
		V4_PLUS_RIGHT_FAST_TEX_HAIR,
		head_center + boost_lift,
		V4_PLUS_ANCHOR_HAIR,
		part_scale * 0.78,
		angle * 0.86,
		alpha * 0.82
	)
	_draw_v4_plus_part(
		V4_PLUS_RIGHT_FAST_TEX_SLEEVE_FAR,
		wrist_far,
		V4_PLUS_ANCHOR_SLEEVE_FAR,
		part_scale * 0.76,
		angle * 0.82,
		alpha * 0.58
	)


func _draw_v4_plus_right_fast_front_parts(pose: Dictionary) -> void:
	var alpha := _v4_plus_right_fast_alpha(pose)
	if alpha <= 0.015:
		return
	var h: Vector2 = pose["heading"]
	h = h.normalized()
	var angle := clampf(h.angle(), -0.50, 0.50) * 0.32
	var wind: float = clampf(float(pose.get("wind", 0.0)), 0.0, 1.6)
	var hip_center: Vector2 = pose["hip_center"]
	var wrist_near: Vector2 = pose["wrist_near"]
	var boost_lift := Vector2(0.0, -2.0 * _boost)
	var part_scale := V4_PLUS_RIGHT_FAST_PART_SCALE
	_draw_v4_plus_part(
		V4_PLUS_RIGHT_FAST_TEX_ROBE_FRONT,
		hip_center + Vector2(0.0, -2.0) + boost_lift,
		V4_PLUS_ANCHOR_ROBE_FRONT,
		part_scale * 0.76,
		angle,
		alpha * 0.76
	)
	_draw_v4_plus_part(
		V4_PLUS_RIGHT_FAST_TEX_SLEEVE_NEAR,
		wrist_near,
		V4_PLUS_ANCHOR_SLEEVE_NEAR,
		part_scale * 0.74,
		angle * 0.82,
		alpha * 0.70
	)
	_draw_v4_plus_part(
		V4_PLUS_RIGHT_FAST_TEX_SASH,
		hip_center + Vector2(0.0, 2.0),
		V4_PLUS_ANCHOR_SASH,
		part_scale * (0.72 + wind * 0.028),
		angle * 0.92,
		alpha * 0.78
	)


func _draw_v4_plus_part(texture: Texture2D, anchor: Vector2, anchor_pixel: Vector2, texture_scale: float, rotation: float, alpha: float) -> void:
	if texture == null or alpha <= 0.001 or texture_scale <= 0.001:
		return
	var texture_size := texture.get_size() * texture_scale
	var offset := -anchor_pixel * texture_scale
	draw_set_transform(anchor, rotation, Vector2.ONE)
	draw_texture_rect(texture, Rect2(offset, texture_size), false, Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_v4_hair_fx_back(pose: Dictionary) -> void:
	if not hair_fx_enabled:
		return
	var state := _hair_fx_state(pose)
	var alpha := float(state["alpha"])
	if alpha <= 0.001:
		return
	var layer_alpha := alpha
	if layer_alpha <= 0.001:
		return
	var layers := _hair_direction_layers(pose, state)
	layer_alpha = _hair_layer_alpha(alpha, float(layers["back_alpha"]))
	_draw_hair_back_mass(pose, state, _hair_layer_alpha(layer_alpha, 1.06))
	_draw_hair_groom_main_locks(pose, state, "back", layer_alpha)
	_draw_hair_groom_secondary_wisps(pose, state, "back", layer_alpha)


func _draw_v4_hair_fx_body_front(pose: Dictionary) -> void:
	if not hair_fx_enabled:
		return
	var state := _hair_fx_state(pose)
	var alpha := float(state["alpha"])
	if alpha <= 0.001:
		return
	var layers := _hair_direction_layers(pose, state)
	var body_alpha := _hair_layer_alpha(alpha, float(layers["body_front_alpha"]))
	if body_alpha <= 0.001:
		return
	_draw_hair_body_front_volume(pose, state, body_alpha)
	_draw_hair_groom_main_locks(pose, state, "body_front", body_alpha)
	_draw_hair_groom_secondary_wisps(pose, state, "body_front", body_alpha * 0.48)


func _draw_hair_groom_secondary_wisps(pose: Dictionary, state: Dictionary, layer: String, alpha: float) -> void:
	if alpha <= 0.001:
		return
	var density := clampf(float(maxi(hair_fx_back_strands, 0)) / 24.0, 0.0, 1.6)
	var highlight_power := maxf(hair_fx_highlight, 0.0)
	if density <= 0.01 and highlight_power <= 0.01:
		return
	var wind := clampf(float(state.get("wind", 0.0)), 0.0, 1.0)
	var max_passes := clampi(int(roundf(lerpf(4.0, 12.0, clampf(density, 0.0, 1.0)))), 3, 14)
	var pass_count := 0
	for lock_def in _hair_groom_lock_defs():
		var region := String(lock_def.get("region", "occipital"))
		if layer == "body_front" and region == "crown":
			continue
		var lock_id := String(lock_def.get("id", ""))
		if lock_id.is_empty():
			continue
		var layer_weight := _hair_groom_layer_weight(lock_def, layer, pose, state)
		if layer_weight <= 0.03:
			continue
		var target := _hair_groom_target_points(lock_def, pose, state)
		var points := _hair_groom_chain_points(lock_id, target)
		if points.size() < 3:
			continue
		var lane_t := clampf(float(lock_def.get("lane", 0.5)), 0.0, 1.0)
		var width_scale := float(lock_def.get("width", 1.0))
		var phase := float(lock_def.get("phase", 0.0))
		var body := 1.0 - absf(lane_t - 0.5) * 0.36
		var root_width := (3.50 + body * 1.15) * width_scale * hair_fx_width
		var mid_width := (5.10 + body * 3.20 + wind * 1.35) * width_scale * hair_fx_width * (0.70 + maxf(hair_fx_volume, 0.0) * 0.30)
		var tip_width := (0.34 + body * 0.34) * width_scale * hair_fx_width
		var lane_count := 1
		if density > 0.78 and highlight_power > 0.35 and region != "crown":
			lane_count = 2
		for lane_index in range(lane_count):
			if pass_count >= max_passes:
				return
			var side_sign := -1.0 if sin(phase + float(lane_index) * 2.1) < 0.0 else 1.0
			var detail := PackedVector2Array()
			var sample_count := 5
			var start_t := 0.18 + float(lane_index) * 0.06
			var end_t := 0.90 - float(lane_index) * 0.05
			for sample_index in range(sample_count):
				var u := float(sample_index) / float(sample_count - 1)
				var t := lerpf(start_t, end_t, u)
				var base := _hair_sample_curve(points, t)
				var tangent := _hair_curve_tangent_at(points, t)
				var normal := tangent.rotated(PI * 0.5)
				var width := _hair_groom_width(t, root_width, mid_width, tip_width)
				var weave := sin(phase * 0.91 + _time * (0.72 + wind * 1.1) + u * TAU) * hair_fx_sway * 0.018 * t
				detail.append(base + normal * side_sign * width * (0.24 + float(lane_index) * 0.22 + weave))
			var line_alpha := clampf(alpha * layer_weight * (0.020 + density * 0.018 + wind * 0.014) * (0.50 + highlight_power * 0.50), 0.0, 0.12)
			_draw_hair_gradient_strand(detail, maxf(0.13 * hair_fx_width, 0.035), maxf(0.018 * hair_fx_width, 0.010), Color(0.74, 0.86, 0.82, line_alpha))
			pass_count += 1


func _draw_v4_hair_fx_head_mount(pose: Dictionary) -> void:
	if not hair_fx_enabled:
		return
	var state := _hair_fx_state(pose)
	var alpha := float(state["alpha"])
	if alpha <= 0.001:
		return
	var layers := _hair_direction_layers(pose, state)
	var mount_alpha := _hair_layer_alpha(alpha, 0.72 + float(layers["bun_front_alpha"]) * 0.42)
	_draw_head_mounted_bun(pose, state, mount_alpha)


func _draw_v4_hair_fx_front(pose: Dictionary) -> void:
	if not hair_fx_enabled:
		return
	var state := _hair_fx_state(pose)
	var alpha := float(state["alpha"])
	if alpha <= 0.001:
		return
	var head_center: Vector2 = pose["head_center"]
	var h: Vector2 = pose["heading"]
	h = h.normalized() if h.length_squared() > 0.0001 else Vector2.RIGHT
	var side: Vector2 = pose["side"]
	side = side.normalized() if side.length_squared() > 0.0001 else h.rotated(PI * 0.5)
	var flow: Vector2 = state["flow"]
	var wave_axis: Vector2 = state["wave_axis"]
	var wind := float(state["wind"])
	var turn := float(state["turn"])
	var front_cover := float(state["front_cover"])
	var fast := clampf(float(pose.get("fast_pose", 0.0)), 0.0, 1.0)
	var layers := _hair_direction_layers(pose, state)
	var scalp_alpha := _hair_layer_alpha(alpha, float(layers["root_overlay_alpha"]) + fast * 0.08)
	_draw_hair_fixed_scalp_layer(pose, state, scalp_alpha)
	_draw_hairline_cap(pose, state, scalp_alpha)
	_draw_hair_scalp_root_fans(pose, state, scalp_alpha)
	_draw_hair_crown_overlay(pose, state, _hair_layer_alpha(alpha, float(layers["crown_overlay_alpha"])))
	_draw_hair_side_visibility_overlay(pose, state, _hair_layer_alpha(alpha, float(layers["side_overlay_alpha"])))
	_draw_hair_groom_main_locks(pose, state, "front", alpha)
	var loose_front_count := maxi(hair_fx_front_strands, 0)
	if front_cover > 0.015 and loose_front_count > 0:
		var foreground_alpha := _hair_layer_alpha(alpha * front_cover, float(layers["front_lock_alpha"]))
		var cover_count := maxi(int(roundf(float(loose_front_count) * 0.74)), 1)
		for index in range(cover_count):
			var lane_t := 0.5 if cover_count <= 1 else float(index) / float(cover_count - 1)
			var edge := absf(lane_t - 0.5) * 2.0
			var body := 1.0 - edge * 0.42
			var phase := 11.4 + float(index) * 1.51
			var root := _hair_front_cover_root(pose, lane_t, wind)
			var initial := _hair_front_initial(pose, "cover", lane_t)
			var cover_flow := _hair_lock_tail_flow(flow.lerp(Vector2.DOWN, 0.16), h, side, wave_axis, lane_t, phase, turn * 0.72, wind, 0.10)
			var cover_length := (13.0 + wind * 34.0 + absf(turn) * 9.0) * (0.76 + body * 0.28) * hair_fx_length
			var cover_sway := (1.0 + wind * 4.9 + absf(turn) * 3.2) * hair_fx_sway
			var points := _hair_sculpted_lock_points(root, initial, cover_flow, wave_axis, cover_length, cover_sway, phase, turn * 0.72, wind, pose, 8, lane_t - 0.5, 0.34)
			var cover_alpha := foreground_alpha * body
			_draw_hair_gradient_strand(points, maxf(0.22 * hair_fx_width, 0.055), maxf(0.025 * hair_fx_width, 0.012), Color(0.0, 0.0, 0.0, 0.16 * cover_alpha))
			if hair_fx_highlight > 0.001:
				_draw_hair_gradient_strand(points, maxf(0.070 * hair_fx_width, 0.018), maxf(0.012 * hair_fx_width, 0.006), Color(0.74, 0.86, 0.82, 0.030 * cover_alpha * hair_fx_highlight))
	if loose_front_count > 0:
		var front_alpha := _hair_layer_alpha(alpha, float(layers["front_lock_alpha"]))
		var temple_count := maxi(int(roundf(float(loose_front_count) * 0.42)), 1)
		for index in range(temple_count):
			var lane_t := 0.5 if temple_count <= 1 else float(index) / float(temple_count - 1)
			var body := 1.0 - absf(lane_t - 0.5) * 0.46
			var phase := 15.0 + float(index) * 1.77
			var root := _hair_temple_root(pose, lane_t, wind)
			var initial := _hair_front_initial(pose, "temple", lane_t)
			var temple_flow := _hair_lock_tail_flow(flow.lerp(Vector2.DOWN, 0.42), h, side, wave_axis, lane_t, phase, turn * 0.45, wind, 0.34)
			var length := (9.0 + wind * 18.0 + absf(turn) * 4.0 + body * 2.4) * hair_fx_length
			var points := _hair_sculpted_lock_points(root, initial, temple_flow, wave_axis, length, (0.8 + wind * 2.4) * hair_fx_sway, phase, turn * 0.45, wind, pose, 7, 0.5 - lane_t, 0.28)
			var temple_alpha := front_alpha * body
			_draw_hair_gradient_strand(points, maxf(0.18 * hair_fx_width, 0.045), maxf(0.020 * hair_fx_width, 0.010), Color(0.0, 0.0, 0.0, 0.13 * temple_alpha))
			if hair_fx_highlight > 0.001:
				_draw_hair_gradient_strand(points, maxf(0.055 * hair_fx_width, 0.016), maxf(0.010 * hair_fx_width, 0.006), Color(0.72, 0.84, 0.80, 0.022 * temple_alpha * hair_fx_highlight))
		var bang_count := maxi(ceili(float(loose_front_count) * 0.56), 1)
		for index in range(bang_count):
			var lane_t := 0.5 if bang_count <= 1 else float(index) / float(bang_count - 1)
			var body := 1.0 - absf(lane_t - 0.5) * 0.35
			var phase := 18.8 + float(index) * 1.42
			var root := _hair_front_root(pose, lane_t, wind)
			var initial := _hair_front_initial(pose, "bang", lane_t)
			var front_flow := _hair_lock_tail_flow(flow.lerp(Vector2.DOWN, 0.54), h, side, wave_axis, lane_t, phase, turn * 0.32, wind, 0.42)
			var length := (6.8 + wind * 12.5 + absf(turn) * 3.1 + float(index % 3) * 0.46) * hair_fx_length
			var points := _hair_sculpted_lock_points(root, initial, front_flow, wave_axis, length, (0.62 + wind * 1.65) * hair_fx_sway, phase, turn * 0.32, wind, pose, 6, lane_t - 0.5, 0.18)
			var bang_alpha := front_alpha * body
			_draw_hair_gradient_strand(points, maxf(0.16 * hair_fx_width, 0.040), maxf(0.018 * hair_fx_width, 0.009), Color(0.0, 0.0, 0.0, 0.14 * bang_alpha))
			if hair_fx_highlight > 0.001:
				_draw_hair_gradient_strand(points, maxf(0.050 * hair_fx_width, 0.014), maxf(0.010 * hair_fx_width, 0.006), Color(0.76, 0.88, 0.84, 0.024 * bang_alpha * hair_fx_highlight))


func _hair_fx_state(pose: Dictionary) -> Dictionary:
	var h: Vector2 = pose["heading"]
	h = h.normalized() if h.length_squared() > 0.0001 else Vector2.RIGHT
	var velocity_dir := _velocity.normalized() if _velocity.length_squared() > 1.0 else h
	var speed_ratio := clampf(float(pose.get("speed_ratio", 0.0)), 0.0, 1.0)
	var fast := clampf(float(pose.get("fast_pose", 0.0)), 0.0, 1.0)
	var wind := clampf(_cloth_wind_power(pose) * 0.96 + _boost * 0.10 + speed_ratio * 0.06, 0.0, 1.0)
	var gravity_flow := (Vector2.DOWN - h * 0.12).normalized()
	var speed_flow := gravity_flow.lerp(-velocity_dir, clampf(wind * 0.94 + _boost * 0.08, 0.0, 0.96))
	var cloth_flow := _cloth_direction(pose)
	var flow := gravity_flow.lerp(cloth_flow.lerp(speed_flow, 0.46 + fast * 0.22), smoothstep(0.10, 0.42, wind))
	var slip_sign := clampf(velocity_dir.cross(h), -1.0, 1.0)
	var physics := maxf(hair_fx_physics, 0.0)
	var turn := clampf((_hair_turn_lag + slip_sign * _cloth_turn * 0.32) * hair_fx_turn_lag * (0.55 + physics * 0.45), -1.0, 1.0)
	flow += h.rotated(PI * 0.5) * turn * (0.16 + wind * 0.16)
	if flow.length_squared() <= 0.0001:
		flow = Vector2.DOWN
	flow = flow.normalized()
	var wave_axis := flow.rotated(PI * 0.5)
	var side: Vector2 = pose["side"]
	if side.length_squared() > 0.0001 and wave_axis.dot(side) < 0.0:
		wave_axis = -wave_axis
	var upness := smoothstep(0.12, 0.72, -h.y)
	var side_front := smoothstep(0.20, 0.55, absf(h.x)) * 0.08
	var front_cover := clampf((upness + side_front) * hair_fx_front_cover, 0.0, 1.0)
	var hover_visibility := 1.0 - smoothstep(0.05, 0.34, speed_ratio)
	var alpha := clampf(0.66 + hover_visibility * 0.14 + wind * 0.24 + absf(turn) * 0.10, 0.0, 1.0) * hair_fx_opacity
	return {
		"alpha": alpha,
		"flow": flow,
		"turn": turn,
		"wave_axis": wave_axis.normalized(),
		"wind": wind,
		"front_cover": front_cover,
	}


func _hair_direction_layers(pose: Dictionary, state: Dictionary) -> Dictionary:
	return _hair_direction_occlusion_profile(pose, state)


func _hair_direction_occlusion_profile(pose: Dictionary, state: Dictionary) -> Dictionary:
	var h := _hair_pose_vector(pose, "heading", Vector2.RIGHT)
	var speed_ratio := clampf(float(pose.get("speed_ratio", 0.0)), 0.0, 1.0)
	var wind := clampf(float(state.get("wind", 0.0)), 0.0, 1.0)
	var front_cover := clampf(float(state.get("front_cover", 0.0)), 0.0, 1.0)
	var layer_depth := maxf(hair_fx_layer_depth, 0.0)
	var upness := smoothstep(0.12, 0.84, -h.y)
	var downness := smoothstep(0.12, 0.84, h.y)
	var sideness := smoothstep(0.08, 0.86, absf(h.x))
	var hover := clampf((1.0 - smoothstep(0.05, 0.32, speed_ratio)) * (1.0 - wind * 0.38), 0.0, 1.0)
	var turn_layer := clampf(_hair_layer_lag * hair_fx_turn_lag * (0.72 + layer_depth * 0.28), -1.0, 1.0)
	var turn_front_boost := smoothstep(0.10, 0.72, absf(turn_layer)) * (0.70 + layer_depth * 0.30)
	var front_depth := 0.66 + layer_depth * 0.34
	var near_lane := 0.5
	if h.x > 0.12:
		near_lane = 1.0
	elif h.x < -0.12:
		near_lane = 0.0
	var turn_lane := clampf(0.5 + turn_layer * 0.5, 0.0, 1.0)
	var channels := {
		"back_alpha": 0.72,
		"root_overlay_alpha": 0.58,
		"crown_overlay_alpha": 0.0,
		"side_overlay_alpha": 0.0,
		"bun_front_alpha": 0.0,
		"body_front_alpha": 0.0,
		"front_lock_alpha": 0.62,
	}
	var rules := [
		{"weight": hover, "back_alpha": 0.18, "root_overlay_alpha": 0.24, "crown_overlay_alpha": 0.30, "side_overlay_alpha": 0.56, "bun_front_alpha": 0.16, "body_front_alpha": 0.10},
		{"weight": upness, "back_alpha": 0.18, "root_overlay_alpha": 0.46, "crown_overlay_alpha": 0.82, "bun_front_alpha": 0.72, "body_front_alpha": 0.92, "front_lock_alpha": 0.18},
		{"weight": downness, "back_alpha": 0.14, "root_overlay_alpha": 0.05, "side_overlay_alpha": 0.16, "body_front_alpha": -0.44, "front_lock_alpha": 0.22},
		{"weight": sideness, "back_alpha": 0.10, "root_overlay_alpha": 0.10, "crown_overlay_alpha": 0.16, "side_overlay_alpha": 0.22, "bun_front_alpha": 0.18, "body_front_alpha": 0.66, "front_lock_alpha": 0.12},
		{"weight": turn_front_boost, "back_alpha": -0.08, "root_overlay_alpha": 0.06, "crown_overlay_alpha": 0.10, "side_overlay_alpha": 0.22, "bun_front_alpha": 0.10, "body_front_alpha": 0.18, "front_lock_alpha": 0.12},
	]
	for rule in rules:
		var weight := clampf(float(rule.get("weight", 0.0)), 0.0, 1.5)
		if weight <= 0.001:
			continue
		for key in channels.keys():
			channels[key] = float(channels[key]) + float(rule.get(key, 0.0)) * weight
	channels["back_alpha"] = clampf(float(channels["back_alpha"]) - front_cover * 0.18, 0.56, 1.10)
	channels["root_overlay_alpha"] = clampf(float(channels["root_overlay_alpha"]), 0.48, 1.18)
	channels["crown_overlay_alpha"] = clampf(float(channels["crown_overlay_alpha"]), 0.0, 1.05)
	channels["side_overlay_alpha"] = clampf(float(channels["side_overlay_alpha"]), 0.0, 0.98)
	channels["bun_front_alpha"] = clampf(float(channels["bun_front_alpha"]), 0.0, 0.98)
	channels["body_front_alpha"] = clampf(float(channels["body_front_alpha"]) * front_depth, 0.0, 1.0)
	channels["front_lock_alpha"] = clampf(float(channels["front_lock_alpha"]), 0.48, 1.08)
	channels["up_front"] = upness
	channels["down_back"] = downness
	channels["side_front"] = sideness
	channels["hover_stability"] = hover
	channels["near_lane"] = near_lane
	channels["turn_lane"] = turn_lane
	channels["turn_layer_lag"] = turn_layer
	channels["turn_front_boost"] = turn_front_boost
	return channels


func _hair_groom_lock_defs() -> Array:
	return [
		{"id": "crown_mantle", "region": "crown", "lane": 0.50, "base_layer": "back", "length": 0.82, "width": 1.18, "stiffness": 0.92, "damping": 0.76, "mass": 0.85, "phase": 1.2, "collision": 0.44, "front_bias": 0.35, "highlight": 0.62, "steps": 5},
		{"id": "occipital_left", "region": "occipital", "lane": 0.17, "base_layer": "back", "length": 1.08, "width": 0.96, "stiffness": 0.78, "damping": 0.80, "mass": 1.05, "phase": 2.9, "collision": 0.66, "front_bias": 0.50, "highlight": 0.52, "steps": 5},
		{"id": "occipital_mid_left", "region": "occipital", "lane": 0.35, "base_layer": "back", "length": 1.26, "width": 1.18, "stiffness": 0.70, "damping": 0.82, "mass": 1.18, "phase": 4.4, "collision": 0.72, "front_bias": 0.70, "highlight": 0.78, "steps": 5},
		{"id": "occipital_core", "region": "occipital", "lane": 0.54, "base_layer": "back", "length": 1.38, "width": 1.34, "stiffness": 0.66, "damping": 0.83, "mass": 1.28, "phase": 6.1, "collision": 0.76, "front_bias": 0.78, "highlight": 0.86, "steps": 5},
		{"id": "occipital_right", "region": "occipital", "lane": 0.78, "base_layer": "back", "length": 1.10, "width": 1.02, "stiffness": 0.76, "damping": 0.80, "mass": 1.04, "phase": 7.8, "collision": 0.66, "front_bias": 0.54, "highlight": 0.50, "steps": 5},
		{"id": "nape_near", "region": "nape", "lane": 0.24, "base_layer": "back", "length": 1.45, "width": 0.98, "stiffness": 0.58, "damping": 0.86, "mass": 1.42, "phase": 9.3, "collision": 0.84, "front_bias": 0.88, "highlight": 0.64, "steps": 5},
		{"id": "nape_long", "region": "nape", "lane": 0.62, "base_layer": "back", "length": 1.64, "width": 1.12, "stiffness": 0.52, "damping": 0.88, "mass": 1.56, "phase": 11.0, "collision": 0.88, "front_bias": 0.94, "highlight": 0.74, "steps": 5},
		{"id": "temple_near", "region": "temple", "lane": 0.12, "base_layer": "front", "length": 0.70, "width": 0.52, "stiffness": 0.88, "damping": 0.74, "mass": 0.72, "phase": 12.6, "collision": 0.38, "front_bias": 0.74, "highlight": 0.46, "steps": 4},
		{"id": "forehead_lock", "region": "cover", "lane": 0.56, "base_layer": "front", "length": 0.76, "width": 0.58, "stiffness": 0.86, "damping": 0.76, "mass": 0.78, "phase": 14.2, "collision": 0.36, "front_bias": 0.82, "highlight": 0.58, "steps": 4},
	]


func _update_hair_groom_physics(pose: Dictionary, delta: float) -> void:
	var state := _hair_fx_state(pose)
	var safe_delta := clampf(delta, 0.0, 0.050)
	var frame_factor := clampf(safe_delta / 0.0166667, 0.0, 2.5)
	var flow: Vector2 = state["flow"]
	var wave_axis: Vector2 = state["wave_axis"]
	var wind := clampf(float(state.get("wind", 0.0)), 0.0, 1.0)
	var turn := clampf(float(state.get("turn", 0.0)), -1.0, 1.0)
	var physics := maxf(hair_fx_physics, 0.0)
	var force_scale := physics
	var collision_scale := 0.35 + physics * 0.65
	var follow_scale := 1.0 + maxf(1.0 - physics, 0.0) * 1.55
	var live_ids := {}
	for lock_def in _hair_groom_lock_defs():
		var lock_id := String(lock_def.get("id", ""))
		if lock_id.is_empty():
			continue
		live_ids[lock_id] = true
		var target := _hair_groom_target_points(lock_def, pose, state)
		if target.size() < 2:
			continue
		if not _hair_groom_chains.has(lock_id):
			_hair_groom_chains[lock_id] = {"points": PackedVector2Array(target), "previous": PackedVector2Array(target), "tip_secondary": Vector2.ZERO, "tip_secondary_velocity": Vector2.ZERO}
			continue
		var chain: Dictionary = _hair_groom_chains[lock_id]
		var points: PackedVector2Array = chain.get("points", PackedVector2Array())
		var previous: PackedVector2Array = chain.get("previous", PackedVector2Array())
		if points.size() != target.size() or previous.size() != target.size() or safe_delta <= 0.0001:
			chain["points"] = PackedVector2Array(target)
			chain["previous"] = PackedVector2Array(target)
			chain["tip_secondary"] = Vector2.ZERO
			chain["tip_secondary_velocity"] = Vector2.ZERO
			_hair_groom_chains[lock_id] = chain
			continue

		var stiffness := clampf(float(lock_def.get("stiffness", 0.72)), 0.02, 2.0)
		var damping := clampf(float(lock_def.get("damping", 0.82)) + maxf(1.0 - physics, 0.0) * 0.08, 0.02, 0.99)
		var mass := maxf(float(lock_def.get("mass", 1.0)), 0.05)
		var phase := float(lock_def.get("phase", 0.0))
		var root: Vector2 = target[0]
		var count := target.size()
		points[0] = root
		previous[0] = root
		var hover_motion := clampf(1.0 - wind, 0.0, 1.0)
		var tip_secondary: Vector2 = chain.get("tip_secondary", Vector2.ZERO)
		var tip_secondary_velocity: Vector2 = chain.get("tip_secondary_velocity", Vector2.ZERO)
		var secondary_target := wave_axis * (sin(_time * 0.64 + phase * 1.91) * hair_fx_sway * (0.24 + hover_motion * 0.62 + wind * 0.20) + turn * (1.60 + wind * 1.80)) * force_scale / mass
		secondary_target += Vector2.DOWN * hover_motion * hair_fx_hover_drop * 0.34 * force_scale / mass
		var secondary_spring := clampf((0.11 + stiffness * 0.052) * frame_factor, 0.0, 0.42)
		var secondary_damping := pow(clampf(0.73 - wind * 0.055 + maxf(1.0 - physics, 0.0) * 0.07, 0.52, 0.92), frame_factor)
		tip_secondary_velocity = (tip_secondary_velocity + (secondary_target - tip_secondary) * secondary_spring) * secondary_damping
		tip_secondary += tip_secondary_velocity * frame_factor
		for i in range(1, count):
			var t := float(i) / float(count - 1)
			var old_point: Vector2 = points[i]
			var old_previous: Vector2 = previous[i]
			var velocity := (old_point - old_previous) * pow(damping, frame_factor)
			var target_point: Vector2 = target[i]
			var follow := clampf((0.052 + stiffness * 0.088) * frame_factor * (0.42 + t * 0.86) * follow_scale, 0.010, 0.54)
			var aerodynamic := flow * (0.18 + wind * 1.70) * t * t * frame_factor * force_scale / mass
			var gravity := Vector2.DOWN * (1.0 - wind * 0.58) * (0.16 + hair_fx_hover_drop * 0.22) * pow(t, 1.42) * frame_factor * force_scale / mass
			var turn_lag := wave_axis * turn * (0.36 + t * 1.28) * (0.52 + wind * 0.95) * frame_factor * force_scale / mass
			var micro_sway := wave_axis * sin(_time * (1.35 + wind * 3.10) + phase + t * TAU * 0.72) * hair_fx_sway * (0.025 + wind * 0.085) * t * t * frame_factor * force_scale / mass
			var secondary_tail := tip_secondary * smoothstep(0.42, 1.0, t) * t
			previous[i] = old_point
			points[i] = old_point + velocity + (target_point - old_point) * follow + aerodynamic + gravity + turn_lag + micro_sway + secondary_tail

		var collision_strength := clampf(float(lock_def.get("collision", 0.62)) * collision_scale, 0.0, 5.0)
		var bend_strength := clampf((0.018 + stiffness * 0.052) * (0.45 + physics * 0.55) * frame_factor, 0.0, 0.24)
		var pre_solve_points := PackedVector2Array(points)
		for _iteration in range(4):
			points[0] = root
			for i in range(count - 1):
				var a: Vector2 = points[i]
				var b: Vector2 = points[i + 1]
				var rest_length := maxf(target[i].distance_to(target[i + 1]), 0.001)
				var delta_vec := b - a
				var distance := delta_vec.length()
				if distance <= 0.001:
					continue
				var diff := (distance - rest_length) / distance
				if i == 0:
					b -= delta_vec * diff
					points[i + 1] = b
				else:
					a += delta_vec * diff * 0.48
					b -= delta_vec * diff * 0.52
					points[i] = a
					points[i + 1] = b
			points = _hair_apply_groom_bend_constraints(points, target, bend_strength)
			points[0] = root
			for i in range(1, count):
				var t := float(i) / float(count - 1)
				points[i] = _hair_collision_push(points[i], pose, t, collision_strength * smoothstep(0.08, 0.88, t))
		previous = _hair_absorb_groom_constraint_velocity(points, previous, pre_solve_points, clampf(0.70 + physics * 0.18, 0.0, 0.96))
		previous[0] = root

		chain["points"] = points
		chain["previous"] = previous
		chain["tip_secondary"] = tip_secondary
		chain["tip_secondary_velocity"] = tip_secondary_velocity
		_hair_groom_chains[lock_id] = chain

	for lock_id in _hair_groom_chains.keys():
		if not live_ids.has(lock_id):
			_hair_groom_chains.erase(lock_id)


func _hair_apply_groom_bend_constraints(points: PackedVector2Array, target: PackedVector2Array, strength: float) -> PackedVector2Array:
	if strength <= 0.001 or points.size() < 3 or target.size() != points.size():
		return points
	var count := points.size()
	for i in range(1, count - 1):
		var t := float(i) / float(count - 1)
		var current_mid := (points[i - 1] + points[i + 1]) * 0.5
		var rest_curve: Vector2 = target[i] - (target[i - 1] + target[i + 1]) * 0.5
		var desired := current_mid + rest_curve
		var local_strength := clampf(strength * (0.34 + pow(t, 0.72) * 0.66), 0.0, 0.32)
		points[i] = points[i].lerp(desired, local_strength)
	return points


func _hair_absorb_groom_constraint_velocity(points: PackedVector2Array, previous: PackedVector2Array, pre_solve_points: PackedVector2Array, strength: float) -> PackedVector2Array:
	if strength <= 0.001 or points.size() != previous.size() or points.size() != pre_solve_points.size():
		return previous
	var corrected_previous := PackedVector2Array(previous)
	var safe_strength := clampf(strength, 0.0, 0.98)
	for i in range(1, points.size()):
		var correction: Vector2 = points[i] - pre_solve_points[i]
		corrected_previous[i] += correction * safe_strength
	return corrected_previous


func _hair_groom_target_points(lock_def: Dictionary, pose: Dictionary, state: Dictionary) -> PackedVector2Array:
	var region := String(lock_def.get("region", "occipital"))
	var lane_t := clampf(float(lock_def.get("lane", 0.5)), 0.0, 1.0)
	var phase := float(lock_def.get("phase", 0.0))
	var h := _hair_pose_vector(pose, "heading", Vector2.RIGHT)
	var side := _hair_pose_vector(pose, "side", Vector2.RIGHT)
	var flow: Vector2 = state["flow"]
	var wave_axis: Vector2 = state["wave_axis"]
	var wind := clampf(float(state.get("wind", 0.0)), 0.0, 1.0)
	var turn := clampf(float(state.get("turn", 0.0)), -1.0, 1.0)
	var head_radius := _hair_head_radius(pose)
	var volume := maxf(hair_fx_volume, 0.0)
	var physics := maxf(hair_fx_physics, 0.0)
	var body := 1.0 - absf(lane_t - 0.5) * 0.36
	var length_base := head_radius * (2.45 + wind * 2.20)
	var gravity_bias := 0.18
	var collision_strength := float(lock_def.get("collision", 0.62))
	match region:
		"crown":
			length_base = head_radius * (2.20 + wind * 1.05)
			gravity_bias = 0.08
		"nape":
			length_base = head_radius * (3.65 + wind * 2.05)
			gravity_bias = 0.34
		"temple":
			length_base = head_radius * (1.32 + wind * 0.52)
			gravity_bias = 0.44
			collision_strength *= 0.72
		"cover":
			length_base = head_radius * (1.52 + wind * 0.72)
			gravity_bias = 0.22
			collision_strength *= 0.64
		_:
			length_base = head_radius * (3.02 + wind * 1.70)
			gravity_bias = 0.18
	var root := _hair_groom_root_for_def(lock_def, pose, state)
	var initial := _hair_groom_initial_for_def(lock_def, pose)
	var flow_for_lock := flow
	if region == "temple" or region == "cover":
		flow_for_lock = flow.lerp(Vector2.DOWN, 0.38)
	elif region == "nape":
		flow_for_lock = flow.lerp(Vector2.DOWN, 0.12)
	var tail_flow := _hair_lock_tail_flow(flow_for_lock, h, side, wave_axis, lane_t, phase, turn, wind, gravity_bias)
	var dynamic_length := length_base * float(lock_def.get("length", 1.0)) * (0.80 + body * 0.22)
	dynamic_length *= (1.0 + _boost * 0.16 + absf(turn) * 0.18 + wind * 0.08)
	dynamic_length *= (0.86 + volume * 0.14)
	dynamic_length *= hair_fx_length
	var sway := (0.82 + wind * 4.15 + absf(turn) * 2.70) * hair_fx_sway * physics * float(lock_def.get("width", 1.0))
	collision_strength *= 0.35 + physics * 0.65
	var steps := maxi(int(lock_def.get("steps", 5)), 3)
	return _hair_sculpted_lock_points(root, initial, tail_flow, wave_axis, dynamic_length, sway, phase, turn, wind, pose, steps, lane_t - 0.5, collision_strength)


func _hair_groom_root_for_def(lock_def: Dictionary, pose: Dictionary, state: Dictionary) -> Vector2:
	var region := String(lock_def.get("region", "occipital"))
	var lane_t := clampf(float(lock_def.get("lane", 0.5)), 0.0, 1.0)
	var wind := clampf(float(state.get("wind", 0.0)), 0.0, 1.0)
	match region:
		"temple":
			return _hair_temple_root(pose, lane_t, wind)
		"cover":
			return _hair_front_cover_root(pose, lane_t, wind)
		"bang":
			return _hair_front_root(pose, lane_t, wind)
		_:
			return _hair_back_root(pose, region, lane_t, wind)


func _hair_groom_initial_for_def(lock_def: Dictionary, pose: Dictionary) -> Vector2:
	var region := String(lock_def.get("region", "occipital"))
	var lane_t := clampf(float(lock_def.get("lane", 0.5)), 0.0, 1.0)
	match region:
		"temple":
			return _hair_front_initial(pose, "temple", lane_t)
		"cover":
			return _hair_front_initial(pose, "cover", lane_t)
		"bang":
			return _hair_front_initial(pose, "bang", lane_t)
		_:
			return _hair_back_initial(pose, region, lane_t)


func _hair_groom_chain_points(lock_id: String, fallback: PackedVector2Array) -> PackedVector2Array:
	if _hair_groom_chains.has(lock_id):
		var chain: Dictionary = _hair_groom_chains[lock_id]
		var points: PackedVector2Array = chain.get("points", PackedVector2Array())
		if points.size() >= 2:
			return points
	return fallback


func _hair_groom_def_by_id(lock_id: String) -> Dictionary:
	for lock_def in _hair_groom_lock_defs():
		if String(lock_def.get("id", "")) == lock_id:
			return lock_def
	return {}


func _hair_groom_points_for_id(lock_id: String, pose: Dictionary, state: Dictionary) -> PackedVector2Array:
	var lock_def := _hair_groom_def_by_id(lock_id)
	if lock_def.is_empty():
		return PackedVector2Array()
	var target := _hair_groom_target_points(lock_def, pose, state)
	return _hair_groom_chain_points(lock_id, target)


func _hair_groom_volume_points_for_id(lock_id: String, pose: Dictionary, state: Dictionary, physical_mix: float) -> PackedVector2Array:
	var lock_def := _hair_groom_def_by_id(lock_id)
	if lock_def.is_empty():
		return PackedVector2Array()
	var target := _hair_groom_target_points(lock_def, pose, state)
	var points := _hair_groom_chain_points(lock_id, target)
	if points.size() != target.size():
		return target
	var blended := PackedVector2Array()
	var safe_mix := clampf(physical_mix, 0.0, 1.0)
	for index in range(target.size()):
		var t := float(index) / maxf(float(target.size() - 1), 1.0)
		var tip_mix := clampf(safe_mix * (0.40 + t * 0.60), 0.0, 1.0)
		blended.append(target[index].lerp(points[index], tip_mix))
	return blended


func _draw_hair_groom_main_locks(pose: Dictionary, state: Dictionary, layer: String, alpha: float) -> void:
	if alpha <= 0.001:
		return
	var wind := clampf(float(state.get("wind", 0.0)), 0.0, 1.0)
	var volume := maxf(hair_fx_volume, 0.0)
	var root_ink := maxf(hair_fx_root_ink, 0.0)
	var highlight_power := maxf(hair_fx_highlight, 0.0)
	var width_volume := 0.68 + volume * 0.32
	for lock_def in _hair_groom_lock_defs():
		var lock_id := String(lock_def.get("id", ""))
		var layer_weight := _hair_groom_layer_weight(lock_def, layer, pose, state)
		if lock_id.is_empty() or layer_weight <= 0.001:
			continue
		var lane_t := clampf(float(lock_def.get("lane", 0.5)), 0.0, 1.0)
		var body := 1.0 - absf(lane_t - 0.5) * 0.36
		var width_scale := float(lock_def.get("width", 1.0))
		var target := _hair_groom_target_points(lock_def, pose, state)
		var points := _hair_groom_chain_points(lock_id, target)
		var lock_alpha := clampf(alpha * layer_weight, 0.0, 1.0)
		var root_width := (3.50 + body * 1.15) * width_scale * hair_fx_width * (0.82 + root_ink * 0.18)
		var mid_width := (5.10 + body * 3.20 + wind * 1.35) * width_scale * hair_fx_width * width_volume
		var tip_width := (0.34 + body * 0.34) * width_scale * hair_fx_width * (0.78 + volume * 0.22)
		if layer == "front":
			root_width *= 0.64
			mid_width *= 0.56
			tip_width *= 0.62
		var fill := Color(0.003, 0.004, 0.005, clampf((0.30 + body * 0.20 + wind * 0.05 + volume * 0.08 + root_ink * 0.05) * lock_alpha, 0.0, 1.0))
		var rim := Color(0.0, 0.0, 0.0, clampf((0.18 + body * 0.13 + wind * 0.035 + volume * 0.055) * lock_alpha, 0.0, 1.0))
		var highlight_strength := float(lock_def.get("highlight", 0.55)) * highlight_power
		var highlight := Color(0.72, 0.86, 0.82, clampf((0.028 + wind * 0.045) * lock_alpha * highlight_strength, 0.0, 0.18))
		_draw_hair_groom_lock(points, root_width, mid_width, tip_width, fill, rim, highlight)
		_draw_hair_groom_surface_details(points, root_width, mid_width, tip_width, lock_alpha, highlight_strength, float(lock_def.get("phase", 0.0)), layer)
		if highlight_strength > 0.68 and layer != "front":
			_draw_hair_gradient_strand(points, maxf(mid_width * 0.11, 0.08), maxf(tip_width * 0.12, 0.035), Color(0.78, 0.90, 0.86, 0.040 * lock_alpha * highlight_strength))


func _hair_groom_layer_weight(lock_def: Dictionary, layer: String, pose: Dictionary, state: Dictionary) -> float:
	var layers := _hair_direction_layers(pose, state)
	var base_layer := String(lock_def.get("base_layer", "back"))
	var region := String(lock_def.get("region", "occipital"))
	var lane_t := clampf(float(lock_def.get("lane", 0.5)), 0.0, 1.0)
	var upness := clampf(float(layers.get("up_front", 0.0)), 0.0, 1.0)
	var downness := clampf(float(layers.get("down_back", 0.0)), 0.0, 1.0)
	var sideness := clampf(float(layers.get("side_front", 0.0)), 0.0, 1.0)
	var near_lane := clampf(float(layers.get("near_lane", 0.5)), 0.0, 1.0)
	var near_weight := clampf(1.0 - absf(lane_t - near_lane) * 1.75, 0.0, 1.0)
	var front_bias := clampf(float(lock_def.get("front_bias", 0.55)), 0.0, 1.2)
	var body_front := clampf(float(layers.get("body_front_alpha", 0.0)), 0.0, 1.0)
	var turn_layer := clampf(float(layers.get("turn_layer_lag", 0.0)), -1.0, 1.0)
	var turn_front_boost := clampf(float(layers.get("turn_front_boost", 0.0)), 0.0, 1.0)
	var layer_depth := maxf(hair_fx_layer_depth, 0.0)
	var depth_weight := 0.62 + layer_depth * 0.38
	var turn_lane := clampf(float(layers.get("turn_lane", 0.5)), 0.0, 1.0)
	var turn_lane_weight := clampf(1.0 - absf(lane_t - turn_lane) * 1.85, 0.0, 1.0)
	if layer == "back":
		if base_layer == "front":
			return 0.0
		var pulled_front := body_front * front_bias * (0.48 + near_weight * 0.36 + turn_front_boost * turn_lane_weight * 0.28) * depth_weight
		return clampf(1.0 - pulled_front * 0.48 + downness * 0.14, 0.20, 1.12)
	if layer == "body_front":
		if base_layer == "front":
			return 0.0
		var region_weight := 0.34
		if region == "nape":
			region_weight = 0.92
		elif region == "occipital":
			region_weight = 0.72
		elif region == "crown":
			region_weight = 0.28
		var side_front := sideness * near_weight * 0.42
		var turn_front := turn_front_boost * turn_lane_weight * 0.42
		return clampf((body_front + side_front + turn_front + upness * 0.24) * front_bias * region_weight * depth_weight - downness * 0.36, 0.0, 1.0)
	if layer == "front":
		if base_layer != "front":
			return clampf((upness * 0.18 + turn_front_boost * turn_lane_weight * 0.08) * front_bias, 0.0, 0.34)
		var front_volume := clampf(float(maxi(hair_fx_front_strands, 0)) / 6.0, 0.0, 1.0)
		return clampf(float(layers.get("front_lock_alpha", 0.0)) * front_bias * (0.26 + front_volume * 0.74 + turn_front_boost * 0.16), 0.0, 1.0)
	return 0.0


func _hair_layer_alpha(base: float, multiplier: float) -> float:
	return clampf(base * multiplier, 0.0, 1.0)


func _hair_scalp_alpha(alpha: float) -> float:
	if alpha <= 0.001 or not hair_fx_enabled:
		return 0.0
	return 1.0


func _hair_head_radius(pose: Dictionary) -> float:
	var head_scale := clampf(float(pose.get("head_scale", 1.0)), 0.35, 2.0)
	return 10.8 * head_scale


func _hair_pose_vector(pose: Dictionary, key: String, fallback: Vector2) -> Vector2:
	var value: Vector2 = pose.get(key, fallback)
	if value.length_squared() <= 0.0001:
		return fallback
	return value.normalized()


func _hair_scalp_anchor(pose: Dictionary, region: String, lane_t: float, depth: float, wind: float) -> Vector2:
	var head_center: Vector2 = pose["head_center"]
	var h := _hair_pose_vector(pose, "heading", Vector2.RIGHT)
	var side := _hair_pose_vector(pose, "side", Vector2.RIGHT)
	var back := -h
	var head_radius := _hair_head_radius(pose)
	var u := clampf(lane_t * 2.0 - 1.0, -1.0, 1.0)
	var safe_depth := clampf(depth, 0.0, 1.0)
	var spread := clampf(hair_fx_spread, 0.20, 5.00)
	var root := head_center
	match region:
		"crown":
			var crown_arc := 1.0 - absf(u) * 0.36
			root += back * head_radius * (0.28 + crown_arc * 0.10 + safe_depth * 0.08)
			root += Vector2.UP * head_radius * (0.52 + crown_arc * 0.16 + safe_depth * 0.04)
			root += side * u * head_radius * (0.12 + safe_depth * 0.04) * spread
		"nape":
			root += back * head_radius * (0.34 + safe_depth * 0.10 + sin(lane_t * 6.9) * 0.04)
			root += Vector2.DOWN * head_radius * (0.24 + lane_t * 0.36 + safe_depth * 0.08)
			root += side * u * head_radius * (0.09 + safe_depth * 0.03) * spread
		"cover":
			var cover_arc := 1.0 - absf(u) * 0.30
			root += h * head_radius * (0.16 + safe_depth * 0.06 + wind * 0.025)
			root += side * u * head_radius * (0.28 + safe_depth * 0.08) * spread
			root += Vector2.UP * head_radius * (0.48 + cover_arc * 0.13 + safe_depth * 0.02)
		"bang":
			var brow_arc := 1.0 - absf(u) * 0.42
			root += h * head_radius * (0.46 + safe_depth * 0.08 + wind * 0.025)
			root += side * u * head_radius * (0.24 + safe_depth * 0.08) * spread
			root += Vector2.UP * head_radius * (0.18 + brow_arc * 0.18 + safe_depth * 0.02)
		"temple":
			var temple_side := -1.0 if lane_t < 0.5 else 1.0
			root += h * head_radius * (0.28 + safe_depth * 0.08 + wind * 0.02)
			root += side * temple_side * head_radius * (0.28 + safe_depth * 0.11 + absf(u) * 0.08) * spread
			root += Vector2.DOWN * head_radius * (0.01 + absf(u) * 0.10 + safe_depth * 0.04)
		"bun":
			root += back * head_radius * (0.62 + safe_depth * 0.10 + wind * 0.04)
			root += Vector2.UP * head_radius * (0.62 + safe_depth * 0.08)
		_:
			root += back * head_radius * (0.40 + safe_depth * 0.10 + sin(lane_t * 9.4 + 0.4) * 0.04)
			root += Vector2.UP * head_radius * lerpf(0.34, -0.18, lane_t)
			root += side * u * head_radius * (0.11 + safe_depth * 0.04) * spread
	root += back * sin(lane_t * 31.7 + 0.43) * head_radius * 0.018
	root += side * sin(lane_t * 24.1 + 1.7) * head_radius * 0.014
	root += back * wind * head_radius * 0.025
	return root


func _hair_scalp_mask_distance(pose: Dictionary, point: Vector2) -> float:
	var geometry := _hair_scalp_mask_geometry(pose)
	var center: Vector2 = geometry["center"]
	var side: Vector2 = geometry["side"]
	var radius_x := float(geometry["radius_x"])
	var radius_y := float(geometry["radius_y"])
	var delta := point - center
	var ellipse_space := Vector2(delta.dot(side) / radius_x, delta.dot(Vector2.UP) / radius_y)
	return (ellipse_space.length() - 1.0) * minf(radius_x, radius_y)


func _hair_is_inside_scalp_mask(pose: Dictionary, point: Vector2, tolerance: float) -> bool:
	return _hair_scalp_mask_distance(pose, point) <= tolerance


func _hair_scalp_mask_geometry(pose: Dictionary) -> Dictionary:
	var head_center: Vector2 = pose["head_center"]
	var h := _hair_pose_vector(pose, "heading", Vector2.RIGHT)
	var side := _hair_pose_vector(pose, "side", Vector2.RIGHT)
	var head_radius := _hair_head_radius(pose)
	var spread := clampf(hair_fx_spread, 0.20, 5.00)
	return {
		"center": head_center + Vector2.UP * head_radius * 0.14 - h * head_radius * 0.07,
		"side": side,
		"radius_x": head_radius * maxf(0.82, 0.50 + spread * 0.44),
		"radius_y": head_radius * 1.26,
	}


func _hair_back_root(pose: Dictionary, region: String, lane_t: float, wind: float) -> Vector2:
	match region:
		"crown":
			return _hair_scalp_anchor(pose, "crown", lane_t, 0.42, wind)
		"nape":
			return _hair_scalp_anchor(pose, "nape", lane_t, 0.50, wind)
		_:
			return _hair_scalp_anchor(pose, "occipital", lane_t, 0.50, wind)


func _hair_front_cover_root(pose: Dictionary, lane_t: float, wind: float) -> Vector2:
	return _hair_scalp_anchor(pose, "cover", lane_t, 0.74, wind)


func _hair_front_root(pose: Dictionary, lane_t: float, wind: float) -> Vector2:
	return _hair_scalp_anchor(pose, "bang", lane_t, 0.78, wind)


func _hair_temple_root(pose: Dictionary, lane_t: float, wind: float) -> Vector2:
	return _hair_scalp_anchor(pose, "temple", lane_t, 0.72, wind)


func _hair_bun_center(pose: Dictionary, wind: float) -> Vector2:
	return _hair_scalp_anchor(pose, "bun", 0.50, 0.52, wind)


func _hair_back_initial(pose: Dictionary, region: String, lane_t: float) -> Vector2:
	var h := _hair_pose_vector(pose, "heading", Vector2.RIGHT)
	var side := _hair_pose_vector(pose, "side", Vector2.RIGHT)
	var u := clampf(lane_t * 2.0 - 1.0, -1.0, 1.0)
	var initial := -h
	match region:
		"crown":
			initial = -h * 0.78 + Vector2.UP * 0.20 + side * u * 0.08
		"nape":
			initial = -h * 0.34 + Vector2.DOWN * 0.86 + side * u * 0.10
		_:
			initial = -h * 0.58 + Vector2.DOWN * lerpf(-0.16, 0.32, lane_t) + side * u * 0.08
	return initial.normalized() if initial.length_squared() > 0.0001 else Vector2.DOWN


func _hair_front_initial(pose: Dictionary, region: String, lane_t: float) -> Vector2:
	var h := _hair_pose_vector(pose, "heading", Vector2.RIGHT)
	var side := _hair_pose_vector(pose, "side", Vector2.RIGHT)
	var u := clampf(lane_t * 2.0 - 1.0, -1.0, 1.0)
	var initial := Vector2.DOWN
	match region:
		"cover":
			initial = h * 0.24 + Vector2.DOWN * 0.38 + side * u * 0.18
		"temple":
			initial = Vector2.DOWN * 0.92 + h * 0.10 + side * u * 0.12
		_:
			initial = Vector2.DOWN * 0.74 + h * 0.28 + side * u * 0.14
	return initial.normalized() if initial.length_squared() > 0.0001 else Vector2.DOWN


func _draw_hair_back_mass(pose: Dictionary, state: Dictionary, alpha: float) -> void:
	if alpha <= 0.001:
		return
	var has_dynamic_volume := _draw_hair_dynamic_back_volume(pose, state, alpha)
	var head_center: Vector2 = pose["head_center"]
	var h := _hair_pose_vector(pose, "heading", Vector2.RIGHT)
	var side := _hair_pose_vector(pose, "side", Vector2.RIGHT)
	var flow: Vector2 = state["flow"]
	var wind := float(state["wind"])
	var head_radius := _hair_head_radius(pose)
	var volume := maxf(hair_fx_volume, 0.0)
	var volume_width := 0.70 + volume * 0.30
	var volume_length := 0.72 + volume * 0.28
	var bun := _hair_bun_center(pose, wind)
	var nape := _hair_back_root(pose, "nape", 0.52, wind)
	var tail_flow := flow.lerp(Vector2.DOWN, (1.0 - wind) * 0.22).normalized()
	var tail_a := nape + tail_flow * head_radius * (2.2 + wind * 2.6) * volume_length - side * head_radius * 0.42 * hair_fx_spread * volume_width
	var tail_b := nape + tail_flow.rotated(0.18) * head_radius * (2.8 + wind * 3.2) * volume_length + side * head_radius * 0.22 * hair_fx_spread * volume_width
	var points := PackedVector2Array([
		head_center - h * head_radius * 0.52 + Vector2.UP * head_radius * 0.48,
		bun + Vector2.UP * head_radius * 0.24,
		bun - side * head_radius * 0.28,
		tail_a,
		tail_b,
		nape + side * head_radius * 0.24,
		head_center - h * head_radius * 0.46 + Vector2.DOWN * head_radius * 0.20,
	])
	var static_alpha := alpha * (0.11 if has_dynamic_volume else 0.34)
	var static_rim := alpha * (0.08 if has_dynamic_volume else 0.18)
	_draw_hair_shape_fan(points, Color(0.002, 0.003, 0.004, static_alpha), Color(0.0, 0.0, 0.0, static_rim))


func _draw_hair_dynamic_back_volume(pose: Dictionary, state: Dictionary, alpha: float) -> bool:
	if alpha <= 0.001:
		return false
	var head_center: Vector2 = pose["head_center"]
	var h := _hair_pose_vector(pose, "heading", Vector2.RIGHT)
	var side := _hair_pose_vector(pose, "side", Vector2.RIGHT)
	var wind := clampf(float(state.get("wind", 0.0)), 0.0, 1.0)
	var head_radius := _hair_head_radius(pose)
	var spread := clampf(hair_fx_spread, 0.4, 5.0)
	var volume := maxf(hair_fx_volume, 0.0)
	var volume_width := 0.68 + volume * 0.32
	var volume_length := 0.72 + volume * 0.28
	var highlight_power := maxf(hair_fx_highlight, 0.0)
	var physical_mix := clampf(0.26 + wind * 0.14 + absf(float(state.get("turn", 0.0))) * 0.10, 0.22, 0.52)
	var occ_left := _hair_groom_volume_points_for_id("occipital_left", pose, state, physical_mix)
	var occ_mid_left := _hair_groom_volume_points_for_id("occipital_mid_left", pose, state, physical_mix)
	var occ_core := _hair_groom_volume_points_for_id("occipital_core", pose, state, physical_mix)
	var occ_right := _hair_groom_volume_points_for_id("occipital_right", pose, state, physical_mix)
	var nape_near := _hair_groom_volume_points_for_id("nape_near", pose, state, physical_mix)
	var nape_long := _hair_groom_volume_points_for_id("nape_long", pose, state, physical_mix)
	if occ_left.size() < 2 or occ_core.size() < 2 or occ_right.size() < 2 or nape_long.size() < 2:
		return false
	var bun := _hair_bun_center(pose, wind)
	var left_mid := _hair_offset_sample(occ_left, 0.34, -side, head_radius * (0.18 + spread * 0.035) * volume_width)
	var left_body := _hair_offset_sample(occ_mid_left, 0.66, -side, head_radius * (0.22 + spread * 0.045) * volume_width)
	var lower_near := _hair_offset_sample(nape_near, 0.76, -side, head_radius * (0.16 + spread * 0.030) * volume_width) if nape_near.size() >= 2 else _hair_offset_sample(occ_mid_left, 0.84, -side, head_radius * 0.20 * volume_width)
	var long_tip := _hair_offset_sample(nape_long, 0.96, Vector2.DOWN, head_radius * (0.12 + wind * 0.08) * volume_length)
	var core_tip := _hair_offset_sample(occ_core, 0.88, h.rotated(PI * 0.5), head_radius * 0.10 * volume_width)
	var right_body := _hair_offset_sample(occ_right, 0.70, side, head_radius * (0.20 + spread * 0.040) * volume_width)
	var right_mid := _hair_offset_sample(occ_right, 0.32, side, head_radius * (0.17 + spread * 0.035) * volume_width)
	var crown_left := head_center - h * head_radius * 0.52 - side * head_radius * (0.40 + spread * 0.10) * volume_width + Vector2.UP * head_radius * 0.42
	var crown_peak := bun + Vector2.UP * head_radius * 0.26 - h * head_radius * 0.06
	var crown_right := head_center - h * head_radius * 0.42 + side * head_radius * (0.38 + spread * 0.09) * volume_width + Vector2.UP * head_radius * 0.36
	var neck_close := head_center - h * head_radius * 0.42 + Vector2.DOWN * head_radius * 0.20
	var silhouette := PackedVector2Array([
		neck_close - side * head_radius * 0.32,
		crown_left,
		crown_peak,
		crown_right,
		right_mid,
		right_body,
		core_tip,
		long_tip,
		lower_near,
		left_body,
		left_mid,
	])
	var shadow := Color(0.0, 0.0, 0.0, clampf(alpha * (0.18 + volume * 0.12), 0.0, 1.0))
	var fill := Color(0.002, 0.003, 0.004, clampf(alpha * (0.34 + volume * 0.12 + wind * 0.08), 0.0, 1.0))
	var rim := Color(0.0, 0.0, 0.0, clampf(alpha * (0.14 + volume * 0.08), 0.0, 1.0))
	var shadow_points := PackedVector2Array()
	for point in silhouette:
		shadow_points.append(point + Vector2(0.90, 1.10))
	_draw_hair_shape_fan(shadow_points, shadow, Color(0.0, 0.0, 0.0, 0.0))
	_draw_hair_shape_fan(silhouette, fill, rim)
	var inner := PackedVector2Array([crown_peak.lerp(crown_right, 0.24), right_body.lerp(core_tip, 0.30), core_tip.lerp(long_tip, 0.52), left_body.lerp(lower_near, 0.30), crown_left.lerp(crown_peak, 0.22)])
	_draw_hair_shape_fan(inner, Color(0.010, 0.012, 0.013, alpha * (0.07 + volume * 0.04)), Color(0.72, 0.84, 0.80, alpha * 0.024 * highlight_power))
	_draw_hair_volume_plane_details(crown_left, crown_peak, crown_right, left_mid, left_body, lower_near, long_tip, core_tip, right_body, right_mid, alpha, volume, highlight_power, head_radius, volume_width)
	var valley_a := PackedVector2Array([crown_peak.lerp(crown_left, 0.34), left_body.lerp(core_tip, 0.18), long_tip.lerp(lower_near, 0.32)])
	var valley_b := PackedVector2Array([crown_peak.lerp(crown_right, 0.42), right_body.lerp(core_tip, 0.24), long_tip.lerp(core_tip, 0.24)])
	var valley_alpha := clampf(alpha * (0.040 + volume * 0.035), 0.0, 0.18)
	_draw_hair_gradient_strand(valley_a, maxf(head_radius * 0.075 * volume_width, 0.35), 0.08, Color(0.0, 0.0, 0.0, valley_alpha))
	_draw_hair_gradient_strand(valley_b, maxf(head_radius * 0.060 * volume_width, 0.30), 0.07, Color(0.0, 0.0, 0.0, valley_alpha * 0.78))
	return true


func _draw_hair_fixed_scalp_layer(pose: Dictionary, _state: Dictionary, alpha: float) -> void:
	if alpha <= 0.001:
		return
	var h := _hair_pose_vector(pose, "heading", Vector2.RIGHT)
	var side := _hair_pose_vector(pose, "side", Vector2.RIGHT)
	var fixed_wind := 0.0
	var head_radius := _hair_head_radius(pose)
	var root_ink := maxf(hair_fx_root_ink, 0.0)
	var scalp_alpha := _hair_scalp_alpha(alpha)
	var occ_left := _hair_scalp_anchor(pose, "occipital", 0.12, 0.54, fixed_wind)
	var occ_right := _hair_scalp_anchor(pose, "occipital", 0.88, 0.54, fixed_wind)
	var nape_left := _hair_scalp_anchor(pose, "nape", 0.20, 0.50, fixed_wind)
	var nape_right := _hair_scalp_anchor(pose, "nape", 0.80, 0.50, fixed_wind)
	var crown_left := _hair_scalp_anchor(pose, "crown", 0.12, 0.50, fixed_wind)
	var crown_peak := _hair_scalp_anchor(pose, "crown", 0.50, 0.60, fixed_wind)
	var crown_right := _hair_scalp_anchor(pose, "crown", 0.88, 0.50, fixed_wind)
	var temple_left := _hair_scalp_anchor(pose, "temple", 0.0, 0.64, fixed_wind)
	var temple_right := _hair_scalp_anchor(pose, "temple", 1.0, 0.64, fixed_wind)
	var fixed_points := PackedVector2Array([
		nape_left - side * head_radius * 0.12,
		occ_left - side * head_radius * 0.08,
		crown_left,
		crown_peak + Vector2.UP * head_radius * 0.05,
		crown_right,
		occ_right + side * head_radius * 0.08,
		nape_right + side * head_radius * 0.12,
		temple_right - h * head_radius * 0.03,
		temple_left - h * head_radius * 0.03,
	])
	var shadow_points := PackedVector2Array()
	for point in fixed_points:
		shadow_points.append(point + Vector2(0.55, 0.80))
	_draw_hair_shape_fan(shadow_points, Color(0.0, 0.0, 0.0, clampf(0.22 * scalp_alpha, 0.0, 1.0)), Color(0.0, 0.0, 0.0, 0.0))
	_draw_hair_shape_fan(fixed_points, Color(0.003, 0.004, 0.005, scalp_alpha), Color(0.0, 0.0, 0.0, clampf((0.40 + root_ink * 0.16) * scalp_alpha, 0.0, 1.0)))


func _draw_hair_volume_plane_details(
		crown_left: Vector2,
		crown_peak: Vector2,
		crown_right: Vector2,
		left_mid: Vector2,
		left_body: Vector2,
		lower_near: Vector2,
		long_tip: Vector2,
		core_tip: Vector2,
		right_body: Vector2,
		right_mid: Vector2,
		alpha: float,
		volume: float,
		highlight_power: float,
		head_radius: float,
		volume_width: float
) -> void:
	var plane_alpha := clampf(alpha * (0.030 + volume * 0.026), 0.0, 0.16)
	if plane_alpha <= 0.001:
		return
	var near_plane := PackedVector2Array([
		crown_peak.lerp(crown_right, 0.52),
		crown_right.lerp(right_mid, 0.55),
		right_body,
		core_tip.lerp(long_tip, 0.36),
		crown_peak.lerp(core_tip, 0.44),
	])
	var far_plane := PackedVector2Array([
		crown_peak.lerp(crown_left, 0.50),
		crown_left.lerp(left_mid, 0.56),
		left_body,
		lower_near.lerp(long_tip, 0.36),
		crown_peak.lerp(core_tip, 0.38),
	])
	var lower_plane := PackedVector2Array([
		left_body.lerp(lower_near, 0.44),
		lower_near.lerp(long_tip, 0.60),
		long_tip,
		right_body.lerp(core_tip, 0.72),
		core_tip.lerp(long_tip, 0.38),
	])
	_draw_hair_shape_fan(near_plane, Color(0.0, 0.0, 0.0, plane_alpha * 0.82), Color(0.0, 0.0, 0.0, plane_alpha * 0.22))
	_draw_hair_shape_fan(far_plane, Color(0.0, 0.0, 0.0, plane_alpha * 0.68), Color(0.0, 0.0, 0.0, plane_alpha * 0.18))
	_draw_hair_shape_fan(lower_plane, Color(0.0, 0.0, 0.0, plane_alpha), Color(0.0, 0.0, 0.0, plane_alpha * 0.24))
	var highlight_alpha := clampf(alpha * highlight_power * (0.018 + volume * 0.014), 0.0, 0.08)
	if highlight_alpha <= 0.001:
		return
	var crown_gloss := PackedVector2Array([
		crown_left.lerp(crown_peak, 0.62),
		crown_peak.lerp(crown_right, 0.52),
		right_mid.lerp(right_body, 0.26),
	])
	var core_gloss := PackedVector2Array([
		crown_peak.lerp(core_tip, 0.22),
		core_tip.lerp(long_tip, 0.30),
		long_tip.lerp(lower_near, 0.24),
	])
	_draw_hair_gradient_strand(crown_gloss, maxf(head_radius * 0.026 * volume_width, 0.12), 0.018, Color(0.76, 0.88, 0.84, highlight_alpha))
	_draw_hair_gradient_strand(core_gloss, maxf(head_radius * 0.020 * volume_width, 0.10), 0.014, Color(0.72, 0.84, 0.80, highlight_alpha * 0.72))


func _draw_hair_body_front_volume(pose: Dictionary, state: Dictionary, alpha: float) -> void:
	if alpha <= 0.001:
		return
	var occ_left := _hair_groom_points_for_id("occipital_left", pose, state)
	var occ_core := _hair_groom_points_for_id("occipital_core", pose, state)
	var occ_right := _hair_groom_points_for_id("occipital_right", pose, state)
	var nape_near := _hair_groom_points_for_id("nape_near", pose, state)
	var nape_long := _hair_groom_points_for_id("nape_long", pose, state)
	if occ_core.size() < 2 or nape_long.size() < 2:
		return
	var h := _hair_pose_vector(pose, "heading", Vector2.RIGHT)
	var side := _hair_pose_vector(pose, "side", Vector2.RIGHT)
	var wind := clampf(float(state.get("wind", 0.0)), 0.0, 1.0)
	var volume := maxf(hair_fx_volume, 0.0)
	var highlight_power := maxf(hair_fx_highlight, 0.0)
	var head_radius := _hair_head_radius(pose)
	var near_occ := occ_core
	if h.x > 0.16 and occ_right.size() >= 2:
		near_occ = occ_right
	elif h.x < -0.16 and occ_left.size() >= 2:
		near_occ = occ_left
	var top := _hair_sample_curve(near_occ, 0.16)
	var shoulder_cover := _hair_offset_sample(near_occ, 0.46, side * signf(h.x if absf(h.x) > 0.05 else 1.0), head_radius * (0.12 + volume * 0.04))
	var lower_cover := _hair_sample_curve(nape_long, 0.78)
	var tip := _hair_offset_sample(nape_long, 0.96, Vector2.DOWN, head_radius * (0.08 + wind * 0.08))
	var inner := _hair_sample_curve(occ_core, 0.42)
	var nape_mid := _hair_sample_curve(nape_near, 0.68) if nape_near.size() >= 2 else _hair_sample_curve(nape_long, 0.54)
	var front_mass := PackedVector2Array([
		top,
		shoulder_cover,
		lower_cover,
		tip,
		nape_mid,
		inner,
	])
	var mass_alpha := clampf(alpha * (0.10 + volume * 0.050), 0.0, 0.34)
	_draw_hair_shape_fan(front_mass, Color(0.002, 0.003, 0.004, mass_alpha), Color(0.0, 0.0, 0.0, mass_alpha * 0.42))
	var seam_alpha := clampf(alpha * (0.038 + volume * 0.020), 0.0, 0.14)
	var seam := PackedVector2Array([
		top.lerp(inner, 0.36),
		inner.lerp(nape_mid, 0.34),
		nape_mid.lerp(tip, 0.44),
	])
	_draw_hair_gradient_strand(seam, maxf(head_radius * 0.042, 0.20), 0.030, Color(0.0, 0.0, 0.0, seam_alpha))
	var glint_alpha := clampf(alpha * highlight_power * 0.026, 0.0, 0.06)
	if glint_alpha > 0.001:
		var glint := PackedVector2Array([
			top.lerp(shoulder_cover, 0.30),
			shoulder_cover.lerp(lower_cover, 0.42),
			lower_cover.lerp(tip, 0.36),
		])
		_draw_hair_gradient_strand(glint, maxf(head_radius * 0.014, 0.08), 0.012, Color(0.74, 0.86, 0.82, glint_alpha))


func _draw_head_mounted_bun(pose: Dictionary, state: Dictionary, alpha: float) -> void:
	if alpha <= 0.001:
		return
	var head_center: Vector2 = pose["head_center"]
	var h := _hair_pose_vector(pose, "heading", Vector2.RIGHT)
	var side := _hair_pose_vector(pose, "side", Vector2.RIGHT)
	var wind := float(state["wind"])
	var head_radius := _hair_head_radius(pose)
	var center := _hair_bun_center(pose, wind)
	var side_visibility := clampf(0.72 + absf(h.x) * 0.20 - maxf(h.y, 0.0) * 0.12, 0.56, 1.0)
	var bun_alpha := clampf(maxf(alpha * side_visibility, _hair_scalp_alpha(alpha)), 0.0, 1.0)
	var volume := maxf(hair_fx_volume, 0.0)
	var root_ink := maxf(hair_fx_root_ink, 0.0)
	var highlight_power := maxf(hair_fx_highlight, 0.0)
	var radius := head_radius * maxf(0.18, 0.24 + hair_fx_width * 0.10 + volume * 0.04)
	var neck := head_center - h * head_radius * 0.32 + Vector2.UP * head_radius * 0.42
	var tie := center.lerp(neck, 0.34)
	draw_line(neck, tie, Color(0.0, 0.0, 0.0, 0.55 * bun_alpha), maxf(radius * 0.88, 1.6), true)
	draw_line(neck, tie, Color(0.004, 0.005, 0.006, 0.82 * bun_alpha), maxf(radius * 0.58, 1.1), true)
	draw_circle(center + Vector2(0.70, 0.90), radius + 1.65, Color(0.0, 0.0, 0.0, (0.18 + root_ink * 0.06) * bun_alpha))
	draw_circle(center, radius + 1.00, Color(0.0, 0.0, 0.0, (0.42 + root_ink * 0.13) * bun_alpha))
	draw_circle(center, radius, Color(0.004, 0.005, 0.006, 0.94 * bun_alpha))
	draw_circle(center - side * radius * 0.20 + Vector2.UP * radius * 0.08, radius * 0.54, Color(0.0, 0.0, 0.0, 0.30 * bun_alpha))
	draw_arc(center - side * radius * 0.16 + Vector2.UP * radius * 0.08, radius * 0.78, PI * 0.12, PI * 1.44, 18, Color(0.74, 0.86, 0.82, 0.13 * bun_alpha * highlight_power), 0.75, true)
	draw_arc(center + side * radius * 0.08 + Vector2.DOWN * radius * 0.04, radius * 0.48, -PI * 0.20, PI * 1.30, 14, Color(0.80, 0.88, 0.84, 0.065 * bun_alpha * highlight_power), 0.55, true)


func _draw_hair_crown_overlay(pose: Dictionary, state: Dictionary, alpha: float) -> void:
	if alpha <= 0.001:
		return
	var wind := float(state["wind"])
	var volume := maxf(hair_fx_volume, 0.0)
	var highlight_power := maxf(hair_fx_highlight, 0.0)
	var density := clampf(float(maxi(hair_fx_back_strands, 0)) / 24.0, 0.0, 1.4)
	var head_radius := _hair_head_radius(pose)
	var crown_points := _hair_groom_points_for_id("crown_mantle", pose, state)
	var forehead_points := _hair_groom_points_for_id("forehead_lock", pose, state)
	if crown_points.size() >= 2:
		var crown_groove := PackedVector2Array([
			_hair_sample_curve(crown_points, 0.06),
			_hair_sample_curve(crown_points, 0.22),
			_hair_sample_curve(crown_points, 0.40),
		])
		var crown_alpha := clampf(alpha * (0.070 + volume * 0.026 + density * 0.018), 0.0, 0.22)
		_draw_hair_gradient_strand(crown_groove, maxf(head_radius * 0.032, 0.16), 0.020, Color(0.0, 0.0, 0.0, crown_alpha))
	if forehead_points.size() >= 2:
		var front_gloss := PackedVector2Array([
			_hair_sample_curve(forehead_points, 0.04),
			_hair_sample_curve(forehead_points, 0.24),
			_hair_sample_curve(forehead_points, 0.48),
		])
		var front_shadow := PackedVector2Array([
			_hair_sample_curve(forehead_points, 0.12),
			_hair_sample_curve(forehead_points, 0.34),
			_hair_sample_curve(forehead_points, 0.62),
		])
		_draw_hair_gradient_strand(front_shadow, maxf(head_radius * 0.024, 0.12), 0.014, Color(0.0, 0.0, 0.0, alpha * (0.052 + volume * 0.018)))
		if highlight_power > 0.001:
			_draw_hair_gradient_strand(front_gloss, maxf(head_radius * 0.012, 0.055), 0.008, Color(0.78, 0.90, 0.86, alpha * highlight_power * (0.020 + wind * 0.014)))


func _draw_hair_side_visibility_overlay(pose: Dictionary, state: Dictionary, alpha: float) -> void:
	if alpha <= 0.001:
		return
	var wind := float(state["wind"])
	var volume := maxf(hair_fx_volume, 0.0)
	var highlight_power := maxf(hair_fx_highlight, 0.0)
	var density := clampf(float(maxi(hair_fx_back_strands, 0)) / 24.0, 0.0, 1.4)
	var head_radius := _hair_head_radius(pose)
	var edge_ids := ["occipital_left", "occipital_right", "nape_near", "nape_long"]
	var pass_count := 0
	var max_passes := clampi(int(roundf(3.0 + density * 5.0)), 3, 9)
	for lock_id in edge_ids:
		if pass_count >= max_passes:
			break
		var points := _hair_groom_points_for_id(String(lock_id), pose, state)
		if points.size() < 2:
			continue
		var edge_shadow := PackedVector2Array([
			_hair_sample_curve(points, 0.18),
			_hair_sample_curve(points, 0.42),
			_hair_sample_curve(points, 0.74),
			_hair_sample_curve(points, 0.94),
		])
		var shadow_alpha := clampf(alpha * (0.048 + volume * 0.020 + density * 0.012), 0.0, 0.16)
		_draw_hair_gradient_strand(edge_shadow, maxf(head_radius * 0.024, 0.12), 0.016, Color(0.0, 0.0, 0.0, shadow_alpha))
		if highlight_power > 0.001:
			var edge_gloss := PackedVector2Array([
				_hair_sample_curve(points, 0.24),
				_hair_sample_curve(points, 0.52),
				_hair_sample_curve(points, 0.86),
			])
			_draw_hair_gradient_strand(edge_gloss, maxf(head_radius * 0.010, 0.050), 0.008, Color(0.76, 0.88, 0.84, alpha * highlight_power * (0.018 + wind * 0.010)))
		pass_count += 1


func _draw_hairline_cap(pose: Dictionary, state: Dictionary, alpha: float) -> void:
	if alpha <= 0.001:
		return
	var head_center: Vector2 = pose["head_center"]
	var h := _hair_pose_vector(pose, "heading", Vector2.RIGHT)
	var side := _hair_pose_vector(pose, "side", Vector2.RIGHT)
	var wind := float(state["wind"])
	var front_cover := float(state["front_cover"])
	var head_radius := _hair_head_radius(pose)
	var root_ink := maxf(hair_fx_root_ink, 0.0)
	var highlight_power := maxf(hair_fx_highlight, 0.0)
	var temple_span := head_radius * (0.10 + wind * 0.02)
	var left_temple := _hair_scalp_anchor(pose, "temple", 0.0, 0.62, wind)
	var right_temple := _hair_scalp_anchor(pose, "temple", 1.0, 0.62, wind)
	var crown_left := _hair_scalp_anchor(pose, "crown", 0.16, 0.44, wind)
	var crown := _hair_scalp_anchor(pose, "crown", 0.52, 0.52, wind)
	var crown_right := _hair_scalp_anchor(pose, "crown", 0.84, 0.44, wind)
	var cover_left := _hair_scalp_anchor(pose, "cover", 0.18, 0.62, wind)
	var cover_right := _hair_scalp_anchor(pose, "cover", 0.82, 0.62, wind)
	var bang_left := _hair_scalp_anchor(pose, "bang", 0.28, 0.64, wind)
	var bang_right := _hair_scalp_anchor(pose, "bang", 0.72, 0.64, wind)
	var forehead := _hair_scalp_anchor(pose, "bang", 0.50, 0.72, wind)
	var points := PackedVector2Array([
		left_temple - side * temple_span + Vector2.UP * head_radius * 0.02,
		crown_left,
		crown + Vector2.UP * head_radius * 0.08,
		crown_right,
		right_temple + side * temple_span + Vector2.UP * head_radius * 0.02,
		cover_right - Vector2.UP * head_radius * (0.04 + front_cover * 0.04),
		bang_right + Vector2.UP * head_radius * (0.06 + front_cover * 0.08),
		forehead + Vector2.UP * head_radius * (0.08 + front_cover * 0.10),
		bang_left + Vector2.UP * head_radius * (0.06 + front_cover * 0.08),
		cover_left - Vector2.UP * head_radius * (0.04 + front_cover * 0.04),
	])
	var dense_alpha := _hair_scalp_alpha(alpha)
	var fill := Color(0.004, 0.005, 0.006, dense_alpha)
	var rim := Color(0.0, 0.0, 0.0, clampf(maxf(alpha * (0.28 + root_ink * 0.08 + front_cover * 0.08), dense_alpha * 0.52), 0.0, 1.0))
	_draw_hair_shape_fan(points, fill, rim)
	draw_line(bang_left + Vector2.UP * head_radius * 0.08, crown_right, Color(0.72, 0.84, 0.80, alpha * 0.060 * highlight_power), 0.55, true)
	draw_line(bang_right + Vector2.UP * head_radius * 0.06, crown_left, Color(0.72, 0.84, 0.80, alpha * 0.045 * highlight_power), 0.50, true)


func _draw_hair_scalp_root_fans(pose: Dictionary, state: Dictionary, alpha: float) -> void:
	if alpha <= 0.001:
		return
	var head_center: Vector2 = pose["head_center"]
	var head_radius := _hair_head_radius(pose)
	var root_ink := maxf(hair_fx_root_ink, 0.0)
	var highlight_power := maxf(hair_fx_highlight, 0.0)
	var dense_alpha := _hair_scalp_alpha(alpha)
	for lock_def in _hair_groom_lock_defs():
		var region := String(lock_def.get("region", "occipital"))
		var lane_t := clampf(float(lock_def.get("lane", 0.5)), 0.0, 1.0)
		var width_scale := float(lock_def.get("width", 1.0))
		var root := _hair_groom_root_for_def(lock_def, pose, state)
		var initial := _hair_groom_initial_for_def(lock_def, pose)
		if initial.length_squared() <= 0.0001:
			initial = Vector2.DOWN
		initial = initial.normalized()
		var inward := head_center - root
		if inward.length_squared() <= 0.0001:
			inward = -initial
		inward = inward.normalized()
		var normal := initial.rotated(PI * 0.5)
		var region_visibility := _hair_root_region_visibility(region)
		var socket_alpha := clampf((0.22 + root_ink * 0.16) * dense_alpha * region_visibility, 0.0, 1.0)
		var groove_alpha := clampf((0.20 + root_ink * 0.18) * alpha * region_visibility, 0.0, 0.72)
		var socket_width := maxf(head_radius * (0.050 + width_scale * 0.014) * (0.80 + root_ink * 0.22), 0.62)
		var buried := root + inward * head_radius * (0.14 + root_ink * 0.025)
		var shoulder := root + initial * head_radius * (0.10 + width_scale * 0.018)
		var socket := PackedVector2Array([
			buried - normal * socket_width * 0.72,
			root - normal * socket_width,
			shoulder - normal * socket_width * 0.54,
			shoulder + normal * socket_width * 0.54,
			root + normal * socket_width,
			buried + normal * socket_width * 0.72,
		])
		_draw_hair_shape_fan(socket, Color(0.0, 0.0, 0.0, socket_alpha), Color(0.0, 0.0, 0.0, socket_alpha * 0.34))
		var groove := PackedVector2Array([
			buried + normal * sin(float(lock_def.get("phase", 0.0))) * socket_width * 0.20,
			root + initial * head_radius * 0.055,
			shoulder + normal * sin(float(lock_def.get("phase", 0.0)) * 1.7) * socket_width * 0.22,
		])
		_draw_hair_gradient_strand(groove, maxf(socket_width * 0.34, 0.16), 0.035, Color(0.0, 0.0, 0.0, groove_alpha))
		if highlight_power > 0.01 and region != "nape":
			var glint_offset := normal * socket_width * (0.22 if lane_t < 0.5 else -0.22)
			var glint := PackedVector2Array([
				buried + glint_offset * 0.45,
				root + glint_offset * 0.74 + initial * head_radius * 0.036,
				shoulder + glint_offset * 0.32,
			])
			_draw_hair_gradient_strand(glint, 0.10, 0.018, Color(0.74, 0.86, 0.82, alpha * highlight_power * region_visibility * 0.032))


func _hair_root_region_visibility(region: String) -> float:
	match region:
		"crown":
			return 0.74
		"occipital":
			return 0.68
		"nape":
			return 0.46
		"temple":
			return 0.92
		"cover":
			return 0.96
		"bang":
			return 0.96
		_:
			return 0.66


func _hair_lock_tail_flow(base_flow: Vector2, h: Vector2, side: Vector2, wave_axis: Vector2, lane_t: float, phase: float, turn: float, wind: float, gravity_bias: float) -> Vector2:
	var flow := base_flow
	if flow.length_squared() <= 0.0001:
		flow = Vector2.DOWN
	var lane := lane_t - 0.5
	var flutter := sin(phase * 1.73) * 0.10 + cos(phase * 0.91 + _time * 0.42) * 0.045
	flow = flow.normalized().rotated(lane * (0.34 + wind * 0.12) + flutter + turn * (0.12 + wind * 0.16))
	var side_pull := side * lane * (0.08 + wind * 0.06)
	flow += side_pull + wave_axis * sin(phase + lane_t * 2.0) * 0.045
	flow = flow.lerp(Vector2.DOWN, clampf(gravity_bias * (1.0 - wind * 0.72), 0.0, 0.58))
	return flow.normalized() if flow.length_squared() > 0.0001 else Vector2.DOWN


func _hair_sculpted_lock_points(
		root: Vector2,
		initial_dir: Vector2,
		tail_flow: Vector2,
		wave_axis: Vector2,
		length: float,
		sway: float,
		phase: float,
		turn: float,
		wind: float,
		pose: Dictionary,
		steps: int,
		s_bias: float,
		collision_strength: float
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_steps := maxi(steps, 2)
	var initial := initial_dir.normalized() if initial_dir.length_squared() > 0.0001 else Vector2.DOWN
	var tail := tail_flow.normalized() if tail_flow.length_squared() > 0.0001 else Vector2.DOWN
	var bend_axis := wave_axis.normalized() if wave_axis.length_squared() > 0.0001 else tail.rotated(PI * 0.5)
	var physics := maxf(hair_fx_physics, 0.0)
	var s_sign := signf(sin(phase * 0.83) + s_bias * 0.75)
	if s_sign == 0.0:
		s_sign = 1.0
	var s_curve := length * (0.12 + wind * 0.075 + absf(turn) * 0.045) * s_sign
	var hover_drop := length * (0.12 + (1.0 - wind) * 0.28) * hair_fx_hover_drop * physics
	var c1 := root + initial * length * (0.22 + (1.0 - wind) * 0.07) + bend_axis * s_curve * 0.42 + Vector2.DOWN * hover_drop * 0.12
	var c2 := root + tail * length * (0.66 + wind * 0.08) - bend_axis * s_curve * (1.10 + absf(turn) * 0.20) + Vector2.DOWN * hover_drop * 0.56
	var tip := root + tail * length * (0.96 + wind * 0.08) + bend_axis * (s_curve * 0.38 + turn * length * 0.05) + Vector2.DOWN * hover_drop
	var wave_rate := lerpf(0.72, 4.65, wind)
	var motion_scale := (0.13 + wind * 0.58 + absf(turn) * 0.20) * physics
	for i in range(safe_steps + 1):
		var t := float(i) / float(safe_steps)
		var p := _hair_cubic_point(root, c1, c2, tip, t)
		var wave_a := bend_axis * sin(phase + _time * wave_rate - t * (2.0 + wind * 1.6)) * sway * pow(t, 1.35) * motion_scale
		var wave_b := -bend_axis * sin(phase * 1.37 + _time * wave_rate * 0.58 + t * PI) * sway * t * (1.0 - t) * (0.10 + wind * 0.24)
		var turn_lag := bend_axis * turn * length * 0.12 * smoothstep(0.08, 1.0, t)
		p += wave_a + wave_b + turn_lag
		p = _hair_collision_push(p, pose, t, collision_strength)
		points.append(p)
	return points


func _hair_cubic_point(a: Vector2, b: Vector2, c: Vector2, d: Vector2, t: float) -> Vector2:
	var inv := 1.0 - t
	return a * inv * inv * inv + b * 3.0 * inv * inv * t + c * 3.0 * inv * t * t + d * t * t * t


func _hair_collision_push(point: Vector2, pose: Dictionary, t: float, strength: float) -> Vector2:
	if strength <= 0.001:
		return point
	var result := point
	var head_center: Vector2 = pose["head_center"]
	var head_strength := smoothstep(0.07, 0.34, t) * strength
	result = _hair_sdf_push_from_circle(result, head_center, _hair_head_radius(pose) * 0.86, head_strength)
	if pose.has("shoulder_near") and pose.has("shoulder_far"):
		var shoulder_near: Vector2 = pose["shoulder_near"]
		var shoulder_far: Vector2 = pose["shoulder_far"]
		var shoulder_radius := maxf(7.0, float(pose.get("torso_width", 10.0)) * 0.42 + 5.0)
		result = _hair_sdf_push_from_capsule(result, shoulder_far, shoulder_near, shoulder_radius, smoothstep(0.18, 0.62, t) * strength * 0.72)
	if pose.has("shoulder_center") and pose.has("hip_center"):
		var shoulder_center: Vector2 = pose["shoulder_center"]
		var hip_center: Vector2 = pose["hip_center"]
		result = _hair_sdf_push_from_capsule(result, shoulder_center, hip_center, maxf(8.0, float(pose.get("torso_width", 10.0)) * 0.46 + 5.5), smoothstep(0.34, 0.92, t) * strength * 0.34)
	return result


func _hair_sdf_circle(point: Vector2, center: Vector2, radius: float) -> float:
	return point.distance_to(center) - radius


func _hair_sdf_capsule(point: Vector2, a: Vector2, b: Vector2, radius: float) -> float:
	var closest := _hair_capsule_closest_point(point, a, b)
	return point.distance_to(closest) - radius


func _hair_capsule_closest_point(point: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab := b - a
	var len_sq := ab.length_squared()
	if len_sq <= 0.001:
		return a
	var segment_t := clampf((point - a).dot(ab) / len_sq, 0.0, 1.0)
	return a + ab * segment_t


func _hair_sdf_push_from_circle(point: Vector2, center: Vector2, radius: float, strength: float) -> Vector2:
	if strength <= 0.001:
		return point
	var delta := point - center
	var dist := delta.length()
	var signed_distance := _hair_sdf_circle(point, center, radius)
	if signed_distance >= 0.0:
		return point
	var dir := delta / dist if dist > 0.001 else Vector2.UP
	return point - dir * signed_distance * strength


func _hair_sdf_push_from_capsule(point: Vector2, a: Vector2, b: Vector2, radius: float, strength: float) -> Vector2:
	if strength <= 0.001:
		return point
	var closest := _hair_capsule_closest_point(point, a, b)
	var signed_distance := _hair_sdf_capsule(point, a, b, radius)
	if signed_distance >= 0.0:
		return point
	var delta := point - closest
	var dir := delta.normalized() if delta.length_squared() > 0.001 else Vector2.UP
	return point - dir * signed_distance * strength


func _draw_hair_groom_lock(points: PackedVector2Array, root_width: float, mid_width: float, tip_width: float, fill: Color, rim: Color, highlight: Color) -> void:
	if points.size() < 2 or fill.a <= 0.001:
		return
	var render_points := _hair_smooth_open_curve(points, 4)
	_draw_hair_ribbon(render_points, root_width + 1.3 * hair_fx_width, mid_width + 1.0 * hair_fx_width, tip_width + 0.30 * hair_fx_width, rim)
	_draw_hair_ribbon(render_points, root_width, mid_width, tip_width, fill)
	_draw_hair_tapered_tip(render_points, mid_width, tip_width, fill, rim, highlight)
	_draw_hair_root_plug(render_points[0], root_width, fill, rim)
	if highlight.a > 0.001:
		_draw_hair_center_highlight(render_points, highlight, maxf(mid_width * 0.16, 0.18 * hair_fx_width))


func _draw_hair_root_plug(root: Vector2, root_width: float, fill: Color, rim: Color) -> void:
	var root_alpha := clampf(maxf(fill.a, _hair_scalp_alpha(fill.a)), 0.0, 1.0)
	var rim_alpha := clampf(maxf(rim.a, root_alpha * 0.62), 0.0, 1.0)
	var root_ink := maxf(hair_fx_root_ink, 0.0)
	draw_circle(root, maxf(root_width * (0.70 + root_ink * 0.16), 0.70), Color(0.0, 0.0, 0.0, rim_alpha))
	draw_circle(root, maxf(root_width * (0.42 + root_ink * 0.12), 0.46), Color(fill.r, fill.g, fill.b, root_alpha))


func _draw_hair_ribbon(points: PackedVector2Array, root_width: float, mid_width: float, tip_width: float, color: Color) -> void:
	if points.size() < 2 or color.a <= 0.001:
		return
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var count := points.size()
	for i in range(count):
		var t := float(i) / maxf(float(count - 1), 1.0)
		var tangent := _hair_curve_tangent(points, i)
		var normal := tangent.rotated(PI * 0.5)
		var width := _hair_groom_width(t, root_width, mid_width, tip_width)
		left.append(points[i] + normal * width)
		right.append(points[i] - normal * width)
	for i in range(count - 1):
		var t_mid := (float(i) + 0.5) / maxf(float(count - 1), 1.0)
		_draw_quad_safe(left[i], left[i + 1], right[i + 1], right[i], _hair_gradient_color(color, t_mid))


func _draw_hair_tapered_tip(points: PackedVector2Array, mid_width: float, tip_width: float, fill: Color, rim: Color, highlight: Color) -> void:
	if points.size() < 3 or fill.a <= 0.001:
		return
	var tip: Vector2 = points[points.size() - 1]
	var tangent := _hair_curve_tangent(points, points.size() - 1)
	if tangent.length_squared() <= 0.0001:
		return
	var normal := tangent.rotated(PI * 0.5)
	var safe_tip_width := maxf(tip_width, 0.08 * hair_fx_width)
	var cap_length := maxf(mid_width * 0.52 + safe_tip_width * 1.40, 0.80)
	var shoulder := tip - tangent * cap_length
	var notch := tip - tangent * cap_length * 0.42
	var rim_alpha := clampf(rim.a * 0.74, 0.0, 1.0)
	var fill_alpha := clampf(fill.a * (0.30 + minf(hair_fx_root_ink, 1.0) * 0.10), 0.0, 1.0)
	var rim_cap := PackedVector2Array([
		shoulder - normal * (safe_tip_width + 0.26 * hair_fx_width),
		notch - normal * safe_tip_width * 0.58,
		tip + tangent * cap_length * 0.18,
		notch + normal * safe_tip_width * 0.58,
		shoulder + normal * (safe_tip_width + 0.26 * hair_fx_width),
	])
	var fill_cap := PackedVector2Array([
		shoulder - normal * safe_tip_width,
		notch - normal * safe_tip_width * 0.44,
		tip + tangent * cap_length * 0.12,
		notch + normal * safe_tip_width * 0.44,
		shoulder + normal * safe_tip_width,
	])
	_draw_hair_shape_fan(rim_cap, Color(0.0, 0.0, 0.0, rim_alpha), Color(0.0, 0.0, 0.0, rim_alpha * 0.18))
	_draw_hair_shape_fan(fill_cap, Color(fill.r, fill.g, fill.b, fill_alpha), Color(0.0, 0.0, 0.0, fill_alpha * 0.18))
	if highlight.a <= 0.001:
		return
	var split_alpha := clampf(highlight.a * 0.46, 0.0, 0.08)
	var split_a := PackedVector2Array([
		shoulder + normal * safe_tip_width * 0.22,
		notch + normal * safe_tip_width * 0.46,
		tip + tangent * cap_length * 0.10 + normal * safe_tip_width * 0.10,
	])
	var split_b := PackedVector2Array([
		shoulder - normal * safe_tip_width * 0.16,
		notch - normal * safe_tip_width * 0.36,
		tip + tangent * cap_length * 0.08 - normal * safe_tip_width * 0.08,
	])
	_draw_hair_gradient_strand(split_a, maxf(0.10 * hair_fx_width, 0.026), 0.010, Color(0.78, 0.90, 0.86, split_alpha))
	_draw_hair_gradient_strand(split_b, maxf(0.075 * hair_fx_width, 0.020), 0.008, Color(0.72, 0.84, 0.80, split_alpha * 0.58))


func _hair_gradient_color(color: Color, t: float) -> Color:
	var root_ink := maxf(hair_fx_root_ink, 0.0)
	var root_alpha := clampf(maxf(color.a, minf(1.0, color.a + (0.30 + root_ink * 0.22) * hair_fx_opacity)), 0.0, 1.0)
	var dense_alpha := clampf(maxf(color.a, root_alpha * 0.74), 0.0, 1.0)
	var tip_alpha := clampf(color.a * (0.24 + minf(root_ink, 1.0) * 0.10), 0.0, 1.0)
	var alpha := color.a
	if t < 0.18:
		alpha = lerpf(root_alpha, dense_alpha, smoothstep(0.0, 0.18, t))
	elif t < 0.72:
		alpha = lerpf(dense_alpha, color.a, smoothstep(0.18, 0.72, t))
	else:
		alpha = lerpf(color.a, tip_alpha, smoothstep(0.72, 1.0, t))
	return Color(color.r, color.g, color.b, alpha)


func _hair_groom_width(t: float, root_width: float, mid_width: float, tip_width: float) -> float:
	if t < 0.52:
		return lerpf(root_width, mid_width, smoothstep(0.0, 0.52, t))
	return lerpf(mid_width, tip_width, smoothstep(0.52, 1.0, t))


func _hair_curve_tangent(points: PackedVector2Array, index: int) -> Vector2:
	var previous: Vector2 = points[maxi(index - 1, 0)]
	var next: Vector2 = points[mini(index + 1, points.size() - 1)]
	var tangent := next - previous
	if tangent.length_squared() <= 0.0001:
		return Vector2.RIGHT
	return tangent.normalized()


func _hair_sample_curve(points: PackedVector2Array, t: float) -> Vector2:
	if points.size() == 0:
		return Vector2.ZERO
	if points.size() == 1:
		return points[0]
	var scaled := clampf(t, 0.0, 1.0) * float(points.size() - 1)
	var index := clampi(floori(scaled), 0, points.size() - 1)
	var next_index := mini(index + 1, points.size() - 1)
	var local_t := clampf(scaled - float(index), 0.0, 1.0)
	var a: Vector2 = points[index]
	var b: Vector2 = points[next_index]
	return a.lerp(b, local_t)


func _hair_curve_tangent_at(points: PackedVector2Array, t: float) -> Vector2:
	if points.size() < 2:
		return Vector2.RIGHT
	var scaled := clampf(t, 0.0, 1.0) * float(points.size() - 1)
	var index := clampi(roundi(scaled), 0, points.size() - 1)
	return _hair_curve_tangent(points, index)


func _hair_offset_sample(points: PackedVector2Array, t: float, offset_dir: Vector2, amount: float) -> Vector2:
	var point := _hair_sample_curve(points, t)
	var safe_dir := offset_dir
	if safe_dir.length_squared() <= 0.0001:
		safe_dir = _hair_curve_tangent_at(points, t).rotated(PI * 0.5)
	return point + safe_dir.normalized() * amount


func _hair_smooth_open_curve(points: PackedVector2Array, subdivisions: int) -> PackedVector2Array:
	if points.size() < 3 or subdivisions <= 1:
		return PackedVector2Array(points)
	var result := PackedVector2Array()
	var safe_subdivisions := maxi(subdivisions, 2)
	for index in range(points.size() - 1):
		var p0: Vector2 = points[maxi(index - 1, 0)]
		var p1: Vector2 = points[index]
		var p2: Vector2 = points[index + 1]
		var p3: Vector2 = points[mini(index + 2, points.size() - 1)]
		for step in range(safe_subdivisions):
			var t := float(step) / float(safe_subdivisions)
			result.append(_hair_catmull_rom_point(p0, p1, p2, p3, t))
	result.append(points[points.size() - 1])
	return result


func _hair_smooth_closed_loop(points: PackedVector2Array, subdivisions: int) -> PackedVector2Array:
	if points.size() < 4 or subdivisions <= 1:
		return PackedVector2Array(points)
	var result := PackedVector2Array()
	var count := points.size()
	var safe_subdivisions := maxi(subdivisions, 2)
	for index in range(count):
		var p0: Vector2 = points[(index - 1 + count) % count]
		var p1: Vector2 = points[index]
		var p2: Vector2 = points[(index + 1) % count]
		var p3: Vector2 = points[(index + 2) % count]
		for step in range(safe_subdivisions):
			var t := float(step) / float(safe_subdivisions)
			result.append(_hair_catmull_rom_point(p0, p1, p2, p3, t))
	return result


func _hair_catmull_rom_point(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return (p1 * 2.0 + (p2 - p0) * t + (p0 * 2.0 - p1 * 5.0 + p2 * 4.0 - p3) * t2 + (-p0 + p1 * 3.0 - p2 * 3.0 + p3) * t3) * 0.5


func _draw_hair_center_highlight(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 2 or color.a <= 0.001:
		return
	var render_points := _hair_smooth_open_curve(points, 3)
	var segment_count := render_points.size() - 1
	for i in range(segment_count):
		var t := float(i) / maxf(float(segment_count - 1), 1.0)
		var segment_color := Color(color.r, color.g, color.b, color.a * pow(1.0 - t, 1.7))
		draw_line(render_points[i], render_points[i + 1], segment_color, maxf(width * (1.0 - t * 0.82), 0.08), true)


func _draw_hair_groom_surface_details(
		points: PackedVector2Array,
		root_width: float,
		mid_width: float,
		tip_width: float,
		alpha: float,
		highlight_strength: float,
		phase: float,
		layer: String
) -> void:
	if points.size() < 3 or alpha <= 0.001:
		return
	var render_points := _hair_smooth_open_curve(points, 3)
	var volume := maxf(hair_fx_volume, 0.0)
	var material_depth := maxf(hair_fx_material_depth, 0.0)
	if material_depth > 0.001:
		_draw_hair_lock_material_planes(render_points, root_width, mid_width, tip_width, alpha, highlight_strength, phase, layer, material_depth)
	var shadow_lanes := 2 if layer != "front" and volume > 0.15 else 1
	for shade_lane_index in range(shadow_lanes):
		var shade_side_sign := 1.0 if shade_lane_index == 0 else -1.0
		var shade := PackedVector2Array()
		var shade_sample_count := 5
		var shade_start_t := 0.22 + float(shade_lane_index) * 0.10
		var shade_end_t := 0.92 - float(shade_lane_index) * 0.08
		for shade_sample_index in range(shade_sample_count):
			var shade_u := float(shade_sample_index) / float(shade_sample_count - 1)
			var shade_t := lerpf(shade_start_t, shade_end_t, shade_u)
			var shade_base := _hair_sample_curve(render_points, shade_t)
			var shade_tangent := _hair_curve_tangent_at(render_points, shade_t)
			var shade_normal := shade_tangent.rotated(PI * 0.5)
			var shade_width := _hair_groom_width(shade_t, root_width, mid_width, tip_width)
			var scallop := sin(phase * 0.77 + _time * 0.62 + shade_u * TAU) * 0.055 * shade_t
			shade.append(shade_base + shade_normal * shade_side_sign * shade_width * (0.12 + float(shade_lane_index) * 0.18 + scallop))
		var shade_alpha := clampf(alpha * (0.024 + material_depth * 0.018 + volume * 0.034), 0.0, 0.22)
		_draw_hair_gradient_strand(shade, maxf(0.30 * hair_fx_width, 0.075), maxf(0.045 * hair_fx_width, 0.020), Color(0.0, 0.0, 0.0, shade_alpha))
	if highlight_strength <= 0.001:
		return
	var lane_count := 2 if layer != "front" and highlight_strength > 0.54 else 1
	for lane_index in range(lane_count):
		var side_sign := -1.0 if lane_index == 0 else 1.0
		var detail := PackedVector2Array()
		var sample_count := 6
		var start_t := 0.16 + float(lane_index) * 0.08
		var end_t := 0.88 - float(lane_index) * 0.05
		for sample_index in range(sample_count):
			var u := float(sample_index) / float(sample_count - 1)
			var t := lerpf(start_t, end_t, u)
			var base := _hair_sample_curve(render_points, t)
			var tangent := _hair_curve_tangent_at(render_points, t)
			var normal := tangent.rotated(PI * 0.5)
			var width := _hair_groom_width(t, root_width, mid_width, tip_width)
			var ripple := sin(phase + _time * 1.25 + u * TAU * 0.65) * hair_fx_sway * 0.020 * t
			detail.append(base + normal * side_sign * width * (0.24 + float(lane_index) * 0.18 + ripple))
		var detail_alpha := clampf(alpha * (0.018 + material_depth * 0.010 + highlight_strength * 0.045), 0.0, 0.16)
		_draw_hair_gradient_strand(detail, maxf(0.22 * hair_fx_width, 0.055), maxf(0.035 * hair_fx_width, 0.018), Color(0.80, 0.90, 0.86, detail_alpha))
	if layer == "front":
		return
	var edge_sign := 1.0 if sin(phase * 0.71) >= 0.0 else -1.0
	var edge := PackedVector2Array()
	for t in [0.58, 0.74, 0.92, 1.0]:
		var base := _hair_sample_curve(render_points, float(t))
		var tangent := _hair_curve_tangent_at(render_points, float(t))
		var normal := tangent.rotated(PI * 0.5)
		var width := _hair_groom_width(float(t), root_width, mid_width, tip_width)
		var lift := normal * edge_sign * width * (0.72 + float(t) * 0.18)
		var flutter := normal * sin(phase + _time * 2.2 + float(t) * 4.0) * hair_fx_sway * 0.040 * float(t)
		edge.append(base + lift + flutter)
	var speed_glint := clampf((_cloth_wind + _boost * 0.35) * material_depth, 0.0, 1.35)
	var edge_alpha := clampf(alpha * highlight_strength * (0.040 + speed_glint * 0.035), 0.0, 0.16)
	_draw_hair_gradient_strand(edge, maxf(0.16 * hair_fx_width, 0.045), maxf(0.020 * hair_fx_width, 0.012), Color(0.74, 0.86, 0.82, edge_alpha))


func _draw_hair_lock_material_planes(
		points: PackedVector2Array,
		root_width: float,
		mid_width: float,
		tip_width: float,
		alpha: float,
		highlight_strength: float,
		phase: float,
		layer: String,
		material_depth: float
) -> void:
	if points.size() < 4 or alpha <= 0.001:
		return
	var volume := maxf(hair_fx_volume, 0.0)
	var root_ink := maxf(hair_fx_root_ink, 0.0)
	var root_path := PackedVector2Array([
		_hair_sample_curve(points, 0.00),
		_hair_sample_curve(points, 0.08),
		_hair_sample_curve(points, 0.19),
		_hair_sample_curve(points, 0.34),
	])
	var root_alpha := clampf(alpha * material_depth * (0.055 + root_ink * 0.052), 0.0, 0.34)
	_draw_hair_gradient_strand(root_path, maxf(root_width * 0.92, 0.38), maxf(mid_width * 0.18, 0.08), Color(0.0, 0.0, 0.0, root_alpha))
	var main_side := 1.0 if sin(phase * 0.83) >= 0.0 else -1.0
	var primary_band := _hair_ribbon_band(points, root_width, mid_width, tip_width, 0.12, 0.78, main_side, 0.10, 0.62, 7, phase)
	var primary_alpha := clampf(alpha * material_depth * (0.026 + volume * 0.024), 0.0, 0.16)
	_draw_hair_shape_fan(primary_band, Color(0.0, 0.0, 0.0, primary_alpha), Color(0.0, 0.0, 0.0, primary_alpha * 0.18))
	if layer != "front":
		var secondary_band := _hair_ribbon_band(points, root_width, mid_width, tip_width, 0.32, 0.94, -main_side, 0.18, 0.48, 6, phase + 2.4)
		var secondary_alpha := clampf(alpha * material_depth * (0.018 + volume * 0.020), 0.0, 0.13)
		_draw_hair_shape_fan(secondary_band, Color(0.0, 0.0, 0.0, secondary_alpha), Color(0.0, 0.0, 0.0, secondary_alpha * 0.16))
	var highlight_alpha := clampf(alpha * material_depth * highlight_strength * (0.014 + _cloth_wind * 0.014 + _boost * 0.010), 0.0, 0.08)
	if highlight_alpha <= 0.001:
		return
	var gloss_side := -main_side
	var gloss := PackedVector2Array()
	for index in range(5):
		var u := float(index) / 4.0
		var t := lerpf(0.18, 0.84, u)
		var base := _hair_sample_curve(points, t)
		var tangent := _hair_curve_tangent_at(points, t)
		var normal := tangent.rotated(PI * 0.5)
		var width := _hair_groom_width(t, root_width, mid_width, tip_width)
		var shimmer := sin(phase * 1.17 + _time * (0.72 + _cloth_wind * 1.35) + u * TAU) * 0.045
		gloss.append(base + normal * gloss_side * width * (0.30 + shimmer))
	_draw_hair_gradient_strand(gloss, maxf(0.20 * hair_fx_width, 0.052), maxf(0.030 * hair_fx_width, 0.014), Color(0.82, 0.92, 0.88, highlight_alpha))


func _hair_ribbon_band(
		points: PackedVector2Array,
		root_width: float,
		mid_width: float,
		tip_width: float,
		t_start: float,
		t_end: float,
		side_sign: float,
		inner_ratio: float,
		outer_ratio: float,
		sample_count: int,
		phase: float
) -> PackedVector2Array:
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	var safe_count := maxi(sample_count, 3)
	for index in range(safe_count):
		var u := float(index) / float(safe_count - 1)
		var t := lerpf(t_start, t_end, u)
		var base := _hair_sample_curve(points, t)
		var tangent := _hair_curve_tangent_at(points, t)
		var normal := tangent.rotated(PI * 0.5)
		var width := _hair_groom_width(t, root_width, mid_width, tip_width)
		var scallop := sin(phase + _time * 0.45 + u * PI * 1.75) * 0.028 * t
		outer.append(base + normal * side_sign * width * (outer_ratio + scallop))
		inner.append(base + normal * side_sign * width * inner_ratio)
	for index in range(inner.size() - 1, -1, -1):
		outer.append(inner[index])
	return outer


func _draw_closed_hair_shape(points: PackedVector2Array, fill: Color, rim: Color) -> void:
	if points.size() < 3:
		return
	if fill.a > 0.001:
		draw_colored_polygon(points, fill)
	if rim.a > 0.001:
		var outline := PackedVector2Array(points)
		outline.append(points[0])
		draw_polyline(outline, rim, 1.0, true)


func _draw_hair_shape_fan(points: PackedVector2Array, fill: Color, rim: Color) -> void:
	if points.size() < 3:
		return
	var render_points := _hair_smooth_closed_loop(points, 3)
	var center := Vector2.ZERO
	for point in render_points:
		center += point
	center /= float(render_points.size())
	if fill.a > 0.001:
		for index in range(render_points.size()):
			var next_index := (index + 1) % render_points.size()
			_draw_triangle_safe(center, render_points[index], render_points[next_index], fill)
	if rim.a > 0.001:
		var outline := PackedVector2Array(render_points)
		outline.append(render_points[0])
		draw_polyline(outline, rim, 1.0, true)


func _hair_strand_points(
		root: Vector2,
		flow: Vector2,
		wave_axis: Vector2,
		length: float,
		sway: float,
		phase: float,
		turn: float,
		wind: float,
		steps: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_steps := maxi(steps, 2)
	var physics := maxf(hair_fx_physics, 0.0)
	var wave_rate := lerpf(1.35, 5.40, wind)
	var motion_scale := (0.22 + wind * 0.78 + absf(turn) * 0.18) * physics
	for i in range(safe_steps + 1):
		var t := float(i) / float(safe_steps)
		var stiffness := t * t
		var lag_phase := phase + _time * wave_rate - t * (1.70 + wind * 1.45)
		var wave := wave_axis * sin(lag_phase) * sway * stiffness * motion_scale
		var turn_lag := wave_axis * turn * length * 0.22 * stiffness
		var hover_drop := Vector2.DOWN * (1.0 - wind) * (2.8 * t * t + sin(_time * 0.82 + phase + t * 1.6) * 0.55 * t) * hair_fx_hover_drop * physics
		var tip_hook := flow.rotated(turn * 0.34) * length * t * (0.88 + wind * 0.16)
		points.append(root + tip_hook + wave + turn_lag + hover_drop)
	return points


func _draw_hair_gradient_strand(points: PackedVector2Array, start_width: float, end_width: float, color: Color) -> void:
	if points.size() < 2 or color.a <= 0.001:
		return
	var render_points := _hair_smooth_open_curve(points, 3)
	var safe_start_width := maxf(start_width, 0.10)
	var safe_end_width := maxf(end_width, 0.04)
	var segment_count := render_points.size() - 1
	for i in range(segment_count):
		var t := float(i) / maxf(float(segment_count - 1), 1.0)
		var fade := pow(1.0 - t, 1.55)
		var width := lerpf(safe_start_width, safe_end_width, t)
		var segment_color := Color(color.r, color.g, color.b, color.a * fade)
		draw_line(render_points[i], render_points[i + 1], segment_color, width, true)
		if i == 0:
			draw_circle(render_points[i], width * 0.48, segment_color)
	var tip_color := Color(color.r, color.g, color.b, color.a * 0.08)
	draw_circle(render_points[render_points.size() - 1], maxf(end_width * 0.55, 0.25), tip_color)


func _draw_hair_groom_debug_overlay(pose: Dictionary) -> void:
	if not hair_fx_debug_overlay or not hair_fx_enabled:
		return
	var state := _hair_fx_state(pose)
	var layers := _hair_direction_layers(pose, state)
	_draw_hair_debug_scalp_mask(pose)
	_draw_hair_debug_sdf_colliders(pose)
	_draw_hair_debug_main_chains(pose, state)
	_draw_hair_debug_layer_meter(pose, layers)


func _draw_hair_debug_scalp_mask(pose: Dictionary) -> void:
	var geometry := _hair_scalp_mask_geometry(pose)
	var center: Vector2 = geometry["center"]
	var side: Vector2 = geometry["side"]
	var radius_x := float(geometry["radius_x"])
	var radius_y := float(geometry["radius_y"])
	var points := PackedVector2Array()
	var steps := 40
	for index in range(steps + 1):
		var angle := TAU * float(index) / float(steps)
		points.append(center + side * cos(angle) * radius_x + Vector2.UP * sin(angle) * radius_y)
	draw_polyline(points, Color(0.26, 1.0, 0.70, 0.72), 0.90, true)
	draw_circle(center, 1.35, Color(0.26, 1.0, 0.70, 0.82))


func _draw_hair_debug_sdf_colliders(pose: Dictionary) -> void:
	var head_center: Vector2 = pose["head_center"]
	draw_arc(head_center, _hair_head_radius(pose) * 0.86, 0.0, TAU, 36, Color(1.0, 0.52, 0.20, 0.58), 0.85, true)
	if pose.has("shoulder_near") and pose.has("shoulder_far"):
		var shoulder_near: Vector2 = pose["shoulder_near"]
		var shoulder_far: Vector2 = pose["shoulder_far"]
		var shoulder_radius := maxf(7.0, float(pose.get("torso_width", 10.0)) * 0.42 + 5.0)
		_draw_debug_capsule(shoulder_far, shoulder_near, shoulder_radius, Color(1.0, 0.52, 0.20, 0.45))
	if pose.has("shoulder_center") and pose.has("hip_center"):
		var shoulder_center: Vector2 = pose["shoulder_center"]
		var hip_center: Vector2 = pose["hip_center"]
		var body_radius := maxf(8.0, float(pose.get("torso_width", 10.0)) * 0.46 + 5.5)
		_draw_debug_capsule(shoulder_center, hip_center, body_radius, Color(1.0, 0.52, 0.20, 0.34))


func _draw_debug_capsule(a: Vector2, b: Vector2, radius: float, color: Color) -> void:
	var axis := b - a
	if axis.length_squared() <= 0.001:
		draw_arc(a, radius, 0.0, TAU, 24, color, 0.75, true)
		return
	var normal := axis.normalized().rotated(PI * 0.5)
	draw_line(a + normal * radius, b + normal * radius, color, 0.75, true)
	draw_line(a - normal * radius, b - normal * radius, color, 0.75, true)
	draw_arc(a, radius, 0.0, TAU, 24, color, 0.65, true)
	draw_arc(b, radius, 0.0, TAU, 24, color, 0.65, true)


func _draw_hair_debug_main_chains(pose: Dictionary, state: Dictionary) -> void:
	for lock_def in _hair_groom_lock_defs():
		var lock_id := String(lock_def.get("id", ""))
		var target := _hair_groom_target_points(lock_def, pose, state)
		var points := _hair_groom_chain_points(lock_id, target)
		if points.size() < 2:
			continue
		var region := String(lock_def.get("region", "occipital"))
		var color := Color(0.40, 0.78, 1.0, 0.72)
		if region == "nape":
			color = Color(0.58, 0.62, 1.0, 0.76)
		elif region == "temple" or region == "cover":
			color = Color(1.0, 0.78, 0.25, 0.76)
		draw_polyline(points, color, 0.85, true)
		for index in range(points.size()):
			var t := float(index) / maxf(float(points.size() - 1), 1.0)
			var radius := lerpf(1.75, 0.95, t)
			draw_circle(points[index], radius, Color(color.r, color.g, color.b, 0.86))
		var root: Vector2 = points[0]
		var root_ok := _hair_is_inside_scalp_mask(pose, root, _hair_head_radius(pose) * 0.16)
		draw_circle(root, 2.35, Color(0.24, 1.0, 0.56, 0.92) if root_ok else Color(1.0, 0.10, 0.10, 0.95))


func _draw_hair_debug_layer_meter(pose: Dictionary, layers: Dictionary) -> void:
	var origin: Vector2 = pose["head_center"] + Vector2(-34.0, -38.0)
	var bar_width := 34.0
	var bar_height := 2.8
	var values := [
		float(layers.get("back_alpha", 0.0)),
		float(layers.get("body_front_alpha", 0.0)),
		float(layers.get("front_lock_alpha", 0.0)),
		float(layers.get("turn_front_boost", 0.0)),
	]
	var colors := [
		Color(0.40, 0.78, 1.0, 0.74),
		Color(1.0, 0.72, 0.24, 0.74),
		Color(0.86, 1.0, 0.52, 0.74),
		Color(1.0, 0.34, 0.68, 0.74),
	]
	for index in range(values.size()):
		var y := float(index) * (bar_height + 1.8)
		draw_rect(Rect2(origin + Vector2(0.0, y), Vector2(bar_width, bar_height)), Color(0.0, 0.0, 0.0, 0.34), false, 0.55)
		draw_rect(Rect2(origin + Vector2(0.0, y), Vector2(bar_width * clampf(values[index], 0.0, 1.0), bar_height)), colors[index], true)


func _draw_clean_skeleton(pose: Dictionary) -> void:
	var speed_ratio: float = clampf(float(pose.get("speed_ratio", 0.0)), 0.0, 1.0)
	var width_scale := 1.0 + speed_ratio * 0.18 + _boost * 0.12
	var spine_width := 8.4 * width_scale
	var arm_width := 6.2 * width_scale
	var leg_width := 7.4 * width_scale
	var shoulder_center: Vector2 = pose["shoulder_center"]
	var hip_center: Vector2 = pose["hip_center"]
	var draw_order := _front_side_adjusted_draw_order(pose.get("draw_order", EDIT_DRAW_LAYER_KEYS), pose)
	for layer_key_variant in draw_order:
		_draw_clean_skeleton_layer(String(layer_key_variant), pose, arm_width, leg_width, spine_width, width_scale)

	if _editor_active or SHOW_JOINTS_IN_GAME:
		for key in EDIT_JOINT_KEYS:
			var point: Vector2 = pose[key]
			var radius := 2.35 * width_scale
			if key == "head_center":
				radius = 1.7 * width_scale
			_draw_clean_joint(point, radius)

	if _switch_flash > 0.0:
		var flash_color := Color(0.86, 1.0, 1.0, 0.16 * _switch_flash)
		draw_arc(shoulder_center.lerp(hip_center, 0.46), 42.0 + _switch_flash * 12.0, -PI * 0.15, PI * 1.15, 36, flash_color, 1.6, true)


func _draw_clean_skeleton_layer(layer_key: String, pose: Dictionary, arm_width: float, leg_width: float, spine_width: float, width_scale: float) -> void:
	match layer_key:
		"far_arm":
			var far_arm_front := _is_front_body_layer(layer_key, pose)
			_draw_clean_limb(
				pose["shoulder_far"],
				pose["elbow_far"],
				pose["wrist_far"],
				arm_width * (1.08 if far_arm_front else 0.90),
				1.0 if far_arm_front else 0.48,
				1.0 if far_arm_front else -0.7
			)
		"far_leg":
			var far_leg_front := _is_front_body_layer(layer_key, pose)
			_draw_clean_limb(
				pose["hip_far"],
				pose["knee_far"],
				pose["ankle_far"],
				leg_width * (1.04 if far_leg_front else 0.92),
				0.94 if far_leg_front else 0.48,
				0.9 if far_leg_front else -0.7
			)
		"torso":
			_draw_clean_torso(pose, spine_width, width_scale)
		"head":
			var head_radius := _clean_head_radius(pose)
			var head_width_scale := clampf(float(pose.get("head_scale", 1.0)), 0.35, 2.0)
			_draw_clean_head_volume(pose["head_center"], pose["heading"], pose["side"], head_radius, head_width_scale)
		"near_leg":
			var near_leg_front := _is_front_body_layer(layer_key, pose)
			_draw_clean_limb(
				pose["hip_near"],
				pose["knee_near"],
				pose["ankle_near"],
				leg_width * (1.04 if near_leg_front else 0.92),
				0.94 if near_leg_front else 0.48,
				0.9 if near_leg_front else -0.7
			)
		"near_arm":
			var near_arm_front := _is_front_body_layer(layer_key, pose)
			_draw_clean_limb(
				pose["shoulder_near"],
				pose["elbow_near"],
				pose["wrist_near"],
				arm_width * (1.08 if near_arm_front else 0.90),
				1.0 if near_arm_front else 0.48,
				1.0 if near_arm_front else -0.7
			)


func _clean_head_radius(pose: Dictionary) -> float:
	var head_scale := clampf(float(pose.get("head_scale", 1.0)), 0.35, 2.0)
	return 10.8 * head_scale


func _draw_clean_torso(pose: Dictionary, spine_width: float, width_scale: float) -> void:
	var head_center: Vector2 = pose["head_center"]
	var shoulder_center: Vector2 = pose["shoulder_center"]
	var hip_mid: Vector2 = pose["hip_near"].lerp(pose["hip_far"], 0.5)
	var neck: Vector2 = shoulder_center.lerp(head_center, 0.34)
	_draw_clean_body_volume(pose, width_scale)
	_draw_clean_bone(neck, hip_mid, spine_width + 2.0, _clean_alpha(CLEAN_BONE, 0.94), 0.45)
	_draw_clean_bone(pose["shoulder_far"], pose["shoulder_near"], spine_width * 0.98, _clean_alpha(CLEAN_BONE, 0.94), 0.65)
	_draw_clean_bone(pose["hip_far"], pose["hip_near"], spine_width * 0.88, _clean_alpha(CLEAN_BONE, 0.82), 0.55)


func _draw_clean_limb(a: Vector2, b: Vector2, c: Vector2, width: float, alpha: float, depth := 1.0) -> void:
	var color := _clean_alpha(CLEAN_BONE, alpha)
	_draw_clean_bone(a, b, width * 1.14, color, depth)
	_draw_clean_bone(b, c, width * 0.94, _clean_alpha(CLEAN_BONE, alpha * 0.94), depth)
	_draw_clean_joint_volume(b, width * 0.48, alpha, depth)


func _draw_clean_bone(a: Vector2, b: Vector2, width: float, color: Color, depth := 1.0) -> void:
	if color.a <= 0.001 or a.distance_squared_to(b) <= 0.001:
		return
	var dir := b - a
	var normal := dir.normalized().rotated(PI * 0.5)
	var depth_sign := -1.0 if depth < 0.0 else 1.0
	var depth_strength := clampf(absf(depth), 0.0, 1.0)
	var depth_offset := normal * clampf(width * 0.24, 0.75, 2.10) * depth_sign + Vector2(0.0, 0.55)
	var glow_width := width + 4.8
	var glow := _clean_alpha(CLEAN_BONE_SOFT, 0.68 * color.a / CLEAN_BONE.a)
	draw_line(a, b, glow, glow_width, true)
	draw_circle(a, glow_width * 0.5, glow)
	draw_circle(b, glow_width * 0.5, glow)
	var shadow := _clean_alpha(CLEAN_BONE_SHADOW, (0.86 + depth_strength * 0.34) * color.a / CLEAN_BONE.a)
	draw_line(a + depth_offset, b + depth_offset, shadow, width + 2.4, true)
	draw_circle(a + depth_offset, (width + 2.4) * 0.5, shadow)
	draw_circle(b + depth_offset, (width + 2.4) * 0.5, shadow)
	var rim := _clean_alpha(CLEAN_VOLUME_RIM, (0.58 + depth_strength * 0.18) * color.a / CLEAN_BONE.a)
	draw_line(a, b, rim, width + 2.1, true)
	draw_circle(a, (width + 2.1) * 0.5, rim)
	draw_circle(b, (width + 2.1) * 0.5, rim)
	draw_line(a, b, color, width, true)
	draw_circle(a, width * 0.5, color)
	draw_circle(b, width * 0.5, color)
	var core_shadow := _clean_alpha(Color(0.018, 0.024, 0.028, 0.56), color.a / CLEAN_BONE.a)
	draw_line(a + depth_offset * 0.35, b + depth_offset * 0.35, core_shadow, maxf(width * 0.48, 1.8), true)
	var highlight := _clean_alpha(CLEAN_BONE_HIGHLIGHT, (0.56 + depth_strength * 0.20) * color.a / CLEAN_BONE.a)
	var highlight_offset := -depth_offset * 0.42 + Vector2(-0.15, -0.35)
	draw_line(a + highlight_offset, b + highlight_offset, highlight, maxf(width * 0.30, 1.2), true)
	draw_circle(a + highlight_offset, maxf(width * 0.12, 0.65), highlight)


func _draw_clean_joint_volume(point: Vector2, radius: float, alpha: float, depth := 1.0) -> void:
	var depth_sign := -1.0 if depth < 0.0 else 1.0
	var shadow_offset := Vector2(0.65 * depth_sign, 0.75)
	var shadow := _clean_alpha(CLEAN_BONE_SHADOW, 0.78 * alpha)
	draw_circle(point + shadow_offset, radius + 1.4, shadow)
	draw_circle(point, radius + 0.8, _clean_alpha(CLEAN_VOLUME_RIM, 0.58 * alpha))
	draw_circle(point, radius, _clean_alpha(CLEAN_BONE, alpha))
	draw_circle(point + Vector2(-0.45, -0.60) * radius, maxf(radius * 0.32, 0.8), _clean_alpha(CLEAN_BONE_HIGHLIGHT, 0.72 * alpha))


func _draw_clean_body_volume(pose: Dictionary, width_scale: float) -> void:
	var shoulder_near: Vector2 = pose["shoulder_near"]
	var shoulder_far: Vector2 = pose["shoulder_far"]
	var hip_near: Vector2 = pose["hip_near"]
	var hip_far: Vector2 = pose["hip_far"]
	var shoulder_center: Vector2 = pose["shoulder_center"]
	var hip_center: Vector2 = pose["hip_center"]
	var h: Vector2 = pose["heading"]
	var side: Vector2 = pose["side"]
	var chest := PackedVector2Array([
		shoulder_far + h * 2.0 - side * 1.2,
		shoulder_near + h * 2.4 + side * 1.4,
		hip_near - h * 1.0 + side * 2.2,
		hip_far - h * 1.2 - side * 1.6,
	])
	_draw_quad_safe(chest[0], chest[1], chest[2], chest[3], CLEAN_VOLUME)
	_draw_closed_polyline(chest, _clean_alpha(CLEAN_VOLUME_RIM, 0.95), 2.0 * width_scale)
	var rib_a := shoulder_center.lerp(hip_center, 0.32)
	var rib_b := shoulder_center.lerp(hip_center, 0.60)
	draw_line(rib_a - side * 7.4 * width_scale, rib_a + side * 6.8 * width_scale, _clean_alpha(CLEAN_VOLUME_RIM, 0.70), 1.8 * width_scale, true)
	draw_line(rib_b - side * 5.4 * width_scale, rib_b + side * 4.8 * width_scale, _clean_alpha(CLEAN_VOLUME_RIM, 0.46), 1.2 * width_scale, true)
	draw_line(shoulder_center.lerp(hip_center, 0.18) - side * 2.2 * width_scale, hip_center - side * 1.6 * width_scale, _clean_alpha(CLEAN_BONE_HIGHLIGHT, 0.28), 2.0 * width_scale, true)
	draw_circle(shoulder_center.lerp(hip_center, 0.48) - side * 2.0 * width_scale + h * 1.0, 2.4 * width_scale, _clean_alpha(CLEAN_BONE_HIGHLIGHT, 0.48))


func _draw_clean_head_volume(head_center: Vector2, h: Vector2, side: Vector2, head_radius: float, width_scale: float) -> void:
	draw_circle(head_center, head_radius + 4.0 * width_scale, _clean_alpha(CLEAN_BONE_SOFT, 0.72))
	draw_circle(head_center + side * 1.2 * width_scale + Vector2(0.0, 1.1) * width_scale, head_radius + 1.2 * width_scale, _clean_alpha(CLEAN_BONE_SHADOW, 0.70))
	draw_circle(head_center, head_radius + 0.8 * width_scale, _clean_alpha(CLEAN_VOLUME_RIM, 0.54))
	draw_circle(head_center, head_radius, CLEAN_HEAD_FILL)
	draw_arc(head_center, head_radius + 1.1 * width_scale, 0.0, TAU, 32, CLEAN_HEAD, 2.4 * width_scale, true)
	draw_arc(head_center - h * 1.8 * width_scale - side * 1.2 * width_scale, head_radius * 0.70, PI * 0.10, PI * 1.24, 18, _clean_alpha(CLEAN_BONE_HIGHLIGHT, 0.58), 1.4 * width_scale, true)
	draw_circle(head_center - side * 2.9 * width_scale + Vector2(-0.8, -2.0) * width_scale, maxf(1.7 * width_scale, 0.9), _clean_alpha(CLEAN_BONE_HIGHLIGHT, 0.92))


func _draw_clean_joint(point: Vector2, radius: float) -> void:
	draw_circle(point, radius + 2.5, _clean_alpha(CLEAN_BONE_SOFT, 0.76))
	draw_circle(point + Vector2(0.55, 0.75), radius + 0.5, _clean_alpha(CLEAN_BONE_SHADOW, 0.68))
	draw_circle(point, radius, CLEAN_JOINT)
	draw_circle(point + Vector2(-0.34, -0.42) * radius, maxf(radius * 0.34, 0.75), CLEAN_BONE_HIGHLIGHT)


func _clean_alpha(color: Color, alpha_scale: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * clampf(alpha_scale, 0.0, 1.8))


func _draw_ink_presence(pose: Dictionary) -> void:
	var head_center: Vector2 = pose["head_center"]
	var shoulder_center: Vector2 = pose["shoulder_center"]
	var hip_center: Vector2 = pose["hip_center"]
	var h: Vector2 = pose["heading"]
	var fast: float = clampf(float(pose.get("fast_pose", 0.0)), 0.0, 1.0)
	var wind_power := _cloth_wind_power(pose)
	var body_axis := hip_center - head_center
	if body_axis.length_squared() <= 0.0001:
		body_axis = Vector2.DOWN
	var center := head_center.lerp(hip_center, 0.58)
	var aura := Color(INK_BODY_GLOW.r, INK_BODY_GLOW.g, INK_BODY_GLOW.b, INK_BODY_GLOW.a * (0.82 + fast * 0.76))
	draw_line(head_center - h * 5.0, hip_center + Vector2(0.0, 11.0), aura, 15.0 + fast * 7.0 + wind_power * 4.0, true)
	draw_circle(center + Vector2(0.0, 5.0), 28.0 + fast * 5.0, Color(0.48, 0.78, 0.86, 0.014 + fast * 0.010))
	draw_line(shoulder_center - h * (18.0 + fast * 13.0), shoulder_center + h * (14.0 + fast * 18.0), Color(0.90, 1.0, 0.94, 0.030 + fast * 0.026), 6.0 + fast * 4.0, true)
	if _switch_flash > 0.0:
		draw_arc(center, 52.0 + _switch_flash * 18.0, -PI * 0.18, PI * 1.12, 36, Color(0.66, 1.0, 1.0, 0.10 * _switch_flash), 2.2, true)


func _draw_back_robe_tail(pose: Dictionary) -> void:
	var hip_near: Vector2 = pose["hip_near"]
	var hip_far: Vector2 = pose["hip_far"]
	var hip_center: Vector2 = pose["hip_center"]
	var side: Vector2 = pose["side"]
	var fast: float = clampf(float(pose.get("fast_pose", 0.0)), 0.0, 1.0)
	var wind_power: float = _cloth_wind_power(pose)
	var flow: Vector2 = _cloth_motion_vector(pose, 30.0 + fast * 10.0, 42.0 + fast * 22.0, 3.0, 0.4)
	var wind_unit := clampf(wind_power, 0.0, 1.0)
	var base_width := 8.0 + fast * 3.0
	_draw_cloth_panel(
		hip_far.lerp(hip_center, 0.42) + Vector2(0.0, 3.0),
		flow * (0.62 + wind_unit * 0.08),
		side,
		-base_width,
		5.8,
		8.2 + fast * 2.6,
		2.8,
		0.8,
		Color(CLOTH_PANEL.r, CLOTH_PANEL.g, CLOTH_PANEL.b, 0.26),
		Color(CLOTH_RIM.r, CLOTH_RIM.g, CLOTH_RIM.b, 0.22)
	)
	_draw_cloth_panel(
		hip_center + Vector2(0.0, 4.0),
		flow * (0.72 + wind_unit * 0.10),
		side,
		0.0,
		6.2,
		9.5 + fast * 3.0,
		3.2,
		2.0,
		Color(0.010, 0.012, 0.014, 0.30),
		Color(CLOTH_RIM.r, CLOTH_RIM.g, CLOTH_RIM.b, 0.24)
	)
	_draw_cloth_panel(
		hip_near.lerp(hip_center, 0.38) + Vector2(0.0, 3.0),
		flow * (0.64 + wind_unit * 0.08),
		side,
		base_width,
		5.6,
		8.0 + fast * 2.4,
		2.8,
		3.2,
		Color(0.028, 0.031, 0.033, 0.22),
		Color(CLOTH_RIM.r, CLOTH_RIM.g, CLOTH_RIM.b, 0.18)
	)


func _draw_torso(pose: Dictionary) -> void:
	var shoulder_near: Vector2 = pose["shoulder_near"]
	var shoulder_far: Vector2 = pose["shoulder_far"]
	var hip_near: Vector2 = pose["hip_near"]
	var hip_far: Vector2 = pose["hip_far"]
	var shoulder_center: Vector2 = pose["shoulder_center"]
	var hip_center: Vector2 = pose["hip_center"]
	var h: Vector2 = pose["heading"]
	var side: Vector2 = pose["side"]
	var wind_power: float = _cloth_wind_power(pose)
	var points := PackedVector2Array([
		shoulder_near,
		shoulder_far,
		hip_far,
		hip_near,
	])
	_draw_closed_polyline(points, OUTLINE, 5.2)
	_draw_quad_safe(shoulder_near, shoulder_far, hip_far, hip_near, TORSO)
	_draw_quad_safe(
		shoulder_near.lerp(shoulder_far, 0.18),
		shoulder_near.lerp(shoulder_far, 0.46),
		hip_center + side * 1.5 + h * 2.0,
		hip_near.lerp(hip_far, 0.28),
		Color(0.25, 0.26, 0.25, 0.52)
	)
	_draw_closed_polyline(points, INK_EDGE, 1.4)
	var fast: float = clampf(float(pose.get("fast_pose", 0.0)), 0.0, 1.0)
	var robe_drop: Vector2 = _cloth_motion_vector(pose, 20.0 + fast * 6.0, 22.0 + fast * 12.0, 2.2, 1.1)
	var skirt_far_bottom: Vector2 = hip_far + robe_drop - side * 4.8 - h * 2.0
	var skirt_bottom_center: Vector2 = hip_center + robe_drop + Vector2(0.0, 7.0 + fast * 2.0)
	var skirt_near_bottom: Vector2 = hip_near + robe_drop + side * 5.6 - h * 2.0
	var skirt_points := PackedVector2Array([
		hip_near,
		hip_far,
		skirt_far_bottom,
		skirt_bottom_center,
		skirt_near_bottom,
	])
	_draw_closed_polyline(skirt_points, OUTLINE, 3.4)
	var skirt_color := Color(ROBE_SHADOW.r, ROBE_SHADOW.g, ROBE_SHADOW.b, 0.58)
	_draw_triangle_safe(hip_near, hip_far, skirt_bottom_center, skirt_color)
	_draw_triangle_safe(hip_far, skirt_far_bottom, skirt_bottom_center, skirt_color)
	_draw_triangle_safe(hip_near, skirt_bottom_center, skirt_near_bottom, skirt_color)
	var front_flap_root: Vector2 = hip_center + Vector2(0.0, 3.5)
	_draw_cloth_panel(
		front_flap_root,
		robe_drop * (0.55 + clampf(wind_power, 0.0, 1.0) * 0.12),
		side,
		0.0,
		3.6,
		5.6,
		1.6,
		5.1,
		Color(0.018, 0.020, 0.022, 0.34),
		Color(CLOTH_RIM.r, CLOTH_RIM.g, CLOTH_RIM.b, 0.24)
	)
	draw_line(hip_far + robe_drop * 0.22, hip_far + robe_drop - side * 4.0, Color(ROBE_LIGHT.r, ROBE_LIGHT.g, ROBE_LIGHT.b, 0.44), 1.6, true)
	draw_line(hip_center + robe_drop * 0.18, skirt_bottom_center, Color(0.82, 0.84, 0.80, 0.34), 1.8, true)
	draw_line(hip_near + robe_drop * 0.22, hip_near + robe_drop + side * 4.4, Color(ROBE_LIGHT.r, ROBE_LIGHT.g, ROBE_LIGHT.b, 0.44), 1.6, true)
	var collar_left := shoulder_center.lerp(shoulder_near, 0.56)
	var collar_right := shoulder_center.lerp(shoulder_far, 0.56)
	var collar_bottom := hip_center + h * 3.0 + Vector2(0.0, -3.0)
	draw_line(collar_left, collar_bottom, OUTLINE, 3.2, true)
	draw_line(collar_right, collar_bottom, OUTLINE, 3.2, true)
	draw_line(collar_left, collar_bottom, ROBE_TRIM, 1.8, true)
	draw_line(collar_right, collar_bottom, ROBE_TRIM, 1.8, true)
	draw_line(hip_near, hip_far, OUTLINE, 6.2, true)
	draw_line(hip_near, hip_far, SASH, 3.8, true)
	draw_line(hip_near + Vector2(0.0, 4.0), hip_far + Vector2(0.0, 4.0), Color(0.60, 0.62, 0.58, 0.34), 1.6, true)
	draw_circle(hip_center + h * 2.0, 3.0, OUTLINE)
	draw_circle(hip_center + h * 2.0, 2.0, JADE)
	draw_line(shoulder_near, shoulder_far, ROBE_TRIM, 1.6, true)


func _draw_body_layer(layer_key: String, pose: Dictionary) -> void:
	match layer_key:
		"far_arm":
			var far_arm_front := _is_front_body_layer(layer_key, pose)
			_draw_robed_arm(pose, pose["shoulder_far"], pose["elbow_far"], pose["wrist_far"], far_arm_front)
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
			_draw_robed_arm(pose, pose["shoulder_near"], pose["elbow_near"], pose["wrist_near"], near_arm_front)


func _draw_robed_arm(pose: Dictionary, shoulder: Vector2, elbow: Vector2, wrist: Vector2, is_front: bool) -> void:
	var alpha := 1.0 if is_front else 0.56
	_draw_capsule(shoulder, elbow, 9.5 if is_front else 8.2, UPPER_ARM, alpha)
	_draw_capsule(elbow, wrist, 10.5 if is_front else 9.0, FOREARM, alpha)
	_draw_wide_sleeve(pose, shoulder, elbow, wrist, alpha)
	_draw_sleeve_cuff(elbow, wrist, alpha)
	_draw_hand_silhouette(elbow, wrist, alpha)
	var fold_dir := (wrist - shoulder)
	if fold_dir.length_squared() > 0.0001:
		var normal := fold_dir.normalized().rotated(PI * 0.5)
		var fold_start := elbow.lerp(wrist, 0.18)
		var fold_end := elbow.lerp(wrist, 0.76)
		draw_line(fold_start + normal * 2.0, fold_end + normal * 2.0, Color(0.96, 1.0, 0.94, 0.32 * alpha), 1.4, true)


func _draw_wide_sleeve(pose: Dictionary, shoulder: Vector2, elbow: Vector2, wrist: Vector2, alpha: float) -> void:
	var arm_dir := wrist - shoulder
	if arm_dir.length_squared() <= 0.0001:
		return
	var normal := arm_dir.normalized().rotated(PI * 0.5)
	var sleeve_tip := elbow.lerp(wrist, 0.34)
	var sleeve_drag: Vector2 = _cloth_motion_vector(pose, 7.0, 12.0, 1.4, shoulder.x * 0.03 + wrist.y * 0.02)
	var shoulder_outer: Vector2 = shoulder + normal * 6.4
	var shoulder_inner: Vector2 = shoulder - normal * 4.6
	var sleeve_inner: Vector2 = sleeve_tip - normal * 7.4 + sleeve_drag * 0.22
	var wrist_inner: Vector2 = wrist - normal * 4.8 + sleeve_drag * 0.16
	var elbow_outer: Vector2 = elbow + normal * 7.2 + sleeve_drag * 0.12
	var sleeve := PackedVector2Array([
		shoulder_outer,
		shoulder_inner,
		sleeve_inner,
		wrist_inner,
		elbow_outer,
	])
	_draw_closed_polyline(sleeve, OUTLINE, 2.8)
	var sleeve_color := ROBE_SHADOW
	sleeve_color.a *= alpha * 0.46
	_draw_triangle_safe(shoulder_outer, shoulder_inner, elbow_outer, sleeve_color)
	_draw_triangle_safe(shoulder_inner, sleeve_inner, elbow_outer, sleeve_color)
	_draw_triangle_safe(sleeve_inner, wrist_inner, elbow_outer, sleeve_color)
	draw_line(shoulder + normal * 5.2, elbow + normal * 6.6, Color(ROBE_LIGHT.r, ROBE_LIGHT.g, ROBE_LIGHT.b, 0.38 * alpha), 1.2, true)
	draw_line(shoulder_inner.lerp(sleeve_inner, 0.18), wrist_inner, Color(CLOTH_RIM.r, CLOTH_RIM.g, CLOTH_RIM.b, 0.24 * alpha), 1.0, true)


func _draw_robed_leg(hip: Vector2, knee: Vector2, ankle: Vector2, is_front: bool) -> void:
	var alpha := 1.0 if is_front else 0.58
	_draw_capsule(hip, knee, 12.6 if is_front else 11.4, THIGH, alpha)
	_draw_capsule(knee, ankle, 9.6 if is_front else 8.6, CALF, alpha)
	var leg_dir := ankle - knee
	if leg_dir.length_squared() > 0.0001:
		var boot_top := knee.lerp(ankle, 0.58)
		_draw_capsule(boot_top, ankle, 8.6 if is_front else 7.8, BOOT, alpha)
		var leg_normal: Vector2 = leg_dir.normalized().rotated(PI * 0.5)
		draw_line(hip.lerp(knee, 0.18) + leg_normal * 2.0, ankle - leg_normal * 1.5, Color(0.72, 0.74, 0.70, 0.18 * alpha), 1.0, true)
	_draw_boot_tip(knee, ankle, alpha)


func _draw_sleeve_cuff(elbow: Vector2, wrist: Vector2, alpha: float) -> void:
	var dir := wrist - elbow
	if dir.length_squared() <= 0.0001:
		return
	var cuff_center := elbow.lerp(wrist, 0.82)
	var normal := dir.normalized().rotated(PI * 0.5)
	draw_line(cuff_center - normal * 5.0, cuff_center + normal * 5.0, OUTLINE, 4.2, true)
	draw_line(cuff_center - normal * 4.2, cuff_center + normal * 4.2, ROBE_TRIM, 2.0 * alpha, true)


func _draw_hand_silhouette(elbow: Vector2, wrist: Vector2, alpha: float) -> void:
	var dir := wrist - elbow
	if dir.length_squared() <= 0.0001:
		return
	var forward := dir.normalized()
	var normal := forward.rotated(PI * 0.5)
	var palm := wrist + forward * 3.0
	var hand := PackedVector2Array([
		palm + forward * 5.5,
		palm + normal * 4.0,
		palm - forward * 4.5,
		palm - normal * 3.5,
	])
	_draw_closed_polyline(hand, OUTLINE, 2.2)
	var hand_color := Color(0.012, 0.014, 0.016, 0.82 * alpha)
	_draw_quad_safe(hand[0], hand[1], hand[2], hand[3], hand_color)
	draw_line(palm + normal * 1.8, palm + forward * 7.5 + normal * 2.6, Color(0.84, 0.86, 0.80, 0.26 * alpha), 1.0, true)


func _draw_boot_tip(knee: Vector2, ankle: Vector2, alpha: float) -> void:
	var dir := ankle - knee
	if dir.length_squared() <= 0.0001:
		return
	var forward := dir.normalized()
	var normal := forward.rotated(PI * 0.5)
	var toe := ankle + forward * 7.0
	var heel_top := ankle - forward * 2.0 + normal * 4.2
	var heel_bottom := ankle - forward * 4.0 - normal * 3.4
	var boot_tip := PackedVector2Array([
		toe,
		heel_top,
		heel_bottom,
	])
	_draw_closed_polyline(boot_tip, OUTLINE, 2.6)
	var boot_color := BOOT
	boot_color.a *= alpha
	_draw_triangle_safe(toe, heel_top, heel_bottom, boot_color)


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


func _draw_outer_rim(pose: Dictionary) -> void:
	var h: Vector2 = pose["heading"]
	var side: Vector2 = pose["side"]
	var fast: float = clampf(float(pose.get("fast_pose", 0.0)), 0.0, 1.0)
	var wind_power := _cloth_wind_power(pose)
	var cold := Color(INK_RIM_COLD.r, INK_RIM_COLD.g, INK_RIM_COLD.b, INK_RIM_COLD.a * (0.58 + fast * 0.28))
	var warm := Color(INK_RIM_WARM.r, INK_RIM_WARM.g, INK_RIM_WARM.b, INK_RIM_WARM.a * (0.54 + fast * 0.20))
	var head_center: Vector2 = pose["head_center"]
	var shoulder_near: Vector2 = pose["shoulder_near"]
	var shoulder_far: Vector2 = pose["shoulder_far"]
	var hip_near: Vector2 = pose["hip_near"]
	var hip_far: Vector2 = pose["hip_far"]
	var knee_near: Vector2 = pose["knee_near"]
	var knee_far: Vector2 = pose["knee_far"]
	var ankle_near: Vector2 = pose["ankle_near"]
	var ankle_far: Vector2 = pose["ankle_far"]
	var wind_edge := _cloth_direction(pose) * (2.0 + wind_power * 2.6)
	draw_line(head_center - h * 9.0 + side * 5.0, shoulder_near + side * 3.5, cold, 2.2 + fast * 0.7, true)
	draw_line(shoulder_near + side * 3.2, hip_near + side * 3.4 + wind_edge * 0.18, cold, 2.4 + fast * 0.8, true)
	draw_line(shoulder_far - side * 2.5, hip_far - side * 2.8 + wind_edge * 0.12, Color(cold.r, cold.g, cold.b, cold.a * 0.58), 1.8, true)
	draw_line(hip_near + side * 2.0, knee_near + side * 2.2, warm, 1.8, true)
	draw_line(knee_near + side * 2.1, ankle_near + side * 1.8, warm, 1.6, true)
	draw_line(hip_far - side * 1.6, knee_far - side * 1.8, Color(warm.r, warm.g, warm.b, warm.a * 0.50), 1.3, true)
	draw_line(knee_far - side * 1.4, ankle_far - side * 1.3, Color(warm.r, warm.g, warm.b, warm.a * 0.45), 1.2, true)
	var shoulder_edge_start := shoulder_far.lerp(shoulder_near, 0.18)
	var shoulder_edge_end := shoulder_far.lerp(shoulder_near, 0.86)
	draw_line(shoulder_edge_start, shoulder_edge_end, Color(0.95, 1.0, 0.94, 0.24 + fast * 0.06), 1.4, true)


func _draw_hair_and_ribbons(pose: Dictionary) -> void:
	var head_center: Vector2 = pose["head_center"]
	var shoulder_center: Vector2 = pose["shoulder_center"]
	var hip_center: Vector2 = pose["hip_center"]
	var h: Vector2 = pose["heading"]
	var side: Vector2 = pose["side"]
	var wind_power: float = _cloth_wind_power(pose)
	var wind_unit: float = clampf(wind_power, 0.0, 1.0)
	var hair_root: Vector2 = head_center - h * 8.0 + Vector2(0.0, -4.0)
	for index in range(5):
		var strand_t: float = float(index) / 4.0
		var side_offset: Vector2 = side * lerpf(-11.0, 13.0, strand_t)
		var start: Vector2 = hair_root + side_offset * 0.28 + Vector2(0.0, strand_t * 2.4)
		var strand: PackedVector2Array = _cloth_curve_points(
			pose,
			start,
			24.0 + strand_t * 7.0,
			30.0 + strand_t * 15.0,
			3.6 + strand_t * 2.6,
			float(index) * 1.47,
			side_offset.x * (0.38 + wind_unit * 0.18),
			9
		)
		_draw_ink_strand(strand, 5.6 - float(index % 2) * 0.8, HAIR_SOFT)
		_draw_ink_strand(strand, 3.2 - float(index % 2) * 0.4, HAIR)
	var bun_center := head_center - h * 16.0 + Vector2(0.0, -9.0)
	draw_circle(bun_center, 9.0, OUTLINE)
	draw_circle(bun_center, 6.5, HAIR)
	draw_arc(bun_center, 8.0, PI * 0.18, PI * 1.84, 18, INK_EDGE, 1.2, true)
	var top_ribbon: PackedVector2Array = _cloth_curve_points(
		pose,
		bun_center + Vector2(0.0, -4.0),
		14.0,
		26.0,
		2.8,
		4.8,
		side.x * 4.0,
		8
	)
	_draw_cloth_band(top_ribbon, 3.0, 0.8, Color(0.055, 0.058, 0.058, 0.42), Color(0.0, 0.0, 0.0, 0.32), Color(0.84, 0.88, 0.80, 0.22))
	for side_sign in [-1.0, 1.0]:
		var side_sign_value := float(side_sign)
		var ribbon_root: Vector2 = shoulder_center + side * side_sign_value * 5.0
		var ribbon: PackedVector2Array = _cloth_curve_points(
			pose,
			ribbon_root,
			20.0,
			40.0,
			4.2,
			side_sign_value * 2.1,
			side_sign_value * (5.2 + wind_power * 1.8),
			9
		)
		_draw_cloth_band(ribbon, 3.2, 0.9, Color(0.030, 0.032, 0.034, 0.40), Color(0.0, 0.0, 0.0, 0.30), Color(CLOTH_RIM.r, CLOTH_RIM.g, CLOTH_RIM.b, 0.20))
	var sash_anchor: Vector2 = hip_center + h * 4.0
	for side_sign in [-1.0, 1.0]:
		var side_sign_value := float(side_sign)
		var sash_root: Vector2 = sash_anchor + side * side_sign_value * 5.0
		var sash: PackedVector2Array = _cloth_curve_points(
			pose,
			sash_root,
			24.0,
			44.0,
			4.8,
			6.0 + side_sign_value,
			side_sign_value * (7.0 + wind_power * 2.0),
			10
		)
		_draw_cloth_band(sash, 3.8, 1.0, Color(0.030, 0.032, 0.034, 0.42), Color(0.0, 0.0, 0.0, 0.30), Color(0.86, 0.88, 0.80, 0.20))


func _draw_ink_strand(points: PackedVector2Array, width: float, color: Color) -> void:
	if points.size() < 2:
		return
	_draw_tapered_polyline(points, color, width, maxf(width * 0.25, 0.45), true)
	var tip := points[points.size() - 1]
	draw_circle(tip, maxf(width * 0.25, 0.8), color)


func _cloth_curve_points(
		pose: Dictionary,
		root: Vector2,
		hover_drop: float,
		wind_drag: float,
		side_wave: float,
		phase: float,
		side_bias: float,
		steps: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_steps := maxi(steps, 2)
	var wind_power: float = _cloth_wind_power(pose)
	var wind_unit: float = clampf(wind_power, 0.0, 1.0)
	var wave_axis: Vector2 = _cloth_wave_axis(pose)
	var flow_dir: Vector2 = _cloth_direction(pose)
	var fall: Vector2 = Vector2.DOWN * lerpf(hover_drop, hover_drop * 0.22, wind_unit)
	var drag: Vector2 = flow_dir * wind_drag * wind_power * 0.58
	var flow: Vector2 = fall + drag
	var wave_rate: float = lerpf(1.20, 3.65, wind_unit)
	for i in range(safe_steps + 1):
		var t: float = float(i) / float(safe_steps)
		var stiffness: float = t * t
		var lag_phase: float = phase + _time * wave_rate - t * (1.65 + wind_unit * 1.15)
		var wave: Vector2 = wave_axis * sin(lag_phase) * side_wave * stiffness * (0.34 + wind_power * 0.72 + _cloth_turn * 0.24)
		var bias: Vector2 = wave_axis * side_bias * stiffness
		var settle: Vector2 = Vector2.DOWN * sin(_time * 1.05 + phase + t * 1.8) * 1.4 * t * (1.0 - wind_unit)
		points.append(root + flow * t + wave + bias + settle)
	return points


func _draw_cloth_band(points: PackedVector2Array, start_width: float, end_width: float, fill: Color, rim: Color, highlight: Color) -> void:
	if points.size() < 2:
		return
	_draw_tapered_polyline(points, rim, start_width + 1.3, maxf(end_width + 0.8, 0.9), true)
	_draw_tapered_polyline(points, fill, start_width, end_width, true)
	if highlight.a > 0.001:
		_draw_tapered_polyline(points, highlight, maxf(start_width * 0.28, 0.9), maxf(end_width * 0.30, 0.35), true)
	var tip := points[points.size() - 1]
	draw_circle(tip, maxf(end_width * 0.65, 0.75), rim)


func _draw_cloth_panel(
		root_center: Vector2,
		flow: Vector2,
		side: Vector2,
		lane_offset: float,
		root_width: float,
		mid_width: float,
		tip_width: float,
		phase: float,
		fill: Color,
		rim: Color
) -> void:
	var wind_unit: float = clampf(_cloth_wind, 0.0, 1.0)
	var wave_rate: float = lerpf(1.25, 3.25, wind_unit)
	var panel_axis := _panel_wave_axis(flow, side)
	var lane: Vector2 = panel_axis * lane_offset
	var mid_wave: Vector2 = panel_axis * sin(_time * wave_rate + phase - 0.75) * (1.8 + _cloth_wind * 2.4 + _cloth_turn * 1.4)
	var tip_wave: Vector2 = panel_axis * sin(_time * wave_rate + phase - 1.75) * (3.0 + _cloth_wind * 3.8 + _cloth_turn * 2.0)
	var c0: Vector2 = root_center + lane * 0.30
	var c1: Vector2 = root_center + flow * 0.56 + lane * 0.92 + mid_wave
	var c2: Vector2 = root_center + flow * 1.08 + lane * 1.34 + tip_wave
	var p0l: Vector2 = c0 - panel_axis * root_width
	var p0r: Vector2 = c0 + panel_axis * root_width
	var p1l: Vector2 = c1 - panel_axis * mid_width
	var p1r: Vector2 = c1 + panel_axis * mid_width
	var p2l: Vector2 = c2 - panel_axis * tip_width
	var p2r: Vector2 = c2 + panel_axis * tip_width
	_draw_quad_safe(p0l, p0r, p1r, p1l, fill)
	_draw_quad_safe(p1l, p1r, p2r, p2l, fill)
	var outline := PackedVector2Array([p0l, p0r, p1r, p2r, p2l, p1l])
	var widest := maxf(maxf(root_width, mid_width), tip_width)
	var outline_width := clampf(widest * 0.22 + 1.0, 1.5, 3.0)
	_draw_closed_polyline(outline, OUTLINE, outline_width)
	draw_line(p0l.lerp(p0r, 0.62), p2l.lerp(p2r, 0.62), rim, clampf(widest * 0.22, 0.7, 1.8), true)
	draw_line(c0, c2, Color(CLOTH_WASH.r, CLOTH_WASH.g, CLOTH_WASH.b, CLOTH_WASH.a * fill.a), clampf(widest * 0.20, 0.8, 1.8), true)


func _panel_wave_axis(flow: Vector2, fallback_side: Vector2) -> Vector2:
	if flow.length_squared() > 0.0001:
		var axis := flow.normalized().rotated(PI * 0.5)
		if axis.y < 0.0:
			axis = -axis
		return axis
	if fallback_side.length_squared() > 0.0001:
		return fallback_side.normalized()
	return Vector2.RIGHT


func _draw_head(pose: Dictionary) -> void:
	var head_center: Vector2 = pose["head_center"]
	var h: Vector2 = pose["heading"]
	var side: Vector2 = pose["side"]
	var head_scale: float = pose.get("head_scale", 1.0)
	var radius := (17.0 + absf(h.y) * 3.0) * head_scale
	draw_circle(head_center, radius + 2.5, OUTLINE)
	draw_circle(head_center, radius, HEAD)
	draw_arc(head_center - h * 4.0 * head_scale, radius * 0.82, PI * 0.05, PI * 1.55, 22, HAIR_SOFT, 3.0 * head_scale, true)
	var frontness: float = pose["frontness"]
	if frontness > 0.42:
		draw_line(head_center - side * 8.0 * head_scale - h * 3.0 * head_scale, head_center + side * 8.0 * head_scale - h * 3.0 * head_scale, INK_EDGE, 1.8 * head_scale, true)
		draw_circle(head_center - h * 2.0 * head_scale, 2.0 * head_scale, OUTLINE)
		draw_circle(head_center - h * 2.0 * head_scale, 1.2 * head_scale, JADE)
	elif frontness < -0.42:
		draw_line(head_center - side * 8.0 * head_scale + h * 2.0 * head_scale, head_center + side * 8.0 * head_scale + h * 2.0 * head_scale, INK_EDGE, 1.8 * head_scale, true)
		draw_circle(head_center - h * 5.0 * head_scale, 1.8 * head_scale, HAIR_SOFT)
	else:
		draw_line(head_center - h * 2.0 * head_scale - side * 5.5 * head_scale, head_center - h * 2.0 * head_scale + side * 4.5 * head_scale, INK_EDGE, 1.6 * head_scale, true)
		draw_circle(head_center + h * 7.5 * head_scale, 2.0 * head_scale, Color(0.0, 0.0, 0.0, 0.42))
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
	if not _editor_active and not SHOW_JOINTS_IN_GAME:
		return
	for key in EDIT_JOINT_KEYS:
		var point: Vector2 = pose[key]
		var selected: bool = _editor_active and String(key) == _editor_selected_joint
		draw_circle(point, 7.0 if selected else 4.0, OUTLINE)
		draw_circle(point, 4.4 if selected else 2.6, Color(1.0, 0.92, 0.34, 1.0) if selected else JOINT)
	if _editor_active:
		var selected_point: Vector2 = pose[_editor_selected_joint]
		draw_arc(selected_point, 12.0, 0.0, TAU, 28, Color(0.45, 1.0, 1.0, 0.72), 1.8, true)


func _update_cloth_motion_state(delta: float) -> void:
	var safe_delta := maxf(delta, 0.0)
	var speed_ratio := clampf(_velocity.length() / FLIGHT_SPEED_POSE_REFERENCE, 0.0, 1.35)
	var wind_target := clampf(speed_ratio * 0.44 + _boost * 0.20 + _carve * 0.14 + _throttle * 0.08, 0.0, 0.95)
	_cloth_wind = _damp_float(_cloth_wind, wind_target, 0.22, safe_delta)
	_cloth_turn = _damp_float(_cloth_turn, maxf(_turn, _carve * 0.55), 0.18, safe_delta)
	var target_flow := _target_cloth_flow_direction(_heading, _velocity, wind_target)
	_cloth_flow_dir = _damp_vector2(_cloth_flow_dir, target_flow, 0.24, safe_delta)
	if _cloth_flow_dir.length_squared() <= 0.0001:
		_cloth_flow_dir = Vector2.DOWN
	else:
		_cloth_flow_dir = _cloth_flow_dir.normalized()


func _update_idle_recover_energy(delta: float) -> void:
	var safe_delta := maxf(delta, 0.0)
	var action_pressure := clampf(maxf(maxf(_boost, _turn), maxf(_carve, _throttle * 0.72)), 0.0, 1.0)
	var release_pressure := _idle_previous_action_pressure - action_pressure
	if release_pressure > 0.10:
		_idle_recover_energy = maxf(_idle_recover_energy, clampf(release_pressure * 1.25, 0.0, 1.0))
	_idle_previous_action_pressure = _damp_float(_idle_previous_action_pressure, action_pressure, 0.07, safe_delta)
	_idle_recover_energy = _damp_float(_idle_recover_energy, 0.0, 0.24, safe_delta)


func _target_cloth_flow_direction(heading: Vector2, velocity: Vector2, wind_power: float) -> Vector2:
	var safe_heading := heading.normalized() if heading.length_squared() > 0.0001 else _direction_vector(_direction_index)
	var velocity_dir := velocity.normalized() if velocity.length_squared() > 1.0 else safe_heading
	var wind_weight := clampf(wind_power * 0.72, 0.0, 0.72)
	var target := Vector2.DOWN.lerp(-velocity_dir, wind_weight)
	if velocity.length_squared() > 1.0:
		var slip_sign := clampf(velocity_dir.cross(safe_heading), -1.0, 1.0)
		target += safe_heading.rotated(PI * 0.5) * slip_sign * _cloth_turn * 0.18
	if target.length_squared() <= 0.0001:
		return Vector2.DOWN
	return target.normalized()


func _cloth_wind_power(pose: Dictionary) -> float:
	var pose_wind := clampf(float(pose.get("wind", 0.0)), 0.0, 1.6)
	if _editor_active:
		return pose_wind
	return clampf(maxf(_cloth_wind, pose_wind * 0.42), 0.0, 0.95)


func _cloth_direction(pose: Dictionary) -> Vector2:
	if _editor_active:
		var h: Vector2 = pose["heading"]
		var safe_heading := h.normalized() if h.length_squared() > 0.0001 else Vector2.RIGHT
		var editor_flow := Vector2.DOWN.lerp(-safe_heading, clampf(_cloth_wind_power(pose), 0.0, 1.0))
		return editor_flow.normalized() if editor_flow.length_squared() > 0.0001 else Vector2.DOWN
	if _cloth_flow_dir.length_squared() <= 0.0001:
		return Vector2.DOWN
	return _cloth_flow_dir.normalized()


func _cloth_wave_axis(pose: Dictionary) -> Vector2:
	var flow_dir := _cloth_direction(pose)
	if flow_dir.length_squared() > 0.0001:
		var axis := flow_dir.normalized().rotated(PI * 0.5)
		if axis.y < 0.0:
			axis = -axis
		if absf(axis.y) < 0.18 and absf(flow_dir.x) > 0.72:
			axis = Vector2.DOWN
		return axis.normalized()
	var side: Vector2 = pose["side"]
	return side.normalized() if side.length_squared() > 0.0001 else Vector2.RIGHT


func _cloth_motion_vector(pose: Dictionary, hover_drop: float, wind_drag: float, side_wave: float, phase: float) -> Vector2:
	var wind_power := _cloth_wind_power(pose)
	var wind_unit := clampf(wind_power, 0.0, 1.0)
	var wave_axis: Vector2 = _cloth_wave_axis(pose)
	var wave_rate := lerpf(1.12, 3.45, wind_unit)
	var wave_amount := side_wave * (0.20 + wind_power * 0.82 + _cloth_turn * 0.25)
	var fall := Vector2.DOWN * lerpf(hover_drop, hover_drop * 0.28, wind_unit)
	var drag := _cloth_direction(pose) * wind_drag * wind_power * 0.58
	var wave := wave_axis * sin(_time * wave_rate + phase) * wave_amount
	return fall + drag + wave


func _damp_float(current: float, target: float, half_life: float, delta: float) -> float:
	if delta <= 0.0 or half_life <= 0.0001:
		return target if half_life <= 0.0001 else current
	var keep := pow(0.5, delta / half_life)
	return lerpf(target, current, keep)


func _damp_vector2(current: Vector2, target: Vector2, half_life: float, delta: float) -> Vector2:
	if delta <= 0.0:
		return current
	if half_life <= 0.0001:
		return target
	var keep := pow(0.5, delta / half_life)
	return target.lerp(current, keep)


func _quadratic_points(a: Vector2, b: Vector2, c: Vector2, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_steps := maxi(steps, 2)
	for i in range(safe_steps + 1):
		var t := float(i) / float(safe_steps)
		var inv := 1.0 - t
		points.append(a * inv * inv + b * 2.0 * inv * t + c * t * t)
	return points


func _draw_tapered_polyline(points: PackedVector2Array, color: Color, start_width: float, end_width: float, antialiased := true) -> void:
	if points.size() < 2 or color.a <= 0.001:
		return
	var segment_count := points.size() - 1
	for i in range(segment_count):
		var t := float(i) / maxf(float(segment_count - 1), 1.0)
		var width := lerpf(start_width, end_width, t)
		draw_line(points[i], points[i + 1], color, width, antialiased)


func _draw_triangle_safe(a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	if color.a <= 0.001:
		return
	var area := absf((b - a).cross(c - a))
	if area <= 0.001:
		return
	draw_colored_polygon(PackedVector2Array([a, b, c]), color)


func _draw_quad_safe(a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> void:
	_draw_triangle_safe(a, b, c, color)
	_draw_triangle_safe(a, c, d, color)


func _draw_closed_polyline(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 2 or color.a <= 0.001 or width <= 0.0:
		return
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, color, width, true)


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


func _toggle_hair_fx_panel() -> void:
	if _hair_fx_panel == null:
		return
	_hair_fx_panel.visible = not _hair_fx_panel.visible
	if _hair_fx_panel.visible:
		_refresh_hair_fx_controls()
	queue_redraw()


func _create_hair_fx_panel() -> void:
	if _editor_layer == null:
		_editor_layer = CanvasLayer.new()
		_editor_layer.name = "V4SkeletonPoseEditorLayer"
		_editor_layer.layer = 92
		add_child(_editor_layer)

	_hair_fx_panel = PanelContainer.new()
	_hair_fx_panel.name = "V4HairFxTuningPanel"
	_hair_fx_panel.position = Vector2(430.0, 92.0)
	_hair_fx_panel.custom_minimum_size = Vector2(470.0, 0.0)
	_hair_fx_panel.visible = false
	_editor_layer.add_child(_hair_fx_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	_hair_fx_panel.add_child(root)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	root.add_child(title_row)

	var title := Label.new()
	title.text = "头发 FX 调参  F5"
	title.add_theme_font_size_override("font_size", 17)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.pressed.connect(Callable(self, "_on_hair_fx_close_pressed"))
	title_row.add_child(close_button)

	_hair_fx_enabled_check = CheckBox.new()
	_hair_fx_enabled_check.text = "启用头发 FX"
	_hair_fx_enabled_check.toggled.connect(Callable(self, "_on_hair_fx_enabled_toggled"))
	root.add_child(_hair_fx_enabled_check)

	_hair_fx_debug_check = CheckBox.new()
	_hair_fx_debug_check.text = "显示 Groom 诊断"
	_hair_fx_debug_check.toggled.connect(Callable(self, "_on_hair_fx_debug_toggled"))
	root.add_child(_hair_fx_debug_check)

	_hair_fx_back_strands_slider = _make_hair_fx_slider(1.0, 48.0, 1.0)
	_hair_fx_back_strands_slider.value_changed.connect(Callable(self, "_on_hair_fx_back_strands_changed"))
	_hair_fx_back_strands_spin = _make_hair_fx_spin(1.0)
	_hair_fx_back_strands_spin.value_changed.connect(Callable(self, "_on_hair_fx_back_strands_changed"))
	root.add_child(_make_hair_fx_slider_row("后发量", _hair_fx_back_strands_slider, _hair_fx_back_strands_spin))

	_hair_fx_front_strands_slider = _make_hair_fx_slider(1.0, 32.0, 1.0)
	_hair_fx_front_strands_slider.value_changed.connect(Callable(self, "_on_hair_fx_front_strands_changed"))
	_hair_fx_front_strands_spin = _make_hair_fx_spin(1.0)
	_hair_fx_front_strands_spin.value_changed.connect(Callable(self, "_on_hair_fx_front_strands_changed"))
	root.add_child(_make_hair_fx_slider_row("前发量", _hair_fx_front_strands_slider, _hair_fx_front_strands_spin))

	_hair_fx_width_slider = _make_hair_fx_slider(0.0, 2.0, 0.01)
	_hair_fx_width_slider.value_changed.connect(Callable(self, "_on_hair_fx_width_changed"))
	_hair_fx_width_spin = _make_hair_fx_spin(0.01)
	_hair_fx_width_spin.value_changed.connect(Callable(self, "_on_hair_fx_width_changed"))
	root.add_child(_make_hair_fx_slider_row("发丝宽", _hair_fx_width_slider, _hair_fx_width_spin))

	_hair_fx_length_slider = _make_hair_fx_slider(0.0, 3.0, 0.01)
	_hair_fx_length_slider.value_changed.connect(Callable(self, "_on_hair_fx_length_changed"))
	_hair_fx_length_spin = _make_hair_fx_spin(0.01)
	_hair_fx_length_spin.value_changed.connect(Callable(self, "_on_hair_fx_length_changed"))
	root.add_child(_make_hair_fx_slider_row("长度", _hair_fx_length_slider, _hair_fx_length_spin))

	_hair_fx_opacity_slider = _make_hair_fx_slider(0.0, 3.0, 0.01)
	_hair_fx_opacity_slider.value_changed.connect(Callable(self, "_on_hair_fx_opacity_changed"))
	_hair_fx_opacity_spin = _make_hair_fx_spin(0.01)
	_hair_fx_opacity_spin.value_changed.connect(Callable(self, "_on_hair_fx_opacity_changed"))
	root.add_child(_make_hair_fx_slider_row("透明度", _hair_fx_opacity_slider, _hair_fx_opacity_spin))

	_hair_fx_spread_slider = _make_hair_fx_slider(0.0, 3.0, 0.01)
	_hair_fx_spread_slider.value_changed.connect(Callable(self, "_on_hair_fx_spread_changed"))
	_hair_fx_spread_spin = _make_hair_fx_spin(0.01)
	_hair_fx_spread_spin.value_changed.connect(Callable(self, "_on_hair_fx_spread_changed"))
	root.add_child(_make_hair_fx_slider_row("散开", _hair_fx_spread_slider, _hair_fx_spread_spin))

	_hair_fx_hover_drop_slider = _make_hair_fx_slider(0.0, 3.0, 0.01)
	_hair_fx_hover_drop_slider.value_changed.connect(Callable(self, "_on_hair_fx_hover_drop_changed"))
	_hair_fx_hover_drop_spin = _make_hair_fx_spin(0.01)
	_hair_fx_hover_drop_spin.value_changed.connect(Callable(self, "_on_hair_fx_hover_drop_changed"))
	root.add_child(_make_hair_fx_slider_row("悬停垂坠", _hair_fx_hover_drop_slider, _hair_fx_hover_drop_spin))

	_hair_fx_sway_slider = _make_hair_fx_slider(0.0, 3.0, 0.01)
	_hair_fx_sway_slider.value_changed.connect(Callable(self, "_on_hair_fx_sway_changed"))
	_hair_fx_sway_spin = _make_hair_fx_spin(0.01)
	_hair_fx_sway_spin.value_changed.connect(Callable(self, "_on_hair_fx_sway_changed"))
	root.add_child(_make_hair_fx_slider_row("风摆", _hair_fx_sway_slider, _hair_fx_sway_spin))

	_hair_fx_turn_lag_slider = _make_hair_fx_slider(0.0, 3.0, 0.01)
	_hair_fx_turn_lag_slider.value_changed.connect(Callable(self, "_on_hair_fx_turn_lag_changed"))
	_hair_fx_turn_lag_spin = _make_hair_fx_spin(0.01)
	_hair_fx_turn_lag_spin.value_changed.connect(Callable(self, "_on_hair_fx_turn_lag_changed"))
	root.add_child(_make_hair_fx_slider_row("转向滞后", _hair_fx_turn_lag_slider, _hair_fx_turn_lag_spin))

	_hair_fx_front_cover_slider = _make_hair_fx_slider(0.0, 3.0, 0.01)
	_hair_fx_front_cover_slider.value_changed.connect(Callable(self, "_on_hair_fx_front_cover_changed"))
	_hair_fx_front_cover_spin = _make_hair_fx_spin(0.01)
	_hair_fx_front_cover_spin.value_changed.connect(Callable(self, "_on_hair_fx_front_cover_changed"))
	root.add_child(_make_hair_fx_slider_row("上向盖头", _hair_fx_front_cover_slider, _hair_fx_front_cover_spin))

	_hair_fx_volume_slider = _make_hair_fx_slider(0.0, 3.0, 0.01)
	_hair_fx_volume_slider.value_changed.connect(Callable(self, "_on_hair_fx_volume_changed"))
	_hair_fx_volume_spin = _make_hair_fx_spin(0.01)
	_hair_fx_volume_spin.value_changed.connect(Callable(self, "_on_hair_fx_volume_changed"))
	root.add_child(_make_hair_fx_slider_row("发型体积", _hair_fx_volume_slider, _hair_fx_volume_spin))

	_hair_fx_root_ink_slider = _make_hair_fx_slider(0.0, 3.0, 0.01)
	_hair_fx_root_ink_slider.value_changed.connect(Callable(self, "_on_hair_fx_root_ink_changed"))
	_hair_fx_root_ink_spin = _make_hair_fx_spin(0.01)
	_hair_fx_root_ink_spin.value_changed.connect(Callable(self, "_on_hair_fx_root_ink_changed"))
	root.add_child(_make_hair_fx_slider_row("发根墨量", _hair_fx_root_ink_slider, _hair_fx_root_ink_spin))

	_hair_fx_highlight_slider = _make_hair_fx_slider(0.0, 3.0, 0.01)
	_hair_fx_highlight_slider.value_changed.connect(Callable(self, "_on_hair_fx_highlight_changed"))
	_hair_fx_highlight_spin = _make_hair_fx_spin(0.01)
	_hair_fx_highlight_spin.value_changed.connect(Callable(self, "_on_hair_fx_highlight_changed"))
	root.add_child(_make_hair_fx_slider_row("高光层次", _hair_fx_highlight_slider, _hair_fx_highlight_spin))

	_hair_fx_physics_slider = _make_hair_fx_slider(0.0, 3.0, 0.01)
	_hair_fx_physics_slider.value_changed.connect(Callable(self, "_on_hair_fx_physics_changed"))
	_hair_fx_physics_spin = _make_hair_fx_spin(0.01)
	_hair_fx_physics_spin.value_changed.connect(Callable(self, "_on_hair_fx_physics_changed"))
	root.add_child(_make_hair_fx_slider_row("物理强度", _hair_fx_physics_slider, _hair_fx_physics_spin))

	_hair_fx_layer_depth_slider = _make_hair_fx_slider(0.0, 3.0, 0.01)
	_hair_fx_layer_depth_slider.value_changed.connect(Callable(self, "_on_hair_fx_layer_depth_changed"))
	_hair_fx_layer_depth_spin = _make_hair_fx_spin(0.01)
	_hair_fx_layer_depth_spin.value_changed.connect(Callable(self, "_on_hair_fx_layer_depth_changed"))
	root.add_child(_make_hair_fx_slider_row("遮挡层次", _hair_fx_layer_depth_slider, _hair_fx_layer_depth_spin))

	_hair_fx_material_depth_slider = _make_hair_fx_slider(0.0, 3.0, 0.01)
	_hair_fx_material_depth_slider.value_changed.connect(Callable(self, "_on_hair_fx_material_depth_changed"))
	_hair_fx_material_depth_spin = _make_hair_fx_spin(0.01)
	_hair_fx_material_depth_spin.value_changed.connect(Callable(self, "_on_hair_fx_material_depth_changed"))
	root.add_child(_make_hair_fx_slider_row("材质层次", _hair_fx_material_depth_slider, _hair_fx_material_depth_spin))

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 6)
	root.add_child(button_row)

	var reset_button := Button.new()
	reset_button.text = "重置"
	reset_button.pressed.connect(Callable(self, "_on_hair_fx_reset_pressed"))
	button_row.add_child(reset_button)

	var copy_button := Button.new()
	copy_button.text = "复制参数"
	copy_button.pressed.connect(Callable(self, "_on_hair_fx_copy_pressed"))
	button_row.add_child(copy_button)

	_hair_fx_status_label = Label.new()
	_hair_fx_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hair_fx_status_label.add_theme_font_size_override("font_size", 12)
	root.add_child(_hair_fx_status_label)
	_refresh_hair_fx_controls()


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


func _make_hair_fx_slider(min_value: float, max_value: float, step: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return slider


func _make_hair_fx_spin(step: float) -> SpinBox:
	var spin := _make_editor_spin(-1000000.0, 1000000.0, step)
	spin.custom_minimum_size = Vector2(82.0, 0.0)
	return spin


func _make_hair_fx_slider_row(label_text: String, slider: HSlider, spin: SpinBox) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(74.0, 0.0)
	row.add_child(label)
	row.add_child(slider)
	row.add_child(spin)
	return row


func _sync_hair_fx_pair(slider: HSlider, spin: SpinBox, value: float) -> void:
	if slider == null or spin == null:
		return
	_hair_fx_updating_controls = true
	_expand_slider_to_value(slider, value)
	slider.value = value
	spin.value = value
	_hair_fx_updating_controls = false


func _expand_slider_to_value(slider: HSlider, value: float) -> void:
	if value < slider.min_value:
		var span := maxf(slider.max_value - slider.min_value, slider.step * 8.0)
		slider.min_value = value - span * 0.25
	if value > slider.max_value:
		var span := maxf(slider.max_value - slider.min_value, slider.step * 8.0)
		slider.max_value = value + span * 0.25


func _refresh_hair_fx_controls() -> void:
	if _hair_fx_enabled_check == null:
		return
	_hair_fx_updating_controls = true
	_hair_fx_enabled_check.button_pressed = hair_fx_enabled
	if _hair_fx_debug_check != null:
		_hair_fx_debug_check.button_pressed = hair_fx_debug_overlay
	_hair_fx_updating_controls = false
	_sync_hair_fx_pair(_hair_fx_back_strands_slider, _hair_fx_back_strands_spin, float(hair_fx_back_strands))
	_sync_hair_fx_pair(_hair_fx_front_strands_slider, _hair_fx_front_strands_spin, float(hair_fx_front_strands))
	_sync_hair_fx_pair(_hair_fx_width_slider, _hair_fx_width_spin, hair_fx_width)
	_sync_hair_fx_pair(_hair_fx_length_slider, _hair_fx_length_spin, hair_fx_length)
	_sync_hair_fx_pair(_hair_fx_opacity_slider, _hair_fx_opacity_spin, hair_fx_opacity)
	_sync_hair_fx_pair(_hair_fx_spread_slider, _hair_fx_spread_spin, hair_fx_spread)
	_sync_hair_fx_pair(_hair_fx_hover_drop_slider, _hair_fx_hover_drop_spin, hair_fx_hover_drop)
	_sync_hair_fx_pair(_hair_fx_sway_slider, _hair_fx_sway_spin, hair_fx_sway)
	_sync_hair_fx_pair(_hair_fx_turn_lag_slider, _hair_fx_turn_lag_spin, hair_fx_turn_lag)
	_sync_hair_fx_pair(_hair_fx_front_cover_slider, _hair_fx_front_cover_spin, hair_fx_front_cover)
	_sync_hair_fx_pair(_hair_fx_volume_slider, _hair_fx_volume_spin, hair_fx_volume)
	_sync_hair_fx_pair(_hair_fx_root_ink_slider, _hair_fx_root_ink_spin, hair_fx_root_ink)
	_sync_hair_fx_pair(_hair_fx_highlight_slider, _hair_fx_highlight_spin, hair_fx_highlight)
	_sync_hair_fx_pair(_hair_fx_physics_slider, _hair_fx_physics_spin, hair_fx_physics)
	_sync_hair_fx_pair(_hair_fx_layer_depth_slider, _hair_fx_layer_depth_spin, hair_fx_layer_depth)
	_sync_hair_fx_pair(_hair_fx_material_depth_slider, _hair_fx_material_depth_spin, hair_fx_material_depth)


func _set_hair_fx_status(text: String) -> void:
	if _hair_fx_status_label != null:
		_hair_fx_status_label.text = text


func _commit_hair_fx_change() -> void:
	_hair_groom_chains.clear()
	_save_hair_fx_tuning()
	queue_redraw()


func _on_hair_fx_close_pressed() -> void:
	if _hair_fx_panel != null:
		_hair_fx_panel.visible = false


func _on_hair_fx_enabled_toggled(value: bool) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_enabled = value
	_commit_hair_fx_change()


func _on_hair_fx_debug_toggled(value: bool) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_debug_overlay = value
	_set_hair_fx_status("Groom 诊断显示已%s" % ("开启" if hair_fx_debug_overlay else "关闭"))
	_save_hair_fx_tuning()
	queue_redraw()


func _on_hair_fx_back_strands_changed(value: float) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_back_strands = int(roundf(value))
	_sync_hair_fx_pair(_hair_fx_back_strands_slider, _hair_fx_back_strands_spin, float(hair_fx_back_strands))
	_commit_hair_fx_change()


func _on_hair_fx_front_strands_changed(value: float) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_front_strands = int(roundf(value))
	_sync_hair_fx_pair(_hair_fx_front_strands_slider, _hair_fx_front_strands_spin, float(hair_fx_front_strands))
	_commit_hair_fx_change()


func _on_hair_fx_width_changed(value: float) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_width = value
	_sync_hair_fx_pair(_hair_fx_width_slider, _hair_fx_width_spin, hair_fx_width)
	_commit_hair_fx_change()


func _on_hair_fx_length_changed(value: float) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_length = value
	_sync_hair_fx_pair(_hair_fx_length_slider, _hair_fx_length_spin, hair_fx_length)
	_commit_hair_fx_change()


func _on_hair_fx_opacity_changed(value: float) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_opacity = value
	_sync_hair_fx_pair(_hair_fx_opacity_slider, _hair_fx_opacity_spin, hair_fx_opacity)
	_commit_hair_fx_change()


func _on_hair_fx_spread_changed(value: float) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_spread = value
	_sync_hair_fx_pair(_hair_fx_spread_slider, _hair_fx_spread_spin, hair_fx_spread)
	_commit_hair_fx_change()


func _on_hair_fx_hover_drop_changed(value: float) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_hover_drop = value
	_sync_hair_fx_pair(_hair_fx_hover_drop_slider, _hair_fx_hover_drop_spin, hair_fx_hover_drop)
	_commit_hair_fx_change()


func _on_hair_fx_sway_changed(value: float) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_sway = value
	_sync_hair_fx_pair(_hair_fx_sway_slider, _hair_fx_sway_spin, hair_fx_sway)
	_commit_hair_fx_change()


func _on_hair_fx_turn_lag_changed(value: float) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_turn_lag = value
	_sync_hair_fx_pair(_hair_fx_turn_lag_slider, _hair_fx_turn_lag_spin, hair_fx_turn_lag)
	_commit_hair_fx_change()


func _on_hair_fx_front_cover_changed(value: float) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_front_cover = value
	_sync_hair_fx_pair(_hair_fx_front_cover_slider, _hair_fx_front_cover_spin, hair_fx_front_cover)
	_commit_hair_fx_change()


func _on_hair_fx_volume_changed(value: float) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_volume = value
	_sync_hair_fx_pair(_hair_fx_volume_slider, _hair_fx_volume_spin, hair_fx_volume)
	_commit_hair_fx_change()


func _on_hair_fx_root_ink_changed(value: float) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_root_ink = value
	_sync_hair_fx_pair(_hair_fx_root_ink_slider, _hair_fx_root_ink_spin, hair_fx_root_ink)
	_commit_hair_fx_change()


func _on_hair_fx_highlight_changed(value: float) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_highlight = value
	_sync_hair_fx_pair(_hair_fx_highlight_slider, _hair_fx_highlight_spin, hair_fx_highlight)
	_commit_hair_fx_change()


func _on_hair_fx_physics_changed(value: float) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_physics = value
	_sync_hair_fx_pair(_hair_fx_physics_slider, _hair_fx_physics_spin, hair_fx_physics)
	_commit_hair_fx_change()


func _on_hair_fx_layer_depth_changed(value: float) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_layer_depth = value
	_sync_hair_fx_pair(_hair_fx_layer_depth_slider, _hair_fx_layer_depth_spin, hair_fx_layer_depth)
	_commit_hair_fx_change()


func _on_hair_fx_material_depth_changed(value: float) -> void:
	if _hair_fx_updating_controls:
		return
	hair_fx_material_depth = value
	_sync_hair_fx_pair(_hair_fx_material_depth_slider, _hair_fx_material_depth_spin, hair_fx_material_depth)
	_commit_hair_fx_change()


func _on_hair_fx_reset_pressed() -> void:
	hair_fx_enabled = true
	hair_fx_back_strands = 15
	hair_fx_front_strands = 0
	hair_fx_width = 0.50
	hair_fx_length = 1.00
	hair_fx_opacity = 1.00
	hair_fx_spread = 3.00
	hair_fx_hover_drop = 3.00
	hair_fx_sway = 3.00
	hair_fx_turn_lag = 3.00
	hair_fx_front_cover = 0.00
	hair_fx_volume = 1.00
	hair_fx_root_ink = 1.00
	hair_fx_highlight = 1.00
	hair_fx_physics = 1.00
	hair_fx_layer_depth = 1.00
	hair_fx_material_depth = 1.00
	hair_fx_debug_overlay = false
	_refresh_hair_fx_controls()
	_save_hair_fx_tuning(true)
	_set_hair_fx_status("已重置头发 FX 参数")
	queue_redraw()


func _on_hair_fx_copy_pressed() -> void:
	var text := "\n".join([
		"hair_fx_enabled = %s" % str(hair_fx_enabled).to_lower(),
		"hair_fx_back_strands = %d" % hair_fx_back_strands,
		"hair_fx_front_strands = %d" % hair_fx_front_strands,
		"hair_fx_width = %.2f" % hair_fx_width,
		"hair_fx_length = %.2f" % hair_fx_length,
		"hair_fx_opacity = %.2f" % hair_fx_opacity,
		"hair_fx_spread = %.2f" % hair_fx_spread,
		"hair_fx_hover_drop = %.2f" % hair_fx_hover_drop,
		"hair_fx_sway = %.2f" % hair_fx_sway,
		"hair_fx_turn_lag = %.2f" % hair_fx_turn_lag,
		"hair_fx_front_cover = %.2f" % hair_fx_front_cover,
		"hair_fx_volume = %.2f" % hair_fx_volume,
		"hair_fx_root_ink = %.2f" % hair_fx_root_ink,
		"hair_fx_highlight = %.2f" % hair_fx_highlight,
		"hair_fx_physics = %.2f" % hair_fx_physics,
		"hair_fx_layer_depth = %.2f" % hair_fx_layer_depth,
		"hair_fx_material_depth = %.2f" % hair_fx_material_depth,
		"hair_fx_debug_overlay = %s" % str(hair_fx_debug_overlay).to_lower(),
	])
	DisplayServer.clipboard_set(text)
	_set_hair_fx_status("已复制当前头发 FX 参数")


func _hair_fx_tuning_data() -> Dictionary:
	return {
		"format_version": 2,
		"hair_fx_enabled": hair_fx_enabled,
		"hair_fx_back_strands": hair_fx_back_strands,
		"hair_fx_front_strands": hair_fx_front_strands,
		"hair_fx_width": hair_fx_width,
		"hair_fx_length": hair_fx_length,
		"hair_fx_opacity": hair_fx_opacity,
		"hair_fx_spread": hair_fx_spread,
		"hair_fx_hover_drop": hair_fx_hover_drop,
		"hair_fx_sway": hair_fx_sway,
		"hair_fx_turn_lag": hair_fx_turn_lag,
		"hair_fx_front_cover": hair_fx_front_cover,
		"hair_fx_volume": hair_fx_volume,
		"hair_fx_root_ink": hair_fx_root_ink,
		"hair_fx_highlight": hair_fx_highlight,
		"hair_fx_physics": hair_fx_physics,
		"hair_fx_layer_depth": hair_fx_layer_depth,
		"hair_fx_material_depth": hair_fx_material_depth,
		"hair_fx_debug_overlay": hair_fx_debug_overlay,
	}


func _load_hair_fx_tuning() -> void:
	if not FileAccess.file_exists(HAIR_FX_TUNING_PATH):
		return
	var text := FileAccess.get_file_as_string(HAIR_FX_TUNING_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_warning("Invalid V4 hair FX tuning JSON: %s" % HAIR_FX_TUNING_PATH)
		return
	var data: Dictionary = parsed
	hair_fx_enabled = bool(data.get("hair_fx_enabled", hair_fx_enabled))
	hair_fx_back_strands = int(roundf(float(data.get("hair_fx_back_strands", hair_fx_back_strands))))
	hair_fx_front_strands = int(roundf(float(data.get("hair_fx_front_strands", hair_fx_front_strands))))
	hair_fx_width = float(data.get("hair_fx_width", hair_fx_width))
	hair_fx_length = float(data.get("hair_fx_length", hair_fx_length))
	hair_fx_opacity = float(data.get("hair_fx_opacity", hair_fx_opacity))
	hair_fx_spread = float(data.get("hair_fx_spread", hair_fx_spread))
	hair_fx_hover_drop = float(data.get("hair_fx_hover_drop", hair_fx_hover_drop))
	hair_fx_sway = float(data.get("hair_fx_sway", hair_fx_sway))
	hair_fx_turn_lag = float(data.get("hair_fx_turn_lag", hair_fx_turn_lag))
	hair_fx_front_cover = float(data.get("hair_fx_front_cover", hair_fx_front_cover))
	hair_fx_volume = float(data.get("hair_fx_volume", hair_fx_volume))
	hair_fx_root_ink = float(data.get("hair_fx_root_ink", hair_fx_root_ink))
	hair_fx_highlight = float(data.get("hair_fx_highlight", hair_fx_highlight))
	hair_fx_physics = float(data.get("hair_fx_physics", hair_fx_physics))
	hair_fx_layer_depth = float(data.get("hair_fx_layer_depth", hair_fx_layer_depth))
	hair_fx_material_depth = float(data.get("hair_fx_material_depth", hair_fx_material_depth))
	hair_fx_debug_overlay = bool(data.get("hair_fx_debug_overlay", hair_fx_debug_overlay))


func _save_hair_fx_tuning(show_status := false) -> void:
	var file := FileAccess.open(HAIR_FX_TUNING_PATH, FileAccess.WRITE)
	if file == null:
		var message := "头发 FX 参数保存失败: %s" % error_string(FileAccess.get_open_error())
		if show_status:
			_set_hair_fx_status(message)
		push_warning(message)
		return
	file.store_string(JSON.stringify(_hair_fx_tuning_data(), "\t"))
	if show_status:
		_set_hair_fx_status("已保存头发 FX 参数到 %s" % HAIR_FX_TUNING_PATH)


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
	if _editor_panel != null and _editor_panel.visible and _editor_panel.get_global_rect().has_point(screen_position):
		return true
	return _hair_fx_panel != null and _hair_fx_panel.visible and _hair_fx_panel.get_global_rect().has_point(screen_position)


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
