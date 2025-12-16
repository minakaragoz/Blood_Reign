extends CharacterBody2D

@onready var bite_area = $BiteArea 
@onready var bite_sprite = $BiteArea/BiteSprite
@onready var claw_area = $ClawArea 
@onready var claw_sprite = $ClawArea/ClawSprite
@onready var bat_area = $BatArea
@export var dash_damage := 25
@export var bite_damage := 25
@export var claw_damage := 20
@export var speed = 400
@export var dash_speed = 5000
@export var dash_duration := 0.2
@export var dash_cooldown := 1.0
@onready var blood_drain_timer = Timer.new()
@export var claw_cooldown := .75
var is_immobilized: bool = false
var claw_timer := 0.0
var blood_loss_accumulator := 0.0
# Sprites
@onready var sprite_move_down= $DownSpriteDynamic
@onready var sprite_move_side= $SideSpriteDynamic
@onready var sprite_move_up=$UpSpriteDynamic
@onready var sprite_down = $SpriteDownStatic
@onready var sprite_up = $SpriteUp
@onready var sprite_side = $SpriteSideStatic
@onready var sprite_bat = $BatSprite
@export var hunger := 5
@export var base_dash_damage := 25
@export var base_bite_damage := 20
@export var base_hunger := 5
@export var base_claw_cooldown := 0.75
@export var base_dash_cost := 25
@export var base_claw_damage := 20
@export var base_speed := 400
@export var max_health := 100


var last_facing := Vector2.DOWN
var dash_timer := 0.0
var cooldown_timer := 0.0
var is_dashing := false
var dash_direction := Vector2.ZERO
var dash_hit_enemies := []

# Blood meter
@export var max_blood := 100
var blood := max_blood
@export var dash_cost := 25

# --- BAT BASE VALUES (for reset) ---
@export var base_bat_bite_multiplier := 0.8
@export var base_bat_claw_multiplier := 0.8
@export var base_bat_claw_cooldown_multiplier := 0.6

var bat_iframe_timer := 0.0
var bat_iframes_active := false
var bat_form_active = false
@export var bat_cooldown := 6.0  # seconds
var bat_cooldown_timer := 0.0

var bonded_enemy: Node = null

# Bite cooldown
@export var bite_cooldown := 1.25
var bite_timer := 0.0

@onready var blood_meter = get_tree().root.get_node("/root/Node2D/CanvasLayer/ProgressBar")


@export var base_max_allies := 1
var max_allies := 1
var super_ally: Node = null

# --- Soul System ---
var soul_count: int:
	get:
		return GlobalData.soul_count
	set(value):
		GlobalData.soul_count = value

var soul_label: Label = null

func _cache_hud():
	soul_label = get_tree().get_root().find_child("SoulLabel", true, false)

func add_soul(amount: int = 1):
	soul_count += amount
	update_soul_ui()

func update_soul_ui():
	if soul_label == null:
		_cache_hud()
	if soul_label:
		soul_label.text = "Soul: %d" % soul_count


func _ready():
	# Hide attack sprites initially
	sprite_bat.visible = false
	bite_sprite.visible = false
	bite_sprite.animation_finished.connect(_on_bite_animation_finished)

	claw_sprite.visible = false
	claw_sprite.animation_finished.connect(_on_claw_animation_finished)



func _on_blood_drain_tick():
	blood -= hunger
	blood = clamp(blood, 0, max_blood)
	blood_meter.value = blood


func _physics_process(delta):
	# Passive blood drain tied to hunger (once per second)
	blood_loss_accumulator += delta

	if blood_loss_accumulator >= 1.0:
		blood_loss_accumulator -= 1.0 
		if not bat_form_active:     # keeps leftover fractional time
			blood -= hunger                    # remove blood proportional to hunger
			blood = clamp(blood, 0, max_blood)
			blood_meter.value = blood
	# Timers
	if bite_timer > 0.0:
		bite_timer -= delta
	if claw_timer > 0.0:
		claw_timer -= delta
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
	if bat_cooldown_timer > 0.0:
		bat_cooldown_timer -= delta

	# -------------------------
	# BAT IFRAMES TIMER
	# -------------------------
	if bat_iframes_active:
		bat_iframe_timer -= delta
		sprite_bat.visible = int(Time.get_ticks_msec() / 100) % 2 == 0  # blink

		if bat_iframe_timer <= 0:
			bat_iframes_active = false
			sprite_bat.visible = true
			print("BAT IFRAMES ENDED")
	
	# Input movement
	
	var input_direction = Vector2.ZERO
	if not is_immobilized:
		input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if input_direction != Vector2.ZERO:
			last_facing = input_direction.normalized()



		# --- DASH ---
		if is_dashing:
			velocity = dash_direction * dash_speed
			dash_timer -= delta
			$DashArea.monitoring = true

			for body in $DashArea.get_overlapping_bodies():
				if (body.is_in_group("enemies") or body.is_in_group("final_boss")) and body not in dash_hit_enemies:
					if body.has_method("take_damage"):
						if GlobalData.purchased_skills["blood_frenzy_best_dash"] and body.health <= 40:
							print("Dash Execute! Enemy killed instantly.")
							body.take_damage(9999, "dash_execute")
						else:
							body.take_damage(dash_damage)
						dash_hit_enemies.append(body)

			if dash_timer <= 0.0:
				is_dashing = false
				dash_hit_enemies.clear()
				$DashArea.monitoring = false
		else:
			if Input.is_action_just_pressed("dash") and cooldown_timer <= 0.0 and blood >= dash_cost  and not bat_form_active:
				is_dashing = true
				dash_direction = input_direction if input_direction != Vector2.ZERO else last_facing
				dash_timer = dash_duration
				cooldown_timer = dash_cooldown
				blood -= dash_cost
				blood_meter.value = blood
			else:
				velocity = input_direction * speed
	else:
		velocity = Vector2.ZERO
	# --- NEW CONTROL SCHEME ---
	# Space = CLAW attack
	if Input.is_action_just_pressed("claw") and (not bat_form_active or GlobalData.purchased_skills["bat_claw"]):
		_do_claw(last_facing)

	# C = BITE attack
	if Input.is_action_just_pressed("bite") and (not bat_form_active or GlobalData.purchased_skills["bat_bite"]):
		_do_bite(last_facing)


	# Player dies
	if blood <= 0:
		_on_player_death()

	# Bat Form
	if GlobalData.purchased_skills["bat_form"]:
		if Input.is_action_just_pressed("bat_form") \
			and not bat_form_active \
			and bat_cooldown_timer <= 0.0:
				_activate_bat_form()
				
				

	
	_apply_blood_bond_skills()
	_apply_blood_frenzy_skills()
	if bat_form_active:
		speed *= 3
	_update_sprite_direction(input_direction)

	# Update hitboxes to always face correct direction
	var dir = input_direction.normalized() if input_direction != Vector2.ZERO else last_facing
	bite_area.position = dir * 16
	bite_area.rotation = dir.angle()
	claw_area.position = dir * 16
	claw_area.rotation = dir.angle()

	move_and_slide()



# --- Bite Attack ---
func _do_bite(direction: Vector2):
	if bite_timer > 0.0:
		bite_sprite.modulate = Color(1,0,0)
		bite_sprite.visible = true
		await get_tree().create_timer(0.2).timeout
		bite_sprite.visible = false
		bite_sprite.modulate = Color(1,1,1)
		return

	bite_timer = bite_cooldown

	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	bite_area.position = direction.normalized() * 16
	bite_area.rotation = direction.angle()
	bite_area.player = self
	bite_area.bite_damage = bite_damage
	bite_area.monitoring = true
	
	bite_sprite.visible = true
	bite_sprite.play("default")
	bite_sprite.flip_h = direction.x < 0
	bite_sprite.rotation = direction.angle()

	await get_tree().create_timer(0.1).timeout

	for body in bite_area.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			if GlobalData.purchased_skills["blood_bond"]:
				_convert_enemy_to_ally(body)
				bonded_enemy = body
			elif body.has_method("take_damage"):
				body.take_damage(bite_damage, "bite")
		if body.is_in_group("final_boss"):
			body.take_damage(bite_damage, "bite")

	bite_area.monitoring = false



func _do_claw(direction: Vector2):
	# --- CLAW COOLDOWN ---
	if claw_timer > 0.0:
		# Flash the claw sprite to show “on cooldown”
		claw_sprite.modulate = Color(1, 0, 0)
		claw_sprite.visible = true
		await get_tree().create_timer(0.15).timeout
		claw_sprite.visible = false
		claw_sprite.modulate = Color(1, 1, 1)
		return

	claw_timer = claw_cooldown

	# Attack direction fallback
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	claw_area.position = direction.normalized() * 16
	claw_area.rotation = direction.angle()
	claw_area.player = self

	claw_sprite.visible = true
	claw_sprite.play("new_animation")
	claw_sprite.flip_h = direction.x < 0
	claw_sprite.rotation = direction.angle()

	claw_area.monitoring = true
	await get_tree().create_timer(0.1).timeout

	for body in claw_area.get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(claw_damage, "claw")
		if body.is_in_group("final_boss"):
			body.take_damage(claw_damage, "claw")

	claw_area.monitoring = false


# --- Bat Form ---
func _activate_bat_form():
	
	bat_form_active = true
	$BatArea.monitoring = true
	var original_speed = base_speed
	var original_hunger = hunger

	speed = 3 * base_speed  # Increase speed in bat form
	hunger = 0  # Bat form doesn't drain hunger

	# -------------------------
	# BAT IFRAMES (FIRST 2 SECS)
	# -------------------------
	if GlobalData.purchased_skills["bat_iframes"]:
		bat_iframes_active = true
		bat_iframe_timer = 2.0
		print("BAT IFRAMES ACTIVE (2s)")

	# Hide human sprites
	sprite_down.visible = false
	sprite_up.visible = false
	sprite_side.visible = false
	sprite_move_down.visible = false
	sprite_move_side.visible = false
	sprite_move_up.visible = false
	
	# --- SHOW BAT SPRITE ---
	sprite_bat.visible = true
	if sprite_bat.has_method("play"):
		sprite_bat.play("default")  # Play bat animation

	# Trigger bat_max effect once on first transformation into bat form

	if GlobalData.purchased_skills["bat_max"]:
		var bodies = $BatArea.get_overlapping_bodies()
		print("BAT MAX check: bodies overlapping:", bodies.size())
		for body in bodies:
			print("Checking body:", body, "in group 'enemies'? ->", body.is_in_group("enemies"), "has take_damage? ->", body.has_method("take_damage"), "is_inside_tree? ->", body.is_inside_tree())
			if body.is_in_group("enemies") and body.has_method("take_damage") and body.is_inside_tree():
				print("BAT MAX: applying damage to", body.name)
				body.take_damage(40, "bat_drain")
				blood += 20
				blood = clamp(blood, 0, max_blood)
				blood_meter.value = blood
		
	
	await get_tree().create_timer(5.0).timeout  # Bat form lasts for 5 seconds

	# -------------------------
	# EXIT BAT FORM
	# -------------------------
	speed = original_speed  # Restore original speed
	hunger = original_hunger  # Restore original hunger
	bat_form_active = false
	bat_cooldown_timer = bat_cooldown
	
	# Hide bat sprite after leaving bat form
	sprite_bat.visible = false
	if sprite_bat.has_method("stop"):
		sprite_bat.stop()
	
	

	# Restore standard direction sprite
	_update_sprite_direction(Vector2.DOWN)




func _convert_enemy_to_ally(enemy):
	var allies = _get_alive_allies()
	if allies.size() >= max_allies:
		print("Max allies reached:", max_allies)
		return
	if !enemy or !enemy.is_inside_tree():
		return
	
	if enemy.has_method("convert_to_ally"):
		enemy.convert_to_ally(self)
		enemy.health = 150
		enemy.speed = 500
		if enemy.has_method("set_velocity"):
			enemy.set_velocity(Vector2.ZERO)
		elif "velocity" in enemy:
			enemy.velocity = Vector2.ZERO

		if "current_target" in enemy:
			enemy.current_target = null
		if "target_enemy" in enemy:
			enemy.target_enemy = null


func _update_sprite_direction(input_direction: Vector2):
	# --- BAT FORM ---
	if bat_form_active:
		sprite_down.visible = false
		sprite_up.visible = false
		sprite_side.visible = false

		var facing = input_direction if input_direction != Vector2.ZERO else last_facing
		if facing.x != 0:
			sprite_bat.flip_h = facing.x > 0
		return

	# Hide all sprites first
	sprite_down.visible = false
	sprite_up.visible = false
	sprite_side.visible = false

	sprite_move_down.visible = false
	sprite_move_up.visible = false
	sprite_move_side.visible = false

	var moving = input_direction != Vector2.ZERO
	var facing = input_direction if moving else last_facing

	# --- MOVING ---
	if moving:
		if facing.y < -0.5:
			sprite_move_up.visible = true
			_play_if_not(sprite_move_up)
		elif facing.y > 0.5:
			sprite_move_down.visible = true
			_play_if_not(sprite_move_down)
		elif abs(facing.x) > 0:
			sprite_move_side.visible = true
			sprite_move_side.flip_h = facing.x < 0
			_play_if_not(sprite_move_side)

	# --- IDLE ---
	else:
		if last_facing.y < -0.5:
			sprite_up.visible = true
		elif last_facing.y > 0.5:
			sprite_down.visible = true
		elif abs(last_facing.x) > 0:
			sprite_side.visible = true
			sprite_side.flip_h = last_facing.x < 0
		else:
			sprite_down.visible = true


func _on_bite_animation_finished():
	bite_sprite.stop()
	bite_sprite.visible = false

func _on_claw_animation_finished():
	claw_sprite.stop()
	claw_sprite.visible = false
	claw_area.monitoring = false

func _play_if_not(sprite: AnimatedSprite2D):
	if not sprite.is_playing():
		sprite.play()
		
func _on_player_death():
	GlobalData.kill_count = 0
	for skill in GlobalData.purchased_skills.keys():
		GlobalData.purchased_skills[skill] = false
	get_tree().change_scene_to_file("res://DeathScreen.tscn")


func _flash_damage():
	# Abort if scene is unloading
	if not is_inside_tree():
		return

	var flash_color = Color(1, 0, 0)
	var normal_color = Color(1, 1, 1)

	# Flash STATIC sprites
	sprite_down.modulate = flash_color
	sprite_up.modulate = flash_color
	sprite_side.modulate = flash_color

	# Flash MOVE sprites
	sprite_move_down.modulate = flash_color
	sprite_move_up.modulate = flash_color
	sprite_move_side.modulate = flash_color
	
	sprite_bat.modulate = flash_color
	
	# Wait
	await get_tree().create_timer(0.15).timeout

	# Abort if destroyed mid-await
	if not is_instance_valid(self):
		return

	# Restore NORMAL sprites
	sprite_down.modulate = normal_color
	sprite_up.modulate = normal_color
	sprite_side.modulate = normal_color

	sprite_move_down.modulate = normal_color
	sprite_move_up.modulate = normal_color
	sprite_move_side.modulate = normal_color
	
	sprite_bat.modulate = normal_color
	
func can_take_damage(damage_type: String) -> bool:
	# Bat iframes
	if bat_iframes_active:
		return false

	# Bat melee immunity skill
	if bat_form_active and damage_type == "melee":
		if GlobalData.purchased_skills.get("bat_melee", false):
			return false

	# Max bat form = full immunity
	if bat_form_active and GlobalData.purchased_skills.get("bat_form_max", false):
		return false
	
	return true
	
func _apply_blood_frenzy_skills():
	#bat form multipliers since this is called every frame
	if bat_form_active:
		bite_damage *= base_bat_bite_multiplier
		claw_damage *= base_bat_claw_multiplier
		claw_cooldown *= base_bat_claw_cooldown_multiplier
	# Reset to base values FIRST
	claw_cooldown = base_claw_cooldown
	dash_cost = base_dash_cost
	speed = base_speed
	bite_damage = base_bite_damage
	hunger = base_hunger
	max_blood = 100

	# -------------------------
	# BASE: Blood Frenzy
	# -------------------------
	if GlobalData.purchased_skills["blood_frenzy"]:
		bite_damage *= 2
		hunger *= 2
		

	# -------------------------
	# BETTER CLAW
	# -------------------------
	if GlobalData.purchased_skills["blood_frenzy_better_claw"]:
		claw_cooldown *= 0.9   # 10% faster
		hunger += 4
		

	# -------------------------
	# BEST CLAW
	# -------------------------
	if GlobalData.purchased_skills["blood_frenzy_best_claw"]:
		claw_cooldown *= 0.8   # 20% faster total
		hunger += 6

	# -------------------------
	# BETTER DASH
	# -------------------------
	if GlobalData.purchased_skills["blood_frenzy_better_dash"]:
		dash_damage *= 1.25
		dash_cost *= 1.30
	

	# -------------------------
	# BEST DASH
	# -------------------------
	if GlobalData.purchased_skills["blood_frenzy_best_dash"]:
		dash_cost *= 1.05


	# -------------------------
	# MAX BLOOD FRENZY
	# -------------------------
	if GlobalData.purchased_skills["blood_frenzy_max"]:
		speed *= 1.2
		bite_damage *= 1.15
		max_blood *= 0.9
		
func _apply_blood_bond_skills():
	var allies = _get_alive_allies()
	var ally_count := allies.size()

	# -------------------------
	# RESET BASE
	# -------------------------
	max_allies = base_max_allies
	var bonus_bite_damage := 0
	var damage_reduction := 0.0

	# -------------------------
	# SECOND DPS
	# -------------------------
	if GlobalData.purchased_skills["blood_bond_second_dps"]:
		max_allies = 2
		for ally in allies:
			ally.ally_attack_damage = int(ally.ally_attack_damage * 1.3)
		print("Blood Bond DPS 2:")
		print("  max_allies =", max_allies)

	# -------------------------
	# THIRD DPS
	# -------------------------
	if GlobalData.purchased_skills["blood_bond_third_dps"]:
		max_allies = 3
		bonus_bite_damage = int(ally_count * 0.05 * bite_damage)
		bite_damage += bonus_bite_damage
		print("Blood Bond DPS 3:")
		print("  ally_count =", ally_count)
		print("  bite_damage =", bite_damage)

	# -------------------------
	# SECOND TANK
	# -------------------------
	if GlobalData.purchased_skills["blood_bond_second_tank"]:
		max_allies = 2
		for ally in allies:
			ally.health = int(ally.health * 1.3)
		print("Blood Bond Tank 2:")
		print("  max_allies =", max_allies)

	# -------------------------
	# THIRD TANK
	# -------------------------
	if GlobalData.purchased_skills["blood_bond_third_tank"]:
		max_allies = 3
		damage_reduction = ally_count * 0.02
		print("Blood Bond Tank 3:")
		print("  damage reduction =", damage_reduction * 100, "%")

	# -------------------------
	# MAX BLOOD BOND (SUPER ALLY)
	# -------------------------
	if GlobalData.purchased_skills["blood_bond_max"]:
		if super_ally == null or not is_instance_valid(super_ally):
			if allies.size() > 0:
				super_ally = allies[0]
				super_ally.modulate = Color(0.2, 0.8, 0.2)
				super_ally.health *= 1.5
				super_ally.ally_attack_damage *= 1.5
				super_ally.speed *= 1.3

func _get_alive_allies() -> Array:
	# SAFETY: node may be exiting the tree
	if not is_inside_tree():
		return []

	var tree := get_tree()
	if tree == null:
		return []

	var allies := []
	for n in tree.get_nodes_in_group("allies"):
		if is_instance_valid(n):
			allies.append(n)
	return allies
