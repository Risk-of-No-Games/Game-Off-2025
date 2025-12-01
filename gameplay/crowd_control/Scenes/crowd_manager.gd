extends Node2D
class_name CrowdManager

# Crowd settings
@export var crowd_size: int = 7  # NPCs per row
@export var num_rows: int = 1  # Number of rows (set to 1 for each manager)
@export var spacing: float = 80.0  # Horizontal spacing
@export var row_spacing: float = 80.0  # Vertical spacing between rows
@export var player_index: int = -1  # Position in the row (-1 = no player)
@export var player_row: int = 0  # Which row the player is in (0-based)
@export var npc_scene: PackedScene  # Drag your NPC scene here in the inspector
@export var npc_scale: float = 1.0  # Scale multiplier for NPCs in this row
@export var player_sprite_frames: SpriteFrames = null  # Special sprite frames for player

# Section layout
@export_group("Section Layout")
@export var left_section_size: int = 5
@export var left_gap: int = 2
@export var center_section_size: int = 7
@export var right_gap: int = 2
@export var right_section_size: int = 5

# Preloaded sprite frames
var sprite_frames_cache = {}

# References
var npcs: Array = []  # 2D array of NPC nodes [row][column]
var player_npc = null  # Reference to player NPC

func _ready():
	if npc_scene == null:
		push_error("CrowdManager: NPC Scene is not assigned! Please assign it in the Inspector.")
		return
	
	# Preload sprite frames
	preload_sprite_frames()
	
	# Center horizontally, keep manual Y position
	center_on_screen()
	
	spawn_crowd()
	

func preload_sprite_frames():
	"""Preload all sprite frame combinations"""
	var colors = ["blue", "orange"]
	var directions = ["left", "center", "right"]
	
	for color in colors:
		for direction in directions:
			var key = color + "_" + direction
			var path = "res://gameplay/crowd_control/Assets/npc_%s_%s.tres" % [color, direction]
			if ResourceLoader.exists(path):
				sprite_frames_cache[key] = load(path)
			else:
				push_warning("CrowdManager: Could not find sprite frames at: " + path)

func center_on_screen():
	"""Position the CrowdManager horizontally centered, keep manual Y position"""
	var viewport_size = get_viewport_rect().size
	position.x = viewport_size.x / 2  # Only center horizontally
	# Keep the Y position that was manually set

func spawn_crowd():
	"""Generate the crowd of NPCs in multiple rows"""
	if npc_scene == null:
		push_error("CrowdManager: Cannot spawn crowd - NPC Scene is null")
		return
		
	clear_crowd()
	
	# Calculate total NPCs including gaps
	var total_npcs = left_section_size + left_gap + center_section_size + right_gap + right_section_size
	
	# Calculate starting positions to center the entire crowd
	var total_width = (total_npcs - 1) * spacing
	var start_x = -total_width / 2
	
	var total_height = (num_rows - 1) * row_spacing
	var start_y = -total_height / 2
	
	# Create rows
	for row in range(num_rows):
		var row_array = []
		
		for col in range(total_npcs):
			# Skip gap positions
			if is_gap_position(col):
				row_array.append(null)  # Placeholder for gap
				continue
			
			# Instance the NPC
			var npc = npc_scene.instantiate()
			
			if npc == null:
				push_error("CrowdManager: Failed to instantiate NPC at row " + str(row) + ", col " + str(col))
				continue
			
			# Check if this is the player position
			var is_player = (row == player_row and col == player_index)
			
			# Determine sprite direction first (outside of sprite selection logic)
			var sprite_direction = get_sprite_direction(col)
			
			# Determine sprite type
			var frames = null
			if is_player and player_sprite_frames != null:
				# Use special player sprite frames
				frames = player_sprite_frames
			else:
				# Use random crowd sprite frames
				var sprite_color = get_random_color()
				frames = load_sprite_frames(sprite_color, sprite_direction)
			
			# Assign sprite frames BEFORE initializing
			if frames:
				npc.sprite_frames = frames  # Direct assignment
			else:
				push_warning("CrowdManager: No frames loaded for position row=%d, col=%d" % [row, col])
			
			# Position the NPC
			var x_pos = start_x + (col * spacing)
			var y_pos = start_y + (row * row_spacing)
			
			# Add perspective offset for side sections
			if sprite_direction == "left":
				x_pos -= 10
			elif sprite_direction == "right":
				x_pos += 10
			
			npc.position = Vector2(x_pos, y_pos)
			
			# Apply scale
			npc.scale = Vector2(npc_scale, npc_scale)
			
			# Initialize NPC
			if npc.has_method("initialize"):
				npc.initialize(row * total_npcs + col, is_player)
			else:
				npc.npc_id = row * total_npcs + col
				npc.is_player = is_player
			
			# Add depth sorting and visual distinction for player
			npc.z_index = row
			if is_player:
				npc.z_index = 100  # Player always on top
				npc.scale *= 1.2  # Make player slightly larger
				player_npc = npc
			
			# Add to scene
			add_child(npc)
			row_array.append(npc)
		
		npcs.append(row_array)

func get_center_column_index() -> int:
	"""Get the column index of the center of the center section"""
	return left_section_size + left_gap + (center_section_size / 2)

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

func is_gap_position(col: int) -> bool:
	"""Check if this column position is a gap"""
	var gap1_start = left_section_size
	var gap1_end = gap1_start + left_gap
	var gap2_start = gap1_end + center_section_size
	var gap2_end = gap2_start + right_gap
	
	return (col >= gap1_start and col < gap1_end) or \
		   (col >= gap2_start and col < gap2_end)

func get_sprite_direction(col: int) -> String:
	"""Determine which sprite direction based on column position"""
	var gap1_end = left_section_size + left_gap
	var center_end = gap1_end + center_section_size
	
	if col < left_section_size:
		return "left"
	elif col >= gap1_end and col < center_end:
		return "center"
	else:
		return "right"

func get_random_color() -> String:
	"""Randomly choose blue or orange"""
	return "blue" if randf() > 0.5 else "orange"

func load_sprite_frames(color: String, direction: String):
	"""Load sprite frames from cache"""
	var key = color + "_" + direction
	if sprite_frames_cache.has(key):
		return sprite_frames_cache[key]
	else:
		push_warning("CrowdManager: Sprite frames not found for: " + key)
		return null

func trigger_wave(direction: int = 1, speed: float = 0.3):
	"""Trigger the wave animation across the crowd
	direction: 1 for left-to-right, -1 for right-to-left
	speed: delay between each person standing (in seconds)
	
	Wave moves through all rows simultaneously
	Player NPC will NOT wave automatically - only when spacebar is pressed
	"""
	var total_npcs = left_section_size + left_gap + center_section_size + right_gap + right_section_size
	var start_col = 0 if direction == 1 else total_npcs - 1
	var end_col = total_npcs if direction == 1 else -1
	var step = 1 if direction == 1 else -1
	
	var delay = 0.0
	for col in range(start_col, end_col, step):
		var wave_delay = delay
		get_tree().create_timer(wave_delay).timeout.connect(
			func():
				# Trigger wave for this column across all rows
				for row in range(num_rows):
					if row < npcs.size() and col >= 0 and col < npcs[row].size():
						var npc = npcs[row][col]
						# Only trigger wave if NPC exists (not a gap) AND is not the player
						if npc != null and npc.has_method("do_wave") and npc != player_npc:
							npc.do_wave()
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
					var npc = npcs[row_index][col]
					# Only trigger wave if NPC is not the player
					if npc != null and npc != player_npc:
						npc.do_wave()
		)
		delay += speed

func trigger_player_wave():
	"""Manually trigger the player's wave animation"""
	if player_npc != null and player_npc.has_method("do_wave"):
		player_npc.do_wave()
