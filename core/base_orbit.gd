class_name BaseOrbit extends Path2D

# TODO: delete this parent scene? this class should just be a script only now

@export var radius: float = 1.0
@export var center: Vector2 = Vector2(0.0, 0.0)

var speed = 100

var debug_viz: bool = false
var debug_orbit: Line2D = null

func _init(radius: float, center: Vector2) -> void:
	curve = Curve2D.new()
	for n in 100:
		var angle = 2*PI*n/100
		var delta_vec: Vector2 = Vector2.from_angle(angle)
		var new_point: Vector2 = center + radius*delta_vec
		curve.add_point(new_point)
	# close the LOOP???
	curve.add_point(center + radius*Vector2(1,0))
	
func create_debug_viz() -> Line2D:
	var lines = Line2D.new()
	lines.points = curve.get_baked_points()
	lines.width = 1
	lines.default_color = Color.FIREBRICK
	return lines

func visualize_debug(toggle: bool) -> void:
	debug_viz = toggle

func _process(delta: float):
	if debug_viz and debug_orbit == null:
		debug_orbit = create_debug_viz()
		add_child(debug_orbit)
	if not debug_viz and debug_orbit:
		remove_child(debug_orbit)
		debug_orbit.free()
		debug_orbit = null
