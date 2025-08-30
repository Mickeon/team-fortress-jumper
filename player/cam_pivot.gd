extends Node3D

const YAW_LIMIT = 1.55334 # 89 degrees up and down.

@export var camera_sensitivity := 0.075

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	
	elif (event is InputEventMouseButton 
	and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	and event.button_index != MOUSE_BUTTON_WHEEL_UP
	and event.button_index != MOUSE_BUTTON_WHEEL_DOWN
	and event.is_pressed()):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	
	elif event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_handle_camera_rotation(event)

func _handle_camera_rotation(event: InputEventMouseMotion):
	rotation.y = wrapf(rotation.y - event.relative.x * deg_to_rad(camera_sensitivity), -PI, PI)
	rotation.x = clampf(rotation.x - event.relative.y * deg_to_rad(camera_sensitivity), -YAW_LIMIT, YAW_LIMIT)
