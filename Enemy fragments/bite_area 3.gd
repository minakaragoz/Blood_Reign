extends Area2D
@export var bite_damage := 20
var player : CharacterBody2D = null

func _ready():
	self.body_entered.connect(self._on_body_entered)
	monitoring = false  # Only active when biting

func _on_body_entered(body):
	print("BiteArea overlapped:", body.name)
	if body.is_in_group("enemies"):
		print("Enemy hit:", body.name)
		if body.has_method("take_damage"):
			body.take_damage(bite_damage)
		if player:
				# Increase player blood equal to damage
				player.blood = min(player.blood + bite_damage, player.max_blood)
				if player.blood_meter:
					player.blood_meter.value = player.blood
					
