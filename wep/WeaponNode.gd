extends Node3D
class_name WeaponNode

const HU = Player.HU

signal shot

@export var attack_interval := 0.8
@export_enum("player_primary", "player_secondary", "player_charge")
var trigger_action := "player_primary"
var active := false:
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


func _unhandled_input(event):
	if event.is_action_pressed(trigger_action):
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
	_deploy()

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

