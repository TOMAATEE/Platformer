extends AudioStreamPlayer2D

func play_sound():
	if $"..".is_on_floor(): pitch_scale = 1.0
	else: pitch_scale = 1.5
	play()
