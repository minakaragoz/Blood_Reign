extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $CollisionShape2D
@export var damage: int = 5
@export var active_time: float = 1.0  # how long spikes stay up
@export var cooldown_time: float = 5.0  # how long before trap can trigger again

var trapped_bodies = {}
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
		# Save original speed and apply damage/stop movement
		if "speed" in body and "blood" in body and "is_dashing" in body and body.is_dashing == false:
			trapped_bodies[body] = body.speed
			body.speed = 0
			body.blood = max(body.blood - damage, 0)
			if body.has_method("_flash_damage"):
				body._flash_damage()
		
		# Keep spikes visually active for a short time
		await get_tree().create_timer(active_time).timeout
		
		# Restore the player’s speed
		for b in trapped_bodies.keys():
			if "speed" in b:
				b.speed = trapped_bodies[b]
		trapped_bodies.clear()
		is_active = false
		queue_free()
		# Start cooldown
		is_on_cooldown = true
		await get_tree().create_timer(cooldown_time).timeout
		is_on_cooldown = false
