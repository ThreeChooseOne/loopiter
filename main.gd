extends Node2D

var orbits: Array[BaseOrbit] = []
var max_viewport_size: Vector2
const player_scene = preload("res://core/player.tscn")
var player: OrbitingBody

signal enter_key_pressed

@onready var camera = %PlayerCamera

func _ready() -> void:
	max_viewport_size = get_viewport_rect().size
	
	$SpaceBackground.size = max_viewport_size
	$JupiterBG_Container.size = max_viewport_size
	
	# Add 5 orbits
	var min_orbit_radius = 500
	var max_orbit_radius = 1000
	
	for n in 21:
		# TODO: figure out the radius ranges
		var orbit_radius = min_orbit_radius + (n/21.0)*(max_orbit_radius - min_orbit_radius)
		var center = get_viewport_rect().size/2.0
		var new_orbit = BaseOrbit.new(orbit_radius, center)
		orbits.append(new_orbit)
		add_child(new_orbit)
	
	var gen_moon = OrbitingBody.new()
	gen_moon.init_random_planet()
	orbits[0].add_child(gen_moon)
	
	orbits[0].visualize_debug(true)
	orbits[10].visualize_debug(true)
	orbits[20].visualize_debug(true)
	
	player = player_scene.instantiate()
	orbits[10].add_child(player)

	# Hooks up signal to increment research meter
	enter_key_pressed.connect(gen_moon._on_enter_pressed)


func _process(delta: float) -> void:
	camera.position = player.position
	var player_angle = player.progress_ratio * TAU
	# Add PI to flip camera 180 degrees
	camera.rotation = player_angle + PI
	# Move the camera 100 units "up" relative to the camera's perspective (transform)
	camera.position += camera.transform.y.normalized() * -100

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			enter_key_pressed.emit()
