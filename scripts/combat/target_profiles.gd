extends RefCounted
class_name TargetProfiles


const HURTBOX_BODY := "body"
const HURTBOX_CORE := "core"
const HURTBOX_SILK := "silk"
const HURTBOX_ARMOR := "armor"

const PROFILE_ENEMY_BODY := "enemy_body"
const PROFILE_PUPPET_BODY := "puppet_body"
const PROFILE_BOSS_BODY := "boss_body"
const PROFILE_BOSS_CORE := "boss_core"
const PROFILE_SILK_SEGMENT := "silk_segment"

const _DEFAULT_PROFILE := {
	"id": "",
	"team": "enemy",
	"hurtbox_kind": HURTBOX_BODY,
	"descriptor_role": "primary",
	"hp_pool_key": "health",
	"resource_channel": "hp",
	"writeback_adapter_id": "",
	"allow_hp_damage": true,
	"armor": 0.0,
	"poise_resist": 0.0,
	"max_poise": 0.0,
	"poise_recovery_delay": 0.0,
	"poise_recovery_rate": 0.0,
	"poise_break_events": [],
	"break_duration": 0.0,
	"guard_max": 0.0,
	"guard_break_events": [],
	"buildup_resist": {},
	"buildup_thresholds": {},
	"part_break_rules": [],
	"event_handler_bindings": {},
	"accept_tags": [],
	"requires_state": "",
	"state_gates": [],
}

const _PROFILES := {
	PROFILE_ENEMY_BODY: {
		"id": PROFILE_ENEMY_BODY,
		"team": "enemy",
		"hurtbox_kind": HURTBOX_BODY,
		"writeback_adapter_id": "enemy_health",
		"hp_pool_key": "health",
		"max_poise": 24.0,
		"poise_recovery_delay": 0.45,
		"poise_recovery_rate": 32.0,
		"poise_break_events": ["stagger"],
		"break_duration": 0.22,
		"event_handler_bindings": {
			"stagger": "enemy_stagger",
		},
		"accept_tags": ["slash", "thrust", "array", "projectile", "melee", "flying_sword"],
	},
	PROFILE_PUPPET_BODY: {
		"id": PROFILE_PUPPET_BODY,
		"team": "enemy",
		"hurtbox_kind": HURTBOX_BODY,
		"writeback_adapter_id": "enemy_health",
		"hp_pool_key": "health",
		"max_poise": 48.0,
		"poise_recovery_delay": 0.6,
		"poise_recovery_rate": 24.0,
		"poise_break_events": ["stagger"],
		"break_duration": 0.35,
		"event_handler_bindings": {
			"stagger": "enemy_stagger",
		},
		"accept_tags": [],
	},
	PROFILE_BOSS_BODY: {
		"id": PROFILE_BOSS_BODY,
		"team": "enemy",
		"hurtbox_kind": HURTBOX_BODY,
		"writeback_adapter_id": "boss_health",
		"hp_pool_key": "boss.health",
		"allow_hp_damage": false,
		"max_poise": 140.0,
		"poise_recovery_delay": 1.4,
		"poise_recovery_rate": 30.0,
		"poise_break_events": ["boss_vulnerable", "core_exposure"],
		"break_duration": 2.0,
		"event_handler_bindings": {
			"boss_vulnerable": "boss_vulnerability",
			"core_exposure": "boss_core_exposure",
		},
		"accept_tags": ["slash", "thrust", "array", "projectile", "flying_sword"],
	},
	PROFILE_BOSS_CORE: {
		"id": PROFILE_BOSS_CORE,
		"team": "enemy",
		"hurtbox_kind": HURTBOX_CORE,
		"writeback_adapter_id": "boss_health",
		"hp_pool_key": "boss.health",
		"event_handler_bindings": {
			"core_exposure": "boss_core_exposure",
		},
		"accept_tags": ["slash", "thrust", "array", "projectile", "flying_sword"],
		"requires_state": "vulnerable",
	},
	PROFILE_SILK_SEGMENT: {
		"id": PROFILE_SILK_SEGMENT,
		"team": "enemy",
		"hurtbox_kind": HURTBOX_SILK,
		"writeback_adapter_id": "silk_sever",
		"hp_pool_key": "silk.health",
		"resource_channel": "sever",
		"part_break_rules": [
			{
				"id": "silk_cut",
				"when": "resource_depleted",
				"events": ["part_break", "tether_sever"],
				"once": true,
			},
		],
		"event_handler_bindings": {
			"part_break": "part_break_feedback",
			"tether_sever": "tether_sever_feedback",
			"guard_break": "guard_break_feedback",
			"buildup_threshold": "buildup_threshold_feedback",
		},
		"accept_tags": ["slash", "thrust", "flying_sword"],
	},
}


static func has_profile(profile_id: String) -> bool:
	return _PROFILES.has(profile_id)


static func get_profile(profile_id: String) -> Dictionary:
	var profile: Dictionary = _DEFAULT_PROFILE.duplicate(true)
	var profile_override: Dictionary = _PROFILES.get(profile_id, {})
	_merge_dictionary(profile, profile_override)
	return profile


static func get_enemy_profile_id(enemy_type: String) -> String:
	return PROFILE_PUPPET_BODY if enemy_type == "puppet" else PROFILE_ENEMY_BODY


static func list_profile_ids() -> Array:
	return _PROFILES.keys()


static func _merge_dictionary(base: Dictionary, override: Dictionary) -> void:
	for key in override.keys():
		var override_value: Variant = override[key]
		if typeof(override_value) == TYPE_DICTIONARY and typeof(base.get(key, null)) == TYPE_DICTIONARY:
			var nested: Dictionary = base[key]
			_merge_dictionary(nested, override_value)
			base[key] = nested
			continue
		base[key] = _duplicate_value(override_value)


static func _duplicate_value(value: Variant) -> Variant:
	if typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY:
		return value.duplicate(true)
	return value
