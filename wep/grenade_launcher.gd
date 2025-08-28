extends WeaponNode

const Grenade = preload("./other/grenade.gd")

@export var first_person_player: AnimationPlayer


func _deploy():
	first_person_player.play(&"rocket_launcher_draw")

func _shoot():
	var grenade: Grenade = preload("./other/Grenade.tscn").instantiate()
	
	grenade.position = global_position
	grenade.linear_velocity = -global_transform.basis.z * 1216 * HU
	grenade.basis = global_basis
	grenade.source = player_owner
	grenade.angular_velocity = Vector3(randf_range(-20, 20), randf_range(-20, 20), randf_range(-20, 20))
	
	grenade.add_collision_exception_with(player_owner)
	player_owner.add_sibling(grenade, true)
	
	shoot_sfx.play()
	first_person_player.stop()
	first_person_player.play(&"rocket_launcher_fire")

