extends AnimationTree


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


func _ready():
	active = true

func _physics_process(_delta: float) -> void:
	var cam_pivot := player.cam_pivot
	model.rotation.y = cam_pivot.rotation.y
	
	_handle_animations()
	
	_previously_grounded = player.grounded

func _handle_animations():
	var velocity_planar := Vector2(player.velocity.x, player.velocity.z).rotated(model.rotation.y)
	var player_speed := velocity_planar.length()
	
	if player.grounded:
		if player.crouching:
			var crouch_speed := player.GROUND_SPEED * player.CROUCH_SPEED_MULTIPLIER
			var move_blend_pos = Vector2(velocity_planar.x, -velocity_planar.y) / crouch_speed
			
			set(&"parameters/ground/transition_request", "crouched")
			
			set(&"parameters/move_crouch_blend/blend_position", move_blend_pos)
			set(&"parameters/crouch_walk/blend_amount", player_speed / crouch_speed)
		else:
			var ground_speed := player.GROUND_SPEED
			var move_blend_pos := Vector2(velocity_planar.x, -velocity_planar.y) / ground_speed
			
			set(&"parameters/ground/transition_request", "grounded")
			
			set(&"parameters/move_blend/blend_position", move_blend_pos)
			set(&"parameters/walk/blend_amount", player_speed / ground_speed)
	else:
		set(&"parameters/ground/transition_request", "airborne")
	
	if player._just_landed:
		set(&"parameters/land/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	if player.just_jumped and not player.grounded:
		set(&"parameters/jump_start/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	air_crouching = not player.grounded and player.crouching
	
	
	var facing_blend_pos := Vector2(
#			remap(player.cam_pivot.rotation.y, -PI / 2, PI / 2, -1, 1),
			0,
			remap(player.cam_pivot.rotation.x, -PI / 2, PI / 2, -1, 1))
	set(&"parameters/facing_direction/blend_position", facing_blend_pos)



func _on_RocketLauncher_shot() -> void:
	set(&"parameters/shoot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
