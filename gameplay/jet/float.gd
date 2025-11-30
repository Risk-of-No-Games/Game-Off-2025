extends RigidBody2D

@export var water_node_path: NodePath
@export var buoyancy_force: float = 300.0
@export var water_drag: float = 0.92
@export var air_drag: float = 0.99
@export var splash_on_enter: bool = true
@export var vertical_damping: float = 0.85  # Dampens vertical movement
@export var stability_threshold: float = 30.0  # Speed below which stabilization kicks in

var water_node: Node2D
var was_in_water: bool = false

func _ready():
	if water_node_path:
		water_node = get_node(water_node_path)
	
	# Make sure gravity is enabled
	gravity_scale = 1.0
	# Increase linear damp for more stability
	linear_damp = 1.0

func _physics_process(delta):
	if water_node and water_node.has_method("is_body_in_water"):
		var in_water = water_node.is_body_in_water(self)
		
		# Just entered water - create splash
		if in_water and not was_in_water:
			if splash_on_enter and water_node.has_method("body_entered_water"):
				water_node.body_entered_water(self)
		
		# Apply water physics
		if in_water:
			# Strong buoyancy - counteract gravity and push upward
			var gravity_force = mass * 980.0 * gravity_scale
			apply_central_force(Vector2(0, -gravity_force - buoyancy_force))
			
			# Apply heavy water drag
			linear_velocity *= water_drag
			angular_velocity *= water_drag
			
			# Extra vertical damping to stop bouncing
			if abs(linear_velocity.y) < stability_threshold:
				linear_velocity.y *= vertical_damping
		else:
			# In air - apply air drag
			linear_velocity *= air_drag
			angular_velocity *= air_drag
		
		was_in_water = in_water
