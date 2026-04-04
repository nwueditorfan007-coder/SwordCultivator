extends RefCounted
class_name SwordArrayController

const SwordArrayConfig = preload("res://scripts/system/sword_array_config.gd")
const SwordArrayBandFamily = preload("res://scripts/system/sword_array_band_family.gd")
const RING_FAN_BAND_FORWARD_PULL := 0.14
const RING_FAN_BAND_FORWARD_RETURN_START := 0.54
const RING_FAN_ARC_SHRINK_START := 0.06
const RING_FAN_OUTER_GROWTH_START := 0.18
const RING_FAN_THICKNESS_GROWTH_START := 0.48
const BAND_COLLAPSE_START_RATIO := 0.62
static func get_mode(main: Node) -> String:
	return get_morph_state(main)["dominant_mode"]


static func get_morph_state(main: Node) -> Dictionary:
	var aim_distance: float = main.player["pos"].distance_to(main.mouse_world)
	return SwordArrayConfig.get_morph_state_for_distance(aim_distance)


static func get_geometry_result(main: Node, state_source, formation_ratio := 1.0) -> Dictionary:
	var morph_state: Dictionary = _resolve_morph_state(main, state_source)
	var preview: Dictionary = _build_preview_data(main, morph_state, formation_ratio)
	return _build_geometry_result(main, morph_state, preview)


static func get_slot_position(main: Node, state_source, slot_index: int, slot_count: int, formation_ratio := 1.0) -> Vector2:
	var morph_state: Dictionary = _resolve_morph_state(main, state_source)
	var geometry: Dictionary = get_geometry_result(main, morph_state, formation_ratio)
	return _get_slot_position_from_geometry(main, morph_state, geometry, slot_index, slot_count, formation_ratio)


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


static func get_fire_source_snapshot_index(
	main: Node,
	state_source,
	source_positions: Array,
	fire_sequence_index := 0,
	volley_count := -1,
	burst_step := 0,
	total_count := -1
) -> int:
	if source_positions.is_empty():
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
	return _get_directional_source_index_from_positions(main.player["pos"], source_positions, desired_direction)


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
			var fan_layer_counts: Array = SwordArrayBandFamily.build_fan_layer_counts(clamped_count, fan_layer_count)
			var fan_slot: Dictionary = SwordArrayBandFamily.locate_fan_slot(slot_index, fan_layer_counts)
			var layer_ratio: float = 1.0
			if fan_layer_count > 1:
				layer_ratio = float(fan_slot["layer"]) / float(fan_layer_count - 1)
			var layer_radius: float = lerpf(fan_inner_radius, fan_outer_radius, layer_ratio)
			var layer_arc: float = fan_arc * lerpf(0.5, 1.0, layer_ratio)
			var layer_slot_count: int = fan_slot["count"]
			var fan_angle: float = SwordArrayBandFamily.get_fan_layout_angle_factor(fan_slot["index"], layer_slot_count) * layer_arc * 0.5
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


static func _get_slot_position_from_geometry(
	main: Node,
	morph_state: Dictionary,
	geometry: Dictionary,
	slot_index: int,
	slot_count: int,
	formation_ratio: float
) -> Vector2:
	if geometry.get("family", "") == SwordArrayConfig.FORMATION_FAMILY_BAND:
		return _get_band_slot_position_from_geometry(main, geometry, morph_state, slot_index, slot_count, formation_ratio)
	return _get_mode_slot_position(main, morph_state["dominant_mode"], slot_index, slot_count, formation_ratio)


static func _get_band_slot_position_from_geometry(
	main: Node,
	geometry: Dictionary,
	morph_state: Dictionary,
	slot_index: int,
	slot_count: int,
	formation_ratio: float
) -> Vector2:
	match _get_geometry_preview_type(geometry):
		SwordArrayConfig.MODE_RING:
			return _get_mode_slot_position(main, SwordArrayConfig.MODE_RING, slot_index, slot_count, formation_ratio)
		"crescent":
			var arc_position: Vector2 = SwordArrayBandFamily.get_slot_position_from_geometry(geometry, slot_index, slot_count)
			var preview_state = geometry.get("preview_state", {})
			if typeof(preview_state) == TYPE_DICTIONARY:
				var from_mode: String = String(preview_state.get("visual_from_mode", ""))
				var to_mode: String = String(preview_state.get("visual_to_mode", ""))
				if from_mode == SwordArrayConfig.MODE_RING and to_mode == SwordArrayConfig.MODE_FAN:
					var ring_position: Vector2 = _get_mode_slot_position(
						main,
						SwordArrayConfig.MODE_RING,
						slot_index,
						slot_count,
						formation_ratio
					)
					var transition_blend: float = clampf(
						float(preview_state.get("visual_blend", geometry.get("blend", 0.0))),
						0.0,
						1.0
					)
					return ring_position.lerp(arc_position, transition_blend)
			return arc_position
		SwordArrayConfig.MODE_FAN:
			var fan_position: Vector2 = SwordArrayBandFamily.get_slot_position_from_geometry(geometry, slot_index, slot_count)
			if _geometry_has_profile_sections(geometry):
				var preview_state = geometry.get("preview_state", {})
				if typeof(preview_state) == TYPE_DICTIONARY:
					var from_mode: String = String(preview_state.get("visual_from_mode", ""))
					var to_mode: String = String(preview_state.get("visual_to_mode", ""))
					if from_mode == SwordArrayConfig.MODE_RING and to_mode == SwordArrayConfig.MODE_FAN:
						var ring_position: Vector2 = _get_mode_slot_position(
							main,
							SwordArrayConfig.MODE_RING,
							slot_index,
							slot_count,
							formation_ratio
						)
						var transition_blend: float = clampf(
							float(preview_state.get("visual_blend", geometry.get("blend", 0.0))),
							0.0,
							1.0
						)
						return ring_position.lerp(fan_position, transition_blend)
					if from_mode == SwordArrayConfig.MODE_FAN and to_mode == SwordArrayConfig.MODE_PIERCE:
						var arc_entry_position: Vector2 = _get_band_fan_entry_slot_position(
							main,
							geometry,
							slot_index,
							slot_count,
							formation_ratio
						)
						var entry_blend: float = _smoothstep_local(
							inverse_lerp(0.0, 0.08, float(geometry.get("blend", 0.0)))
						)
						return arc_entry_position.lerp(fan_position, entry_blend)
			return fan_position
		SwordArrayConfig.MODE_PIERCE:
			return _get_mode_slot_position(main, SwordArrayConfig.MODE_PIERCE, slot_index, slot_count, formation_ratio)
		_:
			return _get_mode_slot_position(main, morph_state["dominant_mode"], slot_index, slot_count, formation_ratio)

static func _sample_band_geometry_section(geometry: Dictionary, ratio: float) -> Dictionary:
	return SwordArrayBandFamily.sample_band_geometry_section(geometry, ratio)


static func _get_geometry_preview_type(geometry: Dictionary) -> String:
	return String(geometry.get("preview_type", geometry.get("dominant_mode", SwordArrayConfig.MODE_RING)))


static func _geometry_has_profile_sections(geometry: Dictionary) -> bool:
	return bool(geometry.get("has_profile_sections", false))


static func _get_band_fan_entry_slot_position(
	main: Node,
	geometry: Dictionary,
	slot_index: int,
	slot_count: int,
	formation_ratio: float
) -> Vector2:
	var preset_data: Dictionary = geometry.get("preset_from_data", {})
	if preset_data.is_empty():
		return SwordArrayBandFamily.get_slot_position_from_geometry(geometry, slot_index, slot_count)
	var preview_state = geometry.get("preview_state", {})
	var preset_runtime := {
		"blend": 0.0,
		"from_id": geometry.get("preset_from", ""),
		"to_id": geometry.get("preset_from", ""),
		"active_id": geometry.get("preset_from", ""),
		"from": preset_data,
		"to": preset_data,
		"blended": preset_data,
		"parameter_blends": {},
		"morph_profile": {},
	}
	var arc_preview: Dictionary = _build_band_arc_preview_from_runtime(
		main,
		preset_runtime,
		formation_ratio,
		"crescent",
		preview_state
	)
	var entry_preview: Dictionary = SwordArrayBandFamily.build_section_fan_preview_from_arc_preview(
		main.player["pos"],
		arc_preview,
		preview_state,
		preset_data
	)
	var entry_geometry := {
		"preview_type": SwordArrayConfig.MODE_FAN,
		"dominant_mode": SwordArrayConfig.MODE_FAN,
		"band_sections": entry_preview.get("sections", []),
		"has_profile_sections": true,
		"center": entry_preview.get("center", arc_preview.get("center", main.player["pos"])),
		"tail": entry_preview.get("tail", main.player["pos"]),
		"aim_vector": entry_preview.get("aim_vector", _get_aim_vector(main)),
		"side_vector": entry_preview.get("side_vector", _get_aim_vector(main).rotated(PI * 0.5)),
		"angle": float(entry_preview.get("angle", arc_preview.get("angle", _get_aim_vector(main).angle()))),
		"arc": float(entry_preview.get("arc", arc_preview.get("arc", 0.0))),
		"inner_arc": float(entry_preview.get("inner_arc", entry_preview.get("arc", arc_preview.get("arc", 0.0)))),
		"inner_radius": float(entry_preview.get("inner_radius", 0.0)),
		"outer_radius": float(entry_preview.get("outer_radius", 0.0)),
	}
	return SwordArrayBandFamily.get_slot_position_from_geometry(entry_geometry, slot_index, slot_count)


static func _get_band_preset_runtime_for_state(state: Dictionary) -> Dictionary:
	return SwordArrayBandFamily.get_preset_runtime_for_state(state)


static func _build_band_arc_preview_from_runtime(
	main: Node,
	preset_runtime: Dictionary,
	formation_ratio: float,
	preview_type: String,
	preview_state
) -> Dictionary:
	return SwordArrayBandFamily.build_arc_preview_from_runtime(
		main,
		preset_runtime,
		formation_ratio,
		preview_type,
		preview_state,
		_get_aim_vector(main)
	)


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
	var geometry: Dictionary = get_geometry_result(main, morph_state, 1.0)
	return _get_fire_launch_origin_from_geometry(
		main,
		morph_state,
		geometry,
		fire_index,
		bullet_pos,
		volley_count,
		burst_step,
		total_count
	)


static func _get_fire_launch_origin_from_geometry(
	main: Node,
	morph_state: Dictionary,
	geometry: Dictionary,
	fire_index: int,
	bullet_pos: Vector2,
	volley_count := -1,
	burst_step := 0,
	total_count := -1
) -> Vector2:
	if geometry.get("family", "") == SwordArrayConfig.FORMATION_FAMILY_BAND:
		return _get_band_launch_origin_from_geometry(main, morph_state, geometry, fire_index, bullet_pos, volley_count, burst_step, total_count)
	return bullet_pos


static func _get_band_launch_origin_from_geometry(
	main: Node,
	morph_state: Dictionary,
	geometry: Dictionary,
	fire_index: int,
	bullet_pos: Vector2,
	volley_count := -1,
	burst_step := 0,
	total_count := -1
) -> Vector2:
	match _get_geometry_preview_type(geometry):
		SwordArrayConfig.MODE_FAN:
			if _geometry_has_profile_sections(geometry):
				return SwordArrayBandFamily.get_spear_launch_origin_from_geometry(geometry, bullet_pos)
			return bullet_pos
		SwordArrayConfig.MODE_PIERCE:
			return SwordArrayBandFamily.get_pierce_launch_origin_from_geometry(geometry, bullet_pos)
		_:
			return bullet_pos


static func get_fire_target(main: Node, state_source, fire_index: int, bullet_pos: Vector2, volley_count := -1, burst_step := 0, total_count := -1) -> Vector2:
	var morph_state: Dictionary = _resolve_morph_state(main, state_source)
	var geometry: Dictionary = get_geometry_result(main, morph_state, 1.0)
	return _get_fire_target_from_geometry(
		main,
		morph_state,
		geometry,
		fire_index,
		bullet_pos,
		volley_count,
		burst_step,
		total_count
	)


static func _get_fire_target_from_geometry(
	main: Node,
	morph_state: Dictionary,
	geometry: Dictionary,
	fire_index: int,
	bullet_pos: Vector2,
	volley_count := -1,
	burst_step := 0,
	total_count := -1
) -> Vector2:
	if geometry.get("family", "") == SwordArrayConfig.FORMATION_FAMILY_BAND:
		return _get_band_fire_target_from_geometry(main, morph_state, geometry, fire_index, bullet_pos, volley_count, burst_step, total_count)
	return _get_mode_fire_target(main, morph_state, morph_state["dominant_mode"], fire_index, bullet_pos, volley_count, burst_step, total_count)


static func _get_band_fire_target_from_geometry(
	main: Node,
	morph_state: Dictionary,
	geometry: Dictionary,
	fire_index: int,
	bullet_pos: Vector2,
	volley_count := -1,
	burst_step := 0,
	total_count := -1
) -> Vector2:
	match _get_geometry_preview_type(geometry):
		"crescent":
			return _get_crescent_fire_target_from_geometry(main, morph_state, geometry, fire_index, bullet_pos, volley_count, burst_step)
		SwordArrayConfig.MODE_FAN:
			if _uses_ring_fire_semantics_for_geometry(main, geometry):
				return _get_mode_fire_target(main, morph_state, SwordArrayConfig.MODE_RING, fire_index, bullet_pos, volley_count, burst_step, total_count)
			if _geometry_has_profile_sections(geometry):
				return _get_fan_fire_target_from_geometry(main, morph_state, geometry, fire_index, bullet_pos, volley_count, burst_step)
			return _get_mode_fire_target(main, morph_state, SwordArrayConfig.MODE_FAN, fire_index, bullet_pos, volley_count, burst_step, total_count)
		SwordArrayConfig.MODE_PIERCE:
			return _get_mode_fire_target(main, morph_state, SwordArrayConfig.MODE_PIERCE, fire_index, bullet_pos, volley_count, burst_step, total_count)
		SwordArrayConfig.MODE_RING:
			return _get_mode_fire_target(main, morph_state, SwordArrayConfig.MODE_RING, fire_index, bullet_pos, volley_count, burst_step, total_count)
		_:
			return _get_mode_fire_target(main, morph_state, morph_state["dominant_mode"], fire_index, bullet_pos, volley_count, burst_step, total_count)


static func _get_mode_fire_target(main: Node, state_source, mode: String, fire_index: int, bullet_pos: Vector2, volley_count := -1, burst_step := 0, total_count := -1) -> Vector2:
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
			var fan_angle_factor: float = _get_fire_angle_factor(main, state_source, fire_index, fan_slot_count)
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


static func _get_crescent_fire_target_from_geometry(main: Node, state_source, geometry: Dictionary, fire_index: int, bullet_pos: Vector2, volley_count := -1, burst_step := 0) -> Vector2:
	var fire_count: int = maxi(volley_count if volley_count > 0 else SwordArrayConfig.get_profile(SwordArrayConfig.MODE_FAN)["slot_count"], 1)
	var angle_factor: float = _get_fire_angle_factor(main, state_source, fire_index, fire_count)
	return SwordArrayBandFamily.get_crescent_fire_target_from_geometry(
		geometry,
		angle_factor,
		bullet_pos,
		main.player["pos"],
		_get_aim_vector(main)
	)


static func _get_fan_fire_target_from_geometry(main: Node, state_source, geometry: Dictionary, fire_index: int, bullet_pos: Vector2, volley_count := -1, burst_step := 0) -> Vector2:
	var fire_count: int = maxi(volley_count if volley_count > 0 else SwordArrayConfig.get_profile(SwordArrayConfig.MODE_FAN)["slot_count"], 1)
	var angle_factor: float = _get_fire_angle_factor(main, state_source, fire_index, fire_count)
	return SwordArrayBandFamily.get_fan_fire_target_from_geometry(
		geometry,
		angle_factor,
		bullet_pos,
		main.player["pos"]
	)


static func get_preview_data(main: Node, state_source, formation_ratio := 1.0) -> Dictionary:
	return get_geometry_result(main, state_source, formation_ratio)["preview"]


static func _build_preview_data(main: Node, morph_state: Dictionary, formation_ratio := 1.0) -> Dictionary:
	var actual_distance: float = _get_actual_morph_distance(morph_state)
	var distances: Dictionary = SwordArrayConfig.get_morph_distances()
	if actual_distance <= distances["ring_stable_end"]:
		return _get_mode_preview_data(main, SwordArrayConfig.MODE_RING, formation_ratio)
	if actual_distance < distances["ring_to_fan_end"]:
		return _get_ring_fan_band_preview(
			main,
			morph_state,
			formation_ratio,
			_get_ring_fan_band_progress(actual_distance, distances)
		)
	if actual_distance <= distances["fan_stable_end"]:
		return _get_stable_band_fan_preview(main, formation_ratio, morph_state)
	var converging_preview: Dictionary = _get_active_fan_pierce_preview(main, morph_state, formation_ratio)
	if not converging_preview.is_empty():
		return converging_preview
	return _get_mode_preview_data(main, morph_state["dominant_mode"], formation_ratio)


static func _build_geometry_result(main: Node, morph_state: Dictionary, preview: Dictionary) -> Dictionary:
	var preview_type: String = String(preview.get("type", morph_state.get("dominant_mode", SwordArrayConfig.MODE_RING)))
	var aim_vector: Vector2 = preview.get("aim_vector", _get_aim_vector(main))
	var side_vector: Vector2 = preview.get("side_vector", aim_vector.rotated(PI * 0.5))
	var center: Vector2 = preview.get("center", main.player["pos"])
	var tail: Vector2 = preview.get("tail", preview.get("start", main.player["pos"]))
	var tip: Vector2 = preview.get("tip", preview.get("end", tail + aim_vector))
	var start: Vector2 = preview.get("start", tail)
	var end: Vector2 = preview.get("end", tip)
	var outer_cap_control: Vector2 = preview.get("outer_cap_control", tip)
	var inner_cap_control: Vector2 = preview.get("inner_cap_control", tail)
	if preview_type == "crescent" and not preview.has("tail") and not preview.has("tip"):
		tail = center + aim_vector * float(preview.get("inner_radius", 0.0))
		tip = center + aim_vector * float(preview.get("outer_radius", 0.0))
		start = tail
		end = tip
		inner_cap_control = preview.get("inner_cap_control", tail)
		outer_cap_control = preview.get("outer_cap_control", tip)
	var has_profile_sections: bool = bool(preview.get("has_profile_sections", false))
	var preview_blend: float = clampf(float(preview.get("blend", 0.0)), 0.0, 1.0)
	var spine_focus: float = clampf(float(preview.get("spine_focus", 0.0)), 0.0, 1.0)
	var tip_focus: float = clampf(float(preview.get("tip_focus", 0.0)), 0.0, 1.0)
	var default_arc: float = TAU if preview_type == SwordArrayConfig.MODE_RING else 0.0
	var band_sections: Array = _build_band_sections_for_preview(main, preview_type, preview, aim_vector, side_vector)
	var geometry := {
		"family": morph_state.get("formation_family", SwordArrayConfig.FORMATION_FAMILY_BAND),
		"dominant_mode": morph_state.get("dominant_mode", preview_type),
		"preset_from": morph_state.get("preset_from", SwordArrayConfig.get_default_preset_for_mode(preview_type)),
		"preset_to": morph_state.get("preset_to", SwordArrayConfig.get_default_preset_for_mode(preview_type)),
		"preset_blend": clampf(float(morph_state.get("preset_blend", morph_state.get("visual_blend", 0.0))), 0.0, 1.0),
		"preview_type": preview_type,
		"preview": preview,
		"preview_state": preview.get("preview_state", preview_type),
		"has_profile_sections": has_profile_sections,
		"sections": preview.get("sections", []),
		"band_sections": band_sections,
		"left_outline": preview.get("left_outline", []),
		"right_outline": preview.get("right_outline", []),
		"aim_vector": aim_vector,
		"side_vector": side_vector,
		"center": center,
		"angle": float(preview.get("angle", aim_vector.angle())),
		"arc": float(preview.get("arc", default_arc)),
		"inner_arc": float(preview.get("inner_arc", preview.get("arc", default_arc))),
		"radius": float(preview.get("radius", preview.get("outer_radius", 0.0))),
		"inner_radius": float(preview.get("inner_radius", preview.get("radius", 0.0))),
		"outer_radius": float(preview.get("outer_radius", preview.get("radius", 0.0))),
		"half_width": float(preview.get("half_width", 0.0)),
		"tip_radius": float(preview.get("tip_radius", 0.0)),
		"wedge_length": float(preview.get("wedge_length", 0.0)),
		"wedge_width": float(preview.get("wedge_width", 0.0)),
		"blend": preview_blend,
		"spine_focus": spine_focus,
		"tip_focus": tip_focus,
		"edge_curve_strength": clampf(float(preview.get("edge_curve_strength", 1.0)), 0.0, 1.0),
		"shoulder_ratio": clampf(float(preview.get("shoulder_ratio", 0.0)), 0.0, 1.0),
		"shoulder_half_width": float(preview.get("shoulder_half_width", 0.0)),
		"tail_half_width": float(preview.get("tail_half_width", 0.0)),
		"tail": tail,
		"tip": tip,
		"start": start,
		"end": end,
		"outer_cap_control": outer_cap_control,
		"inner_cap_control": inner_cap_control,
		"band_stage": _infer_band_stage(preview_type, preview),
	}
	var family_runtime: Dictionary = _build_family_runtime(main, morph_state, geometry)
	for key in family_runtime.keys():
		geometry[key] = family_runtime[key]
	return geometry


static func _build_family_runtime(main: Node, morph_state: Dictionary, geometry: Dictionary) -> Dictionary:
	match String(geometry.get("family", "")):
		SwordArrayConfig.FORMATION_FAMILY_BAND:
			return _build_band_family_runtime(main, morph_state, geometry)
		_:
			return {
				"runtime": {
					"family": geometry.get("family", "unknown"),
				},
				"spine_points": _build_band_spine_points(geometry),
				"section_centers": _extract_section_centers(geometry.get("band_sections", [])),
				"debug": {
					"family": geometry.get("family", "unknown"),
					"actual_distance": _get_actual_morph_distance(morph_state),
					"distance_ratio": float(morph_state.get("distance_ratio", 0.0)),
				},
			}


static func _build_band_family_runtime(main: Node, morph_state: Dictionary, geometry: Dictionary) -> Dictionary:
	return SwordArrayBandFamily.build_runtime(
		morph_state,
		geometry,
		_get_actual_morph_distance(morph_state),
		_get_geometry_preview_type(geometry)
	)


static func _build_band_spine_points(geometry: Dictionary) -> Array:
	return SwordArrayBandFamily.build_spine_points(geometry)


static func _extract_section_centers(sections: Array) -> Array:
	return SwordArrayBandFamily.extract_section_centers(sections)


static func _build_band_sections_for_preview(main: Node, preview_type: String, preview: Dictionary, aim_vector: Vector2, side_vector: Vector2) -> Array:
	return SwordArrayBandFamily.build_band_sections_for_preview(
		main.player["pos"],
		preview_type,
		preview,
		aim_vector,
		side_vector
	)


static func _infer_band_stage(preview_type: String, preview: Dictionary) -> String:
	if preview.has("band_stage_override"):
		return String(preview.get("band_stage_override", "unknown"))
	match preview_type:
		SwordArrayConfig.MODE_RING:
			return "ring"
		"crescent":
			if preview.get("has_profile_sections", false):
				return "section_band"
			return "arc_band"
		SwordArrayConfig.MODE_FAN:
			if preview.get("has_profile_sections", false):
				return "section_band"
			return "fan_band"
		SwordArrayConfig.MODE_PIERCE:
			return "line_band"
		_:
			return "unknown"


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


static func _get_active_fan_pierce_preview(main: Node, morph_state: Dictionary, formation_ratio: float) -> Dictionary:
	var actual_distance: float = _get_actual_morph_distance(morph_state)
	var distances: Dictionary = SwordArrayConfig.get_morph_distances()
	if actual_distance <= distances["fan_stable_end"]:
		return {}
	if actual_distance >= distances["fan_to_pierce_end"]:
		return {}
	return _get_unified_fan_pierce_band_preview(main, morph_state, formation_ratio)


static func _get_ring_fan_band_progress(actual_distance: float, distances: Dictionary) -> float:
	return _smoothstep_local(
		inverse_lerp(distances["ring_stable_end"], distances["ring_to_fan_end"], actual_distance)
	)


static func _get_ring_fan_band_preview(main: Node, morph_state: Dictionary, formation_ratio: float, progress: float) -> Dictionary:
	var band_progress: float = clampf(progress, 0.0, 1.0)
	var transition_state: Dictionary = SwordArrayConfig.complete_morph_state(morph_state.duplicate(true))
	transition_state["formation_family"] = SwordArrayConfig.FORMATION_FAMILY_BAND
	transition_state["preset_from"] = SwordArrayConfig.PRESET_GUARD_BAND
	transition_state["preset_to"] = SwordArrayConfig.PRESET_PRESSURE_BAND
	transition_state["preset_blend"] = band_progress
	transition_state["visual_from_mode"] = SwordArrayConfig.MODE_RING
	transition_state["visual_to_mode"] = SwordArrayConfig.MODE_FAN
	transition_state["visual_blend"] = band_progress
	transition_state["dominant_mode"] = SwordArrayConfig.MODE_RING if band_progress < 0.5 else SwordArrayConfig.MODE_FAN
	var preset_runtime: Dictionary = _get_band_preset_runtime_for_state(transition_state)
	var arc_preview: Dictionary = _build_band_arc_preview_from_runtime(
		main,
		preset_runtime,
		formation_ratio,
		SwordArrayConfig.MODE_FAN,
		transition_state
	)
	arc_preview["spine_focus"] = float(preset_runtime.get("blended", {}).get("spine_emphasis", 0.0)) * band_progress
	arc_preview["tip_focus"] = float(preset_runtime.get("blended", {}).get("tip_emphasis", 0.0)) * band_progress
	arc_preview["band_stage_override"] = "arc_band"
	return arc_preview


static func _get_stable_band_fan_preview(main: Node, formation_ratio: float, preview_state) -> Dictionary:
	var stable_state: Dictionary = SwordArrayConfig.get_mode_state(SwordArrayConfig.MODE_FAN)
	var preset_runtime: Dictionary = _get_band_preset_runtime_for_state(stable_state)
	var preview: Dictionary = _build_band_arc_preview_from_runtime(
		main,
		preset_runtime,
		formation_ratio,
		SwordArrayConfig.MODE_FAN,
		preview_state
	)
	preview["band_stage_override"] = "fan_band"
	preview["spine_focus"] = float(preset_runtime.get("blended", {}).get("spine_emphasis", 0.0))
	preview["tip_focus"] = float(preset_runtime.get("blended", {}).get("tip_emphasis", 0.0))
	return preview


static func _get_unified_fan_pierce_band_preview(main: Node, morph_state: Dictionary, formation_ratio: float) -> Dictionary:
	var distances: Dictionary = SwordArrayConfig.get_morph_distances()
	var actual_distance: float = _get_actual_morph_distance(morph_state)
	var band_start: float = distances["fan_stable_end"]
	var collapse_start: float = _get_band_collapse_start_distance(distances)
	var band_end: float = distances["fan_to_pierce_end"]
	if actual_distance < band_start or actual_distance > band_end:
		return {}
	return _build_unified_fan_pierce_band_preview(
		main,
		morph_state,
		formation_ratio,
		actual_distance,
		band_start,
		collapse_start,
		band_end
	)


static func _build_unified_fan_pierce_band_preview(
	main: Node,
	morph_state: Dictionary,
	formation_ratio: float,
	actual_distance: float,
	band_start: float,
	collapse_start: float,
	band_end: float
) -> Dictionary:
	var preset_runtime: Dictionary = _get_band_preset_runtime_for_state(morph_state)
	var pierce_preview: Dictionary = _get_mode_preview_data(main, SwordArrayConfig.MODE_PIERCE, formation_ratio)
	return SwordArrayBandFamily.build_unified_fan_pierce_preview(
		main,
		morph_state,
		formation_ratio,
		actual_distance,
		band_start,
		collapse_start,
		band_end,
		preset_runtime,
		pierce_preview,
		_get_aim_vector(main)
	)

static func get_fire_release_profile(main: Node, state_source, remaining_count: int) -> Dictionary:
	var morph_state: Dictionary = _resolve_morph_state(main, state_source)
	var geometry: Dictionary = get_geometry_result(main, morph_state, 1.0)
	var clamped_remaining: int = maxi(remaining_count, 1)
	var blend: float = clampf(float(morph_state.get("visual_blend", 0.0)), 0.0, 1.0)
	var from_mode: String = morph_state["visual_from_mode"]
	var to_mode: String = morph_state["visual_to_mode"]
	var ring_rate: float = 1.0 / float(SwordArrayConfig.get_profile(SwordArrayConfig.MODE_RING)["fire_interval"])
	var fan_rate: float = 1.0 / float(SwordArrayConfig.get_profile(SwordArrayConfig.MODE_FAN)["fire_interval"])
	var pierce_rate: float = 1.0 / float(SwordArrayConfig.get_profile(SwordArrayConfig.MODE_PIERCE)["fire_interval"])
	var fan_packet_target: float = _get_fan_packet_size_target(clamped_remaining)
	var ring_fan_packet_blend: float = _smoothstep_local(inverse_lerp(0.42, 1.0, blend))
	var ring_fan_coverage_blend: float = _smoothstep_local(inverse_lerp(0.18, 1.0, blend))
	var ring_fan_encircle_weight: float = _get_ring_fan_encircle_release_weight_from_geometry(main, geometry)
	var ring_fan_release_blend: float = maxf(ring_fan_packet_blend, 1.0 - ring_fan_encircle_weight)
	var ring_fan_forward_blend: float = maxf(ring_fan_coverage_blend, 1.0 - ring_fan_encircle_weight)
	var fan_pierce_rate_blend: float = _smoothstep_local(inverse_lerp(0.08, 1.0, blend))
	var fan_pierce_packet_blend: float = _smoothstep_local(inverse_lerp(0.38, 1.0, blend))
	var fan_pierce_center_blend: float = _smoothstep_local(inverse_lerp(0.3, 1.0, blend))
	var profile := {
		"release_rate": fan_rate,
		"packet_size_target": fan_packet_target,
		"coverage_weight": 0.18,
		"center_bias": 0.0,
	}
	var preview_state = geometry.get("preview_state", {})
	var is_ring_fan_arc_band: bool = false
	if typeof(preview_state) == TYPE_DICTIONARY:
		is_ring_fan_arc_band = (
			String(preview_state.get("visual_from_mode", "")) == SwordArrayConfig.MODE_RING
			and String(preview_state.get("visual_to_mode", "")) == SwordArrayConfig.MODE_FAN
			and String(geometry.get("band_stage", "")) == "arc_band"
		)
	if _get_geometry_preview_type(geometry) == "crescent" or is_ring_fan_arc_band:
		profile["release_rate"] = lerpf(ring_rate, fan_rate, ring_fan_forward_blend)
		profile["packet_size_target"] = lerpf(float(clamped_remaining), fan_packet_target, ring_fan_release_blend)
		profile["coverage_weight"] = lerpf(1.0, 0.28, ring_fan_forward_blend)
		profile["center_bias"] = 0.0
		return profile
	match [from_mode, to_mode]:
		[SwordArrayConfig.MODE_RING, SwordArrayConfig.MODE_RING]:
			profile["release_rate"] = ring_rate
			profile["packet_size_target"] = float(clamped_remaining)
			profile["coverage_weight"] = 1.0
			profile["center_bias"] = 0.0
		[SwordArrayConfig.MODE_FAN, SwordArrayConfig.MODE_FAN]:
			profile["release_rate"] = fan_rate
			profile["packet_size_target"] = fan_packet_target
			profile["coverage_weight"] = 0.26
			profile["center_bias"] = 0.0
		[SwordArrayConfig.MODE_FAN, SwordArrayConfig.MODE_PIERCE]:
			profile["release_rate"] = lerpf(fan_rate, pierce_rate, fan_pierce_rate_blend)
			profile["packet_size_target"] = lerpf(fan_packet_target, 1.0, fan_pierce_packet_blend)
			profile["coverage_weight"] = lerpf(0.26, 0.0, fan_pierce_center_blend)
			profile["center_bias"] = fan_pierce_center_blend
		_:
			profile["release_rate"] = pierce_rate
			profile["packet_size_target"] = 1.0
			profile["coverage_weight"] = 0.0
			profile["center_bias"] = 1.0
	return profile


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
	var geometry: Dictionary = get_geometry_result(main, morph_state, 1.0)
	match _get_geometry_preview_type(geometry):
		SwordArrayConfig.MODE_FAN:
			if _geometry_has_profile_sections(geometry):
				var preview_blend: float = float(geometry.get("blend", 0.0))
				var tip_focus: float = float(geometry.get("tip_focus", 0.0))
				effect["position"] = geometry.get("tail", effect["position"]).lerp(
					geometry.get("tip", effect["position"]),
					clampf(0.52 + preview_blend * 0.18 + tip_focus * 0.22, 0.0, 1.0)
				)
		SwordArrayConfig.MODE_PIERCE:
			effect["position"] = geometry.get("tip", effect["position"])
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


static func _get_band_collapse_start_distance(distances: Dictionary) -> float:
	return lerpf(distances["fan_stable_end"], distances["fan_to_pierce_end"], BAND_COLLAPSE_START_RATIO)


static func _get_directional_source_slot_index(
	main: Node,
	state_source,
	slot_count: int,
	desired_direction: Vector2
) -> int:
	var morph_state: Dictionary = _resolve_morph_state(main, state_source)
	var source_positions: Array = []
	var slot_index: int = 0
	while slot_index < slot_count:
		source_positions.append(get_slot_position(main, morph_state, slot_index, slot_count, 1.0))
		slot_index += 1
	return _get_directional_source_index_from_positions(main.player["pos"], source_positions, desired_direction)


static func _get_directional_source_index_from_positions(
	origin: Vector2,
	source_positions: Array,
	desired_direction: Vector2
) -> int:
	var target_direction: Vector2 = desired_direction.normalized()
	if target_direction.is_zero_approx():
		target_direction = Vector2.RIGHT
	var side_vector: Vector2 = target_direction.rotated(PI * 0.5)
	var best_index: int = 0
	var best_alignment: float = -INF
	var best_forward: float = -INF
	var best_lateral: float = INF
	var source_index: int = 0
	while source_index < source_positions.size():
		var source_position: Vector2 = source_positions[source_index]
		var offset: Vector2 = source_position - origin
		var slot_direction: Vector2 = offset.normalized() if not offset.is_zero_approx() else target_direction
		var alignment: float = slot_direction.dot(target_direction)
		var forward_score: float = offset.dot(target_direction)
		var lateral_score: float = absf(offset.dot(side_vector))
		if alignment > best_alignment + 0.0001:
			best_index = source_index
			best_alignment = alignment
			best_forward = forward_score
			best_lateral = lateral_score
		elif absf(alignment - best_alignment) <= 0.0001:
			if forward_score > best_forward + 0.01:
				best_index = source_index
				best_forward = forward_score
				best_lateral = lateral_score
			elif absf(forward_score - best_forward) <= 0.01 and lateral_score < best_lateral:
				best_index = source_index
				best_lateral = lateral_score
		source_index += 1
	return best_index


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


static func _get_fan_packet_size_target(remaining_count: int) -> float:
	return clampf(1.0 + float(maxi(remaining_count - 1, 0)) * 0.5, 1.0, 4.0)


static func _get_ring_fan_encircle_release_weight_from_geometry(main: Node, geometry: Dictionary) -> float:
	if _get_geometry_preview_type(geometry) != "crescent":
		if not _uses_ring_fire_semantics_for_geometry(main, geometry):
			return 0.0
	var covered_arc: float = float(geometry.get("arc", 0.0))
	var arc_weight: float = _smoothstep_local(inverse_lerp(PI * 0.96, PI * 1.08, covered_arc))
	var outer_radius: float = maxf(float(geometry.get("outer_radius", 0.0)), 1.0)
	var center: Vector2 = geometry.get("center", main.player["pos"])
	var center_offset_ratio: float = center.distance_to(main.player["pos"]) / outer_radius
	var surround_weight: float = 1.0 - _smoothstep_local(inverse_lerp(0.08, 0.2, center_offset_ratio))
	return clampf(arc_weight * surround_weight, 0.0, 1.0)


static func _uses_ring_fire_semantics_for_geometry(main: Node, geometry: Dictionary) -> bool:
	var preview_type: String = _get_geometry_preview_type(geometry)
	if preview_type != "crescent" and preview_type != SwordArrayConfig.MODE_FAN:
		return false
	if String(geometry.get("band_stage", "")) != "arc_band":
		return false
	var covered_arc: float = float(geometry.get("arc", 0.0))
	if covered_arc < PI:
		return false
	var outer_radius: float = maxf(float(geometry.get("outer_radius", 0.0)), 1.0)
	var center: Vector2 = geometry.get("center", main.player["pos"])
	var center_offset_ratio: float = center.distance_to(main.player["pos"]) / outer_radius
	return center_offset_ratio <= 0.2


static func _get_fire_angle_factor(main: Node, state_source, fire_index: int, fire_count: int) -> float:
	if fire_count <= 1:
		return 0.0
	var release_profile: Dictionary = get_fire_release_profile(main, state_source, fire_count)
	var coverage_weight: float = clampf(float(release_profile.get("coverage_weight", 0.0)), 0.0, 1.0)
	var center_bias: float = clampf(float(release_profile.get("center_bias", 0.0)), 0.0, 1.0)
	var base_factor: float = SwordArrayBandFamily.get_symmetric_spread_factor(fire_index, fire_count)
	if is_zero_approx(base_factor):
		return 0.0
	var widened_factor: float = signf(base_factor) * pow(absf(base_factor), lerpf(1.0, 0.55, coverage_weight))
	return widened_factor * lerpf(1.0, 0.08, center_bias)
