extends RefCounted
class_name GameStateFactory

const DamageResolver = preload("res://scripts/combat/damage_resolver.gd")
const SwordArrayConfig = preload("res://scripts/system/sword_array_config.gd")
const HitDetection = preload("res://scripts/combat/hit_detection.gd")
const HitRegistry = preload("res://scripts/combat/hit_registry.gd")
const HurtboxRegistry = preload("res://scripts/combat/hurtbox_registry.gd")
const TargetDescriptorRegistry = preload("res://scripts/combat/target_descriptor_registry.gd")
const TargetEventSystem = preload("res://scripts/combat/target_event_system.gd")
const TargetWritebackAdapters = preload("res://scripts/combat/target_writeback_adapters.gd")


static func reset_runtime(main: Node) -> void:
	main.left_mouse_held = false
	main.right_mouse_held = false
	main.elapsed_time = 0.0
	main.wave = 1
	main.score = 0
	main.enemies_to_spawn = main.WAVE_BASE_ENEMIES
	main.wave_spawn_queue = []
	main.spawn_timer = 0.2
	main.screen_shake = 0.0
	main.is_game_over = false
	main.enemies.clear()
	main.bullets.clear()
	main.array_swords.clear()
	main.particles.clear()
	main.sword_afterimages.clear()
	main.sword_trail_points.clear()
	main.sword_hit_effects.clear()
	main.boss.clear()
	main.status_message = ""
	main.status_message_timer = 0.0
	main.status_message_color = Color.WHITE
	main.focus_status_message = ""
	main.focus_status_message_timer = 0.0
	main.focus_status_message_color = Color.WHITE
	main.array_energy_forecast_level = 0
	main.array_energy_warning_display = 0.0
	main.array_energy_break_timer = 0.0
	main.array_mode_confirm_timer = 0.0
	main.array_mode_confirm_cooldown = 0.0
	main.array_mode_confirm_mode = ""
	main.array_mode_confirm_angle = 0.0
	main.energy_gain_feedback_timer = 0.0
	main.energy_gain_feedback_strength = 0.0
	main.energy_gain_feedback_color = Color.WHITE
	main.hitstop_timer = 0.0
	main.hitstop_queue = []
	main.hitstop_gap_timer = 0.0
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
		"array_release_progress": 0.0,
		"array_packet_remainder": 0.0,
		"array_fire_index": 0,
		"array_mode": SwordArrayConfig.MODE_RING,
		"array_morph_state": SwordArrayConfig.get_mode_state(SwordArrayConfig.MODE_RING),
		"array_fire_morph_state": SwordArrayConfig.get_mode_state(SwordArrayConfig.MODE_RING),
		"array_confirm_observed_stable_mode": SwordArrayConfig.MODE_RING,
		"array_raw_aim_distance": 0.0,
		"array_control_distance": 0.0,
	}
	main.debug_battle_mode = false
	main.debug_flags = {
		"infinite_health": false,
		"infinite_energy": false,
		"one_hit_kill": false,
		"no_spawn": false,
	}
	main.debug_calibration_mode = false
	main.debug_dragging_player = false
	main.visual_time_stop_strength = 0.0
	main.visual_time_stop_hold_timer = 0.0
	main.visual_time_stop_entry_pulse_timer = 0.0
	main.unsheath_flash_timer = 0.0
	main.unsheath_flash_origin = main.ARENA_SIZE * 0.5
	main.unsheath_flash_direction = Vector2.RIGHT
	main.unsheath_flash_strength = 0.0
	main.unsheath_flash_repeat_timer = 0.0
	main.unsheath_press_flash_timer = 0.0
	main.unsheath_press_flash_origin = main.ARENA_SIZE * 0.5
	main.unsheath_press_flash_direction = Vector2.RIGHT
	main.unsheath_press_flash_strength = 0.0
	main.unsheath_press_flash_repeat_timer = 0.0
	main.sword = {
		"pos": main.ARENA_SIZE * 0.5,
		"prev_pos": main.ARENA_SIZE * 0.5,
		"vel": Vector2.ZERO,
		"angle": 0.0,
		"radius": main.SWORD_RADIUS,
		"state": main.SwordState.ORBITING,
		"attack_instance_id": "",
		"attack_profile_id": "",
		"press_timer": 0.0,
		"time_slow_timer": 0.0,
		"target_pos": main.ARENA_SIZE * 0.5,
		"afterimage_burst_timer": 0.0,
		"afterimage_emit_timer": 0.0,
		"trail_emit_timer": 0.0,
		"impact_feedback_timer": 0.0,
		"impact_feedback_offset": Vector2.ZERO,
		"impact_angle_offset": 0.0,
	}
	main.hit_registry = HitRegistry.new()
	main.hurtbox_registry = HurtboxRegistry.new()
	main.damage_resolver = DamageResolver.new()
	main.hit_detection = HitDetection.new()
	main.target_descriptor_registry = TargetDescriptorRegistry.new()
	main.target_event_system = TargetEventSystem.new()
	main.target_writeback_adapters = TargetWritebackAdapters.new()
	main.combat_runtime = {
		"attack_instances": {},
		"target_states": {},
	}
	main.enemy_packages = {}
	main.game_over_label.visible = false
	main._rebuild_array_sword_pool()
	main._update_ui()
	main.queue_redraw()
