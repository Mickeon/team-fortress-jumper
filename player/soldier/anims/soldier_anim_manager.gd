@tool
extends AnimationTree


@export var player: Player
@export var model: Node3D

enum Type { PRIMARY, SECONDARY, MELEE }
@export var held_type := Type.PRIMARY:
	set(new):
		if held_type == new:
			return
		
		var prior_held_type_name: String = Type.find_key(held_type).to_lower()
		
		held_type = new
		held_type_name = Type.find_key(held_type).to_lower()
		
		set(&"parameters/seek/seek_request", get("parameters/%s/current_position" % prior_held_type_name))
		
		set(&"parameters/held_type/transition_request", held_type_name)

var held_type_name := &"primary"

@export var debug_switch_weapons := false:
	set(new):
		debug_switch_weapons = new
		
		if debug_switch_weapons:
			_debug_switch_tween = create_tween()
			#_random_switch_tween.set_loops().tween_callback(func():
				#held_type = (randi() % (Type.size() - 1)) as Type
			#).set_delay(1.5)
			_debug_switch_tween.set_loops().tween_callback(func():
				held_type = ((held_type + 1) % (Type.size() - 1)) as Type
			).set_delay(2.5)
		
		elif _debug_switch_tween:
			_debug_switch_tween.kill()
var _debug_switch_tween: Tween

@warning_ignore("unused_private_class_variable")
@export_tool_button("Generate weapon AnimationRoot resources") var _generate_weapon_roots := func():
	var root := tree_root as AnimationNodeBlendTree
	var i := 1
	for suffix: String in ["SECONDARY", "MELEE"]:
		var lower_suffix := suffix.to_lower()
		# Ideally, only animation nodes that need to be changed should be duplicated. But this does it for everything.
		var wep_root: AnimationNodeBlendTree = load("res://player/soldier/anims/root_primary.tres").duplicate(true)
		var stand: AnimationNodeBlendTree = wep_root.get_node("stand")
		var crouch: AnimationNodeBlendTree = wep_root.get_node("crouch")
		
		var animation_nodes_to_replace: Array[AnimationNodeAnimation]
		animation_nodes_to_replace.append(wep_root.get_node("airborne"))
		animation_nodes_to_replace.append(wep_root.get_node("jump_start_anim"))
		animation_nodes_to_replace.append(wep_root.get_node("jump_start_base"))
		animation_nodes_to_replace.append(wep_root.get_node("jump_land_anim"))
		animation_nodes_to_replace.append(wep_root.get_node("jump_land_base"))
		animation_nodes_to_replace.append(wep_root.get_node("shoot_anim"))
		animation_nodes_to_replace.append(wep_root.get_node("shoot_base"))
		animation_nodes_to_replace.append(wep_root.get_node("look_center"))
		animation_nodes_to_replace.append_array(get_animation_nodes(wep_root.get_node("look_blend")))
		animation_nodes_to_replace.append(stand.get_node("idle"))
		animation_nodes_to_replace.append(stand.get_node("move_center"))
		animation_nodes_to_replace.append_array(get_animation_nodes(stand.get_node("move_blend")))
		animation_nodes_to_replace.append(crouch.get_node("idle"))
		animation_nodes_to_replace.append(crouch.get_node("move_center"))
		animation_nodes_to_replace.append_array(get_animation_nodes(crouch.get_node("move_blend")))
		
		replace_weapon_type_suffix_for_animations(animation_nodes_to_replace, "PRIMARY", suffix)
		
		wep_root.take_over_path("res://player/soldier/anims/root_" + lower_suffix + ".tres")
		ResourceSaver.save(wep_root)
		
		# Add them to the root, too.
		if root.has_node(lower_suffix):
			root.remove_node(lower_suffix)
		
		root.add_node(lower_suffix, wep_root, root.get_node_position("primary") + Vector2(0, 160 * i))
		root.connect_node("held_type", i, lower_suffix)
		
		# Copy the AnimationTree parameters. Nasty.
		var primary_parameter_names := get_property_list(
		).filter(func(property):
			return property.name.begins_with("parameters/primary/")
		).map(func(property):
			return property.name.trim_prefix("parameters/primary/")
		)
		for parameter_name: String in primary_parameter_names:
			if parameter_name.ends_with("/transition_request"):
				# Special case for AnimationNodeTransition.
				set("parameters/%s/%s" % [lower_suffix, parameter_name], 
						get("parameters/primary/" + parameter_name.trim_suffix("transition_request") + "current_state")
				)
				continue
			
			set("parameters/%s/%s" % [lower_suffix, parameter_name], get("parameters/primary/" + parameter_name))
		
		i += 1
		
	
	
var _previously_grounded := false
var air_crouched := false:
	set(new):
		if air_crouched == new:
			return
		
		air_crouched = new
		
		if air_crouched:
			model.position.y -= 20 * player.HU
		else:
			model.position.y += 20 * player.HU

func _ready():
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
	else:
		active = true



func _process(delta: float) -> void:
	var facing_blend_pos := Vector2(0, remap(player.cam_pivot.rotation.x, -PI / 2, PI / 2, -1, 1))
	
	if player.velocity.is_zero_approx():
		# TODO: This isn't very nice and smooth (See CMultiPlayerAnimState::ComputePoseParam_AimYaw, EstimateYaw).
		facing_blend_pos.x = remap(wrapf(player.cam_pivot.rotation.y - model.rotation.y, -PI, PI), PI / 4, -PI / 4, -1, 1)
		if abs(facing_blend_pos.x) >= 1.0:
			model.rotation.y = rotate_toward(model.rotation.y, player.cam_pivot.rotation.y, delta * abs(facing_blend_pos.x) * 4)
			#facing_blend_pos.x = move_toward(get("parameters/%s/look_blend/blend_position" % held_type_name).x, 0.0, delta * abs(facing_blend_pos.x) * 4)
	else:
		model.rotation.y = player.cam_pivot.rotation.y
		
	#set(&"parameters/look_blend/blend_position", facing_blend_pos)
	set("parameters/%s/look_blend/blend_position" % held_type_name, facing_blend_pos)

func _physics_process(_delta: float) -> void:
	_handle_animations()
	
	_previously_grounded = player.grounded


func _handle_animations():
	air_crouched = not player.grounded and player.crouched
	
	var velocity_planar := Vector2(player.velocity.x, player.velocity.z).rotated(model.rotation.y)
	#var player_speed := velocity_planar.length()
	
	if player.grounded:
		if player.crouched:
			var crouch_speed := player.GROUND_SPEED * player.CROUCH_SPEED_MULTIPLIER
			var move_blend_pos = Vector2(velocity_planar.x, -velocity_planar.y) / crouch_speed
			
			set("parameters/%s/movement_state/transition_request" % held_type_name, "crouched")
			set("parameters/%s/crouch/move_blend/blend_position" % held_type_name, move_blend_pos)
			#set(&"parameters/crouch_walk/blend_amount", player_speed / crouch_speed)
		else:
			var ground_speed := player.GROUND_SPEED
			var move_blend_pos := Vector2(velocity_planar.x, -velocity_planar.y) / ground_speed
			
			set("parameters/%s/movement_state/transition_request" % held_type_name, "standing")
			set("parameters/%s/stand/move_blend/blend_position" % held_type_name, move_blend_pos)
			#set(&"parameters/walk/blend_amount", player_speed / ground_speed)
	else:
		set("parameters/%s/movement_state/transition_request" % held_type_name, "airborne")
	
	if player.just_landed:
		set("parameters/%s/jump_land/request" % held_type_name, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	if player.just_jumped and not player.grounded:
		set("parameters/%s/jump_start/request" % held_type_name, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	pass


# These are connected inside the PackedScene.
func _on_any_weapon_shot() -> void:
	set("parameters/%s/shoot/request" % held_type_name, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _on_any_weapon_deployed(weapon_type: Type) -> void:
	held_type = weapon_type



static func get_animation_nodes(root: AnimationRootNode) -> Array[AnimationNode]:
	var result: Array[AnimationNode] = []
	if root is AnimationNodeBlendTree or root is AnimationNodeStateMachine:
		var node_names: Array[String]
		node_names.assign(root.get_property_list(
		).filter(func(property):
				return property.name.begins_with("nodes/") and property.name.ends_with("/node")
		).map(func(property):
				return property.name.trim_prefix("nodes/").trim_suffix("/node")
		))
	
		for node_name in node_names:
			if root.has_node(node_name):
				result.append(root.get_node(node_name))
			else:
				printerr("Can't find animation node '", node_name, "' for some reason.")
	elif root is AnimationNodeBlendSpace2D:
		for idx in root.get_blend_point_count():
			result.append(root.get_blend_point_node(idx))
	else:
		printerr("Can't extract animation nodes from root node of class ", root.get_class())
	
	return result

func replace_weapon_type_suffix_for_animations(animations: Array[AnimationNodeAnimation], from: String, to: String):
	for anim_node in animations:
		if not anim_node:
			printerr("A node is null while replacing suffix. This should not happen. Continuing.")
			continue
		
		if not anim_node.animation.contains(from):
			printerr("Node ", anim_node, " with animation ", anim_node.animation, "does not end with ", from, ". Continuing.")
			continue
		
		anim_node.animation = anim_node.animation.replace(from, to)
		
		if not has_animation(anim_node.animation):
			printerr("No animation named ", anim_node.animation,". Continuing.")
			continue
		
		# Between two weapon types the animation lengths may differ.
		if anim_node.timeline_length > 0.0 and not anim_node.stretch_time_scale:
			anim_node.timeline_length = get_animation(anim_node.animation).length
		
