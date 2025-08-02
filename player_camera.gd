extends Camera2D

signal enter_key_pressed

var max_viewport_size: Vector2

func _ready() -> void:
	max_viewport_size = get_viewport_rect().size
	update_camera_position(Vector2(0,0))

func _input(event: InputEvent):
	handle_movement_input(event)
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:  # Space key
			enter_key_pressed.emit()
	pass

func handle_movement_input(event: InputEvent) -> bool:
	if event is not InputEventKey:
		return false
	var movement_step: float = 50.0
	
	if event.pressed and event.keycode == KEY_UP:
		update_camera_position(movement_step * Vector2(0, -1))
		return true
	if event.pressed and event.keycode == KEY_DOWN:
		update_camera_position(movement_step * Vector2(0, 1))
		return true
	if event.pressed and event.keycode == KEY_LEFT:
		update_camera_position(movement_step * Vector2(-1, 0))
		return true
	if event.pressed and event.keycode == KEY_RIGHT:
		update_camera_position(movement_step * Vector2(1, 0))
		return true

	return false
	
func update_camera_position(delta: Vector2):
	var new_pos = position + delta
	new_pos = new_pos.max(get_camera_lower_limit())
	new_pos = new_pos.min(get_camera_upper_limit())
	position = new_pos
	
func get_main_viewport_size() -> Vector2:
	return get_parent().max_viewport_size
	
func get_camera_upper_limit() -> Vector2:
	return get_main_viewport_size() - get_camera_size()/2

func get_camera_lower_limit() -> Vector2:
	return get_camera_size()/2

func get_camera_size() -> Vector2:
	return get_main_viewport_size()/zoom
