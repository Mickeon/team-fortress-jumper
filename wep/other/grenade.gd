extends RigidBody3D

const GLOW_CURVE := preload("./grenade_glow_curve.tres")

var source: Player
var directly_hit_player: Player

@onready var lifetime: Timer = $Lifetime
@onready var model: CSGMesh3D = $Model

func _ready():
	if get_tree().current_scene == self:
		lifetime.stop()
		add_child(preload("./TestCamera.tscn").instantiate())

func _physics_process(_delta):
	var unit := (lifetime.wait_time - lifetime.time_left) / lifetime.wait_time
	model.material.albedo_color = Color.WHITE.lerp(
		Color.CRIMSON, GLOW_CURVE.sample_baked(unit))

func explode():
	var explosion: Area3D = preload("./Explosion.tscn").instantiate()
	
	explosion.inflictor = source
	explosion.position = global_position
	explosion.directly_hit_player = directly_hit_player
	
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
