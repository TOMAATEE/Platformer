extends Area2D

signal hit(body_rid, body)

const SPEED = 400
var direction: Vector2

func _process(delta: float) -> void:
	position += SPEED * direction * delta
	$Sprite2D.modulate[3] -= delta
	if $Sprite2D.modulate[3] <= 0.3:
		queue_free()

func _on_body_shape_entered(body_rid: RID, body: Node2D, _body_shape_index, _local_shape_index):
	hit.emit(body_rid, body)
	queue_free()
