class_name HomeScene

extends Control

@onready var show_risk_pos : Vector2 = get_viewport().get_visible_rect().size / 2 - $"Risk it popup".size / 2
@onready var hide_risk_pos : Vector2 = show_risk_pos + Vector2.DOWN * 2000

@export var lightsCurve : Curve

# Called when the node enters the scene tree for the first time.
func _ready():
	# DEBUG: Globals.must_use_max_risk = true
	$"Risk it popup".set_position(hide_risk_pos)
	
	# if lights off
	if not Globals.lights_on:
		$"Home Light".modulate.a = 0.0
	
	# set slider
	$"Risk it popup/HSlider".max_value = Globals.max_risk
	$"Risk it popup/HSlider".value = Globals.risk if Globals.risk < Globals.max_risk else Globals.max_risk # set 
	
	# show dialogue
	if Globals.died:
		DialogueManager.show_dialogue_balloon(Globals.dialogue, "death")
	else:
		DialogueManager.show_dialogue_balloon(Globals.dialogue, "win_inside")

func show_risk_popup():
	# tween showing window
	await create_tween().tween_property($"Risk it popup", "position", show_risk_pos, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).finished
	# tween for slider
	# set slider
	create_tween().tween_property($"Risk it popup/HSlider", "size:x", lerp(0, 337, float(Globals.max_risk) / 100), 0.5).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property($"Risk it popup/Slider Blocker", "position:x", lerp(72, 407, float(Globals.max_risk) / 100), 0.5).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property($"Risk it popup/Slider Blocker", "size:x", 407 - lerp(72, 407, float(Globals.max_risk) / 100), 0.5).set_trans(Tween.TRANS_CUBIC)

	await $"Risk it popup/Button".pressed
	
	Globals.risk = $"Risk it popup/HSlider".value

func hide_risk_popup():
	create_tween().tween_property($"Risk it popup", "position", hide_risk_pos, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN).finished

func turn_on_lights():
	print("Got here")
	$"Lights Timer".start()
	Globals.lights_on = true
	
	await $"Lights Timer".timeout
	
	# set up lights flickers
	var t = create_tween().set_loops()
	t.tween_property($"Home Light", "modulate:a", 1, 4.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property($"Home Light", "modulate:a", 0, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property($"Home Light", "modulate:a", 1, 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property($"Home Light", "modulate:a", 1, 9.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property($"Home Light", "modulate:a", 0, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property($"Home Light", "modulate:a", 1, 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# popup
	if Input.is_action_pressed("ui_accept"):
		$"Risk it popup/Button".pressed.emit()
	
	if Globals.must_use_max_risk:
		if Globals.length > 10:
			Globals.length = 10
		$"Risk it popup/HSlider".ratio = 1
	$"Risk it popup/RichTextLabel".text = "[center]Risk: %d%%[/center]" % $"Risk it popup/HSlider".value
	
	# flick on the lights
	if Globals.lights_on:
		$"Home Light".modulate.a = lightsCurve.sample(lerp(2, 0, $"Lights Timer".time_left / $"Lights Timer".wait_time))
