extends CharacterBody2D

# Water physics settings
@export var buoyancy_force: float = 400.0  # Upward force when in water
@export var water_drag: float = 0.85  # Drag coefficient (0-1, lower = more drag)
@export var gravity: float = 980.0  # Gravity when not in water
@export var water_level: float = 300.0  # Y position of water surface

# Movement settings
@export var swim_speed: float = 200.0
@export var jump_force: float = -300.0

# State tracking
var is_in_water: bool = false
var submerged_amount: float = 0.0  # 0 = not in water, 1 = fully submerged

func _ready():
	# You can adjust water_level based on your scene
	pass

func _physics_process(delta):
	# Check if character is in water
	check_water_collision()
	
	# Apply appropriate physics
	if is_in_water:
		apply_water_physics(delta)
	else:
		apply_air_physics(delta)
	
	# Handle horizontal movement
	handle_movement()
	
	# Move the character
	move_and_slide()

func check_water_collision():
	# Simple water detection based on Y position
	# You can replace this with Area2D detection for more complex water shapes
	var char_bottom = global_position.y
	var char_top = global_position.y - 32  # Adjust based on your sprite size
	
	if char_bottom > water_level:
		is_in_water = true
		# Calculate how submerged the character is
		var water_depth = char_bottom - water_level
		var char_height = 32  # Adjust to your character height
		submerged_amount = clamp(water_depth / char_height, 0.0, 1.0)
	else:
		is_in_water = false
		submerged_amount = 0.0

func apply_water_physics(delta):
	# Apply buoyancy (upward force)
	var buoyancy = -buoyancy_force * submerged_amount
	velocity.y += buoyancy * delta
	
	# Apply water drag to simulate resistance
	velocity.x *= water_drag
	velocity.y *= water_drag
	
	# Light gravity still applies in water
	velocity.y += gravity * 0.1 * delta
	
	# Jump/swim upward
	if Input.is_action_just_pressed("ui_up"):
		velocity.y = jump_force * 0.7  # Weaker jump in water

func apply_air_physics(delta):
	# Normal gravity when not in water
	velocity.y += gravity * delta
	
	# Jump
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_force

func handle_movement():
	# Horizontal movement (works both in and out of water)
	var input_dir = Input.get_axis("ui_left", "ui_right")
	
	if is_in_water:
		# Swimming movement
		velocity.x = input_dir * swim_speed
		
		# Vertical swimming
		var vertical_input = Input.get_axis("ui_up", "ui_down")
		velocity.y += vertical_input * swim_speed * 0.5
	else:
		# Normal ground movement
		if input_dir != 0:
			velocity.x = input_dir * swim_speed * 1.5
		else:
			velocity.x = move_toward(velocity.x, 0, swim_speed * 0.1)
