extends Control

onready var enemy_ants_label = get_node("EnemyAntsLabel")
onready var infected_ants_label = get_node("InfectedAntsLabel")
onready var game_over_label = get_node("GameOverLabel")

func _ready() -> void:
	game_over_label.visible = false

func set_enemy_ants(_value : int) -> void:
	enemy_ants_label.text = "Enemy Ants: " + str(_value)

func set_infected_ants(_value : int) -> void:
	infected_ants_label.text = "Infected Ants: " + str(_value)

func game_over(_win : bool) -> void:
	game_over_label.visible = true
	if _win:
		game_over_label.text = "Game Over\nYou Win!"
	else:
		game_over_label.text = "Game Over\nYou Lose!"
