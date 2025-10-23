@tool
extends VMFEntityNode


func _entity_ready():
	set_process(false)
	set_physics_process(false)

func _entity_setup(vmf_entity: VMFEntity):
	var data := vmf_entity.data
	
	var import_scale := VMFConfig.import.scale
	
	var decal: Decal = $Decal
	var material: BaseMaterial3D = VMTLoader.get_material(data.material)
	if not material:
		return
	
	var basis_normal: Vector3 = convert_vector(data.BasisNormal)
	#var basis_u: Vector3 = convert_vector(data.BasisU)
	#var basis_v: Vector3 = convert_vector(data.BasisV)
	
	if basis_normal != Vector3.UP:
		look_at(global_position + basis_normal)
	rotation.y += PI
	
	decal.texture_albedo = material.albedo_texture
	# Severe approximation.
	decal.size.x = abs(data.uv0.x * import_scale * 2)
	decal.size.z = abs(data.uv0.y * import_scale * 2)
	
	name = material.resource_path.get_file().get_basename()
