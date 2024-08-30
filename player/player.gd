extends CharacterBody2D
signal shoot
signal switch_lever

const BASE_SPEED = 150.0
const JUMP_VELOCITY = -400.0
@onready var start_position := position
@export var max_jump_charges := 2
var speed := BASE_SPEED
var jump_charges := max_jump_charges
var on_climbable := false
var wall_jumping := false # necessary so you can't climb walls with spam jumping
var on_belt_lever := false
var belt_dir: float
var direction: float
var lever: RID

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		belt_dir = 0
	if not on_climbable:
		velocity.y = minf(Global.TERMINAL_VELOCITY, velocity.y + Global.gravity * delta) # Fall
		if Input.is_action_just_pressed(&"jump"):
			try_jump()
		elif Input.is_action_just_released(&"jump") and velocity.y < 0.0:
			velocity.y *= 0.6 # The player let go of jump early, reduce vertical momentum
	else: # climb dat ladder/rope
		if Input.is_action_pressed(&"jump"):
			velocity.y = -velocity.y * delta - 100
		else:
			velocity.y = -velocity.y * delta + 100

	# decide if the player is sneaking or not
	if Input.is_action_pressed(&"sneak"):
		Global.player_is_sneaking = true
		speed = BASE_SPEED / 3
	else:
		Global.player_is_sneaking = false
		speed = BASE_SPEED

	# Get the input direction and handle the movement/deceleration
	direction = Input.get_axis(&"move_left", &"move_right")
	if belt_dir: 		# getting moved by belts
		speed = speed / 4 if belt_dir != direction else speed * 1.3
		velocity.x = lerp(0.0, belt_dir, BASE_SPEED / 3)
	if wall_jumping: # walljump sideways speed
		velocity.x += direction * speed / 40
	elif direction: 	# moving on the ground and in the air
		velocity.x = lerp(0.0, direction, speed)
	elif is_on_floor():	# slowing down when not moving on the ground
		velocity.x = move_toward(velocity.x, 0.0, speed / 5)
	else:				# slowing down when not moving in the air
		velocity.x = move_toward(velocity.x, 0.0, speed / 15)
	move_and_slide()


func try_jump() -> void:
	var jump_power: float
	if is_on_wall_only(): # wall jumps
		wall_jumping = true
		jump_power = JUMP_VELOCITY / 1.5
		velocity.x = -get_wall_normal().x * jump_power
	elif jump_charges < 1:
		return
	else: # "double" jumps
		wall_jumping = false
		jump_charges -= 1
		jump_power = JUMP_VELOCITY
	velocity.y = jump_power
	$jump_sound.play_sound()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"click"):
		shoot.emit(get_local_mouse_position())
	if event.is_action_pressed(&"down"): # getting down from a one way platform
		position.y += 1
	if event.is_action_pressed(&"interact"):
		if on_belt_lever:
			switch_lever.emit(lever)

func _process(_delta) -> void:
	if is_on_floor():
		jump_charges = max_jump_charges
		wall_jumping = false
	Global.player_is_on_floor = is_on_floor()
	Global.player_position = position
	Global.player_tile_position = position / Global.tile_size  # position in pixels / tile size

func _on_world_bounce(): # bounce pad bounce power
	velocity.y = JUMP_VELOCITY * 1.5
	jump_charges = max_jump_charges - 1

func _on_death():
	position = start_position

func _on_enemy_detector_body_entered(body: Node2D):
	if body.is_in_group(&"FlyEnemies") and $InvincibilityTime.is_stopped():
		Global.player_health -= 2

func _on_climb_detector_body_entered(_body):
	on_climbable = true
func _on_climb_detector_body_exited(_body):
	on_climbable = false

func _player_on_belt_lever(player_on_lever: bool, body_rid: RID):
	on_belt_lever = player_on_lever
	lever = body_rid

func _on_world_belt_direction(dir: int):
	belt_dir = dir
	prints(get_slide_collision_count(), belt_dir, is_on_floor())
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		print("Collided with: ", collision.get_collider())
