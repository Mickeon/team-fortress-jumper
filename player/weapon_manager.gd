@icon("res://shared/icons/tf.png")
extends Node3D


const DEPLOY_TIME = 0.5

@export var tp: Node3D
@export var fp: Node3D

@export var primary_weapon: WeaponNode
@export var secondary_weapon: WeaponNode
@export var melee_weapon: WeaponNode

@export var held_weapon: WeaponNode: set = switch_to


@onready var deploy_timer: Timer = $Deploy

var firing_primary := false
#var firing_secondary := false
#var firing_charge := false
func _unhandled_input(event: InputEvent):
	if not is_multiplayer_authority():
		return
	
	if event.is_action_pressed("player_switch_to_primary"):
		switch_to_by_path.rpc(primary_weapon.get_path())
	elif event.is_action_pressed("player_switch_to_secondary"):
		switch_to_by_path.rpc(secondary_weapon.get_path())
	elif event.is_action_pressed("player_switch_to_melee"):
		switch_to_by_path.rpc(melee_weapon.get_path())
	
	if event.is_action("player_primary"):
		firing_primary = event.is_pressed()
	#if event.is_action("player_secondary"):
		#firing_secondary = event.is_pressed()
	#if event.is_action("player_charge"):
		#firing_charge = event.is_pressed()
	
	# Additional weapons for further, funny testing.
	if event is InputEventKey:
		match event.keycode:
			KEY_4:
				switch_to_by_path.rpc("GrenadeLauncher")

func _ready() -> void:
	NetworkTime.before_tick_loop.connect(_gather)
	
	deploy_timer.timeout.connect(activate_held_weapon)
	
	var fp_anim_player: AnimationPlayer = fp.get_node("AnimationPlayer")
	var tp_anim_tree: AnimationTree = tp.get_node("AnimationTree")
	for wep: WeaponNode in get_weapons():
		wep.holster()
		if wep.fp_model:
			_prepare_weapon_model(wep.fp_model, true)
		if wep.tp_model:
			_prepare_weapon_model(wep.tp_model, false)
		
		wep.first_person_player = fp_anim_player
		# Bleh. Why do we "inject" first_player_player to the weapons but not the third person one?
		if wep.type != WeaponNode.Type.EQUIPPABLE:
			wep.deployed.connect(tp_anim_tree._on_any_weapon_deployed.bind(wep.type))
			wep.shot.connect(tp_anim_tree._on_any_weapon_shot)

func _physics_process(_delta) -> void:
	_gather()

func _gather() -> void:
	if firing_primary:
		held_weapon.shoot()

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
		held_weapon.holster()
	
	held_weapon = wep
	
	if not is_node_ready(): 
		await ready # At the beginning, the timer isn't quite inside the tree.
	deploy_timer.start(DEPLOY_TIME)
	
	if held_weapon:
		held_weapon.deploy()
	else:
		printerr("Switched to holding no weapon!")
	

func activate_held_weapon():
	assert(held_weapon)
	held_weapon.active = true


func get_weapons() -> Array[WeaponNode]:
	var result: Array[WeaponNode]
	result.assign(get_children().filter(func(child): return child is WeaponNode))
	return result


func _prepare_weapon_model(model: Node3D, for_first_person := false):
	# Nasty assumptions galore.
	assert(model.get_child_count() > 0)
	assert(model.get_child(0).get_child(0) is MeshInstance3D)
	
	var root_person: Node3D = (fp if for_first_person else tp)
	var skeleton_node: Skeleton3D = (fp.get_node("FPSkeleton") if for_first_person else tp.get_node("TPSkeleton"))
	var mesh_instance: MeshInstance3D = model.get_child(0).get_child(0)
	
	mesh_instance.skeleton = ""; # Prevent an error before reparenting.
	model.reparent(root_person, false)
	mesh_instance.skeleton = mesh_instance.get_path_to(skeleton_node)
	
	if not for_first_person:
		model.rotation.y += PI # TPSkeleton is flipped, too.
	
	# Missing bones cause errors. Void the invalid binds.
	var skin: Skin = mesh_instance.skin.duplicate()
	mesh_instance.skin = skin
	for bind in skin.get_bind_count():
		if skeleton_node.find_bone(skin.get_bind_name(bind)) == -1:
			# FIXME: This is not right for the Shovel.
			skin.set_bind_name(bind, "")
			skin.set_bind_bone(bind, 2)
