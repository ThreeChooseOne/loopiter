class_name OrbitingBody extends PathFollow2D

@export var speed: int = 100

func _init():
	rotates = false

func _process(delta: float) -> void:
	progress += speed * delta
