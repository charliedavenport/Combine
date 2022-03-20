extends Node2D
class_name Player

onready var cam = get_node("PlayerCamera")
onready var select_area = get_node("SelectArea")
onready var select_shape = get_node("SelectArea/CollisionShape2D")
var select_rect : Rect2

onready var is_selecting := false
var select_origin : Vector2
const MIN_SELECT_SIZE := 1.0

signal player_begin_select
signal move_bugs_to(pos)
signal player_sacrifice_bug

func _ready() -> void:
	set_process_unhandled_input(true)
	select_area.set_as_toplevel(true)

func _draw() -> void:
	if not is_selecting:
		return
	draw_rect(select_rect, Color.white, false, 1.0)

func _process(delta) -> void:
	var mouse_pos = cam.get_global_mouse_position()
	select_rect = Rect2(select_origin, mouse_pos - select_origin).abs()
	update()
	if is_selecting:
		select_shape.shape.set_extents(select_rect.size * 0.5)
		select_area.position = select_rect.position + (0.5 * select_rect.size)

func _unhandled_input(event):
	var mouse_pos = cam.get_global_mouse_position()
	if event.is_action("LClick"):
		if event.is_pressed(): # left click pressed down
			is_selecting = true
			select_origin = mouse_pos
			select_area.monitoring = true
			emit_signal("player_begin_select")
		else: # left click released
			is_selecting = false
			select_area.monitoring = false
	elif event.is_action("RClick") and event.is_pressed():
		emit_signal("move_bugs_to", mouse_pos)
	elif event.is_action_pressed("sacrifice_bug"):
		emit_signal("player_sacrifice_bug")
