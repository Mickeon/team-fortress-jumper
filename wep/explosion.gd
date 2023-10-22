extends Area3D

const HU = Player.HU
const SCALE_SELF_SOLDIER_RJ = 10.0 * HU # On air
const SCALE_SELF_SOLDIER_BADRJ = 5.0 * HU # On ground


const DEBUG_COLOR = Color.ORANGE
const LIFETIME = 30.0
static var debug_show_radius := false

# For self-inflicted blasts, it seems like roughly 2.3 is actually way more accurate.
# Something to do with bounding box size, 146 - 24 = 122.
# I know why, it's actually finding the closest point to a sphere. Not just a normal distance check.
# I have solved it in the past and I may have to, again.
@export_range(0, 5, 0.001, "hide_slider", "suffix:m")
var splash_radius = 146 * HU:
	set(new):
#		print("from %s to %s" % [splash_radius, new])
		splash_radius = new
		
		if not is_node_ready(): await ready
		
		$BlastShape.scale = Vector3.ONE * splash_radius / 2.0
		$BlastDecal.size = (Vector3.ONE * 4) * splash_radius / 2.0

@export_range(0, 120, 1, "hide_slider", "or_greater")
var base_damage := 90.0

var source: Player

@onready var lifetimer := get_tree().create_timer(LIFETIME)

func _ready() -> void:
#	DebugDraw3D.draw_position(global_transform, Color.CHARTREUSE, LIFETIME)
	if OS.is_debug_build() and debug_show_radius:
		get_tree().physics_frame.connect(_debug_physics_process)
	
	process_physics_priority = 100
	lifetimer.timeout.connect(queue_free)
	# Stay on, just for one frame, for the collisions to register.
	get_tree().physics_frame.connect(set_monitoring.bind(false), CONNECT_DEFERRED)

func _debug_physics_process():
	var delta := get_physics_process_delta_time()
	var ratio := smoothstep(0, LIFETIME, lifetimer.time_left / 2)
	var final_color := Color.BLACK.lerp(DEBUG_COLOR, ratio).srgb_to_linear()
	
	if ratio >= 0.49:
		DebugDraw3D.draw_sphere_hd(position, splash_radius, final_color, delta)
	else:
		DebugDraw3D.draw_sphere(position, splash_radius, final_color, delta)


func apply_knockback(player: Player):
	var player_global_center := player.get_global_center()
	var splash_distance := minf(
			global_position.distance_to(player.global_position), 
			global_position.distance_to(player_global_center))
	if source == player:
#		splash_radius -= 25 * HU
		splash_radius -= 25.25 * HU # For some reason this works better.
	
	var edge_damage := base_damage * 0.5
	var damage := maxf(
			remap(splash_distance, 0.0, splash_radius, base_damage, edge_damage),
			edge_damage)
	
	var multiplier := 9.0 * HU
	if source == player:
		if not player.grounded:
			damage *= 0.6
			multiplier = SCALE_SELF_SOLDIER_RJ
		else:
			multiplier = SCALE_SELF_SOLDIER_BADRJ
	
	# Pretends that the knockback direction of attacks come from 10 Hu lower than they really do.
	# It's part of why you're frequently pushed upwards when taking damage in the Vanilla game.
	var direction := (global_position + Vector3(0, -10 * HU, 0)).direction_to(player_global_center)
	
	var volume_ratio := 1.49091 if player.crouching else 1.0
	var knockback_force := minf(damage * volume_ratio * multiplier, 1000 * HU)
	var add_velocity := knockback_force * direction
	player.velocity += add_velocity
	player.grounded = false
	
	print("Damage: %4.2f | Speed: %5.2f" % [damage, player.velocity.length() / HU])

func is_valid_target(player: Player) -> bool:
	var query := PhysicsRayQueryParameters3D.create(
			global_position, player.get_global_center(),
			0xFFFFFFFF, [player.get_rid()])
	
	# Check for any obstruction between the player and the blast.
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _on_body_entered(body: Node3D) -> void:
	if body is Player and is_valid_target(body):
		apply_knockback(body)

