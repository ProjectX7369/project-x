extends CharacterBody3D

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export var tilt_upper_limit := PI / 3.0
@export var tilt_lower_limit := -0.1
@export var zoom_minimum = 8
@export var zoom_maximum = 2

@export_group("Movement")
@export var move_speed := 8.0
@export var acceleration := 20.0
@export var rotation_speed := 12.0
@export var stopping_speed := 1.0
@export var jump_impulse := 12.0

@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera: Camera3D = %Camera3D
@onready var _skin = %character
@onready var _animation_player = %AnimationPlayer
@onready var _spring_arm = $CameraPivot/SpringArm3D
@onready var _wall_detector = %WallDetector

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.BACK
var _gravity := -30.0
var zoom = 6
var _wall_friction := 20
var _wall_force_jump := 20
var jump_single = true
var jump_double = true



func _ready() -> void:
	_animation_player.stop()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion:= (event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED)
	if is_camera_motion:
		_camera_input_direction.x = -event.relative.x * mouse_sensitivity
		_camera_input_direction.y = +event.relative.y * mouse_sensitivity

func _physics_process(delta: float) -> void:
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	_camera_pivot.rotation.y += _camera_input_direction.x * delta
	_camera_input_direction = Vector2.ZERO
	
	if Input.is_action_just_pressed("zoom_in") and zoom >= zoom_maximum: # Acercar 
		zoom -= 1
		_spring_arm.spring_length = zoom
	if Input.is_action_just_pressed("zoom_out") and zoom <= zoom_minimum: # Alejar
		zoom += 1
		_spring_arm.spring_length = zoom
	
	var raw_input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward", 0.4)
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
	
	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	if is_equal_approx(move_direction.length_squared(), 0.0) and velocity.length_squared() < stopping_speed:
		velocity = Vector3.ZERO
	velocity.y = y_velocity + _gravity * delta
	
	# Jumping
	var is_starting_jump := Input.is_action_just_pressed("ui_accept")
	if is_starting_jump:
		if jump_single or jump_double:
			_is_jumping()
	
	
	# Rotation 
	if move_direction.length() > 0.2:
		_last_movement_direction = move_direction
	var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	_skin.global_rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)
	_wall_detector.global_rotation.y = lerp_angle(_wall_detector.rotation.y, target_angle, rotation_speed * delta)
	
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	if is_starting_jump:
		_animation_player.play("jump")
	elif not is_on_floor() and velocity.y < 0:
		_animation_player.play("static")
	elif is_on_floor():
		jump_single = true
		if ground_speed > 0.0 :
			_animation_player.play("walk")
		else:
			_animation_player.play("idle")
	move_and_slide()
	respawn_player()
	is_wall_collider(move_direction, delta)
func respawn_player():
	if position.y < -10:
		self.global_position = GameManager.respawn
func is_wall_collider(dir, delta):
	if _wall_detector.is_colliding():
		velocity.y = -_wall_friction * delta
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = 10 + _wall_force_jump * delta
		move_and_slide()

func _is_jumping():
	Audio.play("res://assets/sounds/jump.ogg")
	velocity.y += jump_impulse
	if jump_single:
		jump_single = false
		jump_double = true
	else:
		jump_double = false
