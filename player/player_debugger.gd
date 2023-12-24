extends RichTextLabel

const HU = Player.HU
const Explosion = preload("res://wep/other/explosion.gd")

enum ViewMode { FIRST_PERSON, THIRD_PERSON, FRONT, TOP_DOWN }

const STRING = """[color=gray]F3 to toggle, [color=cyan][url="github"]Click here for controls[/url][/color]. (%s)
POS: %s (%s)
ANG: %s
SPD: %s
HSP: %s
[/color]"""

@export var player: Player
@export var display_meters_as_hu := false
@export var view_mode := ViewMode.FIRST_PERSON:
	set(new):
		if view_mode == new or not player:
			return
		
		view_mode = new
		
		if not is_node_ready(): await ready
		
		if view_mode != ViewMode.FIRST_PERSON:
			
			var cam_pivot = player.cam_pivot
			camera = Camera3D.new()
			
			if view_mode == ViewMode.TOP_DOWN:
				var tw := create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).set_parallel()
				tw.tween_property(camera, "position:y", 10.0, 0.75).from(cam_pivot.position.y)
				tw.tween_property(camera, "rotation:x", PI / -2, 0.75).from(cam_pivot.rotation.x)
			
			camera.set_cull_mask_value(2, false) # Hide First Person model.
			camera.make_current()
			player.add_child(camera)
			if not get_tree().process_frame.is_connected(_debug_draw):
				get_tree().process_frame.connect(_debug_draw, CONNECT_DEFERRED)
		else:
			camera.queue_free()
			get_tree().process_frame.disconnect(_debug_draw)
			player.debug_show_collision_hull = false
var camera: Camera3D
var hovered_meta

#region Overriden Methods
func _ready():
	# Jank needed because the mouse input needs to go through the Label.
	meta_hover_started.connect(func _on_meta_hover_started(meta): hovered_meta = meta)
	meta_hover_ended.connect(func _on_meta_hover_ended(_meta): hovered_meta = null)

func _input(event):
	if hovered_meta and event is InputEventMouseButton and event.is_pressed():
		var url := String(hovered_meta)
		if url.begins_with("github"):
			OS.shell_open("https://github.com/Mickeon/team-fortress-jumper")
			accept_event()
			return
		elif url.begins_with("clipboard:"):
			DisplayServer.clipboard_set(url.trim_prefix("clipboard"))
			accept_event()
	
	var key_event := event as InputEventKey
	if key_event and key_event.pressed:
		var key := key_event.keycode
		match key:
			KEY_F1:
				player.cam_pivot.visible = not player.cam_pivot.visible
			KEY_F3:
				if key_event.is_command_or_control_pressed():
					display_meters_as_hu = not display_meters_as_hu
				elif key_event.shift_pressed:
					Explosion.debug_show_radius = not Explosion.debug_show_radius
					player.debug_show_collisions = Explosion.debug_show_radius
					player.debug_show_bounding_box = Explosion.debug_show_radius
				else:
					visible = not visible
			KEY_F4:
				player.debug_allow_bunny_hopping = not player.debug_allow_bunny_hopping
			KEY_PAGEDOWN, KEY_PAGEUP:
				var mult := 0.5 if key == KEY_PAGEDOWN else 2.0
				Engine.time_scale = clampf(snappedf(Engine.time_scale * mult, 0.015625), 0.001, 1.0)
				update_debug_text()
			KEY_M:
				AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))
				var s := "  🔇"
				var title := get_window().title
				get_window().title = (title + s) if AudioServer.is_bus_mute(0) else title.trim_suffix(s)
	
	if event.is_action_pressed("debug_view_mode"):
		view_mode = (view_mode + 1) % ViewMode.size() as ViewMode

func _physics_process(_delta):
	if player and visible:
		# When slowed down, update less frequently.
		var frequency := maxi(Engine.get_frames_per_second() * (1 - Engine.time_scale), 1)
		if (Engine.get_physics_frames() % frequency) == 0:
			update_debug_text()

func _debug_draw():
	var velocity_planar := Vector3(player.velocity.x, 0, player.velocity.z)
	var wish_dir: Vector2 = player.wish_dir
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
	
	camera.rotation.y = player.cam_pivot.rotation.y
	if view_mode == ViewMode.THIRD_PERSON:
		camera.transform = player.cam_pivot.transform.translated_local(Vector3(0, 0, 2.0))
	elif view_mode == ViewMode.FRONT:
		camera.transform = player.cam_pivot.transform.translated_local(Vector3(0, 0, -2.0)
				).rotated_local(Vector3.UP, PI)
#endregion

func update_debug_text():
	var angles := Vector2(player.cam_pivot.rotation_degrees.x, fmod(player.cam_pivot.rotation_degrees.y, 180.0))
	var velocity_planar := Vector2(player.velocity.x, player.velocity.z)
	var multiplayer_id := multiplayer.get_unique_id()
	var is_server := multiplayer.is_server()
	
	var new_text = STRING % [
		"[color=%s][url=clipboard:%s]%s[/url][/color]" % ["blue" if is_server else "cyan", multiplayer_id, multiplayer_id],
		prettify(adjust(player.global_position)),
		"Using Hu" if display_meters_as_hu else "Using Meters",
		prettify(angles),
		prettify(adjust(player.velocity.length())),
		prettify(adjust(velocity_planar.length())),
	]
	
	#var weapon_manager := player.get_node("WeaponManager")
	#if weapon_manager:
		#new_text += "\n[color=gray]"
		#if weapon_manager.held_weapon:
			#new_text += "Holding %s" % weapon_manager.held_weapon.name
		#if weapon_manager.deploy_timer.time_left > 0.0:
			#new_text += " (Deploying %2.2f)" % weapon_manager.deploy_timer.time_left
		#new_text += "[/color]"
	if Player.main and Player.main.name != str(multiplayer_id):
		new_text += "\n[color=dark_gray]Looking from %s[/color]" % Player.main.name
	
	if Engine.time_scale != 1.0:
		new_text += "\nTime scale: %s" % Engine.time_scale
	if player.debug_allow_bunny_hopping:
		new_text += "\nBunny Hopping Enabled"
	if player.crouching:
		new_text += "\nCROUCHING"
	if not player.grounded:
		new_text += "\nAIRBORNE"
	
	text = new_text

#region Utility Methods
func adjust(value: Variant) -> Variant:
	if display_meters_as_hu:
		return m_to_hu(value)
	return value

static func prettify(value: Variant) -> String:
	if value is Vector3:
		return "([color=pink]%9.3f[/color], [color=lime]%9.3f[/color], [color=light_blue]%9.3f[/color])" % [
				value.x, value.y, value.z]
	elif value is Vector2:
		return "([color=pink]%6.2f[/color], [color=lime]%6.2f[/color])" % [value.x, value.y]
	elif value is float:
		return "[color=white]%9.4f[/color]" % [value]
	
	return str(value)

static func m_to_hu(value: Variant) -> Variant:
	if value is float:
		return value / HU
	if value is Vector3:
		return Vector3(value.x / HU, value.y / HU, value.z / HU)
	
	return null
#endregion
