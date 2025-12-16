extends Area2D

@export var speed := 450
@export var damage := 10
var direction := Vector2.ZERO

func _ready():
	# Add visible sprite if not already present
	if $Sprite2D:
		$Sprite2D.z_index = 10
		$Sprite2D.modulate = Color(1,0,0)  # red for visibility
	else:
		var sprite = Sprite2D.new()
		var tex = ImageTexture.new()
		var img = Image.new()
		img.create(8, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color(1,0,0))
		tex.create_from_image(img)
		sprite.texture = tex
		add_child(sprite)

	connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.blood = max(body.blood - damage, 0)
		body._flash_damage()
		if body.blood_meter:
			body.blood_meter.value = body.blood
		print(damage)
		queue_free()
