extends RefCounted
class_name SwordArrayConfig


const MODE_RING := "ring"
const MODE_FAN := "fan"
const MODE_PIERCE := "pierce"
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
		"fire_interval": 0.32,
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
	},
	MODE_FAN: {
		"arc": 1.745,
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
	},
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
		"ring_weight": weights[MODE_RING],
		"fan_weight": weights[MODE_FAN],
		"pierce_weight": weights[MODE_PIERCE],
	}


static func get_morph_state_for_distance(aim_distance: float) -> Dictionary:
	var clamped_distance: float = maxf(aim_distance, 0.0)
	var distances: Dictionary = get_morph_distances()
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
		return stable_state

	var transition_state: Dictionary = _build_transition_state(
		visual_from_mode,
		visual_to_mode,
		visual_blend,
		distance_ratio
	)
	if transition_state["dominant_mode"] != dominant_mode and MODE_PROFILES.has(dominant_mode):
		transition_state["dominant_mode"] = dominant_mode
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
	return {
		"dominant_mode": normalized_from if clamped_blend < 0.5 else normalized_to,
		"visual_from_mode": normalized_from,
		"visual_to_mode": normalized_to,
		"visual_blend": clamped_blend,
		"distance_ratio": distance_ratio,
		"ring_weight": weights[MODE_RING],
		"fan_weight": weights[MODE_FAN],
		"pierce_weight": weights[MODE_PIERCE],
	}


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
