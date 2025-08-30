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

@export var swing_curve: Curve
@export var swing_time = 0.2
var current_swing_time : float
@onready var swing_timer : Timer = $"Timers/Swing Timer"
var was_swinging : bool = false
var start_swing_pos : Vector2 = Vector2.ZERO

@onready var animationTree : AnimationTree = $AnimationTree
@onready var animationStateMachinePlayback : AnimationNodeStateMachinePlayback = animationTree.get("parameters/playback")

@onready var rope : Rope2D = get_parent().get_node("Rope")
@onready var swing_path : Path2D = $"Swing Path"
@onready var swing_path_follow : PathFollow2D = $"Swing Path/PathFollow2D"
@export var swing_path_samples : int = 100

@export var dash_time = 0.1
var dash_velocity : Vector2 = Vector2.ZERO

@onready var dash_detection_area : Area2D = $"Dash Detection Area"

signal win
signal die

var can_move = true

func _ready():
	# unparent path
	remove_child(swing_path)
	
	get_tree().get_root().add_child.call_deferred(swing_path)
	
	# show dialogue
	if Globals.num_nodes == 0 and Globals.num_deaths == 0:
		DialogueManager.show_dialogue_balloon(Globals.dialogue, "intro_inside")
	
func sampleSymCurve(curve : Curve, sample : float):
	if sample < 0:
		return -curve.sample(-sample)
	return curve.sample(sample)

# TODO: bug when you run into walls
var wall_side = Vector2(0, 0)
func _physics_process(delta):
	# step one: get inputs
	var input_direction : float = Input.get_axis("Player_Left", "Player_Right")
	var input_down : bool = Input.is_action_pressed("Player_Down")
	var input_jump : bool = Input.is_action_just_pressed("Player_Jump")
	var input_dash : bool = Input.is_action_just_pressed("Player_Dash")
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
	animationTree.set("parameters/conditions/Not Swing", not input_hold)
	animationTree.set("parameters/conditions/wall", is_on_wall_only())
	animationTree.set("parameters/conditions/Not Wall", not is_on_wall_only())
	# step two point five: set blend positions
	animationTree.set("parameters/Air_2D/blend_position", Vector2(0, -velocity.y) / GLOBAL_MULT / 1.5)
	animationTree.set("parameters/Run_1D/blend_position", get_real_velocity().x / GLOBAL_MULT)
	animationTree.set("parameters/Swing_2D/blend_position", Vector2(0, 0)) # NOTE: fix this if adding sprites
	
	# handle head hitting
	var hit_head = is_on_ceiling()
	
	# step three: based on animation state, control movement
	var targetVelocity : Vector2 = Vector2.ZERO
	var smoothFactor = 0.5
	var currAnimationNode : String = animationStateMachinePlayback.get_current_node()
	match currAnimationNode:
		"Run_1D":
			# move left and right depending on ground_curve
			# move_toward(velocity.x, 0, SPEED)
			targetVelocity.x = sampleSymCurve(ground_curve, input_direction) * GLOBAL_MULT
			
			# fall according to fall
			targetVelocity.y = -fall_curve.sample(lerp(1, 0, fall_timer.time_left / fall_time)) * GLOBAL_MULT
			
			# set max jumps
			jump_count = max_jump_count
			
			was_on_wall = false
			was_swinging = false
		"Air_2D":
			# move left and right depending on air curve
			targetVelocity.x = sampleSymCurve(air_curve, input_direction) * GLOBAL_MULT
			
			# fall according to jump
			targetVelocity.y = -jump_curve.sample(lerp(1, 0, jump_timer.time_left / jump_time)) * GLOBAL_MULT
			
			# handle head hitting
			if hit_head:
				jump_timer.start(0.1)
			
			# we're not on a wall
			was_on_wall = false
			smoothFactor = 0.2
			
			# we're not in the air
			was_swinging = false
		"Swing_2D":
			# Step one: get collision point
			if not was_swinging:
				was_swinging = true
				
				start_swing_pos = position
				var swing_point : Vector2 = rope.lastSegment.startPos
				var radius : float = swing_point.distance_to(start_swing_pos)
				
				var attack_angle : float = Vector2.DOWN.angle_to(position - swing_point)
				
				# Step one point five: set up path
				# 	setup path as circle
				swing_path.curve.clear_points()
				for i in swing_path_samples + 1:
					var angle = lerp(-attack_angle, attack_angle, float(i) / swing_path_samples)
					swing_path.curve.add_point(swing_point + (Vector2.DOWN * radius).rotated(angle))
				
				# Step one point eight: set time, longer if it's a longer curve
				current_swing_time = swing_time + sqrt(radius) / 20
				swing_timer.start(current_swing_time)
			
			# Step two: get path by sampling
			var sample : float = swing_curve.sample(lerp(1, 0, swing_timer.time_left / current_swing_time))
			swing_path_follow.progress_ratio = sample
			var target_pos = swing_path_follow.position
			
			# TODO: visual jitter when moving fast
			targetVelocity = (target_pos - position) / delta
			# move_and_collide(target_pos - position, false, 5)
		"wall_slide":
			# move left and right depending on air curve
			# in practice, this will not do anything but push into the wall
			targetVelocity.x = sampleSymCurve(air_curve, input_direction) * GLOBAL_MULT
			
			targetVelocity.y = -wall_slide_curve.sample(lerp(1, 0, wall_slide_timer.time_left / wall_slide_time)) * GLOBAL_MULT
			
			# if down, move away from the wall
			if input_down:
				input_direction = wall_side.x
				targetVelocity.x = wall_side.x
			# set max jumps
			jump_count = max_jump_count
		"jump_ground", "jump_wall", "jump_swing", "jump_double":
			# move left and right depending on ground_curve
			# but if was on wall, jump away from the wall
			if was_on_wall:
				input_direction = wall_side.x
			targetVelocity.x = sampleSymCurve(ground_curve, input_direction) * GLOBAL_MULT
			
			# fall according to jump
			targetVelocity.y = -jump_curve.sample(lerp(1, 0, jump_timer.time_left / jump_time)) * GLOBAL_MULT
			
			# if we hit head, set timer to when it's going down
			if hit_head:
				jump_timer.start(0.1)
		_:
			pass
	
	# STEP four: handle dashing
	# input_dash
	#	are we in area
	if dash_detection_area.get_overlapping_areas().any(func(a: Area2D): return a.is_in_group("hook area")):
		# if so, draw particles
		var hook = dash_detection_area.get_overlapping_areas() 	\
			.filter(func(a: Area2D): return a.is_in_group("hook area")) 		\
			[0] 																\
			.get_parent()
			
		var dash_dest_pos = hook.attach_point + (hook.attach_point - $"Dash Line Attach".global_position)
		
		# update line
		$"Dash Line Attach/Dash Line".points[0] = $"Dash Line Attach/Dash Line".to_local($"Dash Line Attach".global_position)
		$"Dash Line Attach/Dash Line".points[1] = $"Dash Line Attach/Dash Line".to_local(dash_dest_pos)
		$"Dash Line Attach/Dash Line".visible = true
		
		# can we dash?
		if input_dash:
			$"Timers/Dash Timer".start(dash_time)
			# set dash velocity
			dash_velocity = (dash_dest_pos - position) / delta * dash_time * 2 # two since we're going to the other side
			# set jumps
			jump_count = 1
			# update rope
			rope.lastSegment.collide({"position": hook.attach_point, "normal": hook.transform.y.normalized()})
			# consume hold input
			Input.action_release("Player_Hold")
			
			print(dash_detection_area)
			# if this is a goal node, win!
			if hook is GoalNode:
				win.emit()
		if $"Timers/Dash Timer".time_left > 0:
			targetVelocity = dash_velocity
			
	else:
		$"Dash Line Attach/Dash Line".visible = false
			
	# add momentum when holding direction
	if currAnimationNode != "Swing_2D":
		if input_direction < 0: # moving left
			if velocity.x < targetVelocity.x:
				targetVelocity.x = lerp(velocity.x, targetVelocity.x, 0.4)
		if input_direction > 0: # moving right
			if velocity.x > targetVelocity.x:
				targetVelocity.x = lerp(velocity.x, targetVelocity.x, 0.4)
	
	# step three: smooth to target velocity
	velocity = lerp(velocity, targetVelocity, smoothFactor)
	
	# step five: flip player if moving left
	if velocity.x < -0.2:
		$Visual.scale.x = -1
	if velocity.x > 0.2:
		$Visual.scale.x = 1
	
	if can_move:
		move_and_slide()
	
	# step six: handle rope
	rope.endPoint = $"Visual/Rope Attach Point".global_position
	# also handle jump indicator
	$"Visual/Jump Indicator".frame = jump_count
	# rope.slack = jump_count == 0 # set slack if can't jump

func _on_hurtbox_body_entered(body):
	print("died")
	die.emit()


func _on_die():
	Globals.died = true
	Globals.num_deaths += 1
	$"Death Particles".emitting = true
	can_move = false
	create_tween().tween_property($Visual/AnimatedSprite2D, "modulate:a", 0, 0.4)
	await get_tree().create_timer(0.6).timeout
	# remove progress? 
	# Globals.progress = Globals.progress / 1.2
	
	Globals.enter_home()

func _on_win():
	print("winner!")
	# new node
	Globals.num_nodes += 1
	Globals.length += 2
	# add progress
	Globals.max_risk += Globals.risk / 2 + randi_range(0, 5)
	if Globals.max_risk > 100:
		Globals.max_risk = 100
	
	# transition
	DialogueManager.show_dialogue_balloon(Globals.dialogue, "win_platforming")
