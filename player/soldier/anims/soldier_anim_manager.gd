@tool
extends AnimationTree


@export var player: Player
@export var model: Node3D

enum Type { PRIMARY, SECONDARY, MELEE }
@export var held_type := Type.PRIMARY:
	set(new):
		if held_type == new:
			return
		
		held_type = new
		
		if Engine.is_editor_hint():
			return # I'd like git not to alarm me, thanks.
		
		if not is_node_ready(): await ready
		
		# TODO: Decouple this shit.
		$"../Body/Rocket Launcher".hide()
		$"../Body/Shotgun".hide()
		$"../Body/Shovel".hide()
		if held_type == Type.PRIMARY:
			$"../Body/Rocket Launcher".show()
		elif held_type == Type.SECONDARY:
			$"../Body/Shotgun".show()
		elif held_type == Type.MELEE:
			$"../Body/Shovel".show()

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
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
	else:
		active = true



func _process(_delta: float) -> void:
	model.rotation.y = player.cam_pivot.rotation.y
	var facing_blend_pos := Vector2(
			0, # remap(player.cam_pivot.rotation.y, -PI / 2, PI / 2, -1, 1),
			remap(player.cam_pivot.rotation.x, -PI / 2, PI / 2, -1, 1))
	set(&"parameters/look_blend/blend_position", facing_blend_pos)

func _physics_process(_delta: float) -> void:
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
	
	if player.just_landed:
		set(&"parameters/jump_land/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	if player.just_jumped and not player.grounded:
		set(&"parameters/jump_start/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	air_crouching = not player.grounded and player.crouching


# These are connected inside the PackedScene.
func _on_any_weapon_shot() -> void:
	set(&"parameters/shoot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _on_any_weapon_deployed(weapon_type: Type) -> void:
	held_type = weapon_type

