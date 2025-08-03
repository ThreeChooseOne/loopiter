extends Node2D

signal start_button_pressed
signal tutorial_button_pressed

const speed = 0.025

func _ready() -> void:
	%Moon.progress_ratio = randf()

func _on_start_game_pressed() -> void:
	start_button_pressed.emit()

func _on_tutorial_pressed() -> void:
	tutorial_button_pressed.emit()

func _process(delta: float) -> void:
	%Moon.progress_ratio += speed * delta
