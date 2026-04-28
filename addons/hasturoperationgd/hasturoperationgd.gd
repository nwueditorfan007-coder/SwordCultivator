@tool
extends EditorPlugin


var _dock: EditorDock
var _backend: ExecutorBackend


func _enable_plugin() -> void:
	pass


func _disable_plugin() -> void:
	pass


func _enter_tree() -> void:
	HasturOperationGDPluginSettings.register_settings()
	_try_start_local_broker()

	_backend = ExecutorBackend.new()
	add_child(_backend)
	_backend.initialize(self)

	_dock = EditorDock.new()
	_dock.title = "Hastur Executor"
	_dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_UL
	_dock.available_layouts = EditorDock.DOCK_LAYOUT_VERTICAL | EditorDock.DOCK_LAYOUT_FLOATING
	var dock_content = preload("executor_dock.gd").new()
	dock_content.initialize(_backend)
	_dock.add_child(dock_content)
	add_dock(_dock)


func _exit_tree() -> void:
	if _dock:
		remove_dock(_dock)
		_dock.queue_free()
		_dock = null
	if _backend:
		remove_child(_backend)
		_backend.queue_free()
		_backend = null


func _try_start_local_broker() -> void:
	if OS.get_name() != "Windows":
		return

	var broker_script := ProjectSettings.globalize_path("res://tools/start_hastur_broker.ps1")
	if not FileAccess.file_exists(broker_script):
		return

	var powershell := "powershell.exe"
	var pwsh := "C:/Program Files/PowerShell/7/pwsh.exe"
	if FileAccess.file_exists(pwsh):
		powershell = pwsh

	var args := PackedStringArray([
		"-NoProfile",
		"-ExecutionPolicy",
		"Bypass",
		"-File",
		broker_script,
	])
	var pid := OS.create_process(powershell, args, false)
	if pid <= 0:
		push_warning("HasturOperationGD: failed to auto-start local broker with %s" % powershell)
