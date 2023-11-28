extends WeaponNode

const BULLET_SPREAD_DISTANCE_FROM_CENTER := 0.05
const BULLET_SPREAD_BASE_OFFSETS = [
	Vector2( 0.0,  0.0),
	
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

@export_range(0, 120, 1, "hide_slider", "or_greater")
var base_damage := 6.0

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
		if result.collider is Player:
			deal_damage(result.collider)
		else:
			var decal: Decal = preload("./other/BulletDecal.tscn").instantiate()
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
	
	get_tree().create_timer(60).timeout.connect(decal.queue_free)


func deal_damage(player: Player):
	var damage := base_damage
	damage *= get_damage_falloff(player_owner.global_position.distance_to(player.global_position))
	player.take_damage(damage, player_owner)
	
	var multiplier := 0.05#0.2
	var direction := (global_position + Vector3(0, -10 * HU, 0)).direction_to(player.global_position)
	var volume_ratio := 1.49091 if player.crouching else 1.0
	var knockback_force := minf(damage * volume_ratio * multiplier, 1000 * HU)
	var add_velocity := knockback_force * direction
	player.velocity += add_velocity


static func get_damage_falloff(distance: float) -> float:
#	const FALLOFF_CURVE = preload("res://wep/other/falloff_damage_curve_rocket.tres")
#	return FALLOFF_CURVE.sample(unit)
	
	var unit := clampf(remap(distance, 0.0, 1024 * HU, 0.0, 1.0), 0.0, 1.0)
	
	return cubic_interpolate(1.5, 0.5, 0.0, 0.0, unit)


func _on_FirstPersonPlayer_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		&"shotgun_fire", &"shotgun_draw_pump":
			first_person_player.play(&"shotgun_idle")
