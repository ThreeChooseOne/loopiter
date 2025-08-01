class_name OrbitingBody extends Node2D

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

var follower: PathFollow2D
var sprite: Sprite2D

func _init():
	follower = PathFollow2D.new()
	sprite = Sprite2D.new()
	add_random_planet()
	
# TODO: repeated code, move both copies somewhere else
func add_random_planet() -> void:
	var random_planet_png = planets[randi() % planets.size()]
	sprite.texture = random_planet_png
	var texture_size = sprite.texture.get_size()
	var scale_factor = Vector2(planet_size.x / texture_size.x, planet_size.y / texture_size.y)
	sprite.scale = scale_factor
	follower.add_child(sprite)
	
# TODO: unnecessary function?
func get_follower() -> PathFollow2D:
	return follower

# TODO: should this be triggered externally?	
func update(delta: float):
	follower.progress += speed * delta
