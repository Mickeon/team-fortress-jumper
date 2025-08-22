extends RayCast3D

const Explosion = preload("./explosion.gd")

@export var speed = 1100 * Player.HU

var source: Player

func _ready():
	if get_tree().current_scene == self:
		$Lifetime.stop()
		add_child(preload("./TestCamera.tscn").instantiate())
	
#	hit_from_inside = true
#	set_deferred("hit_from_inside", false)
	# HACK: The code above should've prevented rockets from going through close geometry, but it does not.
	# Alternatively, we push the rocket back, then move it forward to update the raycast at the beginning.
	target_position.z = -speed * get_physics_process_delta_time()
	translate_object_local(-target_position)
	
	# The rocket's model is not is visible for few split seconds, likely not to cover your face.
	$Model.hide()
	get_tree().create_timer(0.05).timeout.connect($Model.show)

func _physics_process(delta):
	if is_colliding():
		# Pull back a bit. Vanilla does this (CTFBaseRocket::Explode).
		global_position = get_collision_point() + get_collision_normal() * Player.HU
		explode()
		return
	
	target_position.z = -speed * delta
	translate_object_local(target_position)


func explode():
	var explosion: Explosion = preload("./Explosion.tscn").instantiate()
	
	explosion.inflictor = source
	explosion.position = global_position
	explosion.directly_hit_player = get_collider() as Player
	# Tansform mumbo jumbo, to ensure the blast node is looking AWAY from the point of impact.
	var normal := get_collision_normal()
	if normal.is_equal_approx(Vector3.DOWN):
		explosion.rotation.x += PI
	elif not normal.is_equal_approx(Vector3.UP) and normal != Vector3.ZERO:
		explosion.look_at_from_position(position, position + normal)
		explosion.rotate_object_local(Vector3.RIGHT, TAU * -0.25);
	
	add_sibling(explosion, true)
	
	queue_free()

func _exit_tree():
	var trail: GPUParticles3D = $Trail
	
	trail.emitting = false
	remove_child(trail)
	get_parent().add_child.call_deferred(trail)
	get_tree().create_timer(1).timeout.connect(trail.queue_free)

