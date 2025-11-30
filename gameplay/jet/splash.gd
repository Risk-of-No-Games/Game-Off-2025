extends Area2D

# Export variables to configure in the editor
@export var circle_radius: float = 32.0
@export var rectangle_size: Vector2 = Vector2(64, 64)

# Reference to collision shape node
@onready var collision_shape = $CollisionShape2D

# Track current shape type
var is_circle: bool = true

func _ready():
	# Start with a circle shape
	var circle = CircleShape2D.new()
	circle.radius = circle_radius
	collision_shape.shape = circle
	
	# Connect the area_entered signal
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _on_area_entered(area):
	# Change shape when another area collides
	toggle_shape()
	print("Hit by area: ", area.name)

func _on_body_entered(body):
	# Change shape when a body collides
	toggle_shape()
	print("Hit by body: ", body.name)

func toggle_shape():
	if is_circle:
		# Change to rectangle
		var rect = RectangleShape2D.new()
		rect.size = rectangle_size
		collision_shape.shape = rect
		is_circle = false
		print("Changed to rectangle")
	else:
		# Change back to circle
		var circle = CircleShape2D.new()
		circle.radius = circle_radius
		collision_shape.shape = circle
		is_circle = true
		print("Changed to circle")
