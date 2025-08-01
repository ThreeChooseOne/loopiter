extends Node2D

@onready var orbit: Path2D = %Orbit

func _ready() -> void:
	# Initialize orbit with a random planet
	orbit.add_random_planet()
