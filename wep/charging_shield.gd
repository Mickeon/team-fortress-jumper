extends WeaponNode

# FIXME: Charging Shield can no longer be "shot" due to netcode changes.

const CHARGE_SPEED = 750 * HU

var previous_ground_speed := 0.0
var previous_ground_acceleration := 0.0
var previous_air_speed := 0.0
var previous_air_acceleration := 0.0

@export var trail: GPUParticles3D

func _ready():
	trail.emitting = false

func _shoot():
	_modify_attributes()
	player_owner.forced_wishdir.y = -1
	if not player_owner.grounded:
		var velocity_planar = Vector2(player_owner.velocity.x, player_owner.velocity.z)
		if velocity_planar.length() <= CHARGE_SPEED:
			var charge_velocity := Vector3(0, 0, CHARGE_SPEED * -0.75).rotated(Vector3.UP, global_rotation.y)
			player_owner.velocity.x = charge_velocity.x
			player_owner.velocity.z = charge_velocity.z
	
	shoot_sfx.play()
	trail.emitting = true

func _ready_to_shoot():
	_restore_attributes()
	trail.emitting = false


func _modify_attributes():
	previous_ground_speed = player_owner.ground_speed
	previous_ground_acceleration = player_owner.ground_acceleration
	previous_air_speed = player_owner.air_speed
	previous_air_acceleration = player_owner.air_acceleration
	
	player_owner.ground_speed = CHARGE_SPEED
	player_owner.ground_acceleration = CHARGE_SPEED * 5
	player_owner.air_speed = CHARGE_SPEED
	player_owner.air_acceleration = CHARGE_SPEED * 2

func _restore_attributes():
	player_owner.forced_wishdir.y = 0.0
	
	player_owner.air_speed = previous_air_speed
	player_owner.ground_speed = previous_ground_speed
	player_owner.air_acceleration = previous_air_acceleration
