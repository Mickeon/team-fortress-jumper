extends WeaponNode


const MELEE_RANGE = 96 * HU #48 * HU

@export_range(0, 120, 1, "hide_slider", "or_greater")
var base_damage := 65.0

@export var first_person_player: AnimationPlayer


func _deploy():
	first_person_player.play("shovel_draw")

func _shoot():
	const SWING_ANIMATIONS = [&"shovel_swing_a", &"shovel_swing_b"]
	
	sfx.play()
	first_person_player.stop()
	first_person_player.play(SWING_ANIMATIONS.pick_random())
	
	get_tree().create_timer(0.3).timeout.connect(_create_attack)

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
			_add_decal(preload("./other/BulletDecal.tscn"), hit_point, result.normal)
			$Hit.play()


func _add_decal(decal_scene: PackedScene, hit_point: Vector3, normal: Vector3):
	var decal: Decal = decal_scene.instantiate()
	decal.position = hit_point
	if normal.is_equal_approx(Vector3.DOWN):
		decal.basis = decal.basis.rotated(Vector3.RIGHT, PI)
	elif not normal.is_equal_approx(Vector3.UP):
		decal.basis = decal.basis.looking_at(normal)
		decal.transform = decal.transform.rotated_local(Vector3.RIGHT, TAU * -0.25)
	
	decal.get_node("Sparks").one_shot = true
	player_owner.add_sibling(decal)
	
	get_tree().create_timer(60).timeout.connect(decal.queue_free)


func deal_damage(player: Player):
	var damage := base_damage
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
