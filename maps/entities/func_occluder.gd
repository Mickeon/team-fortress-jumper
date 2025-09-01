@tool
extends ValveIONode

## Entity setup method. Called during the map import process. Do additional setup for the entity here.
func _apply_entity(entity: Dictionary) -> void:
	super._apply_entity(entity);

	var occluder := get_node("occluder") as OccluderInstance3D;
	var shape := ArrayOccluder3D.new();

	var vertices = get_entity_trimesh_shape().get_faces();
	shape.set_arrays(vertices, range(0, vertices.size()));
	occluder.occluder = shape;
