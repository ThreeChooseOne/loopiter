extends Control

signal start_button_pressed
signal tutorial_button_pressed

func _ready() -> void:
	$CenterButtons.size = get_viewport_rect().size

func _on_start_game_pressed() -> void:
	start_button_pressed.emit()

func _on_tutorial_pressed() -> void:
	tutorial_button_pressed.emit()
