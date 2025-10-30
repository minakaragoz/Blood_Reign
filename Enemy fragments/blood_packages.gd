extends Area2D

@export var heal_amount := 20
var collected := false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if collected:
		return  
	if body.is_in_group("player"):
		collected = true
		# players blood meter raise
		if "blood" in body:
			body.blood = min(body.blood + heal_amount, body.max_blood)
			if body.blood_meter:
				body.blood_meter.value = body.blood
		queue_free()
