extends Node2D

const GameBossController = preload("res://scripts/system/game_boss_controller.gd")
const GameRenderer = preload("res://scripts/system/game_renderer.gd")
const GameStateFactory = preload("res://scripts/system/game_state_factory.gd")
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

const ENERGY_CONSUMPTION_RANGED := 0.25 * 60.0
const ENERGY_RECOVERY_MELEE_NATURAL := 0.05 * 60.0
const ENERGY_GAIN_MELEE_HIT := 2.0
const ENERGY_GAIN_MELEE_DEFLECT := 8.0

const FROZEN_DECEL_TIME := 0.3
const FROZEN_LIFETIME := 3.0
const MARBLE_ABSORB_RANGE := 250.0
const MARBLE_AUTO_ABSORB_RANGE := 110.0
const MARBLE_MAX_ABSORBED := 12
const MARBLE_FIRED_SPEED := 45.0 * 60.0
const MARBLE_FIRED_DAMAGE := 100.0
const SWORD_ARRAY_RING_THRESHOLD := 160.0
const SWORD_ARRAY_FAN_THRESHOLD := 420.0
const SWORD_ARRAY_FAN_ARC := 1.0
const SWORD_ARRAY_RING_RADIUS := 68.0
const SWORD_ARRAY_FAN_PREVIEW_RADIUS := 110.0
const SWORD_ARRAY_PIERCE_SPREAD := 0.08
const SWORD_ARRAY_PIERCE_START_OFFSET := 52.0
const SWORD_ARRAY_PIERCE_SLOT_STEP := 28.0
const SWORD_ARRAY_PIERCE_PREVIEW_LENGTH := 180.0
const SWORD_ARRAY_PIERCE_PREVIEW_HALF_WIDTH := 6.0
const SWORD_ARRAY_RING_SLOT_COUNT := 10
const SWORD_ARRAY_FAN_SLOT_COUNT := 7
const SWORD_ARRAY_PIERCE_SLOT_COUNT := 5
const SWORD_ARRAY_RING_FIRE_RATE := 0.32
const SWORD_ARRAY_FAN_FIRE_RATE := 0.16
const SWORD_ARRAY_PIERCE_FIRE_RATE := 0.08

const SWORD_ARRAY_RING := "ring"
const SWORD_ARRAY_FAN := "fan"
const SWORD_ARRAY_PIERCE := "pierce"

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

var mouse_world: Vector2 = ARENA_SIZE * 0.5
var right_mouse_held: bool = false

@onready var health_label: Label = $CanvasLayer/HealthLabel
@onready var energy_label: Label = $CanvasLayer/EnergyLabel
@onready var wave_label: Label = $CanvasLayer/WaveLabel
@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var mode_label: Label = $CanvasLayer/ModeLabel
@onready var hint_label: Label = $CanvasLayer/HintLabel
@onready var game_over_label: Label = $CanvasLayer/GameOverLabel


func _ready() -> void:
	randomize()
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
		var recovery_progress: float = min(sword["time_slow_timer"] / BULLET_TIME_RECOVERY_DURATION, 1.0)
		bullet_time_ratio = lerpf(BULLET_TIME_START_MULTIPLIER, 1.0, recovery_progress)
		player_time_ratio = lerpf(PLAYER_BULLET_TIME_SPEED_MULTIPLIER, 1.0, recovery_progress)

	var bullet_time_delta: float = delta * bullet_time_ratio
	var player_delta: float = delta * player_time_ratio

	if right_mouse_held:
		sword["press_timer"] += delta
		if sword["press_timer"] > SWORD_TAP_THRESHOLD and sword["state"] == SwordState.ORBITING:
			sword["state"] = SwordState.SLICING
			player["mode"] = CombatMode.RANGED

	if Input.is_action_just_pressed("absorb"):
		player["fire_timer"] = 0.0
		player["array_fire_index"] = 0
		player["array_burst_step"] = 0
		player["array_burst_mode"] = _get_sword_array_mode()

	if Input.is_action_just_released("absorb"):
		player["fire_timer"] = 0.0
		player["array_fire_index"] = 0
		player["array_burst_step"] = 0
		player["array_burst_mode"] = ""

	if Input.is_action_pressed("absorb") and player["absorbed_ids"].size() > 0:
		player["array_mode"] = _get_sword_array_mode()
		player["fire_timer"] -= delta
		if player["fire_timer"] <= 0.0:
			_fire_absorbed_marbles()
			player["fire_timer"] = SwordArrayController.get_fire_interval(self, player["array_mode"])

	_update_auto_absorption()
	_update_player(delta, player_delta)
	_update_sword(delta)
	_update_boss(delta, bullet_time_delta)
	_update_enemies(bullet_time_delta)
	_update_bullets(delta, bullet_time_delta)
	_update_particles(bullet_time_delta)
	_update_wave(delta)
	_try_cast_ultimate()
	_cleanup_absorbed_ids()

	if player["health"] <= 0.0:
		_set_game_over()

	screen_shake = lerpf(screen_shake, 0.0, min(delta * 10.0, 1.0))
	_update_ui()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_world = _screen_to_world(event.position)
	elif event is InputEventMouseButton:
		mouse_world = _screen_to_world(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if is_game_over:
					_reset_game()
					return
				if sword["state"] == SwordState.ORBITING and player["attack_cooldown"] <= 0.0:
					_perform_melee_attack()
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


func _update_player(delta: float, player_delta: float) -> void:
	var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not move_input.is_zero_approx():
		player["vel"] = move_input.normalized() * PLAYER_SPEED
	else:
		player["vel"] = player["vel"].lerp(Vector2.ZERO, min(delta * 8.0, 1.0))

	player["pos"] += player["vel"] * player_delta
	player["pos"] = player["pos"].clamp(Vector2(PLAYER_RADIUS, PLAYER_RADIUS), ARENA_SIZE - Vector2(PLAYER_RADIUS, PLAYER_RADIUS))

	player["attack_cooldown"] = max(player["attack_cooldown"] - delta, 0.0)
	player["attack_flash_timer"] = max(player["attack_flash_timer"] - delta, 0.0)


func _update_auto_absorption() -> void:
	player["is_charging"] = false
	player["array_mode"] = _get_sword_array_mode()
	for bullet in bullets:
		if bullet["state"] != "frozen":
			continue
		if player["absorbed_ids"].has(bullet["id"]):
			continue
		if player["absorbed_ids"].size() >= MARBLE_MAX_ABSORBED:
			break
		if player["pos"].distance_to(bullet["pos"]) <= MARBLE_AUTO_ABSORB_RANGE:
			player["absorbed_ids"].append(bullet["id"])
			player["array_mode"] = _get_sword_array_mode()


func _update_sword(delta: float) -> void:
	sword["prev_pos"] = sword["pos"]

	if sword["state"] == SwordState.ORBITING:
		player["energy"] = min(player["energy"] + ENERGY_RECOVERY_MELEE_NATURAL * delta, PLAYER_MAX_ENERGY)
		sword["angle"] += SWORD_ROTATION_SPEED * delta
		var target: Vector2 = player["pos"] + Vector2.RIGHT.rotated(sword["angle"]) * SWORD_ORBIT_DISTANCE
		sword["pos"] = sword["pos"].lerp(target, min(delta * 18.0, 1.0))
		return

	if sword["state"] == SwordState.SLICING:
		player["energy"] = max(player["energy"] - ENERGY_CONSUMPTION_RANGED * delta, 0.0)
		if player["energy"] <= 0.0:
			sword["state"] = SwordState.RECALLING
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
		enemy["health"] -= damage
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
				boss["health"] -= boss_damage
				_create_particles(sword["pos"], COLORS["boss_body"], 2)


func _update_enemies(delta: float) -> void:
	var index: int = enemies.size() - 1
	while index >= 0:
		var enemy: Dictionary = enemies[index]
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
					player["health"] -= 30.0 * delta
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
							player["health"] -= PUPPET_MELEE_DAMAGE
							screen_shake = max(screen_shake, 5.0)
							_create_particles(player["pos"], COLORS["puppet"], 10)

		if enemy["health"] <= 0.0:
			_create_particles(enemy["pos"], COLORS[enemy["type"]], 14)
			if enemy["type"] != PUPPET:
				score += enemy["score"]
				player["energy"] = min(player["energy"] + ENERGY_GAIN_MELEE_HIT * 2.0, PLAYER_MAX_ENERGY)
			enemies.remove_at(index)
		index -= 1


func _update_bullets(delta: float, bullet_time_delta: float) -> void:
	var index: int = bullets.size() - 1
	while index >= 0:
		var bullet: Dictionary = bullets[index]
		match bullet["state"]:
			"freezing":
				bullet["freeze_timer"] -= delta
				if bullet["freeze_timer"] <= 0.0:
					bullet["state"] = "frozen"
					bullet["vel"] = Vector2.ZERO
				else:
					bullet["vel"] *= bullet["freeze_timer"] / FROZEN_DECEL_TIME
					bullet["pos"] += bullet["vel"] * bullet_time_delta
			"frozen":
				if player["absorbed_ids"].has(bullet["id"]):
					var slot_index: int = player["absorbed_ids"].find(bullet["id"])
					var target_pos: Vector2 = SwordArrayController.get_slot_position(
						self,
						player["array_mode"],
						slot_index,
						player["absorbed_ids"].size()
					)
					bullet["pos"] = bullet["pos"].lerp(target_pos, min(delta * 12.0, 1.0))
				else:
					bullet["life_timer"] -= delta
					if bullet["life_timer"] <= 0.0:
						_remove_bullet(index)
						index -= 1
						continue
			"fired":
				bullet["pos"] += bullet["vel"] * delta
				if _bullet_hits_enemy(bullet):
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
				if _player_hit_by_bullet(bullet):
					_remove_bullet(index)
					index -= 1
					continue
		index -= 1


func _bullet_hits_enemy(bullet: Dictionary) -> bool:
	for enemy in enemies:
		if enemy["type"] == PUPPET:
			continue
		if enemy["pos"].distance_to(bullet["pos"]) > enemy["radius"] + bullet["radius"]:
			continue
		enemy["health"] -= MARBLE_FIRED_DAMAGE
		_create_particles(bullet["pos"], COLORS["frozen"], 10)
		return true
	if _has_boss():
		if boss["pos"].distance_to(bullet["pos"]) <= boss["radius"] + bullet["radius"] and (boss["is_vulnerable"] or boss["phase"] == 1):
			boss["health"] -= MARBLE_FIRED_DAMAGE * 2.0
			_create_particles(bullet["pos"], COLORS["frozen"], 15)
			return true
	return false


func _player_hit_by_bullet(bullet: Dictionary) -> bool:
	if player["pos"].distance_to(bullet["pos"]) > PLAYER_RADIUS + bullet["radius"]:
		return false
	player["health"] -= bullet["damage"]
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

	spawn_timer -= delta
	if spawn_timer > 0.0:
		return

	spawn_timer = SPAWN_INTERVAL
	_spawn_enemy(_roll_enemy_type())
	enemies_to_spawn -= 1


func _try_cast_ultimate() -> void:
	if not Input.is_action_just_pressed("ultimate"):
		return
	if player["energy"] < PLAYER_MAX_ENERGY:
		return

	player["energy"] = 0.0
	screen_shake = max(screen_shake, 14.0)
	var index: int = bullets.size() - 1
	while index >= 0:
		_remove_bullet(index)
		index -= 1
	for enemy in enemies:
		if enemy["type"] == PUPPET:
			continue
		enemy["health"] -= 50.0
		_create_particles(enemy["pos"], COLORS["energy"], 12)
	if _has_boss():
		boss["health"] -= 250.0
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
		bullet["state"] = "freezing"
		bullet["freeze_timer"] = FROZEN_DECEL_TIME
		bullet["life_timer"] = FROZEN_LIFETIME
		player["energy"] = min(player["energy"] + (ENERGY_GAIN_MELEE_DEFLECT * (1.5 if bullet["type"] == "large" else 1.0)), PLAYER_MAX_ENERGY)
		_create_particles(bullet["pos"], COLORS["frozen"], 6)
		screen_shake = max(screen_shake, 3.0)

	for enemy in enemies:
		var enemy_offset: Vector2 = enemy["pos"] - player["pos"]
		if enemy_offset.length() > SWORD_MELEE_RANGE + enemy["radius"]:
			continue
		if absf(wrapf(enemy_offset.angle() - attack_angle, -PI, PI)) > SWORD_MELEE_ARC * 0.5:
			continue
		if enemy["type"] == PUPPET:
			continue
		enemy["health"] -= SWORD_MELEE_DAMAGE
		player["energy"] = min(player["energy"] + ENERGY_GAIN_MELEE_HIT, PLAYER_MAX_ENERGY)
		_create_particles(enemy["pos"], COLORS[enemy["type"]], 5)
		screen_shake = max(screen_shake, 4.0)

	if _has_boss() and (boss["is_vulnerable"] or boss["phase"] == 1):
		var boss_offset: Vector2 = boss["pos"] - player["pos"]
		if boss_offset.length() <= SWORD_MELEE_RANGE + boss["radius"]:
			if absf(wrapf(boss_offset.angle() - attack_angle, -PI, PI)) <= SWORD_MELEE_ARC * 0.5:
				boss["health"] -= SWORD_MELEE_DAMAGE
				player["energy"] = min(player["energy"] + ENERGY_GAIN_MELEE_HIT, PLAYER_MAX_ENERGY)
				_create_particles(boss["pos"], COLORS["boss_body"], 8)
				screen_shake = max(screen_shake, 5.0)


func _start_point_strike() -> void:
	sword["state"] = SwordState.POINT_STRIKE
	sword["target_pos"] = mouse_world
	player["mode"] = CombatMode.RANGED


func _fire_absorbed_marbles() -> void:
	if player["absorbed_ids"].is_empty():
		return
	var current_mode: String = player["array_mode"]
	if player["array_burst_mode"] != current_mode:
		player["array_burst_mode"] = current_mode
		player["array_burst_step"] = 0

	var batch_size: int = SwordArrayController.get_fire_batch_size(
		self,
		current_mode,
		player["absorbed_ids"].size(),
		player["array_burst_step"]
	)
	var fire_count: int = mini(batch_size, player["absorbed_ids"].size())
	var fired_count: int = 0
	while fired_count < fire_count:
		_fire_single_absorbed_marble()
		fired_count += 1

	match current_mode:
		SWORD_ARRAY_FAN:
			player["array_burst_step"] = (player["array_burst_step"] + 1) % 3
		_:
			player["array_burst_step"] = 0


func _fire_single_absorbed_marble() -> void:
	if player["absorbed_ids"].is_empty():
		return
	var bullet_id: String = player["absorbed_ids"].pop_front()
	for bullet in bullets:
		if bullet["id"] != bullet_id:
			continue
		var direction: Vector2 = _get_sword_array_direction(player["array_fire_index"])
		bullet["state"] = "fired"
		bullet["vel"] = direction.normalized() * MARBLE_FIRED_SPEED
		player["array_fire_index"] += 1
		_create_particles(bullet["pos"], COLORS["frozen"], 5)
		screen_shake = max(screen_shake, 2.0)
		return


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
	var bullet_id: String = bullets[index]["id"]
	var absorbed_index: int = player["absorbed_ids"].find(bullet_id)
	if absorbed_index != -1:
		player["absorbed_ids"].remove_at(absorbed_index)
	bullets.remove_at(index)


func _cleanup_absorbed_ids() -> void:
	var index: int = player["absorbed_ids"].size() - 1
	while index >= 0:
		var bullet_id: String = player["absorbed_ids"][index]
		var exists: bool = false
		for bullet in bullets:
			if bullet["id"] == bullet_id:
				exists = true
				break
		if not exists:
			player["absorbed_ids"].remove_at(index)
		index -= 1


func _set_game_over() -> void:
	is_game_over = true
	right_mouse_held = false
	game_over_label.visible = true


func _update_ui() -> void:
	health_label.text = "生命 %.0f / %.0f" % [player["health"], PLAYER_MAX_HEALTH]
	energy_label.text = "剑意 %.0f / %.0f" % [player["energy"], PLAYER_MAX_ENERGY]
	wave_label.text = "波次 %d" % wave
	score_label.text = "得分 %d" % score
	var sword_mode_text: String = "近战" if sword["state"] == SwordState.ORBITING else "御剑"
	var bullet_time_text: String = " | 子弹时间" if sword["state"] != SwordState.ORBITING else ""
	mode_label.text = "%s%s" % [sword_mode_text, bullet_time_text]
	hint_label.text = "WASD 移动 | 左键 挥剑 | 右键 点刺或连斩 | Space 剑阵发射 | Q 必杀"
	game_over_label.text = "力竭身亡\n最终得分 %d  波次 %d\n左键重新开始" % [score, wave]


func _get_sword_array_mode() -> String:
	return SwordArrayController.get_mode(self)


func _get_sword_array_direction(fire_index: int) -> Vector2:
	return SwordArrayController.get_fire_direction(self, player["array_mode"], fire_index)


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


func _dist_to_segment(point: Vector2, segment_a: Vector2, segment_b: Vector2) -> float:
	return GameBossController.dist_to_segment(point, segment_a, segment_b)


func _segment_hits_circle(segment_a: Vector2, segment_b: Vector2, center: Vector2, radius: float) -> bool:
	return _dist_to_segment(center, segment_a, segment_b) <= radius
