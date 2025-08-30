class_name HangingRope2D

extends Line2D

@export var rope_curve : Curve
@export var curve_mult = 50
@export var line_samples = 50
@export var start_node : Node2D
@export var end_node : Node2D

func _process(_delta):	
	clear_points()
	
	for i in line_samples + 1:
		var per : float = float(i) / line_samples
		var loc : Vector2 = lerp(start_node.global_position, end_node.global_position, per)

		add_point(to_local(Vector2(0, -rope_curve.sample(per) * curve_mult) + loc))
	
