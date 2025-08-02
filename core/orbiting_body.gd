class_name OrbitingBody extends PathFollow2D

# Signals for collision events
signal body_collided(body)
signal area_collided(area)
signal research_area_entered(body)
signal research_area_exited(body)

@export var speed: int = 100
@export var MAX_SPEED: int = 300
@export var MIN_SPEED: int = 50

@export var planet_size: Vector2 = Vector2(75.0, 75.0)
@export var research_range_multiplier: float = 2.0  # How much bigger research area is


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
var research_area: Area2D
var research_shape: CollisionShape2D

var collision_area: Area2D
var collision_shape: CollisionShape2D

var planet_sprite: Sprite2D


# Research collection system
var research_timer: Timer
var player_in_research_range: bool = false
var current_research_player: OrbitingBody = null
const RESEARCH_INTERVAL: float = 5.0  # 5 seconds per research point

func _init():
	rotates = false
	
func init_random_planet() -> void:
	# Create the main collision area first
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
	
	# Create collision shape for direct collision
	collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	# Use the larger dimension for collision status
	var collision_radius = max(planet_size.x, planet_size.y) / 2.0
	circle_shape.radius = collision_radius
	collision_shape.shape = circle_shape
	collision_area.add_child(collision_shape)
	
	# Create research collection area
	research_area = Area2D.new()
	research_area.name = "ResearchArea"
	add_child(research_area)
	
	# Create research collection shape
	research_shape = CollisionShape2D.new()
	var research_circle = CircleShape2D.new()
	# Needs to be larger than collision radius
	research_circle.radius = collision_radius * research_range_multiplier
	research_shape.shape = research_circle
	research_area.add_child(research_shape)
	
	# Set up collision detection
	setup_collision_detection()
	
	# Set up research timer
	setup_research_system()
	
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
	if research_area:
		# Connect research area signals
		research_area.area_entered.connect(_on_research_area_entered)
		research_area.area_exited.connect(_on_research_area_exited)
		
func setup_research_system():
	# Create timer for research collection
	research_timer = Timer.new()
	research_timer.wait_time = RESEARCH_INTERVAL
	research_timer.timeout.connect(_on_research_timer_timeout)
	add_child(research_timer)

# Direct collision event handlers
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
	
# Research area event handlers
func _on_research_area_entered(area):
	# Check if it's the player's collision area
	var potential_player = area.get_parent()
	if potential_player is OrbitingBody and potential_player.name == "Player":
		print("Player entered research range of moon!")
		current_research_player = potential_player
		player_in_research_range = true
		start_research_collection()
		research_area_entered.emit(potential_player)
	
func _on_research_area_exited(area):
	# Check if it's the player leaving
	var potential_player = area.get_parent()
	if potential_player is OrbitingBody and potential_player.name == "Player":
		print("Player left research range of moon!")
		player_in_research_range = false
		current_research_player = null
		stop_research_collection()
		research_area_exited.emit(potential_player)
		
func start_research_collection():
	if research.value < research.max_value:
		print("Starting research collection timer...")
		research_timer.start()
		
func stop_research_collection():
	print("Stopping research collection timer...")
	research_timer.stop()
	
func _on_research_timer_timeout():
	if player_in_research_range and research.value < research.max_value:
		research.value += 1
		print("Research progress: ", research.value, "/", research.max_value)
		
		# Check if research is complete
		if research.value >= research.max_value:
			print("Research complete for this moon!")
			stop_research_collection()
		else:
			# Continue collecting if player still in range
			research_timer.start()
	
# TODO: Might just remove this? I don't think we need it
func handle_planet_collision(other_planet: OrbitingBody):
	print("Two planets collided!")
	
func _on_up_pressed():
	speed += 20
	speed = clamp(speed, MIN_SPEED, MAX_SPEED)
	
func _on_down_pressed():
	speed -= 20
	speed = clamp(speed, MIN_SPEED, MAX_SPEED)

func _process(delta: float) -> void:
	progress += speed * delta
	
# Helper methods for external access
func get_collision_area() -> Area2D:
	return collision_area

func get_research_area() -> Area2D:
	return research_area

func set_collision_layer(layer: int):
	if collision_area:
		collision_area.collision_layer = layer

func set_collision_mask(mask: int):
	if collision_area:
		collision_area.collision_mask = mask

func set_research_collision_layer(layer: int):
	if research_area:
		research_area.collision_layer = layer

func set_research_collision_mask(mask: int):
	if research_area:
		research_area.collision_mask = mask
