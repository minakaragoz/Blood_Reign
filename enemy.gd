extends CharacterBody2D
class_name Villager

signal enemy_died

# ------------------------------
# Exported variables
# ------------------------------
@export var speed: float = 120.0
@export var chase_speed: float = 240.0
@export var attack_interval: float = 1.0
@export var attack_damage: int = 10
@export var max_health: int = 100

# ------------------------------
# Loot scenes
# ------------------------------
const SOUL_SCENE = preload("res://Enemy fragments/soul_fragment.tscn") #! added
const BLOOD_SCENE = preload("res://Enemy fragments/blood_packages.tscn") #! added

# ------------------------------
# Internal state
# ------------------------------
var roam_dir: Vector2 = Vector2.ZERO
var dead: bool = false
var health: int = max_health

var bonded_to_player: bool = false
var bonded_player: Node = null
var target_enemy: Node = null
var ally_attack_cooldown := 0.0
var attackTimer = Timer.new()
@onready var sprite = $Sprite2D

var last_hit_type: String = "" #! added
# ------------------------------
# Ready
# ------------------------------
func _ready() -> void:
	add_to_group("enemies")
	attackTimer = Timer.new()
	attackTimer.wait_time = attack_interval
	attackTimer.one_shot = false
	attackTimer.autostart = false
	add_child(attackTimer)
	attackTimer.timeout.connect(_on_attack_timer_timeout)
	# Timer for roaming
	var directionTimer = $Timer
	directionTimer.wait_time = 2.0
	directionTimer.start()
	directionTimer.timeout.connect(_on_Timer_timeout)

	# Timer for attack (used for enemies attacking player)
	var attackTimer = Timer.new()
	attackTimer.wait_time = attack_interval
	attackTimer.one_shot = false
	attackTimer.autostart = false
	add_child(attackTimer)
	attackTimer.timeout.connect(_on_attack_timer_timeout)

	# Connect detection and attack areas
	$DetectionArea.body_entered.connect(_on_chase_area_body_entered)
	$DetectionArea.body_exited.connect(_on_chase_area_body_exited)
	$AttackArea.body_entered.connect(_on_attack_area_body_entered)
	$AttackArea.body_exited.connect(_on_attack_area_body_exited)

# ------------------------------
# Physics process
# ------------------------------
func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		return

	if bonded_to_player:
		_process_as_ally(delta)
		return

	# Normal enemy movement toward player
	var current_target: Node = null
	for b in $DetectionArea.get_overlapping_bodies():
		if b.is_in_group("player"):
			current_target = b
			break

	if current_target and current_target.is_inside_tree():
		var dir = (current_target.global_position - global_position).normalized()
		velocity = dir * chase_speed
	else:
		velocity = roam_dir * speed

	move_and_collide(velocity * delta)

# ------------------------------
# Roaming timer
# ------------------------------
func _on_Timer_timeout() -> void:
	if not bonded_to_player:
		var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.ZERO]
		roam_dir = dirs[randi() % dirs.size()]

# ------------------------------
# Detection
# ------------------------------
func _on_chase_area_body_entered(body: Node2D) -> void:
	if not bonded_to_player and body.is_in_group("player"):
		pass # handled in _physics_process

func _on_chase_area_body_exited(body: Node2D) -> void:
	pass

# ------------------------------
# Attack area
# ------------------------------
func _on_attack_area_body_entered(body: Node2D) -> void:
	if bonded_to_player:
		if body.is_in_group("enemies"):
			target_enemy = body
	else:
		if body.is_in_group("player"):
			# Start attack timer if not running
			if attackTimer.is_stopped():
				attackTimer.start()
			# Track the player as current target
			target_enemy = body

func _on_attack_area_body_exited(body: Node2D) -> void:
	if bonded_to_player:
		if body == target_enemy:
			target_enemy = null
	else:
		if body == target_enemy:
			attackTimer.stop()
			target_enemy = null

# ------------------------------
# Attack timer (for enemies attacking player)
# ------------------------------
func _on_attack_timer_timeout() -> void:
	if target_enemy and target_enemy.is_inside_tree() and "blood" in target_enemy:
		# Reduce player blood or health
		target_enemy.blood = max(target_enemy.blood - attack_damage, 0)
		if target_enemy.has_method("_flash_damage"):
			target_enemy._flash_damage()
		if target_enemy.blood_meter:
			target_enemy.blood_meter.value = target_enemy.blood
# ------------------------------
# Ally behavior
# ------------------------------
func _process_as_ally(delta: float) -> void:
	if not bonded_player:
		return

	# Ally moves faster than normal
	var ally_chase_speed = chase_speed * 1.3
	var attack_damage = 50
	# Find closest enemy
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

	# Move toward enemy and attack
	if closest_enemy:
		var chase_dir = (closest_enemy.global_position - global_position).normalized()
		velocity = chase_dir * ally_chase_speed

		ally_attack_cooldown -= delta
		if closest_dist <= 24 and ally_attack_cooldown <= 0:
			if closest_enemy.has_method("take_damage"):
				print("Ally attacking enemy: %s" % closest_enemy.name)
				closest_enemy.take_damage(attack_damage)
				ally_attack_cooldown = attack_interval

	move_and_collide(velocity * delta)

# ------------------------------
# Convert to ally
# ------------------------------
func convert_to_ally(player_node: Node) -> void:
	if bonded_to_player:
		return
	bonded_to_player = true
	bonded_player = player_node
	remove_from_group("enemies")
	add_to_group("allies")
	sprite.modulate = Color(0.6, 1.0, 0.6)
	target_enemy = null
	print("Converted to ally: %s" % name)

# ------------------------------
# Damage & death
# ------------------------------
func take_damage(amount: int, attack_type := "bite") -> void:
	if dead:
		return
	last_hit_type = attack_type #!added
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	dead = true
	velocity = Vector2.ZERO
	_drop_loot() #! added
	emit_signal("enemy_died")
	queue_free()

# ------------------------------
# Drop logic
# ------------------------------
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
