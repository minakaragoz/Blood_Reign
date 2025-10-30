extends Control

func _ready():
	$Button.pressed.connect(_on_start_pressed)

func _on_start_pressed():
	# Load your main gameplay scene
	get_tree().change_scene_to_file("res://Levels/Level1(Trial).tscn")
