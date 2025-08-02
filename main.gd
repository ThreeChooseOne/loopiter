extends Node2D

var orbits: Array[BaseOrbit] = []
var max_viewport_size: Vector2
const player_scene = preload("res://core/player.tscn")
var player: OrbitingBody

@onready var camera = %PlayerCamera

func _ready() -> void:
	max_viewport_size = get_viewport_rect().size
	$SpaceBackground.size = max_viewport_size
	$JupiterBG_Container.size = max_viewport_size
	
	# Add 21 orbits
	var min_orbit_radius = 200
	var max_orbit_radius = min(max_viewport_size.x, max_viewport_size.y)/2.2
	
	for n in 21:
		# TODO: figure out the radius ranges
		var orbit_radius = min_orbit_radius + (n/21.0)*(max_orbit_radius - min_orbit_radius)
		var center = get_viewport_rect().size/2.0
		var new_orbit = BaseOrbit.new(orbit_radius, center)
		orbits.append(new_orbit)
		add_child(new_orbit)
	
	# Create a moon with collision detection
	var gen_moon = OrbitingBody.new()
	gen_moon.init_random_planet()
	
	# Set up collision layers (optional but recommend)
	gen_moon.set_collision_layer(2) # Moon layer
	gen_moon.set_collision_mask(1) # Can collide with player layer
	
	# Connect to collision signals
	gen_moon.body_collided.connect(_on_moon_collision)
	gen_moon.area_collided.connect(_on_moon_area_collision)
	
	orbits[0].add_child(gen_moon)
	
	# Debug visualization
	orbits[0].visualize_debug(true)
	orbits[10].visualize_debug(true)
	orbits[20].visualize_debug(true)
	
	# Create player
	player = player_scene.instantiate()
	orbits[10].add_child(player)
	
	# Set up player collision if it's also an OrbitingBody
	if player is OrbitingBody:
		player.set_collision_layer(1)  # Player layer
		player.set_collision_mask(2)   # Can collide with moon layer
		player.body_collided.connect(_on_player_collision)

	# Hooks up signal to increment research meter
	$PlayerCamera.enter_key_pressed.connect(gen_moon._on_enter_pressed)

# Collision event handlers
func _on_moon_collision(body):
	print("Moon collided with body: ", body.name)
	
	# Check if it's the player
	if body == player:
		handle_player_moon_collision()
		
func _on_moon_area_collision(area):
	print("Moon collided with area: ", area.name)
	# Handle area-to-area collisions (like moon hitting another moon)

func _on_player_collision(body):
	print("Player collided with: ", body.name)
	
func handle_player_moon_collision():
	print("PLAYER HIT THE MOON!")
	# Add your game logic here:
	# - Reduce player health
	# - Game over
	# - Bounce effect
	# - Screen shake
	# - Sound effect

func _process(delta: float) -> void:
	camera.position = player.position
	var player_angle = player.progress_ratio * TAU
	camera.rotation = player_angle + PI # Add PI to flip camera 180 degrees
