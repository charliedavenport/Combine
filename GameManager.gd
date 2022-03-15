extends Navigation2D
class_name GameManager

onready var player = get_node("Player")
var selected_bugs : Array

func _ready() -> void:
	player.connect("player_begin_select", self, "on_player_begin_select")
	player.select_area.connect("body_entered", self, "on_player_select_body_entered")
	player.select_area.connect("body_exited", self, "on_player_select_body_exited")
	player.connect("move_bugs_to", self, "on_move_bugs_to")

func on_player_select_body_entered(body) -> void:
	if not player.is_selecting:
		return
	if body is Bug and not body.is_enemy:
		body.select()
		selected_bugs.append(body)

func on_player_select_body_exited(body) -> void:
	if not player.is_selecting:
		return
	if body is Bug and not body.is_enemy:
		body.deselect()
		selected_bugs.erase(body)

func on_player_begin_select() -> void:
	for bug in selected_bugs:
		bug.deselect()
	selected_bugs = []

func on_move_bugs_to(_pos) -> void:
	for bug in selected_bugs:
		var path = get_simple_path(bug.global_position, _pos)
		path.remove(0)
		bug.path = path
		bug.start_moving_along_path()
