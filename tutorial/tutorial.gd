extends Node2D

signal tutorial_closed

func _on_close_button_pressed() -> void:
	tutorial_closed.emit()
