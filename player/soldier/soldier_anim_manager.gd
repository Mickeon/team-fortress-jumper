extends AnimationPlayer


@export var player: Player
@export var model: Node3D

var _previously_grounded := false
var air_crouching := false:
	set(new):
		if air_crouching == new:
			return
		
		air_crouching = new
		
		if air_crouching:
			model.position.y -= 27 * player.HU
		else:
			model.position.y += 27 * player.HU
		

func _physics_process(_delta: float) -> void:
	var cam_pivot := player.cam_pivot
	model.rotation.y = cam_pivot.rotation.y
	
	_handle_animations()
	
	_previously_grounded = player.grounded

func _handle_animations():
	# TODO: Replace this with a decent state machine.
	var velocity_planar := Vector2(player.velocity.x, player.velocity.z)
	var player_speed := velocity_planar.length()
	
	if player.grounded:
		if not _previously_grounded:
			play(&"jump_land_PRIMARY")
			air_crouching = false
		
		if player.crouching:
			if player_speed > 0:
				play(&"a_crouch_walk_n_primary", 0.5)
			else:
				play(&"crouch_PRIMARY")
		elif current_animation != &"jump_land_PRIMARY":
			if player_speed > 0:
				play(&"a_run_n_primary")
			else:
				play(&"stand_PRIMARY")
	else:
		if _previously_grounded and not player.grounded:
			play(&"jump_start_PRIMARY")
		elif current_animation != &"jump_start_PRIMARY":
			play(&"jump_float_PRIMARY")
		
		air_crouching = player.crouching

