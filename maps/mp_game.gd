extends Node

const PlayerScene = preload("res://player/Player.tscn")

const PORT = 8002
const SERVER_ADDRESS = "localhost"
const SERVER_ID = 1

@onready var chat := $Chat

func _unhandled_input(event):
	if event.is_action_pressed("debug_spawn_fake_player") and multiplayer.is_server():
		spawn_player(0)

func _ready() -> void:
	tweak_window()
	
	var args := OS.get_cmdline_args()
	
	if args.has("listen"):
		await _host()
		multiplayer.peer_connected.connect(func(id): chat.send_message("Client %s connected" % id))
		multiplayer.peer_disconnected.connect(func(id): chat.send_message("Client %s disconnected" % id))
	
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

func _connect():
	await get_tree().create_timer(0.5).timeout
	
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(SERVER_ADDRESS, PORT)
	if err:
		printerr("Could not connect to server at ", SERVER_ADDRESS, ":", PORT, " ", error_string(err))
	else:
		print("Successfully connected to server at ", SERVER_ADDRESS, ":", PORT)
		multiplayer.multiplayer_peer = peer
		#peer.set_target_peer(SERVER_ID)


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


#region Player Tweaks
func tweak_other(player: Player):
	# Disable input.
	player.propagate_call("set_process_input", [false])
	player.propagate_call("set_process_unhandled_input", [false])
	
	player.cam_pivot.get_node("Camera").queue_free()
	player.cam_pivot.hide()
	
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
	player.position += Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))

func tweak_window():
	var window := get_window()
	var debug_window_count := int(ProjectSettings.get_setting("debug/multirun/number_of_windows", 0))
	
	if args_dict.has("listen"):
		window.title = "Team Fortress Jumper (Hosting)"
		if debug_window_count > 2:
			window.size *= 0.75
		
		return
	
	if args_dict.has("join"):
		window.title = "Team Fortress Jumper (Connected to host)"
		
		if debug_window_count <= 2:
			window.size *= 0.75
			return
		
		window.size *= 0.4#0.25
		window.content_scale_factor = 0.75#0.5
		
		var order := int(args_dict.get("order", 1)) - 1
		var screen_rect := DisplayServer.screen_get_usable_rect(1)
		window.position.y = screen_rect.end.y - window.size.y
		window.position.x = wrapi(screen_rect.end.x - window.size.x * order, 
				screen_rect.position.x, screen_rect.end.x)

#endregion

var _queued_damage_numbers := {} # { Player: float }
func _on_player_hurt(amount: float, inflictor: Player, victim: Player):
	if inflictor == victim:
		return # Don't care about self-inflicted damage.
	
	if not _queued_damage_numbers.has(victim):
		create_damage_label.call_deferred(victim)
		_queued_damage_numbers[victim] = amount
	else:
		_queued_damage_numbers[victim] += amount

func create_damage_label(for_player: Player):
	const DamageNumberScene = preload("res://wep/other/DamageNumber.tscn")
	var damage_label: Label3D = DamageNumberScene.instantiate()
	damage_label.damage = _queued_damage_numbers[for_player]
	damage_label.position = for_player.position
	damage_label.position.y += for_player.get_height()
	add_child(damage_label)
	
	# Likely because this whole method is "deferred", the label shows up at the origin for a single frame.
	# to mitigate this, we fully show the label on the very next frame.
	damage_label.hide()
	get_tree().process_frame.connect(damage_label.show)
	
	_queued_damage_numbers.erase(for_player)


static var args_dict: Dictionary: # { String: Variant }
	get:
		if args_dict:
			return args_dict
		
		var args := OS.get_cmdline_args()
		var new_key := ""
		for argument in args:
			if new_key:
				var value = str_to_var(argument)
				args_dict[new_key] = value if value else argument
				new_key = ""
			elif argument.begins_with("-"):
				new_key = argument.replace("-", "")
			else:
				args_dict[argument] = null
		
		return args_dict

