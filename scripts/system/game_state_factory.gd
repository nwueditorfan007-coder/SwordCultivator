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
	main.array_swords.clear()
	main.pickups.clear()
	main.particles.clear()
	main.boss.clear()
	main.boss_shard_spawn_timer = 3.5
	main.boss_shard_failed_cycles = 0
	main.status_message = ""
	main.status_message_timer = 0.0
	main.status_message_color = Color.WHITE
	main.empower_end_warning_emitted = false
	main.player = {
		"pos": main.ARENA_SIZE * 0.5,
		"vel": Vector2.ZERO,
		"health": main.PLAYER_MAX_HEALTH,
		"energy": 0.0,
		"sword_resource": 0,
		"sword_resource_max": main.SWORD_RESOURCE_MAX,
		"sword_resource_elite_pity": 0,
		"array_empower_timer": 0.0,
		"mode": main.CombatMode.MELEE,
		"attack_cooldown": 0.0,
		"attack_flash_timer": 0.0,
		"array_hold_timer": 0.0,
		"array_hold_ratio": 0.0,
		"array_is_firing": false,
		"array_release_progress": 0.0,
		"array_packet_remainder": 0.0,
		"array_fire_index": 0,
		"array_mode": SwordArrayConfig.MODE_RING,
		"array_morph_state": SwordArrayConfig.get_mode_state(SwordArrayConfig.MODE_RING),
		"array_fire_morph_state": SwordArrayConfig.get_mode_state(SwordArrayConfig.MODE_RING),
		"array_raw_aim_distance": 0.0,
		"array_control_distance": 0.0,
	}
	main.debug_battle_mode = false
	main.debug_flags = {
		"infinite_health": false,
		"infinite_energy": false,
		"one_hit_kill": false,
		"no_spawn": false,
		"infinite_sword_resources": false,
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
	main._rebuild_array_sword_pool()
	main._update_ui()
	main.queue_redraw()
