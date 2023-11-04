extends WeaponNode

const CHARGE_SPEED = 750 * HU

var previous_ground_speed := 0.0
var previous_ground_acceleration := 0.0
var previous_air_speed := 0.0
var previous_air_acceleration := 0.0

@onready var trail: GPUParticles3D = $Trail

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
	
	sfx.play()
	trail.emitting = true

func _ready_to_shoot():
	_restore_attributes()
	trail.emitting = false


func _modify_attributes():
	previous_ground_speed = player_owner.GROUND_SPEED
	previous_ground_acceleration = player_owner.GROUND_ACCELERATION
	previous_air_speed = player_owner.AIR_SPEED
	previous_air_acceleration = player_owner.AIR_ACCELERATION
	
	player_owner.GROUND_SPEED = CHARGE_SPEED
	player_owner.GROUND_ACCELERATION = CHARGE_SPEED * 5
	player_owner.AIR_SPEED = CHARGE_SPEED
	player_owner.AIR_ACCELERATION = CHARGE_SPEED * 2

func _restore_attributes():
	player_owner.forced_wishdir.y = 0.0
	
	player_owner.AIR_SPEED = previous_air_speed
	player_owner.GROUND_SPEED = previous_ground_speed
	player_owner.AIR_ACCELERATION = previous_air_acceleration
