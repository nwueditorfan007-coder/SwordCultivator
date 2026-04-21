extends RefCounted
class_name TargetDescriptors


const TargetProfiles = preload("res://scripts/combat/target_profiles.gd")

const ROLE_PRIMARY := "primary"
const ROLE_BODY := "body"
const ROLE_CORE := "core"
const ROLE_SEGMENT := "segment"


static func build_descriptor(
	target_id: String,
	target_profile_id: String,
	descriptor_role := ROLE_PRIMARY,
	metadata := {},
	overrides := {}
) -> Dictionary:
	var target_profile: Dictionary = TargetProfiles.get_profile(target_profile_id)
	var hurtbox_kind: String = str(target_profile.get("hurtbox_kind", TargetProfiles.HURTBOX_BODY))
	var descriptor := {
		"id": _build_hurtbox_id(target_id, hurtbox_kind),
		"hurtbox_id": _build_hurtbox_id(target_id, hurtbox_kind),
		"target_id": target_id,
		"target_profile_id": target_profile_id,
		"descriptor_role": descriptor_role,
		"hurtbox_kind": hurtbox_kind,
		"requires_state": str(target_profile.get("requires_state", "")),
		"priority": _get_default_priority(hurtbox_kind),
		"metadata": _duplicate_value(metadata),
	}
	for key in overrides.keys():
		descriptor[key] = _duplicate_value(overrides[key])
	return descriptor


static func build_enemy_body(enemy: Dictionary) -> Dictionary:
	var enemy_type: String = str(enemy.get("type", ""))
	var target_id: String = str(enemy.get("id", ""))
	var target_profile_id: String = str(enemy.get("target_profile_id", TargetProfiles.get_enemy_profile_id(enemy_type)))
	return build_descriptor(
		target_id,
		target_profile_id,
		ROLE_PRIMARY,
		{
			"target_kind": "enemy",
			"enemy_type": enemy_type,
		}
	)


static func build_boss_body(boss_data: Dictionary) -> Dictionary:
	var target_profile_id: String = str(boss_data.get("target_profile_id", TargetProfiles.PROFILE_BOSS_BODY))
	return build_descriptor(
		"boss",
		target_profile_id,
		ROLE_PRIMARY,
		{
			"target_kind": "boss",
			"descriptor_kind": "body",
		},
		{
			"priority": 10,
		}
	)


static func build_boss_core(_boss_data: Dictionary) -> Dictionary:
	return build_descriptor(
		"boss",
		TargetProfiles.PROFILE_BOSS_CORE,
		ROLE_PRIMARY,
		{
			"target_kind": "boss",
			"descriptor_kind": "core",
		},
		{
			"priority": 20,
		}
	)


static func build_silk_segment(silk: Dictionary) -> Dictionary:
	var target_id: String = str(silk.get("id", ""))
	var target_profile_id: String = str(silk.get("target_profile_id", TargetProfiles.PROFILE_SILK_SEGMENT))
	return build_descriptor(
		target_id,
		target_profile_id,
		ROLE_PRIMARY,
		{
			"target_kind": "silk",
		},
		{
			"priority": 15,
		}
	)


static func _build_hurtbox_id(target_id: String, hurtbox_kind: String) -> String:
	return "%s:%s" % [target_id, hurtbox_kind]


static func _get_default_priority(hurtbox_kind: String) -> int:
	match hurtbox_kind:
		TargetProfiles.HURTBOX_CORE:
			return 20
		TargetProfiles.HURTBOX_SILK:
			return 15
		TargetProfiles.HURTBOX_BODY:
			return 10
		_:
			return 5


static func _duplicate_value(value: Variant) -> Variant:
	if typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY:
		return value.duplicate(true)
	return value
