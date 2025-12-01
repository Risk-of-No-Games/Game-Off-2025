extends Node
class_name CrowdControlGame

# References
@export var player_crowd_manager: CrowdManager
@export var all_crowd_managers: Array[CrowdManager] = []

# Difficulty settings
@export_range(1, 6) var difficulty: int = 1  # 1 = Easiest, 5 = Hardest

# Timing settings
@export var success_window: float = 0.4  # Success timing window (seconds)

var music_player: CrowdControlMusic

# Difficulty presets (don't edit these directly, they're set by difficulty level)
var wave_duration: float = 5.0  # Total duration for wave to complete (seconds)
var waves_per_game: int = 3  # Number of waves before game ends
var wave_pause_duration: float = 1.0  # Pause between waves (seconds)

# Game state
var game_active: bool = false
var wave_active: bool = false  # Prevents overlapping waves
var wave_reaching_player_time: float = 0.0
var player_has_acted: bool = false
var current_wave_direction: int = 1
var auto_fail_timer  = null  # Reference to cancel timer if needed

# Scoring
var score: int = 0
var lives: int = 1
var max_lives: int = 1
var waves_completed: int = 0

# Signals
signal wave_started(direction: int)
signal player_result(success: bool)
signal lives_changed(current_lives: int, max_lives: int)
signal score_changed(new_score: int)
signal game_over(final_score: int, waves_completed: int)

func _ready():
	if player_crowd_manager == null:
		push_error("CrowdControlGame: Player CrowdManager reference is missing!")
	if all_crowd_managers.is_empty():
		push_error("CrowdControlGame: No crowd managers assigned!")
		
	# Add music
	music_player = CrowdControlMusic.new()
	
	add_child(music_player)
	# Apply difficulty settings
	apply_difficulty_preset()
	start_game()

func apply_difficulty_preset():
	"""Apply settings based on difficulty level"""
	match difficulty:
		1:  # Easiest
			wave_duration = 5.0
			waves_per_game = 3
			wave_pause_duration = 2.0
		2:  # Easy
			wave_duration = 4.0
			waves_per_game = 5
			wave_pause_duration = 1.5
		3:  # Medium
			wave_duration = 3.0
			waves_per_game = 7
			wave_pause_duration = 1.0
		4:  # Hard
			wave_duration = 2.0
			waves_per_game = 9
			wave_pause_duration = 0.75
		5:  # Hardest
			wave_duration = 1
			waves_per_game = 10
			wave_pause_duration = 0
		6:  # Hardester
			wave_duration = 1
			waves_per_game = 10
			wave_pause_duration = -0.2
	
	print("Difficulty set to: ", difficulty)
	print("Wave duration: ", wave_duration, "s | Waves per game: ", waves_per_game, " | Pause: ", wave_pause_duration, "s")

func _input(event):
	if event.is_action_pressed("ui_accept"):
		# Trigger player wave animation immediately, regardless of timing
		if player_crowd_manager != null:
			player_crowd_manager.trigger_player_wave()
		
	# Player action during game - only if wave is active and hasn't acted yet
	if event.is_action_pressed("ui_accept") and wave_active and not player_has_acted:
		# Then check timing
		check_player_timing()

func start_game():
	"""Initialize and start a new game"""
	game_active = true
	score = 0
	lives = max_lives
	waves_completed = 0
	player_has_acted = false
	
	lives_changed.emit(lives, max_lives)
	score_changed.emit(score)
	
	print("CrowdControl Started! Difficulty: ", difficulty, " | Get ready...")
	
	# Start the music
	if music_player:
		music_player.play_music()
	
	# Start first wave after a brief delay
	get_tree().create_timer(4.0).timeout.connect(
		func(): trigger_new_wave()
	)

func trigger_new_wave():
	"""Start a new wave moving toward the player"""
	if not game_active or wave_active:
		return  # Don't start a new wave if one is already active
	
	wave_active = true
	player_has_acted = false
	
	# Randomize direction
	current_wave_direction = 1 if randf() > 0.5 else -1
	
	# Get center column from player's crowd manager
	var center_col = player_crowd_manager.get_center_column_index()
	
	# Calculate total NPCs in player's crowd
	var total_npcs = (player_crowd_manager.left_section_size + player_crowd_manager.left_gap + 
					  player_crowd_manager.center_section_size + player_crowd_manager.right_gap + 
					  player_crowd_manager.right_section_size)
	
	# Calculate wave speed based on desired duration
	# wave_speed = wave_duration / total_npcs
	var wave_speed = wave_duration / total_npcs
	
	# Calculate delay based on direction
	var delay_to_player: float
	if current_wave_direction == 1:  # Left to right
		delay_to_player = center_col * wave_speed
	else:  # Right to left
		delay_to_player = (total_npcs - center_col) * wave_speed
	
	wave_reaching_player_time = Time.get_ticks_msec() / 1000.0 + delay_to_player
	
	# Trigger the wave across all crowd managers with adjusted speeds
	for manager in all_crowd_managers:
		if manager != null:
			# Calculate this manager's total NPCs
			var manager_total_npcs = (manager.left_section_size + manager.left_gap + 
									  manager.center_section_size + manager.right_gap + 
									  manager.right_section_size)
			
			# Calculate adjusted speed so this manager finishes in the same time
			var adjusted_speed = wave_duration / manager_total_npcs
			
			manager.trigger_wave(current_wave_direction, adjusted_speed)
	
	wave_started.emit(current_wave_direction)
	
	# Create auto-fail timer
	auto_fail_timer = get_tree().create_timer(delay_to_player + success_window)
	auto_fail_timer.timeout.connect(
		func():
			if wave_active and not player_has_acted:
				handle_fail()
	)

func check_player_timing():
	"""Check if the player timed their button press correctly"""
	player_has_acted = true
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_difference = abs(current_time - wave_reaching_player_time)
	
	if time_difference <= success_window:
		handle_success()
	else:
		handle_fail()

func handle_success():
	"""Handle successful timing"""
	if not wave_active:
		return  # Prevent duplicate processing
	
	wave_active = false  # Mark wave as complete
	player_has_acted = true
	
	score += 100
	waves_completed += 1
	
	score_changed.emit(score)
	player_result.emit(true)
	
	print("SUCCESS! +100 | Score: ", score, " | Wave ", waves_completed, "/", waves_per_game)
	
	# Check if all waves completed
	if waves_completed >= waves_per_game:
		win_game()
		return
	
	# Trigger next wave after current one finishes
	schedule_next_wave()

func handle_fail():
	"""Handle failed timing or miss"""
	if not wave_active:
		return  # Prevent duplicate processing
	
	wave_active = false  # Mark wave as complete
	player_has_acted = true
	
	lives -= 1
	
	lives_changed.emit(lives, max_lives)
	player_result.emit(false)
	
	print("FAIL! Lives remaining: ", lives)
	
	# Check for game over
	if lives <= 0:
		end_game()
		return
	
	# Continue to next wave
	schedule_next_wave()

func schedule_next_wave():
	"""Schedule the next wave after a delay"""
	var wave_complete_delay = wave_duration + wave_pause_duration
	get_tree().create_timer(wave_complete_delay).timeout.connect(
		func(): trigger_new_wave()
	)

func win_game():
	"""Handle winning the game by completing all waves"""
	game_active = false
	print("YOU WIN! Final Score: ", score, " | Waves: ", waves_completed, "/", waves_per_game)
	game_over.emit(score, waves_completed)

func end_game():
	"""End the current game (loss)"""
		# Stop the music
	if music_player:
		music_player.stop_music()
		
	game_active = false
	game_over.emit(score, waves_completed)
	print("Game Over! Final Score: ", score, " | Waves: ", waves_completed, "/", waves_per_game)
