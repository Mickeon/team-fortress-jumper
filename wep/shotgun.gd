extends WeaponNode

const BULLET_SPREAD_DISTANCE_FROM_CENTER := 0.05
const BULLET_SPREAD_BASE_OFFSETS = [
	Vector2(-1.0, -1.0) * BULLET_SPREAD_DISTANCE_FROM_CENTER,
	Vector2( 0.0, -1.0) * BULLET_SPREAD_DISTANCE_FROM_CENTER,
	Vector2( 1.0, -1.0) * BULLET_SPREAD_DISTANCE_FROM_CENTER,
	
	Vector2(-1.0,  0.0) * BULLET_SPREAD_DISTANCE_FROM_CENTER,
	Vector2( 0.0,  0.0) * BULLET_SPREAD_DISTANCE_FROM_CENTER,
	Vector2( 1.0,  0.0) * BULLET_SPREAD_DISTANCE_FROM_CENTER,
	
	Vector2(-1.0,  1.0) * BULLET_SPREAD_DISTANCE_FROM_CENTER,
	Vector2( 0.0,  1.0) * BULLET_SPREAD_DISTANCE_FROM_CENTER,
	Vector2( 1.0,  1.0) * BULLET_SPREAD_DISTANCE_FROM_CENTER,
]

signal shot

@export var inaccuracy := deg_to_rad(2.0)


@export var first_person_player: AnimationPlayer
@onready var bullet_trail: GPUParticles3D = $BulletTrail

#func _ready():
#	bullet_trail.emitting = false
#	bullet_trail.one_shot = true


func _shoot():
	sfx.play()
	first_person_player.stop()
	first_person_player.play("shotgun_fire")
	
	for base_offset in BULLET_SPREAD_BASE_OFFSETS:
		_create_bullet(base_offset)
	
	emit_signal("shot")

func _create_bullet(base_offset := Vector2.ZERO):
	var spread := Vector2(randf_range(-inaccuracy, inaccuracy), randf_range(-inaccuracy, inaccuracy))
	var ahead := -global_transform.basis.z.rotated(
			global_transform.basis.y, base_offset.y + spread.y).rotated(
			global_transform.basis.x, base_offset.x + spread.x)
	
	var from := global_position
	var to := from + (ahead * 10000 * HU)
	var query := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, [player_owner])
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	
	var hit_point := to
	if result:
		hit_point = result.position
		var decal: Decal = preload("./BulletDecal.tscn").instantiate()
		_setup_decal(decal, hit_point, result.normal)
		
		player_owner.add_sibling(decal)
	
	var particle_origin := bullet_trail.global_position
	bullet_trail.emit_particle(bullet_trail.global_transform,
			particle_origin.direction_to(hit_point) * max(particle_origin.distance_to(hit_point) * 2, 20),
			Color.WHITE, Color(),
			GPUParticles3D.EMIT_FLAG_POSITION | GPUParticles3D.EMIT_FLAG_VELOCITY)


func _setup_decal(decal: Decal, hit_point: Vector3, normal: Vector3):
	decal.position = hit_point
	if normal.is_equal_approx(Vector3.DOWN):
		decal.basis = decal.basis.rotated(Vector3.RIGHT, PI)
	elif not normal.is_equal_approx(Vector3.UP):
		decal.basis = decal.basis.looking_at(normal)
		decal.transform = decal.transform.rotated_local(Vector3.RIGHT, TAU * -0.25)
	
	decal.get_node("Sparks").one_shot = true
	
	get_tree().create_timer(240).timeout.connect(decal.queue_free)

