@tool
extends SceneTree

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/audio")
	_create_wav("res://assets/audio/thorn_shoot.wav", 0.12, 22050, func(t: float, dur: float) -> float:
		var p: float = t / dur
		var freq: float = 900.0 * (1.0 - p * 0.7)
		var sine: float = sin(TAU * freq * t)
		var noise: float = (randf() * 2.0 - 1.0) * (1.0 - p) * 0.25
		var env: float = exp(-p * 8.0)
		return (sine * 0.75 + noise) * env
	)
	_create_wav("res://assets/audio/snail_defeat.wav", 0.22, 22050, func(t: float, dur: float) -> float:
		var p: float = t / dur
		var sweep: float = sin(p * PI)
		var freq: float = 240.0 + 460.0 * sweep
		var sine: float = sin(TAU * freq * t)
		var harm: float = sin(TAU * freq * 2.0 * t) * 0.3
		var env: float = sin(p * PI) * exp(-p * 3.5)
		return (sine + harm) * env
	)
	print("Audio generation completed!")
	quit()

func _create_wav(path: String, duration: float, sample_rate: int, generator: Callable) -> void:
	var num_samples: int = int(sample_rate * duration)
	var data_size: int = num_samples * 2
	var f := FileAccess.open(path, FileAccess.WRITE)
	if not f:
		print("Failed to open " + path)
		return
	f.store_string("RIFF")
	f.store_32(36 + data_size)
	f.store_string("WAVE")
	f.store_string("fmt ")
	f.store_32(16)
	f.store_16(1)
	f.store_16(1)
	f.store_32(sample_rate)
	f.store_32(sample_rate * 2)
	f.store_16(2)
	f.store_16(16)
	f.store_string("data")
	f.store_32(data_size)
	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var val: float = clampf(generator.call(t, duration), -1.0, 1.0)
		var sample: int = int(val * 32767.0)
		f.store_16(sample)
	f.close()
