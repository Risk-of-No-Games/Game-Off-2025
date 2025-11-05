extends VFlowContainer

@export var settings_scene:PackedScene
@export var game_switching_menu:PackedScene

func _ready() -> void:
	get_children()[0].grab_focus()
	
	if !OS.has_feature("pc"):
		$Quit.hide()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_packed(settings_scene)
	

func _on_start_pressed() -> void:
	get_tree().change_scene_to_packed(game_switching_menu)
