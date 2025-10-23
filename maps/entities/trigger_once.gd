@tool
class_name trigger_once
extends VMFEntityNode

func _entity_ready():
	$area.body_entered.connect.call_deferred(func(_node):
		if VMFEntityNode.aliases.get("!player") == _node: 
			trigger_output("OnTrigger");
			queue_free();
	);

func _entity_setup(_vmf_entity: VMFEntity):
	$area/collision.shape = get_entity_shape();
