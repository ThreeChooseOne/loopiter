extends Path2D

@export var speed: int = 100
@export var planet_size: Vector2 = Vector2(75.0, 75.0)

# TODO: repeated code, move both copies somewhere else
var planets = [
	preload("res://assets/planets/planet00.png"),
	preload("res://assets/planets/planet01.png"),
	preload("res://assets/planets/planet02.png"),
	preload("res://assets/planets/planet03.png"),
	preload("res://assets/planets/planet04.png"),
	preload("res://assets/planets/planet05.png"),
	preload("res://assets/planets/planet07.png"),
	preload("res://assets/planets/planet08.png"),
	preload("res://assets/planets/planet09.png"),
]

func _process(delta: float) -> void:
	for body in get_children():
		if body is PathFollow2D:
			body.progress += speed * delta

# TODO: Temp, adds random planet
# TODO: repeated code, move both copies somewhere else
func add_random_planet() -> void:
	var follower = PathFollow2D.new()
	var sprite = Sprite2D.new()

	var random_planet_png = planets[randi() % planets.size()]
	sprite.texture = random_planet_png
	var texture_size = sprite.texture.get_size()
	var scale_factor = Vector2(planet_size.x / texture_size.x, planet_size.y / texture_size.y)
	sprite.scale = scale_factor
	follower.add_child(sprite)
	add_child(follower)
