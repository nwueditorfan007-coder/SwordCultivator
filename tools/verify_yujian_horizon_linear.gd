extends SceneTree

const SCENE_PATH := "res://scenes/prototypes/YujianSpriteSequencePrototype.tscn"
const EPSILON := 0.001
const BOUNDS_EPSILON := 0.02

var had_failure := false


func _initialize() -> void:
	var scene := load(SCENE_PATH)
	if scene == null:
		_fail("Failed to load scene: %s" % SCENE_PATH)
		return

	var root := (scene as PackedScene).instantiate()
	root.set("显示调试文本", false)
	get_root().add_child(root)

	for i in range(4):
		await process_frame

	var start_pos: Vector2 = root.get("flight_pos")
	var renderer := root.get_node_or_null("YujianLevelBackgroundRenderer")
	if renderer == null:
		_fail("Missing YujianLevelBackgroundRenderer")
		quit(1)
		return
	var response := float(renderer.call("get_horizon_y_response"))
	var base_horizon := _horizon_for(root, start_pos, start_pos, Vector2.ZERO, 1.12)

	var up_1000 := _horizon_for(root, start_pos + Vector2(0.0, -1000.0), start_pos, Vector2(240.0, -90.0), 1.30)
	var up_2000 := _horizon_for(root, start_pos + Vector2(0.0, -2000.0), start_pos + Vector2(900.0, 600.0), Vector2(-360.0, 110.0), 1.12)
	var right_fast := _horizon_for(root, start_pos + Vector2(5000.0, 0.0), start_pos + Vector2(1200.0, -800.0), Vector2(360.0, -110.0), 1.30)
	var down_1000 := _horizon_for(root, start_pos + Vector2(0.0, 1000.0), start_pos + Vector2(-700.0, -300.0), Vector2(-240.0, 90.0), 1.30)
	var down_10000 := _horizon_for(root, start_pos + Vector2(0.0, 10000.0), start_pos + Vector2(-700.0, -300.0), Vector2(-240.0, 90.0), 1.30)

	_expect_close("up_1000", up_1000 - base_horizon, 1000.0 * response)
	_expect_close("up_2000", up_2000 - base_horizon, 2000.0 * response)
	_expect_close("down_1000", down_1000 - base_horizon, -1000.0 * response)
	_expect_close("down_10000", down_10000 - base_horizon, -10000.0 * response)
	_expect_close("right_fast", right_fast - base_horizon, 0.0)
	var camera_delta_normal := _camera_screen_delta_for(root, start_pos, 1.12)
	var camera_delta_boost := _camera_screen_delta_for(root, start_pos, 1.30)
	var background_delta_normal := _background_screen_delta_for(root, start_pos, 1.12)
	var background_delta_boost := _background_screen_delta_for(root, start_pos, 1.30)
	_expect_less("camera_zoom_widens_view", camera_delta_boost, camera_delta_normal)
	_expect_close("background_ignores_camera_zoom", background_delta_boost, background_delta_normal)
	_expect_bottom_boundary_projection_contract(root, renderer, start_pos)
	_expect_scenic_y_linear_velocity_contract(root, renderer, start_pos)
	_expect_scenic_y_ignores_vertical_camera_framing(root, renderer, start_pos)
	_expect_scenic_visible_bounds_linear_contract(root, renderer, start_pos)
	_expect_scenic_bounds_visibility_contract(root, renderer, start_pos)
	_expect_scenic_profile_bottom_layout_contract(root, renderer, start_pos)
	if had_failure:
		quit(1)
		return

	print("yujian_background_contract_ok base=%.3f response=%.5f up1000=%.3f up2000=%.3f down1000=%.3f down10000=%.3f right_fast=%.3f camera_delta_normal=%.3f camera_delta_boost=%.3f background_delta_normal=%.3f background_delta_boost=%.3f" % [
		base_horizon,
		response,
		up_1000,
		up_2000,
		down_1000,
		down_10000,
		right_fast,
		camera_delta_normal,
		camera_delta_boost,
		background_delta_normal,
		background_delta_boost,
	])
	quit()


func _horizon_for(root: Node, flight_position: Vector2, camera_position: Vector2, look_ahead: Vector2, zoom: float) -> float:
	root.set("flight_pos", flight_position)
	root.set("visual_pos", flight_position)
	root.set("camera_center", camera_position)
	root.set("camera_look_ahead", look_ahead)
	root.set("camera_zoom", zoom)
	root.set("velocity", Vector2(2600.0, 0.0))
	root.set("throttle_energy", 1.0)
	root.set("boost_energy", 1.0)
	root.call("_sync_level_background_renderer")
	var renderer := root.get_node_or_null("YujianLevelBackgroundRenderer")
	return float(renderer.call("get_horizon_y"))


func _expect_close(label: String, actual: float, expected: float) -> void:
	if absf(actual - expected) > EPSILON:
		_fail("%s expected %.5f got %.5f" % [label, expected, actual])


func _expect_bounds_close(label: String, actual: float, expected: float) -> void:
	if absf(actual - expected) > BOUNDS_EPSILON:
		_fail("%s expected %.5f got %.5f" % [label, expected, actual])


func _expect_less(label: String, actual: float, limit: float) -> void:
	if not actual < limit:
		_fail("%s expected %.5f to be less than %.5f" % [label, actual, limit])


func _expect_greater(label: String, actual: float, limit: float) -> void:
	if not actual > limit:
		_fail("%s expected %.5f to be greater than %.5f" % [label, actual, limit])


func _expect_true(label: String, actual: bool) -> void:
	if not actual:
		_fail("%s expected true" % label)


func _camera_screen_delta_for(root: Node, start_pos: Vector2, zoom: float) -> float:
	root.set("flight_pos", start_pos)
	root.set("camera_center", start_pos)
	root.set("camera_zoom", zoom)
	var p0: Vector2 = root.call("_world_to_screen", start_pos)
	var p1: Vector2 = root.call("_world_to_screen", start_pos + Vector2(1200.0, 0.0))
	return p1.x - p0.x


func _background_screen_delta_for(root: Node, start_pos: Vector2, zoom: float) -> float:
	root.set("flight_pos", start_pos)
	root.set("camera_center", start_pos)
	root.set("camera_zoom", zoom)
	root.call("_sync_level_background_renderer")
	var renderer := root.get_node_or_null("YujianLevelBackgroundRenderer")
	var x0 := float(renderer.call("background_screen_x", start_pos.x, 0.70))
	var x1 := float(renderer.call("background_screen_x", start_pos.x + 1200.0, 0.70))
	return x1 - x0


func _expect_bottom_boundary_projection_contract(root: Node, renderer: Node, start_pos: Vector2) -> void:
	var bottom_camera: Vector2 = root.call("_clamp_camera_center", Vector2(start_pos.x, 100000.0))
	var higher_flight := bottom_camera + Vector2(0.0, -260.0)
	var lower_flight := bottom_camera + Vector2(0.0, 260.0)
	var near_world_y := start_pos.y + 3600.0
	var mid_world_y := start_pos.y + 3600.0
	var far_world_y := start_pos.y + 3600.0
	var near_higher := _project_y_for(root, renderer, higher_flight, bottom_camera, start_pos.x + 6200.0, near_world_y, 0.82, "near", "near_sea")
	var near_lower := _project_y_for(root, renderer, lower_flight, bottom_camera, start_pos.x + 6200.0, near_world_y, 0.82, "near", "near_sea")
	var mid_higher := _project_y_for(root, renderer, higher_flight, bottom_camera, start_pos.x + 6200.0, mid_world_y, 0.42, "mid", "mid_sea")
	var mid_lower := _project_y_for(root, renderer, lower_flight, bottom_camera, start_pos.x + 6200.0, mid_world_y, 0.42, "mid", "mid_sea")
	var far_higher := _project_y_for(root, renderer, higher_flight, bottom_camera, start_pos.x + 6200.0, far_world_y, 0.20, "far", "horizon")
	var far_lower := _project_y_for(root, renderer, lower_flight, bottom_camera, start_pos.x + 6200.0, far_world_y, 0.20, "far", "horizon")
	var near_delta := absf(near_lower - near_higher)
	var mid_delta := absf(mid_lower - mid_higher)
	var far_delta := absf(far_lower - far_higher)
	_expect_less("bottom_boundary_near_moves_up_when_player_descends", near_lower, near_higher)
	_expect_close("bottom_boundary_mid_uses_same_grounded_y_speed", mid_delta, near_delta)
	_expect_close("bottom_boundary_far_uses_same_grounded_y_speed", far_delta, near_delta)


func _expect_scenic_y_linear_velocity_contract(root: Node, renderer: Node, start_pos: Vector2) -> void:
	var flight_start_pos: Vector2 = renderer.get("flight_start_pos")
	var world_x := flight_start_pos.x + 6200.0
	_expect_scenic_y_uniform_steps(root, renderer, "near_scenic_y_uniform", start_pos, world_x, flight_start_pos.y + 3600.0, 0.82, "near", "near_sea")
	_expect_scenic_y_uniform_steps(root, renderer, "mid_scenic_y_uniform", start_pos, world_x, flight_start_pos.y + 3600.0, 0.42, "mid", "mid_sea")
	_expect_scenic_y_uniform_steps(root, renderer, "far_scenic_y_uniform", start_pos, world_x, flight_start_pos.y + 3600.0, 0.20, "far", "horizon")
	var near_base := _project_y_for_zoom(root, renderer, start_pos, start_pos, world_x, flight_start_pos.y + 3600.0, 0.82, "near", "near_sea", 1.12)
	var near_up := _project_y_for_zoom(root, renderer, start_pos + Vector2(0.0, -1000.0), start_pos + Vector2(0.0, -1000.0), world_x, flight_start_pos.y + 3600.0, 0.82, "near", "near_sea", 1.12)
	var near_down := _project_y_for_zoom(root, renderer, start_pos + Vector2(0.0, 1000.0), start_pos + Vector2(0.0, 1000.0), world_x, flight_start_pos.y + 3600.0, 0.82, "near", "near_sea", 1.12)
	_expect_greater("near_moves_down_when_player_flies_up", near_up, near_base)
	_expect_less("near_moves_up_when_player_flies_down", near_down, near_base)
	_expect_scenic_y_cross_layer_velocity_contract(root, renderer, start_pos)


func _expect_scenic_y_uniform_steps(root: Node, renderer: Node, label: String, start_pos: Vector2, world_x: float, world_y: float, depth: float, layer: String, band: String) -> void:
	var camera_offset := Vector2(0.0, -110.0)
	var values := []
	for offset in [-2000.0, -1000.0, 0.0, 1000.0, 2000.0]:
		var flight_position := start_pos + Vector2(0.0, float(offset))
		values.append(_project_y_for_zoom(root, renderer, flight_position, flight_position + camera_offset, world_x, world_y, depth, layer, band, 1.12))
	_expect_equal_steps(label, values)


func _expect_equal_steps(label: String, values: Array) -> void:
	if values.size() < 3:
		return
	var expected := float(values[1]) - float(values[0])
	for i in range(2, values.size()):
		var actual := float(values[i]) - float(values[i - 1])
		_expect_close("%s_step_%d" % [label, i], actual, expected)


func _expect_scenic_y_cross_layer_velocity_contract(root: Node, renderer: Node, start_pos: Vector2) -> void:
	var flight_start_pos: Vector2 = renderer.get("flight_start_pos")
	var world_x := flight_start_pos.x + 6200.0
	var world_y := flight_start_pos.y + 3600.0
	var high_flight := start_pos + Vector2(0.0, -1400.0)
	var low_flight := start_pos + Vector2(0.0, 700.0)
	var near_high := _project_y_for_zoom(root, renderer, high_flight, high_flight + Vector2(0.0, -90.0), world_x, world_y, 0.82, "near", "near_sea", 1.12)
	var near_low := _project_y_for_zoom(root, renderer, low_flight, low_flight + Vector2(0.0, 90.0), world_x, world_y, 0.82, "near", "near_sea", 1.12)
	var mid_high := _project_y_for_zoom(root, renderer, high_flight, high_flight + Vector2(0.0, -90.0), world_x, world_y, 0.42, "mid", "mid_sea", 1.12)
	var mid_low := _project_y_for_zoom(root, renderer, low_flight, low_flight + Vector2(0.0, 90.0), world_x, world_y, 0.42, "mid", "mid_sea", 1.12)
	var far_high := _project_y_for_zoom(root, renderer, high_flight, high_flight + Vector2(0.0, -90.0), world_x, world_y, 0.20, "far", "horizon", 1.12)
	var far_low := _project_y_for_zoom(root, renderer, low_flight, low_flight + Vector2(0.0, 90.0), world_x, world_y, 0.20, "far", "horizon", 1.12)
	var near_delta := near_low - near_high
	var mid_delta := mid_low - mid_high
	var far_delta := far_low - far_high
	_expect_close("scenic_y_delta_mid_matches_near", mid_delta, near_delta)
	_expect_close("scenic_y_delta_far_matches_near", far_delta, near_delta)


func _expect_scenic_y_ignores_vertical_camera_framing(root: Node, renderer: Node, start_pos: Vector2) -> void:
	var flight_start_pos: Vector2 = renderer.get("flight_start_pos")
	var world_x := flight_start_pos.x + 6200.0
	var near_high_camera := _project_y_for_zoom(root, renderer, start_pos, start_pos + Vector2(0.0, -110.0), world_x, flight_start_pos.y + 3600.0, 0.82, "near", "near_sea", 1.12)
	var near_low_camera := _project_y_for_zoom(root, renderer, start_pos, start_pos + Vector2(0.0, 110.0), world_x, flight_start_pos.y + 3600.0, 0.82, "near", "near_sea", 1.12)
	var mid_high_camera := _project_y_for_zoom(root, renderer, start_pos, start_pos + Vector2(0.0, -110.0), world_x, flight_start_pos.y + 3600.0, 0.42, "mid", "mid_sea", 1.12)
	var mid_low_camera := _project_y_for_zoom(root, renderer, start_pos, start_pos + Vector2(0.0, 110.0), world_x, flight_start_pos.y + 3600.0, 0.42, "mid", "mid_sea", 1.12)
	var far_high_camera := _project_y_for_zoom(root, renderer, start_pos, start_pos + Vector2(0.0, -110.0), world_x, flight_start_pos.y + 3600.0, 0.20, "far", "horizon", 1.12)
	var far_low_camera := _project_y_for_zoom(root, renderer, start_pos, start_pos + Vector2(0.0, 110.0), world_x, flight_start_pos.y + 3600.0, 0.20, "far", "horizon", 1.12)
	_expect_close("near_ignores_vertical_camera_framing", near_high_camera, near_low_camera)
	_expect_close("mid_ignores_vertical_camera_framing", mid_high_camera, mid_low_camera)
	_expect_close("far_ignores_vertical_camera_framing", far_high_camera, far_low_camera)


func _expect_scenic_visible_bounds_linear_contract(root: Node, renderer: Node, start_pos: Vector2) -> void:
	var islands: Array = renderer.get("scenic_islands")
	var offsets := [-5000.0, -4000.0, -3000.0, -2000.0, -1000.0, 0.0, 1000.0, 2000.0, 3000.0, 4000.0, 5000.0]
	for island_index in range(islands.size()):
		var raw_island: Variant = islands[island_index]
		if typeof(raw_island) != TYPE_DICTIONARY:
			continue
		var island: Dictionary = raw_island
		var top_values := []
		var bottom_values := []
		for raw_offset in offsets:
			var offset := float(raw_offset)
			_sync_renderer_for_projection(root, renderer, start_pos + Vector2(0.0, offset), start_pos + Vector2(0.0, offset), 1.12)
			var bounds: Rect2 = renderer.call("get_scenic_island_projected_bounds", island)
			top_values.append(bounds.position.y)
			bottom_values.append(bounds.end.y)
		_expect_bounds_equal_steps("scenic_bounds_top_linear_%02d" % island_index, top_values)
		_expect_bounds_equal_steps("scenic_bounds_bottom_linear_%02d" % island_index, bottom_values)


func _expect_bounds_equal_steps(label: String, values: Array) -> void:
	if values.size() < 3:
		return
	var expected := float(values[1]) - float(values[0])
	for i in range(2, values.size()):
		var actual := float(values[i]) - float(values[i - 1])
		_expect_bounds_close("%s_step_%d" % [label, i], actual, expected)


func _expect_scenic_bounds_visibility_contract(root: Node, renderer: Node, start_pos: Vector2) -> void:
	var flight_start_pos: Vector2 = renderer.get("flight_start_pos")
	_sync_renderer_for_projection(root, renderer, start_pos, start_pos, 1.12)
	var horizon := float(renderer.call("get_horizon_y"))
	var guarded_island := {
		"x": flight_start_pos.x + 1600.0,
		"y": -3600.0,
		"layer": "far",
		"band": "horizon",
		"depth": 0.20,
		"width": 360.0,
		"length": 0.090,
		"height": 24.0,
		"kind": 1,
		"landmark": -1,
	}
	var guarded_center: Vector2 = renderer.call("project_scenic_point", guarded_island["x"], flight_start_pos.y + guarded_island["y"], guarded_island["depth"], guarded_island["layer"], guarded_island["band"])
	var guarded_bounds: Rect2 = renderer.call("get_scenic_island_projected_bounds", guarded_island)
	var guarded_alpha := float(renderer.call("get_scenic_island_visibility_alpha", guarded_island))
	_expect_less("guarded_center_would_have_failed_old_center_cull", guarded_center.y, horizon - 80.0)
	_expect_less("guarded_bounds_not_pinned_to_horizon", guarded_bounds.end.y, horizon)
	_expect_greater("guarded_alpha_ignores_horizon", guarded_alpha, 0.999)

	var view_size: Vector2 = renderer.get("view_size")
	var found_edge_fade := false
	for y_offset in range(0, 18000, 250):
		var edge_island := {
			"x": flight_start_pos.x + 1800.0,
			"y": float(y_offset),
			"layer": "near",
			"band": "near_sea",
			"depth": 0.84,
			"width": 720.0,
			"length": 0.210,
			"height": 76.0,
			"kind": 0,
			"landmark": -1,
		}
		var bounds: Rect2 = renderer.call("get_scenic_island_projected_bounds", edge_island)
		var alpha := float(renderer.call("get_scenic_island_visibility_alpha", edge_island))
		if alpha > 0.001 and alpha < 0.999 and bounds.end.y > view_size.y and bounds.position.y < view_size.y + 160.0:
			found_edge_fade = true
			break
	_expect_true("scenic_island_fades_at_screen_edge_before_cull", found_edge_fade)


func _expect_scenic_profile_bottom_layout_contract(root: Node, renderer: Node, start_pos: Vector2) -> void:
	var flight_start_pos: Vector2 = renderer.get("flight_start_pos")
	var play_rect: Rect2 = renderer.get("play_rect")
	var bottom_flight := Vector2(start_pos.x, play_rect.end.y)
	var bottom_camera: Vector2 = root.call("_clamp_camera_center", bottom_flight)
	_sync_renderer_for_projection(root, renderer, bottom_flight, bottom_camera, 1.12)
	var horizon := float(renderer.call("get_horizon_y"))
	var islands: Array = renderer.get("scenic_islands")
	var visible_count := 0
	for island_index in range(islands.size()):
		var raw_island: Variant = islands[island_index]
		if typeof(raw_island) != TYPE_DICTIONARY:
			continue
		var island: Dictionary = raw_island
		var bounds: Rect2 = renderer.call("get_scenic_island_projected_bounds", island)
		var alpha := float(renderer.call("get_scenic_island_visibility_alpha", island))
		if alpha <= 0.05:
			continue
		visible_count += 1
		var center: Vector2 = renderer.call("project_scenic_point", island["x"], flight_start_pos.y + island["y"], island["depth"], island["layer"], island["band"])
		_expect_greater("bottom_profile_visible_center_below_horizon_%02d" % island_index, center.y, horizon + 18.0)
		_expect_greater("bottom_profile_visible_bounds_below_horizon_%02d" % island_index, bounds.end.y, horizon + 8.0)
	_expect_greater("bottom_profile_keeps_visible_scenic_reference", float(visible_count), 0.0)


func _sync_renderer_for_projection(root: Node, renderer: Node, flight_position: Vector2, camera_position: Vector2, zoom: float) -> void:
	root.set("flight_pos", flight_position)
	root.set("visual_pos", flight_position)
	root.set("camera_center", camera_position)
	root.set("camera_zoom", zoom)
	root.set("camera_look_ahead", Vector2.ZERO)
	root.set("velocity", Vector2.ZERO)
	root.set("throttle_energy", 0.0)
	root.set("boost_energy", 0.0)
	root.call("_sync_level_background_renderer")


func _project_y_for(root: Node, renderer: Node, flight_position: Vector2, camera_position: Vector2, world_x: float, world_y: float, depth: float, layer: String, band: String) -> float:
	return _project_y_for_zoom(root, renderer, flight_position, camera_position, world_x, world_y, depth, layer, band, 1.30)


func _project_y_for_zoom(root: Node, renderer: Node, flight_position: Vector2, camera_position: Vector2, world_x: float, world_y: float, depth: float, layer: String, band: String, zoom: float) -> float:
	_sync_renderer_for_projection(root, renderer, flight_position, camera_position, zoom)
	var projected: Vector2 = renderer.call("project_scenic_point", world_x, world_y, depth, layer, band)
	return projected.y


func _fail(message: String) -> void:
	had_failure = true
	push_error(message)
