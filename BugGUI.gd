extends Control

const enemy_hp_tex = preload("res://ant_color.png")
const infected_hp_tex = preload("res://infected_color.png")

onready var health_bar = get_node("TextureProgress")

func set_enemy(_value : bool) -> void:
	if _value:
		health_bar.texture_progress = enemy_hp_tex
	else:
		health_bar.texture_progress = infected_hp_tex

func set_hp(_value : float) -> void:
	health_bar.value = _value
