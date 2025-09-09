extends WeaponNode

func _shoot():
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
	# A potential stop-gap with is_new_hit, as provided in the tutorials, is very janky in my opinion.
	# Investigate. Ideally some things should only happen when the server confirms the shot.
	var is_new_hit := false
	if not fire_action.has_context() or Player.is_offline():
		fire_action.set_context(true)
		is_new_hit = true
	#print(fire_action.get_status_string(), " is_new_hit: ", is_new_hit)
	
	var victim := result.collider as Player
	if victim:
		victim.velocity.y += 500 * HU
		victim.grounded = false
		NetworkRollback.mutate(victim)
		if is_new_hit:
			victim.take_damage(20, player_owner)
			$BulletImpactFlesh.play()


func _deploy():
	first_person_player.play(&"shotgun_draw_pump")
