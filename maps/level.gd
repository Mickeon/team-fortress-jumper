extends Node3D

@export var map: StaticBody3D
@export var collider_mesh_instances: Array[MeshInstance3D]

func _ready() -> void:
	for mesh_instance in collider_mesh_instances:
		create_shape_sibling(mesh_instance, false)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_QUOTELEFT:
				get_tree().reload_current_scene()
			KEY_F1:
				get_tree().change_scene_to_file("res://maps/Harvest.tscn")
			KEY_F2:
				get_tree().change_scene_to_file("res://maps/Level.tscn")
			KEY_F4:
				OS.shell_open("https://github.com/Mickeon/team-fortress-jumper")


var _cache := {} # { Mesh: Shape3D }
func create_shape_sibling(mesh_instance: MeshInstance3D, convex := true):
	var mesh = mesh_instance.mesh
	var collision_shape := CollisionShape3D.new()
	if _cache.has(mesh):
		collision_shape.shape = _cache[mesh_instance.mesh]
	else:
		if convex:
			collision_shape.shape = mesh.create_convex_shape(true, true)
		else:
			collision_shape.shape = mesh.create_trimesh_shape()
		
		_cache[mesh] = collision_shape.shape
	
	collision_shape.name = mesh_instance.name + "_col_shape"
	collision_shape.global_transform = mesh_instance.global_transform
	mesh_instance.add_sibling.call_deferred(collision_shape)

