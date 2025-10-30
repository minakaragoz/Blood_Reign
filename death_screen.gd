extends Control

func _ready():
	$Button.pressed.connect(_on_restart_pressed)

func _on_restart_pressed():
	# Restart the game (go back to start screen or reload level)
	get_tree().change_scene_to_file("res://StartScreen.tscn")
