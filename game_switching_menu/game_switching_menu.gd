extends Control

@onready var scene_list_container = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SceneList
@onready var close_button = $Panel/MarginContainer/VBoxContainer/CloseButton
@onready var title_label = $Panel/MarginContainer/VBoxContainer/Label
@onready var panel = $Panel

var scenes = []

func _ready():
	# Center the panel using anchors
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(600, 500)
	
	# Set the title
	title_label.text = "Scene Selector"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Configure the scroll container
	var scroll_container = $Panel/MarginContainer/VBoxContainer/ScrollContainer
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Configure the scene list container
	scene_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_button.text = "Close"
	close_button.pressed.connect(_on_close_pressed)
	scan_scenes()
	populate_scene_list()

func scan_scenes():
	scenes.clear()
	_scan_directory("res://gameplay/")

func _scan_directory(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			var full_path = path + "/" + file_name if path != "res://" else path + file_name
			
			if dir.current_is_dir():
				# Skip .godot and .import directories
				if file_name != ".godot" and file_name != ".import" and file_name != ".":
					_scan_directory(full_path)
			else:
				# Check if it's a scene file
				if file_name.ends_with(".tscn"):
					scenes.append(full_path)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()

func populate_scene_list():
	# Clear existing buttons
	for child in scene_list_container.get_children():
		child.queue_free()
	
	# Sort scenes alphabetically
	scenes.sort()
	
	# Create a button for each scene
	for scene_path in scenes:
		var button = Button.new()
		# Extract just the filename for cleaner display
		var scene_name = scene_path.get_file()
		button.text = scene_name + "\n" + scene_path
		button.custom_minimum_size = Vector2(550, 50)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_scene_selected.bind(scene_path))
		scene_list_container.add_child(button)
	
	print("Added ", scenes.size(), " scene buttons")

func _on_scene_selected(scene_path: String):
	print("Loading scene: ", scene_path)
	get_tree().change_scene_to_file(scene_path)

func _on_close_pressed():
	get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")

func _input(event):
	# Press Escape to close
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()
