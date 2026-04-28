extends RefCounted
class_name SwordResonanceController

const SwordArrayConfig = preload("res://scripts/system/sword_array_config.gd")

const MODE_NONE := ""
const RESONANCE_DURATION := 5.0
const RESONANCE_FADE_WARNING_TIME := 1.25
const RESONANCE_GAIN_FLASH_DURATION := 0.42
const STANCE_GAIN_TIME := 1.2
const KILL_WINDOW := 2.6
const KILL_SCORE_TARGET := 3.0
const COMBO_NONE := ""
const COMBO_RING_TO_PIERCE := "ring_to_pierce"
const COMBO_FAN_TIME_STOP := "fan_time_stop"
const COMBO_PIERCE_TIME_STOP := "pierce_time_stop"


static func initialize_player_state(player: Dictionary) -> void:
	player["resonance_mode"] = MODE_NONE
	player["resonance_timer"] = 0.0
	player["resonance_duration"] = RESONANCE_DURATION
	player["resonance_flash_timer"] = 0.0
	player["resonance_gain_reason"] = ""
	player["resonance_stance_mode"] = MODE_NONE
	player["resonance_stance_timer"] = 0.0
	player["resonance_kill_mode"] = MODE_NONE
	player["resonance_kill_window_timer"] = 0.0
	player["resonance_kill_score"] = 0.0


static func update(main: Node, delta: float) -> void:
	var player: Dictionary = main.player
	if not player.has("resonance_mode"):
		initialize_player_state(player)
	_tick_current_resonance(player, delta)
	_update_stance_gain(main, player, delta)
	_update_kill_window(player, delta)


static func record_array_kill(main: Node, mode: String, weight := 1.0) -> void:
	var normalized_mode: String = _normalize_mode(mode)
	if normalized_mode == MODE_NONE:
		return
	var player: Dictionary = main.player
	if not player.has("resonance_mode"):
		initialize_player_state(player)
	var current_kill_mode: String = String(player.get("resonance_kill_mode", MODE_NONE))
	var window_timer: float = float(player.get("resonance_kill_window_timer", 0.0))
	if current_kill_mode != normalized_mode or window_timer <= 0.0:
		player["resonance_kill_mode"] = normalized_mode
		player["resonance_kill_score"] = 0.0
	player["resonance_kill_window_timer"] = KILL_WINDOW
	player["resonance_kill_score"] = float(player.get("resonance_kill_score", 0.0)) + maxf(weight, 0.0)
	if float(player.get("resonance_kill_score", 0.0)) >= KILL_SCORE_TARGET:
		_grant_resonance(player, normalized_mode, "kill_chain", true)
		player["resonance_kill_mode"] = MODE_NONE
		player["resonance_kill_window_timer"] = 0.0
		player["resonance_kill_score"] = 0.0


static func peek_array_combo(player: Dictionary, target_mode: String) -> String:
	var resonance_mode: String = get_mode(player)
	if resonance_mode == SwordArrayConfig.MODE_RING and _normalize_mode(target_mode) == SwordArrayConfig.MODE_PIERCE:
		return COMBO_RING_TO_PIERCE
	return COMBO_NONE


static func consume_array_combo(player: Dictionary, target_mode: String) -> String:
	var combo_id: String = peek_array_combo(player, target_mode)
	if combo_id != COMBO_NONE:
		_clear_resonance(player)
	return combo_id


static func peek_time_stop_combo(player: Dictionary) -> String:
	match get_mode(player):
		SwordArrayConfig.MODE_FAN:
			return COMBO_FAN_TIME_STOP
		SwordArrayConfig.MODE_PIERCE:
			return COMBO_PIERCE_TIME_STOP
		_:
			return COMBO_NONE


static func consume_time_stop_combo(player: Dictionary) -> String:
	var combo_id: String = peek_time_stop_combo(player)
	if combo_id != COMBO_NONE:
		_clear_resonance(player)
	return combo_id


static func get_mode(player: Dictionary) -> String:
	return _normalize_mode(String(player.get("resonance_mode", MODE_NONE)))


static func get_color(mode: String) -> Color:
	match _normalize_mode(mode):
		SwordArrayConfig.MODE_RING:
			return Color("8ff8e7")
		SwordArrayConfig.MODE_FAN:
			return Color("a7d8ff")
		SwordArrayConfig.MODE_PIERCE:
			return Color("ffe08a")
		_:
			return Color.TRANSPARENT


static func get_display_name(mode: String) -> String:
	match _normalize_mode(mode):
		SwordArrayConfig.MODE_RING:
			return "环式余韵"
		SwordArrayConfig.MODE_FAN:
			return "扇式余韵"
		SwordArrayConfig.MODE_PIERCE:
			return "刺式余韵"
		_:
			return ""


static func get_strength(player: Dictionary) -> float:
	var mode: String = get_mode(player)
	if mode == MODE_NONE:
		return 0.0
	var timer: float = maxf(float(player.get("resonance_timer", 0.0)), 0.0)
	if timer <= 0.0:
		return 0.0
	var duration: float = maxf(float(player.get("resonance_duration", RESONANCE_DURATION)), 0.001)
	var fade_in: float = clampf(timer / 0.18, 0.0, 1.0)
	var fade_out: float = clampf(timer / maxf(RESONANCE_FADE_WARNING_TIME, 0.001), 0.0, 1.0)
	return minf(fade_in, fade_out)


static func get_flash_strength(player: Dictionary) -> float:
	var flash_timer: float = maxf(float(player.get("resonance_flash_timer", 0.0)), 0.0)
	if flash_timer <= 0.0:
		return 0.0
	return clampf(flash_timer / maxf(RESONANCE_GAIN_FLASH_DURATION, 0.001), 0.0, 1.0)


static func is_expiring(player: Dictionary) -> bool:
	return get_mode(player) != MODE_NONE and float(player.get("resonance_timer", 0.0)) <= RESONANCE_FADE_WARNING_TIME


static func _tick_current_resonance(player: Dictionary, delta: float) -> void:
	player["resonance_flash_timer"] = maxf(float(player.get("resonance_flash_timer", 0.0)) - delta, 0.0)
	var mode: String = get_mode(player)
	if mode == MODE_NONE:
		player["resonance_timer"] = 0.0
		return
	var timer: float = maxf(float(player.get("resonance_timer", 0.0)) - delta, 0.0)
	player["resonance_timer"] = timer
	if timer <= 0.0:
		player["resonance_mode"] = MODE_NONE
		player["resonance_gain_reason"] = ""


static func _update_stance_gain(main: Node, player: Dictionary, delta: float) -> void:
	var active_mode: String = MODE_NONE
	if bool(player.get("array_is_firing", false)):
		active_mode = _normalize_mode(String(player.get("array_mode", SwordArrayConfig.MODE_RING)))
	if active_mode == MODE_NONE:
		player["resonance_stance_mode"] = MODE_NONE
		player["resonance_stance_timer"] = 0.0
		return
	var stance_mode: String = String(player.get("resonance_stance_mode", MODE_NONE))
	if stance_mode != active_mode:
		player["resonance_stance_mode"] = active_mode
		player["resonance_stance_timer"] = 0.0
	player["resonance_stance_timer"] = float(player.get("resonance_stance_timer", 0.0)) + delta
	if float(player.get("resonance_stance_timer", 0.0)) >= STANCE_GAIN_TIME:
		var already_holding_same: bool = get_mode(player) == active_mode and float(player.get("resonance_timer", 0.0)) > 0.0
		_grant_resonance(player, active_mode, "stance", not already_holding_same)
		player["resonance_stance_timer"] = 0.0


static func _update_kill_window(player: Dictionary, delta: float) -> void:
	var timer: float = maxf(float(player.get("resonance_kill_window_timer", 0.0)) - delta, 0.0)
	player["resonance_kill_window_timer"] = timer
	if timer <= 0.0:
		player["resonance_kill_mode"] = MODE_NONE
		player["resonance_kill_score"] = 0.0


static func _grant_resonance(player: Dictionary, mode: String, reason: String, flash := true) -> void:
	var normalized_mode: String = _normalize_mode(mode)
	if normalized_mode == MODE_NONE:
		return
	player["resonance_mode"] = normalized_mode
	player["resonance_timer"] = RESONANCE_DURATION
	player["resonance_duration"] = RESONANCE_DURATION
	player["resonance_gain_reason"] = reason
	if flash:
		player["resonance_flash_timer"] = RESONANCE_GAIN_FLASH_DURATION


static func _clear_resonance(player: Dictionary) -> void:
	player["resonance_mode"] = MODE_NONE
	player["resonance_timer"] = 0.0
	player["resonance_flash_timer"] = 0.0
	player["resonance_gain_reason"] = ""


static func _normalize_mode(mode: String) -> String:
	match mode:
		SwordArrayConfig.MODE_RING, SwordArrayConfig.MODE_FAN, SwordArrayConfig.MODE_PIERCE:
			return mode
		_:
			return MODE_NONE
