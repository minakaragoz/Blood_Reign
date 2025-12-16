extends Area2D

@export var speed := 450
@export var damage := 25
var direction := Vector2.ZERO

func _ready():
	
	var frames = $AnimatedSprite2D.sprite_frames
	if frames and frames.has_animation("default"):
		$AnimatedSprite2D.play("default")
	else:
		print("Projectile WARNING: 'default' anim yok!")

	connect("body_entered", _on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.blood -= damage
		body.blood = clamp(body.blood, 0, body.max_blood)
		body.blood_meter.value = body.blood
		body._flash_damage()

		if body.blood <= 0:
			body._on_player_death()

	queue_free()
