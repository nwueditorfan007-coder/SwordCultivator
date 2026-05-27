extends "res://scripts/prototypes/yujian_sprite_sequence_prototype.gd"

const YUJIAN_MODEL_TO_2D_VISUAL := preload("res://scripts/prototypes/yujian_model_to_2d_flight_visual.gd")

@export_file("*.tscn", "*.scn", "*.glb", "*.gltf", "*.fbx") var model_visual_path := "res://resources/modle/000_男主角/000_Nanzhujue_LOD.FBX"
@export_range(0.5, 4.0, 0.05) var model_visual_model_scale := 1.0
@export_range(0.15, 1.2, 0.01) var model_visual_texture_scale := 0.74
@export_range(1.2, 8.0, 0.05) var model_visual_camera_size := 6.2
@export_range(0.3, 1.8, 0.01) var model_visual_root_scale := 0.82
@export var model_visual_use_preview_materials := true
@export var model_visual_force_silhouette := false
@export var model_visual_enable_bone_pose := true

var model_flight_visual: Node2D


func _create_nodes() -> void:
	eight_way_character_set = EIGHT_WAY_SET_V4_SKELETON
	super._create_nodes()
	_install_model_flight_visual()


func _install_model_flight_visual() -> void:
	if sprite_root == null:
		return
	if skeleton_character != null:
		var old_skeleton := skeleton_character
		old_skeleton.visible = false
		if old_skeleton.get_parent() == sprite_root:
			sprite_root.remove_child(old_skeleton)
		old_skeleton.queue_free()
	model_flight_visual = YUJIAN_MODEL_TO_2D_VISUAL.new()
	model_flight_visual.name = "ModelTo2DFlightCharacter"
	model_flight_visual.set("model_path", model_visual_path)
	model_flight_visual.set("model_scale", model_visual_model_scale)
	model_flight_visual.set("sprite_texture_scale", model_visual_texture_scale)
	model_flight_visual.set("camera_size", model_visual_camera_size)
	model_flight_visual.set("use_preview_materials", model_visual_use_preview_materials)
	model_flight_visual.set("force_silhouette_material", model_visual_force_silhouette)
	model_flight_visual.set("enable_bone_pose", model_visual_enable_bone_pose)
	skeleton_character = model_flight_visual
	sprite_root.add_child(skeleton_character)
	if character_sprite != null:
		character_sprite.visible = false
	if ink_part_character != null:
		ink_part_character.visible = false
	skeleton_character.visible = true


func _set_eight_way_character_set(_next_set: int) -> void:
	eight_way_character_set = EIGHT_WAY_SET_V4_SKELETON
	if character_sprite != null:
		character_sprite.visible = false
	if ink_part_character != null:
		ink_part_character.visible = false
	if skeleton_character != null:
		skeleton_character.visible = true
	eight_way_texture_initialized = false
	eight_way_visual_adjustments_initialized = false
	_refresh_adjustment_controls()
	queue_redraw()


func _create_adjustment_panel() -> void:
	super._create_adjustment_panel()
	if adjustment_panel != null:
		adjustment_panel.visible = false


func _current_eight_way_set_label() -> String:
	return "3D model to 2D"


func _is_skeleton_pose_editor_active() -> bool:
	return false


func _apply_skeleton_eight_way_transform(delta: float, turn_lean: float) -> void:
	if skeleton_character == null:
		return
	if character_sprite != null:
		character_sprite.visible = false
	if ink_part_character != null:
		ink_part_character.visible = false
	skeleton_character.visible = true
	var adjustment_scale := _get_eight_way_global_scale(eight_way_character_set) * eight_way_visual_direction_scale
	var pose_scale := model_visual_root_scale * adjustment_scale * (1.0 + 0.045 * boost_energy + 0.035 * carve_energy)
	var switch_side := visual_heading.rotated(direction_switch_direction * PI * 0.5)
	var switch_offset := (-visual_heading * 4.0 + switch_side * 5.0) * direction_switch_energy
	skeleton_character.position = SKELETON_POSE_OFFSET + eight_way_visual_offset + Vector2(0.0, -5.0 * boost_energy - 2.0 * carve_energy) + switch_offset
	skeleton_character.rotation = -turn_lean * 0.018 + carve_direction * carve_energy * 0.030 + direction_switch_direction * direction_switch_energy * 0.030
	skeleton_character.scale = Vector2.ONE * pose_scale
	if skeleton_character.has_method("set_flight_context"):
		skeleton_character.call(
			"set_flight_context",
			turn_lean,
			carve_direction,
			direction_switch_direction,
			direction_switch_energy
		)
	if skeleton_character.has_method("set_flight_pose"):
		skeleton_character.call(
			"set_flight_pose",
			eight_way_index,
			visual_heading,
			velocity,
			boost_energy,
			turn_energy,
			carve_energy,
			throttle_energy,
			delta
		)


func _draw_debug() -> void:
	var clip := _current_clip()
	var speed_label := "boost" if speed_mode == SPEED_MODE_BOOST else "cruise"
	var control_label := "direct intent" if control_mode == CONTROL_MODE_DIRECT_INTENT else "steer throttle"
	var model_label := model_visual_path
	if model_flight_visual != null and model_flight_visual.has_method("get_active_model_path"):
		model_label = str(model_flight_visual.call("get_active_model_path"))
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 32.0), "Yujian flight 3D-to-2D  |  same movement/VFX as v2  |  WASD intent  Space boost  F3 mode  F2 panel  T demo", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16.0, Color(0.91, 0.96, 0.95, 0.84))
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 56.0), "control: %s  clip: %s  frame: %d/%d  visual: model viewport %s  mode: %s  speed: %.1f  throttle %.2f carve %.2f turn %.0fdeg  body %.0fdeg visual %.0fdeg  zoom %.2f  pos %.0f,%.0f" % [control_label, String(clip["name"]), frame_index, int(clip["frames"]) - 1, model_label, speed_label, velocity.length(), throttle_energy, carve_energy, rad_to_deg(heading_angle_delta), rad_to_deg(body_heading.angle()), rad_to_deg(visual_heading.angle()), camera_zoom, flight_pos.x, flight_pos.y], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13.0, Color(0.72, 0.86, 0.86, 0.76))
