extends Area2D

var velocity: Vector2 = Vector2.ZERO

func _ready():
	# Connect signals for collision detection
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Optional: destroy bullet after 5 seconds
	await get_tree().create_timer(5.0).timeout
	queue_free()

func set_velocity(vel: Vector2):
	velocity = vel

func _process(delta):
	position += velocity * delta

func _on_area_entered(area):
	# Check if bullet hit water/wave
	if area.is_in_group("water") or area.name.contains("Water") or area.name.contains("Wave"):
		queue_free()  # Destroy bullet

func _on_body_entered(body):
	# Check if bullet hit water body
	if body.is_in_group("water") or body.name.contains("Water") or body.name.contains("Wave"):
		queue_free()  # Destroy bullet
		return
	
	# Optional: add collision behavior for other objects
	# Example: if body.has_method("take_damage"):
	#     body.take_damage(10)
	queue_free()  # Destroy bullet on impact
