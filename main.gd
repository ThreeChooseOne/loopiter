extends Node2D

enum PlayerCollisionState { PLAYER_IN_COLLISION, PLAYER_NOT_IN_COLLISION }
# POWERADE = moving inwards
# GATORADE = moving outwards
enum OrbitChangeDirection { POWERADE, GATORADE }
enum GameResultState { GAME_WON, GAME_OVER }
enum SpeedChangeType { ACCELERATE, DECELERATE }

const SECONDS_PER_MINUTE : = 60

# Orbit System constants
const NUM_TOTAL_ORBITS := 21
const NUM_MOONS_PER_ORBIT := 3
const MIN_ORBIT_RADIUS := 500
const MAX_ORBIT_RADIUS = 1000
const VALID_MOON_ORBIT_INDICES := [0, 5, 10, 15, 20]
const PLAYER_ORBIT_STARTING_IDX := 10
const MIN_ORBIT_SPEED := 60
const MAX_ORBIT_SPEED := 140
const DEFAULT_PLAYER_STARTING_PROGRESS := 0.0

# Moon settings
const TOTAL_MOONS := 15
const MIN_DISTANCE_FROM_PLAYER := 0.25  # Keep moons at least 25% away from player on orbit 10
const MAX_RANDOM_MOON_OFFSET := 0.05	# Moon positions are jittered within this range

# Research settings
const HABITABLE_CHANCE_PER_COMPLETION := 100.0 / TOTAL_MOONS

# Controls settings
const FUEL_COST_SWITCHING_ORBIT := 20
const FUEL_RECOVERY_RATE_PER_SEC := 20
const FUEL_COST_SPEED_CHANGE := 5
const PLAYER_MAX_SPEED: int = 300
const PLAYER_MIN_SPEED: int = 50

const PLAYER_SCENE: PackedScene = preload("res://core/player.tscn")
const MOON_SCENE: PackedScene = preload("res://core/moon.tscn")

var orbits: Array[BaseOrbit] = []
var player: OrbitingBody

# Track all moons for signal management
var all_moons: Array[OrbitingBody] = []

# Store speed for each orbit that has moons
var orbit_speeds: Dictionary = {}

var player_orbit_idx := PLAYER_ORBIT_STARTING_IDX

# Habitable Moon System
var completed_research_count: int = 0
var habitable_moon_found: bool = false
var habitable_moon: OrbitingBody = null

var num_loops_around: int = 0
var last_progress: float = 0.0

# The current state of the player if they are in collision with an object.
# true means the player is currently colliding, false means they are not.
var player_collision_state: PlayerCollisionState = PlayerCollisionState.PLAYER_NOT_IN_COLLISION

signal change_player_speed(accelerate: bool)

signal goto_main_menu
signal retry_pressed
signal habitable_moon_discovered(moon: OrbitingBody)

@onready var camera = %PlayerCamera
@onready var fuel = %PlayerHUD/Fuel
@onready var hud = %PlayerHUD
@onready var speed_bar: TextureProgressBar = %Speed
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var researched_moons: RichTextLabel = %ResearchedMoons

func setup_orbits():
	for n in NUM_TOTAL_ORBITS:
		# TODO: figure out the radius ranges
		const center := Vector2.ZERO
		var orbit_radius = lerp(MIN_ORBIT_RADIUS, MAX_ORBIT_RADIUS, float(n)/NUM_TOTAL_ORBITS)
		var new_orbit = BaseOrbit.new(orbit_radius, center)
		orbits.append(new_orbit)
		add_child(new_orbit)
	# Generate a random speed for each orbit that will have moons
	for orbit_index in VALID_MOON_ORBIT_INDICES:
		var random_speed = randi_range(MIN_ORBIT_SPEED, MAX_ORBIT_SPEED)
		orbit_speeds[orbit_index] = random_speed
		print("Orbit ", orbit_index, " speed: ", random_speed)

func setup_moons(player_progress_ratio: float):
	# Possible positions for the moon can be represented as a float value in [0, 1]
	#
	# In the simplest case, where there is no player:
	#	* Discretize the orbit range into N equally spaced positions
	#	* Adjust all positions equally with some random jitter
	#	* Adjust each position with additional random jitter
	#	* For each moon, take a position at random and assign it to the moon's progress ratio
	#
	# In the case where the player is present, we reserve some part of the interval for the player
	# E.g. [0, 1] -> [0, 0.5], if the player requires [-0.25, 0.25] to be free
	# Then we run the same steps as above, but with a smaller N.
	# Finally, we adjust the moon positions so that the player's interval does not contain a moon.
	for orbit_idx in VALID_MOON_ORBIT_INDICES:
		var initial_offset_in_orbit := randf() * MAX_RANDOM_MOON_OFFSET
		
		var num_possible_moon_positions := 5
		if orbit_idx == PLAYER_ORBIT_STARTING_IDX:
			num_possible_moon_positions = 3
		var possible_moon_positions := range(num_possible_moon_positions)
		possible_moon_positions.shuffle()
		
		for moon_idx in range(NUM_MOONS_PER_ORBIT):
			var seed_moon_pos: float = float(possible_moon_positions[moon_idx])/num_possible_moon_positions
			var moon_starting_pos: float = initial_offset_in_orbit + seed_moon_pos + randf()*MAX_RANDOM_MOON_OFFSET
			if orbit_idx == PLAYER_ORBIT_STARTING_IDX:
				moon_starting_pos *= (1.0 - 2*MIN_DISTANCE_FROM_PLAYER)
				moon_starting_pos += MIN_DISTANCE_FROM_PLAYER
			moon_starting_pos = fmod(moon_starting_pos, 1.0)
			var moon = create_moon(orbit_idx, moon_idx, orbit_speeds[orbit_idx])
			orbits[orbit_idx].add_child(moon)
			all_moons.append(moon)
			moon.progress_ratio = moon_starting_pos
	
func setup_player(player_progress_ratio: float):
	# Create player on orbit 10
	player = PLAYER_SCENE.instantiate()
	player.name = "Player" # Important for collision detection
	orbits[PLAYER_ORBIT_STARTING_IDX].add_child(player)
	player.progress_ratio = DEFAULT_PLAYER_STARTING_PROGRESS
	update_orbit_radar_viz()
	speed_bar.max_value = PLAYER_MAX_SPEED
	speed_bar.min_value = PLAYER_MIN_SPEED


func setup_collision_system():
	player.player_crashed.connect(handle_player_crash.bind(PlayerCollisionState.PLAYER_IN_COLLISION))

	for moon in all_moons:
		# Connect collision signals
		moon.player_crash_mode_reset.connect(handle_player_crash.bind(PlayerCollisionState.PLAYER_NOT_IN_COLLISION))
		moon.research_completed.connect(_on_moon_research_completed)

func _ready() -> void:
	setup_orbits()
	setup_moons(DEFAULT_PLAYER_STARTING_PROGRESS)
	setup_player(DEFAULT_PLAYER_STARTING_PROGRESS)
	setup_collision_system()
	
	# Connect to habitable moon discovery
	habitable_moon_discovered.connect(_on_habitable_moon_discovered)
	print("Habitable Moon System initialized - ", TOTAL_MOONS, " moons, ", "%.1f" % HABITABLE_CHANCE_PER_COMPLETION, "% chance per completion")
	update_research_display()

	
func setup_end_game_view(game_result: GameResultState) -> void:
	if $%Panel.visible:
		# Game is already ended, don't update
		return
	%Panel.visible = true
	match game_result:
		GameResultState.GAME_OVER:
			%GameOverLabel.visible = true
		GameResultState.GAME_WON:
			%WinLabel.visible = true

func create_moon(orbit_index: int, moon_index: int, orbit_speed: int) -> OrbitingBody:
	# Create and configure a single moon
	var moon: MoonBody = MOON_SCENE.instantiate()
	moon.name = "Moon_" + str(orbit_index) + "_" + str(moon_index)
	moon.call_deferred("set_random_sprite")
	
	# Set the moon's speed to match its orbit
	moon.speed = orbit_speed
	return moon

func handle_player_crash(collision_state: PlayerCollisionState):
	if player_collision_state != collision_state:
		if collision_state == PlayerCollisionState.PLAYER_IN_COLLISION:
			# We previously were not colliding, but now we are.
			if num_loops_around == 0:
				setup_end_game_view(GameResultState.GAME_OVER)
			num_loops_around -= 1
		player_collision_state = collision_state

# Habitable Moon System
func _on_moon_research_completed(moon: OrbitingBody):
	completed_research_count += 1
	print("Research completed on ", moon.name, " (", completed_research_count, "/", TOTAL_MOONS, ")")
	
	update_research_display()
	
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
	setup_end_game_view(GameResultState.GAME_WON)

func move_player_orbit(orbit_change_dir: OrbitChangeDirection):
	if fuel.value < FUEL_COST_SWITCHING_ORBIT:
		animation_player.play("blink_red")
		return
	animation_player.stop()
	fuel.value -= FUEL_COST_SWITCHING_ORBIT

	var curr_orbit_idx := player_orbit_idx
	var next_orbit_idx := curr_orbit_idx
	if orbit_change_dir == OrbitChangeDirection.POWERADE:
		next_orbit_idx -= 1
	else:
		next_orbit_idx += 1
	next_orbit_idx = clamp(next_orbit_idx, 0, NUM_TOTAL_ORBITS - 1)
	if next_orbit_idx != curr_orbit_idx:
		var progress_ratio = player.progress_ratio
		orbits[curr_orbit_idx].remove_child(player)
		orbits[next_orbit_idx].add_child(player)
		# Keep player angle the same between orbits
		player.progress_ratio = progress_ratio
		player_orbit_idx = next_orbit_idx
		update_orbit_radar_viz()

func update_hud_timer() -> void:
	var time_left_secs = $GameOverTimer.time_left
	var minutes = int(time_left_secs / SECONDS_PER_MINUTE)
	var seconds: int = time_left_secs - (minutes * SECONDS_PER_MINUTE)
	%Timer.text = "%s:%02d" % [str(minutes), seconds]
	speed_bar.value = player.speed
	
func update_research_display():
	if researched_moons:
		researched_moons.text = "Researched Moons: %d/%d" % [completed_research_count, TOTAL_MOONS]

func update_orbit_radar_viz():
	%OrbitRadarViz.add_orbit_viz(orbits[player_orbit_idx])

func _process(delta: float) -> void:
	camera.position = player.position
	fuel.value = fuel.value + FUEL_RECOVERY_RATE_PER_SEC * delta
	update_hud_timer()
	var curr_progress = player.progress_ratio
	if curr_progress < last_progress:
		num_loops_around += 1
	last_progress = player.progress_ratio
	%Loops.text = "Lives: %d" % num_loops_around

	
func request_player_speed_change(speed_change: SpeedChangeType):
	if fuel.value < FUEL_COST_SPEED_CHANGE:
		return
	fuel.value -= FUEL_COST_SPEED_CHANGE
	if speed_change == SpeedChangeType.ACCELERATE:
		player.speed += 20
	if speed_change == SpeedChangeType.DECELERATE:
		player.speed -= 20
	player.speed = clamp(player.speed, PLAYER_MIN_SPEED, PLAYER_MAX_SPEED)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP, KEY_W:
				request_player_speed_change(SpeedChangeType.ACCELERATE)
			KEY_DOWN, KEY_S:
				request_player_speed_change(SpeedChangeType.DECELERATE)
			KEY_I, KEY_A:
				move_player_orbit(OrbitChangeDirection.POWERADE)
			KEY_O, KEY_D:
				move_player_orbit(OrbitChangeDirection.GATORADE)
			KEY_V:
				$DebugCanvas.toggle_viz()


func _on_game_over_timer_timeout() -> void:
	setup_end_game_view(GameResultState.GAME_OVER)

func _on_main_menu_pressed() -> void:
	goto_main_menu.emit()

func _on_retry_pressed() -> void:
	retry_pressed.emit()
