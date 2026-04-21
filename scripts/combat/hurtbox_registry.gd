extends RefCounted
class_name HurtboxRegistry


var _descriptors_by_id: Dictionary = {}
var _descriptors_by_target: Dictionary = {}


func clear() -> void:
	_descriptors_by_id.clear()
	_descriptors_by_target.clear()


func register_descriptor(descriptor: Dictionary) -> void:
	var hurtbox_id: String = str(descriptor.get("hurtbox_id", descriptor.get("id", "")))
	var target_id: String = str(descriptor.get("target_id", ""))
	if hurtbox_id == "" or target_id == "":
		return
	var descriptor_copy: Dictionary = descriptor.duplicate(true)
	descriptor_copy["hurtbox_id"] = hurtbox_id
	descriptor_copy["id"] = hurtbox_id
	_descriptors_by_id[hurtbox_id] = descriptor_copy
	var target_descriptors: Array = _descriptors_by_target.get(target_id, [])
	var replaced: bool = false
	var index: int = 0
	while index < target_descriptors.size():
		var existing: Dictionary = target_descriptors[index]
		if str(existing.get("hurtbox_id", existing.get("id", ""))) == hurtbox_id:
			target_descriptors[index] = descriptor_copy
			replaced = true
			break
		index += 1
	if not replaced:
		target_descriptors.append(descriptor_copy)
	_descriptors_by_target[target_id] = target_descriptors


func register_descriptors(descriptors: Array) -> void:
	for descriptor_variant in descriptors:
		if typeof(descriptor_variant) != TYPE_DICTIONARY:
			continue
		register_descriptor(descriptor_variant)


func remove_descriptor(hurtbox_id: String) -> void:
	if hurtbox_id == "" or not _descriptors_by_id.has(hurtbox_id):
		return
	var descriptor: Dictionary = _descriptors_by_id[hurtbox_id]
	var target_id: String = str(descriptor.get("target_id", ""))
	_descriptors_by_id.erase(hurtbox_id)
	if target_id == "" or not _descriptors_by_target.has(target_id):
		return
	var target_descriptors: Array = _descriptors_by_target.get(target_id, [])
	var index: int = target_descriptors.size() - 1
	while index >= 0:
		if str(target_descriptors[index].get("hurtbox_id", target_descriptors[index].get("id", ""))) == hurtbox_id:
			target_descriptors.remove_at(index)
		index -= 1
	if target_descriptors.is_empty():
		_descriptors_by_target.erase(target_id)
	else:
		_descriptors_by_target[target_id] = target_descriptors


func clear_target(target_id: String) -> void:
	if target_id == "" or not _descriptors_by_target.has(target_id):
		return
	for descriptor_variant in _descriptors_by_target.get(target_id, []):
		var descriptor: Dictionary = descriptor_variant
		var hurtbox_id: String = str(descriptor.get("hurtbox_id", descriptor.get("id", "")))
		if hurtbox_id != "":
			_descriptors_by_id.erase(hurtbox_id)
	_descriptors_by_target.erase(target_id)


func get_descriptor(hurtbox_id: String) -> Dictionary:
	return _descriptors_by_id.get(hurtbox_id, {}).duplicate(true)


func get_descriptors_for_target(target_id: String) -> Array:
	var descriptors: Array = _descriptors_by_target.get(target_id, [])
	var result: Array = []
	for descriptor_variant in descriptors:
		if typeof(descriptor_variant) == TYPE_DICTIONARY:
			result.append(descriptor_variant.duplicate(true))
	return result


func select_descriptor(target_id: String, descriptor_role := "", active_states: Array = []) -> Dictionary:
	var best_descriptor: Dictionary = {}
	var best_score: int = -1000000
	for descriptor_variant in _descriptors_by_target.get(target_id, []):
		var descriptor: Dictionary = descriptor_variant
		if descriptor_role != "" and str(descriptor.get("descriptor_role", "")) != descriptor_role:
			continue
		var requires_state: String = str(descriptor.get("requires_state", ""))
		if requires_state != "" and not active_states.has(requires_state):
			continue
		var score: int = int(descriptor.get("priority", 0))
		if requires_state != "":
			score += 1000
		if score > best_score:
			best_score = score
			best_descriptor = descriptor.duplicate(true)
	return best_descriptor
