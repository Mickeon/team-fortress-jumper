extends Node3D
class_name WeaponNode

const HU = Player.HU

@export var attack_interval := 0.8
@export_enum("player_primary", "player_secondary", "player_charge")
var trigger_action := "player_primary"

@onready var player_owner: Player = owner
@onready var sfx: AudioStreamPlayer3D = $Shoot


func _unhandled_input(event):
	if event.is_action_pressed(trigger_action):
		shoot()

func shoot():
	if _interval_timer and _interval_timer.time_left > 0.0:
		return
	
	refresh_interval()
	_shoot()

var _interval_timer: SceneTreeTimer
func refresh_interval():
	_interval_timer = get_tree().create_timer(attack_interval)
	_interval_timer.timeout.connect(func():
			_ready_to_shoot()
			# When holding down the button, shoot again as soon as possible.
			if Input.is_action_pressed(trigger_action): shoot()
	)


## Overridable. Called when using this weapon.
func _shoot():
	pass

## Overridable. Called when the weapon is ready to shoot again.
func _ready_to_shoot():
	pass

