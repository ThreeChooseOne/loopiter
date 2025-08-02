extends Node2D

var orbits: Array[BaseOrbit] = []
const player_scene = preload("res://core/player.tscn")
var player: OrbitingBody

# Input signals
signal enter_key_pressed
signal up_key_pressed
signal down_key_pressed

@onready var camera = %PlayerCamera

const num_orbits = 21

func _ready() -> void:
	# Add 5 orbits
	var min_orbit_radius = 500
	var max_orbit_radius = 1000
	
	for n in num_orbits:
		# TODO: figure out the radius ranges
		var center = Vector2.ZERO
		var orbit_radius = min_orbit_radius + (n/float(num_orbits))*(max_orbit_radius - min_orbit_radius)
		var new_orbit = BaseOrbit.new(orbit_radius, center)
		orbits.append(new_orbit)
		add_child(new_orbit)
	
	var gen_moon = OrbitingBody.new()
	gen_moon.init_random_planet()
	orbits[0].add_child(gen_moon)
	
	orbits[0].visualize_debug(true)
	orbits[5].visualize_debug(true)
	orbits[10].visualize_debug(true)
	orbits[15].visualize_debug(true)
	orbits[20].visualize_debug(true)
	
	player = player_scene.instantiate()
	orbits[10].add_child(player)
	up_key_pressed.connect(player._on_up_pressed)
	down_key_pressed.connect(player._on_down_pressed)

	# Hooks up signal to increment research meter
	enter_key_pressed.connect(gen_moon._on_enter_pressed)

func move_player_outer_orbit():
	move_player_orbit(true)

func move_player_inner_orbit():
	move_player_orbit(false)

func move_player_orbit(out: bool):
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
	#if debug_line != null:
		#remove_child(debug_line)
		#debug_line.free()
	#debug_line = Line2D.new()
	#debug_line.add_point(camera.position)
	#debug_line.add_point($Jupiter.position)
	#debug_line.default_color = Color.GREEN
	#debug_line.width = 1
	#add_child(debug_line)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				enter_key_pressed.emit()
			KEY_UP:
				up_key_pressed.emit()
			KEY_DOWN:
				down_key_pressed.emit()
			KEY_I:
				move_player_inner_orbit()
			KEY_O:
				move_player_outer_orbit()
