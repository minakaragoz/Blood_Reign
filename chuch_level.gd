extends Node2D

@onready var win_label = $CanvasLayer/WinLabel
@onready var enemy_scene = preload("res://characters/Priest.tscn")
@onready var kill_label = $CanvasLayer/SoulCounter
@onready var skill_tree = $CanvasLayer/SkillTreeUI

@export var max_enemies := 20

# HARD LOCK to prevent double transitions
var transitioning := false


func _ready():
	# Reset state when level loads
	GlobalData.kill_count = 0
	transitioning = false
	$AudioStreamPlayer2D.finished.connect(func():$AudioStreamPlayer2D.play())
		
		
	_update_kill_label()
	skill_tree.skill_purchased.connect(_on_skill_purchased)
	skill_tree.visible = false

	# Initial spawns
	for i in range(7):
		spawn_enemy(_get_random_spawn_pos())

	# Optional: cache player if needed later
	var player = get_node("Player(Trial)")


func spawn_enemy(pos: Vector2):
	if transitioning:
		return

	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.position = pos

	# Connect death signal safely
	if enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_died)


func _get_random_spawn_pos() -> Vector2:
	return Vector2(
		randf_range(-2200, 2200),
		randf_range(-1200, 1200)
	)


func _on_enemy_died():
	if transitioning:
		return

	GlobalData.kill_count += 1
	_update_kill_label()
	print("Kill count:", GlobalData.kill_count)

	# === FINAL BOSS TRIGGER ===
	if GlobalData.kill_count >= max_enemies:
		transitioning = true
		print("FINAL BOSS TRIGGERED")

		var tree := get_tree()
		if tree == null:
			return

		# Freeze & remove all remaining enemies safely
		for e in tree.get_nodes_in_group("enemies"):
			if is_instance_valid(e):
				e.set_process(false)
				e.set_physics_process(false)
				e.call_deferred("queue_free")

		# Change to final boss scene (once)
		tree.call_deferred(
			"change_scene_to_file",
			"res://final_level.tscn"
		)
		return

	# Spawn replacement enemy ONLY if under max
	call_deferred("spawn_enemy", _get_random_spawn_pos())


func _update_kill_label():
	kill_label.text = "Souls: %d" % GlobalData.kill_count


func _process(_delta):
	if Input.is_action_just_pressed("skillTree"):
		_toggle_skill_tree()


func _toggle_skill_tree():
	if skill_tree.visible:
		skill_tree.visible = false
		get_tree().paused = false
	else:
		skill_tree.visible = true
		get_tree().paused = true


func _on_skill_purchased(skill_name: String, cost: int):
	if GlobalData.kill_count >= cost and !GlobalData.purchased_skills[skill_name]:
		GlobalData.kill_count -= cost
		GlobalData.purchased_skills[skill_name] = true
		_update_kill_label()
	else:
		print("Not enough souls or already owned")


func _win_game():
	print("You Win!")
	win_label.text = "YOU WIN!"
	win_label.visible = true
	get_tree().paused = true


func _on_player_died():
	for key in GlobalData.purchased_skills.keys():
		GlobalData.purchased_skills[key] = false
	get_tree().change_scene_to_file("res://DeathScreen.tscn")
