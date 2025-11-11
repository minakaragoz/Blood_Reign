extends Node2D

@export var grass_scene: PackedScene = preload("res://GrassGenerate/grass_random.tscn")
@export var grass_count: int = 800
@export var spawn_range_x: float = 2600
@export var spawn_range_y: float = 1600
@export var disappear_delay_range: Vector2 = Vector2(10, 25)

func _ready():
	spawn_grass_over_world()

func spawn_grass_over_world():
	for i in range(grass_count):
		var grass = grass_scene.instantiate()
		var x = randf_range(-spawn_range_x, spawn_range_x)
		var y = randf_range(-spawn_range_y, spawn_range_y)
		grass.position = Vector2(x, y)
		var scale_val = randf_range(0.8, 1.2)
		grass.scale = Vector2(scale_val, scale_val)
		grass.rotation = randf_range(0, TAU)
		add_child(grass)
		
		var delay = randf_range(disappear_delay_range.x, disappear_delay_range.y)
		call_deferred("_schedule_fade_out", grass, delay)

func _schedule_fade_out(grass: Node2D, delay: float):
	await get_tree().create_timer(delay).timeout
	if !grass or !grass.is_inside_tree():
		return
	var sprite := grass.get_node_or_null("Sprite2D")
	if sprite:
		var tween = get_tree().create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 2.0) # 2 saniyede fade out
		await tween.finished
	if grass and grass.is_inside_tree():
		grass.queue_free()
