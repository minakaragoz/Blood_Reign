extends CharacterBody2D

# ================= STATES =================
enum BossState { IDLE, RANGED, MELEE, TELEPORT }
var state: BossState = BossState.IDLE
var locked := false
var health := 600
var dead := false
var last_hit_type := ""

# ================= REFERENCES =================
var player: Node2D
signal boss_died
@onready var idle_sprite: Sprite2D = $BossIdle
@onready var shoot_anim: AnimatedSprite2D = $ShootStart
@onready var slam_anim: AnimatedSprite2D = $SlamAnimation
@onready var spawn_anim: AnimatedSprite2D = $SpawnAnimation

@onready var close_area: Area2D = $CloseArea
@onready var far_area: Area2D = $FarArea

# ================= RANGED =================
@export var max_bullets := 5
@export var fire_rate := 0.35
@export var bullet_speed := 900
@export var bullet_scene := preload("res://Bullet.tscn")

# ================= SLAM =================
@export var slam_damage := 55
@export var slam_anim_time := 1.2
var slam_ready := true

# ================= TELEPORT DISTANCES =================
@export var ranged_min_tp := 220
@export var ranged_max_tp := 600
@export var slam_min_tp := 500
@export var slam_max_tp := 900
@export var spawn_time := 1.1

# ================= IDLE PAUSE =================
@export var idle_pause_time := 1.2

# ================= READY =================
func _ready():
	randomize()
	player = get_tree().get_first_node_in_group("player")
	_show_only(idle_sprite)

	close_area.body_entered.connect(_on_close_enter)
	far_area.body_entered.connect(_on_far_enter)

	print("FINAL BOSS READY")

# ================= AREA SIGNALS =================
func _on_close_enter(body):
	if body.is_in_group("player") and not locked and slam_ready:
		await slam_attack()

func _on_far_enter(body):
	if body.is_in_group("player") and not locked and state == BossState.IDLE:
		await ranged_attack()

# ================= RANGED ATTACK =================
func ranged_attack():
	if locked or dead:
		return

	locked = true
	state = BossState.RANGED

	print("RANGED ATTACK START")
	_show_only(shoot_anim)

	for i in range(max_bullets):
		fire_bullet()
		await get_tree().create_timer(fire_rate).timeout

	await idle_pause()
	await finish_action(false)

# ================= BULLET =================
func fire_bullet():
	if not player:
		return

	var b = bullet_scene.instantiate()
	b.global_position = global_position
	b.direction = (player.global_position - global_position).normalized()
	b.speed = bullet_speed
	get_tree().current_scene.add_child(b)

	shoot_anim.play("gun_fire")

# ================= SLAM ATTACK =================
func slam_attack():
	if locked or not slam_ready or dead:
		return

	locked = true
	slam_ready = false
	state = BossState.MELEE

	print("SLAM START")
	_show_only(slam_anim)
	slam_anim.play("slam")

	await get_tree().create_timer(slam_anim_time).timeout

	if player in close_area.get_overlapping_bodies():
		if player in close_area.get_overlapping_bodies():
			if "blood" in player:
				player.blood = max(player.blood - 35, 0)
				player._flash_damage()
				if player.blood_meter:
					player.blood_meter.value = player.blood
					

	await idle_pause()
	await finish_action(true)

# ================= FINISH ACTION =================
func finish_action(from_slam: bool):
	if dead:
		return

	await teleport(from_slam)
	await idle_pause()

	locked = false
	slam_ready = true
	state = BossState.IDLE
	_show_only(idle_sprite)

	# Auto chain next move
	if player in close_area.get_overlapping_bodies() and slam_ready:
		await slam_attack()
	elif player in far_area.get_overlapping_bodies():
		await ranged_attack()

# ================= TELEPORT =================
func teleport(from_slam: bool):
	if dead:
		return

	state = BossState.TELEPORT

	var angle = randf() * TAU
	var dist: float

	if from_slam:
		dist = randf_range(slam_min_tp, slam_max_tp)
		print("SLAM TELEPORT (FAR)")
	else:
		dist = randf_range(ranged_min_tp, ranged_max_tp)
		print("RANGED TELEPORT")

	global_position = player.global_position + Vector2(cos(angle), sin(angle)) * dist

	print("TELEPORT TO", global_position)

	_show_only(spawn_anim)
	spawn_anim.play("spawn")

	await get_tree().create_timer(spawn_time).timeout

# ================= IDLE PAUSE =================
func idle_pause():
	if dead:
		return
	print("IDLE PAUSE")
	_show_only(idle_sprite)
	await get_tree().create_timer(idle_pause_time).timeout

# ================= TAKE DAMAGE =================
func take_damage(amount: int, attack_type := "bite") -> void:
	_flash_damage()
	if dead:
		return
	last_hit_type = attack_type
	health -= amount
	print("Boss took", amount, "damage. Health:", health)
	if health <= 0:
		die()

# ================= FLASH DAMAGE =================
func _flash_damage():
	if not is_inside_tree() or dead:
		return

	var flash_color = Color(1, 0, 0)
	var normal_color = Color(1, 1, 1)
	var sprites = [idle_sprite, shoot_anim, slam_anim, spawn_anim]

	for s in sprites:
		if is_instance_valid(s):
			s.modulate = flash_color

	await get_tree().create_timer(0.15).timeout

	for s in sprites:
		if is_instance_valid(s):
			s.modulate = normal_color

# ================= DIE =================
func die():
	print("BOSS DIED")
	dead = true
	locked = true
	state = BossState.IDLE
	_show_only(idle_sprite)
	emit_signal("boss_died")
	queue_free()

# ================= VISIBILITY =================
func _show_only(node: Node):
	idle_sprite.visible = false
	shoot_anim.visible = false
	slam_anim.visible = false
	spawn_anim.visible = false
	node.visible = true
