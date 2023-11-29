extends Node3D


const DEPLOY_TIME = 0.5


@export var primary_weapon: WeaponNode
@export var secondary_weapon: WeaponNode
@export var melee_weapon: WeaponNode

@export var held_weapon: WeaponNode: set = switch_to


@onready var deploy_timer: Timer = $Deploy


func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				switch_to(primary_weapon)
			KEY_2:
				switch_to(secondary_weapon)
			KEY_3:
				switch_to(melee_weapon)


func _ready() -> void:
	deploy_timer.timeout.connect(activate_held_weapon)
	for wep in [primary_weapon, secondary_weapon, melee_weapon]:
		if wep.fp_model:
			wep.fp_model.hide()


func switch_to(wep: WeaponNode):
#	print("From ", held_weapon, " to ", wep)
	if held_weapon == wep:
		return
	
	if held_weapon:
		held_weapon.active = false
		held_weapon.fp_model.hide()
	
	held_weapon = wep
	
	if not is_node_ready(): 
		await ready # At the beginning, the timer isn't quite inside the tree.
	deploy_timer.start(DEPLOY_TIME)
	
	held_weapon.deploy()
	
	# TODO: Decouple this shit EVEN more.
	match held_weapon.name:
		&"RocketLauncher": $"../Soldier/AnimationTree".held_type = 0
		&"Shotgun", &"Shovel": $"../Soldier/AnimationTree".held_type = 1
	

func activate_held_weapon():
	assert(held_weapon)
	held_weapon.active = true

