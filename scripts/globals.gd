extends Node

# these are the globals!
var risk : float = 0
var length : int = 2
var max_risk : int = 10

var lights_on : bool = false

var num_nodes : int = 0
var num_deaths : int = 0
var died : bool = false

var dialogue : Resource = load("res://dialogue/main.dialogue")

var transition_rect: ColorRect

var must_use_max_risk : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	var layer := CanvasLayer.new()
	add_child(layer)
	
	transition_rect = ColorRect.new()
	transition_rect.color = Color.BLACK
	transition_rect.size = get_viewport().get_visible_rect().size
	transition_rect.position.x = -transition_rect.size.x
	layer.add_child(transition_rect)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Show the risk popup in home_scene
func show_risk_popup():
	await get_tree().get_nodes_in_group("home scene")[0].show_risk_popup()

# Show the risk popup in home_scene
func turn_on_lights():
	await get_tree().get_nodes_in_group("home scene")[0].turn_on_lights()

func fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(transition_rect, "position:x", 0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN) # 0.5 sec fade in
	await tween.finished

func fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(transition_rect, "position:x", transition_rect.size.x, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) # 0.5 sec fade out
	await tween.finished
	transition_rect.position.x = -transition_rect.size.x
	
func change_scene_with_wipe(path: String) -> void:
	# Fade to black
	await fade_in()
	await get_tree().process_frame
	await get_tree().process_frame
	# Change scene
	get_tree().change_scene_to_file(path)
	# Wait one frame so the new scene actually enters the tree
	await get_tree().process_frame
	await get_tree().process_frame
	# Now fade back out
	await fade_out()
	
func enter_platforming():
	died = false
	change_scene_with_wipe("res://scenes/platforming.tscn")

func enter_home():
	change_scene_with_wipe("res://scenes/home_scene.tscn")
