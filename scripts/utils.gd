class_name Utility

extends Node

# A helper function
static func choose_weighted(items: Array, weights: Array) -> Variant:
	# Sum of all weights
	var total_weight = 0.0
	for w in weights:
		total_weight += w
	
	# Random pick
	var r = randf() * total_weight
	var cumulative = 0.0
	
	for i in range(items.size()):
		cumulative += weights[i]
		if r <= cumulative:
			return items[i]
	
	return items.back() # fallback

static func screen_to_world(camera: Camera2D, screen_pos: Vector2) -> Vector2:
	var xform : Transform2D = camera.get_screen_transform().affine_inverse()
	return xform * screen_pos   # use * instead of .xform()
	
static func get_camera_world_rect(camera: Camera2D) -> Rect2:
	var viewport_rect = camera.get_viewport_rect()
	var camera_canvas_transform = camera.get_canvas_transform()
	var inverse_canvas_transform = camera_canvas_transform.affine_inverse()
	var camera_world_rect = inverse_canvas_transform * viewport_rect
	
	return camera_world_rect
