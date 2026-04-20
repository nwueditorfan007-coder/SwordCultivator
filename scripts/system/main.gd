extends Node2D

const GameBossController = preload("res://scripts/system/game_boss_controller.gd")
const GameRenderer = preload("res://scripts/system/game_renderer.gd")
const GameStateFactory = preload("res://scripts/system/game_state_factory.gd")
const SwordArrayConfig = preload("res://scripts/system/sword_array_config.gd")
const SwordArrayController = preload("res://scripts/system/sword_array_controller.gd")

enum CombatMode {
	MELEE,
	RANGED,
}

enum SwordState {
	ORBITING,
	POINT_STRIKE,
	SLICING,
	RECALLING,
}

const ARENA_SIZE := Vector2(800.0, 600.0)
const ARENA_ORIGIN := Vector2(240.0, 72.0)
const ARENA_RECT := Rect2(ARENA_ORIGIN, ARENA_SIZE)

const PLAYER_RADIUS := 15.0
const PLAYER_MAX_HEALTH := 100.0
const PLAYER_MAX_ENERGY := 100.0
const PLAYER_SPEED := 300.0

const SWORD_RADIUS := 25.0
const SWORD_ROTATION_SPEED := 5.2
const SWORD_MELEE_RANGE := 100.0
const SWORD_MELEE_COOLDOWN := 10.0 / 60.0
const SWORD_MELEE_ARC := PI * 1.2
const SWORD_MELEE_DAMAGE := 100.0
const SWORD_RANGED_DAMAGE := 100.0
const SWORD_TAP_THRESHOLD := 0.15
const SWORD_POINT_STRIKE_SPEED := 80.0 * 60.0
const SWORD_RECALL_SPEED := 60.0 * 60.0
const SWORD_ORBIT_DISTANCE := 25.0

const BULLET_RADIUS := 5.0
const BULLET_LARGE_RADIUS := 12.0
const BULLET_SPEED := 2.5 * 60.0
const BULLET_LARGE_SPEED := 1.5 * 60.0
const BULLET_DAMAGE := 10.0
const BULLET_LARGE_DAMAGE := 25.0

const BULLET_TIME_START_MULTIPLIER := 0.1
const BULLET_TIME_RECOVERY_DURATION := 2.0
const PLAYER_BULLET_TIME_SPEED_MULTIPLIER := 0.85
const ENEMY_HIT_COOLDOWN := 0.05

const ENERGY_RECOVERY_MELEE_NATURAL := 4.0
const ENERGY_GAIN_MELEE_HIT := 2.0
const ENERGY_GAIN_MELEE_DEFLECT := 8.0
const ARRAY_SWORD_COUNT := 12
const ARRAY_SWORD_RADIUS := 6.0
const ARRAY_SWORD_RETURN_SPEED := 32.0 * 60.0
const ARRAY_SWORD_RETURN_CATCH_RADIUS := 18.0
const ARRAY_SWORD_ENERGY_COST_PER_SWORD := 0.65
const ARRAY_SWORD_MAX_TRAVEL_DISTANCE := 540.0
const ARRAY_SWORD_MIN_SORTIE_DISTANCE := 220.0
const ARRAY_SWORD_HIT_FOLLOW_THROUGH_DISTANCE := 130.0
const ARRAY_MORPH_CONTROL_SMOOTH_SPEED_IDLE := 12.0
const ARRAY_MORPH_CONTROL_SMOOTH_SPEED_HELD := 9.0
const ARRAY_MORPH_CONTROL_SMOOTH_SPEED_FIRING := 6.5
const ARRAY_SWORD_FIRE_SPEED_SCALE := 1.35
const ARRAY_SWORD_RETURN_SPEED_SCALE := 1.0
const ARRAY_SWORD_RELEASE_RATE_SCALE := 0.78
const ACTION_FAILURE_REPEAT_DELAY := 0.35
const ACTION_FAILURE_FLASH_DURATION := 0.28
const DEFLECT_BULLET_SPEED_MULTIPLIER := 8.0
const RING_GUARD_BULLET_CLEAR_RADIUS := 34.0
const RING_GUARD_PLAYER_CLEAR_RADIUS := 58.0

const DAMAGE_SOURCE_NONE := ""
const DAMAGE_SOURCE_MELEE := "melee"
const DAMAGE_SOURCE_FLYING_SWORD := "flying_sword"
const DAMAGE_SOURCE_ARRAY_SWORD := "array_sword"
const DAMAGE_SOURCE_ULTIMATE := "ultimate"
const DAMAGE_SOURCE_SYSTEM := "system"

const WAVE_BASE_ENEMIES := 3
const BOSS_WAVE_INTERVAL := 5
const SPAWN_MARGIN := 50.0
const SPAWN_INTERVAL := 0.35

const SHOOTER := "shooter"
const TANK := "tank"
const CASTER := "caster"
const HEAVY := "heavy"
const PUPPET := "puppet"

const BOSS_IDLE := "idle"
const BOSS_THOUSAND_SILKS := "thousand_silks"
const BOSS_PUPPET_AMBUSH := "puppet_ambush"
const BOSS_SILK_CAGE := "silk_cage"
const BOSS_NEEDLE_RETURN := "needle_return"

const SHOOTER_RADIUS := 25.0
const SHOOTER_HEALTH := 20.0
const SHOOTER_SPEED := 1.5 * 60.0
const SHOOTER_COOLDOWN := 120.0 / 60.0

const TANK_RADIUS := 40.0
const TANK_HEALTH := 100.0
const TANK_SPEED := 0.8 * 60.0

const CASTER_RADIUS := 30.0
const CASTER_HEALTH := 40.0
const CASTER_SPEED := 1.2 * 60.0
const CASTER_COOLDOWN := 180.0 / 60.0

const HEAVY_RADIUS := 35.0
const HEAVY_HEALTH := 60.0
const HEAVY_SPEED := 1.0 * 60.0
const HEAVY_COOLDOWN := 150.0 / 60.0

const PUPPET_RADIUS := 25.0
const PUPPET_HEALTH := 200.0
const PUPPET_SPEED := 2.0 * 60.0
const PUPPET_MELEE_RANGE := 80.0
const PUPPET_MELEE_COOLDOWN := 120.0 / 60.0
const PUPPET_MELEE_DAMAGE := 20.0
const PUPPET_MELEE_PREP_TIME := 40.0 / 60.0

const BOSS_RADIUS := 60.0
const BOSS_MAX_HEALTH := 5000.0
const BOSS_SPEED := 60.0
const SILK_MAX_HEALTH := 10.0

const COLORS := {
	"background": Color("0a0a0a"),
	"grid": Color("1b1b1b"),
	"player": Color("4ade80"),
	"melee_sword": Color("facc15"),
	"ranged_sword": Color("38bdf8"),
	"shooter": Color("f87171"),
	"tank": Color("ef4444"),
	"caster": Color("dc2626"),
	"heavy": Color("991b1b"),
	"puppet": Color("a78bfa"),
	"bullet": Color.WHITE,
	"frozen": Color("00ffff"),
	"array_sword": Color("7dd3fc"),
	"array_sword_return": Color("facc15"),
	"energy": Color("facc15"),
	"health": Color("ef4444"),
	"boss_body": Color("7c3aed"),
	"boss_vulnerable": Color("facc15"),
	"silk": Color("ffffff"),
	"silk_main": Color("ef4444"),
}

var player: Dictionary = {}
var sword: Dictionary = {}
var enemies: Array = []
var bullets: Array = []
var array_swords: Array = []
var particles: Array = []
var boss: Dictionary = {}

var wave: int = 1
var enemies_to_spawn: int = WAVE_BASE_ENEMIES
var spawn_timer: float = 0.0
var score: int = 0
var is_game_over: bool = false
var screen_shake: float = 0.0
var elapsed_time: float = 0.0
var id_counter: int = 0
var status_message: String = ""
var status_message_timer: float = 0.0
var status_message_color: Color = Color.WHITE
var action_failure_cooldowns: Dictionary = {}
var energy_feedback_timer: float = 0.0
var energy_feedback_color: Color = Color.WHITE
var array_feedback_timer: float = 0.0
var array_feedback_color: Color = Color.WHITE

var mouse_world: Vector2 = ARENA_SIZE * 0.5
var left_mouse_held: bool = false
var right_mouse_held: bool = false
var debug_battle_mode: bool = false
var debug_flags: Dictionary = {}
var debug_calibration_mode: bool = false
var debug_dragging_player: bool = false

const DEBUG_ENEMY_LAYOUT := [
	Vector2(120.0, 110.0),
	Vector2(260.0, 110.0),
	Vector2(400.0, 110.0),
	Vector2(540.0, 110.0),
	Vector2(680.0, 110.0),
	Vector2(120.0, 280.0),
	Vector2(260.0, 280.0),
	Vector2(400.0, 280.0),
	Vector2(540.0, 280.0),
	Vector2(680.0, 280.0),
	Vector2(120.0, 450.0),
	Vector2(260.0, 450.0),
	Vector2(400.0, 450.0),
	Vector2(540.0, 450.0),
	Vector2(680.0, 450.0),
]

@onready var health_label: Label = $CanvasLayer/HealthLabel
@onready var energy_label: Label = $CanvasLayer/EnergyLabel
@onready var wave_label: Label = $CanvasLayer/WaveLabel
@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var mode_label: Label = $CanvasLayer/ModeLabel
@onready var status_label: Label = $CanvasLayer/StatusLabel
@onready var hint_label: Label = $CanvasLayer/HintLabel
@onready var game_over_label: Label = $CanvasLayer/GameOverLabel


func _ready() -> void:
	randomize()
	SwordArrayConfig.load_morph_distances_from_project()
	_reset_game()


func _process(delta: float) -> void:
	elapsed_time += delta

	if is_game_over:
		queue_redraw()
		return

	var is_flying_sword: bool = sword["state"] != SwordState.ORBITING
	if is_flying_sword:
		sword["time_slow_timer"] += delta
	else:
		sword["time_slow_timer"] = 0.0

	var bullet_time_ratio: float = 1.0
	var player_time_ratio: float = 1.0
	if is_flying_sword:
		var recovery_duration: float = _get_bullet_time_recovery_duration()
		var recovery_progress: float = min(sword["time_slow_timer"] / recovery_duration, 1.0)
		bullet_time_ratio = lerpf(BULLET_TIME_START_MULTIPLIER, 1.0, recovery_progress)
		player_time_ratio = lerpf(PLAYER_BULLET_TIME_SPEED_MULTIPLIER, 1.0, recovery_progress)

	var bullet_time_delta: float = delta * bullet_time_ratio
	var player_delta: float = delta * player_time_ratio

	if right_mouse_held:
		var previous_press_timer: float = sword["press_timer"]
		sword["press_timer"] += delta
		if previous_press_timer <= SWORD_TAP_THRESHOLD and sword["press_timer"] > SWORD_TAP_THRESHOLD and sword["state"] == SwordState.ORBITING:
			_start_slicing()

	_update_array_morph_control(delta)
	_refresh_sword_array_live_state()

	if debug_calibration_mode:
		_ensure_debug_calibration_state()

	if not _can_use_array_attack() and bool(player.get("array_is_firing", false)):
		_reset_sword_array_hold_state()

	player["array_hold_ratio"] = 0.0
	if left_mouse_held:
		player["array_hold_timer"] = min(
			float(player.get("array_hold_timer", 0.0)) + delta,
			SwordArrayConfig.HOLD_THRESHOLD
		)
		player["array_hold_ratio"] = clampf(float(player.get("array_hold_timer", 0.0)) / SwordArrayConfig.HOLD_THRESHOLD, 0.0, 1.0)
	else:
		player["array_hold_timer"] = 0.0
	if _can_use_array_attack():
		if not player["array_is_firing"]:
			if _get_ready_array_sword_count() > 0:
				_begin_sword_array_firing()
		else:
			player["array_hold_ratio"] = 1.0
			_update_sword_array_continuous_firing(delta)

	_update_status_feedback(delta)
	_update_action_feedback(delta)
	_update_player(delta, player_delta)
	_update_sword(delta)
	_update_boss(delta, bullet_time_delta)
	_update_enemies(bullet_time_delta)
	_update_bullets(delta, bullet_time_delta)
	_update_array_swords(delta)
	_update_particles(bullet_time_delta)
	_update_wave(delta)
	_try_cast_ultimate()
	_apply_debug_runtime_overrides()

	if player["health"] <= 0.0:
		_set_game_over()

	screen_shake = lerpf(screen_shake, 0.0, min(delta * 10.0, 1.0))
	_update_ui()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if _handle_debug_key_input(event):
			return
	if event is InputEventMouseMotion:
		mouse_world = _screen_to_world(event.position)
		if debug_calibration_mode and debug_dragging_player:
			_set_debug_player_position(mouse_world)
	elif event is InputEventMouseButton:
		mouse_world = _screen_to_world(event.position)
		if debug_calibration_mode and event.button_index == MOUSE_BUTTON_MIDDLE:
			debug_dragging_player = event.pressed
			if event.pressed:
				_set_debug_player_position(mouse_world)
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if is_game_over:
					_reset_game()
					return
				left_mouse_held = true
				if sword["state"] == SwordState.ORBITING and player["attack_cooldown"] <= 0.0:
					_perform_melee_attack()
			else:
				left_mouse_held = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if is_game_over:
				return
			if event.pressed:
				right_mouse_held = true
				sword["press_timer"] = 0.0
				sword["target_pos"] = mouse_world
			else:
				right_mouse_held = false
				if sword["state"] == SwordState.ORBITING:
					if sword["press_timer"] < SWORD_TAP_THRESHOLD:
						_start_point_strike()
				elif sword["state"] == SwordState.SLICING:
					sword["state"] = SwordState.RECALLING


func _draw() -> void:
	GameRenderer.draw_game(self)


func _draw_hud_bars() -> void:
	GameRenderer.draw_hud_bars(self)


func _reset_game() -> void:
	GameStateFactory.reset_runtime(self)
	action_failure_cooldowns.clear()
	energy_feedback_timer = 0.0
	energy_feedback_color = Color.WHITE
	array_feedback_timer = 0.0
	array_feedback_color = Color.WHITE


func _update_player(delta: float, player_delta: float) -> void:
	if debug_calibration_mode and debug_dragging_player:
		player["vel"] = Vector2.ZERO
		player["attack_cooldown"] = max(player["attack_cooldown"] - delta, 0.0)
		player["attack_flash_timer"] = max(player["attack_flash_timer"] - delta, 0.0)
		return
	var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not move_input.is_zero_approx():
		player["vel"] = move_input.normalized() * PLAYER_SPEED
	else:
		player["vel"] = player["vel"].lerp(Vector2.ZERO, min(delta * 8.0, 1.0))

	player["pos"] += player["vel"] * player_delta
	player["pos"] = player["pos"].clamp(Vector2(PLAYER_RADIUS, PLAYER_RADIUS), ARENA_SIZE - Vector2(PLAYER_RADIUS, PLAYER_RADIUS))

	player["attack_cooldown"] = max(player["attack_cooldown"] - delta, 0.0)
	player["attack_flash_timer"] = max(player["attack_flash_timer"] - delta, 0.0)


func _get_bullet_time_recovery_duration() -> float:
	return BULLET_TIME_RECOVERY_DURATION


func _can_use_array_attack() -> bool:
	if not left_mouse_held:
		return false
	return float(player.get("array_hold_timer", 0.0)) >= SwordArrayConfig.HOLD_THRESHOLD


func _get_active_array_sword_count() -> int:
	return array_swords.size()


func _get_current_array_sword_capacity() -> int:
	return ARRAY_SWORD_COUNT


func _get_array_sortie_profile(mode: String) -> Dictionary:
	return SwordArrayConfig.get_profile(mode)


func _should_array_consume_energy() -> bool:
	return true


func _get_array_batch_mode() -> String:
	return String(_get_sword_array_fire_state().get("dominant_mode", SwordArrayConfig.MODE_RING))


func _get_array_sword_energy_cost(fire_count: int) -> float:
	if fire_count <= 0 or not _should_array_consume_energy():
		return 0.0
	return float(fire_count) * ARRAY_SWORD_ENERGY_COST_PER_SWORD


func _get_array_mode_batch_target(mode: String) -> int:
	var capacity: int = _get_current_array_sword_capacity()
	match mode:
		SwordArrayConfig.MODE_RING:
			return capacity
		SwordArrayConfig.MODE_FAN:
			return maxi(int(ceil(float(capacity) * 0.5)), 1)
		_:
			return 1


func _can_fire_array_batch(mode: String, ready_count: int) -> bool:
	return ready_count >= _get_array_mode_batch_target(mode)


func _get_array_mode_speed_scale(mode: String) -> float:
	match mode:
		SwordArrayConfig.MODE_RING:
			return 0.92
		SwordArrayConfig.MODE_FAN:
			return 1.0
		_:
			return 1.12


func _get_current_array_sword_speed(mode := "") -> float:
	var resolved_mode: String = mode if mode != "" else _get_array_batch_mode()
	return SwordArrayConfig.FIRED_SPEED * ARRAY_SWORD_FIRE_SPEED_SCALE * _get_array_mode_speed_scale(resolved_mode)


func _get_array_mode_return_speed_scale(mode: String) -> float:
	match mode:
		SwordArrayConfig.MODE_RING:
			return 0.9
		SwordArrayConfig.MODE_FAN:
			return 1.04
		_:
			return 1.32


func _get_current_array_sword_return_speed(mode := "") -> float:
	var resolved_mode: String = mode if mode != "" else _get_array_batch_mode()
	return ARRAY_SWORD_RETURN_SPEED * ARRAY_SWORD_RETURN_SPEED_SCALE * _get_array_mode_return_speed_scale(resolved_mode)


func _get_current_array_release_rate(base_rate: float) -> float:
	return maxf(base_rate, 0.0) * ARRAY_SWORD_RELEASE_RATE_SCALE


func _get_ready_array_sword_count() -> int:
	var ready_count: int = 0
	for array_sword in array_swords:
		if array_sword["state"] == "ready":
			ready_count += 1
	return ready_count


func _get_ready_array_swords() -> Array:
	var ready_swords: Array = []
	for array_sword in array_swords:
		if array_sword["state"] == "ready":
			ready_swords.append(array_sword)
	ready_swords.sort_custom(_sort_array_swords_by_slot)
	return ready_swords


func _sort_array_swords_by_slot(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("slot_index", 0)) < int(b.get("slot_index", 0))


func _build_array_sword(slot_index: int) -> Dictionary:
	return {
		"id": _next_id("array_sword"),
		"pos": player["pos"],
		"vel": Vector2.ZERO,
		"radius": ARRAY_SWORD_RADIUS,
		"slot_index": slot_index,
		"state": "ready",
		"travel_mode": SwordArrayConfig.MODE_RING,
		"trail_timer": 0.0,
		"guidance_active": false,
		"guidance_elapsed": 0.0,
		"guidance_distance": 0.0,
		"guidance_fire_index": -1,
		"guidance_volley_count": -1,
		"guidance_burst_step": 0,
		"guidance_total_count": -1,
		"has_hit_target": false,
		"remaining_penetration": 1,
		"hit_target_cooldowns": {},
		"batch_id": "",
		"batch_return_ready": false,
		"return_unlock_distance": ARRAY_SWORD_MIN_SORTIE_DISTANCE,
		"pending_remove": false,
	}


func _reset_array_sword_sortie_state(array_sword: Dictionary) -> void:
	var travel_mode: String = String(array_sword.get("travel_mode", SwordArrayConfig.MODE_RING))
	array_sword["trail_timer"] = 0.0
	array_sword["guidance_active"] = false
	array_sword["guidance_elapsed"] = 0.0
	array_sword["guidance_distance"] = 0.0
	array_sword["guidance_fire_index"] = -1
	array_sword["guidance_volley_count"] = -1
	array_sword["guidance_burst_step"] = 0
	array_sword["guidance_total_count"] = -1
	array_sword["has_hit_target"] = false
	array_sword["remaining_penetration"] = _get_array_sword_penetration_targets(travel_mode)
	array_sword["hit_target_cooldowns"] = {}
	array_sword["batch_id"] = ""
	array_sword["batch_return_ready"] = false
	array_sword["return_unlock_distance"] = _get_array_sword_min_sortie_distance(travel_mode)


func _rebuild_array_sword_pool() -> void:
	array_swords.clear()
	var sword_index: int = 0
	var target_count: int = _get_current_array_sword_capacity()
	while sword_index < target_count:
		array_swords.append(_build_array_sword(sword_index))
		sword_index += 1
	_layout_ready_array_swords(1.0)


func _sync_array_sword_pool_capacity() -> void:
	var target_count: int = _get_current_array_sword_capacity()
	var current_count: int = array_swords.size()
	if current_count < target_count:
		var add_index: int = current_count
		while add_index < target_count:
			array_swords.append(_build_array_sword(add_index))
			add_index += 1
	elif current_count > target_count:
		var sword_index: int = array_swords.size() - 1
		while sword_index >= 0 and array_swords.size() > target_count:
			var array_sword: Dictionary = array_swords[sword_index]
			if array_sword["state"] == "ready":
				array_swords.remove_at(sword_index)
			sword_index -= 1
		for array_sword in array_swords:
			array_sword["pending_remove"] = array_swords.size() > target_count
	array_swords.sort_custom(_sort_array_swords_by_slot)


func _get_array_sword_slot_position(slot_index: int, formation_ratio := -1.0) -> Vector2:
	var slot_count: int = _get_current_array_sword_capacity()
	if formation_ratio < 0.0:
		formation_ratio = _get_sword_array_formation_ratio()
	return SwordArrayController.get_slot_position(
		self,
		_get_sword_array_morph_state(),
		slot_index,
		slot_count,
		formation_ratio
	)


func _layout_ready_array_swords(delta: float) -> void:
	var formation_ratio: float = _get_sword_array_formation_ratio()
	for array_sword in array_swords:
		if String(array_sword.get("state", "")) != "ready":
			continue
		var target_pos: Vector2 = _get_array_sword_slot_position(int(array_sword.get("slot_index", 0)), formation_ratio)
		array_sword["pos"] = array_sword["pos"].lerp(target_pos, min(delta * 18.0, 1.0))
		array_sword["vel"] = Vector2.ZERO


func _update_status_feedback(delta: float) -> void:
	status_message_timer = maxf(status_message_timer - delta, 0.0)
	if is_zero_approx(status_message_timer):
		status_message = ""


func _update_action_feedback(delta: float) -> void:
	energy_feedback_timer = maxf(energy_feedback_timer - delta, 0.0)
	array_feedback_timer = maxf(array_feedback_timer - delta, 0.0)


func _show_status_message(message: String, color: Color, duration: float) -> void:
	status_message = message
	status_message_color = color
	status_message_timer = duration


func _get_energy_failure_color() -> Color:
	return COLORS["energy"].lerp(COLORS["health"], 0.4)


func _get_array_failure_color() -> Color:
	return COLORS["array_sword"].lerp(COLORS["health"], 0.38)


func _trigger_action_feedback(channel: String, color: Color, duration := ACTION_FAILURE_FLASH_DURATION) -> void:
	match channel:
		"energy":
			energy_feedback_timer = maxf(energy_feedback_timer, duration)
			energy_feedback_color = color
		"array":
			array_feedback_timer = maxf(array_feedback_timer, duration)
			array_feedback_color = color


func _show_action_failure(message: String, reason_key: String, color: Color, channel := "", duration := 0.8, repeat_delay := ACTION_FAILURE_REPEAT_DELAY) -> void:
	if channel != "":
		_trigger_action_feedback(channel, color)
	var next_allowed_time: float = float(action_failure_cooldowns.get(reason_key, 0.0))
	if elapsed_time < next_allowed_time:
		return
	action_failure_cooldowns[reason_key] = elapsed_time + repeat_delay
	_show_status_message(message, color, duration)


func _get_sword_array_formation_ratio() -> float:
	if _can_use_array_attack() and player["array_is_firing"]:
		return 1.0
	return 0.0


func _should_draw_sword_array_preview() -> bool:
	return false


func _update_array_morph_control(delta: float) -> void:
	var raw_distance: float = player["pos"].distance_to(mouse_world)
	var control_distance: float = float(player.get("array_control_distance", raw_distance))
	var smoothing_speed: float = ARRAY_MORPH_CONTROL_SMOOTH_SPEED_IDLE
	if left_mouse_held:
		smoothing_speed = ARRAY_MORPH_CONTROL_SMOOTH_SPEED_HELD
	if bool(player.get("array_is_firing", false)):
		smoothing_speed = ARRAY_MORPH_CONTROL_SMOOTH_SPEED_FIRING
	control_distance = lerpf(control_distance, raw_distance, min(delta * smoothing_speed, 1.0))
	player["array_raw_aim_distance"] = raw_distance
	player["array_control_distance"] = control_distance


func _refresh_sword_array_live_state() -> void:
	var raw_distance: float = float(player.get("array_raw_aim_distance", player["pos"].distance_to(mouse_world)))
	var control_distance: float = float(player.get("array_control_distance", raw_distance))
	var visual_state: Dictionary = SwordArrayConfig.get_morph_state_for_distance(raw_distance)
	var fire_state: Dictionary = SwordArrayConfig.get_control_morph_state_for_distance(control_distance)
	player["array_morph_state"] = visual_state
	player["array_fire_morph_state"] = fire_state
	player["array_mode"] = fire_state["dominant_mode"]


func _begin_sword_array_firing() -> void:
	if not _can_use_array_attack():
		return
	var mode: String = _get_array_batch_mode()
	if not _can_fire_array_batch(mode, _get_ready_array_sword_count()):
		_show_action_failure("飞剑未回收", "array_ready", _get_array_failure_color(), "array")
		return
	_refresh_sword_array_live_state()
	player["array_is_firing"] = true
	player["array_release_progress"] = 1.0
	player["array_packet_remainder"] = 0.0
	if not _fire_array_swords():
		player["array_is_firing"] = false
		player["array_release_progress"] = 0.0
		player["array_packet_remainder"] = 0.0


func _update_sword_array_continuous_firing(delta: float) -> void:
	if not _can_use_array_attack():
		_reset_sword_array_hold_state()
		return
	var morph_state: Dictionary = _get_sword_array_fire_state()
	var mode: String = String(morph_state.get("dominant_mode", SwordArrayConfig.MODE_RING))
	var ready_count: int = _get_ready_array_sword_count()
	var release_profile: Dictionary = SwordArrayController.get_fire_release_profile(
		self,
		morph_state,
		maxi(ready_count, 1)
	)
	var release_rate: float = _get_current_array_release_rate(float(release_profile.get("release_rate", 0.0)))
	player["array_release_progress"] = min(float(player.get("array_release_progress", 0.0)) + delta * release_rate, 1.25)
	var release_count: int = 0
	while player["array_release_progress"] >= 1.0 and release_count < 12:
		ready_count = _get_ready_array_sword_count()
		if not _can_fire_array_batch(mode, ready_count):
			_show_action_failure("飞剑未回收", "array_ready", _get_array_failure_color(), "array")
			player["array_release_progress"] = min(float(player.get("array_release_progress", 0.0)), 1.0)
			return
		if not _fire_array_swords():
			player["array_is_firing"] = false
			player["array_release_progress"] = 0.0
			player["array_packet_remainder"] = 0.0
			return
		player["array_release_progress"] -= 1.0
		release_count += 1
		morph_state = _get_sword_array_fire_state()
		release_profile = SwordArrayController.get_fire_release_profile(
			self,
			morph_state,
			_get_ready_array_sword_count()
		)


func _get_sword_array_morph_state() -> Dictionary:
	return SwordArrayConfig.complete_morph_state(player.get("array_morph_state", {}))


func _get_sword_array_fire_state() -> Dictionary:
	return SwordArrayConfig.complete_morph_state(player.get("array_fire_morph_state", player.get("array_morph_state", {})))


func _get_array_sword_max_travel_distance(mode: String) -> float:
	return float(_get_array_sortie_profile(mode).get("sortie_max_distance", ARRAY_SWORD_MAX_TRAVEL_DISTANCE))


func _get_array_sword_guidance_max_distance(mode: String) -> float:
	return float(_get_array_sortie_profile(mode).get("sortie_guidance_max_distance", SwordArrayConfig.FIRED_GUIDANCE_MAX_DISTANCE))


func _get_array_sword_min_sortie_distance(mode: String) -> float:
	return float(_get_array_sortie_profile(mode).get("sortie_min_distance", ARRAY_SWORD_MIN_SORTIE_DISTANCE))


func _get_array_sword_hit_follow_through_distance(mode: String) -> float:
	return float(_get_array_sortie_profile(mode).get("sortie_hit_follow_through_distance", ARRAY_SWORD_HIT_FOLLOW_THROUGH_DISTANCE))


func _get_array_sword_hit_radius_bonus(mode: String) -> float:
	return float(_get_array_sortie_profile(mode).get("sortie_hit_radius_bonus", 0.0))


func _get_array_sword_penetration_targets(mode: String) -> int:
	return maxi(int(_get_array_sortie_profile(mode).get("sortie_penetration_targets", 1)), 1)


func _get_array_sword_rehit_cooldown(mode: String) -> float:
	return maxf(float(_get_array_sortie_profile(mode).get("sortie_rehit_cooldown", 0.0)), 0.0)


func _decay_array_sword_target_cooldowns(array_sword: Dictionary, delta: float) -> void:
	var hit_target_cooldowns: Dictionary = array_sword.get("hit_target_cooldowns", {})
	if typeof(hit_target_cooldowns) != TYPE_DICTIONARY:
		hit_target_cooldowns = {}
	var expired_targets: Array = []
	for target_id in hit_target_cooldowns.keys():
		var remaining_cooldown: float = maxf(float(hit_target_cooldowns[target_id]) - delta, 0.0)
		if remaining_cooldown <= 0.0:
			expired_targets.append(target_id)
		else:
			hit_target_cooldowns[target_id] = remaining_cooldown
	for target_id in expired_targets:
		hit_target_cooldowns.erase(target_id)
	array_sword["hit_target_cooldowns"] = hit_target_cooldowns


func _can_array_sword_hit_target(array_sword: Dictionary, target_id: String) -> bool:
	if target_id == "":
		return true
	var hit_target_cooldowns: Dictionary = array_sword.get("hit_target_cooldowns", {})
	if typeof(hit_target_cooldowns) != TYPE_DICTIONARY:
		return true
	return not hit_target_cooldowns.has(target_id)


func _register_array_sword_target_hit(array_sword: Dictionary, target_id: String, travel_mode: String) -> bool:
	var hit_target_cooldowns: Dictionary = array_sword.get("hit_target_cooldowns", {})
	if typeof(hit_target_cooldowns) != TYPE_DICTIONARY:
		hit_target_cooldowns = {}
	var rehit_cooldown: float = _get_array_sword_rehit_cooldown(travel_mode)
	if target_id != "" and rehit_cooldown > 0.0:
		hit_target_cooldowns[target_id] = rehit_cooldown
	array_sword["hit_target_cooldowns"] = hit_target_cooldowns
	var remaining_penetration: int = maxi(int(array_sword.get("remaining_penetration", _get_array_sword_penetration_targets(travel_mode))), 0)
	if remaining_penetration > 0:
		remaining_penetration -= 1
	array_sword["remaining_penetration"] = remaining_penetration
	return remaining_penetration <= 0


func _uses_fan_batch_return(array_sword: Dictionary) -> bool:
	return (
		String(array_sword.get("travel_mode", "")) == SwordArrayConfig.MODE_FAN
		and String(array_sword.get("batch_id", "")) != ""
	)


func _mark_fan_batch_member_ready(array_sword: Dictionary) -> void:
	array_sword["batch_return_ready"] = true
	array_sword["guidance_active"] = false
	array_sword["vel"] = Vector2.ZERO


func _is_fan_batch_ready_to_return(batch_id: String) -> bool:
	if batch_id == "":
		return false
	var has_batch_member: bool = false
	for array_sword in array_swords:
		if String(array_sword.get("batch_id", "")) != batch_id:
			continue
		if String(array_sword.get("state", "")) != "outbound":
			continue
		has_batch_member = true
		if not bool(array_sword.get("batch_return_ready", false)):
			return false
	return has_batch_member


func _begin_fan_batch_return(batch_id: String) -> void:
	if batch_id == "":
		return
	for array_sword in array_swords:
		if String(array_sword.get("batch_id", "")) != batch_id:
			continue
		if String(array_sword.get("state", "")) != "outbound":
			continue
		array_sword["has_hit_target"] = true
		array_sword["batch_return_ready"] = false
		_begin_array_sword_return(array_sword)


func _reset_sword_array_hold_state() -> void:
	player["array_hold_timer"] = 0.0
	player["array_hold_ratio"] = 0.0
	player["array_is_firing"] = false
	player["array_release_progress"] = 0.0
	player["array_packet_remainder"] = 0.0
	player["array_fire_index"] = 0
	_refresh_sword_array_live_state()


func _update_sword(delta: float) -> void:
	sword["prev_pos"] = sword["pos"]

	if sword["state"] == SwordState.ORBITING:
		_add_player_energy(ENERGY_RECOVERY_MELEE_NATURAL * delta)
		sword["angle"] += SWORD_ROTATION_SPEED * delta
		var target: Vector2 = player["pos"] + Vector2.RIGHT.rotated(sword["angle"]) * SWORD_ORBIT_DISTANCE
		sword["pos"] = sword["pos"].lerp(target, min(delta * 18.0, 1.0))
		return

	if sword["state"] == SwordState.SLICING:
		sword["pos"] = sword["pos"].lerp(mouse_world, min(delta * 18.0, 1.0))
		sword["vel"] = mouse_world - sword["pos"]
	elif sword["state"] == SwordState.POINT_STRIKE:
		var to_target: Vector2 = sword["target_pos"] - sword["pos"]
		var move_distance: float = SWORD_POINT_STRIKE_SPEED * delta
		if to_target.length() > move_distance and to_target.length() > 10.0:
			sword["vel"] = to_target.normalized() * SWORD_POINT_STRIKE_SPEED
			sword["pos"] += sword["vel"] * delta
		else:
			sword["pos"] = sword["target_pos"]
			sword["vel"] = Vector2.ZERO
			sword["state"] = SwordState.RECALLING
			screen_shake = max(screen_shake, 6.0)
			_create_particles(sword["pos"], COLORS["ranged_sword"], 12)
	elif sword["state"] == SwordState.RECALLING:
		var to_player: Vector2 = player["pos"] - sword["pos"]
		var recall_distance: float = SWORD_RECALL_SPEED * delta
		if to_player.length() > recall_distance and to_player.length() > 20.0:
			sword["vel"] = to_player.normalized() * SWORD_RECALL_SPEED
			sword["pos"] += sword["vel"] * delta
		else:
			sword["pos"] = player["pos"]
			sword["vel"] = Vector2.ZERO
			sword["state"] = SwordState.ORBITING
			player["mode"] = CombatMode.MELEE
			sword["press_timer"] = 0.0

	if sword["vel"].length_squared() > 1.0:
		sword["angle"] = sword["vel"].angle()

	_damage_enemies_with_sword(delta)


func _damage_enemies_with_sword(delta: float) -> void:
	for enemy in enemies:
		if enemy["type"] == PUPPET:
			continue
		enemy["hit_cooldown"] = max(enemy["hit_cooldown"] - delta, 0.0)
		if enemy["hit_cooldown"] > 0.0:
			continue
		var hit_radius: float = sword["radius"] + enemy["radius"]
		if not _segment_hits_circle(sword["prev_pos"], sword["pos"], enemy["pos"], hit_radius):
			continue
		if sword["prev_pos"].distance_to(enemy["pos"]) <= hit_radius:
			continue
		var damage: float = SWORD_RANGED_DAMAGE * (1.5 if sword["state"] == SwordState.POINT_STRIKE else 0.5)
		_damage_enemy(enemy, damage, DAMAGE_SOURCE_FLYING_SWORD)
		enemy["hit_cooldown"] = ENEMY_HIT_COOLDOWN
		_create_particles(sword["pos"], COLORS["ranged_sword"], 4)
		if sword["state"] == SwordState.POINT_STRIKE:
			screen_shake = max(screen_shake, 4.0)

	if _has_boss():
		_update_silk_damage(delta)
		if boss["is_vulnerable"] or boss["phase"] == 1:
			var boss_hit_radius: float = boss["radius"] + sword["radius"]
			if _segment_hits_circle(sword["prev_pos"], sword["pos"], boss["pos"], boss_hit_radius) and sword["prev_pos"].distance_to(boss["pos"]) > boss_hit_radius:
				var boss_damage: float = SWORD_RANGED_DAMAGE * (1.5 if sword["state"] == SwordState.POINT_STRIKE else 0.5) * delta * 15.0
				_damage_boss(boss_damage)
				_create_particles(sword["pos"], COLORS["boss_body"], 2)


func _damage_enemy(enemy: Dictionary, damage: float, damage_source: String) -> void:
	if damage <= 0.0:
		return
	if _has_debug_flag("one_hit_kill"):
		enemy["health"] = 0.0
	else:
		enemy["health"] = max(enemy["health"] - damage, 0.0)
	enemy["last_damage_source"] = damage_source


func _handle_enemy_death(enemy: Dictionary, index: int) -> void:
	_create_particles(enemy["pos"], COLORS[enemy["type"]], 14)
	if enemy["type"] != PUPPET:
		score += enemy["score"]
		_add_player_energy(ENERGY_GAIN_MELEE_HIT * 2.0)
	enemies.remove_at(index)


func _update_enemies(delta: float) -> void:
	var index: int = enemies.size() - 1
	while index >= 0:
		var enemy: Dictionary = enemies[index]
		if enemy.get("is_debug_static", false):
			enemy["hit_cooldown"] = max(enemy["hit_cooldown"] - delta, 0.0)
			if enemy["health"] <= 0.0 and debug_calibration_mode:
				enemy["health"] = enemy["max_health"]
			index -= 1
			continue
		if enemy["health"] <= 0.0:
			_handle_enemy_death(enemy, index)
			index -= 1
			continue
		var to_player: Vector2 = player["pos"] - enemy["pos"]
		var distance: float = max(to_player.length(), 0.001)
		match enemy["type"]:
			SHOOTER:
				if distance > 200.0:
					enemy["pos"] += to_player.normalized() * SHOOTER_SPEED * delta
				elif distance < 150.0:
					enemy["pos"] -= to_player.normalized() * SHOOTER_SPEED * delta
				enemy["shoot_cooldown"] -= delta
				if enemy["shoot_cooldown"] <= 0.0:
					enemy["shoot_cooldown"] = SHOOTER_COOLDOWN
					_spawn_bullet(enemy["pos"], to_player.normalized() * BULLET_SPEED, "small", enemy["id"], COLORS["bullet"])
			TANK:
				enemy["pos"] += to_player.normalized() * TANK_SPEED * delta
				if distance < enemy["radius"] + PLAYER_RADIUS:
					if _apply_player_damage(30.0 * delta, TANK):
						screen_shake = max(screen_shake, 2.0)
			CASTER:
				enemy["move_timer"] -= delta
				if enemy["move_timer"] <= 0.0:
					enemy["move_timer"] = randf_range(1.0, 2.0)
					enemy["vel"] = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * CASTER_SPEED
				enemy["pos"] += enemy["vel"] * delta
				enemy["pos"] = enemy["pos"].clamp(Vector2(enemy["radius"], enemy["radius"]), ARENA_SIZE - Vector2(enemy["radius"], enemy["radius"]))
				enemy["shoot_cooldown"] -= delta
				if enemy["shoot_cooldown"] <= 0.0:
					enemy["shoot_cooldown"] = CASTER_COOLDOWN
					var spoke: int = 0
					while spoke < 8:
						var angle: float = (TAU / 8.0) * float(spoke)
						_spawn_bullet(enemy["pos"], Vector2.RIGHT.rotated(angle) * BULLET_SPEED * 0.7, "small", enemy["id"], COLORS["caster"])
						spoke += 1
			HEAVY:
				enemy["pos"] += to_player.normalized() * HEAVY_SPEED * delta
				enemy["shoot_cooldown"] -= delta
				if enemy["shoot_cooldown"] <= 0.0:
					enemy["shoot_cooldown"] = HEAVY_COOLDOWN
					_spawn_bullet(enemy["pos"], to_player.normalized() * BULLET_LARGE_SPEED, "large", enemy["id"], COLORS["heavy"])
			PUPPET:
				if not _has_boss() or not _is_silk_active(enemy["id"]):
					enemy["last_damage_source"] = DAMAGE_SOURCE_SYSTEM
					enemy["health"] = 0.0
				elif enemy["melee_timer"] <= 0.0:
					if distance > PUPPET_MELEE_RANGE * 0.8:
						enemy["pos"] += to_player.normalized() * PUPPET_SPEED * delta
					if distance < PUPPET_MELEE_RANGE:
						enemy["melee_timer"] = PUPPET_MELEE_COOLDOWN
				else:
					var previous_timer: float = enemy["melee_timer"]
					enemy["melee_timer"] -= delta
					var attack_progress: float = PUPPET_MELEE_COOLDOWN - enemy["melee_timer"]
					var previous_progress: float = PUPPET_MELEE_COOLDOWN - previous_timer
					if previous_progress < PUPPET_MELEE_PREP_TIME and attack_progress >= PUPPET_MELEE_PREP_TIME:
						if distance < PUPPET_MELEE_RANGE + 10.0:
							if _apply_player_damage(PUPPET_MELEE_DAMAGE, PUPPET):
								screen_shake = max(screen_shake, 5.0)
								_create_particles(player["pos"], COLORS["puppet"], 10)

		if enemy["health"] <= 0.0:
			_handle_enemy_death(enemy, index)
		index -= 1


func _update_bullets(delta: float, bullet_time_delta: float) -> void:
	var index: int = bullets.size() - 1
	while index >= 0:
		var bullet: Dictionary = bullets[index]
		match bullet["state"]:
			"deflected":
				bullet["pos"] += bullet["vel"] * delta
				if _deflected_bullet_hits_enemy(bullet):
					_remove_bullet(index)
					index -= 1
					continue
				if not _is_inside_extended_bounds(bullet["pos"]):
					_remove_bullet(index)
					index -= 1
					continue
			_:
				bullet["pos"] += bullet["vel"] * bullet_time_delta
				if not _is_inside_extended_bounds(bullet["pos"]):
					_remove_bullet(index)
					index -= 1
					continue
				if _ring_guard_clears_bullet(bullet):
					_create_particles(bullet["pos"], COLORS["array_sword"], 4)
					screen_shake = max(screen_shake, 1.6)
					_remove_bullet(index)
					index -= 1
					continue
				if _player_hit_by_bullet(bullet):
					_remove_bullet(index)
					index -= 1
					continue
		index -= 1


func _update_array_swords(delta: float) -> void:
	var sword_index: int = array_swords.size() - 1
	while sword_index >= 0:
		var array_sword: Dictionary = array_swords[sword_index]
		match String(array_sword.get("state", "")):
			"outbound":
				var travel_mode: String = String(array_sword.get("travel_mode", SwordArrayConfig.MODE_RING))
				var uses_fan_batch_return: bool = _uses_fan_batch_return(array_sword)
				var batch_return_ready: bool = bool(array_sword.get("batch_return_ready", false))
				if not batch_return_ready:
					_update_guided_array_sword(array_sword, delta)
					array_sword["pos"] += array_sword["vel"] * delta
					array_sword["guidance_distance"] = float(array_sword.get("guidance_distance", 0.0)) + array_sword["vel"].length() * delta
					_emit_array_sword_trail(array_sword, delta, false)
				_decay_array_sword_target_cooldowns(array_sword, delta)
				if not batch_return_ready:
					_clear_bullets_near_ring_guard_sword(array_sword, travel_mode)
				if not batch_return_ready and not bool(array_sword.get("has_hit_target", false)):
					var hit_result: Dictionary = _array_sword_hits_enemy(array_sword)
					if bool(hit_result.get("hit", false)):
						array_sword["guidance_active"] = false
						array_sword["return_unlock_distance"] = maxf(
							float(array_sword.get("return_unlock_distance", _get_array_sword_min_sortie_distance(travel_mode))),
							float(array_sword.get("guidance_distance", 0.0)) + _get_array_sword_hit_follow_through_distance(travel_mode)
						)
						if bool(hit_result.get("should_return", false)):
							array_sword["has_hit_target"] = true
				var can_return: bool = float(array_sword.get("guidance_distance", 0.0)) >= float(array_sword.get("return_unlock_distance", _get_array_sword_min_sortie_distance(travel_mode)))
				var reached_max_distance: bool = float(array_sword.get("guidance_distance", 0.0)) >= _get_array_sword_max_travel_distance(travel_mode)
				var left_bounds: bool = can_return and not _is_inside_extended_bounds(array_sword["pos"])
				if uses_fan_batch_return:
					if not batch_return_ready and (
						(bool(array_sword.get("has_hit_target", false)) and can_return)
						or reached_max_distance
						or left_bounds
					):
						_mark_fan_batch_member_ready(array_sword)
						batch_return_ready = true
					if _is_fan_batch_ready_to_return(String(array_sword.get("batch_id", ""))):
						_begin_fan_batch_return(String(array_sword.get("batch_id", "")))
				else:
					if bool(array_sword.get("has_hit_target", false)) and can_return:
						_begin_array_sword_return(array_sword)
					elif reached_max_distance:
						_begin_array_sword_return(array_sword)
					elif left_bounds:
						_begin_array_sword_return(array_sword)
			"returning":
				var return_target: Vector2 = player["pos"] if bool(array_sword.get("pending_remove", false)) else _get_array_sword_slot_position(int(array_sword.get("slot_index", 0)), 1.0)
				var to_player: Vector2 = return_target - array_sword["pos"]
				if to_player.length() <= ARRAY_SWORD_RETURN_CATCH_RADIUS:
					if bool(array_sword.get("pending_remove", false)):
						array_swords.remove_at(sword_index)
						sword_index -= 1
						continue
					array_sword["state"] = "ready"
					array_sword["pos"] = return_target
					array_sword["vel"] = Vector2.ZERO
					_reset_array_sword_sortie_state(array_sword)
					_create_particles(return_target, COLORS["array_sword_return"], 4)
				else:
					array_sword["vel"] = to_player.normalized() * _get_current_array_sword_return_speed(String(array_sword.get("travel_mode", SwordArrayConfig.MODE_RING)))
					array_sword["pos"] += array_sword["vel"] * delta
					_emit_array_sword_trail(array_sword, delta, true)
		sword_index -= 1
	_layout_ready_array_swords(delta)
	_clear_bullets_near_ready_ring_guard_swords()


func _array_sword_hits_enemy(array_sword: Dictionary) -> Dictionary:
	var travel_mode: String = String(array_sword.get("travel_mode", SwordArrayConfig.MODE_RING))
	var hit_radius_bonus: float = _get_array_sword_hit_radius_bonus(travel_mode)
	var hit_result := {
		"hit": false,
		"should_return": false,
	}
	for enemy in enemies:
		if enemy["type"] == PUPPET:
			continue
		var target_id: String = str(enemy.get("id", ""))
		if not _can_array_sword_hit_target(array_sword, target_id):
			continue
		if enemy["pos"].distance_to(array_sword["pos"]) > enemy["radius"] + array_sword["radius"] + hit_radius_bonus:
			continue
		_damage_enemy(enemy, SwordArrayConfig.FIRED_DAMAGE, DAMAGE_SOURCE_ARRAY_SWORD)
		hit_result["hit"] = true
		hit_result["should_return"] = _register_array_sword_target_hit(array_sword, target_id, travel_mode)
		_create_particles(array_sword["pos"], COLORS["array_sword"], 10)
		return hit_result
	if _has_boss():
		if _can_array_sword_hit_target(array_sword, "boss") and boss["pos"].distance_to(array_sword["pos"]) <= boss["radius"] + array_sword["radius"] + hit_radius_bonus and (boss["is_vulnerable"] or boss["phase"] == 1):
			_damage_boss(SwordArrayConfig.FIRED_DAMAGE * 2.0)
			hit_result["hit"] = true
			hit_result["should_return"] = _register_array_sword_target_hit(array_sword, "boss", travel_mode)
			_create_particles(array_sword["pos"], COLORS["array_sword"], 15)
			return hit_result
	return hit_result


func _clear_bullets_near_ring_guard_sword(array_sword: Dictionary, travel_mode: String) -> void:
	if not _is_ring_guard_active() or travel_mode != SwordArrayConfig.MODE_RING:
		return
	var bullet_index: int = bullets.size() - 1
	var cleared_count: int = 0
	while bullet_index >= 0:
		var bullet: Dictionary = bullets[bullet_index]
		if String(bullet.get("state", "")) != "normal":
			bullet_index -= 1
			continue
		if bullet["pos"].distance_to(array_sword["pos"]) > bullet["radius"] + array_sword["radius"] + RING_GUARD_BULLET_CLEAR_RADIUS:
			bullet_index -= 1
			continue
		_create_particles(bullet["pos"], COLORS["array_sword"], 4)
		_remove_bullet(bullet_index)
		cleared_count += 1
		bullet_index -= 1
	if cleared_count > 0:
		screen_shake = max(screen_shake, 1.8)


func _clear_bullets_near_ready_ring_guard_swords() -> void:
	if not _is_ring_guard_active():
		return
	for array_sword in array_swords:
		if String(array_sword.get("state", "")) != "ready":
			continue
		_clear_bullets_near_ring_guard_sword(array_sword, SwordArrayConfig.MODE_RING)


func _ring_guard_clears_bullet(bullet: Dictionary) -> bool:
	if not _is_ring_guard_active():
		return false
	if String(bullet.get("state", "")) != "normal":
		return false
	if player["pos"].distance_to(bullet["pos"]) <= RING_GUARD_PLAYER_CLEAR_RADIUS + float(bullet.get("radius", BULLET_RADIUS)):
		return true
	for array_sword in array_swords:
		if String(array_sword.get("travel_mode", SwordArrayConfig.MODE_RING)) != SwordArrayConfig.MODE_RING:
			continue
		if String(array_sword.get("state", "")) == "":
			continue
		if bullet["pos"].distance_to(array_sword["pos"]) <= float(bullet.get("radius", BULLET_RADIUS)) + float(array_sword.get("radius", ARRAY_SWORD_RADIUS)) + RING_GUARD_BULLET_CLEAR_RADIUS:
			return true
	return false


func _is_ring_guard_active() -> bool:
	return bool(player.get("array_is_firing", false)) and _get_array_batch_mode() == SwordArrayConfig.MODE_RING


func _begin_array_sword_return(array_sword: Dictionary) -> void:
	array_sword["state"] = "returning"
	array_sword["guidance_active"] = false
	array_sword["trail_timer"] = 0.0


func _update_guided_array_sword(array_sword: Dictionary, delta: float) -> void:
	if not array_sword.get("guidance_active", false):
		return
	var travel_mode: String = String(array_sword.get("travel_mode", SwordArrayConfig.MODE_RING))
	array_sword["guidance_elapsed"] = float(array_sword.get("guidance_elapsed", 0.0)) + delta
	var should_keep_guiding: bool = bool(player.get("array_is_firing", false))
	should_keep_guiding = should_keep_guiding and float(array_sword.get("guidance_elapsed", 0.0)) <= SwordArrayConfig.FIRED_GUIDANCE_DURATION
	should_keep_guiding = should_keep_guiding and float(array_sword.get("guidance_distance", 0.0)) <= _get_array_sword_guidance_max_distance(travel_mode)
	if not should_keep_guiding:
		array_sword["guidance_active"] = false
		return
	var target_point: Vector2 = SwordArrayController.get_fire_target(
		self,
		_get_sword_array_fire_state(),
		int(array_sword.get("guidance_fire_index", 0)),
		array_sword["pos"],
		int(array_sword.get("guidance_volley_count", -1)),
		int(array_sword.get("guidance_burst_step", 0)),
		int(array_sword.get("guidance_total_count", -1))
	)
	var desired_direction: Vector2 = target_point - array_sword["pos"]
	if desired_direction.is_zero_approx():
		desired_direction = array_sword["vel"]
	if desired_direction.is_zero_approx():
		desired_direction = mouse_world - player["pos"]
	if desired_direction.is_zero_approx():
		desired_direction = Vector2.RIGHT
	var current_forward: Vector2 = array_sword["vel"].normalized()
	if not current_forward.is_zero_approx():
		var forward_component: float = desired_direction.dot(current_forward)
		var min_forward_component: float = desired_direction.length() * 0.18
		if forward_component < min_forward_component:
			var lateral_component: Vector2 = desired_direction - current_forward * forward_component
			desired_direction = lateral_component + current_forward * min_forward_component
			if desired_direction.is_zero_approx():
				desired_direction = current_forward
	var desired_velocity: Vector2 = desired_direction.normalized() * _get_current_array_sword_speed(String(array_sword.get("travel_mode", SwordArrayConfig.MODE_RING)))
	array_sword["vel"] = array_sword["vel"].lerp(desired_velocity, min(delta * SwordArrayConfig.FIRED_GUIDANCE_TURN_RATE, 1.0))


func _emit_array_sword_trail(array_sword: Dictionary, delta: float, is_returning: bool) -> void:
	var trail_timer: float = float(array_sword.get("trail_timer", 0.0)) - delta
	if trail_timer > 0.0:
		array_sword["trail_timer"] = trail_timer
		return
	array_sword["trail_timer"] = 0.032 if bool(player.get("array_is_firing", false)) else 0.055
	var trail_color: Color = COLORS["array_sword_return"] if is_returning else COLORS["array_sword"]
	_create_particles(array_sword["pos"], trail_color, 1)


func _deflected_bullet_hits_enemy(bullet: Dictionary) -> bool:
	for enemy in enemies:
		if enemy["type"] == PUPPET:
			continue
		if enemy["pos"].distance_to(bullet["pos"]) > enemy["radius"] + bullet["radius"]:
			continue
		_damage_enemy(enemy, bullet["damage"] * 2.0, DAMAGE_SOURCE_MELEE)
		_create_particles(bullet["pos"], COLORS["melee_sword"], 8)
		return true
	if _has_boss():
		if boss["pos"].distance_to(bullet["pos"]) <= boss["radius"] + bullet["radius"] and (boss["is_vulnerable"] or boss["phase"] == 1):
			_damage_boss(bullet["damage"] * 2.5)
			_create_particles(bullet["pos"], COLORS["melee_sword"], 10)
			return true
	return false


func _player_hit_by_bullet(bullet: Dictionary) -> bool:
	if String(bullet.get("state", "")) == "deflected":
		return false
	if player["pos"].distance_to(bullet["pos"]) > PLAYER_RADIUS + bullet["radius"]:
		return false
	if _apply_player_damage(bullet["damage"], str(bullet.get("owner_id", DAMAGE_SOURCE_NONE))):
		screen_shake = max(screen_shake, 5.0)
		_create_particles(bullet["pos"], bullet["color"], 6)
	return true


func _update_particles(delta: float) -> void:
	var index: int = particles.size() - 1
	while index >= 0:
		var particle: Dictionary = particles[index]
		particle["pos"] += particle["vel"] * delta
		particle["life"] -= delta
		if particle["life"] <= 0.0:
			particles.remove_at(index)
		index -= 1


func _update_wave(delta: float) -> void:
	if debug_calibration_mode:
		return
	if _has_boss() and boss["health"] <= 0.0:
		_create_particles(boss["pos"], COLORS["boss_body"], 40)
		boss.clear()
		score += 5000
		enemies_to_spawn = WAVE_BASE_ENEMIES + wave * 2
		spawn_timer = 0.5
		return

	if enemies_to_spawn <= 0 and enemies.is_empty():
		wave += 1
		if wave % BOSS_WAVE_INTERVAL == 0:
			_spawn_boss()
			spawn_timer = 0.6
			return
		enemies_to_spawn = WAVE_BASE_ENEMIES + wave * 2
		spawn_timer = 0.6

	if enemies_to_spawn <= 0 or _has_boss():
		return
	if _has_debug_flag("no_spawn"):
		return

	spawn_timer -= delta
	if spawn_timer > 0.0:
		return

	spawn_timer = SPAWN_INTERVAL
	_spawn_enemy(_roll_enemy_type())
	enemies_to_spawn -= 1


func _try_cast_ultimate() -> void:
	if not Input.is_action_just_pressed("ultimate"):
		return
	if not _has_debug_flag("infinite_energy") and player["energy"] < PLAYER_MAX_ENERGY:
		return

	if _has_debug_flag("infinite_energy"):
		player["energy"] = PLAYER_MAX_ENERGY
	else:
		player["energy"] = 0.0
	screen_shake = max(screen_shake, 14.0)
	var index: int = bullets.size() - 1
	while index >= 0:
		_remove_bullet(index)
		index -= 1
	for enemy in enemies:
		if enemy["type"] == PUPPET:
			continue
		_damage_enemy(enemy, 50.0, DAMAGE_SOURCE_ULTIMATE)
		_create_particles(enemy["pos"], COLORS["energy"], 12)
	if _has_boss():
		_damage_boss(250.0)
		_create_particles(boss["pos"], COLORS["energy"], 18)
	_create_particles(player["pos"], COLORS["energy"], 24)


func _perform_melee_attack() -> void:
	player["attack_cooldown"] = SWORD_MELEE_COOLDOWN
	player["attack_flash_timer"] = 0.08
	var attack_direction: Vector2 = mouse_world - player["pos"]
	if attack_direction.is_zero_approx():
		attack_direction = Vector2.RIGHT
	var attack_angle: float = attack_direction.angle()

	for bullet in bullets:
		if bullet["state"] != "normal":
			continue
		var offset: Vector2 = bullet["pos"] - player["pos"]
		if offset.length() > SWORD_MELEE_RANGE + 20.0:
			continue
		if absf(wrapf(offset.angle() - attack_angle, -PI, PI)) > SWORD_MELEE_ARC * 0.5:
			continue
		_deflect_enemy_bullet(bullet, attack_direction)
		_add_player_energy(ENERGY_GAIN_MELEE_DEFLECT * (1.5 if bullet["type"] == "large" else 1.0))
		screen_shake = max(screen_shake, 3.0)

	for enemy in enemies:
		var enemy_offset: Vector2 = enemy["pos"] - player["pos"]
		if enemy_offset.length() > SWORD_MELEE_RANGE + enemy["radius"]:
			continue
		if absf(wrapf(enemy_offset.angle() - attack_angle, -PI, PI)) > SWORD_MELEE_ARC * 0.5:
			continue
		if enemy["type"] == PUPPET:
			continue
		_damage_enemy(enemy, SWORD_MELEE_DAMAGE, DAMAGE_SOURCE_MELEE)
		_add_player_energy(ENERGY_GAIN_MELEE_HIT)
		_create_particles(enemy["pos"], COLORS[enemy["type"]], 5)
		screen_shake = max(screen_shake, 4.0)

	if _has_boss() and (boss["is_vulnerable"] or boss["phase"] == 1):
		var boss_offset: Vector2 = boss["pos"] - player["pos"]
		if boss_offset.length() <= SWORD_MELEE_RANGE + boss["radius"]:
			if absf(wrapf(boss_offset.angle() - attack_angle, -PI, PI)) <= SWORD_MELEE_ARC * 0.5:
				_damage_boss(SWORD_MELEE_DAMAGE)
				_add_player_energy(ENERGY_GAIN_MELEE_HIT)
				_create_particles(boss["pos"], COLORS["boss_body"], 8)
				screen_shake = max(screen_shake, 5.0)


func _deflect_enemy_bullet(bullet: Dictionary, attack_direction: Vector2) -> void:
	var deflect_direction: Vector2 = (bullet["pos"] - player["pos"]).normalized()
	if deflect_direction.is_zero_approx():
		deflect_direction = attack_direction.normalized()
	if deflect_direction.is_zero_approx():
		deflect_direction = Vector2.RIGHT
	var blended_direction: Vector2 = deflect_direction.lerp(attack_direction.normalized(), 0.5)
	if blended_direction.is_zero_approx():
		blended_direction = deflect_direction
	bullet["state"] = "deflected"
	bullet["owner_id"] = "player"
	bullet["color"] = COLORS["melee_sword"]
	bullet["vel"] = blended_direction.normalized() * maxf(bullet["vel"].length(), BULLET_SPEED) * DEFLECT_BULLET_SPEED_MULTIPLIER
	_create_particles(bullet["pos"], COLORS["melee_sword"], 4)


func _start_point_strike() -> void:
	sword["state"] = SwordState.POINT_STRIKE
	sword["target_pos"] = mouse_world
	player["mode"] = CombatMode.RANGED


func _start_slicing() -> void:
	sword["state"] = SwordState.SLICING
	player["mode"] = CombatMode.RANGED


func _try_consume_energy(amount: float) -> bool:
	return _consume_player_energy(amount)


func _fire_array_swords() -> bool:
	if not _can_use_array_attack():
		return false
	var ready_count: int = _get_ready_array_sword_count()
	if ready_count <= 0:
		_show_action_failure("飞剑未回收", "array_ready", _get_array_failure_color(), "array")
		return false
	var morph_state: Dictionary = _get_sword_array_fire_state()
	var mode: String = String(morph_state.get("dominant_mode", SwordArrayConfig.MODE_RING))
	if not _can_fire_array_batch(mode, ready_count):
		_show_action_failure("飞剑未回收", "array_ready", _get_array_failure_color(), "array")
		return false
	var fire_count: int = mini(_get_array_mode_batch_target(mode), ready_count)
	var energy_cost: float = _get_array_sword_energy_cost(fire_count)
	if energy_cost > 0.0 and not _try_consume_energy(energy_cost):
		_show_action_failure("剑意不足", "array_energy", _get_energy_failure_color(), "energy")
		return false
	player["array_packet_remainder"] = 0.0
	var source_snapshot: Array = _build_array_sword_source_snapshot()
	fire_count = mini(fire_count, source_snapshot.size())
	if fire_count <= 0:
		_show_action_failure("飞剑未回收", "array_ready", _get_array_failure_color(), "array")
		return false
	var batch_id: String = _next_id("array_batch") if mode == SwordArrayConfig.MODE_FAN else ""
	var burst_step: int = 0
	var fired_count: int = 0
	while fired_count < fire_count:
		var snapshot_positions: Array = []
		for source in source_snapshot:
			snapshot_positions.append(source["pos"])
		var source_snapshot_index: int = SwordArrayController.get_fire_source_snapshot_index(
			self,
			morph_state,
			snapshot_positions,
			fired_count,
			fire_count,
			burst_step,
			ready_count
		)
		if source_snapshot_index < 0 or source_snapshot_index >= source_snapshot.size():
			source_snapshot_index = 0
		var sword_id: String = str(source_snapshot[source_snapshot_index]["id"])
		_fire_single_array_sword(sword_id, fired_count, fire_count, burst_step, ready_count, batch_id)
		source_snapshot.remove_at(source_snapshot_index)
		fired_count += 1
	_emit_sword_array_fire_effect(morph_state, fire_count)
	return true


func _build_array_sword_source_snapshot() -> Array:
	var source_snapshot: Array = []
	for array_sword in _get_ready_array_swords():
		source_snapshot.append({
			"id": array_sword["id"],
			"pos": array_sword["pos"],
		})
	return source_snapshot


func _get_array_sword_by_id(sword_id: String) -> Dictionary:
	for array_sword in array_swords:
		if String(array_sword.get("id", "")) == sword_id:
			return array_sword
	return {}


func _fire_single_array_sword(sword_id: String, volley_fire_index: int, volley_fire_count: int, burst_step: int, total_count_before_fire: int, batch_id := "") -> void:
	if sword_id == "":
		return
	var array_sword: Dictionary = _get_array_sword_by_id(sword_id)
	if array_sword.is_empty() or String(array_sword.get("state", "")) != "ready":
		return
	var launch_origin: Vector2 = SwordArrayController.get_fire_launch_origin(
		self,
		_get_sword_array_fire_state(),
		volley_fire_index,
		array_sword["pos"],
		volley_fire_count,
		burst_step,
		total_count_before_fire
	)
	var target_point: Vector2 = _get_sword_array_target(volley_fire_index, launch_origin, volley_fire_count, burst_step, total_count_before_fire)
	var direction: Vector2 = target_point - launch_origin
	if direction.is_zero_approx():
		direction = mouse_world - player["pos"]
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	array_sword["pos"] = launch_origin
	array_sword["state"] = "outbound"
	array_sword["travel_mode"] = _get_array_batch_mode()
	_reset_array_sword_sortie_state(array_sword)
	array_sword["batch_id"] = String(batch_id)
	array_sword["vel"] = direction.normalized() * _get_current_array_sword_speed(String(array_sword.get("travel_mode", SwordArrayConfig.MODE_RING)))
	array_sword["guidance_active"] = true
	array_sword["guidance_fire_index"] = volley_fire_index
	array_sword["guidance_volley_count"] = volley_fire_count
	array_sword["guidance_burst_step"] = burst_step
	array_sword["guidance_total_count"] = total_count_before_fire
	player["array_fire_index"] += 1
	_create_particles(array_sword["pos"], COLORS["array_sword"], 5)
	screen_shake = max(screen_shake, 2.0)


func _emit_sword_array_fire_effect(state_source, fire_count: int) -> void:
	var effect: Dictionary = SwordArrayController.get_fire_effect(self, state_source, fire_count)
	_create_particles(effect["position"], effect["color"], effect["particles"])
	screen_shake = max(screen_shake, effect["shake"])


func _spawn_enemy(enemy_type: String) -> Dictionary:
	var spawn_pos: Vector2 = _roll_spawn_position()
	var enemy: Dictionary = {
		"id": _next_id(enemy_type),
		"type": enemy_type,
		"pos": spawn_pos,
		"vel": Vector2.ZERO,
		"move_timer": randf_range(0.2, 1.4),
		"shoot_cooldown": randf_range(0.2, 1.0),
		"hit_cooldown": 0.0,
		"radius": SHOOTER_RADIUS,
		"health": SHOOTER_HEALTH,
		"max_health": SHOOTER_HEALTH,
		"last_damage_source": DAMAGE_SOURCE_NONE,
		"score": 20,
	}
	match enemy_type:
		PUPPET:
			enemy["radius"] = PUPPET_RADIUS
			enemy["health"] = PUPPET_HEALTH
			enemy["max_health"] = PUPPET_HEALTH
			enemy["score"] = 0
			enemy["shoot_cooldown"] = 0.0
			enemy["melee_timer"] = 0.0
		TANK:
			enemy["radius"] = TANK_RADIUS
			enemy["health"] = TANK_HEALTH
			enemy["max_health"] = TANK_HEALTH
			enemy["score"] = 50
		CASTER:
			enemy["radius"] = CASTER_RADIUS
			enemy["health"] = CASTER_HEALTH
			enemy["max_health"] = CASTER_HEALTH
			enemy["shoot_cooldown"] = randf_range(0.4, CASTER_COOLDOWN)
		HEAVY:
			enemy["radius"] = HEAVY_RADIUS
			enemy["health"] = HEAVY_HEALTH
			enemy["max_health"] = HEAVY_HEALTH
			enemy["score"] = 40
			enemy["shoot_cooldown"] = randf_range(0.4, HEAVY_COOLDOWN)
		_:
			enemy["shoot_cooldown"] = randf_range(0.4, SHOOTER_COOLDOWN)
	enemies.append(enemy)
	return enemy


func _spawn_bullet(position: Vector2, velocity: Vector2, bullet_type: String, owner_id: String, color: Color) -> void:
	bullets.append({
		"id": _next_id("bullet"),
		"pos": position,
		"vel": velocity,
		"radius": BULLET_LARGE_RADIUS if bullet_type == "large" else BULLET_RADIUS,
		"damage": BULLET_LARGE_DAMAGE if bullet_type == "large" else BULLET_DAMAGE,
		"type": bullet_type,
		"owner_id": owner_id,
		"color": color,
		"state": "normal",
		"freeze_timer": 0.0,
		"life_timer": 0.0,
		"guidance_active": false,
		"guidance_elapsed": 0.0,
		"guidance_distance": 0.0,
		"guidance_fire_index": -1,
		"guidance_volley_count": -1,
		"guidance_burst_step": 0,
		"guidance_total_count": -1,
	})


func _create_particles(position: Vector2, color: Color, count: int) -> void:
	var particle_index: int = 0
	while particle_index < count:
		particles.append({
			"pos": position,
			"vel": Vector2(randf_range(-90.0, 90.0), randf_range(-90.0, 90.0)),
			"life": randf_range(0.2, 0.45),
			"max_life": 0.45,
			"color": color,
			"size": randf_range(2.0, 4.5),
		})
		particle_index += 1


func _remove_bullet(index: int) -> void:
	if index < 0 or index >= bullets.size():
		return
	bullets.remove_at(index)


func _set_game_over() -> void:
	is_game_over = true
	left_mouse_held = false
	right_mouse_held = false
	game_over_label.visible = true


func _update_ui() -> void:
	health_label.text = "生命 %.0f / %.0f" % [player["health"], PLAYER_MAX_HEALTH]
	energy_label.text = "剑意 %.0f / %.0f" % [
		player["energy"],
		PLAYER_MAX_ENERGY
	]
	if debug_calibration_mode:
		var raw_distance: float = float(player.get("array_raw_aim_distance", player["pos"].distance_to(mouse_world)))
		var control_distance: float = float(player.get("array_control_distance", raw_distance))
		var morph_state: Dictionary = _get_sword_array_morph_state()
		var fire_state: Dictionary = _get_sword_array_fire_state()
		var default_distances: Dictionary = SwordArrayConfig.get_default_morph_distances()
		var distances: Dictionary = SwordArrayConfig.get_morph_distances()
		var control_distances: Dictionary = SwordArrayConfig.get_control_morph_distances()
		wave_label.text = "校准模式 | 视觉 %.1f | 控制 %.1f | 显示 %s -> %s (%.2f) | 发射 %s -> %s (%.2f)" % [
			raw_distance,
			control_distance,
			morph_state["visual_from_mode"],
			morph_state["visual_to_mode"],
			morph_state["visual_blend"],
			fire_state["visual_from_mode"],
			fire_state["visual_to_mode"],
			fire_state["visual_blend"]
		]
		score_label.text = "默认 | 1 %.0f | 2 %.0f | 3 %.0f | 4 %.0f\n当前 | 1 %.0f | 2 %.0f | 3 %.0f | 4 %.0f\n控制 | 1 %.0f | 2 %.0f | 3 %.0f | 4 %.0f\n差值 | 1 %s | 2 %s | 3 %s | 4 %s" % [
			default_distances["ring_stable_end"],
			default_distances["ring_to_fan_end"],
			default_distances["fan_stable_end"],
			default_distances["fan_to_pierce_end"],
			distances["ring_stable_end"],
			distances["ring_to_fan_end"],
			distances["fan_stable_end"],
			distances["fan_to_pierce_end"],
			control_distances["ring_stable_end"],
			control_distances["ring_to_fan_end"],
			control_distances["fan_stable_end"],
			control_distances["fan_to_pierce_end"],
			_format_distance_delta(distances["ring_stable_end"] - default_distances["ring_stable_end"]),
			_format_distance_delta(distances["ring_to_fan_end"] - default_distances["ring_to_fan_end"]),
			_format_distance_delta(distances["fan_stable_end"] - default_distances["fan_stable_end"]),
			_format_distance_delta(distances["fan_to_pierce_end"] - default_distances["fan_to_pierce_end"])
		]
	else:
		wave_label.text = "波次 %d%s" % [wave, " | 战斗调试" if debug_battle_mode else ""]
		score_label.text = "得分 %d | 飞剑 %d / %d%s" % [
			score,
			_get_ready_array_sword_count(),
			_get_current_array_sword_capacity(),
			_get_debug_status_suffix()
		]
	var sword_mode_text: String = "近战" if sword["state"] == SwordState.ORBITING else "御剑"
	var bullet_time_text: String = " | 子弹时间" if sword["state"] != SwordState.ORBITING else ""
	var debug_mode_text: String = " | DEBUG" if debug_battle_mode else ""
	mode_label.text = "%s%s%s" % [sword_mode_text, bullet_time_text, debug_mode_text]
	energy_label.modulate = Color.WHITE
	if energy_feedback_timer > 0.0:
		var energy_feedback_strength: float = clampf(energy_feedback_timer / ACTION_FAILURE_FLASH_DURATION, 0.0, 1.0)
		energy_label.modulate = energy_label.modulate.lerp(
			energy_feedback_color,
			(0.45 + 0.35 * absf(sin(elapsed_time * 22.0))) * energy_feedback_strength
		)
	score_label.modulate = Color.WHITE
	if array_feedback_timer > 0.0:
		var array_feedback_strength: float = clampf(array_feedback_timer / ACTION_FAILURE_FLASH_DURATION, 0.0, 1.0)
		score_label.modulate = score_label.modulate.lerp(
			array_feedback_color,
			(0.45 + 0.35 * absf(sin(elapsed_time * 22.0))) * array_feedback_strength
		)
	status_label.text = status_message
	status_label.modulate = status_message_color
	if debug_calibration_mode:
		hint_label.text = "校准模式 | WASD 移动 | 中键拖拽玩家 | 1~4 记录距离 | P 保存 | L 读取 | R 重置 | F6 退出"
	elif debug_battle_mode:
		hint_label.text = "战斗调试 | 1 无限生命 | 2 无限剑意 | 3 一击必杀 | 4 停刷怪 | 5 清敌弹 | F7 退出 | F6 校准"
	else:
		hint_label.text = "WASD 移动 | 左键 挥剑/长按维持剑阵 | 右键 御剑点刺或连斩 | Q 必杀 | F7 战斗调试 | F6 校准调试"
	game_over_label.text = "力竭身亡\n最终得分 %d  波次 %d\n左键重新开始" % [score, wave]


func _format_distance_delta(delta: float) -> String:
	if is_zero_approx(delta):
		return "0"
	return "%+.0f" % delta


func _get_sword_array_mode() -> String:
	return SwordArrayController.get_mode(self)


func _get_sword_array_direction(fire_index: int, volley_count := -1, burst_step := 0, total_count := -1) -> Vector2:
	return SwordArrayController.get_fire_direction(self, _get_sword_array_fire_state(), fire_index, volley_count, burst_step, total_count)


func _get_sword_array_target(fire_index: int, bullet_pos: Vector2, volley_count := -1, burst_step := 0, total_count := -1) -> Vector2:
	return SwordArrayController.get_fire_target(self, _get_sword_array_fire_state(), fire_index, bullet_pos, volley_count, burst_step, total_count)


func _update_boss(delta: float, bullet_time_delta: float) -> void:
	GameBossController.update_boss(self, delta, bullet_time_delta)


func _draw_boss() -> void:
	GameBossController.draw_boss(self)


func _update_boss_silks() -> void:
	GameBossController._update_boss_silks(self)


func _update_silk_damage(delta: float) -> void:
	GameBossController.update_silk_damage(self, delta)


func _choose_next_boss_state() -> void:
	GameBossController._choose_next_boss_state(self)


func _spawn_boss() -> void:
	GameBossController.spawn_boss(self)


func _spawn_puppets(count: int) -> void:
	GameBossController.spawn_puppets(self, count)


func _count_active_silks() -> int:
	return GameBossController.count_active_silks(self)


func _is_silk_active(enemy_id: String) -> bool:
	return GameBossController.is_silk_active(self, enemy_id)


func _find_enemy_by_id(enemy_id: String) -> Variant:
	return GameBossController.find_enemy_by_id(self, enemy_id)


func _kill_enemy_by_id(enemy_id: String) -> void:
	GameBossController.kill_enemy_by_id(self, enemy_id)


func _has_boss() -> bool:
	return GameBossController.has_boss(self)


func _to_screen(world_pos: Vector2) -> Vector2:
	return ARENA_ORIGIN + world_pos


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return (screen_pos - ARENA_ORIGIN).clamp(Vector2.ZERO, ARENA_SIZE)


func _roll_spawn_position() -> Vector2:
	var roll: float = randf()
	if roll < 0.5:
		return Vector2(randf_range(0.0, ARENA_SIZE.x), -SPAWN_MARGIN)
	if roll < 0.75:
		return Vector2(ARENA_SIZE.x + SPAWN_MARGIN, randf_range(0.0, ARENA_SIZE.y))
	return Vector2(-SPAWN_MARGIN, randf_range(0.0, ARENA_SIZE.y))


func _roll_enemy_type() -> String:
	var roll: float = randf()
	if roll > 0.9:
		return HEAVY
	if roll > 0.8:
		return CASTER
	if roll > 0.6:
		return TANK
	return SHOOTER


func _is_inside_extended_bounds(position: Vector2) -> bool:
	return position.x >= -SPAWN_MARGIN and position.x <= ARENA_SIZE.x + SPAWN_MARGIN and position.y >= -SPAWN_MARGIN and position.y <= ARENA_SIZE.y + SPAWN_MARGIN


func _next_id(prefix: String) -> String:
	id_counter += 1
	return "%s_%d" % [prefix, id_counter]


func _handle_debug_key_input(event: InputEventKey) -> bool:
	if event.keycode == KEY_F6:
		_toggle_debug_calibration_mode()
		return true
	if event.keycode == KEY_F7:
		if debug_calibration_mode:
			return true
		_toggle_debug_battle_mode()
		return true
	if debug_calibration_mode:
		var aim_distance: float = player["pos"].distance_to(mouse_world)
		match event.keycode:
			KEY_1:
				SwordArrayConfig.set_morph_distance("ring_stable_end", aim_distance)
				_refresh_sword_array_live_state()
				return true
			KEY_2:
				SwordArrayConfig.set_morph_distance("ring_to_fan_end", aim_distance)
				_refresh_sword_array_live_state()
				return true
			KEY_3:
				SwordArrayConfig.set_morph_distance("fan_stable_end", aim_distance)
				_refresh_sword_array_live_state()
				return true
			KEY_4:
				SwordArrayConfig.set_morph_distance("fan_to_pierce_end", aim_distance)
				_refresh_sword_array_live_state()
				return true
			KEY_R:
				SwordArrayConfig.reset_morph_distances()
				_refresh_sword_array_live_state()
				return true
			KEY_P:
				SwordArrayConfig.save_morph_distances_to_project()
				_refresh_sword_array_live_state()
				return true
			KEY_L:
				SwordArrayConfig.load_morph_distances_from_project()
				_refresh_sword_array_live_state()
				return true
			_:
				return false
	if not debug_battle_mode:
		return false

	match event.keycode:
		KEY_1:
			_toggle_debug_flag("infinite_health")
			return true
		KEY_2:
			_toggle_debug_flag("infinite_energy")
			return true
		KEY_3:
			_toggle_debug_flag("one_hit_kill")
			return true
		KEY_4:
			_toggle_debug_flag("no_spawn")
			return true
		KEY_5:
			_clear_enemy_bullets()
			return true
		_:
			return false


func _toggle_debug_battle_mode() -> void:
	debug_battle_mode = not debug_battle_mode
	if not debug_battle_mode:
		_reset_debug_battle_flags()
	_apply_debug_runtime_overrides()
	_update_ui()
	queue_redraw()


func _reset_debug_battle_flags() -> void:
	debug_flags = {
		"infinite_health": false,
		"infinite_energy": false,
		"one_hit_kill": false,
		"no_spawn": false,
	}


func _toggle_debug_flag(flag_name: String) -> void:
	debug_flags[flag_name] = not _has_debug_flag(flag_name)
	_apply_debug_runtime_overrides()
	_update_ui()
	queue_redraw()


func _has_debug_flag(flag_name: String) -> bool:
	return bool(debug_flags.get(flag_name, false))


func _apply_debug_runtime_overrides() -> void:
	if _has_debug_flag("infinite_health"):
		player["health"] = PLAYER_MAX_HEALTH
	if _has_debug_flag("infinite_energy"):
		player["energy"] = PLAYER_MAX_ENERGY


func _apply_player_damage(amount: float, _damage_source: String = DAMAGE_SOURCE_NONE) -> bool:
	if amount <= 0.0:
		return false
	if _has_debug_flag("infinite_health"):
		player["health"] = PLAYER_MAX_HEALTH
		return false
	player["health"] = max(player["health"] - amount, 0.0)
	return true


func _add_player_energy(amount: float) -> void:
	if amount <= 0.0:
		return
	if _has_debug_flag("infinite_energy"):
		player["energy"] = PLAYER_MAX_ENERGY
		return
	player["energy"] = min(player["energy"] + amount, PLAYER_MAX_ENERGY)


func _drain_player_energy(amount: float) -> void:
	if amount <= 0.0:
		return
	if _has_debug_flag("infinite_energy"):
		player["energy"] = PLAYER_MAX_ENERGY
		return
	player["energy"] = max(player["energy"] - amount, 0.0)


func _consume_player_energy(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if _has_debug_flag("infinite_energy"):
		player["energy"] = PLAYER_MAX_ENERGY
		return true
	if player["energy"] < amount:
		return false
	player["energy"] -= amount
	return true


func _damage_boss(damage: float) -> void:
	if not _has_boss() or damage <= 0.0:
		return
	if _has_debug_flag("one_hit_kill"):
		boss["health"] = 0.0
		return
	boss["health"] = max(boss["health"] - damage, 0.0)


func _clear_enemy_bullets() -> void:
	var index: int = bullets.size() - 1
	while index >= 0:
		_remove_bullet(index)
		index -= 1


func _get_debug_status_suffix() -> String:
	if not debug_battle_mode:
		return ""
	var active_flags: Array = []
	if _has_debug_flag("infinite_health"):
		active_flags.append("无限生命")
	if _has_debug_flag("infinite_energy"):
		active_flags.append("无限剑意")
	if _has_debug_flag("one_hit_kill"):
		active_flags.append("一击必杀")
	if _has_debug_flag("no_spawn"):
		active_flags.append("停刷怪")
	return " | %s" % ("已启用" if active_flags.is_empty() else " / ".join(active_flags))


func _toggle_debug_calibration_mode() -> void:
	debug_calibration_mode = not debug_calibration_mode
	debug_dragging_player = false
	if debug_calibration_mode:
		_enter_debug_calibration_mode()
	else:
		_reset_game()


func _enter_debug_calibration_mode() -> void:
	_reset_game()
	debug_calibration_mode = true
	debug_dragging_player = false
	player["health"] = PLAYER_MAX_HEALTH
	player["energy"] = PLAYER_MAX_ENERGY
	player["pos"] = ARENA_SIZE * 0.5
	sword["pos"] = player["pos"]
	sword["prev_pos"] = player["pos"]
	bullets.clear()
	array_swords.clear()
	enemies.clear()
	particles.clear()
	boss.clear()
	wave = 0
	score = 0
	enemies_to_spawn = 0
	spawn_timer = 9999.0
	_spawn_debug_calibration_enemies()
	_rebuild_array_sword_pool()
	_refresh_sword_array_live_state()
	_update_ui()
	queue_redraw()


func _ensure_debug_calibration_state() -> void:
	player["health"] = PLAYER_MAX_HEALTH
	player["energy"] = PLAYER_MAX_ENERGY
	enemies_to_spawn = 0
	spawn_timer = 9999.0
	if enemies.size() < DEBUG_ENEMY_LAYOUT.size():
		_spawn_debug_calibration_enemies()
	if array_swords.size() != _get_current_array_sword_capacity():
		_rebuild_array_sword_pool()


func _spawn_debug_calibration_enemies() -> void:
	enemies.clear()
	for enemy_pos in DEBUG_ENEMY_LAYOUT:
		var enemy: Dictionary = _spawn_enemy(SHOOTER)
		enemy["pos"] = enemy_pos
		enemy["vel"] = Vector2.ZERO
		enemy["shoot_cooldown"] = 9999.0
		enemy["is_debug_static"] = true
		enemy["health"] = enemy["max_health"]


func _set_debug_player_position(target_pos: Vector2) -> void:
	player["pos"] = target_pos.clamp(Vector2(PLAYER_RADIUS, PLAYER_RADIUS), ARENA_SIZE - Vector2(PLAYER_RADIUS, PLAYER_RADIUS))
	sword["pos"] = player["pos"] if sword["state"] == SwordState.ORBITING else sword["pos"]
	sword["prev_pos"] = sword["pos"]
	_refresh_sword_array_live_state()


func _dist_to_segment(point: Vector2, segment_a: Vector2, segment_b: Vector2) -> float:
	return GameBossController.dist_to_segment(point, segment_a, segment_b)


func _segment_hits_circle(segment_a: Vector2, segment_b: Vector2, center: Vector2, radius: float) -> bool:
	return _dist_to_segment(center, segment_a, segment_b) <= radius
