class_name BaseOrbit extends Path2D

# TODO: delete this parent scene? this class should just be a script only now

@export var radius: float = 1.0
@export var center: Vector2 = Vector2(0.0, 0.0)

var speed = 100

func _init(radius: float, center: Vector2) -> void:
	curve = Curve2D.new()
	for n in 100:
		var angle = 2*PI*n/100
		var delta_vec: Vector2 = Vector2.from_angle(angle)
		var new_point: Vector2 = center + radius*delta_vec
		curve.add_point(new_point)
	# close the LOOP???
	curve.add_point(center + radius*Vector2(1,0))
	return
