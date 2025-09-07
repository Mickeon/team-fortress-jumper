@icon("res://shared/icons/weapon.png")
extends Node3D
class_name WeaponNode

const HU = Player.HU

signal shot
signal deployed

@export var attack_interval := 0.8
@export var active := false:
	set(new):
		if active == new:
			return
		
		active = new
enum Type { PRIMARY, SECONDARY, MELEE, EQUIPPABLE }
@export var type := Type.PRIMARY

@onready var player_owner: Player = owner
@onready var fp_model: Node3D = get_node_or_null("FPModel")
@onready var tp_model: Node3D = get_node_or_null("TPModel")
@onready var shoot_sfx: AudioStreamPlayer3D = get_node_or_null("Shoot")
@onready var deploy_sfx: AudioStreamPlayer3D = get_node_or_null("Deploy")

var first_person_player: AnimationPlayer

func shoot():
	if not active:
		return
	if player_owner.offline:
		if _interval_timer and _interval_timer.time_left > 0.0:
			return
	else:
		if NetworkTime.seconds_between(_last_shoot_tick, NetworkTime.tick) < attack_interval:
			return
	
	refresh_interval()
	_shoot()
	emit_signal("shot")

@rpc("authority", "call_local", "reliable")
func deploy():
	if fp_model:
		fp_model.show()
	if tp_model:
		tp_model.show()
	if deploy_sfx:
		deploy_sfx.play()
	
	_deploy()
	emit_signal("deployed")

func holster():
	if fp_model:
		fp_model.hide()
	if tp_model:
		tp_model.hide()

var _interval_timer: SceneTreeTimer
var _last_shoot_tick := -1
func refresh_interval():
	if player_owner.offline:
		_interval_timer = get_tree().create_timer(attack_interval, true, true)
		_interval_timer.timeout.connect(_ready_to_shoot)
	else:
		_last_shoot_tick = NetworkTime.tick

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
	var decal: Node3D = decal_scene.instantiate()
	decal.position = hit_point
	if normal.is_equal_approx(Vector3.DOWN):		
		#decal.basis = decal.basis.rotated(Vector3.RIGHT, PI)
		#decal.basis *= Basis(Vector3.RIGHT, Vector3.DOWN, Vector3.FORWARD)
		# In this case, it's equivalent to the above code snippets but faster. 
		decal.basis.y *= -1
		decal.basis.z *= -1
	elif not normal.is_equal_approx(Vector3.UP) and normal != Vector3.ZERO:
		#decal.basis = decal.basis.looking_at(normal)
		decal.look_at_from_position(decal.position, decal.position + normal)
		decal.rotate_object_local(Vector3.RIGHT, TAU * -0.25);
	
	decal.get_node("Sparks").one_shot = true # May not exist, remember to fix.
	player_owner.add_sibling(decal)
	
	get_tree().create_timer(60).timeout.connect(decal.queue_free)
