extends RichTextLabel

const HU = Player.HU
const Explosion = preload("res://wep/other/explosion.gd")

enum ViewMode { FIRST_PERSON, THIRD_PERSON, FRONT, TOP_DOWN }

const STRING = """[color=gray]F3 to toggle, [color=cyan][url="github"]Click here for controls[/url][/color]. (%s)
POS: %s (%s) %s
ANG: %s
SPD: %s
HSP: %s
[/color]"""

@export var player: Player
@export var display_meters_as_hu := false
@export var display_pos_from_eyes := false
@export var display_collision_radius := false:
	set(new):
		display_collision_radius = new
		Explosion.debug_show_radius = display_collision_radius
		player.debug_show_collisions = display_collision_radius
		player.debug_show_collision_hull = display_collision_radius
@export var view_mode := ViewMode.FIRST_PERSON:
	set(new):
		if view_mode == new or not player:
			return
		
		view_mode = new
		
		if not is_node_ready(): await ready
		
		if view_mode != ViewMode.FIRST_PERSON:
			if camera:
				camera.queue_free()
			camera = Camera3D.new()
			if view_mode == ViewMode.TOP_DOWN:
				var cam_pivot = player.cam_pivot
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
@export var mute := false:
	set(new):
		mute = new
		AudioServer.set_bus_mute(0, mute)
		var s := "  🔇"
		var title := get_window().title
		get_window().title = (title + s) if mute else title.trim_suffix(s)
var camera: Camera3D
var hovered_meta
var menu: DebugPopupMenu

#region Overriden Methods
func _ready():
	# Jank needed because the mouse input needs to go through the Label.
	meta_hover_started.connect(func _on_meta_hover_started(meta): hovered_meta = meta)
	meta_hover_ended.connect(func _on_meta_hover_ended(_meta): hovered_meta = null)
	
	menu = DebugPopupMenu.new()
	menu.index_pressed.connect(_on_menu_index_pressed)
	menu.about_to_popup.connect(_populate_debug_menu)
	get_tree().create_timer(1.0).timeout.connect(_populate_debug_menu)
	add_child(menu)

func _input(event):
	if event.is_pressed() and not event.is_echo():
		if menu.activate_item_by_event(event):
			return
	
	if event.is_action_pressed("debug_menu"):
		#if event is InputEventMouseButton:
			#menu.popup(Rect2(event.position + Vector2.ONE * -48, Vector2.ZERO))
		menu.popup_centered()
		accept_event()
	
	var mouse_button_event := event as InputEventMouseButton
	if mouse_button_event and mouse_button_event.pressed:
		if hovered_meta:
			var url := String(hovered_meta)
			if url.begins_with("github"):
				OS.shell_open("https://github.com/Mickeon/team-fortress-jumper")
				accept_event()
				return
			elif url.begins_with("clipboard:"):
				DisplayServer.clipboard_set(url.trim_prefix("clipboard:"))
				accept_event()
	
	var key_event := event as InputEventKey
	if key_event and key_event.pressed:
		var key := key_event.keycode
		match key:
			KEY_PAGEDOWN, KEY_PAGEUP:
				var mult := 0.5 if key == KEY_PAGEDOWN else 2.0
				Engine.time_scale = clampf(snappedf(Engine.time_scale * mult, 0.015625), 0.001, 1.0)
				update_debug_text()
			KEY_K:
				player.cam_pivot.rotation.x = -1.55334 if key_event.shift_pressed else 0.0
				player.cam_pivot.rotation.y = PI

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
	var angles := Vector2(player.cam_pivot.rotation_degrees.x, player.cam_pivot.rotation_degrees.y)
	var pos := player.cam_pivot.global_position if display_pos_from_eyes else player.global_position
	var velocity_planar := Vector2(player.velocity.x, player.velocity.z)
	var multiplayer_id := multiplayer.get_unique_id()
	var is_server := multiplayer.is_server()
	
	var new_text = STRING % [
		"[color=%s][url=clipboard:%s]%s[/url][/color]" % ["blue" if is_server else "cyan", multiplayer_id, multiplayer_id],
		prettify(adjust(pos)),
		"Using Hu" if display_meters_as_hu else "Using Meters",
		"(eyes)" if display_pos_from_eyes else "",
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
	if Player.local and Player.local.name != str(multiplayer_id):
		new_text += "\n[color=dark_gray]Looking from %s[/color]" % Player.local.name
	
	if Engine.time_scale != 1.0:
		new_text += "\nTime scale: %s" % Engine.time_scale
	if player.debug_allow_bunny_hopping:
		new_text += "\nBunny Hopping Enabled"
	if player.crouched:
		new_text += "\nCROUCHED"
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


#region Debug Menu
@warning_ignore_start("int_as_enum_without_cast", "int_as_enum_without_match")
func _populate_debug_menu():
	if menu.item_count > 0:
		return # Already populated.
	
	menu_add_multistate_for_property(self, "view_mode", KEY_NONE, ViewMode.size())
	menu.set_item_shortcut(-1, shortcut_from_action("debug_view_mode"))
	
	menu_add_checkable_for_property(self, "visible", KEY_F3)
	menu_add_checkable_for_property(self, "display_meters_as_hu", KEY_F3 | KEY_MASK_CTRL)
	menu_add_checkable_for_property(self, "display_pos_from_eyes", KEY_F3 | KEY_MASK_ALT)
	menu_add_checkable_for_property(self, "display_collision_radius", KEY_F3 | KEY_MASK_SHIFT)
	menu_add_checkable_for_property(self, "mute", KEY_M)
	
	menu_add_checkable_for_property(player, "cam_pivot:visible", KEY_F1)
	menu_add_checkable_for_property(player, "debug_allow_bunny_hopping", KEY_F4)
	menu_add_checkable_for_property(player, "noclip_enabled", KEY_NONE)
	menu.set_item_shortcut(-1, shortcut_from_action("debug_noclip"))

func _on_menu_index_pressed(index: int):
	var metadata = menu.get_item_metadata(index)
	if metadata is not Callable:
		return
	
	var result = metadata.call()
	if result is bool:
		menu.set_item_checked(index, result)
	elif result is int:
		menu.set_item_multistate(index, result)

func menu_add_item(item_name: String, action_name_or_key: Variant, function: Callable):
	menu.add_item(item_name)
	if action_name_or_key is int:
		menu.set_item_accelerator(-1, action_name_or_key)
	elif action_name_or_key is String:
		var shortcut := Shortcut.new()
		shortcut.events = InputMap.action_get_events(action_name_or_key)
		menu.set_item_shortcut(-1, shortcut)
	
	menu.set_item_metadata(-1, function)

func menu_add_multistate_for_property(object: Object, property_path: NodePath, accel: Key, max_states: int):
	var property_value = object.get_indexed(property_path)
	assert(property_value is int)
	
	menu.add_multistate_item(property_path, max_states, property_value, -1, accel)
	menu.set_item_metadata(-1, func():
		object.set_indexed(property_path, (object.get_indexed(property_path) + 1) % max_states)
		return object.get_indexed(property_path)
	)

func menu_add_checkable_for_property(object: Object, property_path: NodePath, accel: Key):
	var property_value = object.get_indexed(property_path)
	assert(property_value is bool)
	
	menu.add_check_item(property_path, -1, accel)
	menu.set_item_checked(-1, property_value)
	menu.set_item_metadata(-1, func():
		object.set_indexed(property_path, not object.get_indexed(property_path))
		return object.get_indexed(property_path)
	)
@warning_ignore_restore("int_as_enum_without_cast", "int_as_enum_without_match")

static func shortcut_from_action(action_name: StringName) -> Shortcut:
	var shortcut := Shortcut.new()
	shortcut.events = InputMap.action_get_events(action_name)
	return shortcut

class DebugPopupMenu extends PopupMenu:
	var last_focused_item_id := 0
	var mouse_mode_before_opening := Input.MOUSE_MODE_VISIBLE
	func _ready() -> void:
		hide_on_checkable_item_selection = false
		hide_on_item_selection = false
		
		about_to_popup.connect(func(): 
			set_focused_item(last_focused_item_id)
			mouse_mode_before_opening = Input.mouse_mode
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		)
		id_focused.connect(func(id): last_focused_item_id = id)
		mouse_exited.connect(hide)
		popup_hide.connect(func(): Input.mouse_mode = mouse_mode_before_opening)
	
	func _input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_focus_next", true, true):
			set_focused_item(posmod(get_focused_item() + 1, item_count))
			set_input_as_handled()
		elif event.is_action_pressed("ui_focus_prev", true, true):
			set_focused_item(posmod(get_focused_item() - 1, item_count))
			set_input_as_handled()
		elif event.is_action_pressed("debug_menu"):
			hide()
			set_input_as_handled()
#endregion
