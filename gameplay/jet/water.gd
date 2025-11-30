extends Node2D

# Water simulation parameters
@export var water_length: float = 1280.0
@export var water_height: float = 400.0
@export var spring_count: int = 50
@export var dampening: float = 0.025
@export var tension: float = 0.025
@export var spread: float = 0.25
@export var wave_height: float = 10.0

# Buoyancy parameters
@export var buoyancy_force: float = 500.0
@export var water_drag: float = 2.0
@export var angular_drag: float = 1.5

# Visual properties
@export var water_color: Color = Color(0.2, 0.5, 0.8, 0.6)
@export var water_border_color: Color = Color(0.1, 0.3, 0.6, 0.8)

var springs: Array = []
var velocities: Array = []
var spring_spacing: float
var floating_bodies: Array = []

func _ready():
	spring_spacing = water_length / spring_count
	
	# Initialize springs and velocities
	for i in range(spring_count + 1):
		springs.append(0.0)
		velocities.append(0.0)
	
	# Start with some initial waves
	create_wave(spring_count / 2, wave_height * 2)
	
	# Find all RigidBody2D children or in the scene
	scan_for_floating_bodies()

func scan_for_floating_bodies():
	# Scan for bodies tagged with a specific group
	floating_bodies = get_tree().get_nodes_in_group("floatable")

func _process(delta):
	# Update springs
	for i in range(springs.size()):
		var x = springs[i]
		var acceleration = -tension * x - dampening * velocities[i]
		velocities[i] += acceleration
		springs[i] += velocities[i]
	
	# Spread waves between springs
	var left_deltas: Array = []
	var right_deltas: Array = []
	
	for i in range(springs.size()):
		left_deltas.append(0.0)
		right_deltas.append(0.0)
	
	for i in range(springs.size()):
		if i > 0:
			left_deltas[i] = spread * (springs[i] - springs[i - 1])
			velocities[i - 1] += left_deltas[i]
		
		if i < springs.size() - 1:
			right_deltas[i] = spread * (springs[i] - springs[i + 1])
			velocities[i + 1] += right_deltas[i]
	
	for i in range(springs.size()):
		if i > 0:
			springs[i - 1] += left_deltas[i]
		if i < springs.size() - 1:
			springs[i + 1] += right_deltas[i]
	
	queue_redraw()

func _physics_process(delta):
	# Update floating bodies
	for body in floating_bodies:
		if body and is_instance_valid(body) and body is RigidBody2D:
			apply_buoyancy(body, delta)

func apply_buoyancy(body: RigidBody2D, delta: float):
	var body_pos = to_local(body.global_position)
	var water_surface_y = get_water_height_at(body_pos.x)
	
	# Check if body is in water
	if body_pos.y > water_surface_y:
		# Calculate submersion depth
		var submersion = body_pos.y - water_surface_y
		
		# Apply buoyancy force (upward)
		var buoyancy = Vector2(0, -buoyancy_force * submersion * delta)
		body.apply_central_force(buoyancy)
		
		# Apply water drag
		body.linear_velocity *= (1.0 - water_drag * delta)
		body.angular_velocity *= (1.0 - angular_drag * delta)
		
		# Create splash based on velocity when entering water
		var velocity_impact = body.linear_velocity.y
		if velocity_impact > 50:  # Threshold for splash
			splash(body_pos.x, -velocity_impact * 0.1)

func get_water_height_at(x_pos: float) -> float:
	# Get interpolated water height at specific x position
	if x_pos < 0 or x_pos > water_length:
		return 0.0
	
	var index = x_pos / spring_spacing
	var i1 = int(floor(index))
	var i2 = int(ceil(index))
	
	if i1 >= springs.size():
		i1 = springs.size() - 1
	if i2 >= springs.size():
		i2 = springs.size() - 1
	
	# Lerp between two springs
	var t = index - i1
	return lerp(springs[i1], springs[i2], t)

func _draw():
	var water_polygon: PackedVector2Array = []
	var water_line: PackedVector2Array = []
	
	# Build the water surface line
	for i in range(springs.size()):
		var x = i * spring_spacing
		var y = springs[i]
		water_line.append(Vector2(x, y))
		water_polygon.append(Vector2(x, y))
	
	# Complete the polygon for the water body
	water_polygon.append(Vector2(water_length, water_height))
	water_polygon.append(Vector2(0, water_height))
	
	# Draw the water body
	draw_colored_polygon(water_polygon, water_color)
	
	# Draw the water surface line
	if water_line.size() > 1:
		draw_polyline(water_line, water_border_color, 2.0)

# Create a wave at a specific spring index
func create_wave(index: int, speed: float):
	if index >= 0 and index < velocities.size():
		velocities[index] = speed

# Splash at world position
func splash(x_position: float, velocity: float):
	var index = int(x_position / spring_spacing)
	if index >= 0 and index < springs.size():
		create_wave(index, velocity)

# Handle input for testing
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var local_pos = to_local(event.position)
		if local_pos.x >= 0 and local_pos.x <= water_length:
			splash(local_pos.x, -wave_height * 3)

# Call this to register a body for buoyancy
func register_floating_body(body: RigidBody2D):
	if body not in floating_bodies:
		floating_bodies.append(body)

# Call this to unregister a body
func unregister_floating_body(body: RigidBody2D):
	if body in floating_bodies:
		floating_bodies.erase(body)
