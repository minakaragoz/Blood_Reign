extends Control
signal skill_purchased

@export var blood_frenzy_cost := 10
@export var blood_bond_cost := 10
@export var bat_form_cost := 10

@onready var frenzy_button = $Panel/BloodFrenzy
@onready var bond_button = $Panel/BloodBond
@onready var bat_button = $Panel/BatForm
@onready var close_button = $Panel/CloseButton

func _ready():
	frenzy_button.pressed.connect(func(): emit_signal("skill_purchased", "blood_frenzy", blood_frenzy_cost))
	bond_button.pressed.connect(func(): emit_signal("skill_purchased", "blood_bond", blood_bond_cost))
	bat_button.pressed.connect(func(): emit_signal("skill_purchased", "bat_form", bat_form_cost))
	close_button.pressed.connect(_on_close_pressed)

func _on_close_pressed():
	visible = false
	get_tree().paused = false
