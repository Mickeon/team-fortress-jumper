extends Node3D

const YAW_LIMIT = 1.55334 # 89 degrees up and down.

@export_range(0, 1, 0.001, "radians_as_degrees") var sensitivity := deg_to_rad(0.075)
var height_offset := 68 * Player.HU

@onready var camera: Camera3D = $Camera

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			_handle_camera_rotation(event)
		elif event.is_action_pressed("ui_cancel"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_viewport().set_input_as_handled()
	
	elif (event is InputEventMouseButton
	and event.button_index != MOUSE_BUTTON_WHEEL_UP
	and event.button_index != MOUSE_BUTTON_WHEEL_DOWN
	and event.is_pressed()):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	

func _handle_camera_rotation(event: InputEventMouseMotion):
	rotation.y = wrapf(rotation.y - event.relative.x * sensitivity, -PI, PI)
	rotation.x = clampf(rotation.x - event.relative.y * sensitivity, -YAW_LIMIT, YAW_LIMIT)

func _process(_delta: float) -> void:
	global_position = get_parent_node_3d().get_global_transform_interpolated().origin + Vector3(0.0, height_offset, 0.0)
