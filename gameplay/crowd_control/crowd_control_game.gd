extends Node
class_name CrowdControlGame

# References
@export var player_crowd_manager: CrowdManager
@export var all_crowd_managers: Array[CrowdManager] = []

# Timing settings
@export var success_window: float = 0.4  # Success timing window (seconds)

var music_player: CrowdControlMusic

# Current difficulty (progresses automatically)
var current_difficulty: int = 1
var max_difficulty: int = 6

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
var auto_fail_timer = null  # Reference to cancel timer if needed

# Scoring
var total_score: int = 0  # Total score across all difficulties
var difficulty_score: int = 0  # Score for current difficulty
var waves_completed: int = 0
var waves_missed: int = 0

# UI Elements
var status_label: Label = null
var difficulty_label: Label = null
var score_label: Label = null

# Signals
signal wave_started(direction: int)
signal player_result(success: bool, time_difference: float)
signal score_changed(new_score: int)
signal difficulty_changed(new_difficulty: int)
signal difficulty_completed(difficulty: int, score: int, waves_hit: int, waves_missed: int)
signal game_completed(final_score: int)

func _ready():
	if player_crowd_manager == null:
		push_error("CrowdControlGame: Player CrowdManager reference is missing!")
	if all_crowd_managers.is_empty():
		push_error("CrowdControlGame: No crowd managers assigned!")
		
	# Add music
	music_player = CrowdControlMusic.new()
	add_child(music_player)
	
	# Create UI
	create_ui()
	
	# Start the game
	start_game()

func create_ui():
	"""Create in-game UI elements"""
	# Status label (for wave notifications) - centered horizontally
	status_label = Label.new()
	status_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	status_label.offset_left = -400  # Half of width to center
	status_label.offset_top = 20
	status_label.offset_right = 400  # Half of width
	status_label.offset_bottom = 120
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	status_label.add_theme_font_size_override("font_size", 36)
	status_label.modulate = Color(1, 1, 1, 0)  # Start invisible
	add_child(status_label)
	
	# Difficulty label
	difficulty_label = Label.new()
	difficulty_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	difficulty_label.position = Vector2(20, 20)
	difficulty_label.add_theme_font_size_override("font_size", 24)
	add_child(difficulty_label)
	
	# Score label
	score_label = Label.new()
	score_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	score_label.position = Vector2(-200, 20)
	score_label.size = Vector2(180, 40)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", 24)
	add_child(score_label)

func update_ui():
	"""Update UI labels"""
	if difficulty_label:
		difficulty_label.text = "Difficulty: %d/%d" % [current_difficulty, max_difficulty]
	
	if score_label:
		score_label.text = "Score: %d" % total_score

func show_status_message(message: String, duration: float = 2.0, color: Color = Color.WHITE):
	"""Show a temporary status message"""
	if not status_label:
		return
	
	status_label.text = message
	status_label.modulate = color
	
	# Fade in
	var tween = create_tween()
	tween.tween_property(status_label, "modulate:a", 1.0, 0.3)
	
	# Wait
	await get_tree().create_timer(duration).timeout
	
	# Fade out
	var tween2 = create_tween()
	tween2.tween_property(status_label, "modulate:a", 0.0, 0.3)

func apply_difficulty_preset():
	"""Apply settings based on difficulty level"""
	match current_difficulty:
		1:  # Easiest
			wave_duration = 5.0
			waves_per_game = 3
			wave_pause_duration = 2.0
		2:  # Easy
			wave_duration = 4.0
			waves_per_game = 3
			wave_pause_duration = 1.5
		3:  # Medium
			wave_duration = 3.0
			waves_per_game = 4
			wave_pause_duration = 1.0
		4:  # Hard
			wave_duration = 2.0
			waves_per_game = 5
			wave_pause_duration = 0.75
		5:  # Hardest
			wave_duration = 1.0
			waves_per_game = 6
			wave_pause_duration = 0.5
		6:  # Extreme
			wave_duration = 0.5
			waves_per_game = 7
			wave_pause_duration = -0.2
	
	print("Difficulty %d/%d | Wave duration: %.1fs | Waves: %d | Pause: %.1fs" % 
		[current_difficulty, max_difficulty, wave_duration, waves_per_game, wave_pause_duration])

func _input(event):
	if not game_active:
		return
		
	if event.is_action_pressed("ui_accept"):
		# Trigger player wave animation immediately
		if player_crowd_manager != null:
			player_crowd_manager.trigger_player_wave()
		
		# Check timing if wave is active and hasn't acted yet
		if wave_active and not player_has_acted:
			check_player_timing()

func start_game():
	"""Initialize and start a new game"""
	game_active = true
	total_score = 0
	current_difficulty = 1
	
	score_changed.emit(total_score)
	update_ui()
	
	print("=== CrowdControl Game Started ===")
	print("Complete all 6 difficulties to see your final score!")
	
	# Start the music
	if music_player:
		music_player.play_music()
	
	# Show start message
	show_status_message("GET READY!", 2.0, Color.YELLOW)
	
	# Start first difficulty
	await get_tree().create_timer(2.0).timeout
	start_difficulty()

func start_difficulty():
	"""Start a new difficulty level"""
	difficulty_score = 0
	waves_completed = 0
	waves_missed = 0
	
	apply_difficulty_preset()
	difficulty_changed.emit(current_difficulty)
	update_ui()
	
	print("\n--- Starting Difficulty %d/%d ---" % [current_difficulty, max_difficulty])
	
	# Show difficulty message
	show_status_message("Difficulty %d" % current_difficulty, 1.5, Color.CYAN)
	
	# Brief delay before first wave
	get_tree().create_timer(2.0).timeout.connect(
		func(): trigger_new_wave()
	)

func trigger_new_wave():
	"""Start a new wave moving toward the player"""
	if not game_active or wave_active:
		return
	
	wave_active = true
	player_has_acted = false
	
	# Show wave number
	var current_wave = waves_completed + waves_missed + 1
	show_status_message("Wave %d/%d" % [current_wave, waves_per_game], 1.0, Color.WHITE)
	
	# Randomize direction
	current_wave_direction = 1 if randf() > 0.5 else -1
	
	# Get center column from player's crowd manager
	var center_col = player_crowd_manager.get_center_column_index()
	
	# Calculate total NPCs in player's crowd
	var total_npcs = (player_crowd_manager.left_section_size + player_crowd_manager.left_gap + 
					  player_crowd_manager.center_section_size + player_crowd_manager.right_gap + 
					  player_crowd_manager.right_section_size)
	
	# Calculate wave speed based on desired duration
	var wave_speed = wave_duration / total_npcs
	
	# Calculate delay based on direction
	var delay_to_player: float
	if current_wave_direction == 1:  # Left to right
		delay_to_player = center_col * wave_speed
	else:  # Right to left
		delay_to_player = (total_npcs - center_col) * wave_speed
	
	wave_reaching_player_time = Time.get_ticks_msec() / 1000.0 + delay_to_player
	
	# Trigger the wave across all crowd managers
	for manager in all_crowd_managers:
		if manager != null:
			var manager_total_npcs = (manager.left_section_size + manager.left_gap + 
									  manager.center_section_size + manager.right_gap + 
									  manager.right_section_size)
			var adjusted_speed = wave_duration / manager_total_npcs
			manager.trigger_wave(current_wave_direction, adjusted_speed)
	
	wave_started.emit(current_wave_direction)
	
	# Create auto-fail timer
	auto_fail_timer = get_tree().create_timer(delay_to_player + success_window)
	auto_fail_timer.timeout.connect(
		func():
			if wave_active and not player_has_acted:
				handle_miss()
	)

func check_player_timing():
	"""Check if the player timed their button press correctly"""
	player_has_acted = true
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_difference = abs(current_time - wave_reaching_player_time)
	
	if time_difference <= success_window:
		handle_success(time_difference)
	else:
		handle_miss()

func handle_success(time_difference: float):
	"""Handle successful timing"""
	if not wave_active:
		return
	
	wave_active = false
	player_has_acted = true
	
	# Calculate score based on accuracy (closer = more points)
	var accuracy_bonus = int((1.0 - (time_difference / success_window)) * 50)
	var wave_score = 100 + accuracy_bonus
	
	difficulty_score += wave_score
	total_score += wave_score
	waves_completed += 1
	
	score_changed.emit(total_score)
	player_result.emit(true, time_difference)
	update_ui()
	
	# Show success message
	var accuracy_text = "PERFECT!" if accuracy_bonus >= 40 else "GREAT!" if accuracy_bonus >= 20 else "GOOD!"
	show_status_message("%s +%d" % [accuracy_text, wave_score], 1.0, Color.GREEN)
	
	print("SUCCESS! +%d (%.3fs timing) | Total: %d | Wave %d/%d" % 
		[wave_score, time_difference, total_score, waves_completed, waves_per_game])
	
	# Check if difficulty completed
	if waves_completed + waves_missed >= waves_per_game:
		await get_tree().create_timer(1.5).timeout  # Wait for status message to show
		complete_difficulty()
		return
	
	# Schedule next wave
	schedule_next_wave()

func handle_miss():
	"""Handle missed timing (no points, but game continues)"""
	if not wave_active:
		return
	
	wave_active = false
	player_has_acted = true
	
	waves_missed += 1
	
	player_result.emit(false, 999.0)
	
	# Show miss message
	show_status_message("MISS!", 1.0, Color.RED)
	
	print("MISS! Total: %d | Wave %d/%d" % [total_score, waves_completed + waves_missed, waves_per_game])
	
	# Check if we've attempted all waves for this difficulty
	if waves_completed + waves_missed >= waves_per_game:
		await get_tree().create_timer(1.5).timeout  # Wait for status message to show
		complete_difficulty()
		return
	
	# Continue to next wave
	schedule_next_wave()

func schedule_next_wave():
	"""Schedule the next wave after a delay"""
	var wave_complete_delay = wave_duration + wave_pause_duration
	get_tree().create_timer(wave_complete_delay).timeout.connect(
		func(): trigger_new_wave()
	)

func complete_difficulty():
	"""Handle completion of current difficulty level"""
	print("\n--- Difficulty %d Complete! ---" % current_difficulty)
	print("Score this difficulty: %d" % difficulty_score)
	print("Waves hit: %d/%d" % [waves_completed, waves_per_game])
	
	difficulty_completed.emit(current_difficulty, difficulty_score, waves_completed, waves_missed)
	
	# Show completion message
	show_status_message("Difficulty %d Complete!\n%d/%d Waves Hit" % 
		[current_difficulty, waves_completed, waves_per_game], 2.5, Color.YELLOW)
	
	# Check if all difficulties completed
	if current_difficulty >= max_difficulty:
		await get_tree().create_timer(3.0).timeout
		complete_game()
		return
	
	# Move to next difficulty
	current_difficulty += 1
	
	# Wait before starting next difficulty
	await get_tree().create_timer(3.0).timeout
	start_difficulty()

func complete_game():
	"""Handle completion of all difficulties"""
	game_active = false
	
	# Stop the music
	if music_player:
		music_player.stop_music()
	
	print("\n=== GAME COMPLETE! ===")
	print("Final Score: %d" % total_score)
	
	game_completed.emit(total_score)
	
	# Show end game screen
	show_end_game_screen()

func show_end_game_screen():
	"""Display the end game screen with score and return to menu button"""
	# Create a simple UI overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	# Create container
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.position = Vector2(-200, -150)
	container.custom_minimum_size = Vector2(400, 300)
	overlay.add_child(container)
	
	# Title
	var title = Label.new()
	title.text = "GAME COMPLETE!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	container.add_child(title)
	
	# Add spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 30)
	container.add_child(spacer1)
	
	# Score
	var score_label_end = Label.new()
	score_label_end.text = "Final Score: %d" % total_score
	score_label_end.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label_end.add_theme_font_size_override("font_size", 36)
	container.add_child(score_label_end)
	
	# Add spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 50)
	container.add_child(spacer2)
	
	# Return button
	var return_button = Button.new()
	return_button.text = "Return to Main Menu"
	return_button.custom_minimum_size = Vector2(300, 60)
	return_button.add_theme_font_size_override("font_size", 24)
	container.add_child(return_button)
	
	# Connect button
	return_button.pressed.connect(return_to_main_menu)

func return_to_main_menu():
	"""Return to the main menu scene"""
	# TODO: Replace with your actual main menu scene path
	get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")
