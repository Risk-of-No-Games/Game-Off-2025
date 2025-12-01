# background_scaler.gd
extends Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready():
	# Make sure we have a texture to work with
	if texture:
		# Connect to the viewport's "size_changed" signal to update the scale
		# whenever the window or viewport size changes.
		get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))
		
		# Initial scale update
		_on_viewport_size_changed()
	else:
		print("Warning: Sprite2D has no texture assigned. Cannot scale background.")

# Function to calculate and apply the scaling
func _on_viewport_size_changed():
	# 1. Get the current viewport size
	var viewport_size = get_viewport_rect().size
	
	# 2. Get the original size of the sprite's texture
	var texture_size = texture.get_size()

	# 3. Calculate the necessary scaling factors for both width and height
	var scale_x = viewport_size.x / texture_size.x
	var scale_y = viewport_size.y / texture_size.y
	
	# 4. Use the LARGER scale factor (max()) to ensure the background covers the entire viewport.
	# This will result in part of the image being clipped, but it guarantees full coverage.
	var scale_factor = max(scale_x, scale_y)
	
	# 5. Apply the calculated scale to the sprite
	self.scale = Vector2(scale_factor, scale_factor)
	
	# 6. Center the sprite in the viewport
	# The Sprite2D's position should be half the viewport size to center it.
	self.global_position = viewport_size / 2.0
