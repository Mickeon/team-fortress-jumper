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
				pass


func _ready() -> void:
	deploy_timer.timeout.connect(activate_held_weapon)


func switch_to(wep: WeaponNode):
#	print("From ", held_weapon, " to ", wep)
	if held_weapon == wep:
		return
	
	if held_weapon:
		held_weapon.active = false
	
	held_weapon = wep
	
	if not is_node_ready(): 
		await ready # At the beginning, the timer isn't quite inside the tree.
	deploy_timer.start(DEPLOY_TIME)
	
	# TODO: Decouple this shit.
	if held_weapon.name == "RocketLauncher":
		$"../Smoothing3D/Pivot/FirstPersonModel/Rocket Launcher".show()
		$"../Smoothing3D/Pivot/FirstPersonModel/Shotgun".hide()
		$"../Smoothing3D/Pivot/FirstPersonModel/AnimationPlayer".play("rocket_launcher_draw")
		$"../Soldier/AnimationTree".held_type = 0
	elif held_weapon.name == "Shotgun":
		$"../Smoothing3D/Pivot/FirstPersonModel/Shotgun".show()
		$"../Smoothing3D/Pivot/FirstPersonModel/Rocket Launcher".hide()
		$"../Smoothing3D/Pivot/FirstPersonModel/AnimationPlayer".play("shotgun_draw_no_pump")
		$"../Soldier/AnimationTree".held_type = 1
	

func activate_held_weapon():
	assert(held_weapon)
	held_weapon.active = true

