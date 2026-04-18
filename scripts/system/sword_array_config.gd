extends RefCounted
class_name SwordArrayConfig


const MODE_RING := "ring"
const MODE_FAN := "fan"
const MODE_PIERCE := "pierce"
const FORMATION_FAMILY_BAND := "band"
const PRESET_GUARD_BAND := "guard_band"
const PRESET_PRESSURE_BAND := "pressure_band"
const PRESET_PIERCE_BAND := "pierce_band"
const DEFAULT_DISTANCE_PRESET_LANE := "default"
const MORPH_CALIBRATION_PATH := "res://resources/debug/sword_array_morph_calibration.json"

const HOLD_THRESHOLD := 0.10
const ABSORB_RANGE := 375.0
const ABSORB_TAP_ENERGY_COST := 15.0
const ABSORB_HOLD_ENERGY_COST := 10.0
const ABSORB_DURATION := 1.0
const ABSORB_RETURN_LERP_SPEED := 16.0
const MAX_ABSORBED := 12
const FIRED_SPEED := 45.0 * 60.0
const FIRED_DAMAGE := 100.0
const FIRED_GUIDANCE_DURATION := 0.24
const FIRED_GUIDANCE_TURN_RATE := 9.5
const FIRED_GUIDANCE_MAX_DISTANCE := 240.0

const RING_THRESHOLD := 160.0
const FAN_THRESHOLD := 420.0
const RING_STABLE_END := 85.0
const RING_TO_FAN_END := 145.0
const FAN_STABLE_END := 295.0
const FAN_TO_PIERCE_END := 400.0

static var _morph_distance_overrides := {
	"ring_stable_end": RING_STABLE_END,
	"ring_to_fan_end": RING_TO_FAN_END,
	"fan_stable_end": FAN_STABLE_END,
	"fan_to_pierce_end": FAN_TO_PIERCE_END,
}

const MODE_PROFILES := {
	MODE_RING: {
		"ring_radius": 68.0,
		"idle_ring_radius": 44.0,
		"slot_count": 10,
		"fire_interval": 0.30,
		"burst_mode": "all",
		"preview_outer_offset_idle": 6.0,
		"preview_outer_offset_active": 10.0,
		"accent_color": Color(0.35, 1.0, 0.92),
		"accent_soft_color": Color(0.25, 1.0, 0.9),
		"fire_particles_base": 6,
		"fire_particles_per_shot": 1,
		"fire_particles_cap": 20,
		"fire_offset": 0.0,
		"fire_shake": 2.2,
		"sortie_target_offset": 124.0,
		"sortie_max_distance": 190.0,
		"sortie_guidance_max_distance": 88.0,
		"sortie_min_distance": 80.0,
		"sortie_hit_follow_through_distance": 44.0,
		"sortie_hit_radius_bonus": 22.0,
		"sortie_penetration_targets": 1,
		"sortie_rehit_cooldown": 0.16,
	},
	MODE_FAN: {
		"arc": deg_to_rad(60.0),
		"idle_arc": 0.92,
		"radius": 142.0,
		"idle_radius": 100.0,
		"inner_radius": 54.0,
		"idle_inner_radius": 40.0,
		"depth_layers": 3,
		"slot_count": 7,
		"fire_interval": 0.16,
		"burst_mode": "step_burst",
		"burst_steps": 2,
		"accent_color": Color(0.72, 0.96, 1.0),
		"accent_soft_color": Color(0.9, 1.0, 1.0),
		"fire_particles_base": 5,
		"fire_particles_per_shot": 1,
		"fire_particles_cap": 18,
		"fire_offset": 40.0,
		"fire_shake": 2.4,
		"sortie_target_offset": 180.0,
		"sortie_max_distance": 380.0,
		"sortie_guidance_max_distance": 190.0,
		"sortie_min_distance": 156.0,
		"sortie_hit_follow_through_distance": 96.0,
		"sortie_hit_radius_bonus": 8.0,
		"sortie_penetration_targets": 1,
		"sortie_rehit_cooldown": 0.14,
	},
	MODE_PIERCE: {
		"spread": 0.08,
		"start_offset": 68.0,
		"idle_start_offset": 42.0,
		"slot_step": 26.0,
		"idle_slot_step": 20.0,
		"preview_length": 220.0,
		"preview_length_idle_scale": 0.65,
		"preview_half_width": 3.5,
		"idle_half_width": 10.0,
		"idle_tip_offset": 118.0,
		"tip_offset": 220.0,
		"tip_radius_idle": 4.0,
		"tip_radius": 7.0,
		"wedge_length_idle": 20.0,
		"wedge_length": 34.0,
		"wedge_width_idle": 14.0,
		"wedge_width": 7.0,
		"slot_count": 5,
		"fire_interval": 0.08,
		"burst_mode": "single",
		"accent_color": Color(0.9, 1.0, 1.0),
		"accent_soft_color": Color(0.8, 1.0, 1.0),
		"fire_particles_base": 4,
		"fire_particles_per_shot": 2,
		"fire_particles_cap": 22,
		"fire_offset": 72.0,
		"fire_shake": 2.8,
		"sortie_target_offset": 180.0,
		"sortie_max_distance": 620.0,
		"sortie_guidance_max_distance": 320.0,
		"sortie_min_distance": 220.0,
		"sortie_hit_follow_through_distance": 170.0,
		"sortie_hit_radius_bonus": 2.0,
		"sortie_penetration_targets": 4,
		"sortie_rehit_cooldown": 0.12,
	},
}

const SHAPE_PRESETS := {
	PRESET_GUARD_BAND: {
		"id": PRESET_GUARD_BAND,
		"family": FORMATION_FAMILY_BAND,
		"dominant_mode": MODE_RING,
		"section_count": 8,
		"arc": TAU,
		"center_offset": 0.0,
		"forward_length": 68.0,
		"band_thickness": 10.0,
		"front_taper": 0.0,
		"rear_taper": 0.0,
		"tip_emphasis": 0.0,
		"spine_emphasis": 0.0,
		"coverage_bias": 1.0,
	},
	PRESET_PRESSURE_BAND: {
		"id": PRESET_PRESSURE_BAND,
		"family": FORMATION_FAMILY_BAND,
		"dominant_mode": MODE_FAN,
		"section_count": 8,
		"arc": deg_to_rad(60.0),
		"center_offset": 18.0,
		"forward_length": 142.0,
		"band_thickness": 88.0,
		"front_taper": 0.12,
		"rear_taper": 0.0,
		"tip_emphasis": 0.18,
		"spine_emphasis": 0.22,
		"coverage_bias": 0.38,
	},
	PRESET_PIERCE_BAND: {
		"id": PRESET_PIERCE_BAND,
		"family": FORMATION_FAMILY_BAND,
		"dominant_mode": MODE_PIERCE,
		"section_count": 8,
		"arc": 0.08,
		"center_offset": 112.0,
		"forward_length": 220.0,
		"band_thickness": 7.0,
		"front_taper": 0.92,
		"rear_taper": 0.22,
		"tip_emphasis": 1.0,
		"spine_emphasis": 1.0,
		"coverage_bias": 0.0,
	},
}

const MORPH_PROFILES := {
	"guard_band->pressure_band": {
		"id": "guard_band->pressure_band",
		"family": FORMATION_FAMILY_BAND,
		"curve": "smoothstep",
		"blend_windows": {
			"arc": [0.0, 0.72],
			"center_offset": [0.18, 0.84],
			"forward_length": [0.24, 1.0],
			"band_thickness": [0.12, 0.9],
			"tip_emphasis": [0.58, 1.0],
			"spine_emphasis": [0.42, 1.0],
		},
	},
	"pressure_band->pierce_band": {
		"id": "pressure_band->pierce_band",
		"family": FORMATION_FAMILY_BAND,
		"curve": "smoothstep",
		"blend_windows": {
			"arc": [0.0, 1.0],
			"center_offset": [0.08, 0.86],
			"forward_length": [0.18, 1.0],
			"band_thickness": [0.2, 1.0],
			"tip_emphasis": [0.72, 1.0],
			"spine_emphasis": [0.58, 1.0],
		},
	},
}

const DISTANCE_PRESET_LANES := {
	DEFAULT_DISTANCE_PRESET_LANE: [
		{
			"mode": MODE_RING,
			"preset": PRESET_GUARD_BAND,
			"distance_key": "ring_stable_end",
		},
		{
			"mode": MODE_FAN,
			"preset": PRESET_PRESSURE_BAND,
			"distance_key": "fan_stable_end",
		},
		{
			"mode": MODE_PIERCE,
			"preset": PRESET_PIERCE_BAND,
			"distance_key": "fan_to_pierce_end",
		},
	],
}


static func get_mode_for_distance(aim_distance: float) -> String:
	return get_morph_state_for_distance(aim_distance)["dominant_mode"]


static func get_profile(mode: String) -> Dictionary:
	return MODE_PROFILES.get(mode, MODE_PROFILES[MODE_PIERCE])


static func get_mode_state(mode: String) -> Dictionary:
	var clamped_mode: String = mode if MODE_PROFILES.has(mode) else MODE_PIERCE
	var weights := {
		MODE_RING: 0.0,
		MODE_FAN: 0.0,
		MODE_PIERCE: 0.0,
	}
	weights[clamped_mode] = 1.0
	return {
		"dominant_mode": clamped_mode,
		"visual_from_mode": clamped_mode,
		"visual_to_mode": clamped_mode,
		"visual_blend": 0.0,
		"distance_ratio": 0.0,
		"formation_family": get_formation_family_for_mode(clamped_mode),
		"preset_from": get_default_preset_for_mode(clamped_mode),
		"preset_to": get_default_preset_for_mode(clamped_mode),
		"preset_blend": 0.0,
		"ring_weight": weights[MODE_RING],
		"fan_weight": weights[MODE_FAN],
		"pierce_weight": weights[MODE_PIERCE],
	}


static func get_morph_state_for_distance(aim_distance: float) -> Dictionary:
	return _get_morph_state_for_distance_with_distances(aim_distance, get_morph_distances())


static func get_control_morph_distances() -> Dictionary:
	var base: Dictionary = get_morph_distances()
	var control_ring_end: float = minf(base["ring_stable_end"] + 30.0, base["ring_to_fan_end"] - 18.0)
	var control_ring_to_fan: float = minf(base["ring_to_fan_end"] + 34.0, base["fan_stable_end"] - 24.0)
	var control_fan_end: float = minf(base["fan_stable_end"] + 36.0, base["fan_to_pierce_end"] - 18.0)
	return {
		"ring_stable_end": maxf(control_ring_end, 0.0),
		"ring_to_fan_end": maxf(control_ring_to_fan, control_ring_end + 1.0),
		"fan_stable_end": maxf(control_fan_end, control_ring_to_fan + 1.0),
		"fan_to_pierce_end": maxf(base["fan_to_pierce_end"], control_fan_end + 1.0),
	}


static func get_control_morph_state_for_distance(aim_distance: float) -> Dictionary:
	return _get_morph_state_for_distance_with_distances(aim_distance, get_control_morph_distances())


static func _get_morph_state_for_distance_with_distances(aim_distance: float, distances: Dictionary) -> Dictionary:
	var clamped_distance: float = maxf(aim_distance, 0.0)
	var distance_ratio: float = clampf(clamped_distance / distances["fan_to_pierce_end"], 0.0, 1.0)

	if clamped_distance <= distances["ring_stable_end"]:
		var ring_state: Dictionary = get_mode_state(MODE_RING)
		ring_state["distance_ratio"] = distance_ratio
		return ring_state

	if clamped_distance < distances["ring_to_fan_end"]:
		return _build_transition_state(
			MODE_RING,
			MODE_FAN,
			_smoothstep(inverse_lerp(distances["ring_stable_end"], distances["ring_to_fan_end"], clamped_distance)),
			distance_ratio
		)

	if clamped_distance <= distances["fan_stable_end"]:
		var fan_state: Dictionary = get_mode_state(MODE_FAN)
		fan_state["distance_ratio"] = distance_ratio
		return fan_state

	if clamped_distance < distances["fan_to_pierce_end"]:
		return _build_transition_state(
			MODE_FAN,
			MODE_PIERCE,
			_smoothstep(inverse_lerp(distances["fan_stable_end"], distances["fan_to_pierce_end"], clamped_distance)),
			distance_ratio
		)

	var pierce_state: Dictionary = get_mode_state(MODE_PIERCE)
	pierce_state["distance_ratio"] = distance_ratio
	return pierce_state


static func complete_morph_state(state: Dictionary) -> Dictionary:
	if state.is_empty():
		return get_mode_state(MODE_RING)

	var dominant_mode: String = state.get("dominant_mode", MODE_RING)
	var visual_from_mode: String = state.get("visual_from_mode", dominant_mode)
	var visual_to_mode: String = state.get("visual_to_mode", dominant_mode)
	var visual_blend: float = clampf(float(state.get("visual_blend", 0.0)), 0.0, 1.0)
	var distance_ratio: float = clampf(float(state.get("distance_ratio", 0.0)), 0.0, 1.0)

	if visual_from_mode == visual_to_mode:
		var stable_state: Dictionary = get_mode_state(dominant_mode)
		stable_state["distance_ratio"] = distance_ratio
		stable_state["formation_family"] = state.get("formation_family", stable_state["formation_family"])
		stable_state["preset_from"] = state.get("preset_from", stable_state["preset_from"])
		stable_state["preset_to"] = state.get("preset_to", stable_state["preset_to"])
		stable_state["preset_blend"] = clampf(float(state.get("preset_blend", stable_state["preset_blend"])), 0.0, 1.0)
		return stable_state

	var transition_state: Dictionary = _build_transition_state(
		visual_from_mode,
		visual_to_mode,
		visual_blend,
		distance_ratio
	)
	if transition_state["dominant_mode"] != dominant_mode and MODE_PROFILES.has(dominant_mode):
		transition_state["dominant_mode"] = dominant_mode
	transition_state["formation_family"] = state.get("formation_family", transition_state["formation_family"])
	transition_state["preset_from"] = state.get("preset_from", transition_state["preset_from"])
	transition_state["preset_to"] = state.get("preset_to", transition_state["preset_to"])
	transition_state["preset_blend"] = clampf(float(state.get("preset_blend", transition_state["preset_blend"])), 0.0, 1.0)
	return transition_state


static func _build_transition_state(from_mode: String, to_mode: String, blend: float, distance_ratio: float) -> Dictionary:
	var clamped_blend: float = clampf(blend, 0.0, 1.0)
	var normalized_from: String = from_mode if MODE_PROFILES.has(from_mode) else MODE_RING
	var normalized_to: String = to_mode if MODE_PROFILES.has(to_mode) else normalized_from
	var weights := {
		MODE_RING: 0.0,
		MODE_FAN: 0.0,
		MODE_PIERCE: 0.0,
	}
	weights[normalized_from] = 1.0 - clamped_blend
	weights[normalized_to] += clamped_blend
	var family: String = get_formation_family_for_mode(normalized_from)
	if family != get_formation_family_for_mode(normalized_to):
		family = get_formation_family_for_mode(normalized_to)
	return {
		"dominant_mode": normalized_from if clamped_blend < 0.5 else normalized_to,
		"visual_from_mode": normalized_from,
		"visual_to_mode": normalized_to,
		"visual_blend": clamped_blend,
		"distance_ratio": distance_ratio,
		"formation_family": family,
		"preset_from": get_default_preset_for_mode(normalized_from),
		"preset_to": get_default_preset_for_mode(normalized_to),
		"preset_blend": clamped_blend,
		"ring_weight": weights[MODE_RING],
		"fan_weight": weights[MODE_FAN],
		"pierce_weight": weights[MODE_PIERCE],
	}


static func get_formation_family_for_mode(mode: String) -> String:
	match mode:
		MODE_RING, MODE_FAN, MODE_PIERCE:
			return FORMATION_FAMILY_BAND
		_:
			return FORMATION_FAMILY_BAND


static func get_default_preset_for_mode(mode: String) -> String:
	match mode:
		MODE_RING:
			return PRESET_GUARD_BAND
		MODE_FAN:
			return PRESET_PRESSURE_BAND
		_:
			return PRESET_PIERCE_BAND


static func get_distance_preset_lane(lane_id := DEFAULT_DISTANCE_PRESET_LANE) -> Array:
	return DISTANCE_PRESET_LANES.get(lane_id, DISTANCE_PRESET_LANES[DEFAULT_DISTANCE_PRESET_LANE]).duplicate(true)


static func get_shape_preset(preset_id: String) -> Dictionary:
	var fallback_id: String = get_default_preset_for_mode(MODE_PIERCE)
	return SHAPE_PRESETS.get(preset_id, SHAPE_PRESETS[fallback_id]).duplicate(true)


static func get_morph_profile(from_preset: String, to_preset: String) -> Dictionary:
	var normalized_from: String = from_preset if SHAPE_PRESETS.has(from_preset) else get_default_preset_for_mode(MODE_RING)
	var normalized_to: String = to_preset if SHAPE_PRESETS.has(to_preset) else normalized_from
	var profile_key: String = _get_morph_profile_key(normalized_from, normalized_to)
	if MORPH_PROFILES.has(profile_key):
		return MORPH_PROFILES[profile_key].duplicate(true)
	return {
		"id": profile_key,
		"family": get_shape_preset(normalized_to)["family"],
		"curve": "smoothstep",
		"blend_windows": {},
	}


static func get_shape_preset_runtime(state: Dictionary) -> Dictionary:
	var completed_state: Dictionary = complete_morph_state(state)
	var dominant_mode: String = String(completed_state.get("dominant_mode", MODE_RING))
	var blend: float = clampf(float(completed_state.get("preset_blend", completed_state.get("visual_blend", 0.0))), 0.0, 1.0)
	var from_preset_id: String = String(completed_state.get("preset_from", get_default_preset_for_mode(dominant_mode)))
	var to_preset_id: String = String(completed_state.get("preset_to", from_preset_id))
	var from_preset: Dictionary = get_shape_preset(from_preset_id)
	var to_preset: Dictionary = get_shape_preset(to_preset_id)
	var morph_profile: Dictionary = get_morph_profile(from_preset_id, to_preset_id)
	var parameter_blends: Dictionary = _build_shape_parameter_blends(morph_profile, blend)
	var blended_preset: Dictionary = _blend_shape_presets(from_preset, to_preset, parameter_blends)
	return {
		"family": String(completed_state.get("formation_family", from_preset.get("family", FORMATION_FAMILY_BAND))),
		"from_id": from_preset_id,
		"to_id": to_preset_id,
		"blend": blend,
		"active_id": from_preset_id if blend < 0.5 else to_preset_id,
		"from": from_preset,
		"to": to_preset,
		"blended": blended_preset,
		"parameter_blends": parameter_blends,
		"morph_profile": morph_profile,
	}


static func _get_morph_profile_key(from_preset: String, to_preset: String) -> String:
	return "%s->%s" % [from_preset, to_preset]


static func _build_shape_parameter_blends(morph_profile: Dictionary, blend: float) -> Dictionary:
	var clamped_blend: float = clampf(blend, 0.0, 1.0)
	var windows: Dictionary = morph_profile.get("blend_windows", {})
	var parameter_blends := {
		"__base": clamped_blend,
	}
	for key in [
		"arc",
		"center_offset",
		"forward_length",
		"band_thickness",
		"front_taper",
		"rear_taper",
		"tip_emphasis",
		"spine_emphasis",
		"coverage_bias",
		"section_count",
	]:
		parameter_blends[key] = _evaluate_morph_window(clamped_blend, windows.get(key, []))
	return parameter_blends


static func _evaluate_morph_window(blend: float, window: Variant) -> float:
	var clamped_blend: float = clampf(blend, 0.0, 1.0)
	if typeof(window) != TYPE_ARRAY or window.size() < 2:
		return clamped_blend
	var start: float = clampf(float(window[0]), 0.0, 1.0)
	var finish: float = clampf(float(window[1]), start, 1.0)
	if is_equal_approx(start, finish):
		return 1.0 if clamped_blend >= finish else 0.0
	return _smoothstep(inverse_lerp(start, finish, clamped_blend))


static func _blend_shape_presets(from_preset: Dictionary, to_preset: Dictionary, parameter_blends: Dictionary) -> Dictionary:
	var base_blend: float = clampf(float(parameter_blends.get("__base", 0.0)), 0.0, 1.0)
	var blended := from_preset.duplicate(true)
	blended["id"] = "%s->%s" % [from_preset.get("id", ""), to_preset.get("id", "")]
	blended["family"] = to_preset.get("family", from_preset.get("family", FORMATION_FAMILY_BAND))
	blended["dominant_mode"] = (
		from_preset.get("dominant_mode", MODE_RING)
		if base_blend < 0.5
		else to_preset.get("dominant_mode", from_preset.get("dominant_mode", MODE_RING))
	)
	for key in [
		"arc",
		"center_offset",
		"forward_length",
		"band_thickness",
		"front_taper",
		"rear_taper",
		"tip_emphasis",
		"spine_emphasis",
		"coverage_bias",
	]:
		var key_blend: float = clampf(float(parameter_blends.get(key, base_blend)), 0.0, 1.0)
		blended[key] = lerpf(float(from_preset.get(key, 0.0)), float(to_preset.get(key, 0.0)), key_blend)
	blended["section_count"] = int(round(lerpf(
		float(from_preset.get("section_count", 8)),
		float(to_preset.get("section_count", 8)),
		clampf(float(parameter_blends.get("section_count", base_blend)), 0.0, 1.0)
	)))
	return blended


static func _smoothstep(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func get_morph_distances() -> Dictionary:
	return _morph_distance_overrides.duplicate()


static func get_default_morph_distances() -> Dictionary:
	return {
		"ring_stable_end": RING_STABLE_END,
		"ring_to_fan_end": RING_TO_FAN_END,
		"fan_stable_end": FAN_STABLE_END,
		"fan_to_pierce_end": FAN_TO_PIERCE_END,
	}


static func reset_morph_distances() -> void:
	_morph_distance_overrides = get_default_morph_distances()


static func set_morph_distance(key: String, value: float) -> void:
	var clamped_value: float = maxf(value, 0.0)
	match key:
		"ring_stable_end":
			_morph_distance_overrides["ring_stable_end"] = minf(clamped_value, _morph_distance_overrides["ring_to_fan_end"] - 1.0)
		"ring_to_fan_end":
			_morph_distance_overrides["ring_to_fan_end"] = clampf(
				clamped_value,
				_morph_distance_overrides["ring_stable_end"] + 1.0,
				_morph_distance_overrides["fan_stable_end"] - 1.0
			)
		"fan_stable_end":
			_morph_distance_overrides["fan_stable_end"] = clampf(
				clamped_value,
				_morph_distance_overrides["ring_to_fan_end"] + 1.0,
				_morph_distance_overrides["fan_to_pierce_end"] - 1.0
			)
		"fan_to_pierce_end":
			_morph_distance_overrides["fan_to_pierce_end"] = maxf(clamped_value, _morph_distance_overrides["fan_stable_end"] + 1.0)


static func save_morph_distances_to_project() -> bool:
	var make_result: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MORPH_CALIBRATION_PATH.get_base_dir()))
	if make_result != OK:
		return false

	var file := FileAccess.open(MORPH_CALIBRATION_PATH, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(get_morph_distances(), "\t"))
	return true


static func load_morph_distances_from_project() -> bool:
	if not FileAccess.file_exists(MORPH_CALIBRATION_PATH):
		return false

	var file := FileAccess.open(MORPH_CALIBRATION_PATH, FileAccess.READ)
	if file == null:
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false

	reset_morph_distances()
	for key in ["ring_stable_end", "ring_to_fan_end", "fan_stable_end", "fan_to_pierce_end"]:
		if parsed.has(key):
			set_morph_distance(key, float(parsed[key]))
	return true
