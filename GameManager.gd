extends Navigation2D
class_name GameManager

onready var player = get_node("Player")
var selected_bugs : Array
var enemy_bugs : Array
var selected_enemy

func _ready() -> void:
	player.connect("player_begin_select", self, "on_player_begin_select")
	player.select_area.connect("body_entered", self, "on_player_select_body_entered")
	player.select_area.connect("body_exited", self, "on_player_select_body_exited")
	player.connect("move_bugs_to", self, "on_move_bugs_to")
	for child in get_children():
		if child is Bug:
			child.connect("bug_killed", self, "on_bug_killed")
			if child.is_enemy:
				enemy_bugs.append(child)
				child.connect("mouse_entered", self, "on_enemy_mouse_entered", [child])
				child.connect("mouse_exited", self, "on_enemy_mouse_exited", [child])

func on_player_select_body_entered(body) -> void:
	if not player.is_selecting:
		return
	if body is Bug and not body.is_enemy:
		body.highlight(true)
		selected_bugs.append(body)

func on_player_select_body_exited(body) -> void:
	if not player.is_selecting:
		return
	if body is Bug and not body.is_enemy:
		body.highlight(false)
		selected_bugs.erase(body)

func on_player_begin_select() -> void:
	for bug in selected_bugs:
		bug.highlight(false)
	for bug in enemy_bugs:
		bug.highlight(false)
	selected_bugs = []

func on_move_bugs_to(_pos) -> void:
	var target_pos = selected_enemy.global_position if (is_instance_valid(selected_enemy) and selected_enemy) else _pos
	for bug in selected_bugs:
		var path = get_simple_path(bug.global_position, target_pos, true)
		#path.remove(0)
		bug.path = path
		bug.start_moving_along_path()

func on_enemy_mouse_entered(_bug) -> void:
	# only care about enemies when we have units selected
	if selected_bugs.empty():
		return
	if _bug is Bug and _bug.is_enemy:
		_bug.highlight(true)
		selected_enemy = _bug

func on_enemy_mouse_exited(_bug) -> void:
	# only care about enemies when we have units selected
	if selected_bugs.empty():
		return
	if _bug is Bug and _bug.is_enemy:
		_bug.highlight(false)
		selected_enemy = null

func on_bug_killed(_bug) -> void:
	if _bug.is_enemy:
		enemy_bugs.erase(_bug)

