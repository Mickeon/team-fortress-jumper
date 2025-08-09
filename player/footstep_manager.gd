extends AudioStreamPlayer3D

# See also CBasePlayer::SetStepSoundTime, UpdateStepSound.

const BASE_VOLUME := 0.5
const JUMP_VOLUME := 1.0

@onready var player: Player = owner
@onready var step_timer: Timer = $Step

func _physics_process(_delta) -> void:
	if player.just_jumped:
		volume_linear = JUMP_VOLUME
		global_position = player.global_position
		play()
	
	if not step_timer.is_stopped():
		return
	
	if (player.grounded
	and is_moving_fast_enough()):
		volume_linear = BASE_VOLUME * get_volume_multiplier()
		# See CBasePlayer::SetStepSoundTime.
		if is_gentle_step():
			step_timer.start(0.5)
		else:
			# Arbitrary durations for now, as they're seemingly based on the animation.
			step_timer.start(0.5 if player.crouching else 0.45)
		
		global_position = player.global_position
		play()
	

func is_gentle_step() -> bool:
	# Based on thorough testing. Yeah.
	var threshold := player.GROUND_SPEED * 0.8
	if player.crouching:
		threshold = player.GROUND_SPEED * 0.9 * player.CROUCH_SPEED_MULTIPLIER 
	
	if player.velocity.length_squared() >= threshold * threshold:
		return false
	
	return true

func get_volume_multiplier():
	var multiplier := 1.0
	if player.crouching:
		multiplier *= 0.65
	
	if is_gentle_step():
		multiplier *= 0.4
	
	return multiplier


func is_moving_fast_enough() -> bool:
	# Not actually based on CBasePlayer::GetStepSoundVelocities.
	var required_speed := player.GROUND_SPEED * 0.3
	if player.crouching:
		required_speed = player.GROUND_SPEED  * 0.75 * player.CROUCH_SPEED_MULTIPLIER
	
	return player.velocity.length_squared() >= required_speed * required_speed
