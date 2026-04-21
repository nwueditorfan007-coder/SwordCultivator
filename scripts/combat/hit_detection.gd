extends RefCounted
class_name HitDetection


func collect_segment_sweep_targets(
	main: Node,
	segment_a: Vector2,
	segment_b: Vector2,
	attacker_radius: float,
	attack_profile_id: String,
	damage_source := "",
	contact_time := 0.0,
	options := {}
) -> Dictionary:
	var result := {
		"contacts": [],
		"boss_contact": {},
	}
	var exclude_enemy_types: Array = options.get("exclude_enemy_types", [])
	var skip_if_start_inside: bool = bool(options.get("skip_if_start_inside", false))
	for enemy in main.enemies:
		if exclude_enemy_types.has(str(enemy.get("type", ""))):
			continue
		var enemy_radius: float = float(enemy.get("radius", 0.0))
		var hit_radius: float = maxf(attacker_radius + enemy_radius, 0.0)
		if not segment_hits_circle(segment_a, segment_b, enemy["pos"], hit_radius):
			continue
		if skip_if_start_inside and segment_a.distance_to(enemy["pos"]) <= hit_radius:
			continue
		var contact_point: Vector2 = closest_point_on_segment(enemy["pos"], segment_a, segment_b)
		var contact: Dictionary = _build_enemy_contact(main, enemy, contact_point, contact_time)
		if not contact.is_empty():
			result["contacts"].append(contact)
	if main._has_boss():
		var boss_radius: float = float(main.boss.get("radius", 0.0))
		var boss_hit_radius: float = maxf(attacker_radius + boss_radius, 0.0)
		if segment_hits_circle(segment_a, segment_b, main.boss["pos"], boss_hit_radius):
			if not skip_if_start_inside or segment_a.distance_to(main.boss["pos"]) > boss_hit_radius:
				var boss_contact_point: Vector2 = closest_point_on_segment(main.boss["pos"], segment_a, segment_b)
				result["boss_contact"] = _build_boss_contact(
					main,
					boss_contact_point,
					attack_profile_id,
					damage_source,
					contact_time
				)
	return result


func collect_circle_contact_targets(
	main: Node,
	center: Vector2,
	attacker_radius: float,
	attack_profile_id: String,
	damage_source := "",
	contact_time := 0.0,
	options := {}
) -> Dictionary:
	var result := {
		"contacts": [],
		"boss_contact": {},
	}
	var exclude_enemy_types: Array = options.get("exclude_enemy_types", [])
	var contact_radius_bonus: float = float(options.get("contact_radius_bonus", 0.0))
	for enemy in main.enemies:
		if exclude_enemy_types.has(str(enemy.get("type", ""))):
			continue
		var enemy_radius: float = float(enemy.get("radius", 0.0))
		if enemy["pos"].distance_to(center) > enemy_radius + attacker_radius + contact_radius_bonus:
			continue
		var contact: Dictionary = _build_enemy_contact(main, enemy, enemy["pos"], contact_time)
		if not contact.is_empty():
			result["contacts"].append(contact)
	if main._has_boss():
		var boss_radius: float = float(main.boss.get("radius", 0.0))
		if main.boss["pos"].distance_to(center) <= boss_radius + attacker_radius + contact_radius_bonus:
			result["boss_contact"] = _build_boss_contact(
				main,
				center,
				attack_profile_id,
				damage_source,
				contact_time
			)
	return result


func collect_melee_arc_targets(
	main: Node,
	origin: Vector2,
	attack_direction: Vector2,
	attack_range: float,
	attack_arc: float,
	attack_profile_id: String,
	damage_source := "",
	options := {}
) -> Dictionary:
	var result := {
		"bullet_contacts": [],
		"contacts": [],
		"boss_contact": {},
	}
	var exclude_enemy_types: Array = options.get("exclude_enemy_types", [])
	var attack_angle: float = attack_direction.angle()
	var bullet_range: float = attack_range + float(options.get("bullet_range_bonus", 0.0))
	for bullet in main.bullets:
		if str(bullet.get("state", "")) != "normal":
			continue
		if not _is_within_arc(origin, bullet["pos"], bullet_range, attack_angle, attack_arc):
			continue
		result["bullet_contacts"].append({
			"bullet": bullet,
			"contact_point": bullet["pos"],
		})
	for enemy in main.enemies:
		if exclude_enemy_types.has(str(enemy.get("type", ""))):
			continue
		var enemy_radius: float = float(enemy.get("radius", 0.0))
		if not _is_within_arc(origin, enemy["pos"], attack_range + enemy_radius, attack_angle, attack_arc):
			continue
		var contact: Dictionary = _build_enemy_contact(main, enemy, enemy["pos"], 0.0)
		if not contact.is_empty():
			result["contacts"].append(contact)
	if main._has_boss():
		var boss_radius: float = float(main.boss.get("radius", 0.0))
		if _is_within_arc(origin, main.boss["pos"], attack_range + boss_radius, attack_angle, attack_arc):
			result["boss_contact"] = _build_boss_contact(main, main.boss["pos"], attack_profile_id, damage_source, 0.0)
	return result


func _build_enemy_contact(main: Node, enemy: Dictionary, contact_point: Vector2, contact_time := 0.0) -> Dictionary:
	var hurtbox: Dictionary = main._get_enemy_primary_hurtbox(enemy)
	return _build_contact_from_descriptor(hurtbox, contact_point, contact_time, "", true, enemy)


func _build_boss_contact(
	main: Node,
	contact_point: Vector2,
	attack_profile_id: String,
	damage_source := "",
	contact_time := 0.0
) -> Dictionary:
	if not main._has_boss():
		return {}
	var boss_hit_context: Dictionary = main._get_boss_hit_context(attack_profile_id, damage_source)
	var descriptor: Dictionary = boss_hit_context.get("descriptor", {})
	return _build_contact_from_descriptor(
		descriptor,
		contact_point,
		contact_time,
		str(boss_hit_context.get("target_state", "")),
		true,
		main.boss
	)


func _build_contact_from_descriptor(
	descriptor: Dictionary,
	contact_point: Vector2,
	contact_time := 0.0,
	target_state := "",
	is_currently_overlapping := true,
	entity: Variant = null
) -> Dictionary:
	var hurtbox_id: String = str(descriptor.get("hurtbox_id", descriptor.get("id", "")))
	var target_id: String = str(descriptor.get("target_id", ""))
	var target_profile_id: String = str(descriptor.get("target_profile_id", ""))
	if hurtbox_id == "" or target_id == "" or target_profile_id == "":
		return {}
	var metadata: Dictionary = descriptor.get("metadata", {})
	return {
		"target_id": target_id,
		"hurtbox_id": hurtbox_id,
		"target_profile_id": target_profile_id,
		"target_state": target_state,
		"contact_point": contact_point,
		"contact_time": maxf(float(contact_time), 0.0),
		"is_currently_overlapping": is_currently_overlapping,
		"target_kind": str(metadata.get("target_kind", "")),
		"hurtbox_kind": str(descriptor.get("hurtbox_kind", "")),
		"descriptor_role": str(descriptor.get("descriptor_role", "")),
		"descriptor": descriptor.duplicate(true),
		"entity": entity,
	}


func _is_within_arc(origin: Vector2, point: Vector2, max_distance: float, attack_angle: float, attack_arc: float) -> bool:
	var offset: Vector2 = point - origin
	if offset.length() > max_distance:
		return false
	return absf(wrapf(offset.angle() - attack_angle, -PI, PI)) <= attack_arc * 0.5


static func closest_point_on_segment(point: Vector2, segment_a: Vector2, segment_b: Vector2) -> Vector2:
	var segment_length_squared: float = segment_a.distance_squared_to(segment_b)
	if is_zero_approx(segment_length_squared):
		return segment_a
	var t: float = clampf((point - segment_a).dot(segment_b - segment_a) / segment_length_squared, 0.0, 1.0)
	return segment_a.lerp(segment_b, t)


static func segment_hits_circle(segment_a: Vector2, segment_b: Vector2, center: Vector2, radius: float) -> bool:
	return closest_point_on_segment(center, segment_a, segment_b).distance_to(center) <= radius
