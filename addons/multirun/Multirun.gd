@tool
extends EditorPlugin

var panel1
var panel2
var pids = []

func _str_args_to_commands(args:String):
	var commands : PackedStringArray = []
	for arg in args.split(" "):
		commands.append(arg)
	return commands

func _enter_tree():
	var editor_node = get_editor_interface()
	var gui_base = editor_node.get_base_control()
	var icon_transition = gui_base.get_theme_icon("TransitionSync", "EditorIcons") #ToolConnect
	var icon_transition_auto = gui_base.get_theme_icon("TransitionSyncAuto", "EditorIcons")
	var icon_load = gui_base.get_theme_icon("Load", "EditorIcons")

	panel2 = _add_tooblar_button(_loaddir_pressed.bind(), icon_load, icon_load)
	panel1 = _add_tooblar_button(_multirun_pressed.bind(), icon_transition, icon_transition_auto)

	if ProjectSettings.has_setting("debug/multirun/other_window_args"):
		ProjectSettings.set("debug/multirun/other_window_args", null)
	if ProjectSettings.has_setting("debug/multirun/window_distance"):
		ProjectSettings.set("debug/multirun/window_distance", null)
	if ProjectSettings.has_setting("debug/multirun/first_window_args"):
		ProjectSettings.set("debug/multirun/first_window_args", null)

	_add_setting("debug/multirun/number_of_windows", TYPE_INT, 2)
	_add_setting("debug/multirun/add_custom_args", TYPE_BOOL, true)
	_add_setting("debug/multirun/window_args", TYPE_ARRAY, ["listen", "join"], "%d:" % [TYPE_STRING])

func _multirun_pressed():
	var window_count : int = ProjectSettings.get_setting("debug/multirun/number_of_windows")
	var add_custom_args : bool = ProjectSettings.get_setting("debug/multirun/add_custom_args")
	var args : PackedStringArray = ProjectSettings.get_setting("debug/multirun/window_args")
	var first_args : String = ""
	var commands = _str_args_to_commands(args[0]) if add_custom_args && args else []

	first_args = " ".join(commands)

	var main_run_args = ProjectSettings.get_setting("editor/run/main_run_args")
	if main_run_args != first_args:
		ProjectSettings.set_setting("editor/run/main_run_args", first_args)
	var interface = get_editor_interface()
	interface.play_main_scene()
	if main_run_args != first_args:
		ProjectSettings.set_setting("editor/run/main_run_args", main_run_args)

	kill_pids()
	for i in range(1, window_count):
		commands = _str_args_to_commands(args[i]) if add_custom_args && args && i < args.size() else []
		pids.append(OS.create_process(OS.get_executable_path(), commands))

func _start_new_view(commands: PackedStringArray):
	pids.append(OS.create_process(OS.get_executable_path(), commands))

func _loaddir_pressed():
	OS.shell_open(OS.get_user_data_dir())

func _exit_tree():
	_remove_panels()
	kill_pids()

func kill_pids():
	for pid in pids:
		OS.kill(pid)
	pids = []

func _remove_panels():
	if panel1:
		remove_control_from_container(CONTAINER_TOOLBAR, panel1)
		panel1.free()
	if panel2:
		remove_control_from_container(CONTAINER_TOOLBAR, panel2)
		panel2.free()

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_F4:
			_multirun_pressed()

func _add_tooblar_button(action:Callable, icon_normal, icon_pressed):
	var panel = PanelContainer.new()
	var b = TextureButton.new();
	b.texture_normal = icon_normal
	b.texture_pressed = icon_pressed
	b.connect("pressed", action.bind())
	panel.add_child(b)
	add_control_to_container(CONTAINER_TOOLBAR, panel)
	return panel

func _add_setting(thename:String, type, value, hint_str=null):
	if ProjectSettings.has_setting(thename):
		return
	ProjectSettings.set(thename, value)
	var property_info = {
		"name": thename,
		"type": type,
		"hint": PROPERTY_HINT_TYPE_STRING if hint_str != null else null,
		"hint_string": hint_str
	}
	ProjectSettings.add_property_info(property_info)
