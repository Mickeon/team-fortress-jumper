extends Node3D
class_name WeaponNode

const HU = Player.HU

signal shot
signal deployed

@export var attack_interval := 0.8
@export_enum("player_primary", "player_secondary", "player_charge")
var trigger_action := "player_primary"
@export var active := false:
	set(new):
		if active == new:
			return
		
		active = new
		# When holding down the button, shoot again as soon as possible.
		if active and Input.is_action_pressed(trigger_action):
			shoot.rpc()

@onready var player_owner: Player = owner
@onready var sfx: AudioStreamPlayer3D = $Shoot
@onready var fp_model: Node3D = get_node_or_null("Model")
@onready var deploy_sfx: AudioStreamPlayer3D = get_node_or_null("Deploy")


func _unhandled_input(event):
	if event.is_action_pressed(trigger_action):
		# TODO: Try testing rpc_id(1) with this.
		shoot.rpc()

@rpc("authority", "call_local", "reliable")
func shoot():
	if not active or (_interval_timer and _interval_timer.time_left > 0.0):
		return
	
	refresh_interval()
	_shoot()
	emit_signal("shot")

@rpc("authority", "call_local", "reliable")
func deploy():
	if fp_model:
		fp_model.show()
	if deploy_sfx:
		deploy_sfx.play()
	
	_deploy()
	emit_signal("deployed")

func holster():
	if fp_model:
		fp_model.hide()

var _interval_timer: SceneTreeTimer
func refresh_interval():
	_interval_timer = get_tree().create_timer(attack_interval)
	_interval_timer.timeout.connect(func():
			_ready_to_shoot()
			# When holding down the button, shoot again as soon as possible.
			if Input.is_action_pressed(trigger_action): shoot.rpc()
	)

## Overridable. Called when deploying this weapon.
func _deploy():
	pass

## Overridable. Called when using this weapon.
func _shoot():
	pass

## Overridable. Called after shooting, when the weapon is ready to shoot again.
func _ready_to_shoot():
	pass


func add_decal(decal_scene: PackedScene, hit_point: Vector3, normal: Vector3):
	var decal: Decal = decal_scene.instantiate()
	decal.position = hit_point
	if normal.is_equal_approx(Vector3.DOWN):		
		#decal.basis = decal.basis.rotated(Vector3.RIGHT, PI)
		#decal.basis *= Basis(Vector3.RIGHT, Vector3.DOWN, Vector3.FORWARD)
		# In this case, it's equivalent to the above code snippets but faster. 
		decal.basis.y *= -1
		decal.basis.z *= -1
	elif not normal.is_equal_approx(Vector3.UP):
		decal.basis = decal.basis.looking_at(normal)
		decal.transform = decal.transform.rotated_local(Vector3.RIGHT, TAU * -0.25)
	
	decal.get_node("Sparks").one_shot = true # May not exist, remember to fix.
	player_owner.add_sibling(decal)
	
	get_tree().create_timer(60).timeout.connect(decal.queue_free)
