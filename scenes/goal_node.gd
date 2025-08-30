class_name GoalNode

extends Node2D

@export var position_curve : Curve
@export var position_mult : float = 20
@onready var attach_point : Vector2 = $"Rope Attach".global_position
@onready var orig_point : Vector2 = $"Rope Attach".global_position

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$"Rope Attach".global_position = orig_point + Vector2.DOWN * position_curve.sample($Position.time_left / $Position.wait_time) * position_mult
	attach_point = $"Rope Attach".global_position
