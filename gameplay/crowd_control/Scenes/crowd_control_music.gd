extends Node
class_name CrowdControlMusic

# Audio players for different channels
var melody_player: AudioStreamPlayer
var bass_player: AudioStreamPlayer
var drums_player: AudioStreamPlayer
var harmony_player: AudioStreamPlayer  # Additional layer for arpeggios and chords

# Music properties
var bpm: float = 160.0  # Faster, more sporty tempo
var beat_duration: float = 60.0 / bpm
var is_playing: bool = false
var current_beat: int = 0

# Note frequencies (8-bit style)
const NOTES = {
	"C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23,
	"G4": 392.00, "A4": 440.00, "B4": 493.88,
	"C5": 523.25, "D5": 587.33, "E5": 659.25, "F5": 698.46,
	"G5": 783.99, "A5": 880.00, "B5": 987.77,
	"C6": 1046.50, "D6": 1174.66, "E6": 1318.51, "F6": 1396.91, "G6": 1567.98
}

# Melody pattern (more sporty, energetic, and catchy - like a sports anthem!)
var melody_pattern = [
	# Main hook - punchy and memorable
	"G5", "G5", "A5", "B5", "REST", "B5", "A5", "G5",
	"E5", "E5", "F5", "G5", "REST", "G5", "F5", "E5",
	
	# Variation with higher energy
	"G5", "G5", "A5", "B5", "C6", "B5", "A5", "G5",
	"A5", "A5", "B5", "C6", "REST", "C6", "B5", "A5",
	
	# Breakdown - build anticipation
	"D5", "E5", "F5", "G5", "A5", "B5", "C6", "D6",
	"C6", "B5", "A5", "G5", "F5", "E5", "D5", "C5",
	
	# Return to hook with intensity
	"G5", "A5", "B5", "C6", "D6", "C6", "B5", "A5",
	"G5", "G5", "REST", "G5", "A5", "B5", "C6", "REST"
]

# Bass pattern (driving, pumping bass)
var bass_pattern = [
	# Pumping quarter notes
	"C4", "C4", "REST", "C4", "C4", "REST", "C4", "REST",
	"C4", "C4", "REST", "C4", "C4", "REST", "C4", "REST",
	
	# Variation
	"A3", "A3", "REST", "A3", "A3", "REST", "A3", "REST",
	"A3", "A3", "REST", "A3", "A3", "REST", "A3", "REST",
	
	# Movement
	"F3", "F3", "REST", "F3", "G3", "G3", "REST", "G3",
	"A3", "A3", "REST", "A3", "B3", "B3", "REST", "B3",
	
	# Build back up
	"C4", "C4", "REST", "C4", "C4", "REST", "C4", "REST",
	"C4", "C4", "REST", "C4", "D4", "D4", "REST", "D4"
]

# Harmony/Arpeggio pattern (fast arpeggios for energy)
var harmony_pattern = [
	# Fast arpeggios (16th note feel)
	"E4", "G4", "C5", "E5", "C5", "G4", "E4", "G4",
	"E4", "G4", "C5", "E5", "C5", "G4", "E4", "G4",
	
	"E4", "A4", "C5", "E5", "C5", "A4", "E4", "A4",
	"E4", "A4", "C5", "E5", "C5", "A4", "E4", "A4",
	
	"D4", "F4", "A4", "D5", "A4", "F4", "D4", "F4",
	"D4", "G4", "B4", "D5", "B4", "G4", "D4", "G4",
	
	"E4", "G4", "C5", "E5", "G5", "E5", "C5", "G4",
	"E4", "G4", "C5", "E5", "REST", "REST", "REST", "REST"
]

func _ready():
	setup_audio_players()
	
func setup_audio_players():
	"""Create audio players for each channel"""
	melody_player = AudioStreamPlayer.new()
	melody_player.bus = "Master"
	melody_player.volume_db = -5
	add_child(melody_player)
	
	bass_player = AudioStreamPlayer.new()
	bass_player.bus = "Master"
	bass_player.volume_db = -8
	add_child(bass_player)
	
	drums_player = AudioStreamPlayer.new()
	drums_player.bus = "Master"
	drums_player.volume_db = -10
	add_child(drums_player)
	
	harmony_player = AudioStreamPlayer.new()
	harmony_player.bus = "Master"
	harmony_player.volume_db = -12
	add_child(harmony_player)

func play_music():
	"""Start playing the chiptune"""
	if is_playing:
		return
	
	is_playing = true
	current_beat = 0
	play_next_beat()

func stop_music():
	"""Stop the music"""
	is_playing = false
	melody_player.stop()
	bass_player.stop()
	drums_player.stop()
	harmony_player.stop()

func play_next_beat():
	"""Play the next beat in the sequence"""
	if not is_playing:
		return
	
	# Get current notes
	var melody_note = melody_pattern[current_beat % melody_pattern.size()]
	var bass_note = bass_pattern[current_beat % bass_pattern.size()]
	var harmony_note = harmony_pattern[current_beat % harmony_pattern.size()]
	
	# Play melody
	if melody_note != "REST":
		play_square_wave(melody_player, NOTES[melody_note], 0.15, 0.5)
	
	# Play bass
	if bass_note != "REST":
		play_square_wave(bass_player, NOTES.get(bass_note, 130.0), 0.2, 0.3)
	
	# Play harmony/arpeggios (shorter, punchier notes)
	if harmony_note != "REST":
		play_square_wave(harmony_player, NOTES[harmony_note], 0.08, 0.25)
	
	# Play drums on beats 0, 4, 8, 12 (kick) and 2, 6, 10, 14 (snare)
	if current_beat % 4 == 0:
		play_kick_drum()
	elif current_beat % 4 == 2:
		play_snare_drum()
	
	# Hi-hat on every other beat
	if current_beat % 2 == 1:
		play_hihat()
	
	current_beat += 1
	
	# Schedule next beat
	get_tree().create_timer(beat_duration).timeout.connect(play_next_beat)

func play_square_wave(player: AudioStreamPlayer, frequency: float, duration: float, duty_cycle: float = 0.5):
	"""Generate and play a square wave (classic 8-bit sound)"""
	var sample_rate = 44100
	var samples = int(sample_rate * duration)
	
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_rate
	stream.buffer_length = duration
	
	player.stream = stream
	player.play()
	
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	
	var increment = frequency / sample_rate
	var phase = 0.0
	
	for i in range(samples):
		var value = 1.0 if fmod(phase, 1.0) < duty_cycle else -1.0
		
		# Apply envelope (attack and decay)
		var envelope = 1.0
		if i < sample_rate * 0.01:  # Attack
			envelope = float(i) / (sample_rate * 0.01)
		elif i > samples - (sample_rate * 0.05):  # Decay
			envelope = float(samples - i) / (sample_rate * 0.05)
		
		value *= envelope * 0.3  # Volume control
		
		playback.push_frame(Vector2(value, value))
		phase += increment

func play_kick_drum():
	"""Generate a kick drum sound"""
	play_sweep(drums_player, 150.0, 50.0, 0.15)

func play_snare_drum():
	"""Generate a snare drum sound using noise"""
	play_noise(drums_player, 0.08, 0.2)

func play_hihat():
	"""Generate a hi-hat sound"""
	play_noise(drums_player, 0.05, 0.1)

func play_sweep(player: AudioStreamPlayer, start_freq: float, end_freq: float, duration: float):
	"""Play a frequency sweep (good for kick drums)"""
	var sample_rate = 44100
	var samples = int(sample_rate * duration)
	
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_rate
	stream.buffer_length = duration
	
	player.stream = stream
	player.play()
	
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	
	var phase = 0.0
	
	for i in range(samples):
		var progress = float(i) / samples
		var frequency = lerp(start_freq, end_freq, progress)
		var increment = frequency / sample_rate
		
		var value = sin(phase * TAU)
		
		# Envelope
		var envelope = 1.0 - progress
		value *= envelope * 0.4
		
		playback.push_frame(Vector2(value, value))
		phase += increment
		if phase > 1.0:
			phase -= 1.0

func play_noise(player: AudioStreamPlayer, duration: float, volume: float = 0.2):
	"""Play white noise (for snare/hi-hat)"""
	var sample_rate = 44100
	var samples = int(sample_rate * duration)
	
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_rate
	stream.buffer_length = duration
	
	player.stream = stream
	player.play()
	
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	
	for i in range(samples):
		var value = (randf() * 2.0 - 1.0)
		
		# Envelope
		var envelope = 1.0 - (float(i) / samples)
		value *= envelope * volume
		
		playback.push_frame(Vector2(value, value))
