extends Node

var movement := Vector2.ZERO
var jumped := false
var crouched := false
var debug_network_use := false
var firing_primary := false

@onready var _rollback_synchronizer: RollbackSynchronizer = $%RollbackSynchronizer

func _ready():
	# TODO: Call this stuff after some sort of custom notification (NOTIFICATION_MP_AUTHORITY_CHANGED)
	# to properly handle changes to multiplayer authority while inside the tree.
	if is_multiplayer_authority():
		NetworkTime.before_tick_loop.connect(_gather)
	
	set_process(Player.is_offline())
	NetworkRollback.after_prepare_tick.connect(_predict)
		

func _unhandled_input(event: InputEvent) -> void:
	assert(is_multiplayer_authority(),
			"Trying to fetch input, but the input callback should've been disabled beforehand.\n" 
			+ "multiplayer: %s | multiplayer_id: %s | authority: %s | multiplayer_peer_id: %s" % [
				multiplayer, multiplayer.get_unique_id(), get_multiplayer_authority(), multiplayer.multiplayer_peer.get_unique_id()
			]
	)
	
	if event.is_action("player_primary"):
		firing_primary = event.is_pressed()
		get_viewport().set_input_as_handled()
	if event.is_action("player_jump"):
		jumped = event.is_pressed()
		get_viewport().set_input_as_handled()
	if event.is_action("player_crouch"):
		crouched = event.is_pressed()
		get_viewport().set_input_as_handled()
	if event.is_action("debug_network_use"):
		debug_network_use = event.is_pressed()
		get_viewport().set_input_as_handled()
	#if (event.is_action("player_left")
	#or event.is_action("player_right")
	#or event.is_action("player_forward")
	#or event.is_action("player_back")):
		#movement = Input.get_vector("player_left", "player_right", "player_forward", "player_back")
		#get_viewport().set_input_as_handled()

func _process(_delta):
	_gather()

var confidence := 1.0
func _gather():
	#assert(is_multiplayer_authority())
	movement = Input.get_vector("player_left", "player_right", "player_forward", "player_back")

func _predict(_tick: int):
	if not _rollback_synchronizer.is_predicting():
		confidence = 1.0 # Not predicting, nothing to do.
		return
	
	if not _rollback_synchronizer.has_input():
		confidence = 0.0 # Can't predict without input.
		return
	
	# Decay input over a short time.
	var decay_time := float(NetworkTime.seconds_to_ticks(0.25))
	var input_age := float(_rollback_synchronizer.get_input_age())
	
	confidence = input_age / decay_time
	confidence = clampf(1.0 - confidence, 0.0, 1.0)
	
	movement *= confidence

