extends Node3D

const Rocket = preload("./rocket.gd")

const HU = Player.HU
const SHOOT_OFFSET = Vector3(12.0, -3.0, -23.5) * HU # Vanilla coords: (23.5, 12.0, -3.0)
const SHOOT_OFFSET_CROUCH = Vector3(12.0, 8.0, -23.5) * HU # Vanilla coords: (23.5, 12.0, 8.0)

@export var attack_interval := 0.8
@export_enum("player_primary", "player_secondary")
var trigger_action := "player_primary"

@onready var player_owner: Player = owner
@onready var sfx: AudioStreamPlayer3D = $Shoot
@export var first_person_player: AnimationPlayer

func _unhandled_input(event):
	if event.is_action_pressed(trigger_action):
		shoot()


func shoot():
	if interval_timer and interval_timer.time_left > 0.0:
		return
	
	refresh_interval()
	
	var shoot_offset = SHOOT_OFFSET_CROUCH if player_owner.crouching else SHOOT_OFFSET
	
	var rocket: Rocket = preload("./Rocket.tscn").instantiate()
	setup_projectile(rocket, shoot_offset)
	rocket.source = player_owner
	rocket.add_exception(player_owner)
	owner.add_sibling(rocket)
	
	sfx.play()
	first_person_player.stop()
	first_person_player.play("rocket_launcher_fire")


var interval_timer: SceneTreeTimer
func refresh_interval():
	interval_timer = get_tree().create_timer(attack_interval)
	interval_timer.timeout.connect(func():
			_interval_timeout()
			# When holding down the button, shoot again as soon as possible.
			if Input.is_action_pressed(trigger_action): shoot()
	)

func _interval_timeout():
	pass

func setup_projectile(rocket: Rocket, shoot_offset: Vector3):
	var origin := global_position
	var target := global_transform.translated_local(Vector3.FORWARD * 2000 * HU).origin
	
	# Check for the closest obstruction straight ahead.
	var query := PhysicsRayQueryParameters3D.create(origin, target, 0xFFFFFFFF, [player_owner.get_rid()])
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	
	# When the obstruction is too close, rockets point far into the horizon.
	# Otherwise, you'd often shoot yourself in the face when peeking corners.
	if result and origin.distance_to(result.position) > 200 * HU:
		target = result.position
	
	rocket.position = global_transform.translated_local(shoot_offset).origin
	rocket.look_at_from_position(rocket.position, target)
	
#	DebugDraw3D.draw_line(rocket.position, target, Color.RED, 10.0)
#	DebugDraw3D.draw_sphere(rocket.position, 0.05, Color.BLUE, 10.0)
	pass


func _on_FirstPersonPlayer_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		&"rocket_launcher_fire", &"rocket_launcher_draw":
			first_person_player.play(&"rocket_launcher_idle")

