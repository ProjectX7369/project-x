extends Node3D

@export var _object_interactive : Node3D
var _object_activate

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		_object_activate = _object_interactive.get_child(2)
		_object_activate.play("move_platform_line_interactive")
