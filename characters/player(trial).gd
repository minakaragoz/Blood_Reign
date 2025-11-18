extends CharacterBody2D
@onready var bite_area = $BiteArea 
@onready var bite_sprite = $BiteArea/BiteSprite
@export var bite_damage := 20
@export var speed = 400
@export var dash_speed = 5000
@export var dash_duration := 0.2
@export var dash_cooldown := 1.0
@onready var blood_drain_timer = Timer.new()

# Sprites
@onready var sprite_down = $SpriteDown
@onready var sprite_up = $SpriteUp
@onready var sprite_side = $SpriteSide
@onready var bat_sprite = $BatSprite
@export var hunger := 5
@export var base_bite_damage := 20
@export var base_hunger := 5

# Remember facing direction
var last_facing := Vector2.DOWN
var dash_timer := 0.0
var cooldown_timer := 0.0
var is_dashing := false
var dash_direction := Vector2.ZERO
var dash_hit_enemies := []  # Track which enemies were hit this dash

# Blood meter
@export var max_blood := 100
var blood := max_blood
@export var dash_cost := 25

var bat_form_active = false

var bonded_enemy: Node = null

# Bite cooldown
@export var bite_cooldown := 1.0
var bite_timer := 0.0

@onready var blood_meter = get_tree().root.get_node("/root/Node2D/CanvasLayer/ProgressBar") 

func _ready():
	# Hide bite sprite initially
	bite_sprite.visible = false
	
	bite_sprite.animation_finished.connect(_on_bite_animation_finished)
	
	# Blood drain
	blood_drain_timer.wait_time = 1.0
	blood_drain_timer.autostart = true
	blood_drain_timer.timeout.connect(_on_blood_drain_tick)
	add_child(blood_drain_timer)

func _on_blood_drain_tick():
	blood -= hunger
	blood = clamp(blood, 0, max_blood)
	blood_meter.value = blood

func _physics_process(delta):
	# Tick down timers
	if bite_timer > 0.0:
		bite_timer -= delta
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

	# Apply Blood Frenzy buffs
	if GlobalData.purchased_skills["blood_frenzy"]:
		bite_damage = base_bite_damage * 2
		hunger = base_hunger * 2
	else:
		bite_damage = base_bite_damage
		hunger = base_hunger

	# Get input
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_direction != Vector2.ZERO:
		last_facing = input_direction.normalized()

	# Handle dash
	if is_dashing:
		velocity = dash_direction * dash_speed
		dash_timer -= delta
		$DashArea.monitoring = true

		# Damage enemies in dash
		for body in $DashArea.get_overlapping_bodies():
			if body.is_in_group("enemies") and body not in dash_hit_enemies:
				if body.has_method("take_damage"):
					body.take_damage(bite_damage)
					dash_hit_enemies.append(body)

		if dash_timer <= 0.0:
			is_dashing = false
			dash_hit_enemies.clear()
			$DashArea.monitoring = false
	else:
		# Start dash if pressed and enough blood
		if Input.is_action_just_pressed("dash") and cooldown_timer <= 0.0 and blood_meter.value >= dash_cost:
			is_dashing = true
			dash_direction = input_direction.normalized() if input_direction != Vector2.ZERO else last_facing
			dash_timer = dash_duration
			cooldown_timer = dash_cooldown
			blood -= dash_cost
			blood_meter.value = blood
			$DashArea.monitoring = true
		else:
			# Normal movement
			velocity = input_direction * speed

	# Update Bite Area position
	if input_direction != Vector2.ZERO:
		$BiteArea.position = input_direction.normalized() * 16
		$BiteArea.rotation = input_direction.angle()

	# Handle Bite
	if Input.is_action_just_pressed("bite"):
		_do_bite(input_direction)

	# Handle Sprint
	if Input.is_action_just_pressed("Sprint"):
		speed = 600
	elif Input.is_action_just_released("Sprint"):
		speed = 400

	# Handle player death
	if blood <= 0:
		_on_player_death()

	# Bat Form
	if GlobalData.purchased_skills["bat_form"]:
		if Input.is_action_just_pressed("bat_form") and not bat_form_active:
			_activate_bat_form()

	_update_sprite_direction(input_direction)
	move_and_slide()

func _do_bite(_direction: Vector2):
	if bite_timer > 0.0:
		# Flash red to indicate cooldown
		bite_sprite.modulate = Color(1,0,0)
		bite_sprite.visible = true
		await get_tree().create_timer(0.2).timeout
		bite_sprite.visible = false
		bite_sprite.modulate = Color(1,1,1)
		return
	
	bite_timer = bite_cooldown
	
	# Use last_facing instead of input direction
	var direction = last_facing
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	bite_area.position = direction.normalized() * 16
	bite_area.rotation = direction.angle()
	bite_area.player = self
	bite_area.bite_damage = bite_damage
	bite_area.monitoring = true
	
	# Play bite animation
	bite_sprite.visible = true
	bite_sprite.play("default")
	bite_sprite.flip_h = direction.x < 0
	bite_sprite.rotation = direction.angle()

	await get_tree().create_timer(0.1).timeout
	for body in bite_area.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			# Only convert if there is no bonded enemy
			if GlobalData.purchased_skills["blood_bond"] and bonded_enemy == null:
				_convert_enemy_to_ally(body)
				bonded_enemy = body
				print("Converted to ally!")
			elif body.has_method("take_damage"):
				body.take_damage(bite_damage)

	bite_area.monitoring = false
func _activate_bat_form():
	bat_form_active = true
	bat_sprite = true
	var original_speed = speed
	var original_hunger = hunger

	speed *= 3
	hunger = 0
	
	# Hide normal sprites
	sprite_down.visible = false
	sprite_up.visible = false
	sprite_side.visible = false
	
	await get_tree().create_timer(5.0).timeout
	
	speed = original_speed
	hunger = original_hunger
	bat_form_active = false
	bat_sprite = false
	_update_sprite_direction(Vector2.DOWN)

func _convert_enemy_to_ally(enemy):
	if !enemy or !enemy.is_inside_tree():
		return

	# Call the Villager's conversion function
	if enemy.has_method("convert_to_ally"):
		enemy.convert_to_ally(self)
		print("Converted to ally!")

		# Reset velocity and movement
		if enemy.has_method("set_velocity"):
			enemy.set_velocity(Vector2.ZERO)
		elif "velocity" in enemy:
			enemy.velocity = Vector2.ZERO

		# Clear any lingering targets
		if "current_target" in enemy:
			enemy.current_target = null
		if "target_enemy" in enemy:
			enemy.target_enemy = null
	else:
		print("Enemy missing convert_to_ally method")
func _update_sprite_direction(input_direction: Vector2):
	sprite_down.visible = false
	sprite_up.visible = false
	sprite_side.visible = false

	var facing = input_direction if input_direction != Vector2.ZERO else last_facing

	if facing.y < -0.5:
		sprite_up.visible = true
	elif facing.y > 0.5:
		sprite_down.visible = true
	elif facing.x != 0:
		sprite_side.visible = true
		sprite_side.flip_h = facing.x < 0
	else:
		sprite_down.visible = true

func _on_bite_animation_finished():
	bite_sprite.stop()
	bite_sprite.visible = false
func _on_player_death():
	GlobalData.kill_count = 0
	# Reset all persistent player state
	for skill in GlobalData.purchased_skills.keys():
		GlobalData.purchased_skills[skill] = false
	
	# Optionally, reset other stats if you have them

	# Then change scene
	get_tree().change_scene_to_file("res://DeathScreen.tscn")
	
func _flash_damage():
	# Change all sprites to red
	sprite_down.modulate = Color(1, 0, 0)
	sprite_up.modulate = Color(1, 0, 0)
	sprite_side.modulate = Color(1, 0, 0)
	
	# Wait a short time, then reset to white
	await get_tree().create_timer(0.15).timeout
	sprite_down.modulate = Color(1, 1, 1)
	sprite_up.modulate = Color(1, 1, 1)
	sprite_side.modulate = Color(1, 1, 1)
