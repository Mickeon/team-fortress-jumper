extends RigidBody3D

const Explosion = preload("./explosion.gd")
const GLOW_CURVE = preload("./grenade_glow_curve.tres")

var source: Player
var directly_hit_player: Player

var damage := 100.0

@onready var lifetime: Timer = $Lifetime
@onready var model: CSGMesh3D = $Model
@onready var trail: GPUParticles3D = $Trail

func _ready():
	if get_tree().current_scene == self:
		lifetime.stop()
		add_child(preload("./TestCamera.tscn").instantiate())

func _physics_process(_delta):
	var unit := (lifetime.wait_time - lifetime.time_left) / lifetime.wait_time
	#model.material.albedo_color = Color.WHITE.lerp(Color.CRIMSON, GLOW_CURVE.sample_baked(unit))
	trail.amount_ratio = inverse_lerp(0, 16.0, linear_velocity.length())
	model.set_instance_shader_parameter(&"weight", GLOW_CURVE.sample_baked(unit))

func explode():
	var explosion: Explosion = preload("./Explosion.tscn").instantiate()
	
	explosion.inflictor = source
	explosion.position = global_position
	explosion.directly_hit_player = directly_hit_player
	explosion.base_damage = damage
	explosion.damage_falloff_enabled = false
	explosion.sfx = preload("res://sfx/primary/rocket_blackbox_explode1.ogg")
	
	add_sibling(explosion, true)
	
	queue_free()


func _on_body_entered(body: Node) -> void:
	if body is Player:
		await get_tree().physics_frame # This is stupid but otherwise the explosion does not register
		directly_hit_player = body
		explode()
	else:
		# Cannot directly hit players after one bounce.
		set_deferred("contact_monitor", false)
		
		# TODO: Self-damage should not be affected by this penalty, or at least not as much.
		damage *= 0.6

