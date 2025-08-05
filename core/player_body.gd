class_name PlayerBody extends OrbitingBody

signal player_crashed
	
func explode():
	%PlayerSprite.visible = false
	%Explosion.visible = true
	%Explosion/Timer.start()

func _on_explostion_timer_timeout() -> void:
	%Explosion.visible = false
	%PlayerSprite.visible = true
	player_crashed.emit()
