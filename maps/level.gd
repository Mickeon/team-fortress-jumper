extends Node3D

func _ready() -> void:
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		$WorldEnvironment.environment = load("res://maps/level_env_compat.tres")
		
		# Make this material less reflective on web builds.
		load("res://maps/test_mat.tres").roughness = 0.5
		load("res://maps/test_mat.tres").albedo_color = Color.WHITE.darkened(0.5)

