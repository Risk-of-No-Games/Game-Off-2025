extends Sprite2D

# Bullet scene to instantiate
@export var bullet_scene: PackedScene

# Shooting properties
@export var shoot_interval: float = 0.5  # Time between shots in seconds
@export var bullet_speed: float = 400.0
@export var shoot_direction: Vector2 = Vector2.RIGHT

var shoot_timer: float = 0.0

func _ready():
	# Initialize timer so first shot happens immediately
	shoot_timer = shoot_interval

func _process(delta):
	# Update timer
	shoot_timer += delta
	
	# Check if it's time to shoot
	if shoot_timer >= shoot_interval:
		shoot()
		shoot_timer = 0.0

func shoot():
	if bullet_scene == null:
		push_warning("No bullet scene assigned!")
		return
	
	# Create bullet instance
	var bullet = bullet_scene.instantiate()
	
	# Set bullet position to sprite's position
	bullet.global_position = global_position
	
	# Set bullet velocity (assuming bullet has a script with 'velocity' variable)
	if bullet.has_method("set_velocity"):
		bullet.set_velocity(shoot_direction.normalized() * bullet_speed)
	elif "velocity" in bullet:
		bullet.velocity = shoot_direction.normalized() * bullet_speed
	
	# Add bullet to scene tree (same parent as this sprite)
	get_parent().add_child(bullet)
