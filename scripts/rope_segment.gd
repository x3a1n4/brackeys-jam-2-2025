class_name RopeSegment2D

extends RigidBody2D

var isColliding : bool = false
var collisionPos : Vector2 = Vector2.ZERO

# func _integrate_forces(state):
# 	if state.get_contact_collider_position(0):
# 		isColliding = true
# 		collisionPos = state.get_contact_collider_position(0)
# 	else:
# 		isColliding = false
