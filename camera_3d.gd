extends Camera3D

@export var move_speed := 7.0
@export var zoom_speed := 1.5

var adjusted_speed = clamp(move_speed * log(size), 2, 100)

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if not (Input.is_anything_pressed()): return
	if (get_viewport().gui_get_focus_owner()): return
	var direction := Vector3.ZERO

	if Input.is_action_pressed("move_up"):
		direction.z -= 1
	if Input.is_action_pressed("move_down"):
		direction.z += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1

	if direction != Vector3.ZERO:
		position += direction.normalized() * adjusted_speed * delta
		
func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		size = clamp(size - zoom_speed, 1.0, 100.0)
		adjusted_speed = clamp(move_speed * log(size), 2, 100)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		size = clamp(size + zoom_speed, 1.0, 100.0)
		adjusted_speed = clamp(move_speed * log(size), 2, 100)
