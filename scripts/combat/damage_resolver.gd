extends RefCounted
class_name DamageResolver


const AttackProfiles = preload("res://scripts/combat/attack_profiles.gd")
const TargetProfiles = preload("res://scripts/combat/target_profiles.gd")

const RULE_TAG_GATE := "tag_gate"
const RULE_STATE_GATE := "state_gate"
const STAGE_BUILD_RAW_CHANNELS := "build_raw_channels"
const STAGE_RUNTIME_CHANNEL_SCALARS := "runtime_channel_scalars"
const RULE_ALLOW_HP_DAMAGE := "allow_hp_damage"
const RULE_HP_ARMOR := "hp_armor"
const RULE_POISE_RESIST := "poise_resist"
const RULE_SILK_ONLY_SEVER := "silk_only_sever"
const RULE_SILK_SEVER_PROGRESS := "silk_sever_progress"

var _gate_rules: Dictionary = {}
var _gate_rule_order: Array = []
var _channel_stages: Dictionary = {}
var _channel_stage_order: Array = []
var _mitigation_rules: Dictionary = {}
var _mitigation_rule_order: Array = []
var _post_rules: Dictionary = {}
var _post_rule_order: Array = []


func _init() -> void:
	reset_defaults()


func clear() -> void:
	_gate_rules.clear()
	_gate_rule_order.clear()
	_channel_stages.clear()
	_channel_stage_order.clear()
	_mitigation_rules.clear()
	_mitigation_rule_order.clear()
	_post_rules.clear()
	_post_rule_order.clear()


func reset_defaults() -> void:
	clear()
	register_gate_rule(RULE_TAG_GATE, Callable(self, "_gate_tag"))
	register_gate_rule(RULE_STATE_GATE, Callable(self, "_gate_required_state"))
	register_channel_stage(STAGE_BUILD_RAW_CHANNELS, Callable(self, "_stage_build_raw_channels"))
	register_channel_stage(STAGE_RUNTIME_CHANNEL_SCALARS, Callable(self, "_stage_apply_runtime_channel_scalars"))
	register_mitigation_rule(RULE_ALLOW_HP_DAMAGE, Callable(self, "_mitigation_allow_hp_damage"))
	register_mitigation_rule(RULE_HP_ARMOR, Callable(self, "_mitigation_hp_armor"))
	register_mitigation_rule(RULE_POISE_RESIST, Callable(self, "_mitigation_poise_resist"))
	register_mitigation_rule(RULE_SILK_ONLY_SEVER, Callable(self, "_mitigation_silk_only_sever"))
	register_post_rule(RULE_SILK_SEVER_PROGRESS, Callable(self, "_post_trigger_silk_sever_progress"))


func register_gate_rule(rule_id: String, rule: Callable) -> void:
	_register_stage(_gate_rules, _gate_rule_order, rule_id, rule)


func unregister_gate_rule(rule_id: String) -> void:
	_unregister_stage(_gate_rules, _gate_rule_order, rule_id)


func has_gate_rule(rule_id: String) -> bool:
	return _gate_rules.has(rule_id)


func list_gate_rule_ids() -> Array:
	return _gate_rule_order.duplicate()


func register_channel_stage(stage_id: String, stage: Callable) -> void:
	_register_stage(_channel_stages, _channel_stage_order, stage_id, stage)


func unregister_channel_stage(stage_id: String) -> void:
	_unregister_stage(_channel_stages, _channel_stage_order, stage_id)


func has_channel_stage(stage_id: String) -> bool:
	return _channel_stages.has(stage_id)


func list_channel_stage_ids() -> Array:
	return _channel_stage_order.duplicate()


func register_mitigation_rule(rule_id: String, rule: Callable) -> void:
	_register_stage(_mitigation_rules, _mitigation_rule_order, rule_id, rule)


func unregister_mitigation_rule(rule_id: String) -> void:
	_unregister_stage(_mitigation_rules, _mitigation_rule_order, rule_id)


func has_mitigation_rule(rule_id: String) -> bool:
	return _mitigation_rules.has(rule_id)


func list_mitigation_rule_ids() -> Array:
	return _mitigation_rule_order.duplicate()


func register_post_rule(rule_id: String, rule: Callable) -> void:
	_register_stage(_post_rules, _post_rule_order, rule_id, rule)


func unregister_post_rule(rule_id: String) -> void:
	_unregister_stage(_post_rules, _post_rule_order, rule_id)


func has_post_rule(rule_id: String) -> bool:
	return _post_rules.has(rule_id)


func list_post_rule_ids() -> Array:
	return _post_rule_order.duplicate()


func resolve_hit(hit_request: Dictionary, attack_profile: Dictionary, target_profile: Dictionary) -> Dictionary:
	var context := _build_context(hit_request, attack_profile, target_profile)
	var result: Dictionary = context.get("result", {})
	var gate_result: Dictionary = _run_gate_rules(context)
	if not bool(gate_result.get("passed", true)):
		result["allowed"] = false
		result["blocked_reason"] = str(gate_result.get("blocked_reason", ""))
		result["blocked_rule_id"] = str(gate_result.get("rule_id", ""))
		context["result"] = result
		return result
	_run_stages(_channel_stage_order, _channel_stages, context)
	result = context.get("result", result)
	result["applied_channels"] = _duplicate_dictionary(result.get("raw_channels", {}))
	context["result"] = result
	_run_stages(_mitigation_rule_order, _mitigation_rules, context)
	_run_stages(_post_rule_order, _post_rules, context)
	return context.get("result", result)


func _build_context(hit_request: Dictionary, attack_profile: Dictionary, target_profile: Dictionary) -> Dictionary:
	var attack_profile_copy: Dictionary = attack_profile.duplicate(true)
	var target_profile_copy: Dictionary = target_profile.duplicate(true)
	var hit_request_copy: Dictionary = hit_request.duplicate(true)
	return {
		"hit_request": hit_request_copy,
		"attack_profile": attack_profile_copy,
		"target_profile": target_profile_copy,
		"result": {
			"allowed": true,
			"blocked_reason": "",
			"blocked_rule_id": "",
			"raw_channels": {},
			"applied_channels": {},
			"applied_buildup": _duplicate_dictionary(attack_profile_copy.get("buildup", {})),
			"triggered_events": [],
			"attack_profile_id": str(hit_request_copy.get("attack_profile_id", attack_profile_copy.get("id", ""))),
			"target_id": str(hit_request_copy.get("target_id", "")),
			"hurtbox_id": str(hit_request_copy.get("hurtbox_id", "")),
			"target_state": str(hit_request_copy.get("target_state", "")),
			"contact_point": hit_request_copy.get("contact_point", Vector2.ZERO),
		},
	}


func _run_gate_rules(context: Dictionary) -> Dictionary:
	for rule_id_variant in _gate_rule_order:
		var rule_id: String = str(rule_id_variant)
		var rule: Callable = _gate_rules.get(rule_id, Callable())
		if not rule.is_valid():
			continue
		var gate_result: Dictionary = _normalize_gate_result(rule.call(context))
		if not bool(gate_result.get("passed", true)):
			if str(gate_result.get("rule_id", "")) == "":
				gate_result["rule_id"] = rule_id
			return gate_result
	return {
		"passed": true,
		"blocked_reason": "",
		"rule_id": "",
	}


func _run_stages(stage_order: Array, stages: Dictionary, context: Dictionary) -> void:
	for stage_id_variant in stage_order:
		var stage_id: String = str(stage_id_variant)
		var stage: Callable = stages.get(stage_id, Callable())
		if not stage.is_valid():
			continue
		stage.call(context)


func _normalize_gate_result(result_variant: Variant) -> Dictionary:
	if typeof(result_variant) == TYPE_DICTIONARY:
		var result: Dictionary = result_variant.duplicate(true)
		if not result.has("passed"):
			result["passed"] = bool(result.get("allowed", true))
		if not result.has("blocked_reason"):
			result["blocked_reason"] = str(result.get("reason", ""))
		if not result.has("rule_id"):
			result["rule_id"] = ""
		return result
	return {
		"passed": bool(result_variant),
		"blocked_reason": "",
		"rule_id": "",
	}


func _register_stage(stage_map: Dictionary, stage_order: Array, stage_id: String, stage: Callable) -> void:
	if stage_id == "" or not stage.is_valid():
		return
	if not stage_map.has(stage_id):
		stage_order.append(stage_id)
	stage_map[stage_id] = stage


func _unregister_stage(stage_map: Dictionary, stage_order: Array, stage_id: String) -> void:
	if stage_id == "":
		return
	stage_map.erase(stage_id)
	stage_order.erase(stage_id)


func _gate_tag(context: Dictionary) -> Dictionary:
	var attack_profile: Dictionary = context.get("attack_profile", {})
	var target_profile: Dictionary = context.get("target_profile", {})
	var accepted_tags: Array = target_profile.get("accept_tags", [])
	if accepted_tags.is_empty():
		return {"passed": true}
	var attack_tags: Array = attack_profile.get("tags", [])
	for tag in attack_tags:
		if accepted_tags.has(tag):
			return {"passed": true}
	return {
		"passed": false,
		"blocked_reason": "tag_blocked",
	}


func _gate_required_state(context: Dictionary) -> Dictionary:
	var hit_request: Dictionary = context.get("hit_request", {})
	var target_profile: Dictionary = context.get("target_profile", {})
	var required_state: String = str(target_profile.get("requires_state", ""))
	if required_state == "":
		return {"passed": true}
	var target_state: String = str(hit_request.get("target_state", ""))
	return {
		"passed": target_state == required_state,
		"blocked_reason": "state_blocked",
	}


func _stage_build_raw_channels(context: Dictionary) -> void:
	var hit_request: Dictionary = context.get("hit_request", {})
	var attack_profile: Dictionary = context.get("attack_profile", {})
	var target_profile: Dictionary = context.get("target_profile", {})
	var hurtbox_kind: String = str(target_profile.get("hurtbox_kind", ""))
	var channel_mode: String = AttackProfiles.get_channel_mode_for_hurtbox(attack_profile, hurtbox_kind)
	var raw_channels: Dictionary = {}
	if channel_mode == "dps":
		raw_channels = _scale_channels(
			_duplicate_dictionary(attack_profile.get("dps_channels", {})),
			maxf(float(hit_request.get("contact_time", 0.0)), 0.0)
		)
	else:
		raw_channels = _duplicate_dictionary(attack_profile.get("channels", {}))
	var result: Dictionary = context.get("result", {})
	result["raw_channels"] = raw_channels
	context["result"] = result


func _stage_apply_runtime_channel_scalars(context: Dictionary) -> void:
	var hit_request: Dictionary = context.get("hit_request", {})
	var result: Dictionary = context.get("result", {})
	var raw_channels: Dictionary = _duplicate_dictionary(result.get("raw_channels", {}))
	result["raw_channels"] = _apply_runtime_channel_scalars(raw_channels, hit_request)
	context["result"] = result


func _mitigation_allow_hp_damage(context: Dictionary) -> void:
	var result: Dictionary = context.get("result", {})
	var target_profile: Dictionary = context.get("target_profile", {})
	var applied_channels: Dictionary = _duplicate_dictionary(result.get("applied_channels", {}))
	if applied_channels.has(AttackProfiles.CHANNEL_HP) and not bool(target_profile.get("allow_hp_damage", true)):
		applied_channels[AttackProfiles.CHANNEL_HP] = 0.0
	result["applied_channels"] = applied_channels
	context["result"] = result


func _mitigation_hp_armor(context: Dictionary) -> void:
	var result: Dictionary = context.get("result", {})
	var target_profile: Dictionary = context.get("target_profile", {})
	var applied_channels: Dictionary = _duplicate_dictionary(result.get("applied_channels", {}))
	if applied_channels.has(AttackProfiles.CHANNEL_HP):
		var armor: float = maxf(float(target_profile.get("armor", 0.0)), 0.0)
		applied_channels[AttackProfiles.CHANNEL_HP] = maxf(
			float(applied_channels.get(AttackProfiles.CHANNEL_HP, 0.0)) - armor,
			0.0
		)
	result["applied_channels"] = applied_channels
	context["result"] = result


func _mitigation_poise_resist(context: Dictionary) -> void:
	var result: Dictionary = context.get("result", {})
	var target_profile: Dictionary = context.get("target_profile", {})
	var applied_channels: Dictionary = _duplicate_dictionary(result.get("applied_channels", {}))
	if applied_channels.has(AttackProfiles.CHANNEL_POISE):
		var poise_resist: float = maxf(float(target_profile.get("poise_resist", 0.0)), 0.0)
		applied_channels[AttackProfiles.CHANNEL_POISE] = maxf(
			float(applied_channels.get(AttackProfiles.CHANNEL_POISE, 0.0)) - poise_resist,
			0.0
		)
	result["applied_channels"] = applied_channels
	context["result"] = result


func _mitigation_silk_only_sever(context: Dictionary) -> void:
	var result: Dictionary = context.get("result", {})
	var target_profile: Dictionary = context.get("target_profile", {})
	var applied_channels: Dictionary = _duplicate_dictionary(result.get("applied_channels", {}))
	if applied_channels.has(AttackProfiles.CHANNEL_SEVER):
		if str(target_profile.get("hurtbox_kind", "")) != TargetProfiles.HURTBOX_SILK:
			applied_channels[AttackProfiles.CHANNEL_SEVER] = 0.0
	result["applied_channels"] = applied_channels
	context["result"] = result


func _post_trigger_silk_sever_progress(context: Dictionary) -> void:
	var result: Dictionary = context.get("result", {})
	var target_profile: Dictionary = context.get("target_profile", {})
	var applied_channels: Dictionary = result.get("applied_channels", {})
	if str(target_profile.get("hurtbox_kind", "")) != TargetProfiles.HURTBOX_SILK:
		return
	var sever_amount: float = float(applied_channels.get(AttackProfiles.CHANNEL_SEVER, 0.0))
	if sever_amount <= 0.0:
		return
	var triggered_events: Array = result.get("triggered_events", [])
	if _has_event_name(triggered_events, "sever_progress"):
		return
	triggered_events.append({
		"name": "sever_progress",
		"payload": {
			"resource_channel": AttackProfiles.CHANNEL_SEVER,
			"amount": sever_amount,
			"hurtbox_kind": TargetProfiles.HURTBOX_SILK,
		},
		"context": {
			"trigger": "damage_resolver",
			"rule_id": RULE_SILK_SEVER_PROGRESS,
		},
	})
	result["triggered_events"] = triggered_events
	context["result"] = result


func _apply_runtime_channel_scalars(raw_channels: Dictionary, hit_request: Dictionary) -> Dictionary:
	var scaled_channels: Dictionary = _scale_channels(raw_channels, maxf(float(hit_request.get("channel_scalar", 1.0)), 0.0))
	var channel_scalar_overrides: Dictionary = hit_request.get("channel_scalar_overrides", {})
	for channel_name_variant in channel_scalar_overrides.keys():
		var channel_name: String = str(channel_name_variant)
		var scaled_value: float = maxf(float(channel_scalar_overrides[channel_name_variant]), 0.0)
		if scaled_channels.has(channel_name):
			scaled_channels[channel_name] = maxf(float(scaled_channels.get(channel_name, 0.0)) * scaled_value, 0.0)
			continue
		if raw_channels.has(channel_name):
			scaled_channels[channel_name] = maxf(float(raw_channels.get(channel_name, 0.0)) * scaled_value, 0.0)
	return scaled_channels


func _scale_channels(channels: Dictionary, factor: float) -> Dictionary:
	var scaled: Dictionary = {}
	for channel_name_variant in channels.keys():
		var channel_name: String = str(channel_name_variant)
		scaled[channel_name] = float(channels[channel_name_variant]) * factor
	return scaled


func _duplicate_dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value.duplicate(true)
	return {}


func _has_event_name(events: Array, event_name: String) -> bool:
	for event_variant in events:
		if typeof(event_variant) == TYPE_DICTIONARY:
			var event_record: Dictionary = event_variant
			if str(event_record.get("name", "")) == event_name:
				return true
			continue
		if str(event_variant) == event_name:
			return true
	return false
