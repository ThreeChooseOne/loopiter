extends TextureProgressBar

func _process(delta: float) -> void:
	var progress = fmod(self.get_value() + 100*delta, 100.0)
	self.set_value_no_signal(progress)
	return
