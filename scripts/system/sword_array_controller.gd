extends RefCounted
class_name SwordArrayController

const SwordArrayConfig = preload("res://scripts/system/sword_array_config.gd")
const CONVERGE_SAMPLE_RADIUS_RATIOS := [0.0, 0.14, 0.28, 0.44, 0.6, 0.76, 0.9, 1.0]
const CONVERGE_SAMPLE_ANGLE_RATIOS := [1.0, 0.94, 0.82, 0.66, 0.48, 0.3, 0.16, 0.08]
const SPEAR_SAMPLE_FORWARD_RATIOS := [0.0, 0.08, 0.18, 0.32, 0.5, 0.68, 0.86, 1.0]
const FAN_DOMINANT_SPEAR_PROGRESS_AT_FAN_END := 0.22
const FAN_PRECONVERGE_ARC_SCALE := 0.9
const FAN_PRECONVERGE_OUTER_SCALE := 1.03
const FAN_PRECONVERGE_INNER_SCALE := 0.96
const FAN_PRECONVERGE_PROGRESS_EXPONENT := 0.72
const FAN_PRECONVERGE_ANGLE_SCALES := [1.0, 0.99, 0.95, 0.88, 0.76, 0.58, 0.36, 0.18]
const FAN_PRECONVERGE_FORWARD_BONUS_SCALES := [0.0, 0.0, 0.02, 0.06, 0.12, 0.18, 0.26, 0.36]
const SPEAR_BULB_PHASE_END := 0.62
const SPEAR_BULB_FORWARD_BLEND_SCALES := [0.0, 0.06, 0.14, 0.28, 0.46, 0.66, 0.88, 1.0]
const SPEAR_BULB_FORWARD_BONUS_SCALES := [0.0, 0.01, 0.04, 0.1, 0.18, 0.28, 0.42, 0.5]
const SPEAR_BULB_WIDTH_TARGET_SCALES := [0.6, 0.74, 0.92, 1.0, 0.9, 0.66, 0.22, 0.0]
const SPEAR_BULB_FAN_WIDTH_LIMIT_SCALES := [0.48, 0.62, 0.74, 0.82, 0.72, 0.48, 0.18, 0.0]
const SPEAR_BULB_SECTION_BLEND_SCALES := [0.14, 0.26, 0.42, 0.62, 0.82, 0.96, 1.0, 1.0]
const SPEAR_BULB_EDGE_CURVE_RELEASE_START := 0.24
const SPEAR_BULB_EDGE_CURVE_MIN := 0.52
const SPEAR_SPINE_FOCUS_AT_BULB_END := 0.68
const SPEAR_TIP_FOCUS_START := 0.76
const BAND_PREVIEW_START_BEFORE_RING_FAN_END := 32.0
const BAND_ENTRY_BLEND_AFTER_RING_FAN_END := 18.0
const BAND_BULB_START_RATIO := 0.62
const BAND_COLLAPSE_START_RATIO := 0.62
const RING_FAN_POST_THRESHOLD_PLATEAU := 10.0
const RING_FAN_BLEND_BEFORE := 0.0
const RING_FAN_BLEND_AFTER := 22.0
const FAN_SPEAR_BLEND_BEFORE := 18.0
const FAN_SPEAR_BLEND_AFTER := 24.0


static func get_mode(main: Node) -> String:
	return get_morph_state(main)["dominant_mode"]


static func get_morph_state(main: Node) -> Dictionary:
	var aim_distance: float = main.player["pos"].distance_to(main.mouse_world)
	return SwordArrayConfig.get_morph_state_for_distance(aim_distance)


static func get_slot_position(main: Node, state_source, slot_index: int, slot_count: int, formation_ratio := 1.0) -> Vector2:
	var morph_state: Dictionary = _resolve_morph_state(main, state_source)
	var converging_preview: Dictionary = _get_active_fan_pierce_preview(main, morph_state, formation_ratio)
	if not converging_preview.is_empty():
		match converging_preview["type"]:
			SwordArrayConfig.MODE_FAN:
				return _get_fan_slot_position_from_preview(main, converging_preview, slot_index, slot_count)
			"spear":
				return _get_spear_slot_position_from_preview(main, converging_preview, slot_index, slot_count)
	var from_mode: String = morph_state["visual_from_mode"]
	var to_mode: String = morph_state["visual_to_mode"]
	if from_mode == to_mode:
		return _get_mode_slot_position(main, from_mode, slot_index, slot_count, formation_ratio)
	return _get_transition_slot_position(
		main,
		from_mode,
		to_mode,
		slot_index,
		slot_count,
		formation_ratio,
		morph_state["visual_blend"]
	)


static func get_fire_source_slot_index(
	main: Node,
	state_source,
	slot_count: int,
	fire_sequence_index := 0,
	volley_count := -1,
	burst_step := 0,
	total_count := -1
) -> int:
	var clamped_count: int = maxi(slot_count, 0)
	if clamped_count <= 0:
		return -1

	var morph_state: Dictionary = _resolve_morph_state(main, state_source)
	var fire_target: Vector2 = get_fire_target(
		main,
		morph_state,
		fire_sequence_index,
		main.player["pos"],
		volley_count,
		burst_step,
		total_count
	)
	var desired_direction: Vector2 = fire_target - main.player["pos"]
	if desired_direction.is_zero_approx():
		desired_direction = _get_aim_vector(main)
	return _get_directional_source_slot_index(main, morph_state, clamped_count, desired_direction)


static func _get_mode_slot_position(main: Node, mode: String, slot_index: int, slot_count: int, formation_ratio := 1.0) -> Vector2:
	var aim_vector: Vector2 = _get_aim_vector(main)
	var aim_angle: float = aim_vector.angle()
	var clamped_count: int = maxi(slot_count, 1)
	var profile: Dictionary = SwordArrayConfig.get_profile(mode)

	match mode:
		SwordArrayConfig.MODE_RING:
			var ring_angle: float = (TAU / float(clamped_count)) * float(slot_index)
			var ring_radius: float = lerpf(profile["idle_ring_radius"], profile["ring_radius"], formation_ratio)
			return main.player["pos"] + Vector2.RIGHT.rotated(ring_angle) * ring_radius
		SwordArrayConfig.MODE_FAN:
			var fan_arc: float = lerpf(profile["idle_arc"], profile["arc"], formation_ratio)
			var fan_inner_radius: float = lerpf(profile["idle_inner_radius"], profile["inner_radius"], formation_ratio)
			var fan_outer_radius: float = lerpf(profile["idle_radius"], profile["radius"], formation_ratio)
			var fan_layer_count: int = mini(int(profile.get("depth_layers", 3)), clamped_count)
			var fan_layer_counts: Array = _build_fan_layer_counts(clamped_count, fan_layer_count)
			var fan_slot: Dictionary = _locate_fan_slot(slot_index, fan_layer_counts)
			var layer_ratio: float = 1.0
			if fan_layer_count > 1:
				layer_ratio = float(fan_slot["layer"]) / float(fan_layer_count - 1)
			var layer_radius: float = lerpf(fan_inner_radius, fan_outer_radius, layer_ratio)
			var layer_arc: float = fan_arc * lerpf(0.5, 1.0, layer_ratio)
			var layer_slot_count: int = fan_slot["count"]
			var fan_angle: float = _get_fan_layout_angle_factor(fan_slot["index"], layer_slot_count) * layer_arc * 0.5
			return main.player["pos"] + Vector2.RIGHT.rotated(aim_angle + fan_angle) * layer_radius
		_:
			var half_span: float = maxf(float(clamped_count - 1) * 0.5, 1.0)
			var centered_index: float = float(slot_index) - half_span
			var lane_depth: float = absf(centered_index)
			var tip_offset: float = lerpf(profile["idle_tip_offset"], profile["tip_offset"], formation_ratio) - 12.0
			var depth_step: float = lerpf(profile["idle_slot_step"], profile["slot_step"] * 0.72, formation_ratio)
			var forward_offset: float = tip_offset - lane_depth * depth_step
			var side_vector: Vector2 = aim_vector.rotated(PI * 0.5)
			var lane_width: float = lerpf(profile["idle_half_width"] * 0.5, profile["wedge_width"], formation_ratio)
			var side_offset: float = signf(centered_index) * lane_depth * lane_width
			return main.player["pos"] + aim_vector * forward_offset + side_vector * side_offset


static func _get_transition_slot_position(
	main: Node,
	from_mode: String,
	to_mode: String,
	slot_index: int,
	slot_count: int,
	formation_ratio: float,
	blend: float
) -> Vector2:
	var stable_position: Vector2 = _get_mode_slot_position(main, from_mode, slot_index, slot_count, formation_ratio).lerp(
		_get_mode_slot_position(main, to_mode, slot_index, slot_count, formation_ratio),
		_smoothstep_local(blend)
	)
	var transition_weight: float = get_transition_shape_weight(blend)
	match [from_mode, to_mode]:
		[SwordArrayConfig.MODE_RING, SwordArrayConfig.MODE_FAN]:
			var transition_position: Vector2 = _get_ring_to_fan_slot_position(main, slot_index, slot_count, formation_ratio, blend)
			return stable_position.lerp(transition_position, transition_weight)
		[SwordArrayConfig.MODE_FAN, SwordArrayConfig.MODE_PIERCE]:
			var transition_position: Vector2 = _get_fan_to_pierce_slot_position(main, slot_index, slot_count, formation_ratio, blend)
			return stable_position.lerp(transition_position, transition_weight)
		_:
			return stable_position


static func _get_ring_to_fan_slot_position(main: Node, slot_index: int, slot_count: int, formation_ratio: float, blend: float) -> Vector2:
	var preview: Dictionary = _get_ring_to_fan_preview(main, formation_ratio, blend)
	var clamped_count: int = maxi(slot_count, 1)
	var fan_profile: Dictionary = SwordArrayConfig.get_profile(SwordArrayConfig.MODE_FAN)
	var fan_layer_count: int = mini(int(fan_profile.get("depth_layers", 3)), clamped_count)
	var fan_layer_counts: Array = _build_fan_layer_counts(clamped_count, fan_layer_count)
	var fan_slot: Dictionary = _locate_fan_slot(slot_index, fan_layer_counts)
	var layer_ratio: float = 1.0
	if fan_layer_count > 1:
		layer_ratio = float(fan_slot["layer"]) / float(fan_layer_count - 1)
	var layer_radius: float = lerpf(preview["inner_radius"], preview["outer_radius"], layer_ratio)
	var layer_arc: float = lerpf(preview["inner_arc"], preview["arc"], layer_ratio)
	var angle_factor: float = _get_symmetric_spread_factor(fan_slot["index"], fan_slot["count"])
	return preview["center"] + Vector2.RIGHT.rotated(preview["angle"] + angle_factor * layer_arc * 0.5) * layer_radius


static func _get_fan_preconverge_slot_position(main: Node, slot_index: int, slot_count: int, formation_ratio: float, progress: float) -> Vector2:
	var preview: Dictionary = _get_fan_preconverge_preview(main, formation_ratio, progress)
	return _get_fan_slot_position_from_preview(main, preview, slot_index, slot_count)


static func _get_fan_slot_position_from_preview(main: Node, preview: Dictionary, slot_index: int, slot_count: int) -> Vector2:
	var clamped_count: int = maxi(slot_count, 1)
	var fan_profile: Dictionary = SwordArrayConfig.get_profile(SwordArrayConfig.MODE_FAN)
	var fan_layer_count: int = mini(int(fan_profile.get("depth_layers", 3)), clamped_count)
	var fan_layer_counts: Array = _build_fan_layer_counts(clamped_count, fan_layer_count)
	var fan_slot: Dictionary = _locate_fan_slot(slot_index, fan_layer_counts)
	var layer_ratio: float = 1.0
	if fan_layer_count > 1:
		layer_ratio = float(fan_slot["layer"]) / float(fan_layer_count - 1)
	if preview.get("has_profile_sections", false):
		var sampled: Dictionary = _sample_spear_preview(preview, layer_ratio)
		var side_factor: float = _get_fan_layout_angle_factor(fan_slot["index"], fan_slot["count"])
		return sampled["center"] + preview["side_vector"] * sampled["half_width"] * side_factor
	var layer_radius: float = lerpf(preview["inner_radius"], preview["outer_radius"], layer_ratio)
	var layer_arc: float = preview["arc"] * lerpf(0.52, 1.0, layer_ratio)
	var angle_factor: float = _get_fan_layout_angle_factor(fan_slot["index"], fan_slot["count"])
	return main.player["pos"] + Vector2.RIGHT.rotated(preview["angle"] + angle_factor * layer_arc * 0.5) * layer_radius


static func _get_fan_to_pierce_slot_position(main: Node, slot_index: int, slot_count: int, formation_ratio: float, blend: float) -> Vector2:
	var preview: Dictionary = _get_fan_to_pierce_preview(main, formation_ratio, blend)
	return _get_spear_slot_position_from_preview(main, preview, slot_index, slot_count)


static func _get_spear_slot_position_from_preview(main: Node, preview: Dictionary, slot_index: int, slot_count: int) -> Vector2:
	var clamped_count: int = maxi(slot_count, 1)
	var row_weights: Array = _get_diamond_row_weights(mini(clamped_count, 5))
	var row_counts: Array = _build_weighted_counts(clamped_count, row_weights)
	var row_slot: Dictionary = _locate_fan_slot(slot_index, row_counts)
	var row_count: int = row_counts.size()
	var row_ratio: float = _get_diamond_row_ratio(row_slot["layer"], row_count)
	var sampled: Dictionary = _sample_spear_preview(preview, row_ratio)
	var side_factor: float = _get_symmetric_spread_factor(row_slot["index"], row_slot["count"])
	return sampled["center"] + preview["side_vector"] * sampled["half_width"] * side_factor


static func get_fire_direction(main: Node, state_source, fire_index: int, volley_count := -1, burst_step := 0, total_count := -1) -> Vector2:
	var fire_target: Vector2 = get_fire_target(main, state_source, fire_index, main.player["pos"], volley_count, burst_step, total_count)
	var fire_direction: Vector2 = fire_target - main.player["pos"]
	if fire_direction.is_zero_approx():
		return _get_aim_vector(main)
	return fire_direction.normalized()


static func get_fire_launch_origin(
	main: Node,
	state_source,
	fire_index: int,
	bullet_pos: Vector2,
	volley_count := -1,
	burst_step := 0,
	total_count := -1
) -> Vector2:
	var morph_state: Dictionary = _resolve_morph_state(main, state_source)
	var preview: Dictionary = get_preview_data(main, morph_state, 1.0)
	match preview["type"]:
		SwordArrayConfig.MODE_PIERCE:
			return _get_pierce_launch_origin(preview, bullet_pos)
		"spear":
			return _get_spear_launch_origin(preview, fire_index, bullet_pos, volley_count, burst_step, total_count)
		_:
			return bullet_pos


static func get_fire_target(main: Node, state_source, fire_index: int, bullet_pos: Vector2, volley_count := -1, burst_step := 0, total_count := -1) -> Vector2:
	var morph_state: Dictionary = _resolve_morph_state(main, state_source)
	var preview: Dictionary = get_preview_data(main, morph_state, 1.0)
	match preview["type"]:
		"crescent":
			return _get_crescent_fire_target(main, preview, fire_index, bullet_pos, volley_count, burst_step)
		SwordArrayConfig.MODE_FAN:
			if preview.get("has_profile_sections", false) or preview.get("is_preconverge", false):
				return _get_fan_fire_target_from_preview(main, preview, fire_index, bullet_pos, volley_count, burst_step)
			return _get_mode_fire_target(main, preview["type"], fire_index, bullet_pos, volley_count, burst_step, total_count)
		"spear":
			return _get_spear_fire_target(main, preview, fire_index, bullet_pos, volley_count, burst_step)
		_:
			return _get_mode_fire_target(main, preview["type"], fire_index, bullet_pos, volley_count, burst_step, total_count)


static func _get_mode_fire_target(main: Node, mode: String, fire_index: int, bullet_pos: Vector2, volley_count := -1, burst_step := 0, total_count := -1) -> Vector2:
	var aim_vector: Vector2 = _get_aim_vector(main)
	var profile: Dictionary = SwordArrayConfig.get_profile(mode)
	match mode:
		SwordArrayConfig.MODE_RING:
			var ring_slot_count: int = maxi(
				volley_count if volley_count > 0 else (total_count if total_count > 0 else profile["slot_count"]),
				1
			)
			var ring_slot: int = fire_index % ring_slot_count
			var ring_angle: float = (TAU / float(ring_slot_count)) * float(ring_slot)
			var ring_fire_dir: Vector2 = bullet_pos - main.player["pos"]
			if ring_fire_dir.is_zero_approx():
				ring_fire_dir = Vector2.RIGHT.rotated(ring_angle)
			return main.player["pos"] + ring_fire_dir.normalized() * (profile["ring_radius"] + 180.0)
		SwordArrayConfig.MODE_FAN:
			var fan_slot_count: int = maxi(volley_count if volley_count > 0 else profile["slot_count"], 1)
			var fan_angle_factor: float = _get_fan_fire_angle_factor(mode, fire_index, fan_slot_count, burst_step)
			var fan_preview: Dictionary = _get_mode_preview_data(main, mode, 1.0)
			var fan_angle: float = fan_preview["angle"] + fan_angle_factor * fan_preview["arc"] * 0.5
			var fan_fire_dir: Vector2 = bullet_pos - main.player["pos"]
			if fan_fire_dir.is_zero_approx():
				fan_fire_dir = Vector2.RIGHT.rotated(fan_angle)
			return main.player["pos"] + fan_fire_dir.normalized() * (fan_preview["outer_radius"] + 180.0)
		_:
			var pierce_preview: Dictionary = _get_mode_preview_data(main, mode, 1.0)
			var pierce_line: Vector2 = pierce_preview["tip"] - pierce_preview["start"]
			var pierce_dir: Vector2 = pierce_line.normalized() if not pierce_line.is_zero_approx() else aim_vector
			return pierce_preview["tip"] + pierce_dir * 180.0


static func _get_crescent_fire_target(main: Node, preview: Dictionary, fire_index: int, bullet_pos: Vector2, volley_count := -1, burst_step := 0) -> Vector2:
	var fire_count: int = maxi(volley_count if volley_count > 0 else SwordArrayConfig.get_profile(SwordArrayConfig.MODE_FAN)["slot_count"], 1)
	var angle_factor: float = _get_fan_fire_angle_factor(SwordArrayConfig.MODE_FAN, fire_index, fire_count, burst_step)
	var fire_angle: float = preview["angle"] + angle_factor * preview["arc"] * 0.5
	var anchor: Vector2 = preview["center"] + Vector2.RIGHT.rotated(fire_angle) * preview["outer_radius"]
	var fire_dir: Vector2 = bullet_pos - preview["center"]
	if fire_dir.is_zero_approx():
		fire_dir = anchor - preview["center"]
	if fire_dir.is_zero_approx():
		fire_dir = _get_aim_vector(main)
	return preview["center"] + fire_dir.normalized() * (preview["outer_radius"] + 180.0)


static func _get_fan_fire_target_from_preview(main: Node, preview: Dictionary, fire_index: int, bullet_pos: Vector2, volley_count := -1, burst_step := 0) -> Vector2:
	var fire_count: int = maxi(volley_count if volley_count > 0 else SwordArrayConfig.get_profile(SwordArrayConfig.MODE_FAN)["slot_count"], 1)
	var angle_factor: float = _get_fan_fire_angle_factor(SwordArrayConfig.MODE_FAN, fire_index, fire_count, burst_step)
	if preview.get("has_profile_sections", false):
		var sampled: Dictionary = _sample_spear_preview(
			preview,
			0.74 + (1.0 - absf(angle_factor)) * 0.16
		)
		var anchor: Vector2 = sampled["center"] + preview["side_vector"] * sampled["half_width"] * angle_factor
		var fire_dir: Vector2 = bullet_pos - main.player["pos"]
		if fire_dir.is_zero_approx():
			fire_dir = anchor - main.player["pos"]
		if fire_dir.is_zero_approx():
			fire_dir = preview["aim_vector"]
		return anchor + fire_dir.normalized() * 180.0
	var fire_angle: float = preview["angle"] + angle_factor * preview["arc"] * 0.5
	var fire_dir: Vector2 = bullet_pos - main.player["pos"]
	if fire_dir.is_zero_approx():
		fire_dir = Vector2.RIGHT.rotated(fire_angle)
	return main.player["pos"] + fire_dir.normalized() * (preview["outer_radius"] + 180.0)


static func _get_spear_fire_target(main: Node, preview: Dictionary, fire_index: int, bullet_pos: Vector2, volley_count := -1, burst_step := 0) -> Vector2:
	var fire_count: int = maxi(volley_count if volley_count > 0 else SwordArrayConfig.get_profile(SwordArrayConfig.MODE_FAN)["slot_count"], 1)
	var lateral_factor: float = _get_fan_fire_angle_factor(SwordArrayConfig.MODE_FAN, fire_index, fire_count, burst_step)
	var forward_ratio: float = 0.72 + (1.0 - absf(lateral_factor)) * 0.22
	var sampled: Dictionary = _sample_spear_preview(preview, forward_ratio)
	var anchor: Vector2 = sampled["center"] + preview["side_vector"] * sampled["half_width"] * lateral_factor
	var fire_dir: Vector2 = bullet_pos - main.player["pos"]
	if fire_dir.is_zero_approx():
		fire_dir = anchor - main.player["pos"]
	if fire_dir.is_zero_approx():
		fire_dir = preview["aim_vector"]
	return anchor + fire_dir.normalized() * 180.0 + preview["side_vector"] * sampled["half_width"] * lateral_factor * 0.12


static func _get_pierce_launch_origin(preview: Dictionary, bullet_pos: Vector2) -> Vector2:
	var launch_origin: Vector2 = preview.get("tip", bullet_pos)
	var tip_dir: Vector2 = launch_origin - preview.get("start", bullet_pos)
	if not tip_dir.is_zero_approx():
		launch_origin -= tip_dir.normalized() * maxf(float(preview.get("tip_radius", 0.0)), 2.0) * 0.35
	return launch_origin


static func _get_spear_launch_origin(
	preview: Dictionary,
	fire_index: int,
	bullet_pos: Vector2,
	volley_count := -1,
	burst_step := 0,
	total_count := -1
) -> Vector2:
	var fire_count: int = maxi(
		volley_count if volley_count > 0 else (total_count if total_count > 0 else SwordArrayConfig.get_profile(SwordArrayConfig.MODE_FAN)["slot_count"]),
		1
	)
	var lateral_factor: float = _get_fan_fire_angle_factor(SwordArrayConfig.MODE_FAN, fire_index, fire_count, burst_step)
	var forward_ratio: float = 0.72 + (1.0 - absf(lateral_factor)) * 0.22
	var sampled: Dictionary = _sample_spear_preview(preview, forward_ratio)
	var anchor: Vector2 = sampled["center"] + preview["side_vector"] * sampled["half_width"] * lateral_factor
	var tip: Vector2 = preview.get("tip", anchor)
	var tip_focus: float = clampf(float(preview.get("tip_focus", 0.0)), 0.0, 1.0)
	var blend: float = clampf(float(preview.get("blend", 0.0)), 0.0, 1.0)
	var launch_blend: float = _smoothstep_local(maxf(tip_focus, blend * 0.78))
	return anchor.lerp(tip, launch_blend)


static func get_preview_data(main: Node, state_source, formation_ratio := 1.0) -> Dictionary:
	var morph_state: Dictionary = _resolve_morph_state(main, state_source)
	var converging_preview: Dictionary = _get_active_fan_pierce_preview(main, morph_state, formation_ratio)
	if not converging_preview.is_empty():
		return converging_preview
	match [morph_state["visual_from_mode"], morph_state["visual_to_mode"]]:
		[SwordArrayConfig.MODE_RING, SwordArrayConfig.MODE_FAN]:
			return _get_ring_to_fan_preview(main, formation_ratio, morph_state["visual_blend"])
		_:
			return _get_mode_preview_data(main, morph_state["dominant_mode"], formation_ratio)


static func _get_mode_preview_data(main: Node, mode: String, formation_ratio := 1.0) -> Dictionary:
	var aim_vector: Vector2 = _get_aim_vector(main)
	var aim_angle: float = aim_vector.angle()
	var profile: Dictionary = SwordArrayConfig.get_profile(mode)
	match mode:
		SwordArrayConfig.MODE_RING:
			return {
				"type": SwordArrayConfig.MODE_RING,
				"radius": lerpf(profile["idle_ring_radius"], profile["ring_radius"], formation_ratio),
				"outer_radius": lerpf(profile["idle_ring_radius"] + profile["preview_outer_offset_idle"], profile["ring_radius"] + profile["preview_outer_offset_active"], formation_ratio),
			}
		SwordArrayConfig.MODE_FAN:
			var fan_arc: float = lerpf(profile["idle_arc"], profile["arc"], formation_ratio)
			var fan_inner_radius: float = lerpf(profile["idle_inner_radius"], profile["inner_radius"], formation_ratio)
			var fan_outer_radius: float = lerpf(profile["idle_radius"], profile["radius"], formation_ratio)
			return {
				"type": SwordArrayConfig.MODE_FAN,
				"inner_radius": fan_inner_radius,
				"outer_radius": fan_outer_radius,
				"angle": aim_angle,
				"arc": fan_arc,
			}
		_:
			var start_offset: float = lerpf(profile["idle_start_offset"], profile["start_offset"], formation_ratio)
			var preview_length: float = lerpf(profile["preview_length"] * profile["preview_length_idle_scale"], profile["preview_length"], formation_ratio)
			var half_width: float = lerpf(profile["idle_half_width"], profile["preview_half_width"], formation_ratio)
			var tip_offset: float = lerpf(profile["idle_tip_offset"], profile["tip_offset"], formation_ratio)
			var tip_radius: float = lerpf(profile["tip_radius_idle"], profile["tip_radius"], formation_ratio)
			var wedge_length: float = lerpf(profile["wedge_length_idle"], profile["wedge_length"], formation_ratio)
			var wedge_width: float = lerpf(profile["wedge_width_idle"], profile["wedge_width"], formation_ratio)
			return {
				"type": SwordArrayConfig.MODE_PIERCE,
				"start": main.player["pos"] + aim_vector * start_offset,
				"end": main.player["pos"] + aim_vector * preview_length,
				"half_width": half_width,
				"tip": main.player["pos"] + aim_vector * tip_offset,
				"tip_radius": tip_radius,
				"wedge_length": wedge_length,
				"wedge_width": wedge_width,
			}


static func _get_fan_section_arc_scale(radius_ratio: float) -> float:
	return lerpf(0.52, 1.0, clampf(radius_ratio, 0.0, 1.0))


static func _build_fan_profile_sections(
	main: Node,
	aim_vector: Vector2,
	side_vector: Vector2,
	inner_radius: float,
	outer_radius: float,
	arc: float,
	angle_scales: Array,
	forward_bonus_base := 0.0,
	forward_bonus_strength := 0.0
) -> Dictionary:
	var sample_count: int = mini(CONVERGE_SAMPLE_RADIUS_RATIOS.size(), angle_scales.size())
	var sections: Array = []
	var left_outline: Array = []
	var right_outline: Array = []
	var sample_index: int = 0
	while sample_index < sample_count:
		var radius_ratio: float = CONVERGE_SAMPLE_RADIUS_RATIOS[sample_index]
		var sample_radius: float = lerpf(inner_radius, outer_radius, radius_ratio)
		var sample_half_angle: float = arc * 0.5 * float(angle_scales[sample_index])
		var forward_bonus: float = 0.0
		if sample_index < FAN_PRECONVERGE_FORWARD_BONUS_SCALES.size():
			forward_bonus = forward_bonus_base * FAN_PRECONVERGE_FORWARD_BONUS_SCALES[sample_index] * forward_bonus_strength
		var forward_offset: float = cos(sample_half_angle) * sample_radius + forward_bonus
		var half_width: float = sin(sample_half_angle) * sample_radius
		var center: Vector2 = main.player["pos"] + aim_vector * forward_offset
		var left_point: Vector2 = center - side_vector * half_width
		var right_point: Vector2 = center + side_vector * half_width
		sections.append({
			"ratio": float(sample_index) / float(maxi(sample_count - 1, 1)),
			"forward_offset": forward_offset,
			"half_width": half_width,
			"center": center,
			"left": left_point,
			"right": right_point,
		})
		left_outline.append(left_point)
		right_outline.append(right_point)
		sample_index += 1
	return {
		"sections": sections,
		"left_outline": left_outline,
		"right_outline": right_outline,
	}


static func _build_sections_from_profile_data(
	main: Node,
	aim_vector: Vector2,
	side_vector: Vector2,
	forward_offsets: Array,
	half_widths: Array
) -> Array:
	var sample_count: int = mini(forward_offsets.size(), half_widths.size())
	var sections: Array = []
	var sample_index: int = 0
	while sample_index < sample_count:
		var forward_offset: float = float(forward_offsets[sample_index])
		var half_width: float = maxf(float(half_widths[sample_index]), 0.0)
		var center: Vector2 = main.player["pos"] + aim_vector * forward_offset
		var left_point: Vector2 = center - side_vector * half_width
		var right_point: Vector2 = center + side_vector * half_width
		sections.append({
			"ratio": float(sample_index) / float(maxi(sample_count - 1, 1)),
			"forward_offset": forward_offset,
			"half_width": half_width,
			"center": center,
			"left": left_point,
			"right": right_point,
		})
		sample_index += 1
	return sections


static func _build_crescent_profile_sections(main: Node, preview: Dictionary) -> Array:
	var aim_vector: Vector2 = Vector2.RIGHT.rotated(preview["angle"])
	var side_vector: Vector2 = aim_vector.rotated(PI * 0.5)
	var sections: Array = []
	var sample_index: int = 0
	while sample_index < CONVERGE_SAMPLE_RADIUS_RATIOS.size():
		var radius_ratio: float = CONVERGE_SAMPLE_RADIUS_RATIOS[sample_index]
		var sample_radius: float = lerpf(preview["inner_radius"], preview["outer_radius"], radius_ratio)
		var sample_arc: float = lerpf(preview["inner_arc"], preview["arc"], radius_ratio)
		var sample_half_angle: float = sample_arc * 0.5
		var center: Vector2 = preview["center"] + aim_vector * cos(sample_half_angle) * sample_radius
		var half_width: float = sin(sample_half_angle) * sample_radius
		sections.append({
			"ratio": float(sample_index) / float(maxi(CONVERGE_SAMPLE_RADIUS_RATIOS.size() - 1, 1)),
			"forward_offset": (center - main.player["pos"]).dot(aim_vector),
			"half_width": half_width,
			"center": center,
			"left": center - side_vector * half_width,
			"right": center + side_vector * half_width,
		})
		sample_index += 1
	return sections


static func _build_section_preview(
	preview_type: String,
	aim_vector: Vector2,
	side_vector: Vector2,
	sections: Array,
	extra := {}
) -> Dictionary:
	if sections.is_empty():
		return {}
	var left_outline: Array = []
	var right_outline: Array = []
	for section in sections:
		left_outline.append(section["left"])
		right_outline.append(section["right"])
	var preview := {
		"type": preview_type,
		"aim_vector": aim_vector,
		"side_vector": side_vector,
		"sections": sections,
		"left_outline": left_outline,
		"right_outline": right_outline,
		"tail": sections[0]["center"],
		"tip": sections[sections.size() - 1]["center"],
		"start": sections[0]["center"],
		"end": sections[maxi(sections.size() - 2, 0)]["center"],
	}
	for key in extra.keys():
		preview[key] = extra[key]
	return preview


static func _get_forward_convex_cap_control(aim_vector: Vector2, section: Dictionary, min_push: float, push_scale: float) -> Vector2:
	return section["center"] + aim_vector * maxf(float(section["half_width"]) * push_scale, min_push)


static func _blend_sections(from_sections: Array, to_sections: Array, blend: float, blend_scales: Array = []) -> Array:
	var section_count: int = mini(from_sections.size(), to_sections.size())
	var sections: Array = []
	var clamped_blend: float = clampf(blend, 0.0, 1.0)
	var section_index: int = 0
	while section_index < section_count:
		var from_section: Dictionary = from_sections[section_index]
		var to_section: Dictionary = to_sections[section_index]
		var local_blend: float = clamped_blend
		if section_index < blend_scales.size():
			local_blend = clampf(clamped_blend * float(blend_scales[section_index]), 0.0, 1.0)
		var left_point: Vector2 = from_section["left"].lerp(to_section["left"], local_blend)
		var right_point: Vector2 = from_section["right"].lerp(to_section["right"], local_blend)
		var center: Vector2 = (left_point + right_point) * 0.5
		sections.append({
			"ratio": float(section_index) / float(maxi(section_count - 1, 1)),
			"forward_offset": lerpf(float(from_section["forward_offset"]), float(to_section["forward_offset"]), local_blend),
			"half_width": left_point.distance_to(right_point) * 0.5,
			"center": center,
			"left": left_point,
			"right": right_point,
		})
		section_index += 1
	return sections


static func _get_pierce_profile_widths(pierce_preview: Dictionary) -> Array:
	var pierce_tail_width: float = maxf(pierce_preview["wedge_width"], pierce_preview["half_width"] * 1.35)
	return [
		pierce_tail_width,
		maxf(pierce_preview["half_width"] * 1.4, 5.5),
		maxf(pierce_preview["half_width"] * 1.1, 4.4),
		maxf(pierce_preview["half_width"] * 0.82, 3.1),
		maxf(pierce_preview["half_width"] * 0.48, 1.5),
		maxf(pierce_preview["half_width"] * 0.18, 0.7),
		maxf(pierce_preview["half_width"] * 0.05, 0.2),
		0.0,
	]


static func _build_pierce_profile_sections(main: Node, aim_vector: Vector2, side_vector: Vector2, pierce_preview: Dictionary, section_count: int) -> Array:
	var width_profile: Array = _get_pierce_profile_widths(pierce_preview)
	var forward_offsets: Array = []
	var half_widths: Array = []
	var pierce_start_offset: float = main.player["pos"].distance_to(pierce_preview["start"])
	var pierce_tip_offset: float = main.player["pos"].distance_to(pierce_preview["tip"])
	var section_index: int = 0
	while section_index < section_count:
		forward_offsets.append(lerpf(
			pierce_start_offset,
			pierce_tip_offset,
			float(SPEAR_SAMPLE_FORWARD_RATIOS[section_index])
		))
		half_widths.append(width_profile[section_index])
		section_index += 1
	return _build_sections_from_profile_data(main, aim_vector, side_vector, forward_offsets, half_widths)


static func _build_bulb_profile_sections(main: Node, aim_vector: Vector2, side_vector: Vector2, fan_sections: Array, pierce_preview: Dictionary, section_count: int) -> Array:
	var width_profile: Array = _get_pierce_profile_widths(pierce_preview)
	var forward_offsets: Array = []
	var half_widths: Array = []
	var pierce_start_offset: float = main.player["pos"].distance_to(pierce_preview["start"])
	var pierce_tip_offset: float = main.player["pos"].distance_to(pierce_preview["tip"])
	var fan_shoulder_width: float = float(fan_sections[mini(3, maxi(section_count - 1, 0))]["half_width"])
	var bulb_base_width: float = maxf(minf(fan_shoulder_width * 0.54, 28.0), maxf(width_profile[1] * 2.0, 12.0))
	var forward_lift: float = maxf((pierce_tip_offset - pierce_start_offset) * 0.18, 18.0)
	var section_index: int = 0
	while section_index < section_count:
		var fan_section: Dictionary = fan_sections[section_index]
		var fan_forward: float = float(fan_section["forward_offset"])
		var fan_half_width: float = float(fan_section["half_width"])
		var pierce_forward: float = lerpf(
			pierce_start_offset,
			pierce_tip_offset,
			float(SPEAR_SAMPLE_FORWARD_RATIOS[section_index])
		)
		var width_limit: float = fan_half_width * SPEAR_BULB_FAN_WIDTH_LIMIT_SCALES[section_index]
		var width_target: float = bulb_base_width * SPEAR_BULB_WIDTH_TARGET_SCALES[section_index]
		var bulb_half_width: float = maxf(width_profile[section_index] * 1.28, minf(width_limit, width_target))
		var forward_target: float = lerpf(
			fan_forward,
			pierce_forward,
			float(SPEAR_BULB_FORWARD_BLEND_SCALES[section_index])
		)
		forward_target = minf(
			pierce_tip_offset,
			forward_target + forward_lift * SPEAR_BULB_FORWARD_BONUS_SCALES[section_index]
		)
		forward_offsets.append(forward_target)
		half_widths.append(bulb_half_width)
		section_index += 1
	return _build_sections_from_profile_data(main, aim_vector, side_vector, forward_offsets, half_widths)


static func _get_fan_preconverge_preview(main: Node, formation_ratio: float, progress: float) -> Dictionary:
	var base_preview: Dictionary = _get_mode_preview_data(main, SwordArrayConfig.MODE_FAN, formation_ratio)
	var aim_vector: Vector2 = Vector2.RIGHT.rotated(base_preview["angle"])
	var side_vector: Vector2 = aim_vector.rotated(PI * 0.5)
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	if clamped_progress <= 0.0:
		return base_preview
	var shaped_progress: float = pow(clamped_progress, FAN_PRECONVERGE_PROGRESS_EXPONENT)
	var preview_arc: float = lerpf(base_preview["arc"], base_preview["arc"] * FAN_PRECONVERGE_ARC_SCALE, shaped_progress)
	var preview_inner_radius: float = lerpf(base_preview["inner_radius"], base_preview["inner_radius"] * FAN_PRECONVERGE_INNER_SCALE, shaped_progress)
	var preview_outer_radius: float = lerpf(base_preview["outer_radius"], base_preview["outer_radius"] * FAN_PRECONVERGE_OUTER_SCALE, shaped_progress)
	var angle_scales: Array = []
	var sample_index: int = 0
	while sample_index < CONVERGE_SAMPLE_RADIUS_RATIOS.size():
		var radius_ratio: float = CONVERGE_SAMPLE_RADIUS_RATIOS[sample_index]
		var base_angle_scale: float = _get_fan_section_arc_scale(radius_ratio)
		var target_angle_scale: float = base_angle_scale
		if sample_index < FAN_PRECONVERGE_ANGLE_SCALES.size():
			target_angle_scale *= FAN_PRECONVERGE_ANGLE_SCALES[sample_index]
		angle_scales.append(lerpf(base_angle_scale, target_angle_scale, shaped_progress))
		sample_index += 1
	var section_data: Dictionary = _build_fan_profile_sections(
		main,
		aim_vector,
		side_vector,
		preview_inner_radius,
		preview_outer_radius,
		preview_arc,
		angle_scales,
		preview_outer_radius * 0.12,
		shaped_progress
	)
	var sections: Array = section_data["sections"]
	if sections.is_empty():
		return base_preview
	return _build_section_preview(
		SwordArrayConfig.MODE_FAN,
		aim_vector,
		side_vector,
		sections,
		{
			"is_preconverge": true,
			"angle": base_preview["angle"],
			"arc": preview_arc,
			"inner_radius": preview_inner_radius,
			"outer_radius": preview_outer_radius,
			"outer_cap_control": main.player["pos"] + aim_vector * preview_outer_radius,
			"inner_cap_control": main.player["pos"] + aim_vector * preview_inner_radius,
			"edge_curve_strength": 1.0,
			"section_line_strength": _smoothstep_local(inverse_lerp(0.12, 0.56, shaped_progress)),
			"has_profile_sections": true,
		}
	)


static func _get_active_fan_pierce_preview(main: Node, morph_state: Dictionary, formation_ratio: float) -> Dictionary:
	var band_preview: Dictionary = _get_continuous_band_preview(main, morph_state, formation_ratio)
	if not band_preview.is_empty():
		return band_preview
	var ring_fan_blend_weight: float = _get_ring_fan_blend_weight(morph_state)
	if ring_fan_blend_weight >= 0.0:
		return _get_ring_fan_blend_preview(main, morph_state, formation_ratio, ring_fan_blend_weight)
	var fan_blend_weight: float = _get_fan_spear_blend_weight(morph_state)
	if fan_blend_weight >= 0.0:
		return _get_fan_spear_blend_preview(main, morph_state, formation_ratio, fan_blend_weight)
	var fan_preconverge_progress: float = _get_fan_preconverge_progress(morph_state)
	if fan_preconverge_progress >= 0.0:
		return _get_fan_preconverge_preview(main, formation_ratio, fan_preconverge_progress)
	if _should_use_converging_pierce_geometry(morph_state):
		return _get_fan_to_pierce_preview(main, formation_ratio, _get_continuous_pierce_progress(morph_state))
	return {}


static func _get_ring_to_fan_preview(main: Node, formation_ratio: float, blend: float) -> Dictionary:
	var aim_vector: Vector2 = _get_aim_vector(main)
	var ring_preview: Dictionary = _get_mode_preview_data(main, SwordArrayConfig.MODE_RING, formation_ratio)
	var fan_preview: Dictionary = _get_mode_preview_data(main, SwordArrayConfig.MODE_FAN, formation_ratio)
	var mid_strength: float = get_transition_shape_weight(blend)
	var center_offset: float = fan_preview["inner_radius"] * 0.18 * mid_strength
	var base_arc: float = lerpf(TAU, fan_preview["arc"], blend)
	return {
		"type": "crescent",
		"blend": blend,
		"from_preview": ring_preview,
		"to_preview": fan_preview,
		"center": main.player["pos"] + aim_vector * center_offset,
		"angle": aim_vector.angle(),
		"outer_radius": lerpf(ring_preview["outer_radius"], fan_preview["outer_radius"], blend),
		"inner_radius": lerpf(ring_preview["radius"], fan_preview["inner_radius"], blend),
		"arc": base_arc,
		"inner_arc": maxf(fan_preview["arc"], base_arc - mid_strength * PI * 0.42),
	}


static func _get_continuous_band_preview(main: Node, morph_state: Dictionary, formation_ratio: float) -> Dictionary:
	var distances: Dictionary = SwordArrayConfig.get_morph_distances()
	var actual_distance: float = _get_actual_morph_distance(morph_state)
	var band_start: float = _get_band_preview_start_distance(distances)
	var band_end: float = _get_band_collapse_start_distance(distances)
	if actual_distance < band_start or actual_distance > band_end:
		return {}
	return _build_continuous_band_preview(main, morph_state, formation_ratio, actual_distance, band_start, band_end)


static func _build_continuous_band_preview(
	main: Node,
	morph_state: Dictionary,
	formation_ratio: float,
	actual_distance: float,
	band_start: float,
	band_end: float
) -> Dictionary:
	var distances: Dictionary = SwordArrayConfig.get_morph_distances()
	var aim_vector: Vector2 = _get_aim_vector(main)
	var side_vector: Vector2 = aim_vector.rotated(PI * 0.5)
	var crescent_blend: float = _smoothstep_local(
		inverse_lerp(distances["ring_stable_end"], distances["ring_to_fan_end"], actual_distance)
	)
	var crescent_preview: Dictionary = _get_ring_to_fan_preview(main, formation_ratio, crescent_blend)
	var crescent_sections: Array = _build_crescent_profile_sections(main, crescent_preview)
	var fan_progress_raw: float = _get_fan_preconverge_progress(morph_state)
	var fan_progress: float = 0.0
	if fan_progress_raw >= 0.0:
		fan_progress = clampf(fan_progress_raw, 0.0, 1.0)
	elif actual_distance > distances["fan_stable_end"]:
		fan_progress = 1.0
	var fan_preview: Dictionary = _get_fan_preconverge_preview(
		main,
		formation_ratio,
		fan_progress
	)
	var fan_sections: Array = _build_fan_sections(main, fan_preview)
	if crescent_sections.is_empty() or fan_sections.is_empty():
		return fan_preview

	var entry_blend: float = 1.0
	if band_start < distances["ring_to_fan_end"] + BAND_ENTRY_BLEND_AFTER_RING_FAN_END:
		entry_blend = _smoothstep_local(
			inverse_lerp(band_start, distances["ring_to_fan_end"] + BAND_ENTRY_BLEND_AFTER_RING_FAN_END, actual_distance)
		)
	var opening_sections: Array = _blend_sections(crescent_sections, fan_sections, entry_blend)
	if opening_sections.is_empty():
		return fan_preview
	var opening_outer_cap: Vector2 = (
		crescent_preview["center"] + aim_vector * crescent_preview["outer_radius"]
	).lerp(
		fan_preview.get("outer_cap_control", main.player["pos"] + aim_vector * fan_preview["outer_radius"]),
		entry_blend
	)
	var opening_inner_cap: Vector2 = (
		crescent_preview["center"] + aim_vector * crescent_preview["inner_radius"]
	).lerp(
		fan_preview.get("inner_cap_control", main.player["pos"] + aim_vector * fan_preview["inner_radius"]),
		entry_blend
	)

	var bulb_start: float = maxf(_get_band_bulb_start_distance(distances), band_start)
	var pierce_preview: Dictionary = _get_mode_preview_data(main, SwordArrayConfig.MODE_PIERCE, formation_ratio)
	var bulb_sections: Array = _build_bulb_profile_sections(
		main,
		aim_vector,
		side_vector,
		fan_sections,
		pierce_preview,
		mini(fan_sections.size(), SPEAR_SAMPLE_FORWARD_RATIOS.size())
	)
	if bulb_sections.is_empty():
		return fan_preview
	var bulb_blend: float = _smoothstep_local(inverse_lerp(bulb_start, band_end, actual_distance))
	var sections: Array = _blend_sections(opening_sections, bulb_sections, bulb_blend)
	if sections.is_empty():
		return fan_preview
	var front_convex_cap: Vector2 = _get_forward_convex_cap_control(
		aim_vector,
		sections[sections.size() - 1],
		12.0,
		1.18
	)
	var rear_soft_cap: Vector2 = sections[0]["center"] + aim_vector * maxf(float(sections[0]["half_width"]) * 0.18, 4.0)

	var spine_focus: float = _smoothstep_local(inverse_lerp(bulb_start - 18.0, band_end, actual_distance))
	var tip_focus: float = _smoothstep_local(inverse_lerp(band_end - 26.0, band_end, actual_distance)) * 0.4
	return _build_section_preview(
		SwordArrayConfig.MODE_FAN,
		aim_vector,
		side_vector,
		sections,
		{
			"blend": clampf(inverse_lerp(band_start, band_end, actual_distance), 0.0, 1.0),
			"phase": "continuous_band",
			"angle": aim_vector.angle(),
			"arc": lerpf(crescent_preview["arc"], fan_preview["arc"], entry_blend),
			"inner_radius": lerpf(crescent_preview["inner_radius"], fan_preview["inner_radius"], entry_blend),
			"outer_radius": lerpf(crescent_preview["outer_radius"], fan_preview["outer_radius"], entry_blend),
			"outer_cap_control": opening_outer_cap.lerp(front_convex_cap, bulb_blend),
			"inner_cap_control": opening_inner_cap.lerp(rear_soft_cap, bulb_blend * 0.72),
			"edge_curve_strength": lerpf(1.0, 0.78, bulb_blend),
			"section_line_strength": lerpf(0.0, 0.82, maxf(entry_blend, bulb_blend * 0.9)),
			"spine_focus": spine_focus,
			"tip_focus": tip_focus,
			"tip_radius": pierce_preview["tip_radius"] * 0.52 * tip_focus,
			"preview_state": morph_state,
			"is_preconverge": true,
			"has_profile_sections": true,
		}
	)


static func _get_ring_fan_blend_preview(main: Node, morph_state: Dictionary, formation_ratio: float, blend_weight: float) -> Dictionary:
	var distances: Dictionary = SwordArrayConfig.get_morph_distances()
	var actual_distance: float = clampf(
		float(morph_state.get("distance_ratio", 0.0)) * distances["fan_to_pierce_end"],
		0.0,
		distances["fan_to_pierce_end"]
	)
	var virtual_crescent_blend: float = _smoothstep_local(
		inverse_lerp(distances["ring_stable_end"], distances["ring_to_fan_end"], actual_distance)
	)
	var crescent_preview: Dictionary = _get_ring_to_fan_preview(main, formation_ratio, virtual_crescent_blend)
	if blend_weight <= 0.06:
		return crescent_preview
	var fan_progress: float = maxf(_get_fan_preconverge_progress(morph_state), 0.0)
	var fan_preview: Dictionary = _get_fan_preconverge_preview(main, formation_ratio, fan_progress)
	var crescent_sections: Array = _build_crescent_profile_sections(main, crescent_preview)
	var fan_sections: Array = _build_fan_sections(main, fan_preview)
	if crescent_sections.is_empty() or fan_sections.is_empty():
		return fan_preview
	var aim_vector: Vector2 = Vector2.RIGHT.rotated(crescent_preview["angle"])
	var side_vector: Vector2 = aim_vector.rotated(PI * 0.5)
	var sections: Array = _blend_sections(crescent_sections, fan_sections, blend_weight)
	if sections.is_empty():
		return fan_preview
	var crescent_outer_cap: Vector2 = crescent_preview["center"] + aim_vector * crescent_preview["outer_radius"]
	var crescent_inner_cap: Vector2 = crescent_preview["center"] + aim_vector * crescent_preview["inner_radius"]
	var fan_outer_cap: Vector2 = fan_preview.get("outer_cap_control", main.player["pos"] + aim_vector * fan_preview["outer_radius"])
	var fan_inner_cap: Vector2 = fan_preview.get("inner_cap_control", main.player["pos"] + aim_vector * fan_preview["inner_radius"])
	return _build_section_preview(
		SwordArrayConfig.MODE_FAN,
		aim_vector,
		side_vector,
		sections,
		{
			"blend": blend_weight,
			"phase": "ring_fan_blend",
			"angle": aim_vector.angle(),
			"arc": lerpf(crescent_preview["arc"], fan_preview["arc"], blend_weight),
			"inner_radius": lerpf(crescent_preview["inner_radius"], fan_preview["inner_radius"], blend_weight),
			"outer_radius": lerpf(crescent_preview["outer_radius"], fan_preview["outer_radius"], blend_weight),
			"outer_cap_control": crescent_outer_cap.lerp(fan_outer_cap, blend_weight),
			"inner_cap_control": crescent_inner_cap.lerp(fan_inner_cap, blend_weight),
			"edge_curve_strength": 1.0,
			"section_line_strength": lerpf(0.0, float(fan_preview.get("section_line_strength", 0.0)), blend_weight),
			"has_profile_sections": true,
		}
	)


static func _get_fan_to_pierce_preview(main: Node, formation_ratio: float, blend: float) -> Dictionary:
	var aim_vector: Vector2 = _get_aim_vector(main)
	var side_vector: Vector2 = aim_vector.rotated(PI * 0.5)
	var fan_preview: Dictionary = _get_fan_preconverge_preview(main, formation_ratio, 1.0)
	var fan_sections: Array = _build_fan_sections(main, fan_preview)
	var pierce_preview: Dictionary = _get_mode_preview_data(main, SwordArrayConfig.MODE_PIERCE, formation_ratio)
	var section_count: int = fan_sections.size()
	section_count = mini(section_count, SPEAR_SAMPLE_FORWARD_RATIOS.size())
	if section_count <= 0:
		return pierce_preview
	var bulb_sections: Array = _build_bulb_profile_sections(main, aim_vector, side_vector, fan_sections, pierce_preview, section_count)
	var pierce_sections: Array = _build_pierce_profile_sections(main, aim_vector, side_vector, pierce_preview, section_count)
	if bulb_sections.is_empty() or pierce_sections.is_empty():
		return pierce_preview
	var clamped_blend: float = clampf(blend, 0.0, 1.0)
	var sections: Array = []
	var edge_curve_strength: float = 0.0
	var spine_focus: float = 0.0
	if clamped_blend <= SPEAR_BULB_PHASE_END:
		var bulb_blend: float = _smoothstep_local(inverse_lerp(0.0, SPEAR_BULB_PHASE_END, clamped_blend))
		sections = _blend_sections(fan_sections, bulb_sections, bulb_blend, SPEAR_BULB_SECTION_BLEND_SCALES)
		var curve_release: float = _smoothstep_local(
			inverse_lerp(SPEAR_BULB_EDGE_CURVE_RELEASE_START, 1.0, bulb_blend)
		)
		edge_curve_strength = lerpf(1.0, SPEAR_BULB_EDGE_CURVE_MIN, curve_release)
		spine_focus = lerpf(0.0, SPEAR_SPINE_FOCUS_AT_BULB_END, bulb_blend)
	else:
		var pierce_blend: float = _smoothstep_local(inverse_lerp(SPEAR_BULB_PHASE_END, 1.0, clamped_blend))
		sections = _blend_sections(bulb_sections, pierce_sections, pierce_blend)
		edge_curve_strength = lerpf(SPEAR_BULB_EDGE_CURVE_MIN, 0.0, pierce_blend)
		spine_focus = lerpf(SPEAR_SPINE_FOCUS_AT_BULB_END, 1.0, pierce_blend)
	if sections.is_empty():
		return pierce_preview
	var tip_focus: float = _smoothstep_local(inverse_lerp(SPEAR_TIP_FOCUS_START, 1.0, clamped_blend))
	return _build_section_preview(
		"spear",
		aim_vector,
		side_vector,
		sections,
		{
			"blend": clamped_blend,
			"phase": "fan_to_bulb" if clamped_blend <= SPEAR_BULB_PHASE_END else "bulb_to_pierce",
			"edge_curve_strength": edge_curve_strength,
			"spine_focus": spine_focus,
			"tip_radius": lerpf(0.0, pierce_preview["tip_radius"], tip_focus),
			"tip_focus": tip_focus,
		}
	)


static func _get_fan_spear_blend_preview(main: Node, morph_state: Dictionary, formation_ratio: float, blend_weight: float) -> Dictionary:
	var fan_preview: Dictionary = _get_fan_preconverge_preview(
		main,
		formation_ratio,
		clampf(_get_fan_preconverge_progress(morph_state), 0.0, 1.0)
	)
	var spear_preview: Dictionary = _get_fan_to_pierce_preview(
		main,
		formation_ratio,
		clampf(_get_continuous_pierce_progress(morph_state), 0.0, 1.0)
	)
	var fan_sections: Array = _build_fan_sections(main, fan_preview)
	var sections: Array = _blend_sections(fan_sections, spear_preview["sections"], blend_weight)
	if sections.is_empty():
		return spear_preview
	return _build_section_preview(
		"spear",
		spear_preview["aim_vector"],
		spear_preview["side_vector"],
		sections,
		{
			"blend": blend_weight,
			"phase": "fan_spear_blend",
			"edge_curve_strength": lerpf(1.0, float(spear_preview.get("edge_curve_strength", 0.0)), blend_weight),
			"spine_focus": lerpf(0.0, float(spear_preview.get("spine_focus", 1.0)), blend_weight),
			"tip_radius": lerpf(0.0, spear_preview["tip_radius"], blend_weight),
			"tip_focus": lerpf(0.0, spear_preview.get("tip_focus", 1.0), blend_weight),
		}
	)


static func _build_fan_sections(main: Node, preview: Dictionary) -> Array:
	if preview.get("has_profile_sections", false):
		return preview["sections"]
	var aim_vector: Vector2 = Vector2.RIGHT.rotated(preview["angle"])
	var angle_scales: Array = []
	var sample_index: int = 0
	while sample_index < CONVERGE_SAMPLE_RADIUS_RATIOS.size():
		angle_scales.append(_get_fan_section_arc_scale(CONVERGE_SAMPLE_RADIUS_RATIOS[sample_index]))
		sample_index += 1
	return _build_fan_profile_sections(
		main,
		aim_vector,
		aim_vector.rotated(PI * 0.5),
		preview["inner_radius"],
		preview["outer_radius"],
		preview["arc"],
		angle_scales
	)["sections"]


static func get_fire_interval(main: Node, mode: String) -> float:
	return SwordArrayConfig.get_profile(mode)["fire_interval"]


static func get_fire_batch_size(main: Node, mode: String, remaining_count: int, burst_step: int) -> int:
	var profile: Dictionary = SwordArrayConfig.get_profile(mode)
	var burst_steps: int = get_burst_cycle_length(mode)
	match profile["burst_mode"]:
		"all":
			return remaining_count
		"step_burst":
			if burst_steps == 2:
				if burst_step == 0:
					if remaining_count >= 5:
						return 3
					if remaining_count >= 3:
						return 2
					return 1
				return remaining_count
			var remaining_volleys: int = maxi(1, burst_steps - burst_step)
			return ceili(float(remaining_count) / float(remaining_volleys))
		_:
			return 1


static func get_burst_cycle_length(mode: String) -> int:
	var profile: Dictionary = SwordArrayConfig.get_profile(mode)
	return maxi(int(profile.get("burst_steps", 1)), 1)


static func get_accent_color(state_source) -> Color:
	var morph_state: Dictionary = _resolve_state_source(state_source)
	var from_mode: String = morph_state["visual_from_mode"]
	var to_mode: String = morph_state["visual_to_mode"]
	var from_color: Color = SwordArrayConfig.get_profile(from_mode)["accent_color"]
	if from_mode == to_mode:
		return from_color
	var to_color: Color = SwordArrayConfig.get_profile(to_mode)["accent_color"]
	return from_color.lerp(to_color, morph_state["visual_blend"])


static func get_soft_accent_color(state_source) -> Color:
	var morph_state: Dictionary = _resolve_state_source(state_source)
	var from_mode: String = morph_state["visual_from_mode"]
	var to_mode: String = morph_state["visual_to_mode"]
	var from_color: Color = SwordArrayConfig.get_profile(from_mode)["accent_soft_color"]
	if from_mode == to_mode:
		return from_color
	var to_color: Color = SwordArrayConfig.get_profile(to_mode)["accent_soft_color"]
	return from_color.lerp(to_color, morph_state["visual_blend"])


static func get_fire_effect(main: Node, state_source, fire_count: int) -> Dictionary:
	var morph_state: Dictionary = _resolve_morph_state(main, state_source)
	var from_mode: String = morph_state["visual_from_mode"]
	var to_mode: String = morph_state["visual_to_mode"]
	var from_effect: Dictionary = _get_mode_fire_effect(main, from_mode, fire_count)
	var effect: Dictionary = from_effect
	if from_mode != to_mode:
		var to_effect: Dictionary = _get_mode_fire_effect(main, to_mode, fire_count)
		effect = {
			"position": from_effect["position"].lerp(to_effect["position"], morph_state["visual_blend"]),
			"color": from_effect["color"].lerp(to_effect["color"], morph_state["visual_blend"]),
			"particles": int(round(lerpf(float(from_effect["particles"]), float(to_effect["particles"]), morph_state["visual_blend"]))),
			"shake": lerpf(from_effect["shake"], to_effect["shake"], morph_state["visual_blend"]),
		}
	var preview: Dictionary = get_preview_data(main, morph_state, 1.0)
	match preview["type"]:
		SwordArrayConfig.MODE_PIERCE:
			effect["position"] = preview.get("tip", effect["position"])
		"spear":
			var preview_blend: float = clampf(float(preview.get("blend", 0.0)), 0.0, 1.0)
			var tip_focus: float = clampf(float(preview.get("tip_focus", 0.0)), 0.0, 1.0)
			effect["position"] = preview["tail"].lerp(
				preview["tip"],
				clampf(0.6 + preview_blend * 0.16 + tip_focus * 0.24, 0.0, 1.0)
			)
	return effect


static func _get_mode_fire_effect(main: Node, mode: String, fire_count: int) -> Dictionary:
	var profile: Dictionary = SwordArrayConfig.get_profile(mode)
	var aim_vector: Vector2 = _get_aim_vector(main)
	return {
		"position": main.player["pos"] + aim_vector * profile["fire_offset"],
		"color": profile["accent_color"],
		"particles": mini(profile["fire_particles_cap"], profile["fire_particles_base"] + fire_count * profile["fire_particles_per_shot"]),
		"shake": profile["fire_shake"],
	}


static func _get_aim_vector(main: Node) -> Vector2:
	var aim_vector: Vector2 = main.mouse_world - main.player["pos"]
	if aim_vector.is_zero_approx():
		return Vector2.RIGHT
	return aim_vector.normalized()


static func _build_fan_layer_counts(slot_count: int, layer_count: int) -> Array:
	var weights: Array = []
	match layer_count:
		1:
			weights = [1.0]
		2:
			weights = [0.34, 0.66]
		_:
			weights = [0.18, 0.28, 0.54]
	return _build_weighted_counts(slot_count, weights)


static func _build_weighted_counts(slot_count: int, weights: Array) -> Array:
	var counts: Array = []
	var layer_count: int = maxi(weights.size(), 1)
	var layer_index: int = 0
	while layer_index < layer_count:
		counts.append(1)
		layer_index += 1

	var remaining: int = maxi(slot_count - layer_count, 0)
	if remaining <= 0:
		return counts

	var weight_total: float = 0.0
	for weight in weights:
		weight_total += weight

	var remainders: Array = []
	layer_index = 0
	var assigned: int = 0
	while layer_index < layer_count:
		var exact_extra: float = float(remaining) * (weights[layer_index] / weight_total)
		var base_extra: int = int(floor(exact_extra))
		counts[layer_index] += base_extra
		assigned += base_extra
		remainders.append(exact_extra - float(base_extra))
		layer_index += 1

	while assigned < remaining:
		var best_index: int = 0
		var best_remainder: float = -1.0
		layer_index = 0
		while layer_index < layer_count:
			if remainders[layer_index] > best_remainder:
				best_remainder = remainders[layer_index]
				best_index = layer_index
			layer_index += 1
		counts[best_index] += 1
		remainders[best_index] = -1.0
		assigned += 1

	return counts


static func _locate_fan_slot(slot_index: int, layer_counts: Array) -> Dictionary:
	var offset: int = 0
	var layer_index: int = 0
	while layer_index < layer_counts.size():
		var count_in_layer: int = layer_counts[layer_index]
		if slot_index < offset + count_in_layer:
			return {
				"layer": layer_index,
				"index": slot_index - offset,
				"count": count_in_layer,
			}
		offset += count_in_layer
		layer_index += 1

	return {
		"layer": maxi(layer_counts.size() - 1, 0),
		"index": 0,
		"count": maxi(int(layer_counts.back() if not layer_counts.is_empty() else 1), 1),
	}


static func _resolve_morph_state(main: Node, state_source) -> Dictionary:
	if typeof(state_source) == TYPE_DICTIONARY:
		return SwordArrayConfig.complete_morph_state(state_source)
	if typeof(state_source) == TYPE_STRING:
		return SwordArrayConfig.get_mode_state(state_source)
	return get_morph_state(main)


static func _resolve_state_source(state_source) -> Dictionary:
	if typeof(state_source) == TYPE_DICTIONARY:
		return SwordArrayConfig.complete_morph_state(state_source)
	if typeof(state_source) == TYPE_STRING:
		return SwordArrayConfig.get_mode_state(state_source)
	return SwordArrayConfig.get_mode_state(SwordArrayConfig.MODE_RING)


static func _get_ring_transition_angle_factor(slot_index: int, slot_count: int) -> float:
	if slot_count <= 1:
		return 0.0
	var ratio: float = (float(slot_index) + 0.5) / float(slot_count)
	return lerpf(-1.0, 1.0, ratio)


static func _smoothstep_local(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func get_transition_shape_weight(blend: float) -> float:
	return sin(clampf(blend, 0.0, 1.0) * PI)


static func _get_actual_morph_distance(morph_state: Dictionary) -> float:
	var distances: Dictionary = SwordArrayConfig.get_morph_distances()
	return clampf(
		float(morph_state.get("distance_ratio", 0.0)) * distances["fan_to_pierce_end"],
		0.0,
		distances["fan_to_pierce_end"]
	)


static func _get_band_preview_start_distance(distances: Dictionary) -> float:
	return distances["fan_stable_end"] - FAN_SPEAR_BLEND_BEFORE


static func _get_band_bulb_start_distance(distances: Dictionary) -> float:
	return lerpf(distances["ring_to_fan_end"], distances["fan_stable_end"], BAND_BULB_START_RATIO)


static func _get_band_collapse_start_distance(distances: Dictionary) -> float:
	return lerpf(distances["fan_stable_end"], distances["fan_to_pierce_end"], BAND_COLLAPSE_START_RATIO)


static func _should_use_converging_pierce_geometry(morph_state: Dictionary) -> bool:
	return _get_continuous_pierce_progress(morph_state) >= 0.0


static func _get_fan_preconverge_progress(morph_state: Dictionary) -> float:
	var distances: Dictionary = SwordArrayConfig.get_morph_distances()
	var actual_distance: float = clampf(
		float(morph_state.get("distance_ratio", 0.0)) * distances["fan_to_pierce_end"],
		0.0,
		distances["fan_to_pierce_end"]
	)
	var fan_start: float = distances["ring_to_fan_end"] + RING_FAN_POST_THRESHOLD_PLATEAU
	var fan_end: float = distances["fan_stable_end"] + FAN_SPEAR_BLEND_AFTER
	if actual_distance < fan_start or actual_distance > fan_end:
		return -1.0
	return clampf(
		inverse_lerp(fan_start, fan_end, actual_distance),
		0.0,
		1.0
	)


static func _get_continuous_pierce_progress(morph_state: Dictionary) -> float:
	var distances: Dictionary = SwordArrayConfig.get_morph_distances()
	var actual_distance: float = clampf(
		float(morph_state.get("distance_ratio", 0.0)) * distances["fan_to_pierce_end"],
		0.0,
		distances["fan_to_pierce_end"]
	)
	var spear_start: float = distances["fan_stable_end"] - FAN_SPEAR_BLEND_BEFORE
	if actual_distance < spear_start:
		return -1.0
	return lerpf(
		0.0,
		1.0,
		_smoothstep_local(
			inverse_lerp(spear_start, distances["fan_to_pierce_end"], actual_distance)
		)
	)


static func _get_fan_spear_blend_weight(morph_state: Dictionary) -> float:
	var distances: Dictionary = SwordArrayConfig.get_morph_distances()
	var actual_distance: float = clampf(
		float(morph_state.get("distance_ratio", 0.0)) * distances["fan_to_pierce_end"],
		0.0,
		distances["fan_to_pierce_end"]
	)
	var blend_start: float = distances["fan_stable_end"] - FAN_SPEAR_BLEND_BEFORE
	var blend_end: float = distances["fan_stable_end"] + FAN_SPEAR_BLEND_AFTER
	if actual_distance < blend_start or actual_distance > blend_end:
		return -1.0
	return _smoothstep_local(inverse_lerp(blend_start, blend_end, actual_distance))


static func _get_ring_fan_blend_weight(morph_state: Dictionary) -> float:
	var distances: Dictionary = SwordArrayConfig.get_morph_distances()
	var actual_distance: float = clampf(
		float(morph_state.get("distance_ratio", 0.0)) * distances["fan_to_pierce_end"],
		0.0,
		distances["fan_to_pierce_end"]
	)
	var blend_start: float = distances["ring_to_fan_end"] + RING_FAN_POST_THRESHOLD_PLATEAU - RING_FAN_BLEND_BEFORE
	var blend_end: float = distances["ring_to_fan_end"] + RING_FAN_POST_THRESHOLD_PLATEAU + RING_FAN_BLEND_AFTER
	if actual_distance < blend_start or actual_distance > blend_end:
		return -1.0
	return _smoothstep_local(inverse_lerp(blend_start, blend_end, actual_distance))


static func _sample_spear_preview(preview: Dictionary, ratio: float) -> Dictionary:
	var sections: Array = preview["sections"]
	if sections.is_empty():
		return {
			"forward_offset": 0.0,
			"half_width": 0.0,
			"center": preview["tail"],
		}
	if sections.size() == 1:
		return sections[0]

	var clamped_ratio: float = clampf(ratio, 0.0, 1.0)
	var scaled_index: float = clamped_ratio * float(sections.size() - 1)
	var from_index: int = mini(int(floor(scaled_index)), sections.size() - 1)
	var to_index: int = mini(from_index + 1, sections.size() - 1)
	var local_ratio: float = scaled_index - float(from_index)
	var from_section: Dictionary = sections[from_index]
	var to_section: Dictionary = sections[to_index]
	var forward_offset: float = lerpf(from_section["forward_offset"], to_section["forward_offset"], local_ratio)
	var half_width: float = lerpf(from_section["half_width"], to_section["half_width"], local_ratio)
	return {
		"forward_offset": forward_offset,
		"half_width": half_width,
		"center": preview["tail"] + preview["aim_vector"] * (forward_offset - sections[0]["forward_offset"]),
	}


static func _get_directional_source_slot_index(
	main: Node,
	state_source,
	slot_count: int,
	desired_direction: Vector2
) -> int:
	var morph_state: Dictionary = _resolve_morph_state(main, state_source)
	var target_direction: Vector2 = desired_direction.normalized()
	if target_direction.is_zero_approx():
		target_direction = _get_aim_vector(main)
	var side_vector: Vector2 = target_direction.rotated(PI * 0.5)
	var best_index: int = 0
	var best_alignment: float = -INF
	var best_forward: float = -INF
	var best_lateral: float = INF
	var slot_index: int = 0
	while slot_index < slot_count:
		var slot_position: Vector2 = get_slot_position(main, morph_state, slot_index, slot_count, 1.0)
		var offset: Vector2 = slot_position - main.player["pos"]
		var slot_direction: Vector2 = offset.normalized() if not offset.is_zero_approx() else target_direction
		var alignment: float = slot_direction.dot(target_direction)
		var forward_score: float = offset.dot(target_direction)
		var lateral_score: float = absf(offset.dot(side_vector))
		if alignment > best_alignment + 0.0001:
			best_index = slot_index
			best_alignment = alignment
			best_forward = forward_score
			best_lateral = lateral_score
		elif absf(alignment - best_alignment) <= 0.0001:
			if forward_score > best_forward + 0.01:
				best_index = slot_index
				best_forward = forward_score
				best_lateral = lateral_score
			elif absf(forward_score - best_forward) <= 0.01 and lateral_score < best_lateral:
				best_index = slot_index
				best_lateral = lateral_score
		slot_index += 1
	return best_index


static func _get_symmetric_spread_factor(slot_index: int, slot_count: int) -> float:
	return _get_fan_layout_angle_factor(slot_index, slot_count)


static func _get_diamond_row_weights(row_count: int) -> Array:
	match row_count:
		1:
			return [1.0]
		2:
			return [1.0, 1.4]
		3:
			return [0.9, 1.8, 1.1]
		4:
			return [0.8, 1.8, 1.7, 1.0]
		_:
			return [0.7, 1.5, 2.2, 1.6, 0.9]


static func _get_diamond_row_ratio(row_index: int, row_count: int) -> float:
	if row_count <= 1:
		return 0.5
	return lerpf(0.08, 0.9, float(row_index) / float(row_count - 1))


static func _get_diamond_half_width(preview: Dictionary, row_ratio: float) -> float:
	var shoulder_ratio: float = preview["shoulder_ratio"]
	var shoulder_half_width: float = preview["shoulder_half_width"]
	var tail_half_width: float = preview["tail_half_width"]
	if row_ratio <= shoulder_ratio:
		var grow_ratio: float = inverse_lerp(0.0, shoulder_ratio, row_ratio)
		return lerpf(tail_half_width, shoulder_half_width, grow_ratio)
	var shrink_ratio: float = inverse_lerp(shoulder_ratio, 1.0, row_ratio)
	return lerpf(shoulder_half_width, 0.0, shrink_ratio)


static func _get_fan_layout_angle_factor(slot_index: int, slot_count: int) -> float:
	match slot_count:
		1:
			return 0.0
		2:
			var two_slot_factors := [-0.42, 0.42]
			return two_slot_factors[mini(slot_index, 1)]
		3:
			var three_slot_factors := [0.0, -0.58, 0.58]
			return three_slot_factors[mini(slot_index, 2)]
		4:
			var four_slot_factors := [-1.0, -0.34, 0.34, 1.0]
			return four_slot_factors[mini(slot_index, 3)]
		5:
			var five_slot_factors := [0.0, -0.48, 0.48, -1.0, 1.0]
			return five_slot_factors[mini(slot_index, 4)]
		_:
			var ratio: float = 0.5
			if slot_count > 1:
				ratio = float(slot_index) / float(slot_count - 1)
			return lerpf(-1.0, 1.0, ratio)


static func _get_fan_primary_fire_angle_factor(fire_index: int, fire_count: int) -> float:
	match fire_count:
		1:
			return 0.0
		2:
			var two_shot_factors := [-0.22, 0.22]
			return two_shot_factors[mini(fire_index, 1)]
		_:
			var three_shot_factors := [0.0, -0.34, 0.34]
			return three_shot_factors[mini(fire_index, 2)]


static func _get_fan_outer_fire_angle_factor(fire_index: int, fire_count: int) -> float:
	match fire_count:
		1:
			return 0.0
		2:
			var two_shot_factors := [-0.78, 0.78]
			return two_shot_factors[mini(fire_index, 1)]
		3:
			var three_shot_factors := [-1.0, 0.0, 1.0]
			return three_shot_factors[mini(fire_index, 2)]
		4:
			var four_shot_factors := [-1.0, -0.34, 0.34, 1.0]
			return four_shot_factors[mini(fire_index, 3)]
		_:
			var ratio: float = 0.5
			if fire_count > 1:
				ratio = float(fire_index) / float(fire_count - 1)
			return lerpf(-1.0, 1.0, ratio)


static func _get_fan_fire_angle_factor(mode: String, fire_index: int, fire_count: int, burst_step: int) -> float:
	if get_burst_cycle_length(mode) > 1 and burst_step == 0:
		return _get_fan_primary_fire_angle_factor(fire_index, fire_count)
	return _get_fan_outer_fire_angle_factor(fire_index, fire_count)
