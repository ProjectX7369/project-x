extends Area3D

const rotation_speed := 7

func _process(delta: float) -> void:
	rotate_y(deg_to_rad(rotation_speed))


func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		GameManager.add_score()
		Audio.play("res://assets/sounds/coin.ogg")
		queue_free()
