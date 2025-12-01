# This script is intended to be attached to a TextureRect node.
# It ensures the texture covers the entire viewport and allows
# setting the texture programmatically.

extends TextureRect

# Exported variable to easily select the texture file in the Inspector
@export var texture_path: String = "res://gameplay/crowd_control/Assets/main_menu.png"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 1. Set Anchors to Full Rect (Best practice is to do this in the editor,
	#    but we ensure it here programmatically for robustness).
	# This stretches the node to cover its parent, which should be the viewport
	# or another full-screen container (like the root Node2D/Control).
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	
	# 2. Load the texture from the path if it exists
	if !texture_path.is_empty() and ResourceLoader.exists(texture_path):
		self.texture = load(texture_path)
	else:
		# Fallback if the path is invalid or empty
		print("Warning: Texture path is empty or resource does not exist: ", texture_path)

	# 3. Set the stretch mode to cover the viewport without distortion
	# We must prefix the constants with the class name (TextureRect) to resolve the error.
	# Use one of these based on your desired behavior:
	# - TextureRect.STRETCH_KEEP_ASPECT_COVER: Fills the entire rect, cropping edges if necessary. (Commonly used for backgrounds)
	# - TextureRect.STRETCH_KEEP_ASPECT: Scales down to fit without cropping, leaving empty bars.
	# - TextureRect.STRETCH_SCALE: Stretches the image to fit, potentially distorting the aspect ratio.
	self.stretch_mode = 4
	
	# Ensures the TextureRect is fully visible (useful if it's part of a complex hierarchy)
	self.mouse_filter = MOUSE_FILTER_IGNORE
