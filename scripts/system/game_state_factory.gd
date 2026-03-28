extends RefCounted
class_name GameStateFactory

const SwordArrayConfig = preload("res://scripts/system/sword_array_config.gd")


static func reset_runtime(main: Node) -> void:
	main.left_mouse_held = false
	main.right_mouse_held = false
	main.elapsed_time = 0.0
	main.wave = 1
	main.score = 0
	main.enemies_to_spawn = main.WAVE_BASE_ENEMIES
	main.spawn_timer = 0.2
	main.screen_shake = 0.0
	main.is_game_over = false
	main.enemies.clear()
	main.bullets.clear()
	main.particles.clear()
	main.boss.clear()
	main.player = {
		"pos": main.ARENA_SIZE * 0.5,
		"vel": Vector2.ZERO,
		"health": main.PLAYER_MAX_HEALTH,
		"energy": 0.0,
		"mode": main.CombatMode.MELEE,
		"attack_cooldown": 0.0,
		"attack_flash_timer": 0.0,
		"array_hold_timer": 0.0,
		"array_hold_ratio": 0.0,
		"array_is_firing": false,
		"fire_timer": 0.0,
		"array_fire_index": 0,
		"array_burst_step": 0,
		"array_burst_mode": "",
		"array_fire_mode": "",
		"array_mode": SwordArrayConfig.MODE_RING,
		"array_morph_state": SwordArrayConfig.get_mode_state(SwordArrayConfig.MODE_RING),
		"is_charging": false,
		"absorbed_ids": [],
	}
	main.debug_calibration_mode = false
	main.debug_dragging_player = false
	main.sword = {
		"pos": main.ARENA_SIZE * 0.5,
		"prev_pos": main.ARENA_SIZE * 0.5,
		"vel": Vector2.ZERO,
		"angle": 0.0,
		"radius": main.SWORD_RADIUS,
		"state": main.SwordState.ORBITING,
		"press_timer": 0.0,
		"time_slow_timer": 0.0,
		"target_pos": main.ARENA_SIZE * 0.5,
	}
	main.game_over_label.visible = false
	main._update_ui()
	main.queue_redraw()
