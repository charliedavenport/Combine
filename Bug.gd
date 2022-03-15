extends KinematicBody2D
class_name Bug

const MOVE_SPEED := 100.0
const MIN_SPEED := 10.0

enum State {IDLE, MOVING, ATTACKING}
var curr_state : int

onready var is_selected := false
onready var sprite = get_node("Sprite")
onready var selected_sprite = get_node("Selected")

export var is_enemy : bool

var path : Array

func _ready() -> void:
	if is_enemy:
		sprite.modulate = Color.red

func _draw() -> void:
	var last_point = Vector2.ZERO
	var transf = get_parent().global_transform
	for point in path:
		var target = global_transform.xform_inv(point)
		draw_line(last_point, target, Color.white)
		last_point = target

func _process(delta) -> void:
	update()

func _physics_process(delta) -> void:
	if curr_state == State.MOVING:
		move_along_path(MOVE_SPEED)

func select() -> void:
	if is_selected or is_enemy:
		return
	is_selected = true
	selected_sprite.visible = true

func deselect() -> void:
	if not is_selected:
		return
	is_selected = false
	selected_sprite.visible = false

func start_moving_along_path() -> void:
	curr_state = State.MOVING

func move_along_path(_dist) -> void:
	var last_point = global_position
	while path.size() > 0:
		var dist_to_next_point = last_point.distance_to(path[0])
		# The position to move to falls between two points.
		if dist_to_next_point > 15.0:
			var vel = (path[0] - last_point) * (_dist / dist_to_next_point)
			vel = move_and_slide(vel)
			if path.size() <= 2 and vel.length() < MIN_SPEED and get_slide_count() > 0:
				#print('bug stopping because blocked')
				break
			return
		# The position is past the end of the segment.
		_dist -= dist_to_next_point
		last_point = path[0]
		path.remove(0)
	# The character reached the end of the path.
	#global_position = last_point
	path = []
	curr_state = State.IDLE
