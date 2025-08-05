extends Node2D

var debug_lines: Array[Line2D] = []
var debug_circs: Array[Line2D] = []
var debug_rects: Array[Line2D] = []

func toggle_viz() -> void:
	visible = !visible

func debug_draw_line(to: Vector2, from: Vector2):
	var line = Line2D.new()
	line.add_point(to)
	line.add_point(from)
	debug_lines.append(line)
	queue_redraw()

func debug_draw_circ(center: Vector2, radius: float) -> void:
	var line = Line2D.new()
	line.add_point(center)
	line.add_point(radius * Vector2.ONE)
	debug_circs.append(line)
	queue_redraw()

func debug_draw_rect(p1: Vector2, p2: Vector2):
	var line = Line2D.new()
	var bl = p1.min(p2)
	var tr = p1.max(p2)
	line.add_point(bl)
	line.add_point(Vector2(bl.x, tr.y))
	line.add_point(tr)
	line.add_point(Vector2(tr.x, bl.y))
	line.add_point(bl)
	debug_rects.append(line)
	queue_redraw()

func _draw() -> void:
	for dl in debug_lines:
		draw_line(dl.points[0], dl.points[1], Color.GREEN)
	debug_lines.clear()
	
	for dc in debug_circs:
		draw_circle(dc.points[0], dc.points[1].x, Color.AQUA, false)
	debug_circs.clear()
	
	for dr in debug_rects:
		draw_polyline(dr.points, Color.YELLOW)
	debug_rects.clear()
