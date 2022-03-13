extends Navigation2D
class_name GameManager

onready var player = get_node("Player")
var selected_bugs : Array

func _ready() -> void:
	player.connect("select_bugs_rect", self, "on_select_bugs_rect")
	player.connect("select_bug", self, "on_select_bug")
	player.connect("move_bugs_to", self, "on_move_bugs_to")

func on_select_bugs_rect(_rect) -> void:
	selected_bugs = []
	for child in get_children():
		if child is Bug:
			child.deselect()
	for child in get_children():
		if child is Bug and _rect.has_point(child.global_position):
			child.select()
			selected_bugs.append(child)
#	if selected_bugs.size() > 0:
#		player.set_state(player.State.BUGS_SELECTED)
#	else:
#		player.set_state(player.State.IDLE)

func on_select_bug(_pos, _shift) -> void:
	pass

func on_move_bugs_to(_pos) -> void:
	for bug in selected_bugs:
		var path = get_simple_path(bug.global_position, _pos)
		path.remove(0)
		bug.path = path
		bug.start_moving_along_path()
