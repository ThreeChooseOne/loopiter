class_name OrbitingBody extends PathFollow2D

# Signals for collision events
signal body_collided(body)
signal area_collided(area)

@export var speed: int = 100
@export var MAX_SPEED: int = 300
@export var MIN_SPEED: int = 50

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
var collision_area: Area2D
var planet_sprite: Sprite2D
var collision_shape: CollisionShape2D

func _init():
	rotates = false
	
func init_random_planet() -> void:
	# Create the collision area first
	collision_area = Area2D.new()
	add_child(collision_area)
	
	# Create sprite as child of collision area
	planet_sprite = Sprite2D.new()
	var random_planet_png = planets[randi() % planets.size()]
	planet_sprite.texture = random_planet_png
	var texture_size = planet_sprite.texture.get_size()
	var scale_factor = Vector2(planet_size.x / texture_size.x, planet_size.y / texture_size.y)
	planet_sprite.scale = scale_factor
	collision_area.add_child(planet_sprite)
	
	# Create collision shape
	collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	# Use the larger dimension for collision status
	var collision_radius = max(planet_size.x, planet_size.y) / 2.0
	circle_shape.radius = collision_radius
	collision_shape.shape = circle_shape
	collision_area.add_child(collision_shape)
	
	# Set up collision detection
	setup_collision_detection()
	
	# Create research progress bar (stays as direct child of PathFollow2D)
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
	
func setup_collision_detection(): 
	if collision_area: 
		# Connect collision signals
		collision_area.body_entered.connect(_on_body_entered)
		collision_area.body_exited.connect(_on_body_exited)
		collision_area.area_entered.connect(_on_area_entered)
		collision_area.area_exited.connect(_on_area_exited)

# Collision event handlers
func _on_body_entered(body):
	print("Planet collision with body: ", body.name)
	body_collided.emit(body)
	
func _on_body_exited(body):
	print("Planet stopped colliding with body: ", body.name)
	
func _on_area_entered(area):
	print("Planet collision with area: ", area.name)
	area_collided.emit(area)
	
	# Check if it's another OrbitingBody
	var other_orbiting_body = area.get_parent()
	if other_orbiting_body is OrbitingBody:
		handle_planet_collision(other_orbiting_body)
		
func _on_area_exited(area):
	print("Planet stopped colliding with area: ", area.name)
	
func handle_planet_collision(other_planet: OrbitingBody):
	print("Two planets collided!")
	# You could add effects here:
	# - Screen shake
	# - Particle effects
	# - Sound effects
	# - Damage/destruction
	# - Bouncing physics
	
func _on_up_pressed():
	speed += 20
	speed = clamp(speed, MIN_SPEED, MAX_SPEED)
	
func _on_down_pressed():
	speed -= 20
	speed = clamp(speed, MIN_SPEED, MAX_SPEED)

func _on_enter_pressed():
	increment_research()

func increment_research():
	research.value = min(research.value + 1, research.max_value)
	print("Progress: ", research.value, "/", research.max_value)

func _process(delta: float) -> void:
	progress += speed * delta
	
# Helper methods for external access
func get_collision_area() -> Area2D:
	return collision_area

func set_collision_layer(layer: int):
	if collision_area:
		collision_area.collision_layer = layer

func set_collision_mask(mask: int):
	if collision_area:
		collision_area.collision_mask = mask
