extends Node2D
class_name CrowdManager

# Crowd settings
@export var crowd_size: int = 7  # NPCs per row
@export var num_rows: int = 3  # Number of rows
@export var spacing: float = 80.0  # Horizontal spacing
@export var row_spacing: float = 80.0  # Vertical spacing between rows
@export var player_index: int = 3  # Position in the row
@export var player_row: int = 1  # Which row the player is in (0-based)
@export var wave_speed: float = 0.3  # Delay between each person in the wave (seconds)
@export var npc_scene: PackedScene  # Drag your NPC scene here in the inspector

# References
var npcs: Array = []  # 2D array of NPC nodes [row][column]
var player_npc = null  # Reference to player NPC

func _ready():
	if npc_scene == null:
		push_error("CrowdManager: NPC Scene is not assigned! Please assign it in the Inspector.")
		return
	
	# Center the crowd manager on screen
	center_on_screen()
	
	spawn_crowd()

func _input(event):
	"""Handle input for testing/triggering the wave"""
	# Press Space to trigger wave
	if event.is_action_pressed("ui_accept"):  # Space bar / Enter
		trigger_wave(1, wave_speed)  # Left to right
	
	# Press Left Arrow to trigger reverse wave
	if event.is_action_pressed("ui_left"):
		trigger_wave(-1, wave_speed)  # Right to left

func center_on_screen():
	"""Position the CrowdManager at the center of the viewport"""
	var viewport_size = get_viewport_rect().size
	position = viewport_size / 2

func spawn_crowd():
	"""Generate the crowd of NPCs in multiple rows"""
	if npc_scene == null:
		push_error("CrowdManager: Cannot spawn crowd - NPC Scene is null")
		return
		
	clear_crowd()
	
	# Calculate starting positions to center the entire crowd
	var total_width = (crowd_size - 1) * spacing
	var start_x = -total_width / 2
	
	var total_height = (num_rows - 1) * row_spacing
	var start_y = -total_height / 2
	
	# Create rows
	for row in range(num_rows):
		var row_array = []
		
		for col in range(crowd_size):
			# Instance the NPC
			var npc = npc_scene.instantiate()
			
			if npc == null:
				push_error("CrowdManager: Failed to instantiate NPC at row " + str(row) + ", col " + str(col))
				continue
			
			# Position the NPC
			var x_pos = start_x + (col * spacing)
			var y_pos = start_y + (row * row_spacing)
			npc.position = Vector2(x_pos, y_pos)
			
			# Check if this is the player
			var is_player = (row == player_row and col == player_index)
			npc.initialize(row * crowd_size + col, is_player)
			
			# Add depth sorting - back rows appear behind front rows
			npc.z_index = row
			if is_player:
				npc.z_index = num_rows  # Player always on top
			
			# Add to scene
			add_child(npc)
			row_array.append(npc)
			
			# Store player reference
			if is_player:
				player_npc = npc
		
		npcs.append(row_array)

func clear_crowd():
	"""Remove all existing NPCs"""
	for row in npcs:
		for npc in row:
			npc.queue_free()
	npcs.clear()
	player_npc = null

func get_npc(row: int, col: int):
	"""Get NPC at specific row and column"""
	if row >= 0 and row < npcs.size():
		if col >= 0 and col < npcs[row].size():
			return npcs[row][col]
	return null

func get_player():
	"""Get the player NPC"""
	return player_npc

func trigger_wave(direction: int = 1, speed: float = 0.3):
	"""Trigger the wave animation across the crowd
	direction: 1 for left-to-right, -1 for right-to-left
	speed: delay between each person standing (in seconds)
	
	Wave moves through all rows simultaneously
	"""
	var start_col = 0 if direction == 1 else crowd_size - 1
	var end_col = crowd_size if direction == 1 else -1
	var step = 1 if direction == 1 else -1
	
	var delay = 0.0
	for col in range(start_col, end_col, step):
		var wave_delay = delay
		get_tree().create_timer(wave_delay).timeout.connect(
			func():
				# Trigger wave for this column across all rows
				for row in range(num_rows):
					if row < npcs.size() and col >= 0 and col < npcs[row].size():
						npcs[row][col].do_wave()
		)
		delay += speed

func trigger_wave_by_row(row_index: int, direction: int = 1, speed: float = 0.3):
	"""Trigger the wave animation for a specific row only"""
	if row_index < 0 or row_index >= npcs.size():
		return
	
	var start_col = 0 if direction == 1 else crowd_size - 1
	var end_col = crowd_size if direction == 1 else -1
	var step = 1 if direction == 1 else -1
	
	var delay = 0.0
	for col in range(start_col, end_col, step):
		var wave_delay = delay
		get_tree().create_timer(wave_delay).timeout.connect(
			func():
				if col >= 0 and col < npcs[row_index].size():
					npcs[row_index][col].do_wave()
		)
		delay += speed
