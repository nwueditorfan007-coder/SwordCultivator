extends RefCounted
class_name HitRegistry


const AttackProfiles = preload("res://scripts/combat/attack_profiles.gd")

var _records: Dictionary = {}


func reset() -> void:
	_records.clear()


func clear_attack_instance(attack_instance_id: String) -> void:
	if attack_instance_id == "":
		return
	_records.erase(attack_instance_id)


func is_hit_allowed(
	attack_instance_id: String,
	target_id: String,
	hurtbox_id: String,
	rehit_policy: String,
	now: float,
	rehit_interval := 0.0,
	is_currently_overlapping := true
) -> bool:
	var record: Dictionary = _get_record(attack_instance_id, target_id, hurtbox_id)
	match rehit_policy:
		AttackProfiles.REHIT_ONCE_PER_INSTANCE:
			return not bool(record.get("has_hit", false))
		AttackProfiles.REHIT_ONCE_PER_ENTRY:
			if bool(record.get("is_overlapping", false)) and is_currently_overlapping:
				return false
			return true
		AttackProfiles.REHIT_INTERVAL_PER_TARGET:
			if not bool(record.get("has_hit", false)):
				return true
			var last_hit_time: float = float(record.get("last_hit_time", -INF))
			return now - last_hit_time >= maxf(float(rehit_interval), 0.0)
		AttackProfiles.REHIT_CONTINUOUS_CONTACT:
			return is_currently_overlapping
		_:
			return not bool(record.get("has_hit", false))


func register_hit(
	attack_instance_id: String,
	target_id: String,
	hurtbox_id: String,
	now: float,
	is_currently_overlapping := true
) -> void:
	var record: Dictionary = _ensure_record(attack_instance_id, target_id, hurtbox_id)
	record["has_hit"] = true
	record["last_hit_time"] = now
	record["last_contact_time"] = now
	record["is_overlapping"] = is_currently_overlapping
	_store_record(attack_instance_id, target_id, hurtbox_id, record)


func set_overlap_state(
	attack_instance_id: String,
	target_id: String,
	hurtbox_id: String,
	is_overlapping: bool,
	now := 0.0
) -> void:
	var record: Dictionary = _ensure_record(attack_instance_id, target_id, hurtbox_id)
	record["is_overlapping"] = is_overlapping
	record["last_contact_time"] = now if is_overlapping else float(record.get("last_contact_time", now))
	_store_record(attack_instance_id, target_id, hurtbox_id, record)


func get_record(attack_instance_id: String, target_id: String, hurtbox_id: String) -> Dictionary:
	return _get_record(attack_instance_id, target_id, hurtbox_id).duplicate(true)


func consume_contact_delta(attack_instance_id: String, target_id: String, hurtbox_id: String, now: float) -> float:
	var record: Dictionary = _ensure_record(attack_instance_id, target_id, hurtbox_id)
	var previous_contact_time: float = float(record.get("last_contact_time", now))
	record["last_contact_time"] = now
	record["is_overlapping"] = true
	_store_record(attack_instance_id, target_id, hurtbox_id, record)
	return maxf(now - previous_contact_time, 0.0)


func _get_record(attack_instance_id: String, target_id: String, hurtbox_id: String) -> Dictionary:
	var attack_records: Dictionary = _records.get(attack_instance_id, {})
	return attack_records.get(_make_record_key(target_id, hurtbox_id), {})


func _ensure_record(attack_instance_id: String, target_id: String, hurtbox_id: String) -> Dictionary:
	var record: Dictionary = _get_record(attack_instance_id, target_id, hurtbox_id)
	if not record.is_empty():
		return record
	return {
		"has_hit": false,
		"last_hit_time": -INF,
		"last_contact_time": -INF,
		"is_overlapping": false,
	}


func _store_record(attack_instance_id: String, target_id: String, hurtbox_id: String, record: Dictionary) -> void:
	var attack_records: Dictionary = _records.get(attack_instance_id, {})
	attack_records[_make_record_key(target_id, hurtbox_id)] = record
	_records[attack_instance_id] = attack_records


func _make_record_key(target_id: String, hurtbox_id: String) -> String:
	return "%s::%s" % [target_id, hurtbox_id]
