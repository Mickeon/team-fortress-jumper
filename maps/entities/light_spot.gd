@tool
extends "light.gd"


func _entity_setup(vmf_entity: VMFEntity):
	super._entity_setup(vmf_entity)
	var data := vmf_entity.data

	light.spot_angle = data._cone
	light.light_energy = data._light.a
	default_light_energy = light.light_energy
	vmf_entity.angles.z = data.get("pitch", -90)
	vmf_entity.angles.x = 0

	basis = get_entity_basis(vmf_entity)
	global_rotation.y -= PI / 2
