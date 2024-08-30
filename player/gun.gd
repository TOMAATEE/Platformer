extends Marker2D
signal shot(bullet)
const BULLET_SCENE = preload("res://player/bullet.tscn")


func _on_player_shoot(dir: Vector2) -> void:
	if not $Cooldown.is_stopped():
		return
	var bullet := BULLET_SCENE.instantiate()
	bullet.position = global_position
	bullet.direction = dir.normalized()
	bullet.add_to_group(&"bullets")
	bullet.set_as_top_level(true)
	add_child(bullet)
	shot.emit(bullet)
	$Shoot.play()
	$Cooldown.start()
