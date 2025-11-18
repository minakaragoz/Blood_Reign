extends Area2D

@onready var hitbox: CollisionShape2D = $CollisionShape2D
@export var damage: int = 10


func _ready():
	hitbox.disabled = false
	
	self.body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node) -> void:
	# Only trigger if not already active and not on cooldown

		print("entered")


		# Save original speed and apply damage/stop movement
		if "speed" in body and "blood" in body and "is_dashing" in body and body.is_dashing == false:
			
			body.blood = max(body.blood - damage, 0)
			if body.has_method("_flash_damage"):
				body._flash_damage()
			print("did damage")

		
