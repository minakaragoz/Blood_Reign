extends Control
signal skill_purchased

@export var blood_frenzy_cost := 10
@export var blood_bond_cost := 10
@export var bat_form_cost := 10

@onready var frenzy_button = $Panel/BloodFrenzy
@onready var bond_button = $Panel/BloodBond
@onready var bat_button = $Panel/BatForm
@onready var close_button = $Panel/CloseButton

@onready var bestclaw = $Panel/BestClaw
@onready var betterclaw = $Panel/BetterClaw
@onready var betterdash = $Panel/BetterDash
@onready var bestdash = $Panel/BestDash
@onready var frenzy_max = $Panel/Max_Frenzy

@onready var bat_iframes = $Panel/BatIframes
@onready var bat_bite = $Panel/BatBite
@onready var bat_claw = $Panel/BatClaw
@onready var bat_melee = $Panel/BatMelee
@onready var bat_max = $Panel/Max_Bat

@onready var second_dps = $Panel/SecondDPS
@onready var third_dps = $Panel/ThirdDPS
@onready var second_tank = $Panel/SecondTank
@onready var third_tank = $Panel/ThirdTank
@onready var bond_max = $Panel/Max_Bond


func _ready():
	frenzy_button.pressed.connect(func(): emit_signal("skill_purchased", "blood_frenzy", blood_frenzy_cost))
	bond_button.pressed.connect(func(): emit_signal("skill_purchased", "blood_bond", blood_bond_cost))
	bat_button.pressed.connect(func(): emit_signal("skill_purchased", "bat_form", bat_form_cost))
	
	bestclaw.pressed.connect(func(): emit_signal("skill_purchased", "blood_frenzy_best_claw", bat_form_cost))
	betterclaw.pressed.connect(func(): emit_signal("skill_purchased", "blood_frenzy_better_claw", bat_form_cost))
	bestdash.pressed.connect(func(): emit_signal("skill_purchased", "blood_frenzy_best_dash", bat_form_cost))
	betterdash.pressed.connect(func(): emit_signal("skill_purchased", "blood_frenzy_better_dash", bat_form_cost))
	frenzy_max.pressed.connect(func(): emit_signal("skill_purchased", "blood_frenzy_max", bat_form_cost))
	
	bat_iframes.pressed.connect(func(): emit_signal("skill_purchased", "bat_iframes", bat_form_cost))
	bat_bite.pressed.connect(func(): emit_signal("skill_purchased", "bat_bite", bat_form_cost))
	bat_claw.pressed.connect(func(): emit_signal("skill_purchased", "bat_claw", bat_form_cost))
	bat_melee.pressed.connect(func(): emit_signal("skill_purchased", "bat_melee", bat_form_cost))
	bat_max.pressed.connect(func(): emit_signal("skill_purchased", "bat_max", bat_form_cost))
	
	second_dps.pressed.connect(func(): emit_signal("skill_purchased", "blood_bond_second_dps", blood_bond_cost))
	third_dps.pressed.connect(func(): emit_signal("skill_purchased", "blood_bond_third_dps", blood_bond_cost))
	second_tank.pressed.connect(func(): emit_signal("skill_purchased", "blood_bond_second_tank", blood_bond_cost))
	third_tank.pressed.connect(func(): emit_signal("skill_purchased", "blood_bond_third_tank", blood_bond_cost))
	bond_max.pressed.connect(func(): emit_signal("skill_purchased", "blood_bond_max", blood_bond_cost))

	
	close_button.pressed.connect(_on_close_pressed)

func _on_close_pressed():
	visible = false
	get_tree().paused = false
