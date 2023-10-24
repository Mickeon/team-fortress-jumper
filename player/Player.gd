extends CharacterBody3D
class_name Player

## "16 Hammer units = 1 foot"
## "1 Hammer unit is equal to exactly 0.01905 metres."
const HU = 0.01905

const CROUCH_SPEED_MULTIPLIER = 0.333333
const BACKPEDAL_SPEED_MULTIPLIER = 0.9

@export_group("Movement")
@export var GROUND_SPEED := 240 * HU # (Soldier's speed) 
@export var GROUND_ACCELERATION := 2400 * HU # 36 at 66.666 ticks
@export var GROUND_DECELERATION := 400.0 # 6 at 66.666 ticks
@export var AIR_SPEED := 75 * HU#12.0 * HU # Especially noticeable when moving backwards.
@export var AIR_ACCELERATION := 2400 * HU * 0.85 #100.0

@export var JUMP_FORCE := 283 * HU # not 271 * HU. Gravity applies the first frame in the air, too.
@export var GRAVITY_FORCE := 800 * HU # 12 * 66.666
@export var TERMINAL_SPEED := 3500 * HU

@export_range(0, 90, 0.001, "radians")
var MAX_SLOPE_ANGLE := deg_to_rad(46.0): # Should be 45.573 degrees
	set(new): # This is really stupid by the way.
		MAX_SLOPE_ANGLE = new
		floor_max_angle = new 

@export var floor_ray_reach := 18 * HU ## How far down the floor raycast will reach out for collisions.

@export_group("")
@export var camera_sensitivity := 0.075
@export var cam_pivot: Node3D
@export var capsule: CollisionShape3D

@export_group("Debug", "debug_")
@export var debug_simulate_vanilla_tickrate := false
@export var debug_allow_bunny_hopping := false
@export var debug_show_collisions := false
@export var debug_top_down_view := false:
	set(new):
		if debug_top_down_view == new:
			return
		
		debug_top_down_view = new
		
		if debug_top_down_view:
			_debug_top_down_camera = Camera3D.new()
			var tw := create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).set_parallel()
			tw.tween_property(_debug_top_down_camera, "position:y", 10.0, 0.75).from(cam_pivot.position.y)
			tw.tween_property(_debug_top_down_camera, "rotation:x", PI / -2, 0.75).from(cam_pivot.rotation.x)
			
			if not is_node_ready(): await ready
			
			_debug_top_down_camera.rotation.y = cam_pivot.rotation.y
			_debug_top_down_camera.make_current()
			add_child(_debug_top_down_camera)
			get_tree().process_frame.connect(_debug_draw)
			
		else:
			_debug_top_down_camera.queue_free()
			if not is_node_ready(): await ready
			get_tree().process_frame.disconnect(_debug_draw)
var _debug_top_down_camera: Camera3D

var grounded := false
var crouching := false:
	set(new):
		const HEIGHT_BASE = 82 * HU
		const HEIGHT_CROUCH = 62 * HU
		const VIEW_BASE = 68 * HU # Same as Soldier's.
		const VIEW_CROUCH = 45 * HU
		
		if crouching == new:
			return
		
		crouching = new
		
		var height := HEIGHT_CROUCH if crouching else HEIGHT_BASE
		if capsule.shape is BoxShape3D:
			capsule.shape.size.y = height
		else:
			capsule.shape.height = height
			
		capsule.position.y = height * 0.5
		
		cam_pivot.position.y = VIEW_CROUCH if crouching else VIEW_BASE
		
		if not grounded:
			position.y += 27 * HU if crouching else -27 * HU

var noclip_enabled := false:
	set(new):
		noclip_enabled = new
		grounded = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	
	elif event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_handle_camera_rotation(event)
	if event.is_action("player_crouch"):
		crouching = event.is_pressed()
	
	if event.is_action_pressed("debug_noclip"):
		noclip_enabled = not noclip_enabled
	if event.is_action_pressed("debug_top_down_view"):
		debug_top_down_view = not debug_top_down_view

func _physics_process(delta: float):
	if debug_simulate_vanilla_tickrate:
		delta = 0.015 # 1 / 66.666
		
	if _just_landed:
		if debug_allow_bunny_hopping:
			_apply_friction(delta) # Prevent carrying speed from bunny-hopping.
		else:
			_clamp_speed(1.1)
#	DebugDraw3D.draw_sphere(get_global_center(), 0.2, Color.RED, delta)
#	DebugDraw3D.draw_camera_frustum(cam_pivot.get_node("Camera"), Color.VIOLET, delta)
	if noclip_enabled:
		_handle_noclip(delta)
		return
	
	if grounded:
#		var floor_collision := _floor_intersect_ray()
		var floor_collision := _floor_intersect_shape()
		if floor_collision:
#			var slope_angle := get_slope_angle(floor_collision.normal)
			var slope_angle := get_slope_angle(floor_collision.get_normal()) 
			grounded = slope_angle < MAX_SLOPE_ANGLE
		else:
			grounded = false
	
	var wish_dir := Input.get_vector("player_left", "player_right", "player_forward", "player_back")
	wish_dir = wish_dir.rotated(-cam_pivot.rotation.y)
	if debug_top_down_view:
		set_meta("wish_dir", wish_dir)
	
	if grounded and Input.is_action_pressed("player_jump"):
		grounded = false
		velocity.y = JUMP_FORCE
	
	_apply_friction(delta)
	
	if not grounded:
		velocity.y = move_toward(velocity.y, -TERMINAL_SPEED, GRAVITY_FORCE * delta)
	
	# ======== The ACCELERATION part, yippie ========
	var velocity_planar := Vector2(velocity.x, velocity.z)
	
	# This dot is the cause for all the movement tricks in Source games.
	# Good reference for this: https://www.youtube.com/watch?v=v3zT3Z5apaM
	var current_speed := velocity_planar.dot(wish_dir)
	
	var max_speed := GROUND_SPEED if grounded else AIR_SPEED
	var acceleration := GROUND_ACCELERATION if grounded else AIR_ACCELERATION
	if crouching and grounded:
		max_speed = GROUND_SPEED * CROUCH_SPEED_MULTIPLIER
	
	# The magic Source function.
	var add_speed := clampf(max_speed - current_speed, 0.0, acceleration * delta)
	velocity_planar += wish_dir * add_speed
	
	velocity = Vector3(velocity_planar.x, velocity.y, velocity_planar.y)
	# ====================================================
	
	_handle_collision(delta)
	
	if grounded:
		_clamp_speed()
	
	if position.y <= -2000 * HU:
		position = Vector3(0, 100 * HU, 0) # Back to the origin for falling into the void.

func _apply_friction(delta: float):
	if not grounded:
		return
	
	var speed := velocity.length()
	var deceleration := GROUND_DECELERATION * delta
	
	# Stronger friction when speed is greater than 100 HU ("speed * 0.01" penalty)
	speed = move_toward(speed, 0, deceleration * maxf(speed * 0.01, HU))
	
	velocity = velocity.normalized() * speed


var _just_landed := false
func _handle_collision(delta: float):
	_just_landed = false
	
	var has_stepped_up := false
	
	var starting_velocity := velocity * delta
	var remainder := Vector3.ZERO
	var normal := Vector3.ZERO
	for i in 5:
		var collision := move_and_collide(remainder.slide(normal) if normal else starting_velocity)
		if not collision:
			break
		
		var pos := collision.get_position()
		remainder = collision.get_remainder()
		normal = collision.get_normal()
		
		if not grounded:
			var adjusted_normal := normal
#			if adjusted_normal.y > 0.0:
#				adjusted_normal.y *= min(0.1 + velocity.length() * HU * 24, 0.5)#0.3333)
##				print(adjusted_normal.y)
#				adjusted_normal = adjusted_normal.normalized()
			velocity = velocity.slide(adjusted_normal)
		
			var slope_angle := get_slope_angle(normal)
			# At fast speeds, even a gentle slope can launch you.
			if slope_angle < maxf(MAX_SLOPE_ANGLE - velocity.length() * 0.02, 0.01):
				# Give one extra frame of just landed mercy. Vanilla TF2 does this.
				# Allows keeping momentum with perfect bunny-hopping.
				set_deferred("grounded", true)
				_just_landed = true
				velocity.y = 0.0
		else:
			var angle_difference = abs(rad_to_deg(normal.angle_to(up_direction)) - 90.0)
			if angle_difference <= 1.0:
				if _try_to_step_up(pos, remainder):
					has_stepped_up = true
		var debug_color := Color.RED
		debug_color.h += i * 0.1
		
		if debug_show_collisions:
			DebugDraw3D.draw_points([pos], 0.1 - i * 0.02, debug_color, 1)
			DebugDraw3D.draw_ray(pos, normal, 0.5 - i * 0.05, debug_color, 1)
	
	if grounded and not has_stepped_up:
		_snap_to_floor()

func _handle_collision_with_slide(_delta: float): # Unused
	_just_landed = false
	floor_snap_length = 0
	
	move_and_slide()
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		
		var normal := collision.get_normal()
		var angle := collision.get_angle()
		if not grounded:
			if angle < floor_max_angle:
				_just_landed = true
				set_deferred("grounded", true)
				velocity.y = 0.0
		
		var debug_color := Color.RED
		debug_color.h += i * 0.1
		
		DebugDraw3D.draw_points([collision.get_position()], 0.2 - i * 0.02, debug_color, 1)
		DebugDraw3D.draw_ray(collision.get_position(), normal, 0.5 - i * 0.05, debug_color, 1)



func _clamp_speed(multiplier := 1.0):
	var max_speed := GROUND_SPEED * multiplier
	var velocity_planar := Vector2(velocity.x, velocity.z)
	
	if velocity_planar.length() > max_speed:
		var clamped_speed := velocity_planar.length() / max_speed
		velocity_planar /= clamped_speed
		
		velocity.x = velocity_planar.x
		velocity.z = velocity_planar.y
	
	var back_speed := velocity.cross(-cam_pivot.global_transform.basis.x)
	var backpedal_walk_speed := max_speed * BACKPEDAL_SPEED_MULTIPLIER
	if (back_speed.length() > backpedal_walk_speed and back_speed.y < 0.0):
		velocity *= backpedal_walk_speed / back_speed.length()


func _handle_camera_rotation(event: InputEventMouseMotion):
	cam_pivot.rotation.y -= event.relative.x * deg_to_rad(camera_sensitivity)
	cam_pivot.rotation.x -= event.relative.y * deg_to_rad(camera_sensitivity)
	cam_pivot.rotation.x = clampf(cam_pivot.rotation.x, -1.55334 , 1.55334) # 89 degrees up and down.
	
	if debug_top_down_view:
		# The debug camera does not rotate on its own.
		_debug_top_down_camera.rotation.y = cam_pivot.rotation.y

func _handle_noclip(delta: float):
	const NOCLIP_SPEED = 15.0
	const NOCLIP_ACCELERATION = 60
	
	var wish_dir := Input.get_vector("player_left", "player_right", "player_forward", "player_back")
	var flat_acceleration := Vector3(wish_dir.x, 0, wish_dir.y) * GROUND_ACCELERATION * delta
	
	var vertical_acceleration := Input.get_axis("player_crouch", "player_jump")
	if vertical_acceleration:
		velocity.y = move_toward(velocity.y, NOCLIP_SPEED * vertical_acceleration, NOCLIP_ACCELERATION * delta)
	
	if flat_acceleration:
		velocity += cam_pivot.transform.translated_local(flat_acceleration).origin - cam_pivot.position
		velocity = velocity.limit_length(NOCLIP_SPEED)
	elif vertical_acceleration == 0.0:
		velocity = velocity.move_toward(Vector3.ZERO, NOCLIP_ACCELERATION * delta) # Decelerate.
	
	position += velocity * delta


func _floor_intersect_ray() -> Dictionary:
	var origin := global_position
	var target := origin + Vector3.DOWN * floor_ray_reach
	
	if debug_show_collisions:
		DebugDraw3D.draw_arrow_line(origin, target, Color.TOMATO, 1, false, 1)
	
	var query := PhysicsRayQueryParameters3D.create(origin, target, 0xFFFFFFFF, [get_rid()])
	
	return get_world_3d().direct_space_state.intersect_ray(query)

func _floor_intersect_shape() -> KinematicCollision3D:
	return move_and_collide(Vector3.DOWN * floor_ray_reach, true, 0)

func _snap_to_floor():
	var floor_collision := _floor_intersect_shape()
	if not floor_collision:
		return
	
	var target_pos := Vector3(global_position.x, floor_collision.get_position().y, global_position.z)
	if target_pos.y + HU < global_position.y:
		if debug_show_collisions:
			DebugDraw3D.draw_points([target_pos], 0.2, Color.ANTIQUE_WHITE, 1)
		move_and_collide(target_pos - global_position)

func _try_to_step_up(pos: Vector3, remainder: Vector3) -> bool:
	var origin := Vector3(pos.x, global_position.y + floor_ray_reach, pos.z)
	var target := Vector3(pos.x, global_position.y, pos.z)
	
	if debug_show_collisions:
		DebugDraw3D.draw_line(origin, target, Color.MEDIUM_TURQUOISE, 1)

	var query := PhysicsRayQueryParameters3D.create(origin, target, 0xFFFFFFFF, [get_rid()])
	query.hit_from_inside = true
	
	# I assure, Source games do this in a way more complicated way.
	# Trying to replicate it is not worth the effort right now.
	var intersection := get_world_3d().direct_space_state.intersect_ray(query)
	if intersection and intersection.normal != Vector3.ZERO:
		var original_position := position
		position.y = intersection.position.y + HU
		if move_and_collide(remainder, true):
#			print("Trying to step up, but nuh-uh.")
			position = original_position
			return false
		
		move_and_collide(remainder.normalized() * HU)
		return true
	
	return false

func get_slope_angle(normal: Vector3) -> float:
	return normal.angle_to(up_direction)


func get_global_center() -> Vector3:
	var center := capsule.global_position
	if crouching:
		# Pretend the center is further down than it actually is.
		# Makes rocket jumping even stronger. Halved because of the box extents.
		center.y = global_position.y + (55 * HU) * 0.6 # For some reason 0.6 works better now.
	
	return center

func get_height() -> float:
	return capsule.shape.height

func get_width() -> float: # Not used anywhere, actually.
	return capsule.shape.radius


func _debug_draw():
	var velocity_planar := Vector3(velocity.x, 0, velocity.z)
	var wish_dir: Vector2 = get_meta("wish_dir", Vector2.ZERO)
	DebugDraw3D.draw_arrow_ray(
			global_position + Vector3.UP * HU, 
			velocity_planar, 
			velocity_planar.length() * 0.25, 
			Color.DARK_BLUE, velocity_planar.length() * 0.2, true)
	DebugDraw3D.draw_arrow_ray(
			global_position + Vector3.UP * HU, 
			Vector3(wish_dir.x, 0, wish_dir.y), 
			wish_dir.length(), 
			Color.DARK_CYAN, 0.25, false)
	if capsule.shape is BoxShape3D:
		var size = capsule.shape.size
		DebugDraw3D.draw_aabb(AABB(capsule.global_position - size * 0.5, size), Color.YELLOW)
	else:
		var radius: float = capsule.shape.radius
		DebugDraw3D.draw_cylinder(global_transform.scaled_local(Vector3(radius, HU, radius)), Color.YELLOW)


#const JUMP_HEIGHT = 72 * HU
#func _get_jump_force(height: float):
#	return -sqrt(2 * GRAVITY_FORCE * height)    # - ceil(GRAVITY_FORCE * delta)

