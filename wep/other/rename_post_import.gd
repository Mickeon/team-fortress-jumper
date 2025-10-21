@tool
extends EditorScenePostImport

# This is one petty hack because for some reason the names of these nodes
# have suddenly changed after many imports, causing lost references around the place.

const rename_map = {
	"models_weapons_c_models_c_shotgun_c_shotgun_reference_001": "c_shotgun",
	"soldier_model": "mesh",
	"c_soldier_arms": "mesh",
	"c_shovel_reference": "c_shovel",
}

func _post_import(scene: Node):
	iterate(scene)
	return scene

func iterate(node: Node):
	if not node:
		return
	
	if rename_map.has(node.name):
		node.name = rename_map[node.name]
	
	for child in node.get_children():
		iterate(child)

