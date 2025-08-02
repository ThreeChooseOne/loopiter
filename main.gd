extends Node2D

@onready var orbit: Path2D = %Orbit

var orbits: Array[BaseOrbit] = []

var moons: Array[OrbitingBody] = []

var max_viewport_size: Vector2

func _ready() -> void:
	max_viewport_size = get_viewport_rect().size
	
	# Initialize orbit with a random planet
	orbit.add_random_planet()
	
	# Add 5 orbits
	for n in 21:
		# TODO: figure out the radius ranges
		var orbit_radius = (n+1)*300.0
		var center = get_viewport_rect().size/2.0
		var new_orbit = BaseOrbit.new(orbit_radius, center)
		orbits.append(new_orbit)
		add_child(new_orbit)
	
	var gen_moon = OrbitingBody.new() # creates a random asset for it
	moons.append(gen_moon)
	orbits[0].add_child(gen_moon.get_follower())
	
	# TODO: Add more moons
	
	# TODO: Refactor this visualization code somewhere else
	# debug_orbit = Line2D.new()
	# debug_orbit.points = orbits[0].curve.get_baked_points()
	# add_child(debug_orbit)
	
	$PlayerCamera.update_camera_position(Vector2(0,0))
	
func _process(delta: float) -> void:
	# Should main be updating the orbits?
	for mm in moons:
		mm.update(delta)
