extends Area2D

@export var claw_damage := 40
var player : CharacterBody2D = null

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	monitoring = false  # Only active when clawing

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(claw_damage, "claw")    
