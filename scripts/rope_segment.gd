class_name RopeSegment2D

extends Node2D

@export var slack : bool = false
@export var rope_curve : Curve
@export var slack_curve : Curve
@export var curve_mult : float = 30
# The number of samples for drawing the line
@export var line_samples : int = 10

var startPos : Vector2
# The start point of the segment, global position
var targetStartPos : Vector2

var endPos : Vector2
# The end point of the segment, global position
var targetEndPos : Vector2

var line_length : float = 0.0

const ropeSegment = preload("res://scenes/rope/rope_segment.tscn") 

func collide(collision : Dictionary):
	var splitPoint : Vector2 = collision.position
	# var splitNormal : Vector2 = collision.normal
	
	# set segment one to be between the two
	var static_segment = ropeSegment.instantiate()
	static_segment.startPos = startPos
	static_segment.endPos = splitPoint
	get_parent().add_child(static_segment)
	
	# set segment two to go to the player
	targetStartPos = splitPoint

# TODO: add drawing and animation for hanging rope
func _process(_delta):	
	var points : Array[Vector2] = []
	for i in line_samples + 1:
		var per : float = float(i) / line_samples
		var loc : Vector2 = lerp(startPos, endPos, per)
		if slack:
			points.append(to_local(Vector2(0, -slack_curve.sample(per) * curve_mult) + loc))
		else:
			points.append(to_local(Vector2(0, -rope_curve.sample(per) * curve_mult) + loc))
	
	$DrawLine.points = points
	
func distance_along_line(start : Vector2, end : Vector2, sample : Vector2):
	return (sample - start).project(end - start).length() / (end - start).length()

# update position of collision
var debugstarts = []
var debugends = []

func process_physics(_delta):
	# Step 1: set up raycasts along length of segment
	var space_state = get_world_2d().direct_space_state
	line_length = startPos.distance_to(endPos)
	var iters = int(line_length / 20)
	
	var collisions : Array[Dictionary] = []
	for i in iters:
		# cast rays between lines
		var ray_start : Vector2 = lerp(startPos, endPos, float(i) / iters)
		var ray_end : Vector2 = lerp(targetStartPos, targetEndPos, float(i) / iters)
		
		# use global coordinates, not local to node
		# note: 4 is the collision mask
		var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end, 4)
		var result = space_state.intersect_ray(query)
		
		# debug draw line
		debugstarts.append(ray_start)
		debugends.append(ray_end)
		
		# result is a dictionary (https://docs.godotengine.org/en/4.4/tutorials/physics/ray-casting.html)
		if result:
			collisions.append(result)
			
	# if it collided
	if collisions:
		# filter out any too close to the start position
		collisions = collisions.filter(func(a): return startPos.distance_to(a.position) > (get_parent() as Rope2D).min_segment_length)
		
		if collisions:
			# and sort by closest to player
			collisions.sort_custom(func(a, b): return endPos.distance_to(a.position) < endPos.distance_to(b.position))
			
			collide(collisions[0])
	
	# update position
	startPos = targetStartPos
	endPos = targetEndPos
	
	queue_redraw()
