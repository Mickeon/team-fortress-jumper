extends Label

const HU = Player.HU
const Explosion = preload("res://wep/explosion.gd")

@export var player: Player
@export var display_meters_as_hu := false

func _input(event):
	var key_event := event as InputEventKey
	if key_event and key_event.pressed:
		var key := key_event.keycode
		match key:
			KEY_F3:
				if key_event.is_command_or_control_pressed():
					display_meters_as_hu = not display_meters_as_hu
				elif key_event.shift_pressed:
					Explosion.debug_show_radius = not Explosion.debug_show_radius
				else:
					visible = not visible
			KEY_PAGEDOWN, KEY_PAGEUP:
				var add := -0.1 if key == KEY_PAGEDOWN else 0.1
				Engine.time_scale = clampf(snappedf(Engine.time_scale + add, 0.1), 0.001, 1.0)

func _physics_process(_delta):
	if player:
		update_debug_text()


func update_debug_text():
	var new_text := """F4 for controls, F3 to toggle. (%s)
	POS: %9.3v
	ANG: %6.2v
	SPD: %9.4f
	HSP: %9.4f
	"""
	
	new_text %= [
		"Using Hu" if display_meters_as_hu else "",
		adjust(player.global_position),
		Vector2(player.cam_pivot.rotation_degrees.x, fmod(player.cam_pivot.rotation_degrees.y, 180.0)),
		adjust(player.velocity.length()),
		adjust(Vector3(player.velocity.x, 0, player.velocity.z).length()),
	]
	if Engine.time_scale != 1.0:
		new_text += "\nTime scale: %s" % Engine.time_scale
	if player.crouching:
		new_text += "\nCROUCHING"
	
	text = new_text


func adjust(value: Variant) -> Variant:
	if display_meters_as_hu:
		return m_to_hu(value)
	return value

static func m_to_hu(value: Variant) -> Variant:
	if value is float:
		return value / HU
	if value is Vector3:
		return Vector3(value.x / HU, value.y / HU, value.z / HU)
	
	return null

