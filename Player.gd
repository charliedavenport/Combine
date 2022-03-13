extends Node2D
class_name Player

onready var is_selecting := false
var select_origin : Vector2
const MIN_SELECT_SIZE := 1.0

signal select_bugs_rect(rect)
signal select_bug(pos, shift)
signal move_bugs_to(pos)

func _ready() -> void:
	set_process_unhandled_input(true)

func _draw() -> void:
	if not is_selecting:
		return
	var select_rect = Rect2(select_origin, get_viewport().get_mouse_position() - select_origin)
	draw_rect(select_rect, Color.white, false, 1.0)

func _process(delta) -> void:
	update()

func _unhandled_input(event):
	var mouse_pos = get_viewport().get_mouse_position()
	if event.is_action("LClick"):
		if event.is_pressed(): # left click pressed down
			is_selecting = true
			select_origin = mouse_pos
		else: # left click released
			is_selecting = false
			var select_rect = Rect2(select_origin, mouse_pos - select_origin).abs()
			emit_signal("select_bugs_rect", select_rect)
	elif event.is_action("RClick") and event.is_pressed():
		emit_signal("move_bugs_to", mouse_pos)
