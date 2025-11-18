extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $CollisionShape2D
@export var damage: int = 20
@export var active_time: float = 1.0  # how long spikes stay up
@export var cooldown_time: float = 5.0  # how long before trap can trigger again

var is_active: bool = false
var is_on_cooldown: bool = false

func _ready():
	hitbox.disabled = false
	
	self.body_entered.connect(_on_body_entered)
	sprite.animation = "new_animation"
	sprite.frame = 0  # first frame
	sprite.stop()    # prevents it from playing until you call play
	
func _on_body_entered(body: Node) -> void:
	# Only trigger if not already active and not on cooldown
	if not is_active and not is_on_cooldown:
		print("entered")
		sprite.play("new_animation")
		is_active = true
		await get_tree().create_timer(active_time).timeout
		# Save original speed and apply damage/stop movement
		if "speed" in body and "blood" in body and "is_dashing" in body and body.is_dashing == false:
			body.blood = max(body.blood - damage, 0)
			if body.has_method("_flash_damage"):
				body._flash_damage()
		
		is_active = false
		queue_free()
		# Start cooldown
		is_on_cooldown = true
		await get_tree().create_timer(cooldown_time).timeout
		is_on_cooldown = false
