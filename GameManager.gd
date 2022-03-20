extends Navigation2D
class_name GameManager

onready var player = get_node("Player")
onready var gui = get_node("CanvasLayer/GUI")
onready var game_over_check_timer = get_node("GameOverCheckTimer")

var selected_bugs : Array
var enemy_bugs : Array
var friendly_bugs : Array
var selected_enemy

func _ready() -> void:
	player.connect("player_begin_select", self, "on_player_begin_select")
	player.select_area.connect("body_entered", self, "on_player_select_body_entered")
	player.select_area.connect("body_exited", self, "on_player_select_body_exited")
	player.connect("move_bugs_to", self, "on_move_bugs_to")
	player.connect("player_sacrifice_bug", self, "on_sacrifice_bug")
	for child in get_children():
		if child is Bug:
			child.connect("bug_killed", self, "on_bug_killed")
			child.connect("bug_infected", self, "on_bug_infected")
			child.connect("bug_path_request", self, "on_bug_path_request")
			if child.is_enemy:
				enemy_bugs.append(child)
				child.connect("mouse_entered", self, "on_enemy_mouse_entered", [child])
				child.connect("mouse_exited", self, "on_enemy_mouse_exited", [child])
			else:
				friendly_bugs.append(child)
	update_gui()

func update_gui() -> void:
	gui.set_enemy_ants(enemy_bugs.size())
	gui.set_infected_ants(friendly_bugs.size())

func check_game_over() -> void:
	game_over_check_timer.wait_time = 0.5
	game_over_check_timer.start()
	yield(game_over_check_timer, "timeout")
	if friendly_bugs.size() == 0:
		gui.game_over(false)
	elif enemy_bugs.size() == 0:
		gui.game_over(true)


func on_player_select_body_entered(body) -> void:
	if not player.is_selecting:
		return
	if body is Bug and not body.is_enemy and not body.is_dead:
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
	else:
		friendly_bugs.erase(_bug)
		selected_bugs.erase(_bug)
	check_game_over()
	update_gui()

func on_bug_infected(_bug) -> void:
	enemy_bugs.erase(_bug)
	friendly_bugs.append(_bug)
	if _bug == selected_enemy:
		selected_enemy = null
		_bug.highlight(false)
	check_game_over()
	update_gui()

func on_bug_path_request(_bug, _pos) -> void:
	var path = get_simple_path(_bug.global_position, _pos, true)
	_bug.path = path
	_bug.start_moving_along_path()

func on_sacrifice_bug() -> void:
	if selected_bugs.size() != 1:
		return
	selected_bugs[0].sacrifice()
