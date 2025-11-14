extends AnimatedSprite2D
class_name NPC

# NPC properties
var npc_id: int = 0
var is_player: bool = false
var current_state: String = "idle"

func _ready():
	# Play idle animation by default
	play("idle")
	
	# Visual indicator for player
	if is_player:
		modulate = Color(1.2, 1.2, 0.8)  # Slight yellow tint
		z_index = 1  # Draw on top
	
	# Connect to animation finished signal for automatic transitions
	animation_finished.connect(_on_animation_finished)

func initialize(id: int, player: bool = false):
	"""Initialize the NPC with ID and player status"""
	npc_id = id
	is_player = player

func do_wave():
	"""Perform the wave - complete cycle (sit → stand → sit)"""
	current_state = "wave"
	play("wave")
	# Make sure wave animation doesn't loop
	sprite_frames.set_animation_loop("wave", false)

func _on_animation_finished():
	"""Auto-transition back to idle after wave completes"""
	if current_state == "wave":
		current_state = "idle"
		play("idle")
