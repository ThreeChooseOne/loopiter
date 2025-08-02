class_name OrbitingBody extends PathFollow2D

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

var research: TextureProgressBar

func _init():
	rotates = false
	
func init_random_planet() -> void:
	var sprite = Sprite2D.new()
	var random_planet_png = planets[randi() % planets.size()]
	sprite.texture = random_planet_png
	var texture_size = sprite.texture.get_size()
	var scale_factor = Vector2(planet_size.x / texture_size.x, planet_size.y / texture_size.y)
	sprite.scale = scale_factor
	add_child(sprite)
	
	research = TextureProgressBar.new()
	research.texture_under = preload("res://assets/tank.svg")
	research.texture_progress = preload("res://assets/fuel.svg")
	research.set_position(Vector2(-25, -50))
	research.scale = Vector2(.5, .5)
	research.min_value = 0
	research.max_value = 3
	research.step = 1
	research.value = 0
	add_child(research)

func _on_enter_pressed():
	increment_research()

func increment_research():
	research.value = min(research.value + 1, research.max_value)
	print("Progress: ", research.value, "/", research.max_value)

func _process(delta: float) -> void:
	progress += speed * delta
