extends WeaponNode

func _fire():
	super()
	var hit := _raycast_forward()
	if hit.is_empty():
		return # Nothing hit, nothing to do.

	_on_hit(hit)
	
func _raycast_forward() -> Dictionary:
	var ahead := -global_transform.basis.z
	
	var from := global_position
	var to := from + (ahead * 10000 * HU)
	var query := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, [player_owner])
	return get_world_3d().direct_space_state.intersect_ray(query)

func _on_hit(result: Dictionary):
	#print(fire_action.get_status_string(), " first_fire: ", first_fire)
	
	var victim := result.collider as Player
	if victim:
		victim.velocity.y += 500 * HU
		victim.grounded = false
		NetworkRollback.mutate(victim)
		if first_fire:
			victim.take_damage(20, player_owner)
			$BulletImpactFlesh.play()


func _deploy():
	first_person_player.play(&"shotgun_draw_pump")
