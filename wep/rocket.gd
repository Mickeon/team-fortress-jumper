extends RayCast3D

# "16 Hammer units = 1 foot"
# "1 Hammer unit is equal to exactly 0.01905 metres."

# Should actually be 1100 Hu, or 20.955 m
@export var speed = 12.5

var source: Player

func _ready():
	if get_tree().current_scene == self:
		$Lifetime.stop()
	
	target_position.z = -speed * get_physics_process_delta_time()
	translate_object_local(-target_position * 1)
#	translate_object_local(target_position * 4)
#	hit_from_inside = true
#	set_deferred("hit_from_inside", false)

func _physics_process(delta):
	if is_colliding():
		global_position = get_collision_point()
		explode()
		return
	
	target_position.z = -speed * delta
	translate_object_local(target_position)


func explode():
	var explosion: Node3D = preload("res://wep/Explosion.tscn").instantiate()
	
	explosion.source = source
	explosion.position = global_position
	var normal := get_collision_normal()
	if normal.is_equal_approx(Vector3.DOWN):
		explosion.rotation.x += PI
	elif not normal.is_equal_approx(Vector3.UP):
		explosion.look_at_from_position(position, position + normal, Vector3.UP)
		explosion.transform = explosion.transform.rotated_local(Vector3.RIGHT, TAU * -0.25)
	
	add_sibling(explosion)
	
	queue_free()

