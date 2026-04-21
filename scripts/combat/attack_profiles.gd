extends RefCounted
class_name AttackProfiles


const HIT_MODE_INSTANT := "instant"
const HIT_MODE_INTERVAL := "interval"
const HIT_MODE_CONTINUOUS := "continuous"

const REHIT_ONCE_PER_INSTANCE := "once_per_instance"
const REHIT_ONCE_PER_ENTRY := "once_per_entry"
const REHIT_INTERVAL_PER_TARGET := "interval_per_target"
const REHIT_CONTINUOUS_CONTACT := "continuous_contact"

const CHANNEL_HP := "hp"
const CHANNEL_POISE := "poise"
const CHANNEL_SEVER := "sever"

const BOSS_WINDOW_GATED := "gated"
const BOSS_WINDOW_BYPASS := "bypass"

const PROFILE_MELEE_SLASH := "melee_slash"
const PROFILE_FLYING_SWORD_POINT := "flying_sword_point"
const PROFILE_FLYING_SWORD_SLICE := "flying_sword_slice"
const PROFILE_ARRAY_RING := "array_ring"
const PROFILE_ARRAY_FAN := "array_fan"
const PROFILE_ARRAY_PIERCE := "array_pierce"
const PROFILE_DEFLECTED_BULLET := "deflected_bullet"
const PROFILE_ULTIMATE_PULSE := "ultimate_pulse"

const _DEFAULT_PROFILE := {
	"id": "",
	"tags": [],
	"shape": {
		"kind": "circle_overlap",
	},
	"hit_mode": HIT_MODE_INSTANT,
	"rehit_policy": REHIT_ONCE_PER_INSTANCE,
	"rehit_interval": 0.0,
	"rehit_policy_overrides": {},
	"rehit_interval_overrides": {},
	"pierce_targets": 1,
	"channel_mode_overrides": {},
	"channels": {
		CHANNEL_HP: 0.0,
		CHANNEL_POISE: 0.0,
		CHANNEL_SEVER: 0.0,
	},
	"dps_channels": {},
	"buildup": {},
	"effects": {},
	"boss_window_mode": BOSS_WINDOW_GATED,
}

const _PROFILES := {
	PROFILE_MELEE_SLASH: {
		"id": PROFILE_MELEE_SLASH,
		"tags": ["slash", "melee"],
		"shape": {
			"kind": "arc",
		},
		"channels": {
			CHANNEL_HP: 100.0,
			CHANNEL_POISE: 20.0,
			CHANNEL_SEVER: 6.0,
		},
	},
	PROFILE_FLYING_SWORD_POINT: {
		"id": PROFILE_FLYING_SWORD_POINT,
		"tags": ["thrust", "flying_sword"],
		"shape": {
			"kind": "segment_sweep",
		},
		"rehit_policy_overrides": {
			"silk": REHIT_CONTINUOUS_CONTACT,
		},
		"channel_mode_overrides": {
			"silk": "dps",
		},
		"channels": {
			CHANNEL_HP: 165.0,
			CHANNEL_POISE: 34.0,
			CHANNEL_SEVER: 6.0,
		},
		"dps_channels": {
			CHANNEL_SEVER: 90.0,
		},
	},
	PROFILE_FLYING_SWORD_SLICE: {
		"id": PROFILE_FLYING_SWORD_SLICE,
		"tags": ["slash", "contact", "flying_sword"],
		"shape": {
			"kind": "segment_sweep",
		},
		"hit_mode": HIT_MODE_INTERVAL,
		"rehit_policy": REHIT_INTERVAL_PER_TARGET,
		"rehit_interval": 0.05,
		"rehit_policy_overrides": {
			"silk": REHIT_CONTINUOUS_CONTACT,
		},
		"channel_mode_overrides": {
			"silk": "dps",
		},
		"channels": {
			CHANNEL_HP: 32.0,
			CHANNEL_POISE: 7.0,
			CHANNEL_SEVER: 12.0,
		},
		"dps_channels": {
			CHANNEL_SEVER: 160.0,
		},
	},
	PROFILE_ARRAY_RING: {
		"id": PROFILE_ARRAY_RING,
		"tags": ["array", "ring", "projectile"],
		"shape": {
			"kind": "projectile_contact",
		},
		"rehit_policy": REHIT_INTERVAL_PER_TARGET,
		"rehit_interval": 0.16,
		"channels": {
			CHANNEL_HP: 62.0,
			CHANNEL_POISE: 16.0,
			CHANNEL_SEVER: 0.0,
		},
	},
	PROFILE_ARRAY_FAN: {
		"id": PROFILE_ARRAY_FAN,
		"tags": ["array", "fan", "projectile"],
		"shape": {
			"kind": "projectile_contact",
		},
		"rehit_policy": REHIT_INTERVAL_PER_TARGET,
		"rehit_interval": 0.14,
		"channels": {
			CHANNEL_HP: 78.0,
			CHANNEL_POISE: 12.0,
			CHANNEL_SEVER: 0.0,
		},
	},
	PROFILE_ARRAY_PIERCE: {
		"id": PROFILE_ARRAY_PIERCE,
		"tags": ["array", "pierce", "projectile"],
		"shape": {
			"kind": "projectile_contact",
		},
		"rehit_policy": REHIT_INTERVAL_PER_TARGET,
		"rehit_interval": 0.12,
		"pierce_targets": 4,
		"channels": {
			CHANNEL_HP: 118.0,
			CHANNEL_POISE: 18.0,
			CHANNEL_SEVER: 0.0,
		},
	},
	PROFILE_DEFLECTED_BULLET: {
		"id": PROFILE_DEFLECTED_BULLET,
		"tags": ["projectile", "melee", "deflect"],
		"shape": {
			"kind": "projectile_contact",
		},
		"channels": {
			CHANNEL_HP: 20.0,
			CHANNEL_POISE: 6.0,
			CHANNEL_SEVER: 0.0,
		},
	},
	PROFILE_ULTIMATE_PULSE: {
		"id": PROFILE_ULTIMATE_PULSE,
		"tags": ["projectile", "ultimate", "aoe"],
		"shape": {
			"kind": "circle_overlap",
		},
		"channels": {
			CHANNEL_HP: 50.0,
			CHANNEL_POISE: 24.0,
			CHANNEL_SEVER: 0.0,
		},
		"boss_window_mode": BOSS_WINDOW_BYPASS,
	},
}


static func has_profile(profile_id: String) -> bool:
	return _PROFILES.has(profile_id)


static func get_profile(profile_id: String) -> Dictionary:
	var profile: Dictionary = _DEFAULT_PROFILE.duplicate(true)
	var profile_override: Dictionary = _PROFILES.get(profile_id, {})
	_merge_dictionary(profile, profile_override)
	return profile


static func list_profile_ids() -> Array:
	return _PROFILES.keys()


static func get_rehit_policy_for_hurtbox(profile: Dictionary, hurtbox_kind: String) -> String:
	var overrides: Dictionary = profile.get("rehit_policy_overrides", {})
	if overrides.has(hurtbox_kind):
		return String(overrides[hurtbox_kind])
	return String(profile.get("rehit_policy", REHIT_ONCE_PER_INSTANCE))


static func get_rehit_interval_for_hurtbox(profile: Dictionary, hurtbox_kind: String) -> float:
	var overrides: Dictionary = profile.get("rehit_interval_overrides", {})
	if overrides.has(hurtbox_kind):
		return float(overrides[hurtbox_kind])
	return float(profile.get("rehit_interval", 0.0))


static func get_channel_mode_for_hurtbox(profile: Dictionary, hurtbox_kind: String) -> String:
	var overrides: Dictionary = profile.get("channel_mode_overrides", {})
	if overrides.has(hurtbox_kind):
		return String(overrides[hurtbox_kind])
	return "dps" if String(profile.get("hit_mode", HIT_MODE_INSTANT)) == HIT_MODE_CONTINUOUS else "burst"


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
