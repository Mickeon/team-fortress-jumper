extends Node

const PlayerScene := preload("res://player/Player.tscn")

const PORT = 8002
const SERVER_ADDRESS = "localhost"
const SERVER_ID = 1

func _input(event):
	if event.is_action_pressed("debug_spawn_fake_player"):
		spawn_player(randi_range(2, 100))

func _ready() -> void:
	var args := OS.get_cmdline_args()
	
	if args.has("listen"):
		await _host()
	
	elif args.has("join"):
		await _connect()
	
	multiplayer.peer_connected.connect(spawn_player)
	multiplayer.peer_disconnected.connect(remove_player)
	multiplayer.server_disconnected.connect(get_tree().quit)
	
	spawn_player(multiplayer.get_unique_id())
	$PlayerDebugger.player = get_node(str(multiplayer.get_unique_id()))


func _host():
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT)
	if err:
		printerr("Could not create server: ", error_string(err))
	else:
		print("Hosting server at port ", PORT)
		multiplayer.multiplayer_peer = peer
	
	get_window().title = "Team Fortress Jumper (Hosting)"

func _connect():
	await get_tree().create_timer(0.5).timeout
	
	var peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(SERVER_ADDRESS, PORT)
	if err:
		printerr("Could not connect to server at ", SERVER_ADDRESS, ":", PORT, " ", error_string(err))
	else:
		print("Successfully connected to server at ", SERVER_ADDRESS, ":", PORT)
		multiplayer.multiplayer_peer = peer
	
	get_window().title = "Team Fortress Jumper (Listening)"
	get_window().size *= 0.75


func spawn_player(id: int):
	var player: Player = PlayerScene.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	
	add_child(player, true)
	if id != multiplayer.get_unique_id():
		tweak_other(player)
	if id == SERVER_ID:
		tweak_server(player)
	else:
		tweak_client(player)

func remove_player(id: int):
	get_node(str(id)).queue_free()


func tweak_other(player: Player):
	# Disable input.
	player.propagate_call("set_process_input", [false])
	player.propagate_call("set_process_unhandled_input", [false])
	
	player.cam_pivot.get_node("Camera").queue_free()
	player.cam_pivot.get_node("FirstPersonModel").hide()
	
	# Show TP model all the time.
	for mesh in [
		player.get_node("Soldier/Body/Skeleton3D/mesh"),
		player.get_node("Soldier/Body/Rocket Launcher/c_rocketlauncher_qc_skeleton/Skeleton3D/c_rocketlauncher"),
		player.get_node("Soldier/Body/Shotgun/c_shotgun_skeleton/Skeleton3D/c_shotgun")
	]: 
		mesh.layers = 6
	
	player.hurt.connect(_on_player_hurt.bind(player))

func tweak_server(player: Player):
	player.cam_pivot.rotation.y += PI

func tweak_client(player: Player):
	# All clients are colored BLU.
	const BLU_COAT = preload("res://player/soldier/mat/coat_mat_blu.tres")
	const BLU_SLEEVES = preload("res://player/soldier/mat/sleeves_mat_blu.tres")
	
	var body_mesh := player.get_node("Soldier/Body/Skeleton3D/mesh")
	body_mesh.set("surface_material_override/0", BLU_COAT)
	
	var fp_mesh := player.cam_pivot.get_node("FirstPersonModel/Arms/Skeleton3D/mesh")
	fp_mesh.set("surface_material_override/1", BLU_SLEEVES)
	
	# All clients are shifted ahead on spawn
	player.position.z += 5


var _queued_damage_numbers := {} # { Player: float }
func _on_player_hurt(amount: float, inflictor: Player, player: Player):
	if inflictor == player:
		return # Don't care about self-inflicted damage.
	
	if not _queued_damage_numbers.has(player):
		create_damage_label.call_deferred(player)
		_queued_damage_numbers[player] = amount
	else:
		_queued_damage_numbers[player] += amount
	
func create_damage_label(for_player: Player):
	const DamageNumberScene := preload("res://wep/other/DamageNumber.tscn")
	var damage_label: Label3D = DamageNumberScene.instantiate()
	damage_label.damage = _queued_damage_numbers[for_player]
	damage_label.position = for_player.position
	damage_label.position.y += for_player.get_height()
	add_child(damage_label)
	
	_queued_damage_numbers.erase(for_player)

