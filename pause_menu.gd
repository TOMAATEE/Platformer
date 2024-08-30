extends Control

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		pause_switch()

func _on_continue_button_up() -> void:
	pause_switch()

func pause_switch() -> void:
		if get_tree().paused:
			self.visible = false
			get_tree().paused = false
		else:
			self.visible = true
			get_tree().paused = true
