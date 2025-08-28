extends Node

const PlayerScene = preload("res://player/Player.tscn")

const PORT = 8002
const SERVER_ADDRESS = "localhost"
const SERVER_ID = 1
const Chat = preload("res://ui/chat/chat.gd")

@onready var chat: Chat = $Chat

@export var map_scene: PackedScene:
	set(new):
		if map == new:
			return
		if not is_node_ready(): await ready
		if map:
			remove_child(map)
			map.queue_free()
		map = new.instantiate()
		if map:
			add_child(map)
var map: Node

func _unhandled_input(event):
	if event.is_action_pressed("debug_spawn_fake_player") and multiplayer.is_server():
		spawn_player.rpc(0)
		get_viewport().set_input_as_handled()
	
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.physical_keycode:
			KEY_KP_SUBTRACT, KEY_KP_ADD:
				var advance := 1 if event.keycode == KEY_KP_ADD else -1
				var players: Array[Player] = []
				players.assign(get_tree().get_nodes_in_group("players"))
				Player.main = players[posmod(players.find(Player.main) + advance, players.size())]
			KEY_QUOTELEFT:
				get_tree().reload_current_scene()
			KEY_F2:
				if (event.is_command_or_control_pressed() 
				and ResourceLoader.exists("res://maps/KOTHHarvestFinal.tscn")):
					map_scene = load("res://maps/KOTHHarvestFinal.tscn")
				elif (event.shift_pressed
				and ResourceLoader.exists("res://maps/PLMinepit.tscn")):
					map_scene = load("res://maps/PLMinepit.tscn")
				else:
					map_scene = load("res://maps/ItemTest.tscn")

func _ready() -> void:
	tweak_window()
	
	var args := OS.get_cmdline_args()
	
	if args.has("listen"):
		await _host()
		multiplayer.peer_connected.connect(func(id): chat.broadcast("Client %s connected" % id))
		multiplayer.peer_disconnected.connect(func(id): chat.broadcast("Client %s disconnected" % id))
	
	elif args.has("join"):
		await _connect()
	
	multiplayer.peer_connected.connect(spawn_player)
	multiplayer.peer_disconnected.connect(remove_player)
	multiplayer.server_disconnected.connect(_start_close_countdown)
	
	spawn_player(multiplayer.get_unique_id())
	$PlayerDebugger.player = get_node(str(multiplayer.get_unique_id()))
	
	if not multiplayer.is_server():
		await multiplayer.peer_connected
	set_peer_name.rpc(args_dict.get("name", ""))


func _host():
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT)
	if err:
		printerr("Could not create server: ", error_string(err))
	else:
		print("Hosting server at port ", PORT)
		multiplayer.multiplayer_peer = peer

func _connect():
	await get_tree().create_timer(0.25).timeout
	
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(SERVER_ADDRESS, PORT)
	if err:
		printerr("Could not connect to server at ", SERVER_ADDRESS, ":", PORT, " ", error_string(err))
	else:
		print("Successfully connected to server at ", SERVER_ADDRESS, ":", PORT)
		multiplayer.multiplayer_peer = peer
		#peer.set_target_peer(SERVER_ID) # I don't know.

@rpc("any_peer", "call_local", "reliable")
func set_peer_name(new_name: String):
	if not multiplayer.is_server():
		return
	if new_name.is_empty():
		return
	
	var sender_id := multiplayer.get_remote_sender_id()
	Chat.name_dict[sender_id] = new_name

@rpc("authority", "call_local", "reliable")
func spawn_player(id: int):
	var is_fake_player := id == 0
	
	var player: Player = PlayerScene.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(SERVER_ID if is_fake_player else id)
	
	add_child(player, true)
	if id == multiplayer.get_unique_id():
		Player.main = player
	else:
		tweak_other(player)
	
	if id == SERVER_ID:
		tweak_server(player)
	else:
		tweak_client(player)

func remove_player(id: int):
	get_node(str(id)).queue_free()

func _start_close_countdown():
	chat.append("Server has closed. Closing game, too.")
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()

#region Player Tweaks 
func tweak_other(player: Player):
	player.hurt.connect(_on_player_hurt.bind(player))

func tweak_server(player: Player):
	player.cam_pivot.rotation.y += PI

func tweak_client(player: Player):
	# All clients are in BLU team.
	player.team = Player.Team.BLU
	
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
		window.position.x = wrapi(screen_rect.end.x - 1 - window.size.x * order, 
				screen_rect.position.x - window.size.x * 0.5, screen_rect.end.x - window.size.x)
		
		get_viewport().scaling_3d_scale = maxf(1 - debug_window_count * 0.1, 0.5)
		
		$PlayerDebugger.hide()

#endregion

var _queued_damage_numbers: Dictionary[Player, float] = {}
func _on_player_hurt(amount: float, inflictor: Player, victim: Player):
	if inflictor == victim:
		#chat.send("%s took self-damage! %4.2f" % [inflictor.name, amount])
		return # Don't care about self-inflicted damage.
	if inflictor != Player.main:
		return # Don't care about damage other players dealt.
	
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
	
	_queued_damage_numbers.erase(for_player)


static var args_dict: Dictionary[String, Variant]:
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

