extends Node

var movement := Vector2.ZERO
var jumped := false
var crouched := false

func _ready():
	NetworkTime.before_tick_loop.connect(_gather)

func _process(_delta):
	_gather()
	
func _gather():
	if not is_multiplayer_authority():
		return
	
	movement = Input.get_vector("player_left", "player_right", "player_forward", "player_back")
	jumped = Input.is_action_pressed("player_jump")
	crouched = Input.is_action_pressed("player_crouch")

