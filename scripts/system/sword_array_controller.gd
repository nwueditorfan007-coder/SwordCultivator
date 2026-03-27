extends RefCounted
class_name SwordArrayController

const SwordArrayConfig = preload("res://scripts/system/sword_array_config.gd")


static func get_mode(main: Node) -> String:
	var aim_distance: float = main.player["pos"].distance_to(main.mouse_world)
	return SwordArrayConfig.get_mode_for_distance(aim_distance)


static func get_slot_position(main: Node, mode: String, slot_index: int, slot_count: int, formation_ratio := 1.0) -> Vector2:
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
			var fan_ratio: float = 0.5
			if clamped_count > 1:
				fan_ratio = float(slot_index) / float(clamped_count - 1)
			var fan_arc: float = lerpf(profile["idle_arc"], profile["arc"], formation_ratio)
			var fan_radius: float = lerpf(profile["idle_radius"], profile["radius"], formation_ratio)
			var fan_angle: float = lerpf(-fan_arc * 0.5, fan_arc * 0.5, fan_ratio)
			return main.player["pos"] + Vector2.RIGHT.rotated(aim_angle + fan_angle) * fan_radius
		_:
			var centered_index: float = float(slot_index) - float(clamped_count - 1) * 0.5
			var line_origin: Vector2 = main.player["pos"] + aim_vector * lerpf(profile["idle_start_offset"], profile["start_offset"], formation_ratio)
			var step_offset: float = float(slot_index) * lerpf(profile["idle_slot_step"], profile["slot_step"], formation_ratio)
			var side_vector: Vector2 = aim_vector.rotated(PI * 0.5)
			var side_offset: float = centered_index * lerpf(profile["idle_half_width"], 0.0, formation_ratio)
			return line_origin + aim_vector * step_offset + side_vector * side_offset


static func get_fire_direction(main: Node, mode: String, fire_index: int) -> Vector2:
	var aim_vector: Vector2 = _get_aim_vector(main)
	var base_angle: float = aim_vector.angle()
	var profile: Dictionary = SwordArrayConfig.get_profile(mode)
	match mode:
		SwordArrayConfig.MODE_RING:
			var ring_slot: int = fire_index % profile["slot_count"]
			return Vector2.RIGHT.rotated((TAU / float(profile["slot_count"])) * float(ring_slot))
		SwordArrayConfig.MODE_FAN:
			var fan_slot: int = fire_index % profile["slot_count"]
			var fan_ratio: float = 0.5
			if profile["slot_count"] > 1:
				fan_ratio = float(fan_slot) / float(profile["slot_count"] - 1)
			var fan_angle: float = lerpf(-profile["arc"] * 0.5, profile["arc"] * 0.5, fan_ratio)
			return Vector2.RIGHT.rotated(base_angle + fan_angle)
		_:
			var pierce_slot: int = fire_index % profile["slot_count"]
			var pierce_ratio: float = 0.5
			if profile["slot_count"] > 1:
				pierce_ratio = float(pierce_slot) / float(profile["slot_count"] - 1)
			var pierce_angle: float = lerpf(-profile["spread"], profile["spread"], pierce_ratio)
			return Vector2.RIGHT.rotated(base_angle + pierce_angle)


static func get_preview_data(main: Node, mode: String, formation_ratio := 1.0) -> Dictionary:
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
			var fan_radius: float = lerpf(profile["idle_radius"], profile["radius"], formation_ratio)
			return {
				"type": SwordArrayConfig.MODE_FAN,
				"radius": fan_radius,
				"angle": aim_angle,
				"arc": fan_arc,
			}
		_:
			var start_offset: float = lerpf(profile["idle_start_offset"], profile["start_offset"], formation_ratio)
			var preview_length: float = lerpf(profile["preview_length"] * profile["preview_length_idle_scale"], profile["preview_length"], formation_ratio)
			var half_width: float = lerpf(profile["idle_half_width"], profile["preview_half_width"], formation_ratio)
			return {
				"type": SwordArrayConfig.MODE_PIERCE,
				"start": main.player["pos"] + aim_vector * start_offset,
				"end": main.player["pos"] + aim_vector * preview_length,
				"half_width": half_width,
			}


static func get_fire_interval(main: Node, mode: String) -> float:
	return SwordArrayConfig.get_profile(mode)["fire_interval"]


static func get_fire_batch_size(main: Node, mode: String, remaining_count: int, burst_step: int) -> int:
	var profile: Dictionary = SwordArrayConfig.get_profile(mode)
	match profile["burst_mode"]:
		"all":
			return remaining_count
		"three_step":
			var remaining_volleys: int = maxi(1, 3 - burst_step)
			return ceili(float(remaining_count) / float(remaining_volleys))
		_:
			return 1


static func get_accent_color(mode: String) -> Color:
	return SwordArrayConfig.get_profile(mode)["accent_color"]


static func get_soft_accent_color(mode: String) -> Color:
	return SwordArrayConfig.get_profile(mode)["accent_soft_color"]


static func get_fire_effect(main: Node, mode: String, fire_count: int) -> Dictionary:
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
