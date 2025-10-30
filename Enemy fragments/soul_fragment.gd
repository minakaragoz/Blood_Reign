extends Area2D

@export var soul_value : int = 1  
var collected := false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if collected:
		return  
	if body.is_in_group("player"):  
		collected = true
		if body.has_method("add_soul"):
			body.add_soul(soul_value)  
		queue_free()
