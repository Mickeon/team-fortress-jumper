@tool
extends VMFEntityNode

func _entity_setup(vmf_entity: VMFEntity):
	var mesh = get_mesh();
	$MeshInstance3D.cast_shadow = vmf_entity.data.get("disableshadows", 0) == 0;

	if !mesh or mesh.get_surface_count() == 0:
		queue_free();
		return;

	$MeshInstance3D.set_mesh(get_mesh());
	$MeshInstance3D/StaticBody3D/CollisionShape3D.shape = $MeshInstance3D.mesh.create_trimesh_shape();
