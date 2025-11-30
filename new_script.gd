extends RigidBody2D

@export var water_node_path: NodePath
@export var buoyancy_force: float = 200.0
@export var water_drag: float = 0.98
@export var air_drag: float = 0.99
@export var splash_on_enter: bool = true
@export var bob_amplitude: float = 1.0
@export var bob_speed: float = 0.5

var water_node: Node2D
var was_in_water: bool = false
var time_in_water: float = 0.0

func _ready():
	if water_node_path:
		water_node = get_node(water_node_path)
	
	# Make sure gravity is enabled
	gravity_scale = 1.0

func _physics_process(delta):
	if water_node and water_node.has_method("is_body_in_water"):
		var in_water = water_node.is_body_in_water(self)
		
		# Just entered water - create splash
		if in_water and not was_in_water:
			if splash_on_enter and water_node.has_method("body_entered_water"):
				water_node.body_entered_water(self)
		
		# Apply water physics
		if in_water:
			time_in_water += delta
			
			# Apply buoyancy (upward force)
			apply_central_force(Vector2(0, -buoyancy_force))
			
			# Apply water drag
			linear_velocity *= water_drag
			angular_velocity *= water_drag
			
			# Add gentle bobbing motion when floating
			if abs(linear_velocity.y) < 50:
				var bob = sin(time_in_water * bob_speed) * bob_amplitude
				apply_central_force(Vector2(0, bob))
		else:
			# In air - apply air drag
			linear_velocity *= air_drag
			angular_velocity *= air_drag
			time_in_water = 0.0
		
		was_in_water = in_water
