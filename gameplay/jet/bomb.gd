extends RigidBody2D

# Horizontal movement speed in pixels per second
@export var horizontal_speed: float = 250.0

# Gravity strength (pixels per second squared)
@export var gravity: float = 500.0

# Vertical velocity
var velocity_y: float = 0.0

# Is the sprite falling?
var is_falling: bool = false

# Optional: Ground level (y position where sprite stops falling)
@export var ground_level: float = 500.0

# Optional: Reset to top when hitting ground
@export var reset_on_ground: bool = false
@export var reset_height: float = 50.0

func _process(delta: float) -> void:
	# Always move horizontally
	position.x += horizontal_speed * delta
	
	# Check for spacebar press to start falling
	if Input.is_action_just_pressed("ui_accept"):  # Spacebar is mapped to ui_accept
		is_falling = true
	
	# Apply gravity and falling
	if is_falling:
		velocity_y += gravity * delta
		position.y += velocity_y * delta
		
		# Optional: Stop at ground level
		if position.y >= ground_level:
			position.y = ground_level
			velocity_y = 0.0
			
			if reset_on_ground:
				position.y = reset_height
				is_falling = false
