extends "rocket_launcher.gd"

const CHARGE_SPEED = 750 * HU

var greatest_velocity_during_air_charge := Vector3.ZERO

var previous_ground_speed := 0.0
var previous_air_speed := 0.0
var previous_air_acceleration := 0.0

func _physics_process(_delta):
	if interval_timer and interval_timer.time_left > 0.0:
		_apply_charge_velocity()

func shoot():
	if interval_timer and interval_timer.time_left > 0.0:
		return
	
	refresh_interval()
	
#	greatest_velocity_during_air_charge = Vector3.ZERO
#	_store_attributes()
	
#	interval_timer.timeout.connect(_restore_attributes)
	sfx.play()
	_apply_charge_velocity()

func _apply_charge_velocity():
	var charge_velocity := Vector3(0, 0, -CHARGE_SPEED).rotated(Vector3.UP, global_rotation.y)
	if player_owner.grounded:
		player_owner.velocity.x = charge_velocity.x
		player_owner.velocity.z = charge_velocity.z
	else:
#		if greatest_velocity_during_air_charge == Vector3.ZERO:
#			greatest_velocity_during_air_charge = charge_velocity
#		var velocity_planar := Vector3(player_owner.velocity.x, 0, player_owner.velocity.z)
#		var current_speed := velocity_planar.length()
#		if current_speed >= greatest_velocity_during_air_charge.length():
#			greatest_velocity_during_air_charge = velocity_planar
#
		player_owner.velocity.x = charge_velocity.x
		player_owner.velocity.z = charge_velocity.z

func _store_attributes():
	previous_ground_speed = player_owner.GROUND_SPEED
	previous_air_speed = player_owner.AIR_SPEED
	previous_air_acceleration = player_owner.AIR_ACCELERATION
	player_owner.GROUND_SPEED = CHARGE_SPEED
	player_owner.AIR_SPEED = CHARGE_SPEED
	player_owner.AIR_ACCELERATION = CHARGE_SPEED * 0.85

func _restore_attributes():
	player_owner.AIR_SPEED = previous_air_speed
	player_owner.GROUND_SPEED = previous_ground_speed
	player_owner.AIR_ACCELERATION = previous_air_acceleration
