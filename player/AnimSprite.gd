extends AnimatedSprite2D

var base_scale = scale.x

func _ready():
	scale.x = -base_scale # turn player facing right


func _process(_delta):
	if Global.player_is_sneaking: speed_scale = .5
	else: speed_scale = 1
	if $"..".direction:
		play(&"run")
	else:
		stop()

	if not is_zero_approx($"..".velocity.x):  # turn in the walking direction
		if $"..".velocity.x > 0: scale.x = -base_scale
		else: scale.x = base_scale


func _on_player_shoot(mouse_pos): # turn player in the shooting direction
	if mouse_pos.x > 0: scale.x = -base_scale
	else: scale.x = base_scale
