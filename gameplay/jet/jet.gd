extends Sprite2D

# Movement speed in pixels per second
@export var speed: float = 250.0

# Optional: Screen width limit (set to 0 to disable)
@export var screen_width: float = 1152.0

# Optional: Reset to left when reaching right edge
@export var loop: bool = true

func _process(delta: float) -> void:
	# Move the sprite to the right
	position.x += speed * delta
	
	# Optional: Loop back to the left side when reaching the right edge
	if loop and screen_width > 0 and position.x > screen_width:
		position.x = 0
