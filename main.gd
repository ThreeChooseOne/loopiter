extends Node2D

@onready var orbit: Path2D = %Orbit

func _ready() -> void:
	# Initialize orbit with a single hardcoded circular body
	var follower = PathFollow2D.new()
	var circle = create_circle_polygon(10)
	follower.loop = true
	follower.add_child(circle)
	orbit.add_body(follower)

# Temp func to create a circle
func create_circle_polygon(radius: float, color: Color = Color.WHITE, num_points: int = 32) -> Polygon2D:
	var polygon = Polygon2D.new()
	var points = PackedVector2Array()
	
	# Points along a cirlce
	for i in num_points:
		var angle = (i * TAU) / num_points 
		var point = Vector2(radius * cos(angle),radius * sin(angle))
		points.append(point)
	
	polygon.polygon = points
	polygon.color = color
	
	return polygon
