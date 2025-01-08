@tool
extends ValveIONode


func _entity_ready():
	set_process(false)
	set_physics_process(false)

func _apply_entity(ent):
	super._apply_entity(ent)
	
	var import_scale := VMFConfig.import.scale
	
	var decal: Decal = $Decal
	var material: BaseMaterial3D = VMFTool.get_material(ent.material)
	if not material:
		return
	
	var basis_normal: Vector3 = convert_vector(ent.BasisNormal)
	#var basis_u: Vector3 = convert_vector(ent.BasisU)
	#var basis_v: Vector3 = convert_vector(ent.BasisV)
	
	if basis_normal != Vector3.UP:
		look_at(global_position + basis_normal)
	rotation.y += PI
	
	decal.texture_albedo = material.albedo_texture
	# Severe approximation.
	decal.size.x = abs(ent.uv0.x * import_scale * 2)
	decal.size.z = abs(ent.uv0.y * import_scale * 2)
	
	name = material.resource_path.get_file().get_basename()
