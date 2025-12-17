extends Node2D
@onready var kill_label = $CanvasLayer/SoulCounter
@onready var skill_tree = $CanvasLayer/SkillTreeUI
@onready var enemy_scene = preload("res://characters/villager.tscn")

var transitioning := false

func _ready():
	$Music.finished.connect(func():$Music.play())
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.has_signal("enemy_died"):
			e.enemy_died.connect(_on_enemy_died)
	var boss = get_tree().get_first_node_in_group("final_boss")
	if boss and boss.has_signal("boss_died"):
		boss.boss_died.connect(_on_boss_died)
	_update_kill_label()
	skill_tree.skill_purchased.connect(_on_skill_purchased)
	skill_tree.visible = false
	var player = get_node("Player(Trial)")  # player node
	

func _on_boss_died():
	var tree := get_tree() 
	if tree == null: return
	print("PLAYER WON THE GAME")
	
	tree.call_deferred( "change_scene_to_file", "res://ending.tscn" )
	
func _on_enemy_died():
	if transitioning:
		return

	GlobalData.kill_count += 1
	_update_kill_label()
	print("Kill count:", GlobalData.kill_count)

	# Spawn replacement enemy ONLY if under max
	call_deferred("spawn_enemy", _get_random_spawn_pos())



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

func _on_player_died():
		for key in GlobalData.purchased_skills.keys():
			GlobalData.purchased_skills[key] = false
		get_tree().change_scene_to_file("res://DeathScreen.tscn")
		
func _get_random_spawn_pos() -> Vector2:
	return Vector2(
		randf_range(-2200, 2200),
		randf_range(-1200, 1200)
	)
	
func spawn_enemy(pos: Vector2):
	if transitioning:
		return

	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.position = pos

	# Connect death signal safely
	if enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_died)
