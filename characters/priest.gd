extends CharacterBody2D


@export var chase_speed: float = 240.0
@export var attack_interval: float = 1.0
@export var ally_attack_damage := 30
signal enemy_died
@export var speed := 130
@export var attack_range := 700
@export var attack_cooldown := 2.0
@export var projectile_scene: PackedScene
@export var health := 100
var last_hit_type: String = "" #! added

const SOUL_SCENE = preload("res://Enemy fragments/soul_fragment.tscn") #! added
const BLOOD_SCENE = preload("res://Enemy fragments/blood_packages.tscn") #! added

var player
var can_attack := true

var bonded_to_player: bool = false
var bonded_player: Node = null
var target_enemy: Node = null
var ally_attack_cooldown := 0.0

func _ready():

	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	$AnimatedSprite2D.play("walk")

func _physics_process(delta):
	if bonded_to_player:
		_process_as_ally(delta)
		return




	var distance = global_position.distance_to(player.global_position)

	# --- WALK ---
	if distance > attack_range:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * speed
		move_and_slide()
		_update_facing()

		if $AnimatedSprite2D.animation != "walk":
			$AnimatedSprite2D.play("walk")

	# --- ATTACK ---
	else:
		velocity = Vector2.ZERO
		move_and_slide()

		if can_attack:
			_start_attack()

func _start_attack():
	_update_facing()
	if bonded_to_player:
		return

	can_attack = false
	$AnimatedSprite2D.play("throw")

# CALLED WHEN THROW ANIMATION ENDS
func _on_AnimatedSprite2D_animation_finished():
		if bonded_to_player:
			return
		print("Throw animation finished. Attempting to spawn projectile.")
		
		_spawn_projectile()
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true
		$AnimatedSprite2D.play("walk")

func _spawn_projectile():
	if bonded_to_player:
		return
	
	if not projectile_scene:
		push_warning("Projectile scene is not assigned!")
		return
	else:
		print("Projectile scene is correctly assigned.")  # Debug check

	var projectile = projectile_scene.instantiate()
	
	if not is_instance_valid(projectile):
		push_warning("Projectile instantiation failed!")  # Check if the instantiation is valid
		return
	else:
		print("Projectile instantiated successfully.")  # Debug check

	var dir = (player.global_position - global_position).normalized()
	projectile.global_position = $ProjectileSpawn.global_position
	projectile.direction = dir
	
	# Add the projectile to the scene
	get_parent().add_child(projectile)
	print("Projectile added to the scene.")  # Debug check

func _flash_damage():
	# Change all sprites to red
	$AnimatedSprite2D.modulate = Color(1, 0, 0)
	# Wait a short time, then reset to white
	await get_tree().create_timer(0.15).timeout
	$AnimatedSprite2D.modulate = Color(1, 1, 1)

func take_damage(amount: int, attack_type: String = ""):
	health -= amount
	print("Priest took ", amount, " damage from ", attack_type)
	last_hit_type = attack_type
	_flash_damage()
	if health <= 0:
		die()


func die():
	emit_signal("enemy_died")
	_drop_loot() #! added
	queue_free()
	

func _drop_loot() -> void: #! added
	if last_hit_type == "bite":
		if SOUL_SCENE:
			var soul = SOUL_SCENE.instantiate()
			soul.global_position = global_position
			get_parent().add_child(soul)
	elif last_hit_type == "claw":
		if BLOOD_SCENE:
			var offsets = [
				Vector2(-24, -16),
				Vector2(24, -8),
				Vector2(0, 24)
			]
			for offset in offsets:
				var blood = BLOOD_SCENE.instantiate()
				blood.global_position = global_position + offset + Vector2(randf_range(-4, 4), randf_range(-4, 4))
				get_parent().add_child(blood)
				

func _process_as_ally(delta: float) -> void:
	velocity = Vector2.ZERO
	

	if not is_instance_valid(bonded_player):
		return

	var ally_chase_speed = chase_speed * 1.3
	var attack_damage = 50

	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy: Node = null
	var closest_dist := 9999.0

	for e in enemies:
		if e == self or not e.is_inside_tree():
			continue
		var d = global_position.distance_to(e.global_position)
		if d < closest_dist and d < 200:
			closest_enemy = e
			closest_dist = d

	if closest_enemy:
	
		var chase_dir = (closest_enemy.global_position - global_position).normalized()
		velocity = chase_dir * ally_chase_speed

		ally_attack_cooldown -= delta
		if closest_dist <= 24 and ally_attack_cooldown <= 0:
			if closest_enemy.has_method("take_damage"):
				print("Ally priest attacking enemy:", closest_enemy.name)
				closest_enemy.take_damage(attack_damage)
				ally_attack_cooldown = attack_interval
	else:
		var follow_dir = bonded_player.global_position - global_position

		if follow_dir.length() > 40:
			velocity = follow_dir.normalized() * ally_chase_speed

	move_and_slide()


func convert_to_ally(player_node: Node) -> void:
	if bonded_to_player:
		return

	bonded_to_player = true
	bonded_player = player_node

	remove_from_group("enemies")
	add_to_group("allies")
	can_attack = false # stop priest attack mode

	print("Priest converted to ally")

func _update_facing():
	if velocity.x > 5:
		$AnimatedSprite2D.flip_h = false  # facing right
	elif velocity.x < -5:
		$AnimatedSprite2D.flip_h = true   # facing l
