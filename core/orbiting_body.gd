class_name OrbitingBody extends PathFollow2D

# Signals for collision events
signal body_collided(body)
signal area_collided(area)
signal research_area_entered(body)
signal research_area_exited(body)
signal research_completed(moon: OrbitingBody)
signal player_crashed

@export var speed: int = 100
@export var MAX_SPEED: int = 300
@export var MIN_SPEED: int = 50

@export var planet_size: Vector2 = Vector2(75.0, 75.0)
@export var research_range_multiplier: float = 3.0  # How much bigger research area is
var is_research_complete: bool = false
var is_habitable: bool = false

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
var range_texture = preload("res://assets/light5.png")

var research: TextureProgressBar
var research_area: Area2D
var research_shape: CollisionShape2D

var collision_area: Area2D
var collision_shape: CollisionShape2D

var planet_sprite: Sprite2D
var range_idicator: Sprite2D


# Research collection system
var research_timer: Timer
var reset_timer: Timer
var player_in_research_range: bool = false
var current_research_player: OrbitingBody = null
const RESEARCH_INTERVAL: float = 5.0  # 5 seconds per research point
const RESET_INTERVAL: float = 0.1 # 100 ms grace perioud to reenter research zone

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
	
	# Create range indicator sprite
	range_idicator = Sprite2D.new()
	range_idicator.texture = range_texture
	var circle_size = range_idicator.texture.get_size()
	var scale = Vector2(research_circle.radius*2, research_circle.radius*2) / circle_size
	range_idicator.scale = scale
	range_idicator.modulate = Color(0.8, 0.8, 0.8, 0.1)
	range_idicator.z_index = -1
	research_area.add_child(range_idicator)

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
	
	reset_timer = Timer.new()
	reset_timer.wait_time = RESET_INTERVAL
	reset_timer.timeout.connect(_on_reset_timer_timeout)
	add_child(reset_timer)

# Direct collision event handlers
func _on_body_entered(body):
	print("Moon collision with body: ", body.name)
	body_collided.emit(body)
	
func _on_body_exited(body):
	print("Moon stopped colliding with body: ", body.name)
	
func _on_area_entered(area):
	print("Moon collision with area: ", area.name)
	area_collided.emit(area)
	
	# Check if it's another OrbitingBody
	var other_orbiting_body = area.get_parent()
	if other_orbiting_body is OrbitingBody:
		# Check if it's the player crashing into thisi moon
		if other_orbiting_body.name == "Player":
			print("Player crashed into moon!")
			other_orbiting_body.explode()
		else:
			handle_satellite_moon_collision(other_orbiting_body)
		
func _on_area_exited(area):
	print("Planet stopped colliding with area: ", area.name)
	
func explode():
	%PlayerSprite.visible = false
	%Explosion.visible = true
	%Explosion/Timer.start()
	
# Research area event handlers
func _on_research_area_entered(area):
	# Check if it's the player's collision area
	var potential_player = area.get_parent()
	if potential_player is OrbitingBody and potential_player.name == "Player":
		print("Player entered research range of moon!")
		reset_timer.stop()
		if not player_in_research_range:
			current_research_player = potential_player
			player_in_research_range = true
			start_research_collection()
			research_area_entered.emit(potential_player)
			range_idicator.modulate = Color(1, 1, 1, 0.2)
	
func _on_research_area_exited(area):
	# Check if it's the player leaving
	var potential_player = area.get_parent()
	if potential_player is OrbitingBody and potential_player.name == "Player":
		print("Player left research range of moon!")
		reset_timer.start()
		
func start_research_collection():
	if research.value < research.max_value:
		print("Starting research collection timer...")
		research_timer.start()
		
func stop_research_collection():
	print("Stopping research collection timer...")
	research_timer.stop()
	
func _on_reset_timer_timeout():
	reset_timer.stop()
	print("Grace period ended!")
	player_in_research_range = false
	current_research_player = null
	stop_research_collection()
	#research_area_exited.emit(potential_player)
	range_idicator.modulate = Color(0.8, 0.8, 0.8, 0.1)
	
func _on_research_timer_timeout():
	if player_in_research_range and research.value < research.max_value:
		research.value += 1
		print("Research progress: ", research.value, "/", research.max_value)
		
		# Check if research is complete
		if research.value >= research.max_value:
			print("Research complete for this moon!")
			complete_research()
		else:
			# Continue collecting if player still in range
			research_timer.start()

func complete_research():
	if not is_research_complete:
		is_research_complete = true
		stop_research_collection()
		research_completed.emit(self)  # Emit the signal
		print("Moon ", name, " research completed - signal emitted")
		
func make_habitable():
	is_habitable = true
	print("Moon ", name, " is now marked as HABITABLE!")

	if planet_sprite:
		planet_sprite.modulate = Color.GREEN
	
func handle_satellite_moon_collision(other_planet: OrbitingBody):
	print("Collided with moon!")
	
func can_change_speed(accelerate: bool) -> bool:
	if accelerate:
		return speed < MAX_SPEED
	else:
		return speed > MIN_SPEED

func request_speed_change(accelerate: bool) -> void:
	if accelerate:
		speed += 20
		speed = clamp(speed, MIN_SPEED, MAX_SPEED)
	else:
		speed -= 20
		speed = clamp(speed, MIN_SPEED, MAX_SPEED)
	
func _process(delta: float) -> void:
	progress += speed * delta
	
	if research_timer:
		queue_redraw()

func _draw() -> void:
	if research_timer and !research_timer.is_stopped():
		var planet_radius = planet_size.x/2.0
		var research_max_radius = planet_radius * research_range_multiplier
		var ratio = research_timer.time_left / RESEARCH_INTERVAL
		var radius = lerp(planet_radius, research_max_radius, ratio)
		draw_circle(Vector2.ZERO, radius, Color.GHOST_WHITE, false, 1.0)
	
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


func _on_explostion_timer_timeout() -> void:
	%Explosion.visible = false
	%PlayerSprite.visible = true
	player_crashed.emit()
