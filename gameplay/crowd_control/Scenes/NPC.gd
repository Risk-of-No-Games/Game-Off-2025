extends AnimatedSprite2D
class_name NPC

# NPC properties
var npc_id: int = 0
var is_player: bool = false
var current_state: String = "idle"

# Bobbing animation
var bob_offset: float = 0.0
var bob_speed: float = 0.0
var bob_amount: float = 0.0
var base_y_position: float = 0.0

# Player animation speed multiplier
@export var player_wave_speed: float = 2.0  # Make player wave 2x faster

func _ready():
	# Store base position
	base_y_position = position.y
	
	# Randomize bobbing for crowd members (not player)
	if not is_player:
		bob_speed = randf_range(1.5, 3.0)
		bob_amount = randf_range(1.0, 2.0)
		# Random starting offset so they don't all bob in sync
		bob_offset = randf_range(0.0, TAU)
	
	# Only play animation if sprite_frames is set
	if sprite_frames != null:
		play("idle")
	
	# Connect to animation finished signal for automatic transitions
	animation_finished.connect(_on_animation_finished)

func _process(delta):
	# Only bob during idle state and if not player
	if current_state == "idle" and not is_player:
		bob_offset += delta * bob_speed
		position.y = base_y_position + sin(bob_offset) * bob_amount

func initialize(id: int, player: bool = false):
	"""Initialize the NPC with ID and player status"""
	npc_id = id
	is_player = player

func assign_sprite_frames(frames: SpriteFrames):
	"""Assign the sprite frames for this NPC"""
	sprite_frames = frames
	# Start playing idle animation after assignment
	if sprite_frames != null:
		play("idle")

func do_wave():
	"""Perform the wave - complete cycle (sit → stand → sit)"""
	# Don't interrupt an already playing wave
	if current_state == "wave":
		return
	
	# Reset to base position when starting wave
	position.y = base_y_position
	
	current_state = "wave"
	
	# Make sure wave animation doesn't loop
	if sprite_frames:
		sprite_frames.set_animation_loop("wave", false)
	
	# Set speed multiplier for player
	if is_player:
		speed_scale = player_wave_speed
	else:
		speed_scale = 1.0
	
	play("wave")

func _on_animation_finished():
	"""Auto-transition back to idle after wave completes"""
	if current_state == "wave":
		current_state = "idle"
		speed_scale = 1.0  # Reset speed to normal
		play("idle")
		# Bobbing resumes automatically in _process
