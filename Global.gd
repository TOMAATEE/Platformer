extends Node
signal max_hp_change(emits: int)
signal hp_change(emits: int)

const STARTING_MAX_HEALTH = 20
const TERMINAL_VELOCITY = 700
var tile_size: int
# Get the gravity from the project settings to be synced with everything else
var gravity: int = ProjectSettings.get_setting(&"physics/2d/default_gravity")

var player_max_health: int:
	get:
		return player_max_health
	set(value):
		player_max_health = value
		max_hp_change.emit(player_max_health)
var player_health: int:
	get:
		return player_health
	set(value):
		if value < player_health: # if you take damage, prevent damage for a while
			get_node("/root/main/Player/InvincibilityTime").start()
		player_health = value
		hp_change.emit(player_health)

var player_is_on_floor: bool
var player_position: Vector2i
var player_tile_position: Vector2i
var player_is_sneaking: bool
