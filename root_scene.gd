extends Node2D

func _on_start_screen_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

# TODO: Handle when the game ends, and load the start screen.
