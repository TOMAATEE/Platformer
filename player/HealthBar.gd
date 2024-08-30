extends HBoxContainer

signal death

const HEART_FULL = preload("res://assets/hud_heartFull.png")
const HEART_EMPTY = preload("res://assets/hud_heartEmpty.png")
const HEART_HALF = preload("res://assets/hud_heartHalf.png")
var max_health: int
var heart_containers: int
var health: int

func _ready():
	Global.max_hp_change.connect(_on_max_hp_change)
	Global.hp_change.connect(_on_hp_change)
	Global.player_max_health = Global.STARTING_MAX_HEALTH

func update_health(value: int) -> void:
	health = clamp(Global.player_health, 0, max_health)
	for i in heart_containers:
		if not get_child(i) is PopupPanel:
			if value > i * 2 + 1:
				get_child(i).set_texture(HEART_FULL)
			elif value > i * 2:
				get_child(i).set_texture(HEART_HALF)
			else:
				get_child(i).set_texture(HEART_EMPTY)
	if health <= 0:
		death.emit()
		Global.player_health = max_health

func update_max_health(value: int) -> void:
	if Global.player_max_health & 1: # max health can only be even
		Global.player_max_health += 1
		return
	var heart_container_change = value * .5 - heart_containers
	if value * .5 >= heart_containers:	# Health increase
		health += value - max_health
		for i in heart_container_change:
			add_child(TextureRect.new())
	else:								# Health decrease
		if health >= value: health = value
		for i in -int(heart_container_change):
			remove_child(get_child(-1))
	heart_containers = len(get_children())
	max_health = value
	Global.player_health = health

func _on_max_hp_change(value: int) -> void:
	update_max_health(value)
func _on_hp_change(value: int) -> void:
	update_health(value)
