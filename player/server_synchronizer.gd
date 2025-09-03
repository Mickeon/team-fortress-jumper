extends Node

var current_tick := 0
var client_delay_ticks := 0
var last_received_client_tick := 0

@onready var o: Player = owner

const SERVER_ID = 1
#const BUFFER_SIZE = 10


func _ready() -> void:
	if multiplayer.is_server() and o.get_multiplayer_authority() != multiplayer.get_unique_id():
		# The server moves them manually.
		o.set_physics_process.call_deferred(false)

func _physics_process(_delta: float) -> void:
	set_multiplayer_authority(SERVER_ID)
	
	current_tick += 1
	
	if multiplayer.is_server():
		#update_history()
		
		# FIXME: Extremely jittery pivot rotation, specially noticeable with 3+ players.
		# It's possible they're resetting themselves back to the previous rotation for some reason?
		update_physics.rpc(current_tick, {
			position = o.position, 
			velocity = o.velocity, 
			wish_dir = o.wish_dir,
			crouched = o.crouched,
			pivot_basis = o.view_pivot.basis.orthonormalized(),
		})
		
	else: # Client sends
		update_input.rpc_id(SERVER_ID, current_tick, {
			wish_dir = o.wish_dir,
			crouched = o.crouched,
			pivot_basis = o.view_pivot.basis.orthonormalized(),
		})
	
	

@rpc("authority", "call_remote", "unreliable_ordered")
func update_physics(server_tick: int, server: Dictionary):
	current_tick = server_tick
	
	o.position = server.position
	o.velocity = server.velocity
	
	if o.get_multiplayer_authority() != multiplayer.get_unique_id():
		o.wish_dir = server.wish_dir
		o.crouched = server.crouched
		o.view_pivot.basis = server.pivot_basis


@rpc("any_peer", "call_remote", "unreliable_ordered")
func update_input(client_tick: int, client: Dictionary):
	#if history.has(client_tick):
		#history[client_tick].wish_dir = client_data.wish_dir
		#history[client_tick].crouched = client_data.crouched
		#client_delay_ticks = current_tick - client_tick
	if not multiplayer.is_server():
		return
	
	var missed_ticks := client_tick - last_received_client_tick
	if missed_ticks > 0 and o.get_multiplayer_authority() != SERVER_ID:
		last_received_client_tick = client_tick
		
		o.wish_dir = client.wish_dir
		o.crouched = client.crouched
		o.view_pivot.basis = client.pivot_basis
		
		for tick in missed_ticks:
			o._physics_process(get_physics_process_delta_time())


#var history := { }
#func update_history():
	#history[current_tick] = {
		#position = o.position,
		#velocity = o.velocity,
	#}
	#
	#if history.size() > BUFFER_SIZE:
		#var previous_lowest_tick: int = history.keys().min()
		#history.erase(history.keys()[0])
	#
		#assert(history.keys().min() > previous_lowest_tick)


#func simulate():
	#var starting_tick := maxi(current_tick - BUFFER_SIZE + 1, 0)
	#
	#o.position = history[starting_tick].position
	#o.velocity = history[starting_tick].velocity
	#for tick in range(starting_tick, current_tick + 1):
		#o.wish_dir = history[tick].get("wish_dir", o.wish_dir)
		#o.velocity = history[tick].velocity
		#
		#o._physics_process(get_physics_process_delta_time())
	#
	#pass

static func pr(string: String):
	Engine.get_main_loop().root.get_node("MPGame/Chat").append(string)

