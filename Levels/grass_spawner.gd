extends Node2D

@export var grass_scene: PackedScene = preload("res://GrassGenerate/grass_random.tscn")
@export var grass_count := 300
@export var spawn_range_x := 600.0
@export var spawn_range_y := 400.0

func _ready():
	for i in range(grass_count):
		var g = grass_scene.instantiate()
		g.position = Vector2(
			randf_range(-spawn_range_x, spawn_range_x),
			randf_range(-spawn_range_y, spawn_range_y)
		)
		g.scale = Vector2(1, 1) # zorunlu güvenlik
		add_child(g)
