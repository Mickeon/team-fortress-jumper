extends RewindableAction


var _active := false
var _confirmed := false

func set_active(new_active: bool, _tick := 0) -> void:
	if _active == new_active:
		return
	
	_active = new_active
	_confirmed = new_active
	if _confirmed:
		set_deferred(&"confirmed", false)

func is_active(_tick := 0) -> bool:
	return _active

func has_confirmed() -> bool:
	return _confirmed

func get_status(_tick := 0) -> int:
	return ACTIVE if is_active() else INACTIVE

func set_context(value: Variant, tick := 0) -> void:
	super(value, tick)
	erase_context.call_deferred(tick)

func mutate(_target: Object) -> void:
	pass

func _enter_tree() -> void:
	pass

func _exit_tree() -> void:
	pass
