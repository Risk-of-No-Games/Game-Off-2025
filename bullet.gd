extends Area2D

var velocity: Vector2 = Vector2.ZERO

func _ready():
	# Optional: destroy bullet after 5 seconds
	await get_tree().create_timer(5.0).timeout
	queue_free()

func set_velocity(vel: Vector2):
	velocity = vel

func _process(delta):
	position += velocity * delta

func _on_body_entered(body):
	# Optional: add collision behavior here
	# Example: if body.has_method("take_damage"):
	#     body.take_damage(10)
	queue_free()  # Destroy bullet on impact
