extends CharacterBody2D
class_name Villager

signal enemy_died

# ------------------------------
# Exported variables
# ------------------------------
@export var speed: float = 300.0
@export var chase_speed: float = 240.0
@export var attack_interval: float = .75
@export var attack_damage: int = 10
@export var max_health: int = 100
var is_attacking := false

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
var ally_attack_damage := 25
var attackTimer = Timer.new()
@onready var sprite = $Sprite2D
@onready var attack_animation = $villager_attack
@onready var walk_animation = $villager_walk
var last_hit_type: String = "" #! added
# ------------------------------
# Ready
# ------------------------------
func _ready() -> void:
	add_to_group("enemies")
	attackTimer.wait_time = attack_interval
	attackTimer.one_shot = false
	attackTimer.autostart = false
	add_child(attackTimer)
	attackTimer.timeout.connect(_on_attack_timer_timeout)
	attack_animation.animation_finished.connect(_on_attack_animation_finished)
	# Timer for roaming
	var directionTimer = $Timer
	directionTimer.wait_time = 2.0
	directionTimer.start()
	directionTimer.timeout.connect(_on_Timer_timeout)

	

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
		sprite.modulate = Color(0.6, 1.0, 0.6)
		_process_as_ally(delta)
		return

	# Normal enemy movement toward player
	var current_target: Node = null
	for b in $DetectionArea.get_overlapping_bodies():
		if b.is_in_group("player") or b.is_in_group("allies"):
			current_target = b
			break
			
# Update target dynamically (closest)
	current_target = _find_closest_target(["allies", "player"])
	if current_target != null:
		target_enemy = current_target

		
	if current_target != target_enemy:
		target_enemy = current_target
	
	if current_target and current_target.is_inside_tree():
		var dir = (current_target.global_position - global_position).normalized()
		velocity = dir * speed
	else:
		velocity = roam_dir * speed

	move_and_slide()
	_update_facing()
	_update_animation()
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
			if attackTimer.is_stopped():
				attackTimer.start()
			target_enemy = body
	else:
		if body.is_in_group("player") or body.is_in_group("allies"):
			# Start attack timer if not running
			if attackTimer.is_stopped():
				attackTimer.start()
			# Track the player as current target
			target_enemy = body

func _on_attack_area_body_exited(body: Node2D) -> void:
	if bonded_to_player:
		if body == target_enemy:
			attackTimer.stop()
			target_enemy = null
	else:
		if body == target_enemy:
			attackTimer.stop()
			target_enemy = null

# ------------------------------
# Attack timer
# ------------------------------
func _on_attack_timer_timeout() -> void:
	if not target_enemy or not target_enemy.is_inside_tree():
		return

	_start_attack_animation()

	# ----------------------
	# Ally logic (bonded to player)
	# ----------------------
	if bonded_to_player:
		if target_enemy.is_in_group("enemies") and target_enemy.is_inside_tree():
			# Only attack if target is in attack area
			if $AttackArea.get_overlapping_bodies().has(target_enemy):
				print("Ally attacking enemy:", target_enemy.name, "with damage:", ally_attack_damage)
				target_enemy.take_damage(ally_attack_damage, "claw")
				if target_enemy.has_method("_flash_damage"):
					target_enemy._flash_damage()
			else:
				print("Ally skipped target (not in attack area):", target_enemy.name)
		return

	# ----------------------
	# Enemy logic (non-bonded)
	# ----------------------
	# Only attack if target is actually in the attack area
	if not $AttackArea.get_overlapping_bodies().has(target_enemy):
		print("Enemy skipped target (not in attack area):", target_enemy.name)
		return

	if "blood" in target_enemy and target_enemy.is_in_group("player"):
		if target_enemy.has_method("can_take_damage"):
			if not target_enemy.can_take_damage("melee"):
				print("Player immune to melee")
				return
		print("Enemy attacking player:", target_enemy.name, "damage:", attack_damage)
		target_enemy.blood = max(target_enemy.blood - attack_damage, 0)
		if target_enemy.has_method("_flash_damage"):
			target_enemy._flash_damage()
		if target_enemy.blood_meter:
			target_enemy.blood_meter.value = target_enemy.blood
	elif "health" in target_enemy and target_enemy.is_in_group("allies"):
		print("Enemy attacking ally:", target_enemy.name, "damage:", attack_damage)
		target_enemy.take_damage(attack_damage, "claw")
	elif "health" in target_enemy and target_enemy.is_in_group("enemies"):
		print("Enemy attacking enemy:", target_enemy.name, "damage:", attack_damage)
		target_enemy.take_damage(attack_damage, "claw")

# ------------------------------
# Ally behavior
# ------------------------------
func _process_as_ally(delta: float) -> void:
	sprite.modulate = Color(0.6, 1.0, 0.6)
	walk_animation.modulate = Color(0.6, 1.0, 0.6)
	attack_animation.modulate = Color(0.6, 1.0, 0.6)
	if not bonded_player:
		return
	# Normal enemy movement toward enemies
	var current_target: Node = null
	for b in $DetectionArea.get_overlapping_bodies():
		if b.is_in_group("enemies") and b != bonded_player:
			current_target = b
			break

	if current_target and current_target.is_inside_tree():
		var dir = (current_target.global_position - global_position).normalized()
		velocity = dir * chase_speed
	else:
		velocity = roam_dir * speed
		

	move_and_slide()
	_update_facing()
# ------------------------------
# Convert to ally
# ------------------------------
func convert_to_ally(player_node: Node) -> void:
	if bonded_to_player:
		return
	bonded_to_player = true
	bonded_player = player_node
	self.collision_layer &= ~ 3
	remove_from_group("enemies")
	add_to_group("allies")
	
	target_enemy = null
	print("Converted to ally: %s" % name)

# ------------------------------
# Damage & death
# ------------------------------
func take_damage(amount: int, attack_type := "bite") -> void:
	_flash_damage()
	if dead:
		return
	last_hit_type = attack_type #!added
	health -= amount
	if health <= 0:
		die()
		
func _flash_damage():
	# Abort immediately if this node is already being freed
	if not is_inside_tree():
		return

	var flash_color = Color(1, 0, 0)
	var normal_color = Color(1, 1, 1)

	# --- APPLY FLASH ---
	if is_instance_valid(sprite):
		sprite.modulate = flash_color
	if is_instance_valid(walk_animation):
		walk_animation.modulate = flash_color
	if is_instance_valid(attack_animation):
		attack_animation.modulate = flash_color

	# Wait briefly
	await get_tree().create_timer(0.15).timeout

	# Abort if object was destroyed during await
	if not is_instance_valid(self):
		return

	# --- RESTORE NORMAL ---
	if is_instance_valid(sprite):
		sprite.modulate = normal_color
	if is_instance_valid(walk_animation):
		walk_animation.modulate = normal_color
	if is_instance_valid(attack_animation):
		attack_animation.modulate = normal_color


func die() -> void:
	dead = true
	velocity = Vector2.ZERO
	_drop_loot() #! added
	if self.is_in_group("enemies"):
		print("enemy died")
		emit_signal("enemy_died")
		call_deferred("queue_free")
	else:
		print("ally died")
		call_deferred("queue_free")

# ------------------------------
# Drop logic
# ------------------------------
func _drop_loot() -> void:
	call_deferred("_drop_loot_safe")


func _drop_loot_safe() -> void:
	if not is_inside_tree():
		return

	if last_hit_type == "bite":
		if SOUL_SCENE:
			var soul = SOUL_SCENE.instantiate()
			get_parent().add_child(soul)
			soul.global_position = global_position

	elif last_hit_type == "claw":
		if BLOOD_SCENE:
			var offsets = [
				Vector2(-24, -16),
				Vector2(24, -8),
				Vector2(0, 24)
			]
			for offset in offsets:
				var blood = BLOOD_SCENE.instantiate()
				get_parent().add_child(blood)
				blood.global_position = global_position + offset + Vector2(randf_range(-4, 4), randf_range(-4, 4))
				
func _update_facing():
	if velocity.x > 5:
		sprite.flip_h = false
		walk_animation.flip_h = false
		attack_animation.flip_h = false # facing right
	elif velocity.x < -5:
		sprite.flip_h = true   # facing left
		walk_animation.flip_h = true
		attack_animation.flip_h = true
		
func _update_animation() -> void:
	if is_attacking:
		return

	if velocity.length() > 5:
		if not walk_animation.is_playing():
			walk_animation.visible = true
			attack_animation.visible = false
			walk_animation.play()
	else:
		walk_animation.stop()
		
func _start_attack_animation() -> void:
	if is_attacking:
		return

	is_attacking = true
	walk_animation.stop()
	walk_animation.visible = false

	attack_animation.visible = true
	attack_animation.play()
	
func _on_attack_animation_finished() -> void:
	is_attacking = false
	attack_animation.visible = false

	if velocity.length() > 5:
		walk_animation.visible = true
		walk_animation.play()

func _find_closest_target(group_names: Array) -> Node:
	var closest: Node = null
	var closest_dist := INF

	for group_name in group_names:
		for body in $DetectionArea.get_overlapping_bodies():
			if not body.is_inside_tree():
				continue
			if not body.is_in_group(group_name):
				continue

			var dist := global_position.distance_to(body.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = body

	return closest
