extends Node3D

@export var map: StaticBody3D
@export var collider_mesh_instances: Array[MeshInstance3D]

func _ready() -> void:
	for mesh_instance in collider_mesh_instances:
		create_shape_sibling(mesh_instance, false)
	
	if OS.has_feature("web"):
		var env: Environment = $WorldEnvironment.environment
		
		env.fog_enabled = false # Fog doesn't look great in web builds right now.
		env.ssil_enabled = false
		env.glow_enabled = false
		env.adjustment_enabled = false
		
		# Make this material less reflective on web builds.
		load("res://maps/test_mat.tres").roughness = 0.5
		load("res://maps/test_mat.tres").albedo_color = Color.WHITE.darkened(0.5)


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

