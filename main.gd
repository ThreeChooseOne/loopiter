extends Node2D

@onready var orbit: Path2D = %Orbit

var orbits: Array[BaseOrbit] = []

var moons: Array[OrbitingBody] = []
var debug_orbit
func _ready() -> void:
	# Initialize orbit with a random planet
	orbit.add_random_planet()
	
	# Add 5 orbits
	for n in 5:
		var orbit_radius = (n+1)*300.0
		var center = get_viewport_rect().size/2.0
		var new_orbit = BaseOrbit.new(orbit_radius, center)
		orbits.append(new_orbit)
		add_child(new_orbit)
	
	var gen_moon = OrbitingBody.new()
	moons.append(gen_moon)
	orbits[0].add_child(gen_moon.get_follower())
	
	# TODO: Refactor this visualization code somewhere else
	# debug_orbit = Line2D.new()
	# debug_orbit.points = orbits[0].curve.get_baked_points()
	# add_child(debug_orbit)
	
func _process(delta: float) -> void:
	# Should main be updating the orbits?
	for mm in moons:
		mm.update(delta)
