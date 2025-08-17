@tool
extends AnimationNodeExtension
class_name AnimationNodeCustom

const DEFAULT_NODE_INFO := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0] # Should be PackedFloat32Array.
const SUFFIX_PROPERTY_NAME := &"held_type_name"
const PLACEHOLDER := "*"

enum Mode { NONE, FORCE_LOOPING, FORCE_FIRST_FRAME }

@export var mode := Mode.NONE
@export var animation_name := "":
	set(new):
		animation_name = new
		emit_changed()


func _init():
	#add_input("in0")
	pass

func _has_filter() -> bool:
	return false

func _get_caption() -> String:
	return "Custom (%s)" % animation_name

func _get_parameter_list() -> Array:
	return [
		{ name = "coolness", type = TYPE_FLOAT },
		{ name = "wetness", type = TYPE_FLOAT },
		{ name = "current_time", type = TYPE_FLOAT, usage = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY },
	]

func _get_parameter_default_value(parameter: StringName) -> Variant:
	return 0.0

func _validate_property(property: Dictionary) -> void:
	if not Engine.is_editor_hint():
		return
	
	if property.name == "animation_name":
		var animation_tree: AnimationTree
		for node in EditorInterface.get_selection().get_selected_nodes():
			if node is AnimationTree:
				animation_tree = node
				break
		if not animation_tree:
			return
		
		property.hint = PROPERTY_HINT_ENUM_SUGGESTION
		property.hint_string = ",".join(animation_tree.get_animation_list())
		print(property.hint_string)

func _process_animation_node(playback_info: PackedFloat64Array, test_only: bool) -> PackedFloat32Array:
	# Destructuring everything.
	@warning_ignore_start("unused_variable")
	var time := playback_info[0]
	var delta := playback_info[1]
	#var start_time := playback_info[2]
	#var end_time := playback_info[3]
	var seek_requested := playback_info[4] > 0.0
	var seek_externally_requested := playback_info[5] > 0.0
	var looped_flag := int(playback_info[6]) as Animation.LoopedFlag
	#var blend_weight := playback_info[7]
	
	# Parameters.
	var coolness: float = get_parameter("coolness")
	var wetness: float = get_parameter("wetness")
	@warning_ignore_restore("unused_variable")
	#print(
			#"time: " + str(time) + " | ",
			#"delta: " + str(delta) + " | ",
			#"start_time: " + str(start_time) + " | ",
			#"end_time: " + str(end_time) + " | ",
			#"seek_requested: " + str(seek_requested) + " | ",
			#"seek_externally_requested: " + str(seek_externally_requested) + " | ",
			#"looped_flag: " + str(looped_flag) + " | ",
			#"blend_weight: " + str(blend_weight) + " | ",
			#".",
	#)
	
	var tree_node: AnimationTree = instance_from_id(get_processing_animation_tree_instance_id())
	var chosen_animation_name := animation_name.replace(PLACEHOLDER, tree_node.get(SUFFIX_PROPERTY_NAME).to_upper())
	var chosen_animation := tree_node.get_animation(chosen_animation_name)
	if not chosen_animation:
		return DEFAULT_NODE_INFO
	var animation_length := chosen_animation.length
	
	#var previous_time: float = get_parameter(&"current_position")
	var loop_mode := Animation.LoopMode.LOOP_NONE if not mode == Mode.FORCE_LOOPING else Animation.LoopMode.LOOP_LINEAR
	var animation_is_about_to_end := time > animation_length
	var animation_is_infinite := false #mode == Mode.FORCE_LOOPING # Doesn't seem to do anything?
	
	if mode == Mode.FORCE_LOOPING:
		time = fposmod(time, animation_length)
	elif mode == Mode.FORCE_FIRST_FRAME:
		time = 0.0
		animation_length = 0.0
		
	if not test_only:
		blend_animation(chosen_animation_name, time, delta, seek_requested, seek_externally_requested, 1.0)
	
	set_parameter(&"current_time", time) # Just for show.
	
	var node_time_info := PackedFloat32Array([
		animation_length,
		time,
		delta,
		loop_mode,
		animation_is_about_to_end,
		animation_is_infinite,
	])
	return node_time_info





# This method returns length minus position, both of input node's NodeTimeInfo.
#blend_input(0, time, seek_requested, seek_externally_requested, coolness)
#var a := Time.get_ticks_usec()
#print(Time.get_ticks_usec() - a, " usec")
