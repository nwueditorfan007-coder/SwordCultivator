extends RefCounted
class_name TargetDescriptorRegistry


const PROVIDER_ENEMY := "enemy"
const PROVIDER_BOSS := "boss"
const PROVIDER_SILK_SEGMENT := "silk_segment"

const TargetDescriptors = preload("res://scripts/combat/target_descriptors.gd")

var _providers: Dictionary = {}


func _init() -> void:
	reset_defaults()


func clear() -> void:
	_providers.clear()


func reset_defaults() -> void:
	clear()
	register_provider(PROVIDER_ENEMY, Callable(self, "_build_enemy_descriptors"))
	register_provider(PROVIDER_BOSS, Callable(self, "_build_boss_descriptors"))
	register_provider(PROVIDER_SILK_SEGMENT, Callable(self, "_build_silk_descriptors"))


func register_provider(provider_id: String, builder: Callable) -> void:
	if provider_id == "" or not builder.is_valid():
		return
	_providers[provider_id] = builder


func unregister_provider(provider_id: String) -> void:
	if provider_id == "":
		return
	_providers.erase(provider_id)


func has_provider(provider_id: String) -> bool:
	return _providers.has(provider_id)


func list_provider_ids() -> Array:
	return _providers.keys()


func build_descriptors(source_data: Dictionary, context := {}) -> Array:
	var provider_id: String = str(context.get("provider_id", source_data.get("descriptor_provider_id", "")))
	return build_descriptors_with_provider(provider_id, source_data, context)


func build_descriptors_with_provider(provider_id: String, source_data: Dictionary, context := {}) -> Array:
	if provider_id == "" or not _providers.has(provider_id):
		return []
	var builder: Callable = _providers.get(provider_id, Callable())
	if not builder.is_valid():
		return []
	var built_variant: Variant = builder.call(source_data, context)
	return _normalize_descriptors(built_variant)


func _build_enemy_descriptors(enemy: Dictionary, _context := {}) -> Array:
	return [TargetDescriptors.build_enemy_body(enemy)]


func _build_boss_descriptors(boss_data: Dictionary, _context := {}) -> Array:
	return [
		TargetDescriptors.build_boss_body(boss_data),
		TargetDescriptors.build_boss_core(boss_data),
	]


func _build_silk_descriptors(silk: Dictionary, _context := {}) -> Array:
	return [TargetDescriptors.build_silk_segment(silk)]


func _normalize_descriptors(built_variant: Variant) -> Array:
	var descriptors: Array = []
	if typeof(built_variant) == TYPE_DICTIONARY:
		descriptors.append((built_variant as Dictionary).duplicate(true))
		return descriptors
	if typeof(built_variant) != TYPE_ARRAY:
		return descriptors
	for descriptor_variant in built_variant:
		if typeof(descriptor_variant) != TYPE_DICTIONARY:
			continue
		descriptors.append((descriptor_variant as Dictionary).duplicate(true))
	return descriptors
