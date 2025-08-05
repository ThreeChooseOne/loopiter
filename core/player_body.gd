class_name PlayerBody extends OrbitingBody

const Types = preload("res://core/common_types.gd")

# Controls settings
const FUEL_COST_SWITCHING_ORBIT := 20.0
const FUEL_RECOVERY_RATE_PER_SEC := 20.0
const FUEL_COST_SPEED_CHANGE := 5.0
const PLAYER_MAX_SPEED: int = 300
const PLAYER_MIN_SPEED: int = 50

const PLAYER_SPEED_INCREMENT := 20

@export var current_fuel: float = 100.0
@export var curr_orbit_idx: int = 0

var orbit_radar_viz: OrbitRadarViz = null

signal fuel_unavailable

func _ready() -> void:
	var orbit_radar_viz_scene: PackedScene = load("res://jazz/circular_halo_mask.tscn")
	orbit_radar_viz = orbit_radar_viz_scene.instantiate()
	add_child(orbit_radar_viz)
	
func explode():
	%PlayerSprite.visible = false
	%Explosion.visible = true
	%Explosion/Timer.start()
	
func is_the_player() -> bool:
	return true

func _on_explostion_timer_timeout() -> void:
	%Explosion.visible = false
	%PlayerSprite.visible = true
	player_crashed.emit()

func move_player_orbit(orbit_change_dir: Types.OrbitChangeDirection, orbits: Array[BaseOrbit]):
	if current_fuel < FUEL_COST_SWITCHING_ORBIT:
		fuel_unavailable.emit()
		return
	var next_orbit_idx := curr_orbit_idx
	if orbit_change_dir == Types.OrbitChangeDirection.POWERADE:
		next_orbit_idx -= 1
	if orbit_change_dir == Types.OrbitChangeDirection.GATORADE:
		next_orbit_idx += 1
	next_orbit_idx = clamp(next_orbit_idx, 0, orbits.size())
	if curr_orbit_idx == next_orbit_idx:
		return
	current_fuel -= FUEL_COST_SWITCHING_ORBIT
	#var curr_progress_ratio := progress_ratio
	orbits[curr_orbit_idx].remove_child(self)
	orbits[next_orbit_idx].add_child(self)
	# Keep player angle the same between orbits
	#progress_ratio = curr_progress_ratio
	update_orbit_radar_viz(orbits[next_orbit_idx])
	curr_orbit_idx = next_orbit_idx


func request_player_speed_change(speed_change: Types.SpeedChangeType):
	if current_fuel < FUEL_COST_SPEED_CHANGE:
		fuel_unavailable.emit()
		return
	current_fuel -= FUEL_COST_SPEED_CHANGE
	if speed_change == Types.SpeedChangeType.ACCELERATE:
		speed += PLAYER_SPEED_INCREMENT
	if speed_change == Types.SpeedChangeType.DECELERATE:
		speed -= PLAYER_SPEED_INCREMENT
	speed = clamp(speed, PLAYER_MIN_SPEED, PLAYER_MAX_SPEED)


func update_orbit_radar_viz(orbit: BaseOrbit):
	orbit_radar_viz.add_orbit_viz(orbit)
	
func has_sufficient_fuel() -> bool:
	if current_fuel > FUEL_COST_SWITCHING_ORBIT:
		return true
	return false


func _process(delta: float) -> void:
	current_fuel = clampf(current_fuel + FUEL_RECOVERY_RATE_PER_SEC * delta, 0, 100)
	progress += speed * delta
