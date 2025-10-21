@tool
extends EditorPlugin

var panel_start: PanelContainer
var panel_open_dir: PanelContainer
var pids: Array[int]

func _str_args_to_commands(args: String) -> PackedStringArray:
	var commands := PackedStringArray()
	for arg in args.split(" "):
		commands.append(arg)
	return commands

func _enter_tree():
	var gui_base := EditorInterface.get_base_control()
	var icon_transition := gui_base.get_theme_icon("TransitionSync", "EditorIcons") #ToolConnect
	var icon_transition_auto := gui_base.get_theme_icon("TransitionSyncAuto", "EditorIcons")
	var icon_load := gui_base.get_theme_icon("Load", "EditorIcons")

	panel_open_dir = _add_toolbar_button(_loaddir_pressed.bind(), icon_load, icon_load)
	panel_start = _add_toolbar_button(_multirun_pressed.bind(), icon_transition, icon_transition_auto)

	if ProjectSettings.has_setting("debug/multirun/other_window_args"):
		ProjectSettings.set_setting("debug/multirun/other_window_args", null)
	if ProjectSettings.has_setting("debug/multirun/window_distance"):
		ProjectSettings.set_setting("debug/multirun/window_distance", null)
	if ProjectSettings.has_setting("debug/multirun/first_window_args"):
		ProjectSettings.set_setting("debug/multirun/first_window_args", null)

	_add_setting("debug/multirun/number_of_windows", TYPE_INT, 2)
	_add_setting("debug/multirun/add_custom_args", TYPE_BOOL, true)
	_add_setting("debug/multirun/window_args", TYPE_ARRAY, ["listen", "join"], "%d:" % [TYPE_STRING])

func _multirun_pressed():
	var window_count: int = ProjectSettings.get_setting("debug/multirun/number_of_windows")
	var add_custom_args: bool = ProjectSettings.get_setting("debug/multirun/add_custom_args")
	var args: PackedStringArray = ProjectSettings.get_setting("debug/multirun/window_args", PackedStringArray())
	
	var first_commands := _str_args_to_commands(args[0]) if add_custom_args else []
	var first_args := " ".join(first_commands)
	
	# We can't pass command line arguments directly to the main execution.
	# We set them with project settings, temporarily.
	var main_run_args: String = ProjectSettings.get_setting("editor/run/main_run_args")
	if main_run_args != first_args:
		ProjectSettings.set_setting("editor/run/main_run_args", first_args)
	
	await ProjectSettings.settings_changed # Wait a bit in order to properly register.
	
	EditorInterface.play_main_scene()
	if main_run_args != first_args:
		ProjectSettings.set_setting("editor/run/main_run_args", main_run_args)

	kill_pids()
	for i in range(1, window_count):
		var commands := _str_args_to_commands(args[i]) if add_custom_args and i < args.size() else []
		var pid := OS.create_process(OS.get_executable_path(), commands)
		if pid > 0:
			pids.append(pid)
		else:
			push_error("Multirun couldn't start the application!")

func _loaddir_pressed():
	OS.shell_open(OS.get_user_data_dir())

func _exit_tree():
	_remove_panels()
	kill_pids()

func kill_pids():
	for pid in pids:
		OS.kill(pid)
	pids.clear()

func _remove_panels():
	if panel_start:
		remove_control_from_container(CONTAINER_TOOLBAR, panel_start)
		panel_start.free()
	if panel_open_dir:
		remove_control_from_container(CONTAINER_TOOLBAR, panel_open_dir)
		panel_open_dir.free()

#func _unhandled_input(event):
	#if event is InputEventKey:
		#if event.pressed and event.keycode == KEY_F4:
			#_multirun_pressed()

func _add_toolbar_button(action: Callable, icon_normal: Texture2D, icon_pressed: Texture2D, tooltip := "") -> PanelContainer:
	var panel := PanelContainer.new()
	var button := TextureButton.new()
	button.texture_normal = icon_normal
	button.texture_pressed = icon_pressed
	button.tooltip_text = tooltip
	button.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	button.pressed.connect(action)
	panel.add_child(button)
	add_control_to_container(CONTAINER_TOOLBAR, panel)
	return panel

func _add_setting(the_name: String, type, value, hint_str = null):
	if ProjectSettings.has_setting(the_name):
		return
	
	ProjectSettings.set_setting(the_name, value)
	var property_info = {
		"name": the_name,
		"type": type,
		"hint": PROPERTY_HINT_TYPE_STRING if hint_str != null else null,
		"hint_string": hint_str
	}
	ProjectSettings.add_property_info(property_info)
