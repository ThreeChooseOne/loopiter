class_name BaseOrbit extends Path2D

@export var radius: float = 1.0
@export var center: Vector2 = Vector2(0.0, 0.0)

var speed = 100

func _init(radius: float, center: Vector2) -> void:
	center = get_viewport_rect().size/2.0
	curve = Curve2D.new()
	for n in 100:
		var angle = 2*PI*n/100
		var delta_vec: Vector2 = Vector2.from_angle(angle)
		var new_point: Vector2 = center + radius*delta_vec
		curve.add_point(new_point)
	return
