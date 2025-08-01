extends Path2D

@export var speed: int = 100
var bodies: Array[PathFollow2D] = []

func _process(delta: float) -> void:
	for body in bodies:
		if body and body.get_parent():
			body.progress += speed * delta


func add_body(body: PathFollow2D) -> void:
	add_child(body)
	bodies.append(body)
