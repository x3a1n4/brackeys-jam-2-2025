class_name Rope2D

extends Node2D

@export_category("Controls")
@export var min_segment_length : int = 10

@export_category("Variables")
@export var slack : bool = false
@export var startPoint : Vector2
@export var endPoint : Vector2

@onready var lastSegment : RopeSegment2D = $Segment

func _ready():
	lastSegment.startPos = startPoint
	lastSegment.targetStartPos = startPoint

func _physics_process(delta):
	# Step 1: update positions
	lastSegment.targetEndPos = endPoint
	lastSegment.process_physics(delta)
	# gets a y of 0 for some reason?
