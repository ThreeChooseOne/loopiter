extends Camera2D

signal enter_key_pressed

signal camera_zoom_changed

var max_viewport_size: Vector2

var ZOOM_MAX: Vector2 = 2.0 * Vector2.ONE
var ZOOM_MIN: Vector2 = 1.0 * Vector2.ONE
var ZOOM_SPD: Vector2 = 0.01 * Vector2.ONE

func _ready() -> void:
	max_viewport_size = get_viewport_rect().size
	update_camera_position(Vector2(0,0))

func _input(event: InputEvent):
	if handle_movement_input(event):
		return
	if handle_scroll_input(event):
		camera_zoom_changed.emit(zoom)
		return
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:  # Space key
			enter_key_pressed.emit()
	pass

func handle_movement_input(event: InputEvent) -> bool:
	if event is not InputEventKey:
		return false
	var movement_step: float = 50.0
	
	if event.pressed and event.keycode == KEY_UP:
		update_camera_position(movement_step * Vector2.UP)
		return true
	if event.pressed and event.keycode == KEY_DOWN:
		update_camera_position(movement_step * Vector2.DOWN)
		return true
	if event.pressed and event.keycode == KEY_LEFT:
		update_camera_position(movement_step * Vector2.LEFT)
		return true
	if event.pressed and event.keycode == KEY_RIGHT:
		update_camera_position(movement_step * Vector2.RIGHT)
		return true

	return false

func handle_scroll_input(event: InputEvent):
	if event is not InputEventMouseButton:
		return false
	var emb = event as InputEventMouseButton
	if emb.is_pressed():
		if emb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = ZOOM_MAX.min(zoom + ZOOM_SPD)
		elif emb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = ZOOM_MIN.max(zoom - ZOOM_SPD)
	update_camera_position(Vector2.ZERO)
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
