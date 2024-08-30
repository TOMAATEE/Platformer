extends Node2D
signal coin_collected(amount: int)
signal bounce
signal on_belt_lever(player_on_lever: bool, body_rid: RID)
signal belt_direction(dir: int)

@onready var interact: TileMapLayer = $Interact
@onready var foreground: TileMapLayer = $Foreground
@onready var background: TileMapLayer = $Background
@onready var decoration: TileMapLayer = $Decoration
@onready var secret: TileMapLayer = $Secret
@onready var player = $"../Player"

@export var beltlever_beltleftside: Dictionary
@export var levers := {Vector2i(11, 9): &"off"}
@export var lock_key := {Vector2i(39, 9): Vector2i(21, 2)}
@export var button_lock := {Vector2i(33, 9): Vector2i(39, 8)}

var player_in_secret: bool
var to_reset: Array
var snowmen: Array
var discarded: Array
var beltstanding: Array
var secret_coords: Array

const COIN_SOUND = preload("res://player/coin_pickup.wav")
const CURRENT_TO_NEW_BELT_LEVER_STATE = {&"L": &"N", &"N": &"R", &"R": &"L"}
const BELTS = { &"air": {   # tileset: 0 = Neutral, 1-2 = Left, 3-4 = Right
				&"NL": Vector2i(0, 0), &"NM": Vector2i(1, 0), &"NR": Vector2i(2, 0),
				&"LL": Vector2i(0, 2), &"LM": Vector2i(3, 2), &"LR": Vector2i(6, 2),
				&"RL": Vector2i(0, 4), &"RM": Vector2i(3, 4), &"RR": Vector2i(6, 4)},
				&"stand": {
				&"NL": Vector2i(3, 0), &"NM": Vector2i(4, 0), &"NR": Vector2i(5, 0),
				&"LL": Vector2i(0, 1), &"LM": Vector2i(3, 1), &"LR": Vector2i(6, 1),
				&"RL": Vector2i(0, 3), &"RM": Vector2i(3, 3), &"RR": Vector2i(6, 3)}}
const ITEMS = {
	&"diamond": Vector2i(7, 0),
	&"!active": Vector2i(10, 0),
	&"!inactive": Vector2i(10, 1),
	&"target_active": Vector2i(11, 0),
	&"target_inactive": Vector2i(11, 1),
	&"box": Vector2i(6, 1),
	&"key": Vector2i(7, 1),
	&"lock": Vector2i(7, 3),
	&"heart": Vector2i(4, 2),
	&"lever_off": Vector2i(4, 3),
	&"lever_on": Vector2i(6, 3),
	&"spikes": Vector2i(8, 3),
	&"bounce_primed": Vector2i(7, 5),
	&"bounce_sprung": Vector2i(8, 5),
	&"snowmanR": Vector2i(4, 7),
	&"snowmanL": Vector2i(5, 7),
	&"button_off": Vector2i(8, 7),
	&"button_pressed": Vector2i(9, 7),
	&"coin": Vector2i(11, 7),
	&"air": Vector2i(17, 7),
	&"BeltLever": { &"L": Vector2i(6, 0),
					&"N": Vector2i(7, 0),
					&"R": Vector2i(8, 0)}
	}

func _ready() -> void:
	Global.tile_size = foreground.tile_set.tile_size.x
	secret_coords = secret.get_used_cells()

	snowmen = foreground.get_used_cells_by_id(1, ITEMS.snowmanL)
	snowmen.append_array(foreground.get_used_cells_by_id(1, ITEMS.snowmanR))

	for i in BELTS[&"stand"]:
		beltstanding.append(BELTS[&"stand"][i])

	var map_left = min(foreground.get_used_rect().position.x, interact.get_used_rect().position.x, background.get_used_rect().position.x)
	var map_right = max(foreground.get_used_rect().end.x, interact.get_used_rect().end.x, background.get_used_rect().end.x)
	var map_top = min(foreground.get_used_rect().position.y, interact.get_used_rect().position.y, background.get_used_rect().position.y)
	var map_bottom = max(foreground.get_used_rect().end.y, interact.get_used_rect().end.y, background.get_used_rect().end.y)
	var used: Array
	for layer in [interact, foreground, background]:
		used.append_array(layer.get_used_cells())
	for x in range(map_left, map_right):
		for y in range(map_top, map_bottom):
			if Vector2i(x, y) not in used:
				interact.set_cell(Vector2i(x, y), 1, ITEMS.air)


func _on_interact_detector_body_shape_entered(body_rid: RID, _body, _body_shape_index, _local_shape_index) -> void:
	var tile_pos = interact.get_coords_for_body_rid(body_rid)
	var source_id = interact.get_cell_source_id(tile_pos)
	var tiledata = interact.get_cell_tile_data(tile_pos)
	var item = interact.get_cell_atlas_coords(tile_pos)

	match item:
		ITEMS.coin, ITEMS.diamond, ITEMS.key when tiledata.get_custom_data(&"collectible"):
			collect(tile_pos, source_id, tiledata)
			money(tiledata)
			discarded.append(body_rid.get_id())
		ITEMS.heart:
			if Global.player_health != Global.player_max_health:
				collect(tile_pos, source_id, tiledata)
				damage(tiledata)
				discarded.append(body_rid.get_id())
		ITEMS.box when source_id == 1:
			var left_clear: Array
			var right_clear: Array
			for layer in [interact, foreground]:
				var left_tile = layer.get_cell_atlas_coords(tile_pos - Vector2i(1, 0))
				var right_tile = layer.get_cell_atlas_coords(tile_pos + Vector2i(1, 0))
				left_clear.append(true if left_tile == ITEMS.air else false)
				right_clear.append(true if right_tile == ITEMS.air else false)
			if right_clear[0] and right_clear[1] and tile_pos.x > Global.player_tile_position.x:
				interact.set_cell(tile_pos, source_id, ITEMS.air)
				interact.set_cell(tile_pos + Vector2i(1, 0), source_id, ITEMS.box)
			elif left_clear[0] and left_clear[1] and tile_pos.x < Global.player_tile_position.x:
				interact.set_cell(tile_pos, source_id, ITEMS.air)
				interact.set_cell(tile_pos - Vector2i(1, 0), source_id, ITEMS.box)
			discarded.append(body_rid.get_id())
		ITEMS.spikes:
			if not Global.player_is_on_floor:
				damage(tiledata)
		ITEMS.bounce_primed:
			if not Global.player_is_sneaking:
				bounce.emit()
				$BounceTimer.start()
				interact.set_cell(tile_pos, source_id, ITEMS.bounce_sprung)
				to_reset.append([tile_pos, source_id])
				discarded.append(body_rid.get_id())
		ITEMS.lever_on when source_id == 1:
			interact.set_cell(tile_pos, source_id, ITEMS.lever_off)
			levers[tile_pos] = &"off"
			secret.collision_enabled = true
		ITEMS.lever_off when source_id == 1:
			interact.set_cell(tile_pos, source_id, ITEMS.lever_on)
			levers[tile_pos] = &"on"
			secret.collision_enabled = false
		ITEMS[&"!active"]:
			interact.set_cell(tile_pos, source_id, ITEMS[&"!inactive"])
			money(tiledata)
			$coin_sound.play()
			discarded.append(body_rid.get_id())
		ITEMS.button_off:
			interact.set_cell(tile_pos, source_id, ITEMS.button_pressed)
			interact.set_cell(button_lock[tile_pos], source_id, ITEMS.air)
		ITEMS.lock:
			if tile_pos in lock_key: # crash prevention for locks without (defined) keys
				if interact.get_cell_atlas_coords(lock_key[tile_pos]) != ITEMS[&"key"]:
					interact.set_cell(tile_pos, source_id, ITEMS.air)
					discarded.append(body_rid.get_id())
		ITEMS.BeltLever.L, ITEMS.BeltLever.N, ITEMS.BeltLever.R:
			on_belt_lever.emit(true, body_rid)
		_ when tiledata.get_custom_data(&"direction"):
			belt_direction.emit(tiledata.get_custom_data(&"direction"))


func _on_interact_detector_body_shape_exited(body_rid: RID, _body, _body_shape_index, _local_shape_index) -> void:
	if body_rid.get_id() in discarded:
		return
	var tile_pos = interact.get_coords_for_body_rid(body_rid)
	var item = interact.get_cell_atlas_coords(tile_pos)

	match item:
		ITEMS.BeltLever.L, ITEMS.BeltLever.N, ITEMS.BeltLever.R:
			on_belt_lever.emit(false, body_rid)


func damage(tiledata: TileData) -> void:
	if tiledata.get_custom_data(&"damage"):
		Global.player_health -= tiledata.get_custom_data(&"damage")

func collect(tile_player_pos: Vector2i, source_id: int, tiledata: TileData) -> void:
	if tiledata.get_custom_data(&"collectible"):
		interact.set_cell(tile_player_pos, source_id, ITEMS.air)

func money(tiledata: TileData) -> void:
	if tiledata.get_custom_data(&"CoinValue"):
		coin_collected.emit(tiledata.get_custom_data(&"CoinValue"))
		$coin_sound.play()

func _process(delta: float) -> void:
	var secret_layer_alpha = secret.modulate[3]
	if player_in_secret and levers[Vector2i(11, 9)] == &"on": # Animate the layer transparency.
		if secret_layer_alpha > 0.3:
			secret_layer_alpha = move_toward(secret_layer_alpha, 0.3, delta)
			secret.modulate = Color(1, 1, 1, secret_layer_alpha)
	else:
		if secret_layer_alpha < 1.0:
			secret_layer_alpha = move_toward(secret_layer_alpha, 1.0, delta)
			secret.modulate = Color(1, 1, 1, secret_layer_alpha)

	for i in len(snowmen):
		if snowmen[i][0] < Global.player_tile_position[0]:
			foreground.set_cell(snowmen[i], 1, ITEMS.snowmanR)
		elif snowmen[i][0] > Global.player_tile_position[0]:
			foreground.set_cell(snowmen[i], 1, ITEMS.snowmanL)


func _on_secret_detector_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D: # Detect player only
		player_in_secret = true

func _on_secret_detector_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_secret = false


func _on_bounce_timer_timeout() -> void:
	for i in range(len(to_reset)):
		interact.set_cell(to_reset[i][0], to_reset[i][1], ITEMS.bounce_primed)
	to_reset.clear()


func _on_bullet_body_shape_entered(body_rid: RID, body: Node2D) -> void:
	if body.is_in_group(&"FlyEnemies"):
		interact.set_cell(body.starting_position, 1, ITEMS.air)
		body.queue_free()
		coin_collected.emit(1)
		return
	if body.name != &"Interact":
		return

	var tile_pos = interact.get_coords_for_body_rid(body_rid)
	var source_id = interact.get_cell_source_id(tile_pos)
	var item = interact.get_cell_atlas_coords(tile_pos)
	match item:
		ITEMS.target_active:
			interact.set_cell(tile_pos, source_id, ITEMS.target_inactive)
			discarded.append(body_rid.get_id())

func _on_gun_shot(bullet: Node2D) -> void:
	bullet.hit.connect(_on_bullet_body_shape_entered)

func _on_player_switch_lever(body_rid: RID) -> void:
	var tile_pos = interact.get_coords_for_body_rid(body_rid)
	var item = interact.get_cell_atlas_coords(tile_pos)

	match item:
		ITEMS.BeltLever.L: # left to neutral
			update_belt(tile_pos, &"L")
		ITEMS.BeltLever.N: # neutral to right
			update_belt(tile_pos, &"N")
		ITEMS.BeltLever.R: # right to left
			update_belt(tile_pos, &"R")

func update_belt(tile_pos: Vector2i, current_lever_state: String) -> void:
	var source_id = interact.get_cell_source_id(tile_pos)
	var new_lever_state = CURRENT_TO_NEW_BELT_LEVER_STATE[current_lever_state]
	var belt: Array

	if tile_pos not in beltlever_beltleftside:
		var options: Array
		for type in [&"air", &"stand"]:
			options.append_array(interact.get_used_cells_by_id(2, BELTS[type]["%sL" % current_lever_state]))
		belt = get_belt_coords(find_closest_node_to_point(options, tile_pos))
		beltlever_beltleftside[tile_pos] = find_closest_node_to_point(options, tile_pos)
	else: belt = get_belt_coords(beltlever_beltleftside[tile_pos])

	interact.set_cell(tile_pos, source_id, ITEMS.BeltLever[new_lever_state]) # change lever
	for coords in belt:
		var type = &"stand" if interact.get_cell_atlas_coords(coords) in beltstanding else &"air"
		var belt_key: String

		if coords == belt[0]:
			belt_key = &"L"  # Left side of the belt
		elif coords == belt[-1]:
			belt_key = &"R"  # Right side of the belt
		else:
			belt_key = &"M"  # Middle part of the belt

		interact.set_cell(coords, source_id, BELTS[type]["%s%s" % [new_lever_state, belt_key]])

func get_belt_coords(start: Vector2i) -> Array:
	var belt_coords: Array
	while interact.get_cell_atlas_coords(start) != ITEMS.air:
		belt_coords.append(start)
		start.x += 1
	return belt_coords

func find_closest_node_to_point(array: Array, point: Vector2i):
	if array.is_empty(): # Handle empty array case
		return null

	var closest_node = array[0]
	var closest_node_distance = point.distance_squared_to(closest_node)

	for i in range(1, array.size()):
		var current_node_distance = point.distance_squared_to(array[i])
		if current_node_distance < closest_node_distance:
			closest_node = array[i]
			closest_node_distance = current_node_distance

	return closest_node
