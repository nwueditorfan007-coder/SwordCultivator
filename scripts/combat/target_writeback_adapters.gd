extends RefCounted
class_name TargetWritebackAdapters


const AttackProfiles = preload("res://scripts/combat/attack_profiles.gd")
const GameBossController = preload("res://scripts/system/game_boss_controller.gd")

const ADAPTER_ENEMY_HEALTH := "enemy_health"
const ADAPTER_BOSS_HEALTH := "boss_health"
const ADAPTER_SILK_SEVER := "silk_sever"

const _DEFAULT_BINDING := {
	"found": false,
	"adapter_id": "",
	"target_id": "",
	"target_profile_id": "",
	"target_profile": {},
	"target_kind": "",
	"pool_key": "",
	"resource_channel": AttackProfiles.CHANNEL_HP,
	"entity": null,
	"aux": {},
}

var _adapters: Dictionary = {}


func _init() -> void:
	reset_defaults()


func clear() -> void:
	_adapters.clear()


func reset_defaults() -> void:
	clear()
	register_adapter(
		ADAPTER_ENEMY_HEALTH,
		Callable(self, "_resolve_enemy_health_binding"),
		Callable(self, "_apply_enemy_health")
	)
	register_adapter(
		ADAPTER_BOSS_HEALTH,
		Callable(self, "_resolve_boss_health_binding"),
		Callable(self, "_apply_boss_health")
	)
	register_adapter(
		ADAPTER_SILK_SEVER,
		Callable(self, "_resolve_silk_sever_binding"),
		Callable(self, "_apply_silk_sever")
	)


func register_adapter(adapter_id: String, resolve_binding_callable: Callable, apply_callable: Callable) -> void:
	if adapter_id == "":
		return
	if not resolve_binding_callable.is_valid() or not apply_callable.is_valid():
		return
	_adapters[adapter_id] = {
		"resolve_binding": resolve_binding_callable,
		"apply": apply_callable,
	}


func unregister_adapter(adapter_id: String) -> void:
	if adapter_id == "":
		return
	_adapters.erase(adapter_id)


func has_adapter(adapter_id: String) -> bool:
	return _adapters.has(adapter_id)


func list_adapter_ids() -> Array:
	return _adapters.keys()


func resolve_binding(main: Node, target_id: String, target_profile_id: String, target_profile: Dictionary) -> Dictionary:
	var binding: Dictionary = _DEFAULT_BINDING.duplicate(true)
	binding["target_id"] = target_id
	binding["target_profile_id"] = target_profile_id
	binding["target_profile"] = target_profile.duplicate(true)
	binding["pool_key"] = str(target_profile.get("hp_pool_key", ""))
	binding["resource_channel"] = str(target_profile.get("resource_channel", AttackProfiles.CHANNEL_HP))
	var adapter_id: String = get_adapter_id(target_profile)
	binding["adapter_id"] = adapter_id
	var adapter: Dictionary = _adapters.get(adapter_id, {})
	var resolve_binding_callable: Callable = adapter.get("resolve_binding", Callable())
	if not resolve_binding_callable.is_valid():
		return binding
	return resolve_binding_callable.call(main, binding)


func apply(main: Node, target_binding: Dictionary, amount: float, damage_source := "") -> Dictionary:
	var adapter_id: String = str(target_binding.get("adapter_id", ""))
	var adapter: Dictionary = _adapters.get(adapter_id, {})
	var apply_callable: Callable = adapter.get("apply", Callable())
	if not apply_callable.is_valid():
		return {
			"target_found": false,
			"applied": false,
			"amount": 0.0,
			"killed": false,
		}
	return apply_callable.call(main, target_binding, amount, damage_source)


func get_adapter_id(target_profile: Dictionary) -> String:
	var explicit_adapter_id: String = str(target_profile.get("writeback_adapter_id", ""))
	if explicit_adapter_id != "":
		return explicit_adapter_id
	match str(target_profile.get("hp_pool_key", "")):
		"health":
			return ADAPTER_ENEMY_HEALTH
		"boss.health":
			return ADAPTER_BOSS_HEALTH
		"silk.health":
			return ADAPTER_SILK_SEVER
		_:
			return ""


func _resolve_enemy_health_binding(main: Node, binding: Dictionary) -> Dictionary:
	var enemy: Variant = main._find_enemy_by_id(str(binding.get("target_id", "")))
	if enemy == null:
		return binding
	binding["found"] = true
	binding["target_kind"] = "enemy"
	binding["entity"] = enemy
	return binding


func _resolve_boss_health_binding(main: Node, binding: Dictionary) -> Dictionary:
	if not main._has_boss():
		return binding
	binding["found"] = true
	binding["target_kind"] = "boss"
	binding["entity"] = main.boss
	return binding


func _resolve_silk_sever_binding(main: Node, binding: Dictionary) -> Dictionary:
	var silk_binding: Dictionary = GameBossController.resolve_silk_binding(main, str(binding.get("target_id", "")))
	if not bool(silk_binding.get("found", false)):
		return binding
	binding["found"] = true
	binding["target_kind"] = "silk"
	binding["aux"] = silk_binding
	return binding


func _apply_enemy_health(main: Node, target_binding: Dictionary, amount: float, damage_source := "") -> Dictionary:
	var result := {
		"target_found": bool(target_binding.get("found", false)),
		"applied": false,
		"amount": 0.0,
		"killed": false,
		"resource_before": 0.0,
		"resource_after": 0.0,
		"resource_max": 0.0,
	}
	var enemy: Variant = target_binding.get("entity", null)
	if enemy == null:
		result["target_found"] = false
		return result
	var current_health: float = float(enemy.get("health", 0.0))
	result["resource_before"] = current_health
	result["resource_after"] = current_health
	result["resource_max"] = float(enemy.get("max_health", current_health))
	if amount > 0.0:
		var previous_health: float = current_health
		main._damage_enemy(enemy, amount, damage_source)
		result["resource_before"] = previous_health
		result["resource_after"] = float(enemy.get("health", previous_health))
		result["amount"] = maxf(previous_health - float(result.get("resource_after", previous_health)), 0.0)
		result["applied"] = float(result.get("amount", 0.0)) > 0.0
	result["resource_after"] = float(enemy.get("health", result.get("resource_after", current_health)))
	result["killed"] = float(result.get("resource_after", 0.0)) <= 0.0
	return result


func _apply_boss_health(main: Node, target_binding: Dictionary, amount: float, _damage_source := "") -> Dictionary:
	var result := {
		"target_found": bool(target_binding.get("found", false)),
		"applied": false,
		"amount": 0.0,
		"killed": false,
		"resource_before": 0.0,
		"resource_after": 0.0,
		"resource_max": 0.0,
	}
	if not main._has_boss():
		result["target_found"] = false
		return result
	var current_boss_health: float = float(main.boss.get("health", 0.0))
	result["resource_before"] = current_boss_health
	result["resource_after"] = current_boss_health
	result["resource_max"] = float(main.boss.get("max_health", main.BOSS_MAX_HEALTH))
	if amount > 0.0:
		var previous_boss_health: float = current_boss_health
		main._damage_boss(amount)
		result["resource_before"] = previous_boss_health
		result["resource_after"] = float(main.boss.get("health", previous_boss_health))
		result["amount"] = maxf(previous_boss_health - float(result.get("resource_after", previous_boss_health)), 0.0)
		result["applied"] = float(result.get("amount", 0.0)) > 0.0
	result["resource_after"] = float(main.boss.get("health", result.get("resource_after", current_boss_health)))
	result["killed"] = float(result.get("resource_after", 0.0)) <= 0.0
	return result


func _apply_silk_sever(main: Node, target_binding: Dictionary, amount: float, damage_source := "") -> Dictionary:
	var silk_id: String = str(target_binding.get("target_id", ""))
	var silk_result: Dictionary = GameBossController.apply_silk_damage(main, silk_id, amount, damage_source)
	return {
		"target_found": bool(silk_result.get("found", false)),
		"applied": bool(silk_result.get("applied", false)),
		"amount": float(silk_result.get("amount", 0.0)),
		"killed": bool(silk_result.get("killed", false)),
		"resource_before": float(silk_result.get("resource_before", 0.0)),
		"resource_after": float(silk_result.get("resource_after", 0.0)),
		"resource_max": float(silk_result.get("resource_max", 0.0)),
	}
