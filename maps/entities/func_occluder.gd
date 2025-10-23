@tool
extends VMFEntityNode


func _entity_setup(vmf_entity: VMFEntity) -> void:
	var occluder := get_node("occluder") as OccluderInstance3D;
	var shape := ArrayOccluder3D.new();

	var vertices := get_entity_trimesh_shape().get_faces();
	shape.set_arrays(vertices, range(0, vertices.size()));
	occluder.occluder = shape;
