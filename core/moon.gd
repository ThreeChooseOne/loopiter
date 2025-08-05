class_name MoonBody extends OrbitingBody

const RESEARCH_ON_MODULATION = Color(1.0, 1.0, 1.0, 0.2)
const RESEARCH_OFF_MODULATION = Color(0.8, 0.8, 0.8, 0.1)
const INDICATOR_MAX_SIZE = 100.0
const INDICATOR_MIN_SIZE = 26.0

const ALL_SPRITES = [
	preload("res://assets/planets/planet00.png"),
	preload("res://assets/planets/planet01.png"),
	preload("res://assets/planets/planet02.png"),
	preload("res://assets/planets/planet03.png"),
	preload("res://assets/planets/planet04.png"),
	preload("res://assets/planets/planet05.png"),
	preload("res://assets/planets/planet07.png"),
	preload("res://assets/planets/planet08.png"),
	preload("res://assets/planets/planet09.png"),
]

var is_research_complete: bool = false
var is_habitable: bool = false
var player_in_research_range: bool = false
var current_research_player: OrbitingBody = null

signal research_area_entered(moon: MoonBody)
signal research_area_exited(moon: MoonBody)
signal research_completed(moon: MoonBody)
signal player_crash_mode_reset

@onready var research_timer: Timer = %ResearchTimer
@onready var reset_timer: Timer = %ResetTimer
@onready var moon_sprite: Sprite2D = %MoonSprite
@onready var range_indicator: Sprite2D = %RangeIndicator
@onready var research_bar: TextureProgressBar = %ResearchBar

func set_random_sprite() -> void:
	moon_sprite.texture = ALL_SPRITES[randi() % ALL_SPRITES.size()]

func _on_area_entered(area):
	# Only the player can interact with this collision area (mask: layer 1)
	var player: OrbitingBody = area.get_parent()
	print("Player crashed into moon!")
	research_timer.paused = true
	player.explode()
		
func _on_area_exited(area):
	# Only the player can interact with this collision area (mask: layer 1)
	var player: OrbitingBody = area.get_parent()
	print("Player uncrashed into moon!")
	research_timer.paused = false
	player_crash_mode_reset.emit()
	
# Research area event handlers
func _on_research_area_entered(area):
	# Only the player can interact with this collision area (mask: layer 1)
	var player: OrbitingBody = area.get_parent()
	print("Player entered research range of moon!")
	reset_timer.stop()
	if not player_in_research_range:
		current_research_player = player
		player_in_research_range = true
		start_research_collection()
		research_area_entered.emit(player)
		range_indicator.modulate = RESEARCH_ON_MODULATION
	
func _on_research_area_exited(area):
	# Only the player can interact with this collision area (mask: layer 1)
	var player: OrbitingBody = area.get_parent()
	print("Player left research range of moon!")
	reset_timer.start()
		
func start_research_collection():
	if research_bar.value < research_bar.max_value:
		print("Starting research collection timer...")
		research_timer.start()
		
func stop_research_collection():
	print("Stopping research collection timer...")
	research_timer.stop()
	
func _on_reset_timer_timeout():
	reset_timer.stop()
	print("Grace period ended!")
	player_in_research_range = false
	current_research_player = null
	stop_research_collection()
	range_indicator.modulate = RESEARCH_OFF_MODULATION
	
func _on_research_timer_timeout():
	if player_in_research_range and research_bar.value < research_bar.max_value:
		research_bar.value += 1
		print("Research progress: ", research_bar.value, "/", research_bar.max_value)
		
		# Check if research is complete
		if research_bar.value >= research_bar.max_value:
			print("Research complete for this moon!")
			complete_research()
		else:
			# Continue collecting if player still in range
			research_timer.start()

func complete_research():
	if not is_research_complete:
		is_research_complete = true
		stop_research_collection()
		research_completed.emit(self)  # Emit the signal
		print("Moon ", name, " research completed - signal emitted")
		
func make_habitable():
	is_habitable = true
	print("Moon ", name, " is now marked as HABITABLE!")
	if moon_sprite:
		moon_sprite.modulate = Color.GREEN

func _process(delta: float) -> void:
	super._process(delta)
	if !research_timer.is_stopped():
		queue_redraw()

func _draw() -> void:
	if !research_timer.is_stopped():
		var ratio = research_timer.time_left / research_timer.wait_time
		var radius = lerp(INDICATOR_MIN_SIZE, INDICATOR_MAX_SIZE, ratio)
		if research_timer.paused:
			draw_circle(Vector2.ZERO, radius, Color.DARK_RED, false, 1.0)
		else:
			draw_circle(Vector2.ZERO, radius, Color.GHOST_WHITE, false, 1.0)
