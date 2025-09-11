extends Label3D

var fade_multiplier := 1.0
var damage := 0:
	set(new):
		damage = new
		text = str(damage)


func _process(delta: float) -> void:
	transparency += delta * fade_multiplier
	offset.y += delta * 2
	if transparency >= 1.0:
		queue_free()
