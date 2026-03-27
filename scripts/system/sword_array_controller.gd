extends RefCounted
class_name SwordArrayController


static func get_mode(main: Node) -> String:
	var aim_distance: float = main.player["pos"].distance_to(main.mouse_world)
	if aim_distance <= main.SWORD_ARRAY_RING_THRESHOLD:
		return main.SWORD_ARRAY_RING
	if aim_distance <= main.SWORD_ARRAY_FAN_THRESHOLD:
		return main.SWORD_ARRAY_FAN
	return main.SWORD_ARRAY_PIERCE


static func get_slot_position(main: Node, mode: String, slot_index: int, slot_count: int) -> Vector2:
	var aim_vector: Vector2 = _get_aim_vector(main)
	var aim_angle: float = aim_vector.angle()
	var clamped_count: int = maxi(slot_count, 1)

	match mode:
		main.SWORD_ARRAY_RING:
			var ring_angle: float = (TAU / float(clamped_count)) * float(slot_index)
			return main.player["pos"] + Vector2.RIGHT.rotated(ring_angle) * main.SWORD_ARRAY_RING_RADIUS
		main.SWORD_ARRAY_FAN:
			var fan_ratio: float = 0.5
			if clamped_count > 1:
				fan_ratio = float(slot_index) / float(clamped_count - 1)
			var fan_angle: float = lerpf(-main.SWORD_ARRAY_FAN_ARC * 0.5, main.SWORD_ARRAY_FAN_ARC * 0.5, fan_ratio)
			return main.player["pos"] + Vector2.RIGHT.rotated(aim_angle + fan_angle) * main.SWORD_ARRAY_FAN_PREVIEW_RADIUS
		_:
			var line_origin: Vector2 = main.player["pos"] + aim_vector * main.SWORD_ARRAY_PIERCE_START_OFFSET
			var step_offset: float = float(slot_index) * main.SWORD_ARRAY_PIERCE_SLOT_STEP
			return line_origin + aim_vector * step_offset


static func get_fire_direction(main: Node, mode: String, fire_index: int) -> Vector2:
	var aim_vector: Vector2 = _get_aim_vector(main)
	var base_angle: float = aim_vector.angle()
	match mode:
		main.SWORD_ARRAY_RING:
			var ring_slot: int = fire_index % main.SWORD_ARRAY_RING_SLOT_COUNT
			return Vector2.RIGHT.rotated((TAU / float(main.SWORD_ARRAY_RING_SLOT_COUNT)) * float(ring_slot))
		main.SWORD_ARRAY_FAN:
			var fan_slot: int = fire_index % main.SWORD_ARRAY_FAN_SLOT_COUNT
			var fan_ratio: float = 0.5
			if main.SWORD_ARRAY_FAN_SLOT_COUNT > 1:
				fan_ratio = float(fan_slot) / float(main.SWORD_ARRAY_FAN_SLOT_COUNT - 1)
			var fan_angle: float = lerpf(-main.SWORD_ARRAY_FAN_ARC * 0.5, main.SWORD_ARRAY_FAN_ARC * 0.5, fan_ratio)
			return Vector2.RIGHT.rotated(base_angle + fan_angle)
		_:
			var pierce_slot: int = fire_index % main.SWORD_ARRAY_PIERCE_SLOT_COUNT
			var pierce_ratio: float = 0.5
			if main.SWORD_ARRAY_PIERCE_SLOT_COUNT > 1:
				pierce_ratio = float(pierce_slot) / float(main.SWORD_ARRAY_PIERCE_SLOT_COUNT - 1)
			var pierce_angle: float = lerpf(-main.SWORD_ARRAY_PIERCE_SPREAD, main.SWORD_ARRAY_PIERCE_SPREAD, pierce_ratio)
			return Vector2.RIGHT.rotated(base_angle + pierce_angle)


static func get_preview_data(main: Node, mode: String) -> Dictionary:
	var aim_vector: Vector2 = _get_aim_vector(main)
	var aim_angle: float = aim_vector.angle()
	match mode:
		main.SWORD_ARRAY_RING:
			return {
				"type": main.SWORD_ARRAY_RING,
				"radius": main.SWORD_ARRAY_RING_RADIUS,
				"outer_radius": main.SWORD_ARRAY_RING_RADIUS + 10.0,
			}
		main.SWORD_ARRAY_FAN:
			return {
				"type": main.SWORD_ARRAY_FAN,
				"radius": main.SWORD_ARRAY_FAN_PREVIEW_RADIUS,
				"angle": aim_angle,
				"arc": main.SWORD_ARRAY_FAN_ARC,
			}
		_:
			return {
				"type": main.SWORD_ARRAY_PIERCE,
				"start": main.player["pos"] + aim_vector * main.SWORD_ARRAY_PIERCE_START_OFFSET,
				"end": main.player["pos"] + aim_vector * main.SWORD_ARRAY_PIERCE_PREVIEW_LENGTH,
				"half_width": main.SWORD_ARRAY_PIERCE_PREVIEW_HALF_WIDTH,
			}


static func get_fire_interval(main: Node, mode: String) -> float:
	match mode:
		main.SWORD_ARRAY_RING:
			return main.SWORD_ARRAY_RING_FIRE_RATE
		main.SWORD_ARRAY_FAN:
			return main.SWORD_ARRAY_FAN_FIRE_RATE
		_:
			return main.SWORD_ARRAY_PIERCE_FIRE_RATE


static func get_fire_batch_size(main: Node, mode: String, remaining_count: int, burst_step: int) -> int:
	match mode:
		main.SWORD_ARRAY_RING:
			return remaining_count
		main.SWORD_ARRAY_FAN:
			var remaining_volleys: int = maxi(1, 3 - burst_step)
			return ceili(float(remaining_count) / float(remaining_volleys))
		_:
			return 1


static func _get_aim_vector(main: Node) -> Vector2:
	var aim_vector: Vector2 = main.mouse_world - main.player["pos"]
	if aim_vector.is_zero_approx():
		return Vector2.RIGHT
	return aim_vector.normalized()
