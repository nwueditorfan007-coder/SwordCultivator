extends RefCounted
class_name TargetEventSystem


const EVENT_STAGGER := "stagger"
const EVENT_BOSS_VULNERABLE := "boss_vulnerable"
const EVENT_CORE_EXPOSURE := "core_exposure"
const EVENT_PART_BREAK := "part_break"
const EVENT_TETHER_SEVER := "tether_sever"
const EVENT_GUARD_BREAK := "guard_break"
const EVENT_BUILDUP_THRESHOLD_PREFIX := "buildup_threshold:"

var _event_handlers: Dictionary = {}
var _structural_rule_evaluators: Dictionary = {}


func _init() -> void:
	reset_defaults()


func clear() -> void:
	_event_handlers.clear()
	_structural_rule_evaluators.clear()


func reset_defaults() -> void:
	clear()
	register_handler("enemy_stagger", Callable(self, "_handle_enemy_stagger"))
	register_handler("boss_vulnerability", Callable(self, "_handle_boss_vulnerability"))
	register_handler("boss_core_exposure", Callable(self, "_handle_boss_core_exposure"))
	register_handler("part_break_feedback", Callable(self, "_handle_part_break_feedback"))
	register_handler("tether_sever_feedback", Callable(self, "_handle_tether_sever_feedback"))
	register_handler("guard_break_feedback", Callable(self, "_handle_guard_break_feedback"))
	register_handler("buildup_threshold_feedback", Callable(self, "_handle_buildup_threshold_feedback"))
	register_structural_rule_evaluator("resource_depleted", Callable(self, "_rule_resource_depleted"))
	register_structural_rule_evaluator("resource_zero", Callable(self, "_rule_resource_zero"))
	register_structural_rule_evaluator("target_kind", Callable(self, "_rule_target_kind"))


func register_handler(handler_id: String, handler: Callable) -> void:
	if handler_id == "" or not handler.is_valid():
		return
	_event_handlers[handler_id] = handler


func unregister_handler(handler_id: String) -> void:
	if handler_id == "":
		return
	_event_handlers.erase(handler_id)


func has_handler(handler_id: String) -> bool:
	return _event_handlers.has(handler_id)


func list_handler_ids() -> Array:
	return _event_handlers.keys()


func register_structural_rule_evaluator(trigger_id: String, evaluator: Callable) -> void:
	if trigger_id == "" or not evaluator.is_valid():
		return
	_structural_rule_evaluators[trigger_id] = evaluator


func unregister_structural_rule_evaluator(trigger_id: String) -> void:
	if trigger_id == "":
		return
	_structural_rule_evaluators.erase(trigger_id)


func has_structural_rule_evaluator(trigger_id: String) -> bool:
	return _structural_rule_evaluators.has(trigger_id)


func list_structural_rule_evaluators() -> Array:
	return _structural_rule_evaluators.keys()


func prime_target_state(target_state: Dictionary) -> Dictionary:
	if not target_state.has("buildup_pools"):
		target_state["buildup_pools"] = {}
	if not target_state.has("triggered_rule_events"):
		target_state["triggered_rule_events"] = {}
	if not target_state.has("guard_value"):
		target_state["guard_value"] = 0.0
	if not target_state.has("guard_initialized"):
		target_state["guard_initialized"] = false
	return target_state


func make_event_record(event_name: String, payload := {}, context := {}) -> Dictionary:
	if event_name == "":
		return {}
	return {
		"name": event_name,
		"payload": _duplicate_dictionary(payload),
		"context": _duplicate_dictionary(context),
	}


func append_event_record(events: Array, event_variant: Variant, base_payload := {}, base_context := {}) -> void:
	var event_record: Dictionary = _normalize_event_record(event_variant, base_payload, base_context)
	if event_record.is_empty():
		return
	var event_signature: String = _get_event_signature(event_record)
	for existing_variant in events:
		if typeof(existing_variant) != TYPE_DICTIONARY:
			continue
		if _get_event_signature(existing_variant) == event_signature:
			return
	events.append(event_record)


func list_event_names(events: Array) -> Array:
	var event_names: Array = []
	for event_variant in events:
		if typeof(event_variant) == TYPE_DICTIONARY:
			var event_record: Dictionary = event_variant
			var event_name: String = str(event_record.get("name", ""))
			if event_name != "":
				event_names.append(event_name)
			continue
		var fallback_name: String = str(event_variant)
		if fallback_name != "":
			event_names.append(fallback_name)
	return event_names


func build_base_payload(
	target_binding: Dictionary,
	target_profile: Dictionary,
	hit_result: Dictionary,
	writeback_result: Dictionary,
	damage_source := ""
) -> Dictionary:
	var payload := {
		"target_id": str(target_binding.get("target_id", "")),
		"target_profile_id": str(target_binding.get("target_profile_id", target_profile.get("id", ""))),
		"target_kind": str(target_binding.get("target_kind", "")),
		"hurtbox_id": str(hit_result.get("hurtbox_id", "")),
		"hurtbox_kind": str(target_profile.get("hurtbox_kind", "")),
		"resource_channel": str(writeback_result.get("resource_channel", target_binding.get("resource_channel", ""))),
		"pool_key": str(writeback_result.get("pool_key", target_binding.get("pool_key", ""))),
		"amount": float(writeback_result.get("amount", 0.0)),
		"applied": bool(writeback_result.get("applied", false)),
		"killed": bool(writeback_result.get("killed", false)),
		"damage_source": damage_source,
		"attack_profile_id": str(hit_result.get("attack_profile_id", "")),
		"target_state": str(hit_result.get("target_state", "")),
		"contact_point": hit_result.get("contact_point", Vector2.ZERO),
		"channels": _duplicate_dictionary(hit_result.get("applied_channels", {})),
		"raw_channels": _duplicate_dictionary(hit_result.get("raw_channels", {})),
		"buildup": _duplicate_dictionary(hit_result.get("applied_buildup", {})),
	}
	if writeback_result.has("resource_before"):
		payload["resource_before"] = float(writeback_result.get("resource_before", 0.0))
	if writeback_result.has("resource_after"):
		payload["resource_after"] = float(writeback_result.get("resource_after", 0.0))
	if writeback_result.has("resource_max"):
		payload["resource_max"] = float(writeback_result.get("resource_max", 0.0))
	return payload


func collect_events(
	target_binding: Dictionary,
	target_profile: Dictionary,
	hit_result: Dictionary,
	writeback_result: Dictionary,
	target_state: Dictionary,
	damage_source := ""
) -> Dictionary:
	target_state = prime_target_state(target_state)
	var events: Array = []
	var base_payload: Dictionary = build_base_payload(target_binding, target_profile, hit_result, writeback_result, damage_source)
	for event_variant in hit_result.get("triggered_events", []):
		append_event_record(
			events,
			event_variant,
			base_payload,
			{
				"trigger": "damage_resolver",
			}
		)
	var buildup_result: Dictionary = _apply_buildup_progress(target_profile, hit_result.get("applied_buildup", {}), target_state, base_payload)
	target_state = buildup_result.get("target_state", target_state)
	for event_variant in buildup_result.get("events", []):
		append_event_record(events, event_variant)
	var guard_result: Dictionary = _apply_guard_progress(target_profile, hit_result.get("applied_channels", {}), target_state, base_payload)
	target_state = guard_result.get("target_state", target_state)
	for event_variant in guard_result.get("events", []):
		append_event_record(events, event_variant)
	var structural_result: Dictionary = _collect_structural_events(target_binding, target_profile, writeback_result, target_state, base_payload)
	target_state = structural_result.get("target_state", target_state)
	for event_variant in structural_result.get("events", []):
		append_event_record(events, event_variant)
	return {
		"events": events,
		"event_names": list_event_names(events),
		"target_state": target_state,
	}


func dispatch_events(
	main: Node,
	target_binding: Dictionary,
	target_profile: Dictionary,
	response_events: Array,
	_damage_source := ""
) -> Dictionary:
	var applied_response_events: Array = []
	for event_variant in response_events:
		var event_record: Dictionary = _normalize_event_record(event_variant)
		if event_record.is_empty():
			continue
		var event_name: String = str(event_record.get("name", ""))
		var handler_id: String = _resolve_handler_id(event_name, target_profile)
		if handler_id == "":
			continue
		event_record["handler_id"] = handler_id
		if _apply_handler(main, target_binding, target_profile, event_record):
			applied_response_events.append(event_record)
	return {
		"applied_response_events": applied_response_events,
		"applied_response_event_names": list_event_names(applied_response_events),
	}


func _apply_buildup_progress(
	target_profile: Dictionary,
	applied_buildup: Dictionary,
	target_state: Dictionary,
	base_payload: Dictionary
) -> Dictionary:
	var events: Array = []
	if applied_buildup.is_empty():
		return {
			"events": events,
			"target_state": target_state,
		}
	var buildup_pools: Dictionary = target_state.get("buildup_pools", {})
	var buildup_resist: Dictionary = target_profile.get("buildup_resist", {})
	var buildup_thresholds: Dictionary = target_profile.get("buildup_thresholds", {})
	for buildup_key_variant in applied_buildup.keys():
		var buildup_key: String = str(buildup_key_variant)
		var raw_amount: float = maxf(float(applied_buildup[buildup_key_variant]), 0.0)
		var effective_amount: float = maxf(raw_amount - float(buildup_resist.get(buildup_key, 0.0)), 0.0)
		if effective_amount <= 0.0:
			continue
		var previous_value: float = float(buildup_pools.get(buildup_key, 0.0))
		var current_value: float = previous_value + effective_amount
		buildup_pools[buildup_key] = current_value
		if not buildup_thresholds.has(buildup_key):
			continue
		var threshold_def: Variant = buildup_thresholds[buildup_key]
		var threshold_value: float = _get_threshold_value(threshold_def)
		if threshold_value <= 0.0:
			continue
		if previous_value < threshold_value and current_value >= threshold_value:
			var consume_on_trigger: bool = typeof(threshold_def) == TYPE_DICTIONARY and bool(threshold_def.get("consume_on_trigger", false))
			var threshold_payload: Dictionary = _merge_dictionaries(
				base_payload,
				{
					"buildup_key": buildup_key,
					"buildup_amount": effective_amount,
					"buildup_previous": previous_value,
					"buildup_current": current_value,
				}
			)
			var threshold_context := {
				"trigger": "buildup_threshold",
				"buildup_key": buildup_key,
				"threshold": threshold_value,
				"consume_on_trigger": consume_on_trigger,
			}
			var threshold_events: Array = _get_threshold_events(threshold_def, buildup_key)
			for event_variant in threshold_events:
				append_event_record(events, event_variant, threshold_payload, threshold_context)
			if consume_on_trigger:
				buildup_pools[buildup_key] = maxf(current_value - threshold_value, 0.0)
	target_state["buildup_pools"] = buildup_pools
	return {
		"events": events,
		"target_state": target_state,
	}


func _apply_guard_progress(
	target_profile: Dictionary,
	applied_channels: Dictionary,
	target_state: Dictionary,
	base_payload: Dictionary
) -> Dictionary:
	var guard_max: float = maxf(float(target_profile.get("guard_max", 0.0)), 0.0)
	if guard_max <= 0.0:
		return {
			"events": [],
			"target_state": target_state,
		}
	var guard_initialized: bool = bool(target_state.get("guard_initialized", false))
	var guard_value: float = float(target_state.get("guard_value", guard_max))
	if not guard_initialized:
		guard_value = guard_max
		target_state["guard_initialized"] = true
	var guard_damage: float = maxf(float(applied_channels.get("guard", 0.0)), 0.0)
	var events: Array = []
	if guard_damage > 0.0:
		var previous_guard: float = guard_value
		guard_value = maxf(previous_guard - guard_damage, 0.0)
		if previous_guard > 0.0 and guard_value <= 0.0:
			var guard_payload: Dictionary = _merge_dictionaries(
				base_payload,
				{
					"guard_damage": guard_damage,
					"guard_before": previous_guard,
					"guard_after": guard_value,
					"guard_max": guard_max,
				}
			)
			var guard_context := {
				"trigger": "guard_break",
				"guard_before": previous_guard,
				"guard_after": guard_value,
				"guard_max": guard_max,
			}
			for event_variant in target_profile.get("guard_break_events", [EVENT_GUARD_BREAK]):
				append_event_record(events, event_variant, guard_payload, guard_context)
	target_state["guard_value"] = guard_value
	return {
		"events": events,
		"target_state": target_state,
	}


func _collect_structural_events(
	target_binding: Dictionary,
	target_profile: Dictionary,
	writeback_result: Dictionary,
	target_state: Dictionary,
	base_payload: Dictionary
) -> Dictionary:
	var events: Array = []
	var triggered_rule_events: Dictionary = target_state.get("triggered_rule_events", {})
	for rule_variant in target_profile.get("part_break_rules", []):
		if typeof(rule_variant) != TYPE_DICTIONARY:
			continue
		var rule: Dictionary = rule_variant
		var rule_id: String = str(rule.get("id", ""))
		if rule_id != "" and bool(rule.get("once", true)) and triggered_rule_events.has(rule_id):
			continue
		var evaluation: Dictionary = _evaluate_structural_rule(target_binding, rule, writeback_result, target_state)
		if not bool(evaluation.get("triggered", false)):
			continue
		var structural_payload: Dictionary = _merge_dictionaries(base_payload, evaluation.get("payload", {}))
		var structural_context: Dictionary = _merge_dictionaries(
			{
				"trigger": "structural_rule",
				"rule_id": rule_id,
				"trigger_id": str(rule.get("when", "resource_depleted")),
				"once": bool(rule.get("once", true)),
			},
			evaluation.get("context", {})
		)
		for event_variant in rule.get("events", [EVENT_PART_BREAK]):
			append_event_record(events, event_variant, structural_payload, structural_context)
		if rule_id != "":
			triggered_rule_events[rule_id] = true
	target_state["triggered_rule_events"] = triggered_rule_events
	return {
		"events": events,
		"target_state": target_state,
	}


func _evaluate_structural_rule(
	target_binding: Dictionary,
	rule: Dictionary,
	writeback_result: Dictionary,
	target_state: Dictionary
) -> Dictionary:
	var trigger_id: String = str(rule.get("when", "resource_depleted"))
	var evaluator: Callable = _structural_rule_evaluators.get(trigger_id, Callable())
	if not evaluator.is_valid():
		return {
			"triggered": false,
			"payload": {},
			"context": {},
		}
	var evaluation_variant: Variant = evaluator.call(target_binding, rule, writeback_result, target_state)
	if typeof(evaluation_variant) == TYPE_DICTIONARY:
		var evaluation: Dictionary = evaluation_variant.duplicate(true)
		if not evaluation.has("triggered"):
			evaluation["triggered"] = bool(evaluation.get("passed", false))
		if not evaluation.has("payload"):
			evaluation["payload"] = {}
		if not evaluation.has("context"):
			evaluation["context"] = {}
		return evaluation
	return {
		"triggered": bool(evaluation_variant),
		"payload": {},
		"context": {},
	}


func _resolve_handler_id(event_name: String, target_profile: Dictionary) -> String:
	var event_handler_bindings: Dictionary = target_profile.get("event_handler_bindings", {})
	if event_handler_bindings.has(event_name):
		return str(event_handler_bindings[event_name])
	if event_name.begins_with(EVENT_BUILDUP_THRESHOLD_PREFIX) and event_handler_bindings.has("buildup_threshold"):
		return str(event_handler_bindings["buildup_threshold"])
	return event_name


func _apply_handler(
	main: Node,
	target_binding: Dictionary,
	target_profile: Dictionary,
	event_record: Dictionary
) -> bool:
	var handler_id: String = str(event_record.get("handler_id", ""))
	var handler: Callable = _event_handlers.get(handler_id, Callable())
	if not handler.is_valid():
		return false
	return bool(handler.call(main, target_binding, target_profile, event_record))


func _handle_enemy_stagger(
	_main: Node,
	target_binding: Dictionary,
	target_profile: Dictionary,
	_event_record: Dictionary
) -> bool:
	if str(target_binding.get("target_kind", "")) != "enemy":
		return false
	var enemy: Variant = target_binding.get("entity", null)
	if enemy == null or float(enemy.get("health", 0.0)) <= 0.0:
		return false
	var break_duration: float = maxf(float(target_profile.get("break_duration", 0.0)), 0.0)
	if break_duration <= 0.0:
		return false
	enemy["stagger_timer"] = maxf(float(enemy.get("stagger_timer", 0.0)), break_duration)
	enemy["vel"] = Vector2.ZERO
	return true


func _handle_boss_vulnerability(
	main: Node,
	target_binding: Dictionary,
	target_profile: Dictionary,
	event_record: Dictionary
) -> bool:
	if str(target_binding.get("target_kind", "")) != "boss" or not main._has_boss():
		return false
	var payload: Dictionary = event_record.get("payload", {})
	var vulnerable_duration: float = maxf(float(payload.get("break_duration", target_profile.get("break_duration", 0.0))), 0.0)
	if vulnerable_duration <= 0.0:
		return false
	return main._open_boss_vulnerability_window(vulnerable_duration)


func _handle_boss_core_exposure(
	main: Node,
	target_binding: Dictionary,
	_target_profile: Dictionary,
	_event_record: Dictionary
) -> bool:
	if str(target_binding.get("target_kind", "")) != "boss" or not main._has_boss():
		return false
	if not main._is_boss_core_open():
		return false
	return true


func _handle_part_break_feedback(
	main: Node,
	target_binding: Dictionary,
	_target_profile: Dictionary,
	event_record: Dictionary
) -> bool:
	var event_position: Vector2 = _resolve_event_position(main, target_binding, event_record)
	main._create_particles(event_position, main.COLORS.get("silk", Color.WHITE), 14)
	return true


func _handle_tether_sever_feedback(
	main: Node,
	target_binding: Dictionary,
	_target_profile: Dictionary,
	_event_record: Dictionary
) -> bool:
	if str(target_binding.get("target_kind", "")) != "silk":
		return false
	main._show_status_message("丝线断裂", main.COLORS.get("silk", Color.WHITE), 0.45)
	return true


func _handle_guard_break_feedback(
	main: Node,
	_target_binding: Dictionary,
	_target_profile: Dictionary,
	_event_record: Dictionary
) -> bool:
	main._show_status_message("格挡崩解", Color.WHITE, 0.45)
	return true


func _handle_buildup_threshold_feedback(
	main: Node,
	_target_binding: Dictionary,
	_target_profile: Dictionary,
	event_record: Dictionary
) -> bool:
	var event_name: String = str(event_record.get("name", ""))
	var payload: Dictionary = event_record.get("payload", {})
	var buildup_key: String = str(payload.get("buildup_key", event_name.trim_prefix(EVENT_BUILDUP_THRESHOLD_PREFIX)))
	var message: String = "积累触发"
	if buildup_key != "":
		message = "%s触发" % buildup_key
	main._show_status_message(message, Color.WHITE, 0.45)
	return true


func _rule_resource_depleted(
	_target_binding: Dictionary,
	_rule: Dictionary,
	writeback_result: Dictionary,
	_target_state: Dictionary
) -> Dictionary:
	return {
		"triggered": bool(writeback_result.get("killed", false)),
		"payload": {
			"resource_before": float(writeback_result.get("resource_before", 0.0)),
			"resource_after": float(writeback_result.get("resource_after", 0.0)),
			"resource_max": float(writeback_result.get("resource_max", 0.0)),
		},
		"context": {
			"trigger": "resource_depleted",
		},
	}


func _rule_resource_zero(
	_target_binding: Dictionary,
	_rule: Dictionary,
	writeback_result: Dictionary,
	_target_state: Dictionary
) -> Dictionary:
	var resource_after: float = float(writeback_result.get("resource_after", INF))
	var triggered: bool = resource_after <= 0.0 or bool(writeback_result.get("killed", false))
	return {
		"triggered": triggered,
		"payload": {
			"resource_before": float(writeback_result.get("resource_before", 0.0)),
			"resource_after": resource_after,
			"resource_max": float(writeback_result.get("resource_max", 0.0)),
		},
		"context": {
			"trigger": "resource_zero",
		},
	}


func _rule_target_kind(
	target_binding: Dictionary,
	rule: Dictionary,
	_writeback_result: Dictionary,
	_target_state: Dictionary
) -> Dictionary:
	var actual_kind: String = str(target_binding.get("target_kind", ""))
	var expected_kind: String = str(rule.get("target_kind", ""))
	return {
		"triggered": actual_kind == expected_kind and expected_kind != "",
		"context": {
			"trigger": "target_kind",
			"expected_target_kind": expected_kind,
			"actual_target_kind": actual_kind,
		},
	}


func _resolve_event_position(main: Node, target_binding: Dictionary, event_record := {}) -> Vector2:
	if typeof(event_record) == TYPE_DICTIONARY:
		var payload: Dictionary = event_record.get("payload", {})
		if payload.has("contact_point"):
			return payload.get("contact_point", main.ARENA_SIZE * 0.5)
	match str(target_binding.get("target_kind", "")):
		"enemy":
			var enemy: Variant = target_binding.get("entity", null)
			if enemy != null:
				return enemy.get("pos", main.ARENA_SIZE * 0.5)
		"boss":
			if main._has_boss():
				return main.boss.get("pos", main.ARENA_SIZE * 0.5)
		"silk":
			var silk_aux: Dictionary = target_binding.get("aux", {})
			if silk_aux.has("to"):
				return silk_aux.get("to", main.ARENA_SIZE * 0.5)
	return main.ARENA_SIZE * 0.5


func _get_threshold_value(threshold_def: Variant) -> float:
	if typeof(threshold_def) == TYPE_DICTIONARY:
		return maxf(float(threshold_def.get("threshold", 0.0)), 0.0)
	return maxf(float(threshold_def), 0.0)


func _get_threshold_events(threshold_def: Variant, buildup_key: String) -> Array:
	if typeof(threshold_def) == TYPE_DICTIONARY:
		var threshold_events: Array = threshold_def.get("events", [])
		if not threshold_events.is_empty():
			return threshold_events.duplicate(true)
	return ["%s%s" % [EVENT_BUILDUP_THRESHOLD_PREFIX, buildup_key]]


func _normalize_event_record(event_variant: Variant, base_payload := {}, base_context := {}) -> Dictionary:
	var event_name := ""
	var payload: Dictionary = _duplicate_dictionary(base_payload)
	var context: Dictionary = _duplicate_dictionary(base_context)
	if typeof(event_variant) == TYPE_DICTIONARY:
		var raw_event: Dictionary = event_variant
		event_name = str(raw_event.get("name", raw_event.get("event", raw_event.get("id", ""))))
		payload = _merge_dictionaries(payload, raw_event.get("payload", {}))
		context = _merge_dictionaries(context, raw_event.get("context", {}))
		if raw_event.has("handler_id"):
			context["handler_id"] = str(raw_event.get("handler_id", ""))
	else:
		event_name = str(event_variant)
	if event_name == "":
		return {}
	var event_record := make_event_record(event_name, payload, context)
	if context.has("handler_id"):
		event_record["handler_id"] = str(context.get("handler_id", ""))
	return event_record


func _get_event_signature(event_variant: Variant) -> String:
	if typeof(event_variant) != TYPE_DICTIONARY:
		return str(event_variant)
	var event_record: Dictionary = event_variant
	var event_name: String = str(event_record.get("name", ""))
	var context: Dictionary = event_record.get("context", {})
	var signature_parts := [event_name]
	if context.has("rule_id"):
		signature_parts.append(str(context.get("rule_id", "")))
	if context.has("buildup_key"):
		signature_parts.append(str(context.get("buildup_key", "")))
	if context.has("trigger"):
		signature_parts.append(str(context.get("trigger", "")))
	return "::".join(signature_parts)


func _merge_dictionaries(base_value: Variant, overlay_value: Variant) -> Dictionary:
	var merged: Dictionary = _duplicate_dictionary(base_value)
	var overlay: Dictionary = _duplicate_dictionary(overlay_value)
	for key in overlay.keys():
		merged[key] = overlay[key]
	return merged


func _duplicate_dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value.duplicate(true)
	return {}
