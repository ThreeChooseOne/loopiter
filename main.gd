extends Node2D

var orbits: Array[BaseOrbit] = []
const player_scene = preload("res://core/player.tscn")
var player: OrbitingBody

# Track all moons for signal management
var all_moons: Array[OrbitingBody] = []

# Store speed for each orbit that has moons
var orbit_speeds: Dictionary = {}

# Input signals
signal up_key_pressed
signal down_key_pressed

@onready var camera = %PlayerCamera
@onready var fuel = %Fuel

const fuel_cost = 20

const num_orbits = 21
const moons_per_orbit = 3

# Define which orbits should have moons (same as debug visualization)
const moon_orbit_indices = [0, 5, 10, 15, 20]

# Speed range for orbits with moons
const MIN_ORBIT_SPEED = 60
const MAX_ORBIT_SPEED = 140

# Moon positioning settings
const MIN_MOON_DISTANCE = 0.15 # Minimum distance between moons (as fraction of orbit)
const POSITION_RANDOMNESS = 0.08  # How much to randomly offset from even spacing

func _ready() -> void:
	# Add 21 orbits
	var min_orbit_radius = 500
	var max_orbit_radius = 1000
	
	for n in num_orbits:
		# TODO: figure out the radius ranges
		var center = Vector2.ZERO
		var orbit_radius = min_orbit_radius + (n/float(num_orbits))*(max_orbit_radius - min_orbit_radius)
		var new_orbit = BaseOrbit.new(orbit_radius, center)
		orbits.append(new_orbit)
		add_child(new_orbit)
		
	
	# Generate random speeds for moon orbits
	generate_orbit_speeds()
	
	# Add moons only to specific orbits
	populate_selected_orbits_with_moons()
	
	# Debug visualization
	orbits[0].visualize_debug(true)
	orbits[5].visualize_debug(true)
	orbits[10].visualize_debug(true)
	orbits[15].visualize_debug(true)
	orbits[20].visualize_debug(true)
	
	# Create player
	player = player_scene.instantiate()
	player.name = "Player" # Important for collision detection
	orbits[10].add_child(player)
	
	# Set up player collision if it's also an OrbitingBody
	if player is OrbitingBody:
		player.set_collision_layer(1)  # Player layer
		player.set_collision_mask(2 + 4)   # Can collide with moon layer (2) and research layer (4)
		player.body_collided.connect(_on_player_collision)
	
	up_key_pressed.connect(player._on_up_pressed)
	down_key_pressed.connect(player._on_down_pressed)
	
func generate_orbit_speeds():
	# Generate a random speed for each orbit that will have moons
	for orbit_index in moon_orbit_indices:
		var random_speed = randi_range(MIN_ORBIT_SPEED, MAX_ORBIT_SPEED)
		orbit_speeds[orbit_index] = random_speed
		print("Orbit ", orbit_index, " speed: ", random_speed)

func populate_selected_orbits_with_moons():
	# Add moons only to the orbits with debug visualization
	for orbit_index in moon_orbit_indices:
		add_moons_to_orbit(orbit_index)
	print("Created ", all_moons.size(), " moons across ", moon_orbit_indices.size(), " orbits")

func add_moons_to_orbit(orbit_index: int):
	# Add multiple moons to a specific orbit with proper spacing
	var orbit = orbits[orbit_index]
	var orbit_speed = orbit_speeds[orbit_index]
	
	# Generate positions for all moons in this orbit
	var moon_positions = generate_moon_positions(moons_per_orbit)
	
	for moon_index in range(moons_per_orbit):
		var moon = create_moon(orbit_index, moon_index, orbit_speed)
		orbit.add_child(moon)
		all_moons.append(moon)
		
		# Use the calculated position
		var moon_progress = moon_positions[moon_index]
		moon.progress_ratio = moon_progress
		
		print("Created moon ", moon.name, " at progress ", "%.3f" % moon_progress, " with speed ", orbit_speed)

func generate_moon_positions(num_moons: int) -> Array[float]:
	# Generate well-spaced positions for moons on an orbit
	var positions: Array[float] = []
	
	# Start with even spacing
	for i in range(num_moons):
		var base_position = float(i) / float(num_moons)
		positions.append(base_position)
	
	# Add controlled randomness while maintaining minimum distance
	for i in range(positions.size()):
		var random_offset = randf_range(-POSITION_RANDOMNESS, POSITION_RANDOMNESS)
		var new_position = positions[i] + random_offset
		
		# Wrap around the orbit (0.0 to 1.0)
		new_position = fmod(new_position + 1.0, 1.0)
		
		# Check if this position is valid (far enough from other moons)
		if is_position_valid(new_position, positions, i):
			positions[i] = new_position
		# If not valid, keep the original even spacing position
	
	return positions
	
func is_position_valid(test_position: float, existing_positions: Array[float], skip_index: int) -> bool:
	# Check if a position is far enough from all other moons
	for i in range(existing_positions.size()):
		if i == skip_index:
			continue  # Don't compare with self
		
		var distance = calculate_circular_distance(test_position, existing_positions[i])
		if distance < MIN_MOON_DISTANCE:
			return false
	
	return true
	
func calculate_circular_distance(pos1: float, pos2: float) -> float:
	# Calculate the shortest distance between two positions on a circle
	var direct_distance = abs(pos1 - pos2)
	var wrap_distance = 1.0 - direct_distance
	return min(direct_distance, wrap_distance)

func create_moon(orbit_index: int, moon_index: int, orbit_speed: int) -> OrbitingBody:
	# Create and configure a single moon
	var moon = OrbitingBody.new()
	moon.name = "Moon_" + str(orbit_index) + "_" + str(moon_index)
	moon.init_random_planet()
	
	# Set the moon's speed to match its orbit
	moon.speed = orbit_speed
	
	# Set up collision layers
	moon.set_collision_layer(2) # Moon layer
	moon.set_collision_mask(1) # Can collide with player layer
	
	# Set up research area layers
	moon.set_research_collision_layer(4) # Research area layer
	moon.set_research_collision_mask(1) # Can detect player layer
	
	# Connect collision signals
	moon.body_collided.connect(_on_moon_collision)
	moon.research_area_entered.connect(_on_moon_research_entered)
	moon.research_area_exited.connect(_on_moon_research_exited)
	
	return moon


# Collision event handlers
func _on_moon_collision(body):
	print("Moon collided with body: ", body.name)
	
	# Check if it's the player
	if body == player:
		handle_player_moon_collision()

func _on_player_collision(body):
	print("Player collided with: ", body.name)
	
# Research event handlers
func _on_moon_research_entered(player_body):
	print("MAIN: Player entered moon research range!")

func _on_moon_research_exited(player_body):
	print("MAIN: Player left moon research range!")

func handle_player_moon_collision():
	print("PLAYER HIT THE MOON!")

func move_player_outer_orbit():
	move_player_orbit(true)

func move_player_inner_orbit():
	move_player_orbit(false)

func move_player_orbit(out: bool):
	if fuel.value < fuel_cost:
		return
	fuel.value -= fuel_cost

	var curr = current_player_orbit()
	var new = curr + (1 if out else -1)
	new = clamp(new, 0, num_orbits - 1)
	if new != curr:
		var progress_ratio = player.progress_ratio
		orbits[curr].remove_child(player)
		orbits[new].add_child(player)
		# Keep player angle the same between orbits
		player.progress_ratio = progress_ratio

func current_player_orbit() -> int:
	for i in len(orbits):
		if orbits[i].get_children().has(player):
			return i
	return -1

func _process(delta: float) -> void:
	camera.position = player.position
	fuel.value = fuel.value + 20 * delta

	# Example Code:
	#
	# $DebugCanvas.debug_draw_line(player.position, $JupiterBackground.position)
	# $DebugCanvas.debug_draw_circ(player.position, 150)
	# var f = 50*Vector2.ONE
	# $DebugCanvas.debug_draw_rect(player.position-f, player.position+f)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				up_key_pressed.emit()
			KEY_DOWN:
				down_key_pressed.emit()
			KEY_I:
				move_player_inner_orbit()
			KEY_O:
				move_player_outer_orbit()
			KEY_V:
				$DebugCanvas.toggle_viz()


# Helper functions for debugging/management
func get_moons_in_orbit(orbit_index: int) -> Array[OrbitingBody]:
	# Get all moons in a specific orbit
	var moons_in_orbit: Array[OrbitingBody] = []
	if orbit_index < orbits.size():
		for child in orbits[orbit_index].get_children():
			if child is OrbitingBody and child != player:
				moons_in_orbit.append(child)
	return moons_in_orbit

func get_total_moon_count() -> int:
	# Get total number of moons in the game
	return all_moons.size()

func get_completed_research_count() -> int:
	# Get number of moons with completed research
	var completed = 0
	for moon in all_moons:
		if moon.research.value >= moon.research.max_value:
			completed += 1
	return completed

func is_orbit_with_moons(orbit_index: int) -> bool:
	# Check if an orbit has moons
	return orbit_index in moon_orbit_indices

func get_orbit_speed(orbit_index: int) -> int:
	# Get the speed for a specific orbit
	return orbit_speeds.get(orbit_index, 0)  # Default to 0 if not found
