@tool
extends GLTFDocumentExtension

const HU = 0.01905 # Hammer Unit.
const MAP_SCALE = Vector3.ONE * HU * 10#0.2


func _import_preflight(state: GLTFState, extensions: PackedStringArray) -> Error:
	state.set_meta("shape_cache", {})
	return OK

func _import_post_parse(state: GLTFState) -> Error:
	for m in state.get_materials():
		var material := m as StandardMaterial3D
		if material:
			material.vertex_color_use_as_albedo = false
			material.cull_mode = BaseMaterial3D.CULL_BACK
	
	var prefix := state.scene_name + "_"
	for gltf_mesh in state.get_meshes():
		gltf_mesh.mesh.resource_name = gltf_mesh.mesh.resource_name.trim_prefix(prefix)
	
	return OK

func _import_node(state: GLTFState, gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	var mesh_instance := node as ImporterMeshInstance3D
	if mesh_instance:
		var final_name := mesh_instance.mesh.resource_name
		
		if final_name.begins_with("props_"):
			create_shape_sibling(state, mesh_instance)
			final_name = final_name.trim_prefix("props_").capitalize().replace(" ", "")
			mesh_instance.add_to_group("props")
		
		mesh_instance.name = final_name
	
	return OK


func create_shape_sibling(state: GLTFState, mesh_instance: ImporterMeshInstance3D, convex := true):
	var cache: Dictionary = state.get_meta("shape_cache")
	
	var array_mesh := mesh_instance.mesh.get_mesh()
	var collision_shape := CollisionShape3D.new()
	if cache.has(array_mesh):
		collision_shape.shape = cache[array_mesh]
	else:
		if convex:
			collision_shape.shape = array_mesh.create_convex_shape(true, true)
		else:
			collision_shape.shape = array_mesh.create_trimesh_shape()
		cache[array_mesh] = collision_shape.shape
	
	mesh_instance.add_sibling(collision_shape)
	collision_shape.owner = mesh_instance.owner
	collision_shape.transform = mesh_instance.transform
	collision_shape.scale = MAP_SCALE

