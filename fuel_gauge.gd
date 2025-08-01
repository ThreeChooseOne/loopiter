extends TextureProgressBar

func _process(delta: float) -> void:
	value = fmod(value + 20 * delta, 100.0)
	return
