extends Control

@onready var fade_rect = $FadeRect
@onready var start_label = $StartLabel

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Start position
	fade_rect.modulate.a = 1.0

	# fade-in effect
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(fade_rect, "modulate:a", 0.0, 1.5)

	# label blink effect
	_blink_text()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		_start_fade_out()

func _start_fade_out():
	var tween = get_tree().create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 1.0)
	tween.tween_callback(Callable(self, "_go_to_start"))

func _go_to_start():
	get_tree().change_scene_to_file("res://StartScreen.tscn")

func _blink_text():
	var tween = get_tree().create_tween().set_loops()
	tween.tween_property(start_label, "modulate:a", 0.0, 0.8)
	tween.tween_property(start_label, "modulate:a", 1.0, 0.8)
