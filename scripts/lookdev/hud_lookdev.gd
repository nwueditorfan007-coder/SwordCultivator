extends Control

const PRESET_KEYS := ["a", "b", "c"]
const PRESETS := {
	"a": {
		"name": "极简天仪版",
		"summary": "保读感，装饰最轻",
		"scale": 0.92,
		"frame_alpha": 0.34,
		"ornament_alpha": 0.22,
		"background_density": 0.55,
		"skill_emphasis": 0.9,
		"battle_width": 0.73,
		"battle_height": 0.62,
		"battle_center_x": 0.50,
		"battle_center_y": 0.55,
		"mantra_alpha": 0.22,
		"char_alpha": 0.07,
		"mode_radius": 32.0,
		"big_skill_radius": 34.0,
	},
	"b": {
		"name": "平衡法器版",
		"summary": "主推方向，气质和信息平衡",
		"scale": 1.0,
		"frame_alpha": 0.52,
		"ornament_alpha": 0.34,
		"background_density": 0.78,
		"skill_emphasis": 1.0,
		"battle_width": 0.71,
		"battle_height": 0.64,
		"battle_center_x": 0.50,
		"battle_center_y": 0.56,
		"mantra_alpha": 0.34,
		"char_alpha": 0.11,
		"mode_radius": 36.0,
		"big_skill_radius": 40.0,
	},
	"c": {
		"name": "华丽星图版",
		"summary": "抬上限，但要控制信息量",
		"scale": 1.08,
		"frame_alpha": 0.64,
		"ornament_alpha": 0.44,
		"background_density": 1.0,
		"skill_emphasis": 1.1,
		"battle_width": 0.68,
		"battle_height": 0.64,
		"battle_center_x": 0.50,
		"battle_center_y": 0.56,
		"mantra_alpha": 0.46,
		"char_alpha": 0.14,
		"mode_radius": 41.0,
		"big_skill_radius": 44.0,
	},
}

const COLOR_BG := Color("06101c")
const COLOR_BG_DEEP := Color("03070d")
const COLOR_GOLD := Color("d7bb79")
const COLOR_GOLD_SOFT := Color(0.84, 0.74, 0.5, 0.24)
const COLOR_BLUE := Color("88d8ff")
const COLOR_BLUE_SOFT := Color(0.55, 0.84, 1.0, 0.15)
const COLOR_BLUE_CORE := Color("f6fbff")
const COLOR_RED := Color("df5b66")
const COLOR_TEXT := Color("f1e3bc")
const COLOR_TEXT_SOFT := Color("9cb0c2")

var current_preset: String = "b"
var elapsed_time: float = 0.0
var labels: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	_create_labels()
	_apply_preset()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	elapsed_time += delta
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_labels()
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_set_preset("a")
			KEY_2:
				_set_preset("b")
			KEY_3:
				_set_preset("c")


func _draw() -> void:
	var preset: Dictionary = PRESETS[current_preset]
	var metrics: Dictionary = _get_metrics(preset)
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BG, true)
	_draw_background_wash(metrics, preset)
	_draw_battlefield(metrics, preset)
	_draw_left_resource_cluster(metrics, preset)
	_draw_top_banner(metrics, preset)
	_draw_mode_badge(metrics, preset)
	_draw_side_ornaments(metrics, preset)
	_draw_skill_tray(metrics, preset)
	_draw_bottom_hairline(metrics, preset)


func _set_preset(preset_key: String) -> void:
	if current_preset == preset_key or not PRESETS.has(preset_key):
		return
	current_preset = preset_key
	_apply_preset()
	queue_redraw()


func _apply_preset() -> void:
	var preset: Dictionary = PRESETS[current_preset]
	_set_label_text("status", "飞剑未回收")
	_set_label_text("mode", "近战\n3/3")
	_set_label_text("health", "生命 68 / 100")
	_set_label_text("energy", "剑意 82 / 100")
	_set_label_text("wave", "波次 3")
	_set_label_text("score", "得分 260 | 飞剑 6 / 12")
	_set_label_text("left_mantra", "万剑归宗\n御剑乘风")
	_set_label_text("right_mantra", "剑心通明\n道逾无极")
	_set_label_text("bottom_hint", "1 极简 | 2 平衡 | 3 华丽   当前：" + str(preset["name"]))
	_set_label_text("preset_summary", "HUD Lookdev · " + str(preset["summary"]))
	_set_label_text("bg_char", "剑")

	var scale: float = float(preset["scale"])
	_style_label("preset_summary", 17, COLOR_TEXT_SOFT, HORIZONTAL_ALIGNMENT_LEFT, 0.92)
	_style_label("status", int(round(30 * scale)), COLOR_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 0.96)
	_style_label("mode", int(round(26 * scale)), COLOR_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 0.96)
	_style_label("health", int(round(28 * scale)), COLOR_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 0.96)
	_style_label("energy", int(round(24 * scale)), COLOR_TEXT_SOFT.lerp(COLOR_BLUE, 0.25), HORIZONTAL_ALIGNMENT_LEFT, 0.96)
	_style_label("wave", int(round(22 * scale)), COLOR_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 0.92)
	_style_label("score", int(round(20 * scale)), COLOR_TEXT_SOFT, HORIZONTAL_ALIGNMENT_LEFT, 0.92)
	_style_label("left_mantra", int(round(18 * scale)), _with_alpha(COLOR_GOLD, float(preset["mantra_alpha"])), HORIZONTAL_ALIGNMENT_CENTER, 0.92)
	_style_label("right_mantra", int(round(18 * scale)), _with_alpha(COLOR_GOLD, float(preset["mantra_alpha"])), HORIZONTAL_ALIGNMENT_CENTER, 0.92)
	_style_label("bottom_hint", int(round(18 * scale)), COLOR_TEXT_SOFT, HORIZONTAL_ALIGNMENT_CENTER, 0.92)
	_style_label("bg_char", int(round(310 * scale)), _with_alpha(COLOR_TEXT, float(preset["char_alpha"])), HORIZONTAL_ALIGNMENT_CENTER, 0.9)
	_layout_labels()


func _create_labels() -> void:
	_create_label("preset_summary")
	_create_label("status")
	_create_label("mode")
	_create_label("health")
	_create_label("energy")
	_create_label("wave")
	_create_label("score")
	_create_label("left_mantra")
	_create_label("right_mantra")
	_create_label("bottom_hint")
	_create_label("bg_char")


func _create_label(label_key: String) -> void:
	var label := Label.new()
	label.name = label_key.capitalize()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = false
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.38))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
	labels[label_key] = label


func _style_label(label_key: String, font_size: int, color: Color, alignment: HorizontalAlignment, alpha: float) -> void:
	var label: Label = labels[label_key]
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", _with_alpha(color, alpha))
	label.horizontal_alignment = alignment


func _set_label_text(label_key: String, text_value: String) -> void:
	var label: Label = labels[label_key]
	label.text = text_value


func _layout_labels() -> void:
	var preset: Dictionary = PRESETS[current_preset]
	var metrics: Dictionary = _get_metrics(preset)

	_place_label("preset_summary", Vector2(28.0, 20.0), Vector2(360.0, 28.0))
	_place_label("bg_char", Vector2(size.x * 0.26, size.y * 0.16), Vector2(size.x * 0.48, size.y * 0.46))
	_place_label("status", metrics["top_banner_rect"].position + Vector2(0.0, 2.0), metrics["top_banner_rect"].size)
	_place_label("mode", Vector2(metrics["mode_badge_center"].x - 52.0, metrics["top_margin"] + 6.0), Vector2(104.0, 80.0))

	_place_label("health", metrics["resource_text_origin"] + Vector2(0.0, 2.0), Vector2(240.0, 32.0))
	_place_label("energy", metrics["resource_text_origin"] + Vector2(0.0, 34.0), Vector2(240.0, 28.0))
	_place_label("wave", metrics["resource_text_origin"] + Vector2(0.0, 84.0), Vector2(160.0, 28.0))
	_place_label("score", metrics["resource_text_origin"] + Vector2(0.0, 110.0), Vector2(300.0, 28.0))

	_place_label("left_mantra", Vector2(metrics["left_mantra_x"], size.y * 0.43), Vector2(96.0, 160.0))
	_place_label("right_mantra", Vector2(metrics["right_mantra_x"], size.y * 0.43), Vector2(96.0, 160.0))
	_place_label("bottom_hint", Vector2(size.x * 0.22, size.y - 44.0), Vector2(size.x * 0.56, 30.0))


func _place_label(label_key: String, label_position: Vector2, label_size: Vector2) -> void:
	var label: Label = labels[label_key]
	label.position = label_position
	label.size = label_size


func _get_metrics(preset: Dictionary) -> Dictionary:
	var scale: float = float(preset["scale"])
	var top_margin: float = 26.0
	var side_margin: float = 26.0
	var arena_rect := Rect2(
		Vector2(size.x * (1.0 - float(preset["battle_width"])) * 0.5, size.y * 0.17),
		Vector2(size.x * float(preset["battle_width"]), size.y * float(preset["battle_height"]))
	)
	var battle_center := Vector2(
		arena_rect.position.x + arena_rect.size.x * float(preset["battle_center_x"]),
		arena_rect.position.y + arena_rect.size.y * float(preset["battle_center_y"])
	)
	var top_banner_rect := Rect2(
		Vector2(size.x * 0.5 - 220.0 * scale, top_margin),
		Vector2(440.0 * scale, 42.0 * scale)
	)
	return {
		"top_margin": top_margin,
		"side_margin": side_margin,
		"arena_rect": arena_rect,
		"battle_center": battle_center,
		"resource_icon_center": Vector2(side_margin + 42.0, top_margin + 30.0),
		"resource_text_origin": Vector2(side_margin + 88.0, top_margin + 2.0),
		"resource_bar_origin": Vector2(side_margin + 92.0, top_margin + 36.0),
		"top_banner_rect": top_banner_rect,
		"mode_badge_center": Vector2(size.x - side_margin - 38.0, top_margin + 38.0),
		"skill_center": Vector2(size.x * 0.5, size.y - 90.0),
		"left_mantra_x": 12.0,
		"right_mantra_x": size.x - 108.0,
	}


func _draw_background_wash(metrics: Dictionary, preset: Dictionary) -> void:
	var arena_rect: Rect2 = metrics["arena_rect"]
	var density: float = float(preset["background_density"])
	var pulse: float = 0.5 + 0.5 * sin(elapsed_time * 0.35)
	draw_rect(arena_rect.grow(8.0), _with_alpha(COLOR_BG_DEEP, 0.45), true)
	draw_rect(arena_rect.grow(8.0), _with_alpha(COLOR_GOLD, 0.06 * float(preset["frame_alpha"])), false, 2.0)

	var ring_radius: Array[float] = [80.0, 150.0, 235.0, 320.0]
	for radius in ring_radius:
		draw_arc(
			metrics["battle_center"],
			radius * float(preset["scale"]),
			0.0,
			TAU,
			72,
			_with_alpha(COLOR_GOLD, 0.07 + 0.05 * density),
			1.0 + 0.25 * density
		)

	var orbit_count: int = 5 + int(round(density * 2.0))
	for orbit_index in range(orbit_count):
		var t: float = float(orbit_index) / float(maxi(orbit_count - 1, 1))
		var orbit_radius: float = lerpf(110.0, 360.0, t) * float(preset["scale"])
		var orbit_arc: float = PI * (1.0 + t * 0.28)
		var orbit_angle: float = elapsed_time * (0.06 + t * 0.04) + t * 0.7
		draw_arc(
			metrics["battle_center"] + Vector2(cos(orbit_angle), sin(orbit_angle * 0.8)) * (8.0 + 18.0 * t),
			orbit_radius,
			-orbit_arc * 0.45,
			orbit_arc * 0.45,
			48,
			_with_alpha(COLOR_BLUE, 0.04 + 0.05 * density),
			1.0
		)

	var particle_count: int = 22 + int(round(density * 18.0))
	for particle_index in range(particle_count):
		var ratio: float = float(particle_index) / float(maxi(particle_count - 1, 1))
		var angle: float = ratio * TAU * 1.37 + elapsed_time * (0.08 + ratio * 0.03)
		var radius_offset: float = 90.0 + fmod(ratio * 310.0 + elapsed_time * 10.0, 280.0)
		var sparkle_pos: Vector2 = metrics["battle_center"] + Vector2.RIGHT.rotated(angle) * radius_offset
		var sparkle_color: Color = COLOR_GOLD.lerp(COLOR_BLUE_CORE, ratio * 0.45 + pulse * 0.1)
		draw_circle(sparkle_pos, 1.2 + 2.0 * fmod(ratio * 7.0, 1.0), _with_alpha(sparkle_color, 0.18 + 0.14 * density))


func _draw_battlefield(metrics: Dictionary, preset: Dictionary) -> void:
	var battle_center: Vector2 = metrics["battle_center"]
	var scale: float = float(preset["scale"])
	var sword_vectors := [
		Vector2(426.0, -312.0),
		Vector2(184.0, -158.0),
		Vector2(-214.0, -190.0),
		Vector2(-332.0, -34.0),
		Vector2(-280.0, 110.0),
		Vector2(238.0, 112.0),
		Vector2(106.0, -222.0),
	]
	var sword_time: float = elapsed_time * 0.9
	for sword_index in range(sword_vectors.size()):
		var vector: Vector2 = sword_vectors[sword_index] * scale
		var wave: float = sin(sword_time + float(sword_index) * 0.85)
		var from_pos: Vector2 = battle_center + vector * 0.06 + Vector2.RIGHT.rotated(float(sword_index) * 0.85) * (8.0 + wave * 6.0)
		var to_pos: Vector2 = battle_center + vector + Vector2(0.0, wave * 10.0)
		var is_main_sword: bool = sword_index == 0
		_draw_sword_streak(from_pos, to_pos, is_main_sword, preset)

	var enemy_offsets := [
		Vector2(328.0, -220.0),
		Vector2(412.0, -80.0),
		Vector2(366.0, 114.0),
		Vector2(-258.0, -180.0),
		Vector2(-302.0, 118.0),
	]
	for enemy_index in range(enemy_offsets.size()):
		var marker_pos: Vector2 = battle_center + enemy_offsets[enemy_index] * scale
		_draw_enemy_marker(marker_pos, 16.0 + float(enemy_index % 2) * 4.0, preset)

	draw_circle(battle_center, 12.0, _with_alpha(COLOR_BLUE_CORE, 0.94))
	draw_circle(battle_center, 32.0, _with_alpha(COLOR_GOLD, 0.14))
	draw_arc(battle_center, 34.0, 0.0, TAU, 40, _with_alpha(COLOR_GOLD, 0.52), 2.2)
	draw_arc(battle_center, 62.0, 0.0, TAU, 48, _with_alpha(COLOR_BLUE, 0.18), 1.3)


func _draw_sword_streak(from_pos: Vector2, to_pos: Vector2, is_main_sword: bool, preset: Dictionary) -> void:
	var direction: Vector2 = (to_pos - from_pos).normalized()
	var wing: Vector2 = direction.rotated(PI * 0.5)
	var glow_alpha: float = 0.18 if is_main_sword else 0.12
	var core_width: float = 8.0 if is_main_sword else 4.4
	var glow_width: float = 20.0 if is_main_sword else 10.0
	draw_line(from_pos, to_pos, _with_alpha(COLOR_BLUE, glow_alpha), glow_width)
	draw_line(from_pos, to_pos, _with_alpha(COLOR_BLUE_CORE, 0.96), core_width)
	draw_line(from_pos, to_pos - direction * 8.0, _with_alpha(COLOR_GOLD, 0.26), 1.4)
	draw_colored_polygon(
		PackedVector2Array([
			to_pos,
			to_pos - direction * (18.0 if is_main_sword else 12.0) + wing * (6.0 if is_main_sword else 3.5),
			to_pos - direction * (18.0 if is_main_sword else 12.0) - wing * (6.0 if is_main_sword else 3.5),
		]),
		_with_alpha(COLOR_BLUE_CORE, 0.82)
	)
	draw_circle(from_pos, 2.0 if is_main_sword else 1.4, _with_alpha(COLOR_GOLD, 0.42))


func _draw_enemy_marker(marker_pos: Vector2, marker_radius: float, preset: Dictionary) -> void:
	var pulse: float = 0.86 + 0.14 * sin(elapsed_time * 1.6 + marker_pos.x * 0.01)
	var color: Color = _with_alpha(COLOR_RED, 0.72 * pulse)
	draw_arc(marker_pos, marker_radius, 0.0, TAU, 24, color, 2.0)
	draw_line(marker_pos + Vector2(-marker_radius * 0.9, 0.0), marker_pos + Vector2(marker_radius * 0.9, 0.0), color, 1.5)
	draw_line(marker_pos + Vector2(0.0, -marker_radius * 0.9), marker_pos + Vector2(0.0, marker_radius * 0.9), color, 1.5)
	draw_circle(marker_pos, 3.0, _with_alpha(COLOR_BLUE_CORE, 0.86))


func _draw_left_resource_cluster(metrics: Dictionary, preset: Dictionary) -> void:
	var icon_center: Vector2 = metrics["resource_icon_center"]
	var bar_origin: Vector2 = metrics["resource_bar_origin"]
	var scale: float = float(preset["scale"])
	var health_width: float = 210.0 * scale
	var energy_width: float = 190.0 * scale
	_draw_lotus_emblem(icon_center, 22.0 * scale, preset)

	_draw_bar(
		Rect2(bar_origin + Vector2(0.0, -4.0), Vector2(health_width, 10.0 * scale)),
		0.68,
		COLOR_BLUE_CORE,
		COLOR_BLUE,
		preset
	)
	_draw_bar(
		Rect2(bar_origin + Vector2(0.0, 28.0 * scale), Vector2(energy_width, 8.0 * scale)),
		0.82,
		COLOR_TEXT,
		COLOR_GOLD,
		preset
	)

	draw_line(bar_origin + Vector2(0.0, -18.0), bar_origin + Vector2(health_width + 34.0, -18.0), _with_alpha(COLOR_GOLD, 0.32), 1.2)
	draw_line(bar_origin + Vector2(0.0, 46.0 * scale), bar_origin + Vector2(energy_width + 24.0, 46.0 * scale), _with_alpha(COLOR_GOLD, 0.22), 1.0)


func _draw_lotus_emblem(center: Vector2, radius: float, preset: Dictionary) -> void:
	var pulse: float = 0.92 + 0.08 * sin(elapsed_time * 1.4)
	for petal_index in range(5):
		var angle: float = -PI * 0.5 + (float(petal_index) - 2.0) * 0.34
		var tip: Vector2 = center + Vector2.RIGHT.rotated(angle) * radius * 0.9
		var left: Vector2 = center + Vector2.RIGHT.rotated(angle + 0.48) * radius * 0.58
		var right: Vector2 = center + Vector2.RIGHT.rotated(angle - 0.48) * radius * 0.58
		draw_colored_polygon(
			PackedVector2Array([left, tip, right]),
			_with_alpha(COLOR_GOLD, 0.18 * pulse)
		)
		draw_line(left, tip, _with_alpha(COLOR_GOLD, 0.52), 1.2)
		draw_line(tip, right, _with_alpha(COLOR_GOLD, 0.52), 1.2)
	draw_arc(center, radius * 1.18, 0.0, TAU, 28, _with_alpha(COLOR_BLUE, 0.14), 1.2)
	draw_arc(center, radius * 1.55, PI * 0.18, PI * 0.82, 18, _with_alpha(COLOR_BLUE, 0.2), 1.0)


func _draw_bar(bar_rect: Rect2, fill_ratio: float, core_color: Color, accent_color: Color, preset: Dictionary) -> void:
	var frame_alpha: float = float(preset["frame_alpha"])
	draw_rect(bar_rect, _with_alpha(COLOR_BG_DEEP, 0.56), true)
	draw_rect(bar_rect, _with_alpha(COLOR_GOLD, 0.18 + 0.18 * frame_alpha), false, 1.4)
	var fill_rect := Rect2(bar_rect.position, Vector2(bar_rect.size.x * clampf(fill_ratio, 0.0, 1.0), bar_rect.size.y))
	draw_rect(fill_rect, _with_alpha(accent_color, 0.18), true)
	draw_rect(
		Rect2(fill_rect.position, Vector2(fill_rect.size.x, maxf(fill_rect.size.y - 2.0, 1.0))),
		_with_alpha(core_color, 0.82),
		true
	)
	draw_rect(Rect2(fill_rect.end - Vector2(10.0, 0.0), Vector2(10.0, fill_rect.size.y)), _with_alpha(core_color, 0.94), true)


func _draw_top_banner(metrics: Dictionary, preset: Dictionary) -> void:
	var banner_rect: Rect2 = metrics["top_banner_rect"]
	var ornament_alpha: float = float(preset["ornament_alpha"])
	var frame_alpha: float = float(preset["frame_alpha"])
	draw_rect(banner_rect.grow_individual(10.0, 4.0, 10.0, 4.0), _with_alpha(COLOR_BG_DEEP, 0.26), true)
	draw_rect(banner_rect, _with_alpha(COLOR_GOLD, 0.16), false, 1.6)
	draw_line(
		Vector2(banner_rect.position.x - 48.0, banner_rect.get_center().y),
		Vector2(banner_rect.position.x - 10.0, banner_rect.get_center().y),
		_with_alpha(COLOR_GOLD, 0.38 + ornament_alpha * 0.4),
		1.2
	)
	draw_line(
		Vector2(banner_rect.end.x + 10.0, banner_rect.get_center().y),
		Vector2(banner_rect.end.x + 48.0, banner_rect.get_center().y),
		_with_alpha(COLOR_GOLD, 0.38 + ornament_alpha * 0.4),
		1.2
	)
	draw_circle(Vector2(banner_rect.position.x - 18.0, banner_rect.get_center().y), 2.0, _with_alpha(COLOR_GOLD, 0.64 * frame_alpha))
	draw_circle(Vector2(banner_rect.end.x + 18.0, banner_rect.get_center().y), 2.0, _with_alpha(COLOR_GOLD, 0.64 * frame_alpha))


func _draw_mode_badge(metrics: Dictionary, preset: Dictionary) -> void:
	var center: Vector2 = metrics["mode_badge_center"]
	var radius: float = float(preset["mode_radius"])
	var frame_alpha: float = float(preset["frame_alpha"])
	draw_circle(center, radius + 10.0, _with_alpha(COLOR_BLUE, 0.06 + frame_alpha * 0.06))
	draw_arc(center, radius, 0.0, TAU, 34, _with_alpha(COLOR_GOLD, 0.5 + frame_alpha * 0.2), 1.8)
	draw_arc(center, radius - 10.0, PI * 0.15, PI * 1.85, 28, _with_alpha(COLOR_BLUE, 0.22), 1.2)
	draw_line(center + Vector2(0.0, -radius - 8.0), center + Vector2(0.0, radius + 8.0), _with_alpha(COLOR_GOLD, 0.18), 1.0)


func _draw_side_ornaments(metrics: Dictionary, preset: Dictionary) -> void:
	var left_x: float = metrics["left_mantra_x"] + 40.0
	var right_x: float = metrics["right_mantra_x"] + 40.0
	var top_y: float = size.y * 0.26
	var height: float = size.y * 0.34
	var mantra_alpha: float = float(preset["mantra_alpha"])
	draw_line(Vector2(left_x, top_y), Vector2(left_x, top_y + height), _with_alpha(COLOR_GOLD, 0.2 + mantra_alpha * 0.5), 1.2)
	draw_line(Vector2(right_x, top_y), Vector2(right_x, top_y + height), _with_alpha(COLOR_GOLD, 0.2 + mantra_alpha * 0.5), 1.2)
	draw_circle(Vector2(left_x, top_y), 2.2, _with_alpha(COLOR_GOLD, 0.72 * mantra_alpha))
	draw_circle(Vector2(right_x, top_y), 2.2, _with_alpha(COLOR_GOLD, 0.72 * mantra_alpha))


func _draw_skill_tray(metrics: Dictionary, preset: Dictionary) -> void:
	var center: Vector2 = metrics["skill_center"]
	var scale: float = float(preset["scale"])
	var emphasis: float = float(preset["skill_emphasis"])
	var small_radius: float = 22.0 * scale
	var big_radius: float = float(preset["big_skill_radius"])
	var positions := [
		center + Vector2(-124.0 * scale, 0.0),
		center + Vector2(-52.0 * scale, 0.0),
		center + Vector2(20.0 * scale, 0.0),
		center + Vector2(94.0 * scale, 0.0),
		center + Vector2(176.0 * scale, 0.0),
	]
	for icon_index in range(positions.size()):
		var icon_center: Vector2 = positions[icon_index]
		var radius: float = big_radius if icon_index == positions.size() - 1 else small_radius
		var is_primary: bool = icon_index == positions.size() - 1
		var frame_color: Color = _with_alpha(COLOR_GOLD if is_primary else COLOR_BLUE, 0.42 + 0.18 * emphasis)
		draw_circle(icon_center, radius + 10.0, _with_alpha(COLOR_BLUE, 0.04 if not is_primary else 0.08))
		draw_arc(icon_center, radius, 0.0, TAU, 28, frame_color, 1.8)
		draw_arc(icon_center, radius - 7.0, 0.0, TAU, 22, _with_alpha(COLOR_GOLD, 0.16 if not is_primary else 0.3), 1.0)
		_draw_skill_glyph(icon_center, radius * 0.58, icon_index, is_primary)

	draw_line(
		center + Vector2(-238.0 * scale, 0.0),
		center + Vector2(238.0 * scale, 0.0),
		_with_alpha(COLOR_GOLD, 0.16 + emphasis * 0.08),
		1.0
	)


func _draw_skill_glyph(center: Vector2, radius: float, icon_index: int, is_primary: bool) -> void:
	var color: Color = _with_alpha(COLOR_BLUE_CORE if not is_primary else COLOR_TEXT, 0.82)
	match icon_index:
		0:
			draw_line(center + Vector2(-radius * 0.42, radius * 0.3), center + Vector2(0.0, -radius * 0.56), color, 1.6)
			draw_line(center + Vector2(0.0, -radius * 0.56), center + Vector2(radius * 0.42, radius * 0.3), color, 1.6)
		1:
			draw_line(center + Vector2(0.0, -radius * 0.58), center + Vector2(0.0, radius * 0.56), color, 1.6)
			draw_line(center + Vector2(-radius * 0.36, radius * 0.2), center + Vector2(0.0, -radius * 0.12), color, 1.3)
			draw_line(center + Vector2(radius * 0.36, radius * 0.2), center + Vector2(0.0, -radius * 0.12), color, 1.3)
		2:
			draw_line(center + Vector2(-radius * 0.48, radius * 0.18), center + Vector2(radius * 0.24, -radius * 0.54), color, 1.6)
			draw_line(center + Vector2(-radius * 0.1, radius * 0.56), center + Vector2(radius * 0.48, -radius * 0.1), color, 1.2)
		3:
			draw_arc(center, radius * 0.54, 0.0, TAU, 20, color, 1.2)
			draw_line(center + Vector2(-radius * 0.46, 0.0), center + Vector2(radius * 0.46, 0.0), color, 1.2)
			draw_line(center + Vector2(0.0, -radius * 0.46), center + Vector2(0.0, radius * 0.46), color, 1.2)
		_:
			draw_circle(center, radius * 0.2, color)
			draw_arc(center, radius * 0.58, -PI * 0.75, PI * 0.25, 20, color, 1.5)
			draw_line(center + Vector2(-radius * 0.3, radius * 0.38), center + Vector2(radius * 0.34, -radius * 0.36), color, 1.5)


func _draw_bottom_hairline(metrics: Dictionary, preset: Dictionary) -> void:
	var y: float = size.y - 60.0
	draw_line(Vector2(36.0, y), Vector2(size.x - 36.0, y), _with_alpha(COLOR_GOLD, 0.14 + float(preset["ornament_alpha"]) * 0.12), 1.0)


func _with_alpha(color: Color, alpha: float) -> Color:
	var result: Color = color
	result.a = alpha
	return result
