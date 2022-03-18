extends KinematicBody2D
class_name Bug

const MOVE_SPEED := 150.0
const MIN_SPEED := 10.0
const MAX_HP := 100.0

const enemy_sprite = preload("res://ant_spritesheet.png")
const friendly_sprite = preload("res://ant_infected_spritesheet.png")

enum State {IDLE, MOVING, ATTACKING}
var curr_state : int

onready var sprite = get_node("Sprite")
onready var selected_sprite = get_node("Selected")
onready var atk_area = get_node("AttackableArea")
onready var atk_timer = get_node("AtkTimer")
onready var anim = get_node("AnimationPlayer")
onready var particles = get_node("CPUParticles2D")
onready var bug_gui = get_node("BugGUI")

export var is_enemy : bool
export var atk_damage := 10.0
export var atk_rate := 1.0
export var draw_path := false

var path : Array
var target_bug
var hp : float

signal bug_killed(_bug)
signal bug_infected(_bug)

func _ready() -> void:
	set_enemy(is_enemy)
	atk_area.connect("body_entered", self, "on_body_entered")
	atk_timer.wait_time = atk_rate
	anim.play("idle")
	sprite.material.set_shader_param("outline_width", 0)
	hp = MAX_HP

func _draw() -> void:
	var last_point = Vector2.ZERO
	var transf = get_parent().global_transform
	for point in path:
		var target = global_transform.xform_inv(point)
		draw_line(last_point, target, Color.white)
		last_point = target

func set_enemy(_value : bool) -> void:
	is_enemy = _value
	bug_gui.set_enemy(is_enemy)
	if is_enemy:
		#sprite.modulate = Color.red
		self.collision_layer = 4 # enemy
		atk_area.collision_mask = 2 # player
		sprite.texture = enemy_sprite
		particles.emitting = false
	else:
		#sprite.modulate = Color.white
		self.collision_layer = 2 # player
		atk_area.collision_mask = 4 # enemy
		sprite.texture = friendly_sprite
		particles.emitting = true

func _process(delta) -> void:
	if draw_path:
		update()

func _physics_process(delta) -> void:
	if curr_state == State.MOVING:
		move_along_path(MOVE_SPEED)

func set_state(_value) -> void:
	pass # TODO

func highlight(_value : bool) -> void:
	sprite.material.set_shader_param("outline_width", 10 if _value else 0)
	#selected_sprite.visible = _value

func start_moving_along_path() -> void:
	curr_state = State.MOVING
	anim.play("walk")

func move_along_path(_dist) -> void:
	var last_point = global_position
	while path.size() > 0:
		var dist_to_next_point = last_point.distance_to(path[0])
		# The position to move to falls between two points.
		if dist_to_next_point > 15.0:
			var vel = (path[0] - last_point) * (_dist / dist_to_next_point)
			sprite.flip_h = (vel.x < 0)
			vel = move_and_slide(vel)
			if path.size() <= 1 and vel.length() < MIN_SPEED and get_slide_count() > 0:
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
	anim.play("idle")

func start_attacking(_target) -> void:
	if is_enemy:
		return
	anim.play("idle")
	target_bug = _target
	curr_state = State.ATTACKING
#	sprite.texture = atk_sprite
	#target_bug.connect("bug_killed", self, "on_target_killed")
	target_bug.connect("bug_infected", self, "on_target_killed")
	print(self.name + " attacking " + target_bug.name)
	while curr_state == State.ATTACKING:
		atk_timer.start()
		yield(atk_timer, "timeout")
		if curr_state != State.ATTACKING:
			return
		target_bug.damage(atk_damage)

func on_target_killed(_bug) -> void:
	curr_state = State.IDLE
	target_bug = null
#	sprite.texture = idle_sprite

func on_body_entered(body) -> void:
	if curr_state != State.ATTACKING:
		start_attacking(body)

func infect() -> void:
	hp = 100.0
	bug_gui.set_hp(hp)
	emit_signal("bug_infected", self)
	set_enemy(false)
	#sprite.texture = friendly_sprite

func kill() -> void:
	print(name + " is killed")
	emit_signal("bug_killed", self)
	queue_free()

func damage(_value : float) -> void:
	#print(name + " is damaged for " + str(_value))
	anim.play("flash")
	hp -= _value
	bug_gui.set_hp(hp)
	if hp <= 0:
		#kill()
		infect()

func on_flash_anim_end() -> void:
	anim.play("idle")
