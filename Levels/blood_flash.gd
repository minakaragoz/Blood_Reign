extends Control

@export var trigger_threshold := 40.0   # yüzde 40'tan itibaren başlasın
@export var max_alpha := 0.6            # en fazla bu kadar kırmızı
@export var fade_speed := 2.0           # geçiş hızı
@export var edge_thickness := 150       # kenar kalınlığı
@export var edge_color := Color(0.4, 0, 0, 0)  # 🍷 vişne kırmızısı

var blood_bar: ProgressBar
var flash_rects: Array[TextureRect] = []
var current_alpha := 0.0




func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	set_process_unhandled_input(false)
	blood_bar = get_tree().root.find_child("ProgressBar", true, false)
	
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1

	_create_soft_edges()
	set_process(true)


func _create_soft_edges():
	var sides = ["top", "bottom", "left", "right"]
	for side in sides:
		var rect := TextureRect.new()
		rect.name = side
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.anchor_left = 0
		rect.anchor_top = 0
		rect.anchor_right = 1
		rect.anchor_bottom = 1

		var gradient := Gradient.new()
		var tex := GradientTexture2D.new()
		gradient.offsets = [0.0, 1.0]
		gradient.colors = [
			Color(edge_color.r, edge_color.g, edge_color.b, 1.0),
			Color(edge_color.r, edge_color.g, edge_color.b, 0.0)
		]
		tex.gradient = gradient
		tex.width = edge_thickness

		match side:
			"top":
				rect.texture = tex
				rect.offset_top = 0
				rect.offset_bottom = edge_thickness
			"bottom":
				rect.texture = tex
				rect.offset_top = -edge_thickness
				rect.offset_bottom = 0
				rect.rotation = PI
			"left":
				var g := Gradient.new()
				g.offsets = [0.0, 1.0]
				g.colors = [
					Color(edge_color.r, edge_color.g, edge_color.b, 1.0),
					Color(edge_color.r, edge_color.g, edge_color.b, 0.0)
				]
				var t := GradientTexture2D.new()
				t.gradient = g
				t.width = edge_thickness
				rect.texture = t
				rect.rotation = -PI / 2
			"right":
				var g2 := Gradient.new()
				g2.offsets = [0.0, 1.0]
				g2.colors = [
					Color(edge_color.r, edge_color.g, edge_color.b, 1.0),
					Color(edge_color.r, edge_color.g, edge_color.b, 0.0)
				]
				var t2 := GradientTexture2D.new()
				t2.gradient = g2
				t2.width = edge_thickness
				rect.texture = t2
				rect.rotation = PI / 2

		add_child(rect)
		flash_rects.append(rect)


func _process(delta):
	if not blood_bar:
		return

	var percent := blood_bar.value / blood_bar.max_value * 100.0
	var target_alpha := 0.0
	if percent < trigger_threshold:
		target_alpha = clamp((trigger_threshold - percent) / trigger_threshold, 0.0, 1.0) * max_alpha

	current_alpha = lerp(current_alpha, target_alpha, delta * fade_speed)

	for rect in flash_rects:
		var color := rect.modulate
		color.a = current_alpha
		rect.modulate = color
