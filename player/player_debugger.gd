extends Label

const HU = Player.HU
const Explosion = preload("res://wep/explosion.gd")

@export var player: Player
@export var display_meters_as_hu := false
@export var top_down_view := false:
	set(new):
		if top_down_view == new:
			return
		
		top_down_view = new
		
		if top_down_view:
			var cam_pivot = player.cam_pivot
			top_down_camera = Camera3D.new()
			var tw := create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).set_parallel()
			tw.tween_property(top_down_camera, "position:y", 10.0, 0.75).from(cam_pivot.position.y)
			tw.tween_property(top_down_camera, "rotation:x", PI / -2, 0.75).from(cam_pivot.rotation.x)
			
			if not is_node_ready(): await ready
			
			top_down_camera.rotation.y = cam_pivot.rotation.y
			top_down_camera.make_current()
			player.add_child(top_down_camera)
			get_tree().process_frame.connect(_debug_draw)
			
		else:
			top_down_camera.queue_free()
			if not is_node_ready(): await ready
			get_tree().process_frame.disconnect(_debug_draw)
var top_down_camera: Camera3D

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
					player.debug_show_collisions = Explosion.debug_show_radius
				else:
					visible = not visible
			KEY_F4:
				player.debug_allow_bunny_hopping = not player.debug_allow_bunny_hopping
			KEY_F6:
				OS.shell_open("https://github.com/Mickeon/team-fortress-jumper")
			KEY_PAGEDOWN, KEY_PAGEUP:
				var add := -0.1 if key == KEY_PAGEDOWN else 0.1
				Engine.time_scale = clampf(snappedf(Engine.time_scale + add, 0.1), 0.001, 1.0)
	
	if event.is_action_pressed("debug_top_down_view"):
		top_down_view = not top_down_view

func _physics_process(_delta):
	if player:
		update_debug_text()

func _debug_draw():
	var velocity_planar := Vector3(player.velocity.x, 0, player.velocity.z)
	var wish_dir: Vector2 = player.get_meta("wish_dir", Vector2.ZERO)
	DebugDraw3D.draw_arrow_ray(
			player.global_position + Vector3.UP * HU, 
			velocity_planar, 
			velocity_planar.length() * 0.25, 
			Color.DARK_BLUE, velocity_planar.length() * 0.2, true)
	DebugDraw3D.draw_arrow_ray(
			player.global_position + Vector3.UP * HU, 
			Vector3(wish_dir.x, 0, wish_dir.y), 
			wish_dir.length(), 
			Color.DARK_CYAN, 0.25, false)
	
	var capsule = player.capsule
	if capsule.shape is BoxShape3D:
		var shape_size = player.capsule.shape.size
		DebugDraw3D.draw_aabb(AABB(capsule.global_position - shape_size * 0.5, shape_size), Color.YELLOW)
	else:
		var radius: float = capsule.shape.radius
		DebugDraw3D.draw_cylinder(player.global_transform.scaled_local(Vector3(radius, HU, radius)), Color.YELLOW)
	
	top_down_camera.rotation.y = player.cam_pivot.rotation.y


func update_debug_text():
	var new_text := """F6 for controls, F3 to toggle. (%s)
	POS: %9.3v
	ANG: %6.2v
	SPD: %9.4f
	HSP: %9.4f
	"""
	
	new_text %= [
		"Using Hu" if display_meters_as_hu else "Using Meters",
		adjust(player.global_position),
		Vector2(player.cam_pivot.rotation_degrees.x, fmod(player.cam_pivot.rotation_degrees.y, 180.0)),
		adjust(player.velocity.length()),
		adjust(Vector3(player.velocity.x, 0, player.velocity.z).length()),
	]
	if Engine.time_scale != 1.0:
		new_text += "\nTime scale: %s" % Engine.time_scale
	if player.crouching:
		new_text += "\nCROUCHING"
	if not player.grounded:
		new_text += "\nAIRBORNE"
	
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

