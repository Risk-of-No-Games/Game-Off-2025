extends CanvasLayer
class_name WaveGameUI

# References
@export var game_controller: CrowdControlGame

# UI Nodes (create these as children in your scene)
@onready var score_label: Label = $ScoreLabel
@onready var combo_label: Label = $ComboLabel
@onready var feedback_label: Label = $FeedbackLabel
@onready var instruction_label: Label = $InstructionLabel

func _ready():
	if game_controller:
		game_controller.wave_started.connect(_on_wave_started)
		game_controller.player_result.connect(_on_player_action)
		game_controller.game_over.connect(_on_game_over)
	
	update_ui()

func _process(_delta):
	if game_controller and game_controller.game_active:
		update_ui()

func update_ui():
	"""Update all UI elements"""
	if game_controller == null:
		return
	
	# Update score and combo
	if score_label:
		score_label.text = "Score: " + str(game_controller.score)
	
	if combo_label:
		combo_label.text = "Combo: x" + str(game_controller.combo)
		# Change color based on combo
		if game_controller.combo >= 10:
			combo_label.modulate = Color.GOLD
		elif game_controller.combo >= 5:
			combo_label.modulate = Color.ORANGE
		else:
			combo_label.modulate = Color.WHITE
	
	# Update instruction
	if instruction_label:
		if not game_controller.game_active:
			instruction_label.text = "Press SPACE to Start!"
		else:
			instruction_label.text = "Press SPACE when the wave reaches you!"

func _on_wave_started(direction: int):
	"""Called when a new wave starts"""
	if feedback_label:
		var dir_text = "→" if direction == 1 else "←"
		feedback_label.text = "Wave coming " + dir_text
		feedback_label.modulate = Color.CYAN

func _on_player_action(result: String):
	"""Called when player presses the button"""
	if feedback_label == null:
		return
	
	match result:
		"perfect":
			feedback_label.text = "PERFECT!"
			feedback_label.modulate = Color.GOLD
		"good":
			feedback_label.text = "GOOD!"
			feedback_label.modulate = Color.GREEN
		"ok":
			feedback_label.text = "OK..."
			feedback_label.modulate = Color.YELLOW
		"miss":
			feedback_label.text = "MISS!"
			feedback_label.modulate = Color.RED
	
	# Fade out feedback after a moment
	var tween = create_tween()
	tween.tween_property(feedback_label, "modulate:a", 0.0, 0.5).set_delay(1.0)
	tween.tween_callback(func(): feedback_label.modulate.a = 1.0)

func _on_game_over(final_score: int, max_combo: int):
	"""Called when game ends"""
	if feedback_label:
		feedback_label.text = "GAME OVER!\nScore: " + str(final_score) + "\nMax Combo: " + str(max_combo)
		feedback_label.modulate = Color.WHITE
