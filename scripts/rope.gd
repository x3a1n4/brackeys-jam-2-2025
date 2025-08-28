extends Node2D

@export_category("Controls")
@export var maxSegmentLength : int = 10

@export_category("Variables")
@export var slack : bool = false
@export var startPoint : Vector2
@export var endPoint : Vector2
@export var canAddLength : bool = true

@onready var segment : RopeSegment2D = $Segment
@onready var lastSegment : RopeSegment2D = segment

@onready var startCollider : StaticBody2D = $Start
@onready var endCollider : StaticBody2D = $End

@export_category("Exports")
@export var collisionPoint : Vector2 = Vector2.ZERO
# process: create a long rigid body with pin joint 
# at collision, make a new one

var points : Array[RopeSegment2D] = []

func getJoint(segment : RopeSegment2D) -> PinJoint2D:
	return segment.get_node("PinJoint2D")

# Called when the node enters the scene tree for the first time.
func _ready():
	points.append(segment)

func _physics_process(delta):
	# update positions
	startCollider.position = startPoint
	endCollider.position = endPoint
	
	# look at endpoint (needed?)
	lastSegment.look_at(endPoint)
	
	# if can't reach the endPoint, continuously add segments
	if getJoint(lastSegment).global_position.distance_to(endPoint) < maxSegmentLength:
		pass
	elif canAddLength:
		# store last added segment
		var prev : RopeSegment2D = lastSegment
		# duplicate
		lastSegment = segment.duplicate()
		add_child(lastSegment)
		lastSegment.global_position = getJoint(prev).global_position
		lastSegment.look_at(endPoint)
		
		# update pin joints
		getJoint(prev).node_b = lastSegment.get_path()
		getJoint(prev).softness = 0
		getJoint(lastSegment).node_b = endCollider.get_path()
		getJoint(lastSegment).softness = 0.4
		
		# add to list 
		points.append(lastSegment)
	
	# draw end line
	# note: can instead just draw a line of all the points
	var linePoints : Array[Vector2] = []
	for rb in points:
		linePoints.append(rb.position)
	linePoints.append(to_local(endPoint))
	$DrawLine.points = PackedVector2Array(linePoints)
