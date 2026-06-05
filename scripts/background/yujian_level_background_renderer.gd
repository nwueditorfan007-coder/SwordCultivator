extends Node2D

const DEFAULT_PROFILE_PATH := "res://resources/flight/background/level_01_immortal_sea_background.json"
const BOUNDARY_CLOUD_WALL_TEXTURE_PATH := "res://resources/flight/background/yujian_cloudsea_v1/boundary_cloud_wall_01.png"
const BOUNDARY_RUNE_STRIP_TEXTURE_PATH := "res://resources/flight/background/yujian_cloudsea_v1/boundary_rune_strip_01.png"

const SCENE_BACKGROUND_BOUNDARY_SCREEN_RANGE := 260.0
const SCENE_BACKGROUND_BOUNDARY_ALPHA := 0.30
const SCENE_BACKGROUND_RUNE_ALPHA := 0.18
const SCENE_BACKGROUND_SPEED_MIN := 0.36
const CRUISE_SPEED := 390.0 * 3.0
const BOOST_SPEED := 760.0 * 3.0
const SCENIC_ISLAND_CULL_MARGIN := 160.0
const SCENIC_ISLAND_EDGE_FADE_RANGE := 128.0

var view_size := Vector2(1280.0, 720.0)
var play_rect := Rect2(Vector2(92.0, 86.0), Vector2(1096.0 * 80.0, 548.0 * 48.0))
var flight_start_pos := Vector2.ZERO
var fixed_background_zoom := 1.12

var enabled := true
var profile_path := DEFAULT_PROFILE_PATH
var show_debug_guides := false

var flight_pos := Vector2.ZERO
var camera_center := Vector2.ZERO
var camera_zoom := 1.12
var velocity := Vector2.ZERO
var throttle_energy := 0.0
var carve_energy := 0.0
var direction_switch_energy := 0.0
var elapsed_time := 0.0

var profile: Dictionary = {}
var far_island_bands: Array = []
var scenic_islands: Array = []

var far_strength := 1.0
var mid_strength := 1.0
var near_strength := 0.85
var island_color_strength := 1.08
var vertical_exit_strength := 0.92
var far_scenic_y_parallax := 0.05
var mid_scenic_y_parallax := 0.5
var near_scenic_y_parallax := 1
var turn_background_keep_ratio := 0.72
var island_speed_keep_ratio := 0.70
var sea_speed_keep_ratio := 0.82
var shimmer_speed_keep_ratio := 0.30

var sky_top_color := Color(0.36, 0.66, 0.90, 1.0)
var sky_mid_color := Color(0.68, 0.86, 0.94, 1.0)
var sky_bottom_color := Color(0.95, 0.98, 0.92, 1.0)
var sky_warm_haze := 0.12
var sky_low_cyan_haze := 0.045

var horizon_ratio := 0.545
var horizon_y_response := 0.016
var horizon_high_exit_ratio := 1.40
var horizon_low_visible_ratio := 0.43
var horizon_glow_color := Color(0.72, 0.92, 1.0, 1.0)
var horizon_glow_strength := 0.14
var horizon_glow_width := 56.0
var sea_base_color := Color(0.03, 0.38, 0.82, 1.0)
var sea_base_alpha := 0.72

var boundary_cloud_wall_texture: Texture2D
var boundary_rune_strip_texture: Texture2D


func _ready() -> void:
	_load_textures()
	load_profile(profile_path)


func configure_world(new_view_size: Vector2, new_play_rect: Rect2, new_flight_start_pos: Vector2, new_fixed_background_zoom: float) -> void:
	view_size = new_view_size
	play_rect = new_play_rect
	flight_start_pos = new_flight_start_pos
	fixed_background_zoom = maxf(new_fixed_background_zoom, 0.001)
	if flight_pos == Vector2.ZERO:
		flight_pos = flight_start_pos
	if camera_center == Vector2.ZERO:
		camera_center = flight_start_pos
	queue_redraw()


func set_profile_path(new_profile_path: String) -> void:
	profile_path = new_profile_path if not new_profile_path.is_empty() else DEFAULT_PROFILE_PATH
	load_profile(profile_path)


func set_world_state(
	new_elapsed_time: float,
	new_flight_pos: Vector2,
	new_camera_center: Vector2,
	new_camera_zoom: float,
	new_velocity: Vector2,
	new_throttle_energy: float,
	new_carve_energy: float,
	new_direction_switch_energy: float,
	new_show_debug_guides: bool
) -> void:
	elapsed_time = new_elapsed_time
	flight_pos = new_flight_pos
	camera_center = new_camera_center
	camera_zoom = maxf(new_camera_zoom, 0.001)
	velocity = new_velocity
	throttle_energy = clampf(new_throttle_energy, 0.0, 1.0)
	carve_energy = clampf(new_carve_energy, 0.0, 1.0)
	direction_switch_energy = clampf(new_direction_switch_energy, 0.0, 1.0)
	show_debug_guides = new_show_debug_guides
	queue_redraw()


func load_profile(path: String) -> bool:
	profile = {}
	far_island_bands = []
	scenic_islands = []
	profile_path = path if not path.is_empty() else DEFAULT_PROFILE_PATH
	if not FileAccess.file_exists(profile_path):
		push_warning("Missing yujian level background profile: %s" % profile_path)
		queue_redraw()
		return false
	var file := FileAccess.open(profile_path, FileAccess.READ)
	if file == null:
		push_warning("Failed to open yujian level background profile: %s" % profile_path)
		queue_redraw()
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Invalid yujian level background profile JSON: %s" % profile_path)
		queue_redraw()
		return false
	profile = parsed
	var raw_settings: Variant = profile.get("settings", {})
	if typeof(raw_settings) == TYPE_DICTIONARY:
		_apply_profile_settings(raw_settings)
	far_island_bands = _profile_array("far_island_bands")
	scenic_islands = _profile_array("scenic_islands")
	queue_redraw()
	return true


func get_horizon_y() -> float:
	var base_horizon_y := view_size.y * horizon_ratio
	var altitude := flight_start_pos.y - flight_pos.y
	var horizon_y := base_horizon_y + altitude * horizon_y_response
	var play_bottom_horizon_y := base_horizon_y + (flight_start_pos.y - play_rect.end.y) * horizon_y_response
	var play_top_horizon_y := base_horizon_y + (flight_start_pos.y - play_rect.position.y) * horizon_y_response
	var low_altitude_limit := minf(view_size.y * horizon_low_visible_ratio, play_bottom_horizon_y)
	var high_altitude_limit := maxf(view_size.y * horizon_high_exit_ratio, play_top_horizon_y)
	return clampf(horizon_y, low_altitude_limit, high_altitude_limit)


func get_horizon_y_response() -> float:
	return horizon_y_response


func get_scenic_anchor_parallax_y(layer: String, depth: float) -> float:
	return _scenic_anchor_parallax_y(layer, depth)


func background_screen_x(world_x: float, depth: float) -> float:
	return view_size.x * 0.5 + (world_x - camera_center.x) * depth / _background_zoom()


func project_scenic_point(world_x: float, world_y: float, depth: float, layer: String, band: String) -> Vector2:
	return _project_scenic_point(world_x, world_y, depth, layer, band, get_horizon_y())


func get_scenic_island_projected_bounds(island: Dictionary) -> Rect2:
	var projection := _build_projected_scenic_island(island, get_horizon_y())
	if projection.is_empty():
		return Rect2()
	return projection["bounds"]


func get_scenic_island_visibility_alpha(island: Dictionary) -> float:
	var projection := _build_projected_scenic_island(island, get_horizon_y())
	if projection.is_empty():
		return 0.0
	var bounds: Rect2 = projection["bounds"]
	if _rect_outside_screen(bounds, SCENIC_ISLAND_CULL_MARGIN):
		return 0.0
	return _screen_bounds_visibility_fade(bounds)


func _draw() -> void:
	if not enabled:
		return
	var speed_pressure := _background_speed_pressure()
	var turn_pressure := clampf(maxf(carve_energy, direction_switch_energy), 0.0, 1.0)
	var readability_fade := lerpf(1.0, turn_background_keep_ratio, turn_pressure)
	var grounded_plane_fade := readability_fade * lerpf(1.0, island_speed_keep_ratio, speed_pressure)
	_draw_sky_wash(readability_fade)
	_draw_far_clouds(readability_fade)
	_draw_sea_plane(speed_pressure, readability_fade)
	_draw_far_island_bands(readability_fade)
	_draw_sea_shimmer(speed_pressure, grounded_plane_fade)
	_draw_perspective_islands(grounded_plane_fade)
	_draw_near_speed_references(speed_pressure)
	_draw_battlefield_boundary_layers()
	if show_debug_guides:
		_draw_world_guides()


func _load_textures() -> void:
	boundary_cloud_wall_texture = _load_png_texture(BOUNDARY_CLOUD_WALL_TEXTURE_PATH)
	boundary_rune_strip_texture = _load_png_texture(BOUNDARY_RUNE_STRIP_TEXTURE_PATH)


func _load_png_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_warning("Missing background texture: %s" % path)
		return null
	return load(path) as Texture2D


func _apply_profile_settings(settings: Dictionary) -> void:
	far_strength = _profile_float(settings, "far_strength", far_strength)
	mid_strength = _profile_float(settings, "mid_strength", mid_strength)
	near_strength = _profile_float(settings, "near_strength", near_strength)
	island_color_strength = _profile_float(settings, "island_color_strength", island_color_strength)
	vertical_exit_strength = _profile_float(settings, "vertical_exit_strength", vertical_exit_strength)
	far_scenic_y_parallax = _profile_float(settings, "far_scenic_y_parallax", far_scenic_y_parallax)
	mid_scenic_y_parallax = _profile_float(settings, "mid_scenic_y_parallax", mid_scenic_y_parallax)
	near_scenic_y_parallax = _profile_float(settings, "near_scenic_y_parallax", near_scenic_y_parallax)
	turn_background_keep_ratio = _profile_float(settings, "turn_background_keep_ratio", turn_background_keep_ratio)
	island_speed_keep_ratio = _profile_float(settings, "island_speed_keep_ratio", island_speed_keep_ratio)
	sea_speed_keep_ratio = _profile_float(settings, "sea_speed_keep_ratio", sea_speed_keep_ratio)
	shimmer_speed_keep_ratio = _profile_float(settings, "shimmer_speed_keep", shimmer_speed_keep_ratio)
	sky_top_color = _profile_color(settings, "sky_top_color", sky_top_color)
	sky_mid_color = _profile_color(settings, "sky_mid_color", sky_mid_color)
	sky_bottom_color = _profile_color(settings, "sky_bottom_color", sky_bottom_color)
	sky_warm_haze = _profile_float(settings, "sky_warm_haze", sky_warm_haze)
	sky_low_cyan_haze = _profile_float(settings, "sky_low_cyan_haze", sky_low_cyan_haze)
	horizon_ratio = _profile_float(settings, "horizon_ratio", horizon_ratio)
	horizon_y_response = _profile_float(settings, "horizon_y_response", horizon_y_response)
	horizon_high_exit_ratio = _profile_float(settings, "horizon_high_exit_ratio", _profile_float(settings, "horizon_top_limit_ratio", horizon_high_exit_ratio))
	horizon_low_visible_ratio = _profile_float(settings, "horizon_low_visible_ratio", horizon_low_visible_ratio)
	horizon_glow_color = _profile_color(settings, "horizon_glow_color", horizon_glow_color)
	horizon_glow_strength = _profile_float(settings, "horizon_glow_strength", horizon_glow_strength)
	horizon_glow_width = _profile_float(settings, "horizon_glow_width", horizon_glow_width)
	sea_base_color = _profile_color(settings, "sea_base_color", sea_base_color)
	sea_base_alpha = _profile_float(settings, "sea_base_alpha", sea_base_alpha)


func _profile_array(key: String) -> Array:
	var raw_value: Variant = profile.get(key, [])
	if typeof(raw_value) != TYPE_ARRAY:
		push_warning("Yujian level background profile field is not an array: %s" % key)
		return []
	var result: Array = raw_value
	return result.duplicate(true)


func _profile_float(settings: Dictionary, key: String, fallback: float) -> float:
	if not settings.has(key):
		return fallback
	return float(settings[key])


func _profile_color(settings: Dictionary, key: String, fallback: Color) -> Color:
	if not settings.has(key):
		return fallback
	return _profile_color_from_value(settings[key], fallback)


func _profile_color_from_value(value: Variant, fallback: Color) -> Color:
	if typeof(value) != TYPE_ARRAY:
		return fallback
	var parts: Array = value
	if parts.size() < 3:
		return fallback
	var alpha := fallback.a
	if parts.size() >= 4:
		alpha = float(parts[3])
	return Color(float(parts[0]), float(parts[1]), float(parts[2]), alpha)


func _background_zoom() -> float:
	return maxf(fixed_background_zoom, 0.001)


func _background_camera_origin() -> Vector2:
	return Vector2(camera_center.x, flight_pos.y) - view_size * 0.5 * _background_zoom()


func _get_background_visible_world_rect() -> Rect2:
	var zoom := _background_zoom()
	return Rect2(_background_camera_origin(), view_size * zoom).intersection(play_rect)


func _world_to_screen(world_pos: Vector2) -> Vector2:
	return (world_pos - camera_center) / maxf(camera_zoom, 0.001) + view_size * 0.5


func _get_visible_world_rect() -> Rect2:
	return Rect2(camera_center - view_size * 0.5 * camera_zoom, view_size * camera_zoom).intersection(play_rect)


func _background_speed_pressure() -> float:
	var min_speed := CRUISE_SPEED * SCENE_BACKGROUND_SPEED_MIN
	return clampf((velocity.length() - min_speed) / maxf(BOOST_SPEED - min_speed, 1.0), 0.0, 1.0)


func _draw_sky_wash(readability_fade: float) -> void:
	_draw_smooth_sky_gradient(sky_top_color, sky_mid_color, sky_bottom_color)
	_draw_soft_sky_haze(0.42, 0.26, Color(1.0, 0.96, 0.76, sky_warm_haze * 0.78 * readability_fade))
	_draw_soft_sky_haze(0.70, 0.28, Color(0.72, 0.93, 1.0, sky_low_cyan_haze * 1.35 * readability_fade))
	for i in range(18):
		var t := float(i) / 17.0
		var radius := lerpf(42.0, 220.0, t)
		var alpha := 0.016 * readability_fade * pow(1.0 - t, 1.9)
		draw_circle(Vector2(view_size.x * 0.17, view_size.y * 0.20), radius, Color(1.0, 0.88, 0.50, alpha))


func _draw_sea_plane(speed_pressure: float, readability_fade: float) -> void:
	var horizon_y := get_horizon_y()
	var bottom_y := view_size.y + 2.0
	var height := maxf(bottom_y - horizon_y, 1.0)
	var alpha_scale := readability_fade * lerpf(1.0, sea_speed_keep_ratio, speed_pressure)
	var mid_y := horizon_y + height * 0.44
	var top_color := Color(0.38, 0.80, 0.98, 0.72 * alpha_scale)
	var mid_color := Color(0.13, 0.58, 0.90, 0.80 * alpha_scale)
	var bottom_color := Color(sea_base_color.r, sea_base_color.g, sea_base_color.b, sea_base_alpha * alpha_scale * sea_base_color.a)
	_draw_vertical_gradient_rect(Rect2(Vector2(0.0, horizon_y), Vector2(view_size.x, mid_y - horizon_y)), top_color, mid_color)
	_draw_vertical_gradient_rect(Rect2(Vector2(0.0, mid_y), Vector2(view_size.x, bottom_y - mid_y)), mid_color, bottom_color)
	_draw_soft_horizon_glow(horizon_y, alpha_scale)


func _draw_far_clouds(readability_fade: float) -> void:
	if far_strength <= 0.001:
		return
	_draw_cloud_layer(0.055, 2350.0, 0.25, 0.016 * far_strength * readability_fade, 0.62)
	_draw_cloud_layer(0.085, 1850.0, 0.43, 0.022 * far_strength * readability_fade, 0.78)


func _draw_cloud_layer(depth: float, spacing_world: float, y_ratio: float, alpha: float, scale_base: float) -> void:
	var visible_rect := _get_background_visible_world_rect()
	if not visible_rect.has_area():
		return
	var start_index := int(floorf(visible_rect.position.x / spacing_world)) - 3
	var end_index := int(ceilf(visible_rect.end.x / spacing_world)) + 3
	for index in range(start_index, end_index + 1):
		var seed := float(index) * 23.17 + depth * 19.0
		var world_x := float(index) * spacing_world + lerpf(-420.0, 420.0, _hash01(seed + 1.0))
		var screen_x := background_screen_x(world_x, depth)
		if screen_x < -520.0 or screen_x > view_size.x + 520.0:
			continue
		var screen_y := view_size.y * y_ratio + lerpf(-26.0, 24.0, _hash01(seed + 2.0))
		var scale := scale_base * lerpf(0.82, 1.22, _hash01(seed + 3.0))
		_draw_cloud_bank(Vector2(screen_x, screen_y), scale, alpha * lerpf(0.68, 1.0, _hash01(seed + 4.0)), seed)


func _draw_cloud_bank(center: Vector2, scale: float, alpha: float, seed: float) -> void:
	if alpha <= 0.001:
		return
	var color := Color(0.96, 0.99, 1.0, alpha)
	for i in range(7):
		var offset_x := lerpf(-170.0, 170.0, float(i) / 6.0) * scale
		var offset_y := sin(seed + float(i) * 1.7) * 9.0 * scale
		var radius := lerpf(34.0, 78.0, _hash01(seed + float(i) * 5.2)) * scale
		draw_circle(center + Vector2(offset_x, offset_y), radius, color)
	draw_line(center + Vector2(-210.0, 22.0) * scale, center + Vector2(210.0, 21.0) * scale, Color(0.82, 0.93, 0.98, alpha * 0.64), 18.0 * scale, true)


func _draw_perspective_islands(grounded_plane_fade: float) -> void:
	if mid_strength <= 0.001 or grounded_plane_fade <= 0.001:
		return
	var horizon_y := get_horizon_y()
	var contrast := clampf(mid_strength * lerpf(0.84, 1.0, grounded_plane_fade), 0.0, 1.0)
	for island in scenic_islands:
		if typeof(island) != TYPE_DICTIONARY:
			continue
		_draw_perspective_island(island, horizon_y, contrast)


func _draw_perspective_island(island: Dictionary, horizon_y: float, contrast: float) -> void:
	var projection := _build_projected_scenic_island(island, horizon_y)
	if projection.is_empty():
		return
	var bounds: Rect2 = projection["bounds"]
	if _rect_outside_screen(bounds, SCENIC_ISLAND_CULL_MARGIN):
		return
	var visibility_fade := _screen_bounds_visibility_fade(bounds)
	if visibility_fade <= 0.001:
		return
	var center_x: float = projection["center_x"]
	var center_y: float = projection["center_y"]
	var center_z: float = projection["center_z"]
	var layer: String = projection["layer"]
	var band: String = projection["band"]
	var width_world: float = projection["width_world"]
	var length_z: float = projection["length_z"]
	var kind: int = projection["kind"]
	var scale: float = projection["scale"]
	var top_outline: PackedVector2Array = projection["top_outline"]
	var visible_edge: PackedVector2Array = projection["visible_edge"]
	var lower_edge: PackedVector2Array = projection["lower_edge"]
	var air_mix := clampf((1.0 - center_z) * 0.42 + (1.0 - contrast) * 0.20, 0.0, 0.55)
	var air_color := Color(0.62, 0.82, 0.84, 1.0)
	var top_color := _island_top_color(kind).lerp(air_color, air_mix)
	var cliff_color := _island_cliff_color(kind).lerp(air_color, air_mix * 0.76)
	var cliff_dark := Color(0.32, 0.27, 0.20, 1.0).lerp(air_color, air_mix * 0.62)

	_draw_perspective_island_shadow(visible_edge, lower_edge, center_z, visibility_fade)
	_draw_perspective_cliff_faces(visible_edge, lower_edge, cliff_color, cliff_dark, center_z, air_mix, visibility_fade)
	draw_colored_polygon(top_outline, _fade_color(top_color, visibility_fade))
	_draw_perspective_island_top_details(center_x, center_y, center_z, width_world, length_z, horizon_y, top_outline, kind, center_z, air_mix, layer, band, visibility_fade)
	_draw_perspective_island_rims(top_outline, visible_edge, lower_edge, center_z, air_mix, visibility_fade)
	_draw_perspective_vegetation(center_x, center_y, center_z, width_world, length_z, horizon_y, center_z, kind, layer, band, visibility_fade)
	var landmark := int(island.get("landmark", -1))
	if landmark >= 0:
		var landmark_anchor: Vector2 = projection["landmark_anchor"]
		_draw_perspective_landmark(landmark, landmark_anchor, scale * lerpf(0.58, 0.94, center_z), air_mix, visibility_fade)


func _build_projected_scenic_island(island: Dictionary, horizon_y: float) -> Dictionary:
	var center_x := float(island.get("x", flight_start_pos.x))
	var center_y := flight_start_pos.y + float(island.get("y", 0.0))
	var layer := String(island.get("layer", "mid"))
	var band := String(island.get("band", "mid_sea"))
	var center_z := clampf(float(island.get("depth", island.get("z", 0.5))), 0.06, 0.96)
	var width_world := float(island.get("width", 420.0))
	var length_z := clampf(float(island.get("length", 0.14)), 0.035, 0.28)
	var kind := int(island.get("kind", 0))
	var scale := _scenic_screen_scale(center_z, layer) / _background_zoom()
	var cliff_height := float(island.get("height", 48.0)) * scale
	var top_outline := _perspective_island_outline(center_x, center_y, center_z, width_world, length_z, horizon_y, kind, layer, band)
	if top_outline.size() < 3:
		return {}
	var visible_edge := _perspective_island_visible_edge(top_outline)
	var lower_edge := _perspective_island_lower_edge(visible_edge, width_world, scale, cliff_height, center_z, center_x * 0.011 + float(kind) * 23.0)
	var silhouette_bounds := _bounds_from_point_groups([top_outline, visible_edge, lower_edge])
	var bounds := silhouette_bounds
	var landmark_anchor := Vector2.ZERO
	var landmark := int(island.get("landmark", -1))
	if landmark >= 0:
		landmark_anchor = _project_island_local_point(center_x, center_y, center_z, width_world, length_z, 0.52, 0.54, horizon_y, layer, band)
		var landmark_scale := scale * lerpf(0.58, 0.94, center_z)
		bounds = _merge_rects(bounds, _landmark_projected_bounds(landmark_anchor, landmark_scale))
	var draw_padding := maxf(28.0, cliff_height * 0.35 + width_world * scale * 0.05)
	bounds = _expand_rect(bounds, draw_padding)
	return {
		"center_x": center_x,
		"center_y": center_y,
		"center_z": center_z,
		"layer": layer,
		"band": band,
		"width_world": width_world,
		"length_z": length_z,
		"kind": kind,
		"scale": scale,
		"top_outline": top_outline,
		"visible_edge": visible_edge,
		"lower_edge": lower_edge,
		"landmark_anchor": landmark_anchor,
		"bounds": bounds,
	}


func _draw_perspective_island_shadow(visible_edge: PackedVector2Array, lower_edge: PackedVector2Array, depth: float, visibility_fade: float) -> void:
	if lower_edge.size() < 2 or visible_edge.size() < 2:
		return
	var lower_left := lower_edge[0]
	var lower_right := lower_edge[lower_edge.size() - 1]
	var front_left := visible_edge[0]
	var front_right := visible_edge[visible_edge.size() - 1]
	var shadow_alpha := lerpf(0.035, 0.115, depth)
	var offset := Vector2(0.0, lerpf(8.0, 22.0, depth))
	draw_colored_polygon(
		PackedVector2Array([
			lower_left + Vector2(-18.0, 4.0) + offset,
			lower_right + Vector2(18.0, 3.0) + offset,
			front_right + Vector2(34.0, 34.0) + offset,
			front_left + Vector2(-34.0, 36.0) + offset,
		]),
		Color(0.02, 0.20, 0.28, shadow_alpha * visibility_fade)
	)


func _draw_perspective_cliff_faces(visible_edge: PackedVector2Array, lower_edge: PackedVector2Array, cliff_color: Color, cliff_dark: Color, depth: float, air_mix: float, visibility_fade: float) -> void:
	var count: int = visible_edge.size()
	if lower_edge.size() < count:
		count = lower_edge.size()
	if count < 2:
		return
	for i in range(count - 1):
		var t := float(i) / maxf(float(count - 2), 1.0)
		var panel_mix := 0.06 + absf(t - 0.5) * 0.34
		var face_color := cliff_color.lerp(cliff_dark, panel_mix)
		face_color = _fade_color(face_color, visibility_fade)
		draw_colored_polygon(PackedVector2Array([
			visible_edge[i],
			visible_edge[i + 1],
			lower_edge[i + 1],
			lower_edge[i],
		]), face_color)
		var line_alpha := lerpf(0.10, 0.22, depth) * (1.0 - air_mix * 0.75) * visibility_fade
		var line_top := visible_edge[i].lerp(visible_edge[i + 1], 0.52)
		var line_bottom := lower_edge[i].lerp(lower_edge[i + 1], 0.47)
		draw_line(line_top, line_bottom, Color(0.28, 0.24, 0.18, line_alpha), maxf(1.0, lerpf(1.0, 2.0, depth)), true)
	for i in range(3):
		var t := (float(i) + 0.5) / 3.0
		var top := _polyline_lerp(visible_edge, t)
		var bottom := _polyline_lerp(lower_edge, clampf(t + lerpf(-0.06, 0.06, _hash01(depth * 23.0 + float(i))), 0.0, 1.0))
		var crease_color := Color(0.88, 0.76, 0.50, lerpf(0.09, 0.16, depth) * (1.0 - air_mix * 0.55) * visibility_fade)
		draw_line(top.lerp(bottom, 0.16), bottom.lerp(top, 0.12), crease_color, maxf(1.0, lerpf(1.0, 2.4, depth)), true)


func _perspective_island_outline(center_x: float, center_y: float, center_z: float, width: float, length_z: float, horizon_y: float, kind: int, layer: String, band: String) -> PackedVector2Array:
	var seed := center_x * 0.011 + center_y * 0.007 + float(kind) * 19.31 + width * 0.017 + length_z * 13.0
	var local_points := [
		Vector2(-0.42, 0.50 + lerpf(-0.04, 0.02, _hash01(seed + 1.0))),
		Vector2(lerpf(-0.08, 0.08, _hash01(seed + 2.0)), 0.56 + lerpf(-0.02, 0.04, _hash01(seed + 3.0))),
		Vector2(0.42, 0.50 + lerpf(-0.04, 0.02, _hash01(seed + 4.0))),
		Vector2(0.53 + lerpf(-0.03, 0.04, _hash01(seed + 5.0)), 0.08 + lerpf(-0.05, 0.04, _hash01(seed + 6.0))),
		Vector2(0.35 + lerpf(-0.04, 0.03, _hash01(seed + 7.0)), -0.42 + lerpf(-0.04, 0.02, _hash01(seed + 8.0))),
		Vector2(lerpf(-0.08, 0.08, _hash01(seed + 9.0)), -0.56 + lerpf(-0.03, 0.03, _hash01(seed + 10.0))),
		Vector2(-0.36 + lerpf(-0.03, 0.04, _hash01(seed + 11.0)), -0.42 + lerpf(-0.03, 0.04, _hash01(seed + 12.0))),
		Vector2(-0.53 + lerpf(-0.04, 0.03, _hash01(seed + 13.0)), 0.08 + lerpf(-0.04, 0.05, _hash01(seed + 14.0))),
	]
	var points := PackedVector2Array()
	for raw_local_point in local_points:
		var local_point: Vector2 = raw_local_point
		points.append(_project_island_footprint_point(center_x, center_y, center_z, width, length_z, local_point, horizon_y, layer, band))
	return points


func _perspective_island_visible_edge(top_outline: PackedVector2Array) -> PackedVector2Array:
	if top_outline.size() < 8:
		return top_outline
	return PackedVector2Array([
		top_outline[7],
		top_outline[0],
		top_outline[1],
		top_outline[2],
		top_outline[3],
	])


func _perspective_island_lower_edge(visible_edge: PackedVector2Array, width: float, scale: float, cliff_height: float, depth: float, seed: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := visible_edge.size()
	for i in range(count):
		var t := float(i) / maxf(float(count - 1), 1.0)
		var side_push := (t - 0.5) * width * scale * lerpf(0.024, 0.040, depth)
		var height_jitter := lerpf(0.88, 1.10, _hash01(seed + float(i) * 6.13))
		points.append(visible_edge[i] + Vector2(side_push, cliff_height * height_jitter))
	return points


func _draw_perspective_island_rims(top_outline: PackedVector2Array, visible_edge: PackedVector2Array, lower_edge: PackedVector2Array, depth: float, air_mix: float, visibility_fade: float) -> void:
	var shore_color := _fade_color(Color(0.92, 0.82, 0.54, 0.92).lerp(Color(0.70, 0.88, 0.86, 1.0), air_mix), visibility_fade)
	var waterline := Color(0.84, 0.97, 1.0, lerpf(0.20, 0.36, depth) * visibility_fade)
	var rim_points := PackedVector2Array(top_outline)
	rim_points.append(top_outline[0])
	draw_polyline(rim_points, shore_color, maxf(1.0, lerpf(1.5, 4.0, depth)), true)
	draw_polyline(lower_edge, waterline, maxf(3.0, lerpf(4.0, 12.0, depth)), true)
	if visible_edge.size() > 2:
		draw_polyline(visible_edge, Color(0.98, 0.87, 0.58, lerpf(0.30, 0.54, depth) * (1.0 - air_mix * 0.45) * visibility_fade), maxf(1.0, lerpf(1.0, 2.8, depth)), true)
	for i in range(3):
		var t := (float(i) + 1.0) / 4.0
		var top_a := top_outline[0].lerp(top_outline[4], t * 0.72)
		var top_b := top_outline[2].lerp(top_outline[5], minf(t * 0.72 + 0.16, 0.92))
		draw_line(top_a, top_b, Color(0.98, 0.86, 0.54, lerpf(0.22, 0.42, depth) * visibility_fade), maxf(1.0, lerpf(1.0, 2.2, depth)), true)


func _draw_perspective_island_top_details(center_x: float, center_y: float, center_z: float, width: float, length_z: float, horizon_y: float, top_outline: PackedVector2Array, kind: int, depth: float, air_mix: float, layer: String, band: String, visibility_fade: float) -> void:
	var seed := center_x * 0.017 + float(kind) * 11.0
	var center := _polygon_center(top_outline)
	var inner := _scaled_polygon(top_outline, center, lerpf(0.72, 0.84, _hash01(seed + 1.0)))
	draw_colored_polygon(inner, Color(0.86, 0.76, 0.53, lerpf(0.10, 0.18, depth) * (1.0 - air_mix * 0.60) * visibility_fade))
	for i in range(4):
		var v := lerpf(0.30, 0.72, (float(i) + 0.35) / 4.0)
		var u0 := lerpf(0.20, 0.32, _hash01(seed + float(i) * 5.0))
		var u1 := lerpf(0.66, 0.82, _hash01(seed + float(i) * 7.0))
		var mid := lerpf(0.42, 0.58, _hash01(seed + float(i) * 9.0))
		var p0 := _project_island_local_point(center_x, center_y, center_z, width, length_z, u0, v, horizon_y, layer, band)
		var p1 := _project_island_local_point(center_x, center_y, center_z, width, length_z, mid, clampf(v + 0.035, 0.08, 0.92), horizon_y, layer, band)
		var p2 := _project_island_local_point(center_x, center_y, center_z, width, length_z, u1, clampf(v + 0.015, 0.08, 0.92), horizon_y, layer, band)
		var line_color := Color(0.96, 0.84, 0.58, lerpf(0.12, 0.24, depth) * (1.0 - air_mix * 0.55) * visibility_fade)
		draw_polyline(PackedVector2Array([p0, p1, p2]), line_color, maxf(1.0, lerpf(1.0, 2.3, depth)), true)


func _draw_perspective_vegetation(center_x: float, center_y: float, center_z: float, width: float, length_z: float, horizon_y: float, depth: float, kind: int, layer: String, band: String, visibility_fade: float) -> void:
	var patch_count := 2 + (kind % 3)
	for patch_index in range(patch_count):
		var seed := float(kind * 17 + patch_index * 11)
		var u := lerpf(0.24, 0.72, _hash01(seed + 1.0))
		var v := lerpf(0.34, 0.76, _hash01(seed + 2.0))
		var patch_w := lerpf(0.12, 0.24, _hash01(seed + 3.0))
		var patch_d := lerpf(0.08, 0.16, _hash01(seed + 4.0))
		var p0 := _project_island_local_point(center_x, center_y, center_z, width, length_z, clampf(u - patch_w, 0.05, 0.95), clampf(v - patch_d, 0.05, 0.95), horizon_y, layer, band)
		var p1 := _project_island_local_point(center_x, center_y, center_z, width, length_z, clampf(u + patch_w, 0.05, 0.95), clampf(v - patch_d * 0.68, 0.05, 0.95), horizon_y, layer, band)
		var p2 := _project_island_local_point(center_x, center_y, center_z, width, length_z, clampf(u + patch_w * 0.82, 0.05, 0.95), clampf(v + patch_d, 0.05, 0.95), horizon_y, layer, band)
		var p3 := _project_island_local_point(center_x, center_y, center_z, width, length_z, clampf(u - patch_w * 0.70, 0.05, 0.95), clampf(v + patch_d * 0.82, 0.05, 0.95), horizon_y, layer, band)
		var green := Color(0.12, 0.56, 0.34, 1.0).lerp(Color(0.52, 0.72, 0.58, 1.0), (1.0 - depth) * 0.30)
		green = _fade_color(green, visibility_fade)
		draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), green)
		for blade in range(3):
			var t := (float(blade) + 0.5) / 3.0
			var a := p0.lerp(p3, t)
			var b := p1.lerp(p2, clampf(t + lerpf(-0.10, 0.10, _hash01(seed + float(blade) * 4.4)), 0.0, 1.0))
			draw_line(a, b, Color(0.50, 0.82, 0.42, 0.72 * visibility_fade), maxf(1.0, width * 0.0045), true)


func _draw_perspective_landmark(kind: int, anchor: Vector2, scale: float, air_mix: float, visibility_fade: float) -> void:
	var solid := _fade_color(Color(0.30, 0.32, 0.30, 1.0).lerp(Color(0.64, 0.78, 0.78, 1.0), air_mix), visibility_fade)
	var gold := _fade_color(Color(0.90, 0.76, 0.36, 1.0).lerp(Color(0.78, 0.86, 0.76, 1.0), air_mix * 0.60), visibility_fade)
	var h := 48.0 * scale
	var w := 14.0 * scale
	match kind % 4:
		0:
			draw_colored_polygon(PackedVector2Array([
				anchor + Vector2(-w * 0.5, 0.0),
				anchor + Vector2(w * 0.5, 0.0),
				anchor + Vector2(w * 0.36, -h),
				anchor + Vector2(-w * 0.36, -h),
			]), solid)
			draw_line(anchor + Vector2(-w, -h), anchor + Vector2(w, -h), gold, maxf(1.0, 1.6 * scale), true)
		1:
			draw_line(anchor + Vector2(-24.0, 0.0) * scale, anchor + Vector2(24.0, -5.0) * scale, solid, maxf(2.0, 3.2 * scale), true)
			draw_line(anchor, anchor + Vector2(0.0, -h), gold, maxf(1.0, 2.0 * scale), true)
			draw_circle(anchor + Vector2(0.0, -h - 4.0 * scale), 4.0 * scale, gold)
		2:
			var arch := PackedVector2Array()
			for i in range(14):
				var t := float(i) / 13.0
				var a := lerpf(PI, 0.0, t)
				arch.append(anchor + Vector2(cos(a) * 26.0, -absf(sin(a)) * 36.0) * scale)
			draw_polyline(arch, solid, maxf(1.5, 3.0 * scale), true)
		_:
			draw_line(anchor + Vector2(-20.0, -4.0) * scale, anchor + Vector2(22.0, -4.0) * scale, solid, maxf(2.0, 3.0 * scale), true)
			draw_line(anchor, anchor + Vector2(0.0, -h * 0.86), gold, maxf(1.0, 1.5 * scale), true)


func _fade_color(color: Color, alpha_scale: float) -> Color:
	var faded := color
	faded.a *= clampf(alpha_scale, 0.0, 1.0)
	return faded


func _landmark_projected_bounds(anchor: Vector2, scale: float) -> Rect2:
	var half_width := 34.0 * scale
	var height := 62.0 * scale
	return Rect2(anchor + Vector2(-half_width, -height), Vector2(half_width * 2.0, height + 12.0 * scale))


func _bounds_from_point_groups(groups: Array) -> Rect2:
	var has_point := false
	var min_point := Vector2.ZERO
	var max_point := Vector2.ZERO
	for group in groups:
		if typeof(group) == TYPE_PACKED_VECTOR2_ARRAY:
			var packed_points: PackedVector2Array = group
			for point in packed_points:
				if not has_point:
					min_point = point
					max_point = point
					has_point = true
				else:
					min_point.x = minf(min_point.x, point.x)
					min_point.y = minf(min_point.y, point.y)
					max_point.x = maxf(max_point.x, point.x)
					max_point.y = maxf(max_point.y, point.y)
		elif typeof(group) == TYPE_ARRAY:
			var array_points: Array = group
			for raw_point in array_points:
				if typeof(raw_point) != TYPE_VECTOR2:
					continue
				var point: Vector2 = raw_point
				if not has_point:
					min_point = point
					max_point = point
					has_point = true
				else:
					min_point.x = minf(min_point.x, point.x)
					min_point.y = minf(min_point.y, point.y)
					max_point.x = maxf(max_point.x, point.x)
					max_point.y = maxf(max_point.y, point.y)
	if not has_point:
		return Rect2()
	return Rect2(min_point, max_point - min_point)


func _merge_rects(a: Rect2, b: Rect2) -> Rect2:
	var min_point := Vector2(minf(a.position.x, b.position.x), minf(a.position.y, b.position.y))
	var max_point := Vector2(maxf(a.end.x, b.end.x), maxf(a.end.y, b.end.y))
	return Rect2(min_point, max_point - min_point)


func _expand_rect(rect: Rect2, padding: float) -> Rect2:
	var p := maxf(padding, 0.0)
	return Rect2(rect.position - Vector2(p, p), rect.size + Vector2(p * 2.0, p * 2.0))


func _rect_outside_screen(bounds: Rect2, margin: float) -> bool:
	return (
		bounds.end.x < -margin
		or bounds.position.x > view_size.x + margin
		or bounds.end.y < -margin
		or bounds.position.y > view_size.y + margin
	)


func _screen_bounds_visibility_fade(bounds: Rect2) -> float:
	var margin := SCENIC_ISLAND_CULL_MARGIN
	var fade_range := SCENIC_ISLAND_EDGE_FADE_RANGE
	var denominator := margin + fade_range
	var fade := 1.0
	fade = minf(fade, clampf((bounds.end.x + margin) / denominator, 0.0, 1.0))
	fade = minf(fade, clampf((view_size.x + margin - bounds.position.x) / denominator, 0.0, 1.0))
	fade = minf(fade, clampf((bounds.end.y + margin) / denominator, 0.0, 1.0))
	fade = minf(fade, clampf((view_size.y + margin - bounds.position.y) / denominator, 0.0, 1.0))
	return fade


func _project_island_local_point(center_x: float, center_y: float, center_z: float, width: float, length_z: float, u: float, v: float, horizon_y: float, layer: String, band: String) -> Vector2:
	return _project_island_footprint_point(center_x, center_y, center_z, width, length_z, Vector2(u - 0.5, v - 0.5), horizon_y, layer, band)


func _project_island_footprint_point(center_x: float, center_y: float, center_z: float, width: float, length_z: float, local_point: Vector2, horizon_y: float, layer: String, band: String) -> Vector2:
	var foreshortening := _island_depth_foreshortening(center_z)
	var side_yaw := clampf((center_x - camera_center.x) * 0.000075, -0.16, 0.16)
	var local_z := local_point.y * foreshortening
	var local_x := local_point.x + local_z * side_yaw
	var center := _project_scenic_point(center_x, center_y, center_z, layer, band, horizon_y)
	var scale := _scenic_screen_scale(center_z, layer) / _background_zoom()
	var x := center.x + local_x * width * scale
	var y := center.y + local_z * width * scale * lerpf(0.22, 0.34, center_z) + local_point.y * length_z * 260.0 * scale
	return Vector2(x, y)


func _project_scenic_point(world_x: float, world_y: float, depth: float, layer: String, band: String, horizon_y: float) -> Vector2:
	var layer_key := layer.to_lower()
	var band_key := band.to_lower()
	var x_parallax := _scenic_layer_parallax_x(layer_key, depth)
	var x := view_size.x * 0.5 + (world_x - camera_center.x) * x_parallax / _background_zoom()
	var y := horizon_y + _scenic_band_offset(band_key, depth) + _scenic_anchor_y_delta(world_y) * _scenic_anchor_parallax_y(layer_key, depth) / _background_zoom()
	return Vector2(x, y)


func _scenic_anchor_y_delta(world_y: float) -> float:
	return world_y - flight_pos.y


func _scenic_layer_parallax_x(layer: String, depth: float) -> float:
	match layer:
		"far":
			return lerpf(0.055, 0.12, clampf(depth, 0.0, 1.0))
		"near":
			return lerpf(0.46, 0.66, clampf(depth, 0.0, 1.0))
		_:
			return lerpf(0.22, 0.38, clampf(depth, 0.0, 1.0))


func _scenic_anchor_parallax_y(layer: String, _depth: float) -> float:
	var base := 0.060 * vertical_exit_strength
	match layer.to_lower():
		"far":
			return base * far_scenic_y_parallax
		"near":
			return base * near_scenic_y_parallax
		_:
			return base * mid_scenic_y_parallax


func _scenic_band_offset(band: String, depth: float) -> float:
	match band:
		"horizon":
			return 66.0 + depth * 22.0
		"near_sea":
			return 252.0 + depth * 50.0
		"foreground":
			return 284.0 + depth * 58.0
		"foreground_bottom":
			return 252.0 + depth * 50.0
		_:
			return 132.0 + depth * 44.0


func _island_depth_foreshortening(center_z: float) -> float:
	var t := clampf((center_z - 0.20) / 0.74, 0.0, 1.0)
	var eased := t * t * (3.0 - 2.0 * t)
	return lerpf(0.38, 0.70, eased)


func _scenic_screen_scale(depth: float, layer: String) -> float:
	var scale := _perspective_screen_scale(depth)
	match layer.to_lower():
		"far":
			return scale * 0.78
		"near":
			return scale * 1.05
		_:
			return scale


func _perspective_screen_scale(depth: float) -> float:
	return lerpf(0.18, 1.06, pow(clampf(depth, 0.0, 1.0), 0.82))


func _perspective_parallax(depth: float) -> float:
	return 0.62 * _perspective_screen_scale(depth)


func _project_sea_point(world_x: float, sea_z: float, horizon_y: float) -> Vector2:
	var z := clampf(sea_z, 0.02, 0.985)
	var parallax := _perspective_parallax(z)
	var x := view_size.x * 0.5 + (world_x - camera_center.x) * parallax / _background_zoom()
	var sea_height := view_size.y - horizon_y
	var y := horizon_y + sea_height * pow(z, 1.18) * 0.96
	return Vector2(x, y)


func _draw_far_island_bands(readability_fade: float) -> void:
	if far_strength <= 0.001 or far_island_bands.is_empty():
		return
	var horizon_y := get_horizon_y()
	for band in far_island_bands:
		if typeof(band) != TYPE_DICTIONARY:
			continue
		var depth := clampf(float(band.get("depth", 0.06)), 0.01, 0.20)
		var spacing_world := float(band.get("spacing_world", 2600.0))
		var y_offset := float(band.get("y_offset", 28.0))
		var height := float(band.get("height", 42.0))
		var scale_base := float(band.get("scale", 1.0))
		var color := _profile_color_from_value(band.get("color", []), Color(0.24, 0.45, 0.46, 0.08))
		color.a *= far_strength * readability_fade
		_draw_far_island_layer(depth, spacing_world, horizon_y + y_offset, height, color, scale_base, horizon_y)


func _draw_far_island_layer(depth: float, spacing_world: float, base_y: float, height: float, color: Color, scale_base: float, horizon_y: float) -> void:
	var visible_rect := _get_background_visible_world_rect()
	if not visible_rect.has_area():
		return
	var start_index := int(floorf(visible_rect.position.x / spacing_world)) - 3
	var end_index := int(ceilf(visible_rect.end.x / spacing_world)) + 3
	for index in range(start_index, end_index + 1):
		var seed := float(index) * 41.73 + depth * 31.0
		var world_x := float(index) * spacing_world + lerpf(-520.0, 520.0, _hash01(seed + 1.0))
		var screen_x := background_screen_x(world_x, depth)
		if screen_x < -520.0 or screen_x > view_size.x + 520.0:
			continue
		var width := lerpf(330.0, 780.0, _hash01(seed + 2.0)) * scale_base / _background_zoom()
		var layer_height := height * lerpf(0.72, 1.35, _hash01(seed + 3.0)) / _background_zoom()
		_draw_far_island_segment(screen_x, base_y, width, layer_height, color, seed, horizon_y)


func _draw_far_island_segment(center_x: float, base_y: float, width: float, height: float, color: Color, seed: float, horizon_y: float) -> void:
	var points := PackedVector2Array()
	points.append(Vector2(center_x - width * 0.56, base_y + height * 0.28))
	var safe_top_y := horizon_y + 10.0
	for i in range(8):
		var t := float(i) / 7.0
		var ridge := absf(sin(seed * 0.27 + float(i) * 1.13)) * 0.85 + absf(sin(seed * 0.51 + float(i) * 0.71)) * 0.35
		var y := maxf(base_y - height * lerpf(0.20, 1.0, clampf(ridge, 0.0, 1.0)), safe_top_y)
		points.append(Vector2(center_x - width * 0.5 + width * t, y))
	points.append(Vector2(center_x + width * 0.58, base_y + height * 0.30))
	draw_colored_polygon(points, color)
	draw_line(Vector2(center_x - width * 0.48, base_y + height * 0.08), Vector2(center_x + width * 0.50, base_y + height * 0.05), Color(0.92, 0.98, 1.0, color.a * 0.18), maxf(height * 0.06, 1.0), true)


func _draw_sea_shimmer(speed_pressure: float, grounded_plane_fade: float) -> void:
	if grounded_plane_fade <= 0.001:
		return
	var visible_rect := _get_background_visible_world_rect()
	if not visible_rect.has_area():
		return
	var horizon_y := get_horizon_y()
	var left_vp := Vector2(-880.0, horizon_y - 14.0)
	var right_vp := Vector2(view_size.x + 880.0, horizon_y - 14.0)
	var spacing_world := 740.0
	var start_index := int(floorf(visible_rect.position.x / spacing_world)) - 4
	var end_index := int(ceilf(visible_rect.end.x / spacing_world)) + 4
	var alpha_scale := far_strength * grounded_plane_fade * lerpf(1.0, shimmer_speed_keep_ratio, speed_pressure)
	for index in range(start_index, end_index + 1):
		var seed := float(index) * 13.37
		var world_x := float(index) * spacing_world + lerpf(-240.0, 240.0, _hash01(seed + 1.0))
		var depth := lerpf(0.18, 0.92, _hash01(seed + 2.0))
		var screen_pos := _project_sea_point(world_x, depth, horizon_y)
		if screen_pos.x < -180.0 or screen_pos.x > view_size.x + 180.0:
			continue
		if screen_pos.y < horizon_y + 24.0 or screen_pos.y > view_size.y + 40.0:
			continue
		var vp := right_vp if screen_pos.x < view_size.x * 0.5 else left_vp
		var dir := (vp - screen_pos).normalized()
		var length := lerpf(28.0, 110.0, _hash01(seed + 3.0)) * lerpf(0.55, 1.2, depth) / _background_zoom()
		var alpha := lerpf(0.010, 0.034, _hash01(seed + 4.0)) * alpha_scale
		var wave_offset := Vector2(-dir.y, dir.x) * sin(seed + elapsed_time * 0.22) * 2.0
		draw_line(screen_pos - dir * length * 0.45 + wave_offset, screen_pos + dir * length * 0.55 - wave_offset, Color(0.84, 0.98, 1.0, alpha), maxf(1.0, 1.5 / _background_zoom()), true)


func _draw_near_speed_references(speed_pressure: float) -> void:
	var active_pressure := clampf(maxf(speed_pressure, throttle_energy * 0.30) - 0.04, 0.0, 1.0) * near_strength
	if active_pressure <= 0.001:
		return
	var visible_rect := _get_background_visible_world_rect()
	if not visible_rect.has_area():
		return
	var spacing_world := 980.0
	var depth := 0.70
	var start_index := int(floorf(visible_rect.position.x / spacing_world)) - 4
	var end_index := int(ceilf(visible_rect.end.x / spacing_world)) + 4
	for index in range(start_index, end_index + 1):
		var seed := float(index) * 29.91
		var world_x := float(index) * spacing_world + lerpf(-320.0, 320.0, _hash01(seed + 1.0))
		var screen_x := background_screen_x(world_x, depth)
		var screen_y := view_size.y * lerpf(0.64, 0.88, _hash01(seed + 2.0))
		if screen_x < -320.0 or screen_x > view_size.x + 320.0:
			continue
		var length := lerpf(210.0, 540.0, _hash01(seed + 3.0)) * lerpf(0.82, 1.34, active_pressure) / _background_zoom()
		var alpha := lerpf(0.025, 0.075, active_pressure) * lerpf(0.60, 1.0, _hash01(seed + 4.0))
		_draw_speed_wisp(Vector2(screen_x, screen_y), length, alpha, seed)


func _draw_speed_wisp(center: Vector2, length: float, alpha: float, seed: float) -> void:
	var color := Color(0.88, 0.99, 1.0, alpha)
	for lane in range(3):
		var lane_offset := (float(lane) - 1.0) * 10.0
		var points := PackedVector2Array()
		for i in range(10):
			var t := float(i) / 9.0
			var wave := sin(seed + t * TAU * 0.8 + elapsed_time * 0.18) * 6.0
			points.append(center + Vector2(length * (t - 0.5), lane_offset + wave))
		draw_polyline(points, Color(color.r, color.g, color.b, color.a * lerpf(1.0, 0.45, float(lane) / 2.0)), maxf(2.0, 5.0 / _background_zoom()), true)


func _draw_battlefield_boundary_layers() -> void:
	var top_y := _world_to_screen(Vector2(camera_center.x, play_rect.position.y)).y
	var bottom_y := _world_to_screen(Vector2(camera_center.x, play_rect.end.y)).y
	var left_x := _world_to_screen(Vector2(play_rect.position.x, camera_center.y)).x
	var right_x := _world_to_screen(Vector2(play_rect.end.x, camera_center.y)).x
	_draw_horizontal_boundary_layer(top_y, true, _boundary_screen_pressure(top_y, 0.0))
	_draw_horizontal_boundary_layer(bottom_y, false, _boundary_screen_pressure(bottom_y, view_size.y))
	_draw_vertical_boundary_layer(left_x, true, _boundary_screen_pressure(left_x, 0.0))
	_draw_vertical_boundary_layer(right_x, false, _boundary_screen_pressure(right_x, view_size.x))


func _boundary_screen_pressure(screen_value: float, edge_value: float) -> float:
	return clampf(1.0 - absf(screen_value - edge_value) / SCENE_BACKGROUND_BOUNDARY_SCREEN_RANGE, 0.0, 1.0)


func _draw_horizontal_boundary_layer(screen_y: float, is_top: bool, pressure: float) -> void:
	if pressure <= 0.001:
		return
	if boundary_cloud_wall_texture == null or boundary_rune_strip_texture == null:
		return
	var cloud_size: Vector2 = boundary_cloud_wall_texture.get_size()
	var cloud_y: float = screen_y - cloud_size.y * 0.24 if is_top else screen_y - cloud_size.y * 0.76
	_draw_tiled_texture_x(boundary_cloud_wall_texture, cloud_y, 0.42, SCENE_BACKGROUND_BOUNDARY_ALPHA * pressure)
	var rune_size: Vector2 = boundary_rune_strip_texture.get_size()
	var rune_y: float = screen_y + 58.0 if is_top else screen_y - rune_size.y - 58.0
	_draw_tiled_texture_x(boundary_rune_strip_texture, rune_y, 0.55, SCENE_BACKGROUND_RUNE_ALPHA * pressure)


func _draw_vertical_boundary_layer(screen_x: float, is_left: bool, pressure: float) -> void:
	if pressure <= 0.001:
		return
	if boundary_cloud_wall_texture == null or boundary_rune_strip_texture == null:
		return
	var cloud_width := 240.0
	var cloud_x := screen_x - cloud_width * 0.34 if is_left else screen_x - cloud_width * 0.66
	var cloud_rect := Rect2(Vector2(cloud_x, -20.0), Vector2(cloud_width, view_size.y + 40.0))
	var cloud_source := Rect2(Vector2.ZERO, boundary_cloud_wall_texture.get_size())
	draw_texture_rect_region(boundary_cloud_wall_texture, cloud_rect, cloud_source, Color(1.0, 1.0, 1.0, SCENE_BACKGROUND_BOUNDARY_ALPHA * 0.72 * pressure))
	var rune_width := 92.0
	var rune_x := screen_x + 52.0 if is_left else screen_x - rune_width - 52.0
	var rune_rect := Rect2(Vector2(rune_x, 0.0), Vector2(rune_width, view_size.y))
	var rune_source := Rect2(Vector2.ZERO, boundary_rune_strip_texture.get_size())
	draw_texture_rect_region(boundary_rune_strip_texture, rune_rect, rune_source, Color(1.0, 1.0, 1.0, SCENE_BACKGROUND_RUNE_ALPHA * 0.48 * pressure))


func _draw_tiled_texture_x(texture: Texture2D, y: float, parallax_x: float, alpha: float, scale: float = 1.0) -> void:
	if texture == null or alpha <= 0.001:
		return
	var texture_size: Vector2 = texture.get_size()
	var draw_size: Vector2 = texture_size * scale
	if draw_size.x <= 0.0 or draw_size.y <= 0.0:
		return
	_draw_repeated_texture_tile_x(texture, y, camera_center.x * parallax_x, Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0)), scale)


func _draw_repeated_texture_tile_x(texture: Texture2D, y: float, phase: float, color: Color, scale: float = 1.0) -> void:
	var texture_size: Vector2 = texture.get_size()
	var draw_size: Vector2 = texture_size * scale
	if draw_size.x <= 0.0 or draw_size.y <= 0.0:
		return
	var x: float = -fposmod(phase, draw_size.x) - draw_size.x
	var source := Rect2(Vector2.ZERO, texture_size)
	while x < view_size.x + draw_size.x:
		draw_texture_rect_region(texture, Rect2(Vector2(x, y), draw_size), source, color)
		x += draw_size.x


func _draw_world_guides() -> void:
	var visible_rect := _get_visible_world_rect()
	if not visible_rect.has_area():
		return
	var grid_step := 360.0
	var start_x: float = floorf(visible_rect.position.x / grid_step) * grid_step
	var x: float = start_x
	while x <= visible_rect.end.x + grid_step:
		var alpha := 0.14 if int(round(x / grid_step)) % 5 == 0 else 0.055
		draw_line(_world_to_screen(Vector2(x, visible_rect.position.y)), _world_to_screen(Vector2(x, visible_rect.end.y)), Color(0.72, 0.92, 0.95, alpha), 1.0)
		x += grid_step
	var start_y: float = floorf(visible_rect.position.y / grid_step) * grid_step
	var y: float = start_y
	while y <= visible_rect.end.y + grid_step:
		var alpha := 0.12 if int(round(y / grid_step)) % 3 == 0 else 0.05
		draw_line(_world_to_screen(Vector2(visible_rect.position.x, y)), _world_to_screen(Vector2(visible_rect.end.x, y)), Color(0.72, 0.92, 0.95, alpha), 1.0)
		y += grid_step
	var rect_screen := Rect2(_world_to_screen(play_rect.position), play_rect.size / maxf(camera_zoom, 0.001))
	draw_rect(rect_screen, Color(0.22, 0.64, 0.72, 0.32), false, 2.0)


func _draw_vertical_gradient_rect(rect: Rect2, top_color: Color, bottom_color: Color) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var points := PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y),
	])
	var colors := PackedColorArray([
		top_color,
		top_color,
		bottom_color,
		bottom_color,
	])
	draw_polygon(points, colors)


func _draw_smooth_sky_gradient(top_color: Color, middle_color: Color, bottom_color: Color) -> void:
	var middle_y := view_size.y * 0.58
	_draw_vertical_gradient_rect(Rect2(Vector2.ZERO, Vector2(view_size.x, middle_y)), top_color, middle_color)
	_draw_vertical_gradient_rect(Rect2(Vector2(0.0, middle_y), Vector2(view_size.x, view_size.y - middle_y)), middle_color, bottom_color)


func _draw_soft_sky_haze(center_ratio: float, half_height_ratio: float, color: Color) -> void:
	var half_height := view_size.y * half_height_ratio
	var center_y := view_size.y * center_ratio
	var top_y := center_y - half_height
	var bottom_y := center_y + half_height
	var edge_color := Color(color.r, color.g, color.b, 0.0)
	var center_color := Color(color.r, color.g, color.b, color.a)
	_draw_vertical_gradient_rect(Rect2(Vector2(0.0, top_y), Vector2(view_size.x, center_y - top_y)), edge_color, center_color)
	_draw_vertical_gradient_rect(Rect2(Vector2(0.0, center_y), Vector2(view_size.x, bottom_y - center_y)), center_color, edge_color)


func _draw_soft_horizon_glow(horizon_y: float, alpha_scale: float) -> void:
	var band_height := horizon_glow_width
	var top_y := horizon_y - band_height * 0.45
	var bottom_y := horizon_y + band_height * 0.55
	var edge_color := Color(horizon_glow_color.r, horizon_glow_color.g, horizon_glow_color.b, 0.0)
	var center_color := Color(
		horizon_glow_color.r,
		horizon_glow_color.g,
		horizon_glow_color.b,
		horizon_glow_strength * alpha_scale * horizon_glow_color.a
	)
	_draw_vertical_gradient_rect(Rect2(Vector2(0.0, top_y), Vector2(view_size.x, horizon_y - top_y)), edge_color, center_color)
	_draw_vertical_gradient_rect(Rect2(Vector2(0.0, horizon_y), Vector2(view_size.x, bottom_y - horizon_y)), center_color, edge_color)


func _island_top_color(kind: int) -> Color:
	match kind % 3:
		0:
			return Color(0.72, 0.58, 0.39, 1.0)
		1:
			return Color(0.66, 0.56, 0.40, 1.0)
		_:
			return Color(0.76, 0.64, 0.43, 1.0)


func _island_cliff_color(kind: int) -> Color:
	match kind % 3:
		0:
			return Color(0.46, 0.37, 0.27, 1.0)
		1:
			return Color(0.40, 0.34, 0.26, 1.0)
		_:
			return Color(0.52, 0.40, 0.28, 1.0)


func _polygon_center(points: PackedVector2Array) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var total := Vector2.ZERO
	for point in points:
		total += point
	return total / float(points.size())


func _scaled_polygon(points: PackedVector2Array, center: Vector2, scale: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(center + (point - center) * scale)
	return result


func _polyline_lerp(points: PackedVector2Array, t: float) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	if points.size() == 1:
		return points[0]
	var scaled_t := clampf(t, 0.0, 1.0) * float(points.size() - 1)
	var index := int(floorf(scaled_t))
	if index >= points.size() - 1:
		return points[points.size() - 1]
	return points[index].lerp(points[index + 1], scaled_t - float(index))


func _hash01(value: float) -> float:
	return fposmod(sin(value * 12.9898 + 78.233) * 43758.5453, 1.0)
