extends Node2D

var debug_lines: Array[Line2D] = []

func _init() -> void:
	visible = false

func toggle_viz() -> void:
	visible = !visible

func debug_draw_line(to: Vector2, from: Vector2):
	var line = Line2D.new()
	line.add_point(to)
	line.add_point(from)
	debug_lines.append(line)
	queue_redraw()

func _draw() -> void:
	for dl in debug_lines:
		draw_line(dl.points[0], dl.points[1], Color.GREEN)
	debug_lines.clear()
