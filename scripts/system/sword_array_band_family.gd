extends RefCounted
class_name SwordArrayBandFamily

const SwordArrayConfig = preload("res://scripts/system/sword_array_config.gd")
const CONVERGE_SAMPLE_RADIUS_RATIOS := [0.0, 0.14, 0.28, 0.44, 0.6, 0.76, 0.9, 1.0]
const BAND_COLLAPSE_WIDTH_SCALES := [0.94, 0.98, 0.96, 0.88, 0.7, 0.44, 0.2, 0.05]
const BAND_COLLAPSE_FORWARD_BLEND_SCALES := [0.0, 0.04, 0.18, 0.32, 0.52, 0.72, 0.86, 1.0]
const BAND_COLLAPSE_FORWARD_BONUS_SCALES := [0.0, 0.0, 0.03, 0.06, 0.1, 0.14, 0.2, 0.24]
const BAND_LINE_BLEND_SCALES := [1.0, 1.04, 1.12, 1.16, 1.12, 1.08, 1.04, 1.0]
const BAND_LINE_WIDTH_SCALES := [0.36, 0.3, 0.24, 0.16, 0.1, 0.05, 0.02, 0.0]
const BAND_LINE_FORWARD_RATIOS := [0.0, 0.08, 0.18, 0.32, 0.5, 0.68, 0.86, 1.0]
const BAND_TO_LINE_SPINE_START := 0.72
const BAND_TO_LINE_TIP_START := 0.9


static func get_preset_runtime_for_state(state: Dictionary) -> Dictionary:
	return SwordArrayConfig.get_shape_preset_runtime(state)


static func build_arc_preview_from_runtime(
	main: Node,
	preset_runtime: Dictionary,
	formation_ratio: float,
	preview_type: String,
	preview_state,
	aim_vector: Vector2
) -> Dictionary:
	var active_ratio: float = _smoothstep_local(clampf(formation_ratio, 0.0, 1.0))
	var blended_preset: Dictionary = preset_runtime.get("blended", {})
	var outer_radius: float = maxf(float(blended_preset.get("forward_length", 0.0)) * lerpf(0.72, 1.0, active_ratio), 1.0)
	var band_thickness: float = maxf(float(blended_preset.get("band_thickness", 0.0)) * lerpf(0.52, 1.0, active_ratio), 1.0)
	var inner_radius: float = maxf(outer_radius - band_thickness, 0.0)
	var center_offset: float = float(blended_preset.get("center_offset", 0.0)) * lerpf(0.42, 1.0, active_ratio)
	var arc: float = clampf(float(blended_preset.get("arc", 0.0)), 0.0, TAU)
	var center: Vector2 = main.player["pos"] + aim_vector * center_offset
	var side_vector: Vector2 = aim_vector.rotated(PI * 0.5)
	var tail: Vector2 = center + aim_vector * inner_radius
	var tip: Vector2 = center + aim_vector * outer_radius
	return {
		"type": preview_type,
		"blend": clampf(float(preset_runtime.get("blend", 0.0)), 0.0, 1.0),
		"center": center,
		"angle": aim_vector.angle(),
		"outer_radius": outer_radius,
		"inner_radius": inner_radius,
		"arc": arc,
		"inner_arc": arc,
		"aim_vector": aim_vector,
		"side_vector": side_vector,
		"tail": tail,
		"tip": tip,
		"start": tail,
		"end": tip,
		"outer_cap_control": tip,
		"inner_cap_control": tail,
		"preview_state": preview_state,
	}


static func build_runtime(morph_state: Dictionary, geometry: Dictionary, actual_distance: float, preview_type: String) -> Dictionary:
	var preset_runtime: Dictionary = get_preset_runtime_for_state(morph_state)
	var morph_profile: Dictionary = preset_runtime.get("morph_profile", {})
	var spine_points: Array = build_spine_points(geometry)
	var section_centers: Array = extract_section_centers(geometry.get("band_sections", []))
	return {
		"runtime": {
			"family": SwordArrayConfig.FORMATION_FAMILY_BAND,
			"from_preset_id": preset_runtime.get("from_id", geometry.get("preset_from", "")),
			"to_preset_id": preset_runtime.get("to_id", geometry.get("preset_to", "")),
			"active_preset_id": preset_runtime.get("active_id", geometry.get("preset_to", "")),
			"blend": preset_runtime.get("blend", geometry.get("preset_blend", 0.0)),
			"morph_profile_id": morph_profile.get("id", ""),
		},
		"active_preset_id": preset_runtime.get("active_id", geometry.get("preset_to", "")),
		"preset_from_data": preset_runtime.get("from", {}),
		"preset_to_data": preset_runtime.get("to", {}),
		"blended_preset": preset_runtime.get("blended", {}),
		"parameter_blends": preset_runtime.get("parameter_blends", {}),
		"morph_profile": morph_profile,
		"morph_profile_id": morph_profile.get("id", ""),
		"section_centers": section_centers,
		"spine_points": spine_points,
		"debug": {
			"family": SwordArrayConfig.FORMATION_FAMILY_BAND,
			"band_stage": geometry.get("band_stage", "unknown"),
			"section_count": section_centers.size(),
			"actual_distance": actual_distance,
			"distance_ratio": float(morph_state.get("distance_ratio", 0.0)),
			"preset_from": preset_runtime.get("from_id", ""),
			"preset_to": preset_runtime.get("to_id", ""),
			"active_preset": preset_runtime.get("active_id", ""),
			"preview_type": preview_type,
		},
	}


static func build_spine_points(geometry: Dictionary) -> Array:
	var points: Array = []
	_append_unique_point(points, geometry.get("tail", geometry.get("center", Vector2.ZERO)))
	for center in extract_section_centers(geometry.get("band_sections", [])):
		_append_unique_point(points, center)
	_append_unique_point(points, geometry.get("tip", geometry.get("end", geometry.get("center", Vector2.ZERO))))
	if points.size() >= 2:
		return points
	return [geometry.get("start", Vector2.ZERO), geometry.get("tip", Vector2.ZERO)]


static func extract_section_centers(sections: Array) -> Array:
	var centers: Array = []
	for section in sections:
		if section.has("center"):
			centers.append(section["center"])
	return centers


static func build_band_sections_for_preview(origin: Vector2, preview_type: String, preview: Dictionary, aim_vector: Vector2, side_vector: Vector2) -> Array:
	match preview_type:
		"crescent":
			if preview.get("has_profile_sections", false):
				return preview.get("sections", [])
			return []
		SwordArrayConfig.MODE_FAN:
			if preview.get("has_profile_sections", false):
				return preview.get("sections", [])
			return build_fan_sections(origin, preview)
		SwordArrayConfig.MODE_PIERCE:
			return build_line_band_sections(origin, aim_vector, side_vector, preview, BAND_LINE_FORWARD_RATIOS.size())
		_:
			return []


static func build_fan_sections(origin: Vector2, preview: Dictionary) -> Array:
	if preview.get("has_profile_sections", false):
		return preview["sections"]
	var aim_vector: Vector2 = Vector2.RIGHT.rotated(preview["angle"])
	var section_origin: Vector2 = preview.get("center", origin)
	var angle_scales: Array = []
	var sample_index: int = 0
	while sample_index < CONVERGE_SAMPLE_RADIUS_RATIOS.size():
		angle_scales.append(get_fan_section_arc_scale(CONVERGE_SAMPLE_RADIUS_RATIOS[sample_index]))
		sample_index += 1
	return build_fan_profile_sections(
		section_origin,
		aim_vector,
		aim_vector.rotated(PI * 0.5),
		preview["inner_radius"],
		preview["outer_radius"],
		preview["arc"],
		angle_scales
	)["sections"]


static func build_section_fan_preview_from_arc_preview(
	origin: Vector2,
	preview: Dictionary,
	preview_state,
	blended_preset: Dictionary = {}
) -> Dictionary:
	return _build_section_arc_preview_from_arc_preview(
		SwordArrayConfig.MODE_FAN,
		origin,
		preview,
		preview_state,
		blended_preset
	)


static func build_section_crescent_preview_from_arc_preview(
	origin: Vector2,
	preview: Dictionary,
	preview_state,
	blended_preset: Dictionary = {}
) -> Dictionary:
	return _build_section_arc_preview_from_arc_preview(
		"crescent",
		origin,
		preview,
		preview_state,
		blended_preset
	)


static func _build_section_arc_preview_from_arc_preview(
	preview_type: String,
	origin: Vector2,
	preview: Dictionary,
	preview_state,
	blended_preset: Dictionary = {}
) -> Dictionary:
	if preview.get("has_profile_sections", false):
		return preview
	var aim_vector: Vector2 = preview.get("aim_vector", Vector2.RIGHT.rotated(float(preview.get("angle", 0.0))))
	var side_vector: Vector2 = preview.get("side_vector", aim_vector.rotated(PI * 0.5))
	var profile_data: Dictionary = build_fan_profile_sections(
		preview.get("center", origin),
		aim_vector,
		side_vector,
		float(preview.get("inner_radius", 0.0)),
		float(preview.get("outer_radius", 0.0)),
		float(preview.get("arc", 0.0)),
		_build_default_fan_angle_scales()
	)
	var sections: Array = profile_data.get("sections", [])
	if sections.is_empty():
		return preview
	return build_section_preview(
		preview_type,
		aim_vector,
		side_vector,
		sections,
		{
			"blend": float(preview.get("blend", 0.0)),
			"angle": float(preview.get("angle", aim_vector.angle())),
			"arc": float(preview.get("arc", 0.0)),
			"inner_arc": float(preview.get("inner_arc", preview.get("arc", 0.0))),
			"inner_radius": float(sections[0]["forward_offset"]),
			"outer_radius": float(sections[sections.size() - 1]["forward_offset"]),
			"center": preview.get("center", origin),
			"outer_cap_control": preview.get("center", origin) + aim_vector * float(preview.get("outer_radius", 0.0)),
			"inner_cap_control": preview.get("center", origin) + aim_vector * float(preview.get("inner_radius", 0.0)),
			"preview_state": preview_state,
			"has_profile_sections": true,
			"edge_curve_strength": 1.0,
			"spine_focus": float(blended_preset.get("spine_emphasis", 0.0)),
			"tip_focus": float(blended_preset.get("tip_emphasis", 0.0)),
			"tip_radius": 0.0,
		}
	)


static func get_fan_section_arc_scale(radius_ratio: float) -> float:
	return lerpf(0.52, 1.0, clampf(radius_ratio, 0.0, 1.0))


static func _build_default_fan_angle_scales() -> Array:
	var angle_scales: Array = []
	var sample_index: int = 0
	while sample_index < CONVERGE_SAMPLE_RADIUS_RATIOS.size():
		angle_scales.append(get_fan_section_arc_scale(CONVERGE_SAMPLE_RADIUS_RATIOS[sample_index]))
		sample_index += 1
	return angle_scales


static func build_fan_profile_sections(
	origin: Vector2,
	aim_vector: Vector2,
	side_vector: Vector2,
	inner_radius: float,
	outer_radius: float,
	arc: float,
	angle_scales: Array
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
		var forward_offset: float = cos(sample_half_angle) * sample_radius
		var half_width: float = sin(sample_half_angle) * sample_radius
		var center: Vector2 = origin + aim_vector * forward_offset
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


static func build_sections_from_profile_data(
	origin: Vector2,
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
		var center: Vector2 = origin + aim_vector * forward_offset
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


static func build_section_preview(
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


static func get_forward_convex_cap_control(aim_vector: Vector2, section: Dictionary, min_push: float, push_scale: float) -> Vector2:
	return section["center"] + aim_vector * maxf(float(section["half_width"]) * push_scale, min_push)


static func blend_sections(from_sections: Array, to_sections: Array, blend: float, blend_scales: Array = []) -> Array:
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


static func build_collapse_band_sections(
	origin: Vector2,
	aim_vector: Vector2,
	side_vector: Vector2,
	fan_sections: Array,
	pierce_preview: Dictionary,
	section_count: int
) -> Array:
	var forward_offsets: Array = []
	var half_widths: Array = []
	var pierce_start_offset: float = origin.distance_to(pierce_preview["start"])
	var pierce_tip_offset: float = origin.distance_to(pierce_preview["tip"])
	var forward_bonus: float = maxf((pierce_tip_offset - pierce_start_offset) * 0.12, 12.0)
	var section_index: int = 0
	while section_index < section_count:
		var fan_section: Dictionary = fan_sections[section_index]
		var fan_center: Vector2 = fan_section.get("center", origin)
		var fan_forward: float = (fan_center - origin).dot(aim_vector)
		var fan_half_width: float = float(fan_section["half_width"])
		var line_forward: float = lerpf(
			pierce_start_offset,
			pierce_tip_offset,
			float(BAND_LINE_FORWARD_RATIOS[section_index])
		)
		var forward_target: float = lerpf(
			fan_forward,
			line_forward,
			float(BAND_COLLAPSE_FORWARD_BLEND_SCALES[section_index])
		)
		forward_target = minf(
			pierce_tip_offset,
			forward_target + forward_bonus * float(BAND_COLLAPSE_FORWARD_BONUS_SCALES[section_index])
		)
		var width_floor: float = maxf(pierce_preview["half_width"] * (0.9 - float(BAND_LINE_WIDTH_SCALES[section_index]) * 0.45), 0.9)
		var half_width_target: float = maxf(
			fan_half_width * float(BAND_COLLAPSE_WIDTH_SCALES[section_index]),
			width_floor
		)
		forward_offsets.append(forward_target)
		half_widths.append(half_width_target)
		section_index += 1
	return build_sections_from_profile_data(origin, aim_vector, side_vector, forward_offsets, half_widths)


static func build_line_band_sections(
	origin: Vector2,
	aim_vector: Vector2,
	side_vector: Vector2,
	pierce_preview: Dictionary,
	section_count: int
) -> Array:
	var forward_offsets: Array = []
	var half_widths: Array = []
	var pierce_start_offset: float = origin.distance_to(pierce_preview["start"])
	var pierce_tip_offset: float = origin.distance_to(pierce_preview["tip"])
	var line_half_width: float = maxf(pierce_preview["half_width"] * 0.72, 1.0)
	var section_index: int = 0
	while section_index < section_count:
		forward_offsets.append(lerpf(
			pierce_start_offset,
			pierce_tip_offset,
			float(BAND_LINE_FORWARD_RATIOS[section_index])
		))
		half_widths.append(line_half_width * float(BAND_LINE_WIDTH_SCALES[section_index]))
		section_index += 1
	return build_sections_from_profile_data(origin, aim_vector, side_vector, forward_offsets, half_widths)


static func build_fan_layer_counts(slot_count: int, layer_count: int) -> Array:
	var weights: Array = []
	match layer_count:
		1:
			weights = [1.0]
		2:
			weights = [0.34, 0.66]
		_:
			weights = [0.18, 0.28, 0.54]
	return _build_weighted_counts(slot_count, weights)


static func locate_fan_slot(slot_index: int, layer_counts: Array) -> Dictionary:
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


static func get_fan_layout_angle_factor(slot_index: int, slot_count: int) -> float:
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


static func get_symmetric_spread_factor(slot_index: int, slot_count: int) -> float:
	return get_fan_layout_angle_factor(slot_index, slot_count)


static func sample_spear_preview(preview: Dictionary, ratio: float) -> Dictionary:
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


static func sample_band_geometry_section(geometry: Dictionary, ratio: float) -> Dictionary:
	var sections: Array = geometry.get("band_sections", [])
	if sections.is_empty():
		return {
			"forward_offset": 0.0,
			"half_width": 0.0,
			"center": geometry.get("tail", Vector2.ZERO),
		}
	var preview_like := {
		"sections": sections,
		"tail": geometry.get("tail", Vector2.ZERO),
		"aim_vector": geometry.get("aim_vector", Vector2.RIGHT),
	}
	return sample_spear_preview(preview_like, ratio)


static func get_slot_position_from_geometry(geometry: Dictionary, slot_index: int, slot_count: int) -> Vector2:
	var clamped_count: int = maxi(slot_count, 1)
	var fan_profile: Dictionary = SwordArrayConfig.get_profile(SwordArrayConfig.MODE_FAN)
	var fan_layer_count: int = mini(int(fan_profile.get("depth_layers", 3)), clamped_count)
	var fan_layer_counts: Array = build_fan_layer_counts(clamped_count, fan_layer_count)
	var fan_slot: Dictionary = locate_fan_slot(slot_index, fan_layer_counts)
	var layer_ratio: float = 1.0
	if fan_layer_count > 1:
		layer_ratio = float(fan_slot["layer"]) / float(fan_layer_count - 1)
	var preview_type: String = String(geometry.get("preview_type", geometry.get("dominant_mode", SwordArrayConfig.MODE_RING)))
	match preview_type:
		"crescent":
			if bool(geometry.get("has_profile_sections", false)) and not geometry.get("band_sections", []).is_empty():
				return _get_layered_band_slot_position_from_geometry(geometry, fan_slot, layer_ratio)
			return _get_arc_band_slot_position_from_geometry(geometry, fan_slot, layer_ratio)
		SwordArrayConfig.MODE_FAN:
			if not geometry.get("band_sections", []).is_empty():
				return _get_layered_band_slot_position_from_geometry(geometry, fan_slot, layer_ratio)
			return _get_fan_slot_position_from_geometry(geometry, fan_slot, layer_ratio)
		_:
			return geometry.get("center", Vector2.ZERO)


static func get_pierce_launch_origin_from_geometry(geometry: Dictionary, bullet_pos: Vector2) -> Vector2:
	var launch_origin: Vector2 = geometry.get("tip", bullet_pos)
	var tip_dir: Vector2 = launch_origin - geometry.get("start", bullet_pos)
	if not tip_dir.is_zero_approx():
		launch_origin -= tip_dir.normalized() * maxf(float(geometry.get("tip_radius", 0.0)), 2.0) * 0.35
	return launch_origin


static func get_spear_launch_origin_from_geometry(geometry: Dictionary, bullet_pos: Vector2) -> Vector2:
	var launch_origin: Vector2 = bullet_pos
	var tip: Vector2 = get_pierce_launch_origin_from_geometry(geometry, bullet_pos)
	var tip_focus: float = float(geometry.get("tip_focus", 0.0))
	var blend: float = float(geometry.get("blend", 0.0))
	var launch_blend: float = _smoothstep_local(maxf(tip_focus, blend * 0.78))
	return launch_origin.lerp(tip, launch_blend)


static func get_crescent_fire_target_from_geometry(
	geometry: Dictionary,
	angle_factor: float,
	bullet_pos: Vector2,
	player_pos: Vector2,
	fallback_direction: Vector2
) -> Vector2:
	var center: Vector2 = geometry.get("center", player_pos)
	var outer_radius: float = float(geometry.get("outer_radius", 0.0))
	var fire_angle: float = float(geometry.get("angle", 0.0)) + angle_factor * float(geometry.get("arc", 0.0)) * 0.5
	var anchor: Vector2 = center + Vector2.RIGHT.rotated(fire_angle) * outer_radius
	var fire_dir: Vector2 = bullet_pos - center
	if fire_dir.is_zero_approx():
		fire_dir = anchor - center
	if fire_dir.is_zero_approx():
		fire_dir = fallback_direction
	return center + fire_dir.normalized() * (outer_radius + 180.0)


static func get_fan_fire_target_from_geometry(
	geometry: Dictionary,
	angle_factor: float,
	bullet_pos: Vector2,
	player_pos: Vector2
) -> Vector2:
	var center: Vector2 = geometry.get("center", player_pos)
	if bool(geometry.get("has_profile_sections", false)):
		var sampled: Dictionary = sample_band_geometry_section(geometry, 0.74 + (1.0 - absf(angle_factor)) * 0.16)
		var anchor: Vector2 = sampled["center"] + geometry.get("side_vector", Vector2.DOWN) * sampled["half_width"] * angle_factor
		var radial_dir: Vector2 = bullet_pos - player_pos
		if radial_dir.is_zero_approx():
			radial_dir = anchor - player_pos
		if radial_dir.is_zero_approx():
			radial_dir = geometry.get("aim_vector", Vector2.RIGHT)
		var forward_dir: Vector2 = geometry.get("outer_cap_control", geometry.get("tip", anchor)) - anchor
		if forward_dir.is_zero_approx():
			forward_dir = geometry.get("aim_vector", Vector2.RIGHT)
		var preview_blend: float = float(geometry.get("blend", 0.0))
		var spine_focus: float = float(geometry.get("spine_focus", 0.0))
		var tip_focus: float = float(geometry.get("tip_focus", 0.0))
		var axis_align: float = clampf(maxf(spine_focus, maxf(tip_focus, preview_blend * 0.6)), 0.0, 1.0)
		var fire_dir: Vector2 = radial_dir.normalized().lerp(forward_dir.normalized(), axis_align)
		if fire_dir.is_zero_approx():
			fire_dir = forward_dir
		if fire_dir.is_zero_approx():
			fire_dir = radial_dir
		if fire_dir.is_zero_approx():
			fire_dir = geometry.get("aim_vector", Vector2.RIGHT)
		return anchor + fire_dir.normalized() * 180.0
	var fire_angle: float = float(geometry.get("angle", 0.0)) + angle_factor * float(geometry.get("arc", 0.0)) * 0.5
	var fire_dir: Vector2 = bullet_pos - player_pos
	if fire_dir.is_zero_approx():
		fire_dir = Vector2.RIGHT.rotated(fire_angle)
	return center + fire_dir.normalized() * (float(geometry.get("outer_radius", 0.0)) + 180.0)


static func build_unified_fan_pierce_preview(
	main: Node,
	morph_state: Dictionary,
	formation_ratio: float,
	actual_distance: float,
	band_start: float,
	collapse_start: float,
	band_end: float,
	preset_runtime: Dictionary,
	pierce_preview: Dictionary,
	aim_vector: Vector2
) -> Dictionary:
	var blended_preset: Dictionary = preset_runtime.get("blended", {})
	var parameter_blends: Dictionary = preset_runtime.get("parameter_blends", {})
	var start_preset: Dictionary = preset_runtime.get("from", blended_preset)
	var stable_fan_runtime := {
		"blend": 0.0,
		"from": start_preset,
		"to": start_preset,
		"blended": start_preset,
		"from_id": preset_runtime.get("from_id", ""),
		"to_id": preset_runtime.get("from_id", ""),
		"active_id": preset_runtime.get("from_id", ""),
		"parameter_blends": {},
		"morph_profile": preset_runtime.get("morph_profile", {}),
	}
	var stable_fan_preview: Dictionary = build_arc_preview_from_runtime(
		main,
		stable_fan_runtime,
		formation_ratio,
		SwordArrayConfig.MODE_FAN,
		morph_state,
		aim_vector
	)

	var full_progress: float = clampf(inverse_lerp(band_start, band_end, actual_distance), 0.0, 1.0)
	var line_blend: float = _smoothstep_local(inverse_lerp(collapse_start, band_end, actual_distance))
	var early_line_hint: float = _smoothstep_local(inverse_lerp(collapse_start - 16.0, collapse_start + 8.0, actual_distance))
	var spine_focus: float = clampf(maxf(
		float(blended_preset.get("spine_emphasis", 0.0)),
		lerpf(early_line_hint * 0.12, 1.0, _smoothstep_local(inverse_lerp(BAND_TO_LINE_SPINE_START, 1.0, line_blend)))
	), 0.0, 1.0)
	var tip_focus: float = clampf(maxf(
		float(blended_preset.get("tip_emphasis", 0.0)),
		lerpf(early_line_hint * 0.08, 1.0, _smoothstep_local(inverse_lerp(BAND_TO_LINE_TIP_START, 1.0, line_blend)))
	), 0.0, 1.0)

	var target_arc: float = maxf(float(blended_preset.get("arc", 0.08)), 0.02)
	var stable_arc: float = float(stable_fan_preview.get("arc", target_arc))
	var stable_center_offset: float = stable_fan_preview.get("center", main.player["pos"]).distance_to(main.player["pos"])
	var target_center_offset: float = 0.0
	var stable_inner_radius: float = float(stable_fan_preview.get("inner_radius", 0.0))
	var stable_outer_radius: float = float(stable_fan_preview.get("outer_radius", 0.0))
	var target_inner_radius: float = main.player["pos"].distance_to(pierce_preview["start"])
	var target_outer_radius: float = main.player["pos"].distance_to(pierce_preview["tip"])
	var arc_blend: float = clampf(float(parameter_blends.get("arc", full_progress)), 0.0, 1.0)
	var radius_blend: float = clampf(maxf(
		float(parameter_blends.get("forward_length", full_progress)),
		float(parameter_blends.get("band_thickness", full_progress)) * 0.42
	), 0.0, 1.0)
	var center_blend: float = clampf(maxf(
		float(parameter_blends.get("center_offset", full_progress)),
		radius_blend * 0.72
	), 0.0, 1.0)
	var preview_arc: float = lerpf(stable_arc, target_arc, arc_blend)
	var preview_inner_radius: float = lerpf(stable_inner_radius, target_inner_radius, radius_blend)
	var preview_outer_radius: float = lerpf(stable_outer_radius, target_outer_radius, radius_blend)
	var preview_center_offset: float = lerpf(stable_center_offset, target_center_offset, center_blend)
	var preview_center: Vector2 = main.player["pos"] + aim_vector * preview_center_offset

	return {
		"type": SwordArrayConfig.MODE_FAN,
		"blend": full_progress,
		"center": preview_center,
		"angle": aim_vector.angle(),
		"outer_radius": preview_outer_radius,
		"inner_radius": preview_inner_radius,
		"arc": preview_arc,
		"inner_arc": preview_arc,
		"aim_vector": aim_vector,
		"side_vector": aim_vector.rotated(PI * 0.5),
		"tail": preview_center + aim_vector * preview_inner_radius,
		"tip": preview_center + aim_vector * preview_outer_radius,
		"start": preview_center + aim_vector * preview_inner_radius,
		"end": preview_center + aim_vector * preview_outer_radius,
		"outer_cap_control": preview_center + aim_vector * preview_outer_radius,
		"inner_cap_control": preview_center + aim_vector * preview_inner_radius,
		"preview_state": morph_state,
		"spine_focus": spine_focus,
		"tip_focus": tip_focus,
		"tip_radius": lerpf(
		pierce_preview["tip_radius"] * 0.08 * early_line_hint,
		pierce_preview["tip_radius"] * 0.18,
		line_blend
		),
		"edge_curve_strength": lerpf(1.0, 0.42, line_blend),
		"has_profile_sections": false,
	}


static func _get_layered_band_slot_position_from_geometry(geometry: Dictionary, fan_slot: Dictionary, layer_ratio: float) -> Vector2:
	var sampled: Dictionary = sample_band_geometry_section(geometry, layer_ratio)
	var side_factor: float = get_fan_layout_angle_factor(fan_slot["index"], fan_slot["count"])
	return sampled["center"] + geometry["side_vector"] * sampled["half_width"] * side_factor


static func _get_arc_band_slot_position_from_geometry(geometry: Dictionary, fan_slot: Dictionary, layer_ratio: float) -> Vector2:
	var layer_radius: float = lerpf(float(geometry.get("inner_radius", 0.0)), float(geometry.get("outer_radius", 0.0)), layer_ratio)
	var layer_arc: float = lerpf(float(geometry.get("inner_arc", 0.0)), float(geometry.get("arc", 0.0)), layer_ratio)
	var angle_factor: float = get_symmetric_spread_factor(fan_slot["index"], fan_slot["count"])
	return geometry.get("center", Vector2.ZERO) + Vector2.RIGHT.rotated(float(geometry.get("angle", 0.0)) + angle_factor * layer_arc * 0.5) * layer_radius


static func _get_fan_slot_position_from_geometry(geometry: Dictionary, fan_slot: Dictionary, layer_ratio: float) -> Vector2:
	if bool(geometry.get("has_profile_sections", false)):
		var sampled: Dictionary = sample_band_geometry_section(geometry, layer_ratio)
		var side_factor: float = get_fan_layout_angle_factor(fan_slot["index"], fan_slot["count"])
		return sampled["center"] + geometry.get("side_vector", Vector2.DOWN) * sampled["half_width"] * side_factor
	var layer_radius: float = lerpf(float(geometry.get("inner_radius", 0.0)), float(geometry.get("outer_radius", 0.0)), layer_ratio)
	var layer_arc: float = float(geometry.get("arc", 0.0)) * lerpf(0.52, 1.0, layer_ratio)
	var angle_factor: float = get_fan_layout_angle_factor(fan_slot["index"], fan_slot["count"])
	return geometry.get("center", Vector2.ZERO) + Vector2.RIGHT.rotated(float(geometry.get("angle", 0.0)) + angle_factor * layer_arc * 0.5) * layer_radius


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


static func _append_unique_point(points: Array, point: Vector2) -> void:
	if points.is_empty():
		points.append(point)
		return
	if points[points.size() - 1].distance_to(point) > 0.01:
		points.append(point)


static func _smoothstep_local(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
