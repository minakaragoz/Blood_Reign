extends Control

@export var trigger_threshold := 40.0   # yüzde 40'tan itibaren başlasın
@export var max_alpha := 0.8            # en fazla bu kadar kırmızı
@export var fade_speed := 2.0           # geçiş hızı
@export var edge_thickness := 120       # kenar kalınlığı
@export var edge_color := Color(0.4, 0, 0, 0)  # 🍷 vişne kırmızısı

var blood_bar: ProgressBar
var flash_rects := []
var current_alpha := 0.0


func _ready():
	blood_bar = get_tree().root.find_child("ProgressBar", true, false)
	
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1

	_create_edge_overlay()
	set_process(true)


func _create_edge_overlay():
	var sides = ["top", "bottom", "left", "right"]
	for side in sides:
		var rect = ColorRect.new()
		rect.color = edge_color
		rect.name = side

		match side:
			"top":
				rect.anchor_top = 0
				rect.anchor_bottom = 0
				rect.offset_top = 0
				rect.offset_bottom = edge_thickness
				rect.anchor_left = 0
				rect.anchor_right = 1
			"bottom":
				rect.anchor_top = 1
				rect.anchor_bottom = 1
				rect.offset_top = -edge_thickness
				rect.offset_bottom = 0
				rect.anchor_left = 0
				rect.anchor_right = 1
			"left":
				rect.anchor_left = 0
				rect.anchor_right = 0
				rect.offset_left = 0
				rect.offset_right = edge_thickness
				rect.anchor_top = 0
				rect.anchor_bottom = 1
			"right":
				rect.anchor_left = 1
				rect.anchor_right = 1
				rect.offset_left = -edge_thickness
				rect.offset_right = 0
				rect.anchor_top = 0
				rect.anchor_bottom = 1

		add_child(rect)
		flash_rects.append(rect)


func _process(delta):
	if not blood_bar:
		return

	var percent = blood_bar.value / blood_bar.max_value * 100.0

	# yüzde azaldıkça alpha artar
	var target_alpha := 0.0
	if percent < trigger_threshold:
		target_alpha = clamp((trigger_threshold - percent) / trigger_threshold, 0.0, 1.0) * max_alpha

	# smooth geçiş
	current_alpha = lerp(current_alpha, target_alpha, delta * fade_speed)

	# güncelle
	for rect in flash_rects:
		var c = edge_color
		c.a = current_alpha
		rect.color = c
