extends WeaponNode


const MELEE_RANGE = 96 * HU #48 * HU
const SWING_DELAY = 0.25

@export_range(0, 120, 1, "hide_slider", "or_greater")
var base_damage := 65.0

@export var first_person_player: AnimationPlayer


func _deploy():
	first_person_player.play(&"shovel_draw")

func _shoot():
	const SWING_ANIMATIONS = [&"shovel_swing_a", &"shovel_swing_b"]
	
	sfx.play()
	first_person_player.stop()
	first_person_player.play(SWING_ANIMATIONS.pick_random())
	
	create_tween().tween_callback(_create_attack).set_delay(SWING_DELAY)

func _create_attack():
	var ahead := -global_transform.basis.z
	
	var from := global_position
	var to := from + (ahead * MELEE_RANGE)
	var query := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, [player_owner])
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	
	var hit_point := to
	if result:
		hit_point = result.position
		if result.collider is Player:
			deal_damage(result.collider)
			$Hurt.play()
		else:
			add_decal(preload("./other/BulletDecal.tscn"), hit_point, result.normal)
			$Hit.play()


func deal_damage(player: Player):
	var damage := base_damage
	if player_owner.rocket_jumping:
		damage *= 3 # Behave more like the Market Gardener.
		$Crit.play()
	player.take_damage(damage, player_owner)
	
	var multiplier := 0.05#0.2
	var direction := (global_position + Vector3(0, -10 * HU, 0)).direction_to(player.global_position)
	var volume_ratio := 1.49091 if player.crouching else 1.0
	var knockback_force := minf(damage * volume_ratio * multiplier, 1000 * HU)
	var add_velocity := knockback_force * direction
	player.velocity += add_velocity


func _on_FirstPersonPlayer_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		&"shovel_swing_a", &"shovel_swing_b", &"shovel_draw":
			first_person_player.play(&"shovel_idle")

