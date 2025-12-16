extends Node2D
@onready var win_label = $CanvasLayer/WinLabel
@onready var enemy_scene = preload("res://characters/Priest.tscn")
@onready var kill_label = $CanvasLayer/SoulCounter
@onready var skill_tree = $CanvasLayer/SkillTreeUI
@export var max_enemies := 60


func _ready():
	_update_kill_label()
	skill_tree.skill_purchased.connect(_on_skill_purchased)
	spawn_enemy(_get_random_spawn_pos())
	spawn_enemy(_get_random_spawn_pos())
	spawn_enemy(_get_random_spawn_pos())
	spawn_enemy(_get_random_spawn_pos())
	spawn_enemy(_get_random_spawn_pos())
	spawn_enemy(_get_random_spawn_pos())
	skill_tree.visible = false
	var player = get_node("Player(Trial)")  # player node


func spawn_enemy(pos: Vector2):
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.position = pos


func _get_random_spawn_pos() -> Vector2:
	return Vector2(randf_range(-2200, 2200), randf_range(-1200, 1200))

func _on_enemy_died():
	GlobalData.kill_count += 1
	_update_kill_label()
	call_deferred("spawn_enemy", _get_random_spawn_pos())
	call_deferred("spawn_enemy", _get_random_spawn_pos())
	if GlobalData.kill_count >= max_enemies:
		var tree := get_tree()
		if tree == null:
			return

		# Safely free remaining enemies
		for e in tree.get_nodes_in_group("enemies"):
			if is_instance_valid(e):
				e.call_deferred("queue_free")

		# Change scene deferred to avoid tree teardown crash
		tree.call_deferred(
			"change_scene_to_file",
			"res://Levels/church_level.tscn"
		)
func _update_kill_label():
	kill_label.text = "Souls: %d" % GlobalData.kill_count

func _process(_delta):
	if Input.is_action_just_pressed("skillTree"): # for example, Z
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
