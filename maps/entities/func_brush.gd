@tool
extends ValveIONode

enum Solidity {
	TOGGLE,
	NEVER_SOLID,
	ALWAYS_SOLID
}

func _entity_ready():
	set_process(false)
	set_physics_process(false)

func _apply_entity(entity_data):
	super._apply_entity(entity_data)
	
	var import_scale := VMFConfig.import.scale
	
	if position == Vector3.ZERO and entity_data.solid.has("side"): # func_detail
		var all_points := PackedVector3Array()
		for side in entity_data.solid.side:
			for point in side.plane.points:
				all_points.append(point * import_scale)
		
		var sum := Vector3.ZERO
		for point in all_points:
			sum += convert_vector(point)
		
		var average := sum / all_points.size()
		position += average
		#position += mesh.get_aabb().get_center()
		#mesh = get_mesh() # Do it again accounting for new position.
	
	var mesh := get_mesh()
	
	if VMFConfig.import.generate_lightmap_uv2:
		mesh.lightmap_unwrap(global_transform, VMFConfig.import.lightmap_texel_size)
	
	var mesh_instance: MeshInstance3D = $MeshInstance3D
	mesh_instance.cast_shadow = entity_data.get("disableshadows", 0) == 0
	mesh_instance.set_mesh(mesh)
	
	if entity_data.get("Solidity", Solidity.ALWAYS_SOLID) != Solidity.NEVER_SOLID:
		var collision_shape: CollisionShape3D = $MeshInstance3D/StaticBody3D/CollisionShape3D
		collision_shape.shape = mesh_instance.mesh.create_trimesh_shape()
