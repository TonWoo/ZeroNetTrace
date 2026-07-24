extends Node

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _phase := 0.0
var _sting_frames := 0
var _silence_frames := 0
var _hard_drive_frames := 0
var _key_frames := 0
var _progress_frames := 0
var _progress_total_frames := 0
var _progress_queued := false
var _progress_queued_frames := 0
var _noise_seed := 17357

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_player = AudioStreamPlayer.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.3
	_player.stream = generator
	_player.volume_db = -34.0
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()

func _process(_delta: float) -> void:
	if _playback == null:
		return
	var frames := _playback.get_frames_available()
	for _index in frames:
		if _progress_queued and _sting_frames <= 0 and _silence_frames <= 0 and _progress_frames <= 0:
			_start_progress(_progress_queued_frames)
		var frequency := 71.0
		var amplitude := 0.018
		var sample := 0.0
		if _sting_frames > 0:
			frequency = 930.0
			amplitude = 0.16
		elif _silence_frames > 0:
			amplitude = 0.0
		elif _hard_drive_frames > 0:
			_noise_seed = int((_noise_seed * 1103515245 + 12345) & 0x7fffffff)
			var noise := float(_noise_seed) / 1073741824.0 - 1.0
			amplitude = 0.035 if _hard_drive_frames % 97 > 9 else 0.075
			sample = noise * amplitude
		elif _key_frames > 0:
			frequency = 1450.0
			amplitude = 0.045
		elif _progress_frames > 0:
			var elapsed := _progress_total_frames - _progress_frames
			frequency = 620.0 if elapsed < _progress_total_frames / 2 else 820.0
			amplitude = 0.022
		if not (_hard_drive_frames > 0 and _sting_frames <= 0 and _silence_frames <= 0):
			sample = sin(_phase) * amplitude
		_phase = fmod(_phase + TAU * frequency / 22050.0, TAU)
		_playback.push_frame(Vector2(sample, sample))
		if _sting_frames > 0:
			_sting_frames -= 1
		elif _silence_frames > 0:
			_silence_frames -= 1
		elif _hard_drive_frames > 0:
			_hard_drive_frames -= 1
		elif _key_frames > 0:
			_key_frames -= 1
		elif _progress_frames > 0:
			_progress_frames -= 1

func play_sting(duration := 0.22) -> void:
	_queue_active_progress()
	_sting_frames = int(22050.0 * duration)

func begin_silence(duration: float) -> void:
	_queue_active_progress()
	_silence_frames = maxi(_silence_frames, int(22050.0 * duration))
	_hard_drive_frames = 0
	_key_frames = 0

func play_key_tick() -> void:
	_key_frames = max(_key_frames, 120)

func play_hard_drive(duration := 0.12) -> void:
	_hard_drive_frames = maxi(_hard_drive_frames, int(22050.0 * duration))

func play_progress_soft(duration := 0.16) -> void:
	var requested_frames := maxi(1, int(22050.0 * duration))
	if _sting_frames > 0 or _silence_frames > 0:
		_progress_queued = true
		_progress_queued_frames = maxi(_progress_queued_frames, requested_frames)
		return
	_start_progress(requested_frames)

func _start_progress(frames: int) -> void:
	_progress_total_frames = maxi(frames, 1)
	_progress_frames = _progress_total_frames
	_progress_queued = false
	_progress_queued_frames = 0

func _queue_active_progress() -> void:
	if _progress_frames <= 0:
		return
	_progress_queued = true
	_progress_queued_frames = maxi(_progress_queued_frames, _progress_total_frames)
	_progress_frames = 0

func _exit_tree() -> void:
	if _player:
		_player.stop()
		_player.stream = null
		if _player.get_parent() == self:
			remove_child(_player)
		_player.free()
		_player = null
	_playback = null
