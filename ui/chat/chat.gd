extends Panel

const SERVER_ID = 1
const CHAT_CHANNEL = 2
const MAX_MESSAGES = 50
const MAX_MESSAGE_LENGTH = 96

const COLOR_DEF = Color("#FBECCB")
const COLOR_SPC = Color("#FFFFFF") ## Spectator team
const COLOR_RED = Color("#FF3D3D") ## RED Team
const COLOR_BLU = Color("#9ACDFF") ## BLU Team
const COLOR_YWL = Color("#F7DB26")
const COLOR_SYS = Color.LIME_GREEN


@export var chat_focused := true:
	set(new):
		if chat_focused == new:
			return
		
		chat_focused = new
		
		if not is_node_ready(): await ready
		
		if chat_focused:
			modulate.a = 1.0
			text.modulate.a = 1.0
			text.scroll_active = true
			if scroll_bar.page < scroll_bar.max_value:
				scroll_bar.show() # Show the scroll bar only when appropriate
			
			mouse_filter = Control.MOUSE_FILTER_STOP
			
			text.selection_enabled = true
			text.focus_mode = Control.FOCUS_ALL
			
			line_edit.focus_mode = Control.FOCUS_ALL
			line_edit.mouse_filter = Control.MOUSE_FILTER_STOP
			line_edit.mouse_default_cursor_shape = Control.CURSOR_IBEAM
			
			_previous_mouse_mode = Input.mouse_mode
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			modulate.a = 0.01
			text.modulate.a = _unfocused_text_alpha
			text.scroll_active = false # Chat should not detect the scroll wheel when unfocused.
			scroll_bar.hide()
			
			mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			text.selection_enabled = false
			text.focus_mode = Control.FOCUS_NONE
			
			line_edit.focus_mode = Control.FOCUS_NONE
			line_edit.mouse_filter = Control.MOUSE_FILTER_IGNORE
			line_edit.mouse_default_cursor_shape = Control.CURSOR_ARROW
			
			text.scroll_to_line(text.get_line_count())
			Input.mouse_mode = _previous_mouse_mode

@export var release_focus_on_submit := false

@export_group("Nodes")
@export var text: RichTextLabel 
@export var line_edit: LineEdit
@export var send_button: Button
@onready var scroll_bar: VScrollBar = text.get_v_scroll_bar()

var _previous_mouse_mode: Input.MouseMode
var _unfocused_text_alpha := 100.0:
	set(new):
		_unfocused_text_alpha = new
		
		if not chat_focused:
			text.modulate.a = _unfocused_text_alpha
var _new_message_tween: Tween

func _ready():
	scroll_bar.min_value = 1
	scroll_bar.custom_step = text.get_theme_font("normal_font").get_height(
			text.get_theme_font_size("normal_font_size"))
	#scroll_bar.step = ceil(scroll_bar.custom_step)
	
	if get_tree().current_scene != self:
		text.clear()
		# Removing the first paragraph is bugged, create one as padding.
		text.push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
		text.pop()
	
	line_edit.max_length = MAX_MESSAGE_LENGTH
	line_edit.focus_entered.connect(func(): chat_focused = true)
	set_multiplayer_authority(multiplayer.get_unique_id())

func _input(event: InputEvent):
	if event.is_action_pressed("menu_open_chat") and not line_edit.has_focus():
		line_edit.focus_mode = Control.FOCUS_ALL # Otherwise grab_focus() cannot work.
		line_edit.grab_focus()
		get_viewport().set_input_as_handled()
	
	elif (chat_focused
	and event is InputEventMouseButton 
	and event.pressed
	and event.button_index != MOUSE_BUTTON_WHEEL_UP and event.button_index != MOUSE_BUTTON_WHEEL_DOWN
	and not get_global_rect().has_point(event.global_position)):
		line_edit.release_focus()
		text.release_focus()
	
	elif event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_MB_XBUTTON1:
		send_message.rpc_id(SERVER_ID, str(randi() % 1000)) # Quick debuggin.


func _on_LineEdit_text_submitted() -> void:
	if release_focus_on_submit:
		line_edit.release_focus()
	
	var message := line_edit.text.strip_edges()
	if message.is_empty():
		return
	
	line_edit.clear()
	#if message.is_valid_int():
		# For testing, you shouldn't be able to do this.
		#send_message.rpc_id(message.to_int(), "Teehee")
		#return
	
	send_message.rpc_id(SERVER_ID, message)

func _on_LineEdit_text_changed() -> void:
	send_button.disabled = line_edit.text.is_empty()

func _on_LineEdit_text_change_rejected() -> void:
	$Fail.play()
	create_tween().tween_property(line_edit, "self_modulate", Color.WHITE, 0.5).from(Color.CRIMSON)

func _on_LineEdit_or_Text_focus_exited() -> void:
	await get_tree().process_frame # We need to know the new focus owner, if any.
	var new_focus_owner := get_viewport().gui_get_focus_owner()
	if new_focus_owner != text and new_focus_owner != line_edit:
		chat_focused = false


@rpc("any_peer", "call_local", "reliable", CHAT_CHANNEL)
func send_message(message: String):
	if not multiplayer.is_server():
		#modulate.s = randf_range(0.25, 0.75) # Some code to see that it actually works.
		#modulate.h += randf_range(0.25, 0.75)
		return # Someone's being a lil' malicious.
	
	var adjusted_message := message
	
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		adjusted_message = "[color=%s]%s[/color]" % [COLOR_SYS.to_html(), message]
	else:
		adjusted_message = "[color=%s]%s[/color] : %s" % [
			_get_team_color_html(sender_id),
			_get_username(sender_id),
			strip_bbcode(message)
		]
	
	append_to_chat.rpc(adjusted_message)

@rpc("authority", "call_local", "reliable", CHAT_CHANNEL)
func append_to_chat(additional: String):
	text.push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
	text.append_text(additional)
	text.pop() #text.newline()
	
	if text.get_paragraph_count() > MAX_MESSAGES:
		for _i in MAX_MESSAGES / 10.0:
			# For some reason removing the first paragraph (0) is bugged.
			# Deferred because it would crash otherwise.
			#text.remove_paragraph.call_deferred(1)
			text.remove_paragraph(1)
	
	_scroll_to_new_message()
	_flash_for_new_message()


func _scroll_to_new_message():
	if not text.is_ready(): await text.finished
	
	if chat_focused:
		var scroll_bar_handle_bottom := scroll_bar.value + scroll_bar.page 
		var scroll_bar_limit_bottom := scroll_bar.max_value - scroll_bar.min_value - 32
		
		if scroll_bar_handle_bottom >= scroll_bar_limit_bottom:
			# Only scroll when already at the bottom.
			text.scroll_to_line(text.get_line_count())
	else:
		text.scroll_to_line(text.get_line_count())

func _flash_for_new_message():
	if not text.is_ready(): await text.finished
	
	if _new_message_tween:
		_new_message_tween.kill()
	
	_new_message_tween = create_tween()
	_new_message_tween.tween_property(self, "_unfocused_text_alpha", 0.0, 15.0).from(100.0
			).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)


func _get_team_color_html(for_id: int) -> String:
	# TODO: Actually have this work over being random.
	if for_id == 0:
		return COLOR_SYS.to_html()
	if for_id == SERVER_ID:
		return COLOR_YWL.to_html()
	
	return [COLOR_RED, COLOR_BLU, COLOR_SPC][
			multiplayer.get_peers().find(for_id) % 3
	].to_html()

static func _get_username(for_id: int) -> String:
	if for_id == 0:
		return "System"
	
	return "Host" if for_id == SERVER_ID else "C_" + String.num_int64(for_id, 32, true)

static func strip_bbcode(a: String) -> String:
	var result := ""
	var from := 0
	while true:
		var lb_pos := a.find("[", from)
		if (lb_pos < 0):
			break
		
		var rb_pos := a.find("]", lb_pos + 1)
		if (rb_pos < 0):
			break
		
		result += a.substr(from, lb_pos - from)
		from = rb_pos + 1;
	
	result += a.substr(from)
	# Remove remaining special characters to avoid security issues with concatenation.
	return result.replace("[", "").replace("]", "");

