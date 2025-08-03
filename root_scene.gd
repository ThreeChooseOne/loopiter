extends Node2D

const MAIN_SCENE_PATH: String = "res://main.tscn"
const START_SCENE_PATH: String = "res://start_screen/start_screen.tscn"

var current_scene_handle: Node = null

func _ready() -> void:
	current_scene_handle = $StartScreen

func _on_start_screen_start_button_pressed() -> void:
	goto_game_scene()

func _on_game_over() -> void:
	goto_start_scene()
	
func goto_game_scene() -> void:
	swap_scene_to(MAIN_SCENE_PATH)
	current_scene_handle.connect("game_over_timeout", _on_game_over)

func goto_start_scene() -> void:
	swap_scene_to(START_SCENE_PATH)
	current_scene_handle.connect("start_button_pressed", _on_start_screen_start_button_pressed)
	# TODO: Connect the signal for going to the tutorial

func swap_scene_to(scene_path: String) -> void:
	var scene_packed = load(scene_path)
	if scene_packed:
		remove_child(current_scene_handle)
		current_scene_handle.queue_free()
		var scene_inst = scene_packed.instantiate()
		add_child(scene_inst)
		current_scene_handle = scene_inst
