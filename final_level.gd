extends Node2D
@onready var kill_label = $CanvasLayer/SoulCounter
@onready var skill_tree = $CanvasLayer/SkillTreeUI
@export var max_enemies := 30


func _ready():
	$Music.finished.connect(func():$Music.play())
	_update_kill_label()
	skill_tree.skill_purchased.connect(_on_skill_purchased)
	skill_tree.visible = false
	var player = get_node("Player(Trial)")  # player node



func _on_enemy_died():
	GlobalData.kill_count += 1
	_update_kill_label()


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
