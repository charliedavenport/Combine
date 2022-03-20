extends KinematicBody2D
class_name Bug

const MOVE_SPEED := 150.0
const MIN_SPEED := 10.0
const MAX_HP := 100.0
const ENEMY_REACTION_TIME := 0.5
const INFECTION_RATE := 0.25
const INFECTION_AMOUNT := 3.0
const PATH_UPDATE_INTERVAL := 0.5

const enemy_sprite = preload("res://ant_spritesheet.png")
const friendly_sprite = preload("res://ant_infected_spritesheet.png")

enum State {IDLE, MOVING, ATTACKING}
var curr_state : int

onready var sprite = get_node("Sprite")
onready var selected_sprite = get_node("Selected")
onready var infect_area = get_node("InfectArea")
onready var atk_area = get_node("AttackableArea")
onready var atk_timer = get_node("AtkTimer")
onready var infect_timer = get_node("InfectTimer")
onready var flip_h_timer = get_node("FlipHTimer")
onready var enemy_reaction_timer = get_node("EnemyReactionTimer")
onready var path_update_timer = get_node("PathUpdateTimer")
onready var anim = get_node("AnimationPlayer")
onready var particles = get_node("CPUParticles2D")
onready var bug_gui = get_node("BugGUI")
onready var enemy_vision = get_node("EnemyVisionArea")
onready var tween = get_node("Tween")

export var is_enemy : bool
export var is_enemy_patrol : bool
export var atk_damage := 10.0
export var atk_rate := 1.0
export var draw_path := false
export var is_facing_left : bool

var path : Array
var target_bug
var hp : float
var infect_level : float
var is_enemy_chasing : bool
var nearby_infected : Array
var is_being_infected : bool

signal bug_killed(_bug)
signal bug_infected(_bug)
signal bug_path_request(_bug, pos)

func _ready() -> void:
	set_enemy(is_enemy)
	atk_area.connect("body_entered", self, "on_atk_body_entered")
	atk_area.connect("body_exited", self, "on_atk_body_exited")
	infect_area.connect("body_entered", self, "on_infect_body_entered")
	infect_area.connect("body_exited", self, "on_infect_body_exited")
	atk_timer.wait_time = atk_rate
	enemy_reaction_timer.wait_time = ENEMY_REACTION_TIME
	path_update_timer.wait_time = PATH_UPDATE_INTERVAL
	anim.play("idle")
	sprite.material.set_shader_param("line_thickness", 0)
	hp = MAX_HP
	infect_level = 0
	is_enemy_chasing = false
	particles.emission_sphere_radius = infect_area.get_node("CollisionShape2D").shape.radius
	nearby_infected = []
	spread_infection()

func _draw() -> void:
	var last_point = Vector2.ZERO
	var transf = get_parent().global_transform
	for point in path:
		var target = global_transform.xform_inv(point)
		draw_line(last_point, target, Color.white)
		last_point = target

func spread_infection() -> void:
	infect_timer.wait_time = INFECTION_RATE
	while true:
		infect_timer.start()
		yield(infect_timer, "timeout")
		if nearby_infected.size() > 0:
			self.add_infection(INFECTION_AMOUNT)

func set_enemy(_value : bool) -> void:
	is_enemy = _value
	bug_gui.set_enemy(is_enemy)
	if is_enemy:
		self.collision_layer = 4 # enemy
		atk_area.collision_mask = 2 # player
		enemy_vision.collision_mask = 2
		sprite.texture = enemy_sprite
		particles.emitting = false
		enemy_vision.monitoring = true
		infect_area.monitoring = true
		infect_area.visible = true
		if not enemy_vision.is_connected("body_entered", self, "on_enemy_vision_body_entered"):
			enemy_vision.connect("body_entered", self, "on_enemy_vision_body_entered")
	else:
		self.collision_layer = 2 # player
		atk_area.collision_mask = 4 # enemy
		enemy_vision.collision_mask = 0
		enemy_vision.visible = false
		sprite.texture = friendly_sprite
		particles.emitting = true
		enemy_vision.monitoring = false
		infect_area.monitoring = false
		infect_area.visible = false
		if enemy_vision.is_connected("body_entered", self, "on_enemy_vision_body_entered"):
			enemy_vision.disconnect("body_entered", self, "on_enemy_vision_body_entered")

func _process(delta) -> void:
	if draw_path:
		update()

func _physics_process(delta) -> void:
	sprite.flip_h = is_facing_left
	enemy_vision.scale.x = -1 if is_facing_left else 1
	if curr_state == State.MOVING:
		move_along_path(MOVE_SPEED)

func set_state(_value) -> void:
	pass # TODO

func highlight(_value : bool) -> void:
	sprite.material.set_shader_param("line_thickness", 10 if _value else 0)

func start_moving_along_path() -> void:
	curr_state = State.MOVING
	anim.play("walk")
	# flip left or right
	if path.size() >= 1:
		is_facing_left = path[1].x < global_position.x

func move_along_path(_dist) -> void:
	var last_point = global_position
	while path.size() > 0:
		var dist_to_next_point = last_point.distance_to(path[0])
		# The position to move to falls between two points.
		if dist_to_next_point > 15.0:
			var vel = (path[0] - last_point) * (_dist / dist_to_next_point)
			vel = move_and_slide(vel)
			# check for overlapping enemies
			var bods = atk_area.get_overlapping_areas()
			for b in bods:
				if b.is_enemy != is_enemy:
					start_attacking(b)
			if flip_h_timer.is_stopped():
				is_facing_left = (vel.x < 0)
				flip_h_timer.start()
			return
		# The position is past the end of the segment.
		_dist -= dist_to_next_point
		last_point = path[0]
		path.remove(0)
	# The character reached the end of the path.
	path = []
	curr_state = State.IDLE
	anim.play("idle")

func start_attacking(_target) -> void:
	anim.play("idle")
	target_bug = _target
	curr_state = State.ATTACKING
#	sprite.texture = atk_sprite
	if not is_enemy and not target_bug.is_connected("bug_infected", self, "on_target_killed"):
		target_bug.connect("bug_infected", self, "on_target_killed")
	elif is_enemy and not target_bug.is_connected("bug_killed", self, "on_target_killed"):
		target_bug.connect("bug_killed", self, "on_target_killed")
	print(self.name + " attacking " + target_bug.name)
	while curr_state == State.ATTACKING:
		atk_timer.start()
		yield(atk_timer, "timeout")
		if curr_state != State.ATTACKING or not is_instance_valid(target_bug) or not target_bug:
			return
		target_bug.damage(atk_damage)

func on_target_killed(_bug) -> void:
	curr_state = State.IDLE
	target_bug = null
#	sprite.texture = idle_sprite

func on_atk_body_entered(_body) -> void:
	is_enemy_chasing = false
	if curr_state != State.ATTACKING:
		start_attacking(_body)

func on_atk_body_exited(_body) -> void:
	if is_enemy and is_instance_valid(target_bug) and target_bug:
		enemy_reaction_timer.start()
		yield(enemy_reaction_timer, "timeout")
		#yield(get_tree().create_timer(ENEMY_REACTION_TIME), "timeout")
		start_chasing(target_bug)
	else:
		stop_attacking()

func on_infect_body_entered(_body) -> void:
	nearby_infected.append(_body)

func on_infect_body_exited(_body) -> void:
	nearby_infected.erase(_body)

func stop_attacking() -> void:
	if is_enemy:
		curr_state = State.IDLE
	target_bug = null

func infect() -> void:
	#hp = 100.0
	#bug_gui.set_hp(hp)
	emit_signal("bug_infected", self)
	set_enemy(false)
	curr_state = State.IDLE

func kill() -> void:
	print(name + " is killed")
	emit_signal("bug_killed", self)
	queue_free()

func damage(_value : float) -> void:
	#print(name + " is damaged for " + str(_value))
	flash()
	hp -= _value
	bug_gui.set_hp(hp)
	if hp <= 0:
		kill()

func add_infection(_value : float) -> void:
	if not is_enemy:
		return
	infect_level += INFECTION_AMOUNT
	bug_gui.set_infection(infect_level)
	if infect_level >= 100:
		infect()

func flash() -> void:
	tween.interpolate_property(sprite.get_material(), "shader_param/flash_amount", 
			1.0, 0.0, 0.5)
	tween.start()

func start_chasing(_bug) -> void:
	if not is_instance_valid(_bug):
		return
	emit_signal("bug_path_request", self, _bug.global_position)
	is_enemy_chasing = true
	while is_enemy_chasing:
		path_update_timer.start()
		yield(path_update_timer, "timeout")
		if is_enemy_chasing and is_instance_valid(_bug):
			emit_signal("bug_path_request", self, _bug.global_position)

func on_enemy_vision_body_entered(_body) -> void:
	start_chasing(_body)
