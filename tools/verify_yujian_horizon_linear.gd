extends SceneTree

const SCENE_PATH := "res://scenes/prototypes/YujianSpriteSequencePrototype.tscn"
const EPSILON := 0.001

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
	var response := float(root.get("海平线纵向响应"))
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
	return float(root.call("_get_sea_horizon_y"))


func _expect_close(label: String, actual: float, expected: float) -> void:
	if absf(actual - expected) > EPSILON:
		_fail("%s expected %.5f got %.5f" % [label, expected, actual])


func _expect_less(label: String, actual: float, limit: float) -> void:
	if not actual < limit:
		_fail("%s expected %.5f to be less than %.5f" % [label, actual, limit])


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
	var x0 := float(root.call("_background_screen_x", start_pos.x, 0.70))
	var x1 := float(root.call("_background_screen_x", start_pos.x + 1200.0, 0.70))
	return x1 - x0


func _fail(message: String) -> void:
	had_failure = true
	push_error(message)
