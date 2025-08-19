extends Decal


func _init() -> void:
	sorting_offset = randf_range(0.0, 100.0) # Lazy approach to avoid Z-fighting.
	if randi() % 2:
		texture_albedo = preload("res://wep/other/decals/scorch/scorch2.png")
