extends Node2D

var orbits: Array[BaseOrbit] = []
var moons: Array[OrbitingBody] = []
var max_viewport_size: Vector2

func _ready() -> void:
	max_viewport_size = get_viewport_rect().size
	
	$SpaceBackground.size = max_viewport_size
	$JupiterBG_Container.size = max_viewport_size
	
	# Add 5 orbits
	var min_orbit_radius = 200
	var max_orbit_radius = min(max_viewport_size.x, max_viewport_size.y)/2.2
	
	for n in 21:
		# TODO: figure out the radius ranges
		var orbit_radius = min_orbit_radius + (n/21.0)*(max_orbit_radius - min_orbit_radius)
		var center = get_viewport_rect().size/2.0
		var new_orbit = BaseOrbit.new(orbit_radius, center)
		orbits.append(new_orbit)
		add_child(new_orbit)
	
	var gen_moon = OrbitingBody.new() # creates a random asset for it
	moons.append(gen_moon)
	orbits[0].add_child(gen_moon.get_follower())
	
	orbits[0].visualize_debug(true)
	orbits[10].visualize_debug(true)
	orbits[20].visualize_debug(true)

	# Hooks up signal to increment research meter
	$PlayerCamera.enter_key_pressed.connect(gen_moon._on_enter_pressed)
	$PlayerCamera.update_camera_position(Vector2(0,0))
	
	
func _process(delta: float) -> void:
	# Should main be updating the orbits?
	for mm in moons:
		mm.update(delta)
