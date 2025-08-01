extends Node2D

@onready var orbit: Path2D = %Orbit

var orbits: Array[BaseOrbit] = []

var moons: Array[OrbitingBody] = []
var debug_orbit
func _ready() -> void:
	# Initialize orbit with a random planet
	orbit.add_random_planet()
	
	for n in 5:
		var orbit_radius = (n+1)*200.0
		var center = Vector2()
		orbits.append(BaseOrbit.new(orbit_radius, center))
	
	var gen_moon = OrbitingBody.new()
	moons.append(gen_moon)
	orbits[0].add_child(gen_moon.get_follower())
	debug_orbit = Line2D.new()
	debug_orbit.points = orbits[0].curve.get_baked_points()
	add_child(debug_orbit)
	print(orbits[0])
	
func _process(delta: float) -> void:
	for mm in moons:
		mm.update(delta)
