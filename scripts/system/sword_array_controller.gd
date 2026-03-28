extends RefCounted
class_name SwordArrayController

const SwordArrayConfig = preload("res://scripts/system/sword_array_config.gd")
const CONVERGE_SAMPLE_RADIUS_RATIOS := [0.0, 0.18, 0.36, 0.58, 0.78, 0.92, 1.0]
const CONVERGE_SAMPLE_ANGLE_RATIOS := [1.0, 0.88, 0.68, 0.42, 0.2, 0.06, 0.0]
const SPEAR_SAMPLE_FORWARD_RATIOS := [0.0, 0.12, 0.28, 0.48, 0.7, 0.88, 1.0]
const SPEAR_BONUS_WIDTH_SCALES := [0.0, 0.42, 0.9, 1.0, 0.48, 0.12, 0.0]


static func get_mode(main: Node) -> String:
	return get_morph_state(main)["dominant_mode"]


static func get_morph_state(main: Node) -> Dictionary:
	var aim_distance: float = main.player["pos"].distance_to(main.mouse_world)
	return SwordArrayConfig.get_morph_state_for_distance(aim_distance)


static func get_slot_position(main: Node, state_source, slot_index: int, slot_count: int, formation_ratio := 1.0) -> Vector2:
	var morph_state: Dictionary = _resolve_morph_state(main, state_source)
	if _should_use_converging_pierce_geometry(morph_state):
		return _get_fan_to_pierce_slot_position(
			main,
			slot_index,
			slot_count,
			formation_ratio,
			_get_continuous_pierce_progress(morph_state)
		)
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


static func _get_fan_to_pierce_slot_position(main: Node, slot_index: int, slot_count: int, formation_ratio: float, blend: float) -> Vector2:
	var preview: Dictionary = _get_fan_to_pierce_preview(main, formation_ratio, blend)
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


static func get_fire_target(main: Node, state_source, fire_index: int, bullet_pos: Vector2, volley_count := -1, burst_step := 0, total_count := -1) -> Vector2:
	var morph_state: Dictionary = _resolve_morph_state(main, state_source)
	var preview: Dictionary = get_preview_data(main, morph_state, 1.0)
	match preview["type"]:
		"crescent":
			return _get_crescent_fire_target(main, preview, fire_index, bullet_pos, volley_count, burst_step)
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


static func get_preview_data(main: Node, state_source, formation_ratio := 1.0) -> Dictionary:
	var morph_state: Dictionary = _resolve_morph_state(main, state_source)
	if _should_use_converging_pierce_geometry(morph_state):
		return _get_fan_to_pierce_preview(main, formation_ratio, _get_continuous_pierce_progress(morph_state))
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


static func _get_fan_to_pierce_preview(main: Node, formation_ratio: float, blend: float) -> Dictionary:
	var aim_vector: Vector2 = _get_aim_vector(main)
	var side_vector: Vector2 = aim_vector.rotated(PI * 0.5)
	var fan_preview: Dictionary = _get_mode_preview_data(main, SwordArrayConfig.MODE_FAN, formation_ratio)
	var pierce_preview: Dictionary = _get_mode_preview_data(main, SwordArrayConfig.MODE_PIERCE, formation_ratio)
	var section_count: int = CONVERGE_SAMPLE_RADIUS_RATIOS.size()
	var shape_progress: float = _smoothstep_local(blend)
	var bonus_strength: float = get_transition_shape_weight(blend)
	var pierce_start_offset: float = main.player["pos"].distance_to(pierce_preview["start"])
	var pierce_tip_offset: float = main.player["pos"].distance_to(pierce_preview["tip"])
	var pierce_tail_width: float = maxf(pierce_preview["wedge_width"], pierce_preview["half_width"] * 1.35)
	var pierce_widths := [
		pierce_tail_width,
		maxf(pierce_preview["half_width"] * 1.6, 6.0),
		maxf(pierce_preview["half_width"] * 1.3, 5.0),
		maxf(pierce_preview["half_width"] * 0.95, 4.0),
		maxf(pierce_preview["half_width"] * 0.55, 2.0),
		maxf(pierce_preview["half_width"] * 0.18, 0.8),
		0.0,
	]
	var bonus_width: float = maxf(fan_preview["outer_radius"] * 0.16, 18.0) * bonus_strength
	var sections: Array = []
	var left_outline: Array = []
	var right_outline: Array = []
	var section_index: int = 0
	while section_index < section_count:
		var fan_radius: float = lerpf(
			fan_preview["inner_radius"],
			fan_preview["outer_radius"],
			CONVERGE_SAMPLE_RADIUS_RATIOS[section_index]
		)
		var fan_angle_half: float = fan_preview["arc"] * 0.5 * CONVERGE_SAMPLE_ANGLE_RATIOS[section_index]
		var fan_forward: float = cos(fan_angle_half) * fan_radius
		var fan_half_width: float = sin(fan_angle_half) * fan_radius
		var pierce_forward: float = lerpf(
			pierce_start_offset,
			pierce_tip_offset,
			SPEAR_SAMPLE_FORWARD_RATIOS[section_index]
		)
		var half_width: float = lerpf(fan_half_width, pierce_widths[section_index], shape_progress)
		half_width += bonus_width * SPEAR_BONUS_WIDTH_SCALES[section_index]
		var forward_offset: float = lerpf(fan_forward, pierce_forward, shape_progress)
		var center: Vector2 = main.player["pos"] + aim_vector * forward_offset
		var left_point: Vector2 = center - side_vector * half_width
		var right_point: Vector2 = center + side_vector * half_width
		sections.append({
			"ratio": float(section_index) / float(maxi(section_count - 1, 1)),
			"forward_offset": forward_offset,
			"half_width": half_width,
			"center": center,
			"left": left_point,
			"right": right_point,
		})
		left_outline.append(left_point)
		right_outline.append(right_point)
		section_index += 1

	return {
		"type": "spear",
		"blend": blend,
		"aim_vector": aim_vector,
		"side_vector": side_vector,
		"sections": sections,
		"left_outline": left_outline,
		"right_outline": right_outline,
		"tail": sections.front()["center"],
		"tip": sections.back()["center"],
		"start": sections.front()["center"],
		"end": sections[maxi(sections.size() - 2, 0)]["center"],
		"tip_radius": lerpf(5.0, pierce_preview["tip_radius"], shape_progress),
	}


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
	if from_mode == to_mode:
		return from_effect
	var to_effect: Dictionary = _get_mode_fire_effect(main, to_mode, fire_count)
	return {
		"position": from_effect["position"].lerp(to_effect["position"], morph_state["visual_blend"]),
		"color": from_effect["color"].lerp(to_effect["color"], morph_state["visual_blend"]),
		"particles": int(round(lerpf(float(from_effect["particles"]), float(to_effect["particles"]), morph_state["visual_blend"]))),
		"shake": lerpf(from_effect["shake"], to_effect["shake"], morph_state["visual_blend"]),
	}


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


static func _should_use_converging_pierce_geometry(morph_state: Dictionary) -> bool:
	return _get_continuous_pierce_progress(morph_state) >= 0.0


static func _get_continuous_pierce_progress(morph_state: Dictionary) -> float:
	var distances: Dictionary = SwordArrayConfig.get_morph_distances()
	var actual_distance: float = clampf(
		float(morph_state.get("distance_ratio", 0.0)) * distances["fan_to_pierce_end"],
		0.0,
		distances["fan_to_pierce_end"]
	)
	if actual_distance < distances["ring_to_fan_end"]:
		return -1.0
	return clampf(
		inverse_lerp(distances["ring_to_fan_end"], distances["fan_to_pierce_end"], actual_distance),
		0.0,
		1.0
	)


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
