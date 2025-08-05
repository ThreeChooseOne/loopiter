class_name OrbitRadarViz extends Node2D

var viz_orbit: BaseOrbit = null

var drawline: Line2D = null

var line_alpha: float = 0 

func _process(delta: float) -> void:
	if viz_orbit == null:
		return
	$InvertMask.scale += 1 * delta * Vector2.ONE
	var mask_alpha = $InvertMask.modulate.a
	mask_alpha -= 0.7 * delta
	if mask_alpha < 0 and $RadarTimer.is_stopped():
		$RadarTimer.start(4.0)
	if mask_alpha < 0.3 and mask_alpha > 0 and line_alpha < 0:
		line_alpha = 0.3
	line_alpha -= 0.2 * delta
	$InvertMask.modulate.a = mask_alpha
	drawline.modulate.a = line_alpha

func _draw() -> void:
	if drawline:
		remove_child(drawline)
		drawline.queue_free()
	if viz_orbit == null:
		return
	var line = Line2D.new()
	line.points = viz_orbit.curve.get_baked_points()
	line.default_color = Color.YELLOW
	line.width = 2
	line.top_level = true
	$InvertMask.add_child(line)
	drawline = line

func add_orbit_viz(orbit: BaseOrbit) -> void:
	viz_orbit = orbit
	if drawline:
		remove_child(drawline)
		drawline.queue_free()
	queue_redraw()

func _on_radar_timer_timeout() -> void:
	$InvertMask.scale = 0.01 * Vector2.ONE
	$InvertMask.modulate.a = 1.0
