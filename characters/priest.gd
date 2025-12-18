extends CharacterBody2D

@export var chase_speed: float = 240.0
@export var attack_interval: float = 1.0
@export var ally_attack_damage := 30
@export var speed := 130
@export var attack_range := 700
@export var attack_cooldown := 2.0
@export var projectile_scene: PackedScene
@export var health := 100
signal enemy_died
var last_hit_type: String = ""

const SOUL_SCENE = preload("res://Enemy fragments/soul_fragment.tscn")
const BLOOD_SCENE = preload("res://Enemy fragments/blood_packages.tscn")

var player
var can_attack := true
var bonded_to_player: bool = false
var bonded_player: Node = null
var target_enemy: Node = null
var ally_attack_cooldown := 0.0
var ally_target: Node = null

func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	$AnimatedSprite2D.play("walk")
	$AnimatedSprite2D.animation_finished.connect(_on_AnimatedSprite2D_animation_finished)

func _physics_process(delta):
	if bonded_to_player:
		_process_as_ally(delta)
		return

	if not is_instance_valid(player):
		return

	var distance = global_position.distance_to(player.global_position)
	if distance > attack_range:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * speed
		move_and_slide()
		_update_facing()
		if $AnimatedSprite2D.animation != "walk":
			$AnimatedSprite2D.play("walk")
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		if can_attack:
			_start_attack()

func _process_as_ally(delta: float) -> void:
	$AnimatedSprite2D.modulate = Color(0.6, 1.0, 0.6)
	if not is_instance_valid(bonded_player):
		return

	# Find the closest enemy
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy: Node = null
	var closest_dist := INF

	for e in enemies:
		if e == self or not e.is_inside_tree():
			continue
		var d = global_position.distance_to(e.global_position)
		if d < closest_dist:
			closest_enemy = e
			closest_dist = d

	ally_target = closest_enemy

	if ally_target:
		var distance = global_position.distance_to(ally_target.global_position)
		if distance > attack_range:
			var dir = (ally_target.global_position - global_position).normalized()
			velocity = dir * chase_speed
			move_and_slide()
			_update_facing()
			if $AnimatedSprite2D.animation != "walk":
				$AnimatedSprite2D.play("walk")
		else:
			velocity = Vector2.ZERO
			move_and_slide()
			if ally_attack_cooldown <= 0 and $AnimatedSprite2D.animation != "throw":
				$AnimatedSprite2D.play("throw")
				ally_attack_cooldown = attack_interval
	else:
		# Follow player if no enemies
		var follow_dir = bonded_player.global_position - global_position
		if follow_dir.length() > 40:
			velocity = follow_dir.normalized() * chase_speed
		move_and_slide()

	ally_attack_cooldown -= delta

func _start_attack():
	_update_facing()
	can_attack = false
	$AnimatedSprite2D.play("throw")

func _on_AnimatedSprite2D_animation_finished():
	if $AnimatedSprite2D.animation != "throw":
		return

	if bonded_to_player:
		if not is_instance_valid(ally_target):
			return
		_spawn_projectile(true)
	else:
		_spawn_projectile(false)
		await get_tree().create_timer(attack_cooldown).timeout

	can_attack = true
	$AnimatedSprite2D.play("walk")

func _spawn_projectile(is_ally: bool):
	if not projectile_scene:
		return
	var projectile = projectile_scene.instantiate()
	if not is_instance_valid(projectile):
		return

	var dir: Vector2
	if is_ally:
		if not is_instance_valid(ally_target):
			return
		dir = (ally_target.global_position - global_position).normalized()
		projectile.damage = ally_attack_damage
	else:
		dir = (player.global_position - global_position).normalized()

	projectile.global_position = $ProjectileSpawn.global_position
	projectile.direction = dir
	get_parent().add_child(projectile)

func _flash_damage():
	$AnimatedSprite2D.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.15).timeout
	$AnimatedSprite2D.modulate = Color(0.6, 1.0, 0.6) if bonded_to_player else Color(1,1,1)

func take_damage(amount: int, attack_type: String = ""):
	health -= amount
	last_hit_type = attack_type
	_flash_damage()
	if health <= 0:
		die()

func die():
	emit_signal("enemy_died")
	_drop_loot()
	queue_free()

func _drop_loot() -> void:
	if last_hit_type == "bite":
		if SOUL_SCENE:
			var soul = SOUL_SCENE.instantiate()
			soul.global_position = global_position
			get_parent().add_child(soul)
	elif last_hit_type == "claw":
		if BLOOD_SCENE:
			var offsets = [Vector2(-24,-16), Vector2(24,-8), Vector2(0,24)]
			for offset in offsets:
				var blood = BLOOD_SCENE.instantiate()
				blood.global_position = global_position + offset + Vector2(randf_range(-4,4), randf_range(-4,4))
				get_parent().add_child(blood)

func convert_to_ally(player_node: Node) -> void:
	if bonded_to_player:
		return
	bonded_to_player = true
	bonded_player = player_node
	remove_from_group("enemies")
	add_to_group("allies")
	can_attack = false

func _update_facing():
	if velocity.x > 5:
		$AnimatedSprite2D.flip_h = false
	elif velocity.x < -5:
		$AnimatedSprite2D.flip_h = true
