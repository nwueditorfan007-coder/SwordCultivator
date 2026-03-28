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


static func get_fire_direction(main: Node, mode: String, fire_index: int, volley_count := -1, burst_step := 0, total_count := -1) -> Vector2:
	var fire_target: Vector2 = get_fire_target(main, mode, fire_index, main.player["pos"], volley_count, burst_step, total_count)
	var fire_direction: Vector2 = fire_target - main.player["pos"]
	if fire_direction.is_zero_approx():
		return _get_aim_vector(main)
	return fire_direction.normalized()


static func get_fire_target(main: Node, mode: String, fire_index: int, bullet_pos: Vector2, volley_count := -1, burst_step := 0, total_count := -1) -> Vector2:
	var aim_vector: Vector2 = _get_aim_vector(main)
	var aim_angle: float = aim_vector.angle()
	var profile: Dictionary = SwordArrayConfig.get_profile(mode)
	match mode:
		SwordArrayConfig.MODE_RING:
			var ring_slot: int = fire_index % profile["slot_count"]
			var ring_angle: float = (TAU / float(profile["slot_count"])) * float(ring_slot)
			return main.player["pos"] + Vector2.RIGHT.rotated(ring_angle) * (profile["ring_radius"] + 180.0)
		SwordArrayConfig.MODE_FAN:
			var fan_slot_count: int = maxi(volley_count if volley_count > 0 else profile["slot_count"], 1)
			var fan_angle_factor: float = _get_fan_fire_angle_factor(mode, fire_index, fan_slot_count, burst_step)
			var fan_preview: Dictionary = get_preview_data(main, mode, 1.0)
			var fan_angle: float = fan_preview["angle"] + fan_angle_factor * fan_preview["arc"] * 0.5
			return main.player["pos"] + Vector2.RIGHT.rotated(fan_angle) * (fan_preview["outer_radius"] + 180.0)
		_:
			var pierce_preview: Dictionary = get_preview_data(main, mode, 1.0)
			var pierce_line: Vector2 = pierce_preview["tip"] - pierce_preview["start"]
			var pierce_dir: Vector2 = pierce_line.normalized() if not pierce_line.is_zero_approx() else aim_vector
			return pierce_preview["tip"] + pierce_dir * 180.0


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


static func _build_fan_layer_counts(slot_count: int, layer_count: int) -> Array:
	var counts: Array = []
	var layer_index: int = 0
	while layer_index < layer_count:
		counts.append(1)
		layer_index += 1

	var remaining: int = maxi(slot_count - layer_count, 0)
	if remaining <= 0:
		return counts

	var weights: Array = []
	match layer_count:
		1:
			weights = [1.0]
		2:
			weights = [0.34, 0.66]
		_:
			weights = [0.18, 0.28, 0.54]

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
