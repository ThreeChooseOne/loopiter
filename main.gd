extends Node2D

var orbits: Array[BaseOrbit] = []
const player_scene = preload("res://core/player.tscn")
var player: OrbitingBody

# Track all moons for signal management
var all_moons: Array[OrbitingBody] = []

# Store speed for each orbit that has moons
var orbit_speeds: Dictionary = {}

# Habitable Moon System
var completed_research_count: int = 0
var habitable_moon_found: bool = false
var habitable_moon: OrbitingBody = null

signal change_player_speed(accelerate: bool)

signal goto_main_menu
signal retry_pressed
signal habitable_moon_discovered(moon: OrbitingBody)

@onready var camera = %PlayerCamera
@onready var fuel = %PlayerHUD/Fuel
@onready var hud = %PlayerHUD
@onready var speed_bar: TextureProgressBar = %Speed

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
const MIN_DISTANCE_FROM_PLAYER = 0.25  # Keep moons at least 25% away from player on orbit 10

# Habitable Moon settings
const TOTAL_MOONS = 15

const HABITABLE_CHANCE_PER_COMPLETION = 100.0 / TOTAL_MOONS  # 6.67% per completion

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
	#orbits[0].visualize_debug(true)
	#orbits[5].visualize_debug(true)
	#orbits[10].visualize_debug(true)
	#orbits[15].visualize_debug(true)
	#orbits[20].visualize_debug(true)
	
	# Create player on orbit 10
	player = player_scene.instantiate()
	player.name = "Player" # Important for collision detection
	orbits[10].add_child(player)
	
	# Set up player collision if it's also an OrbitingBody
	if player is OrbitingBody:
		player.set_collision_layer(1)  # Player layer
		player.set_collision_mask(2 + 4)   # Can collide with moon layer (2) and research layer (4)
		player.body_collided.connect(_on_player_collision)
	
	change_player_speed.connect(player.request_speed_change)
	
	# Connect to habitable moon discovery
	habitable_moon_discovered.connect(_on_habitable_moon_discovered)
	
	$PlayerCamera/HaloMask.add_orbit_viz(orbits[10])
	
	speed_bar.max_value = player.MAX_SPEED
	speed_bar.min_value = player.MIN_SPEED
	
	print("Habitable Moon System initialized - ", TOTAL_MOONS, " moons, ", "%.1f" % HABITABLE_CHANCE_PER_COMPLETION, "% chance per completion")
	
func setup_end_game_view(win: bool) -> void:
	if $%Panel.visible:
		# Game is already ended, don't update
		return
	%Panel.visible = true
	%GameOverLabel.visible = !win
	%WinLabel.visible = win
	
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
	
		# Generate positions for all moons in this orbit (player-aware for orbit 10)
	var moon_positions = generate_moon_positions_safe(moons_per_orbit, orbit_index)
	
	for moon_index in range(moons_per_orbit):
		var moon = create_moon(orbit_index, moon_index, orbit_speed)
		orbit.add_child(moon)
		all_moons.append(moon)
		
		# Use the calculated position
		var moon_progress = moon_positions[moon_index]
		moon.progress_ratio = moon_progress
		
		print("Created moon ", moon.name, " at progress ", "%.3f" % moon_progress, " with speed ", orbit_speed)
		
		# Extra safety check for player orbit
		if orbit_index == 10:
			var distance_from_player = calculate_circular_distance(moon_progress, 0.0)
			print("  Distance from player: ", "%.3f" % distance_from_player)

func generate_moon_positions_safe(num_moons: int, orbit_index: int) -> Array[float]:
	# Generate well-spaced positions for moons, avoiding player if on same orbit
	var positions: Array[float] = []
	var player_position = 0.0  # Player starts at progress 0
	
	# Start with even spacing
	for i in range(num_moons):
		var base_position = float(i) / float(num_moons)
		positions.append(base_position)
	
	# If this is the player's orbit, adjust base positions to avoid player
	if orbit_index == 10:
		positions = adjust_positions_for_player(positions, player_position)
	
	# Add controlled randomness while maintaining minimum distance
	for i in range(positions.size()):
		var random_offset = randf_range(-POSITION_RANDOMNESS, POSITION_RANDOMNESS)
		var new_position = positions[i] + random_offset
		
		# Wrap around the orbit (0.0 to 1.0)
		new_position = fmod(new_position + 1.0, 1.0)
		
		# Check if this position is valid (far enough from other moons AND player)
		var valid_position = is_position_valid(new_position, positions, i)
		
		# If this is the player's orbit, also check distance from player
		if orbit_index == 10:
			var distance_from_player = calculate_circular_distance(new_position, player_position)
			if distance_from_player < MIN_DISTANCE_FROM_PLAYER:
				valid_position = false
		
		if valid_position:
			positions[i] = new_position
		# If not valid, keep the original safe position
	
	return positions
	
func adjust_positions_for_player(positions: Array[float], player_position: float) -> Array[float]:
	# Adjust base positions to ensure they're far from player
	var safe_positions: Array[float] = []
	
	for i in range(positions.size()):
		var base_pos = positions[i]
		var distance_from_player = calculate_circular_distance(base_pos, player_position)
		
		if distance_from_player < MIN_DISTANCE_FROM_PLAYER:
			# Move this position to a safe location
			var safe_pos = player_position + MIN_DISTANCE_FROM_PLAYER + (i * 0.15)
			safe_pos = fmod(safe_pos, 1.0)  # Wrap around
			safe_positions.append(safe_pos)
			print("  Adjusted moon ", i, " from ", "%.3f" % base_pos, " to ", "%.3f" % safe_pos, " (too close to player)")
		else:
			safe_positions.append(base_pos)
	
	return safe_positions
	
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
	moon.player_crashed.connect(setup_end_game_view.bind(false))
	
	moon.research_area_entered.connect(_on_moon_research_entered)
	moon.research_area_exited.connect(_on_moon_research_exited)
	moon.research_completed.connect(_on_moon_research_completed)
	
	return moon


# Habitable Moon System
func _on_moon_research_completed(moon: OrbitingBody):
	completed_research_count += 1
	print("Research completed on ", moon.name, " (", completed_research_count, "/", TOTAL_MOONS, ")")
	
	# Don't check for habitability if we already found one
	if habitable_moon_found:
		return
	
	# Calculate current probability
	var current_probability = completed_research_count * HABITABLE_CHANCE_PER_COMPLETION
	current_probability = min(current_probability, 100.0)  # Cap at 100%
	
	print("Checking habitability - ", "%.1f" % current_probability, "% chance")
	
	# Roll for habitability
	var roll = randf() * 100.0
	if roll <= current_probability:
		# This moon is habitable!
		moon.make_habitable()
		habitable_moon_found = true
		habitable_moon = moon
		habitable_moon_discovered.emit(moon)
		print("🎉 HABITABLE MOON DISCOVERED! ", moon.name, " is habitable!")
	else:
		print("Moon ", moon.name, " is not habitable (rolled ", "%.1f" % roll, ")")

func _on_habitable_moon_discovered(moon: OrbitingBody):
	print("GAME WON! Player discovered habitable moon: ", moon.name)
	setup_end_game_view(true)

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
		$PlayerCamera/HaloMask.add_orbit_viz(orbits[new])

func current_player_orbit() -> int:
	for i in len(orbits):
		if orbits[i].get_children().has(player):
			return i
	return -1

func update_hud_timer() -> void:
	var time_left_secs = $GameOverTimer.time_left
	var minutes = int(time_left_secs / 60)
	var seconds: int = time_left_secs - (minutes*60)
	%Timer.text = "%s:%02d" % [str(minutes), seconds]
	speed_bar.value = player.speed

func _process(delta: float) -> void:
	camera.position = player.position
	fuel.value = fuel.value + 20 * delta
	update_hud_timer()

	# Example Code:
	#
	# $DebugCanvas.debug_draw_line(player.position, $JupiterBackground.position)
	# $DebugCanvas.debug_draw_circ(player.position, 150)
	# var f = 50*Vector2.ONE
	# $DebugCanvas.debug_draw_rect(player.position-f, player.position+f)
	
func request_player_speed_change(accelerate: bool):
	if fuel.value < 5:
		return
	if player.can_change_speed(accelerate):
		fuel.value -= 5
		change_player_speed.emit(accelerate)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP, KEY_W:
				request_player_speed_change(true)
			KEY_DOWN, KEY_S:
				request_player_speed_change(false)
			KEY_I, KEY_A:
				move_player_inner_orbit()
			KEY_O, KEY_D:
				move_player_outer_orbit()
			KEY_V:
				$DebugCanvas.toggle_viz()


func _on_game_over_timer_timeout() -> void:
	setup_end_game_view(false)

func _on_main_menu_pressed() -> void:
	goto_main_menu.emit()

func _on_retry_pressed() -> void:
	retry_pressed.emit()
