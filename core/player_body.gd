class_name PlayerBody extends OrbitingBody

	
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
