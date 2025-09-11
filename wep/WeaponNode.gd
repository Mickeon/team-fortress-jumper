@icon("res://shared/icons/weapon.png")
extends Node3D
class_name WeaponNode

const HU = Player.HU
const OfflineRewindableAction = preload("res://wep/other/offline_rewindable_action.gd")

signal shot
signal deployed

@export var fire_cooldown := 0.8
@export var active := false:
	set(new):
		if active == new:
			return
		
		active = new
enum Type { PRIMARY, SECONDARY, MELEE, EQUIPPABLE }
@export var type := Type.PRIMARY

@onready var player_owner: Player = owner
@onready var input := player_owner.input
@onready var fp_model: Node3D = get_node_or_null("FPModel")
@onready var tp_model: Node3D = get_node_or_null("TPModel")
@onready var shoot_sfx: AudioStreamPlayer3D = get_node_or_null("Shoot")
@onready var deploy_sfx: AudioStreamPlayer3D = get_node_or_null("Deploy")

@onready var fire_action: RewindableAction
@onready var rollback_synchronizer: RollbackSynchronizer = $%RollbackSynchronizer

var first_person_player: AnimationPlayer

var _fire_timer: SceneTreeTimer
var _last_fire := -1

func _ready() -> void:
	fire_action = (OfflineRewindableAction if Player.is_offline() else RewindableAction).new()
	fire_action.name = "FireAction"
	fire_action.mutate(self)         # Mutate self, so firing code can run.
	fire_action.mutate(player_owner) # Mutate player.
	add_child(fire_action)
	rollback_synchronizer.add_state(self, "_last_fire")

	NetworkTime.after_tick_loop.connect(_after_tick_loop)
	
	set_physics_process(Player.is_offline())

func _physics_process(delta: float) -> void:
	_rollback_tick(delta, 0, false)
	_after_tick_loop()

func _rollback_tick(_delta: float, _tick: int, _is_fresh: bool):
	if rollback_synchronizer.is_predicting():
		return
	
	fire_action.set_active(_can_fire())
	match fire_action.get_status():
		RewindableAction.CONFIRMING:
			_fire_confirming()
			_fire()
		RewindableAction.ACTIVE:
			if Player.is_offline(): # HACK: Confirming doesn't happen in offline.
				_fire_confirming()
			_fire()
		RewindableAction.CANCELLING:
			_unfire() # Whoops, turns out we couldn't have fired, undo.

func _after_tick_loop():
	if fire_action.has_confirmed():
		_fire_confirmed()
	

func _can_fire() -> bool:
	if not input.firing_primary:
		return false
	if not active:
		return false
	if Player.is_offline():
		if _fire_timer and _fire_timer.time_left > 0.0:
			return false
	else:
		if NetworkTime.seconds_between(_last_fire, NetworkRollback.tick) < fire_cooldown:
			return false
	
	return true

var first_fire := false
func _fire():
	refresh_cooldown()
	# A potential stop-gap with is_new_hit, as provided in the tutorials, may be odd.
	# Investigate. Ideally some things should only happen when the server confirms the shot.
	first_fire = false
	if not fire_action.has_context():
		fire_action.set_context(true)
		first_fire = true

func _unfire():
	fire_action.erase_context()

func _fire_confirming():
	pass

func _fire_confirmed():
	shoot_sfx.play()
	emit_signal("shot")


@rpc("authority", "call_local", "reliable")
func deploy():
	if fp_model:
		fp_model.show()
	if tp_model:
		tp_model.show()
	if deploy_sfx:
		deploy_sfx.play()
	
	_deploy()
	emit_signal("deployed")

func holster():
	if fp_model:
		fp_model.hide()
	if tp_model:
		tp_model.hide()


func refresh_cooldown():
	if Player.is_offline():
		_fire_timer = get_tree().create_timer(fire_cooldown, true, true)
		_fire_timer.timeout.connect(_ready_to_shoot)
	else:
		_last_fire = NetworkRollback.tick

## Overridable. Called when deploying this weapon.
func _deploy():
	pass

## Overridable. Called after shooting, when the weapon is ready to shoot again.
func _ready_to_shoot():
	pass


func add_decal(decal_scene: PackedScene, hit_point: Vector3, normal: Vector3):
	var decal: Node3D = decal_scene.instantiate()
	decal.position = hit_point
	if normal.is_equal_approx(Vector3.DOWN):		
		#decal.basis = decal.basis.rotated(Vector3.RIGHT, PI)
		#decal.basis *= Basis(Vector3.RIGHT, Vector3.DOWN, Vector3.FORWARD)
		# In this case, it's equivalent to the above code snippets but faster. 
		decal.basis.y *= -1
		decal.basis.z *= -1
	elif not normal.is_equal_approx(Vector3.UP) and normal != Vector3.ZERO:
		#decal.basis = decal.basis.looking_at(normal)
		decal.look_at_from_position(decal.position, decal.position + normal)
		decal.rotate_object_local(Vector3.RIGHT, TAU * -0.25);
	
	decal.get_node("Sparks").one_shot = true # May not exist, remember to fix.
	player_owner.add_sibling(decal)
	
	get_tree().create_timer(60).timeout.connect(decal.queue_free)
