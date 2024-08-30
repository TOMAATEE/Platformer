extends CharacterBody2D

@export var movement_speed = 50
@onready var navigation_agent = $NavigationAgent2D
var starting_position: Vector2i

func _ready() -> void:
	starting_position = global_position / 18

func _physics_process(delta: float):
	navigation_agent.target_position = Global.player_position
	if navigation_agent.is_navigation_finished():
		return

	var direction = (navigation_agent.get_next_path_position() - position).normalized()
	if navigation_agent.distance_to_target() < 650:
		navigation_agent.velocity = velocity.lerp(direction * movement_speed, delta)
	else: navigation_agent.velocity = Vector2i(0, 0) # stand still if out of range

	move_and_slide()

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
