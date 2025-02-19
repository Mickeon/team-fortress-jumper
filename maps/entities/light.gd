@tool
extends ValveIONode

const FLAG_INITIALLY_DARK = 1

@export var default_light_energy = 0.0
@onready var light: Light3D = $OmniLight3D if has_node("OmniLight3D") else $SpotLight3D

func _entity_ready():
	set_process(false)
	set_physics_process(false)

func _apply_entity(ent):
	super._apply_entity(ent)

	var color = ent._light

	if ent.get("targetname", null) or ent.get("parentname", null):
		light.light_bake_mode = Light3D.BAKE_DYNAMIC
	else:
		light.light_bake_mode = Light3D.BAKE_STATIC

	if color is Vector3:
		light.light_color = Color(color.x, color.y, color.z)
		light.light_energy = 1.0
	elif color is Color:
		light.light_color = Color(color.r, color.g, color.b)
		light.light_energy = color.a
	else:
		VMFLogger.error("Invalid light: %d" % ent.id)
		get_parent().remove_child(self)
		queue_free()
		return

	if light is OmniLight3D:
		# TODO: Implement constant linear quadratic calculation.

		var radius = (1 / config.import.scale) * sqrt(light.light_energy)
		var attenuation := 1.44

		var fifty_percent_distance: float = ent.get("_fifty_percent_distance", 0.0)
		var zero_percent_distance: float  = ent.get("_zero_percent_distance", 0.0)

		if fifty_percent_distance > 0.0 or zero_percent_distance > 0.0:
			var dist50 = minf(fifty_percent_distance, zero_percent_distance) * config.import.scale
			var dist0 = maxf(fifty_percent_distance, zero_percent_distance) * config.import.scale

			attenuation = 1 / ((dist0 - dist50) / dist0)

			radius = exp(dist0)

		light.omni_range = radius
		light.omni_attenuation = attenuation

	light.shadow_enabled = true
	default_light_energy = light.light_energy
	
	hide()
