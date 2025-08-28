extends CharacterBody2D

@export_category("Params")
@export var GLOBAL_MULT = 400

@export var ground_curve: Curve
@export var air_curve: Curve

@export var jump_curve: Curve
@export var jump_time = 0.2
@onready var jump_timer : Timer = $"Timers/Jump Timer"

@export var max_jump_count = 2
var jump_count = max_jump_count

@export var fall_curve: Curve
@export var fall_time = 0.2
@onready var fall_timer : Timer = $"Timers/Fall Timer"

@export var wall_slide_curve: Curve
@export var wall_slide_time = 0.2
@onready var wall_slide_timer : Timer = $"Timers/Wall Slide Timer"
var was_on_wall : bool = false

@onready var animationTree : AnimationTree = $AnimationTree
@onready var animationStateMachinePlayback : AnimationNodeStateMachinePlayback = animationTree.get("parameters/playback")

func sampleSymCurve(curve : Curve, sample : float):
	if sample < 0:
		return -curve.sample(-sample)
	return curve.sample(sample)

# TODO: bug when you run into walls
var wall_side = Vector2(0, 0)
func _physics_process(delta):
	# step one: get inputs
	var input_direction : float = Input.get_axis("Player_Left", "Player_Right")
	var input_jump : bool = Input.is_action_just_pressed("Player_Jump")
	var input_dash : bool = Input.is_action_pressed("Player_Dash")
	var input_dash_release : bool = Input.is_action_just_released("Player_Dash")
	var input_hold : bool = Input.is_action_pressed("Player_Hold")
	
	# handle jump logic here, why not? TODO: move somewhere better
	var is_jumpting : bool = false
	if input_jump and jump_count > 0:
		is_jumpting = true
		jump_count -= 1
		jump_timer.start(jump_time)
	# start wall timer
	
	if is_on_wall_only() and !was_on_wall:
		wall_slide_timer.start(wall_slide_time)
		wall_side = Vector2.LEFT if (get_slide_collision(0).get_position() - position).x > 0 else Vector2.RIGHT
		was_on_wall = true
	
	# step two: set AnimationTree flags
	animationTree.set("parameters/conditions/ground", is_on_floor())
	animationTree.set("parameters/conditions/Not ground", not is_on_floor())
	animationTree.set("parameters/conditions/jump", is_jumpting)
	animationTree.set("parameters/conditions/swing", input_hold)
	animationTree.set("parameters/conditions/wall", is_on_wall_only())
	animationTree.set("parameters/conditions/Not Wall", not is_on_wall_only())
	# step two point five: set blend positions
	animationTree.set("parameters/Air_2D/blend_position", Vector2(0, - velocity.y) / GLOBAL_MULT)
	animationTree.set("parameters/Run_1D/blend_position", get_real_velocity().x / GLOBAL_MULT)
	animationTree.set("parameters/Swing_2D/blend_position", Vector2(0, 0)) # NOTE: fix this if adding sprites
	
	
	# step three: based on animation state, control movement
	var targetVelocity : Vector2 = Vector2.ZERO
	var smoothFactor = 0.5
	match animationStateMachinePlayback.get_current_node():
		"Run_1D":
			# move left and right depending on ground_curve
			# move_toward(velocity.x, 0, SPEED)
			targetVelocity.x = sampleSymCurve(ground_curve, input_direction) * GLOBAL_MULT
			
			# fall according to fall
			targetVelocity.y = -fall_curve.sample(lerp(1, 0, fall_timer.time_left / fall_time)) * GLOBAL_MULT
			
			# set max jumps
			jump_count = max_jump_count
		"Air_2D":
			# move left and right depending on air curve
			targetVelocity.x = sampleSymCurve(air_curve, input_direction) * GLOBAL_MULT
			
			# fall according to jump
			targetVelocity.y = -jump_curve.sample(lerp(1, 0, jump_timer.time_left / jump_time)) * GLOBAL_MULT
			
			# we're not on a wall
			was_on_wall = false
			smoothFactor = 0.2
		"Swing_2D":
			# Step one: get collision point:
			# Step two: move in arc from collision point
			pass # TODO: write this section
		"wall_slide":
			# move left and right depending on air curve
			# in practice, this will not do anything but push into the wall
			targetVelocity.x = sampleSymCurve(air_curve, input_direction) * GLOBAL_MULT
			
			targetVelocity.y = -wall_slide_curve.sample(lerp(1, 0, wall_slide_timer.time_left / wall_slide_time)) * GLOBAL_MULT
			
			# set max jumps
			jump_count = max_jump_count
		
		# TODO: handle jumps so that 
		"jump_ground", "jump_wall", "jump_swing", "jump_double":
			# move left and right depending on ground_curve
			# but if was on wall, jump away from the wall
			if was_on_wall:
				input_direction = wall_side.x
			targetVelocity.x = sampleSymCurve(ground_curve, input_direction) * GLOBAL_MULT
			
			# fall according to jump
			targetVelocity.y = -jump_curve.sample(lerp(1, 0, jump_timer.time_left / jump_time)) * GLOBAL_MULT
		_:
			pass
	# step three: smooth to target velocity
	velocity = lerp(velocity, targetVelocity, smoothFactor)
	# step four: flip player if moving left
	if velocity.x < -0.2:
		$Visual.scale.x = -1
	if velocity.x > 0.2:
		$Visual.scale.x = 1
	
	move_and_slide()
	
	# step five: handle rope
	if get_parent().get_node("Rope"):
		get_parent().get_node("Rope").endPoint = $"Visual/Rope Attach Point".global_position
	
	# DEBUG
	#print(velocity)
