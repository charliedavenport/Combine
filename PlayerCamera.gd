extends Camera2D

const SLOW_MARGIN := 75.0
const FAST_MARGIN := 30.0
const SLOW_SPEED := 200.0
const FAST_SPEED := 750.0

const MIN_ZOOM := Vector2(0.75, 0.75)
const MAX_ZOOM := Vector2(1.5, 1.5)
const ZOOM_STEP := Vector2(0.25, 0.25)

const MAX_X := 4100
const MAX_Y := 4100

func _process(delta):
	var mouse_pos := get_viewport().get_mouse_position()
	var viewport_rect := get_viewport_rect()
	var cam_vel := Vector2.ZERO
	# RIGHT
	if mouse_pos.x > get_viewport_rect().end.x - FAST_MARGIN:
		cam_vel.x = FAST_SPEED
	elif mouse_pos.x > get_viewport_rect().end.x - SLOW_MARGIN:
		cam_vel.x = SLOW_SPEED
	# LEFT
	elif mouse_pos.x < get_viewport_rect().position.x + FAST_MARGIN:
		cam_vel.x = -FAST_SPEED
	elif mouse_pos.x < get_viewport_rect().position.x + SLOW_MARGIN:
		cam_vel.x = -SLOW_SPEED
	# DOWN
	if mouse_pos.y > get_viewport_rect().end.y - FAST_MARGIN:
		cam_vel.y = FAST_SPEED
	elif mouse_pos.y > get_viewport_rect().end.y - SLOW_MARGIN:
		cam_vel.y = SLOW_SPEED
	# UP
	elif mouse_pos.y < get_viewport_rect().position.y + FAST_MARGIN:
		cam_vel.y = -FAST_SPEED
	elif mouse_pos.y < get_viewport_rect().position.y + SLOW_MARGIN:
		cam_vel.y = -SLOW_SPEED
	var prev_pos = global_position
	global_position = global_position + (cam_vel * delta)
	if global_position.x > MAX_X or global_position.x < 0 or global_position.y > MAX_Y or global_position.y < 0:
		global_position = prev_pos

func _input(event) -> void:
	if event.is_action_pressed("cam_zoom_out") and zoom.x < MAX_ZOOM.x:
		zoom += ZOOM_STEP
	elif event.is_action_pressed("cam_zoom_in") and zoom.x > MIN_ZOOM.x:
		zoom -= ZOOM_STEP

