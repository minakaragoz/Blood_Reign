extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $CollisionShape2D

@export var damage: int = 20
@export var active_time: float = 1.0
@export var cooldown_time: float = 5.0

var is_active: bool = false
var is_on_cooldown: bool = false
var trapped_body: Node = null   # ✅ Track player inside trap

func _ready():
	hitbox.disabled = false
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)  # ✅ Track exit
	
	sprite.animation = "new_animation"
	sprite.frame = 0
	sprite.stop()

func _on_body_entered(body: Node) -> void:
	if is_active or is_on_cooldown:
		return

	print("entered")
	trapped_body = body
	is_active = true
	
	sprite.play("new_animation")
	hitbox.visible = true
	
	await get_tree().create_timer(active_time).timeout
	
	# ✅ Only damage if still inside
	if trapped_body and is_instance_valid(trapped_body):
		if "speed" in trapped_body and "blood" in trapped_body and "is_dashing" in trapped_body:
			if trapped_body.is_dashing == false:
				trapped_body.blood = max(trapped_body.blood - damage, 0)
				if trapped_body.has_method("_flash_damage"):
					trapped_body._flash_damage()


	
	is_active = false
	trapped_body = null
	queue_free()

func _on_body_exited(body: Node) -> void:
	# ✅ Clear player if they leave
	if body == trapped_body:
		trapped_body = null
