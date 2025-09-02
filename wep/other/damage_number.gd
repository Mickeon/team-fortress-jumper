extends Label3D

var damage := 0:
	set(new):
		damage = new
		text = str(damage)


func _process(delta: float) -> void:
	transparency += delta
	offset.y += delta * 2
	if transparency >= 1.0:
		queue_free()
