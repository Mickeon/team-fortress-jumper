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
				switch_to_by_path.rpc(primary_weapon.get_path())
			KEY_2:
				switch_to_by_path.rpc(secondary_weapon.get_path())
			KEY_3:
				switch_to_by_path.rpc(melee_weapon.get_path())


func _ready() -> void:
	deploy_timer.timeout.connect(activate_held_weapon)
	for wep in [primary_weapon, secondary_weapon, melee_weapon]:
		if wep.fp_model:
			wep.fp_model.hide()

# You cannot pass a whole Object remotely, hence why this exists.
@rpc("authority", "call_local", "reliable")
func switch_to_by_path(path: NodePath):
	switch_to(get_node(path))

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
	
	if held_weapon:
		held_weapon.deploy()
		
		# TODO: Decouple this shit EVEN more.
		match held_weapon.name:
			&"RocketLauncher": $"../Soldier/AnimationTree".held_type = 0
			&"Shotgun": $"../Soldier/AnimationTree".held_type = 1
			&"Shovel": $"../Soldier/AnimationTree".held_type = 2
	

func activate_held_weapon():
	assert(held_weapon)
	held_weapon.active = true
