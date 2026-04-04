extends SceneTree

const SwordArrayConfig = preload("res://scripts/system/sword_array_config.gd")
const SwordArrayController = preload("res://scripts/system/sword_array_controller.gd")

const REPORT_JSON_PATH := "res://resources/debug/sword_array_geometry_regression.json"
const REPORT_MD_PATH := "res://resources/debug/sword_array_geometry_regression.md"
const DEFAULT_FORMATION_RATIO := 1.0
const DEFAULT_SLOT_COUNT := 8
const DEFAULT_FIRE_COUNT := 5
const BOUNDARY_OFFSETS := [-4.0, -1.0, 0.0, 1.0, 4.0]


class MockSwordArrayMain extends Node:
	var player := {
		"pos": Vector2.ZERO,
		"absorbed_ids": [],
	}
	var mouse_world: Vector2 = Vector2.RIGHT * 120.0


func _initialize() -> void:
	SwordArrayConfig.load_morph_distances_from_project()
	var report: Dictionary = _build_report()
	var json_ok: bool = _write_text_file(REPORT_JSON_PATH, JSON.stringify(report, "\t"))
	var markdown_ok: bool = _write_text_file(REPORT_MD_PATH, _build_markdown_report(report))
	if json_ok and markdown_ok:
		print("Sword array geometry regression exported to:")
		print("  %s" % ProjectSettings.globalize_path(REPORT_JSON_PATH))
		print("  %s" % ProjectSettings.globalize_path(REPORT_MD_PATH))
		quit(0)
	else:
		push_error("Failed to export sword array geometry regression report.")
		quit(1)


func _build_report() -> Dictionary:
	var mock_main := MockSwordArrayMain.new()
	var distances: Dictionary = SwordArrayConfig.get_morph_distances()
	var samples: Array = []
	for sample_distance in _build_sample_distances(distances):
		samples.append(_build_sample(mock_main, sample_distance))
	samples.sort_custom(func(a, b): return float(a.get("distance", 0.0)) < float(b.get("distance", 0.0)))
	_apply_continuity_metrics(samples)
	var report := {
		"generated_at": Time.get_datetime_string_from_system(true, true),
		"formation_ratio": DEFAULT_FORMATION_RATIO,
		"slot_count": DEFAULT_SLOT_COUNT,
		"fire_count": DEFAULT_FIRE_COUNT,
		"distances": distances,
		"samples": samples,
	}
	mock_main.free()
	return report


func _build_sample_distances(distances: Dictionary) -> Array:
	var raw_samples := [
		{"label": "ring_core", "distance": maxf(float(distances["ring_stable_end"]) - 8.0, 0.0)},
		{"label": "ring_mid", "distance": maxf(float(distances["ring_stable_end"]) * 0.5, 0.0)},
		{"label": "ring_to_fan_mid", "distance": lerpf(float(distances["ring_stable_end"]), float(distances["fan_stable_end"]), 0.5)},
		{"label": "fan_mid", "distance": lerpf(float(distances["ring_to_fan_end"]), float(distances["fan_stable_end"]), 0.5)},
		{"label": "fan_to_pierce_mid", "distance": lerpf(float(distances["fan_stable_end"]), float(distances["fan_to_pierce_end"]), 0.5)},
		{"label": "fan_to_pierce_late", "distance": lerpf(float(distances["fan_stable_end"]), float(distances["fan_to_pierce_end"]), 0.82)},
		{"label": "pierce_core", "distance": float(distances["fan_to_pierce_end"]) + 8.0},
	]
	var boundaries := [
		{"prefix": "ring_stable", "distance": float(distances["ring_stable_end"])},
		{"prefix": "ring_to_fan", "distance": float(distances["ring_to_fan_end"])},
		{"prefix": "fan_stable", "distance": float(distances["fan_stable_end"])},
		{"prefix": "fan_to_pierce", "distance": float(distances["fan_to_pierce_end"])},
	]
	for boundary in boundaries:
		for offset in BOUNDARY_OFFSETS:
			raw_samples.append({
				"label": "%s_%s" % [boundary["prefix"], _format_offset_label(offset)],
				"distance": maxf(float(boundary["distance"]) + offset, 0.0),
			})
	return _dedupe_sample_distances(raw_samples)


func _build_sample(mock_main: MockSwordArrayMain, sample_distance: Dictionary) -> Dictionary:
	var distance: float = float(sample_distance.get("distance", 0.0))
	mock_main.mouse_world = mock_main.player["pos"] + Vector2.RIGHT * distance
	var morph_state: Dictionary = SwordArrayConfig.get_morph_state_for_distance(distance)
	var geometry: Dictionary = SwordArrayController.get_geometry_result(mock_main, morph_state, DEFAULT_FORMATION_RATIO)
	var slot_positions: Array = []
	var fire_targets: Array = []
	var fire_origins: Array = []
	var slot_index: int = 0
	while slot_index < DEFAULT_SLOT_COUNT:
		slot_positions.append(
			_vector_to_array(
				SwordArrayController.get_slot_position(mock_main, morph_state, slot_index, DEFAULT_SLOT_COUNT, DEFAULT_FORMATION_RATIO)
			)
		)
		slot_index += 1
	var fire_index: int = 0
	while fire_index < DEFAULT_FIRE_COUNT:
		fire_targets.append(
			_vector_to_array(
				SwordArrayController.get_fire_target(mock_main, morph_state, fire_index, mock_main.player["pos"], DEFAULT_FIRE_COUNT)
			)
		)
		fire_origins.append(
			_vector_to_array(
				SwordArrayController.get_fire_launch_origin(mock_main, morph_state, fire_index, mock_main.player["pos"], DEFAULT_FIRE_COUNT)
			)
		)
		fire_index += 1
	return {
		"label": String(sample_distance.get("label", "")),
		"distance": snapped(distance, 0.001),
		"morph_state": {
			"dominant_mode": morph_state.get("dominant_mode", ""),
			"visual_from_mode": morph_state.get("visual_from_mode", ""),
			"visual_to_mode": morph_state.get("visual_to_mode", ""),
			"visual_blend": snapped(float(morph_state.get("visual_blend", 0.0)), 0.0001),
			"formation_family": morph_state.get("formation_family", ""),
			"preset_from": morph_state.get("preset_from", ""),
			"preset_to": morph_state.get("preset_to", ""),
			"preset_blend": snapped(float(morph_state.get("preset_blend", 0.0)), 0.0001),
		},
		"geometry": _serialize_geometry(geometry),
		"release_profile": _serialize_number_dictionary(SwordArrayController.get_fire_release_profile(mock_main, morph_state, DEFAULT_FIRE_COUNT)),
		"slot_positions": slot_positions,
		"fire_targets": fire_targets,
		"fire_origins": fire_origins,
	}


func _serialize_geometry(geometry: Dictionary) -> Dictionary:
	var preview_state = geometry.get("preview_state", null)
	var preview_state_summary := {}
	if typeof(preview_state) == TYPE_DICTIONARY:
		preview_state_summary = {
			"type": "dictionary",
			"dominant_mode": preview_state.get("dominant_mode", ""),
			"visual_from_mode": preview_state.get("visual_from_mode", ""),
			"visual_to_mode": preview_state.get("visual_to_mode", ""),
			"visual_blend": snapped(float(preview_state.get("visual_blend", 0.0)), 0.0001),
			"preset_from": preview_state.get("preset_from", ""),
			"preset_to": preview_state.get("preset_to", ""),
			"preset_blend": snapped(float(preview_state.get("preset_blend", 0.0)), 0.0001),
		}
	else:
		preview_state_summary = {
			"type": typeof(preview_state),
			"value": str(preview_state),
		}
	return {
		"family": geometry.get("family", ""),
		"preview_type": geometry.get("preview_type", ""),
		"band_stage": geometry.get("band_stage", ""),
		"has_profile_sections": bool(geometry.get("has_profile_sections", false)),
		"active_preset_id": geometry.get("active_preset_id", ""),
		"preset_from": geometry.get("runtime", {}).get("from_preset_id", geometry.get("preset_from", "")),
		"preset_to": geometry.get("runtime", {}).get("to_preset_id", geometry.get("preset_to", "")),
		"morph_profile_id": geometry.get("morph_profile_id", ""),
		"preview_state": preview_state_summary,
		"center": _vector_to_array(geometry.get("center", Vector2.ZERO)),
		"tail": _vector_to_array(geometry.get("tail", Vector2.ZERO)),
		"tip": _vector_to_array(geometry.get("tip", Vector2.ZERO)),
		"start": _vector_to_array(geometry.get("start", Vector2.ZERO)),
		"end": _vector_to_array(geometry.get("end", Vector2.ZERO)),
		"outer_cap_control": _vector_to_array(geometry.get("outer_cap_control", Vector2.ZERO)),
		"inner_cap_control": _vector_to_array(geometry.get("inner_cap_control", Vector2.ZERO)),
		"aim_vector": _vector_to_array(geometry.get("aim_vector", Vector2.RIGHT)),
		"arc": snapped(float(geometry.get("arc", 0.0)), 0.0001),
		"inner_arc": snapped(float(geometry.get("inner_arc", 0.0)), 0.0001),
		"radius": snapped(float(geometry.get("radius", 0.0)), 0.0001),
		"inner_radius": snapped(float(geometry.get("inner_radius", 0.0)), 0.0001),
		"outer_radius": snapped(float(geometry.get("outer_radius", 0.0)), 0.0001),
		"half_width": snapped(float(geometry.get("half_width", 0.0)), 0.0001),
		"tip_radius": snapped(float(geometry.get("tip_radius", 0.0)), 0.0001),
		"blend": snapped(float(geometry.get("blend", 0.0)), 0.0001),
		"spine_focus": snapped(float(geometry.get("spine_focus", 0.0)), 0.0001),
		"tip_focus": snapped(float(geometry.get("tip_focus", 0.0)), 0.0001),
		"section_centers": _vector_array_to_arrays(geometry.get("section_centers", [])),
		"spine_points": _vector_array_to_arrays(geometry.get("spine_points", [])),
	}


func _apply_continuity_metrics(samples: Array) -> void:
	var previous_sample: Dictionary = {}
	for sample in samples:
		if previous_sample.is_empty():
			sample["continuity_from_previous"] = {}
			previous_sample = sample
			continue
		var previous_geometry: Dictionary = previous_sample.get("geometry", {})
		var geometry: Dictionary = sample.get("geometry", {})
		sample["continuity_from_previous"] = {
			"distance_step": snapped(float(sample.get("distance", 0.0)) - float(previous_sample.get("distance", 0.0)), 0.0001),
			"center_delta": _vector_delta(previous_geometry.get("center", []), geometry.get("center", [])),
			"tail_delta": _vector_delta(previous_geometry.get("tail", []), geometry.get("tail", [])),
			"tip_delta": _vector_delta(previous_geometry.get("tip", []), geometry.get("tip", [])),
			"outer_radius_delta": snapped(absf(float(geometry.get("outer_radius", 0.0)) - float(previous_geometry.get("outer_radius", 0.0))), 0.0001),
			"inner_radius_delta": snapped(absf(float(geometry.get("inner_radius", 0.0)) - float(previous_geometry.get("inner_radius", 0.0))), 0.0001),
			"arc_delta": snapped(absf(float(geometry.get("arc", 0.0)) - float(previous_geometry.get("arc", 0.0))), 0.0001),
			"max_slot_delta": _max_point_delta(previous_sample.get("slot_positions", []), sample.get("slot_positions", [])),
		}
		previous_sample = sample


func _build_markdown_report(report: Dictionary) -> String:
	var lines: Array = [
		"# Sword Array Geometry Regression",
		"",
		"Generated: %s" % String(report.get("generated_at", "")),
		"",
		"| Label | Distance | Preview | Stage | Active Preset | Tip Delta | Max Slot Delta |",
		"| --- | ---: | --- | --- | --- | ---: | ---: |",
	]
	for sample in report.get("samples", []):
		var geometry: Dictionary = sample.get("geometry", {})
		var continuity: Dictionary = sample.get("continuity_from_previous", {})
		lines.append(
			"| %s | %.3f | %s | %s | %s | %.3f | %.3f |" % [
				sample.get("label", ""),
				float(sample.get("distance", 0.0)),
				geometry.get("preview_type", ""),
				geometry.get("band_stage", ""),
				geometry.get("active_preset_id", ""),
				float(continuity.get("tip_delta", 0.0)),
				float(continuity.get("max_slot_delta", 0.0)),
			]
		)
	return "\n".join(lines) + "\n"


func _serialize_number_dictionary(values: Dictionary) -> Dictionary:
	var output := {}
	for key in values.keys():
		var value = values[key]
		if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
			output[key] = snapped(float(value), 0.0001)
		else:
			output[key] = value
	return output


func _vector_to_array(value) -> Array:
	if value is Vector2:
		return [snapped(value.x, 0.001), snapped(value.y, 0.001)]
	return [0.0, 0.0]


func _vector_array_to_arrays(values: Array) -> Array:
	var output: Array = []
	for value in values:
		output.append(_vector_to_array(value))
	return output


func _vector_delta(from_value, to_value) -> float:
	if from_value is Array and to_value is Array and from_value.size() >= 2 and to_value.size() >= 2:
		return snapped(Vector2(float(from_value[0]), float(from_value[1])).distance_to(Vector2(float(to_value[0]), float(to_value[1]))), 0.0001)
	return 0.0


func _max_point_delta(from_points: Array, to_points: Array) -> float:
	var point_count: int = mini(from_points.size(), to_points.size())
	var max_delta: float = 0.0
	var point_index: int = 0
	while point_index < point_count:
		max_delta = maxf(max_delta, _vector_delta(from_points[point_index], to_points[point_index]))
		point_index += 1
	return snapped(max_delta, 0.0001)


func _dedupe_sample_distances(raw_samples: Array) -> Array:
	var deduped: Array = []
	var seen := {}
	for sample in raw_samples:
		var distance: float = snapped(float(sample.get("distance", 0.0)), 0.001)
		var key: String = str(distance)
		if seen.has(key):
			continue
		seen[key] = true
		deduped.append({
			"label": sample.get("label", ""),
			"distance": distance,
		})
	return deduped


func _format_offset_label(offset: float) -> String:
	if is_zero_approx(offset):
		return "at"
	if offset > 0.0:
		return "plus_%d" % int(round(offset))
	return "minus_%d" % int(round(absf(offset)))


func _write_text_file(project_path: String, content: String) -> bool:
	var absolute_path: String = ProjectSettings.globalize_path(project_path)
	var directory_path: String = absolute_path.get_base_dir()
	var make_result: Error = DirAccess.make_dir_recursive_absolute(directory_path)
	if make_result != OK:
		return false
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	return true
