extends Control

const enemy_hp_tex = preload("res://ant_color.png")
const infected_hp_tex = preload("res://infected_color.png")

onready var health_bar = get_node("HealthBar")
onready var infect_bar = get_node("InfectBar")

func set_enemy(_is_enemy : bool) -> void:
	if _is_enemy:
		health_bar.texture_progress = enemy_hp_tex
		infect_bar.visible = true
	else:
		health_bar.texture_progress = infected_hp_tex
		infect_bar.visible = false

func set_hp(_value : float) -> void:
	health_bar.value = _value

func set_infection(_value : float) -> void:
	infect_bar.value = _value
