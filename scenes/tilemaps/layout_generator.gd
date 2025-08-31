class_name LayoutGenerator

extends Node2D

var difficulty : float = Globals.risk / 4
var iters : int = Globals.length

@onready var tileLibrary : Node2D = load("res://scenes/tilemaps/tile_library.tscn").instantiate()

# store tile offsets
@onready var existingTileOffsets : Dictionary[TileLibraryElement, Vector2i] = {$"Start Room": Vector2i.ZERO}

func addTiles(tileElement : TileLibraryElement, depth : int, used_coords : Vector2i):
	# This is a recursive function
	# Step -0.1: sort by proximity to difficulty
	var targetDifficulty : float = difficulty + randf_range(-3, 3) # add some randomness to difficulty
		
	# Step 0: if the depth is too big, return 
	if depth > iters:
		targetDifficulty = 99
	
	# Step 1: for the tileElement, find the exit tiles
	var exitTiles = tileElement.get_used_cells().filter(func(a : Vector2i):
			return tileElement.get_cell_tile_data(a).get_custom_data("type") in \
				["exit_bottom", "exit_top", "exit_left", "exit_right"])
	# tileElement.get_cell_tile_data(tileElement.get_used_cells()[0])
	
	# Step 2: remove the used coords from this
	if exitTiles.find(used_coords) != -1:
		exitTiles.remove_at(exitTiles.find(used_coords))
	
	# Step 3: for all remaining
	for exitTile : Vector2i in exitTiles:
		# Get the name
		var type : String = tileElement.get_cell_tile_data(exitTile).get_custom_data("type")
		var targetType : String = {
			"exit_bottom": "exit_top",
			"exit_top": "exit_bottom",
			"exit_left": "exit_right",
			"exit_right": "exit_left"
		}[type]
	
		# Step 4: filter to only tiles that have that
		var potentialTileElements = tileLibrary.get_children()
		# tileLibrary.get_children()[0].get_used_cells()
		
		potentialTileElements = potentialTileElements.filter(func(a : TileLibraryElement):
				return a.get_used_cells().any(func(b : Vector2i):
					return a.get_cell_tile_data(b).get_custom_data("type") == targetType
				) and a.name != tileElement.name) # can't repeat
		
		
		potentialTileElements.shuffle() # add some randomness to tiles
		potentialTileElements.sort_custom(func(a : TileLibraryElement, b : TileLibraryElement):
			var a_diff = abs(a.difficulty - targetDifficulty)
			if a.difficulty > targetDifficulty:
				a_diff += 10
			var b_diff = abs(b.difficulty - targetDifficulty)
			if b.difficulty > targetDifficulty:
				b_diff += 10
			return a_diff < b_diff
			)
			
		# Step 5: for each potential, place to see if there are any overlaps
		for potentialTileElement : TileLibraryElement in potentialTileElements:
			# get the start position(s)
			var potentialEnterTiles = potentialTileElement.get_used_cells().filter(func(a : Vector2i):
				return potentialTileElement.get_cell_tile_data(a).get_custom_data("type") == targetType
				)
			potentialEnterTiles.shuffle()
			# for each potential start position
			var found : bool = false
			for potentialEnterTile : Vector2i in potentialEnterTiles:
				# add the new tile element in position
				var newTileElement : TileLibraryElement = potentialTileElement.duplicate()
				newTileElement.position = (exitTile - potentialEnterTile) * 128
				tileElement.add_child(newTileElement)
				
				# check for collisions
				var valid = true
				for existingTileElement : TileLibraryElement in existingTileOffsets.keys():
					if existingTileElement == tileElement: # it can intersect with self
						continue
					
					var existingRect = existingTileElement.get_used_rect()
					existingRect.position += existingTileOffsets[existingTileElement]
					var newRect = newTileElement.get_used_rect()
					newRect.position += existingTileOffsets[tileElement as TileLibraryElement] + exitTile - potentialEnterTile
					
					if existingRect.intersects(newRect):
						# intersects with a tile, remove!
						tileElement.remove_child(newTileElement)
						newTileElement.queue_free()
						valid = false
						break
				
				if valid:
					newTileElement.visible = true
					existingTileOffsets[newTileElement] = existingTileOffsets[tileElement] + exitTile - potentialEnterTile
					addTiles(newTileElement, depth + 1, potentialEnterTile)
					found = true
					break
			if found:
				break

var allInsideTiles : Dictionary[Vector2i, bool] = {}
# Called when the node enters the scene tree for the first time.
func _ready():
	difficulty = Globals.risk / 4
	iters = Globals.length
	addTiles($"Start Room", 0, Vector2i.ZERO)
	
	# get all inside tile locations
	
	for tileLibraryElement in existingTileOffsets.keys():
		# for each tile 
		var insideTiles = tileLibraryElement.get_used_cells().filter(func(a : Vector2i):
			return tileLibraryElement.get_cell_tile_data(a).get_custom_data("is inside")
			)
		
		for insideTileLoc : Vector2i in insideTiles:
			allInsideTiles.set(insideTileLoc + existingTileOffsets[tileLibraryElement], true)
	
	# remove physics tiles
	for tileLibraryElement in existingTileOffsets.keys():
		tileLibraryElement.hide_tiles()
		
	
func _process(delta):
	# For every tile on screen:
	var rect = Utility.get_camera_world_rect(get_viewport().get_camera_2d())
	
	var startRoom : TileLibraryElement = ($"Start Room" as TileLibraryElement)
	var start = startRoom.local_to_map(startRoom.to_local(rect.position))
	var end = startRoom.local_to_map(startRoom.to_local(rect.position + rect.size))
	
	for x in range(start.x, end.x + 1):
		for y in range(start.y, end.y + 1):
			var coords = Vector2i(x, y)
			# check if tile marked as inside
			if allInsideTiles.get(coords, false):
				continue
			
			# check if already placed
			var tile_data : TileData = startRoom.get_cell_tile_data(coords)
			if tile_data:
				if tile_data.get_custom_data("is placed"): # means tile exists
					continue
			
			# place the tile!
			var atlas_coords : Array[Vector2i] = []
			var probabilities : Array[float] = []
			var tile_set_source : TileSetAtlasSource = startRoom.tile_set.get_source(0)
			for i : int in tile_set_source.get_tiles_count():
				var atlas_coord = tile_set_source.get_tile_id(i)
				var data : TileData = tile_set_source.get_tile_data(atlas_coord, 0) # 0 = alternative index
				if data.get_custom_data("is placed"):
					atlas_coords.append(atlas_coord)
					probabilities.append(data.probability)
			
			# startRoom.tile_set.get_source(0).get_tile_data(Vector2i.Zero)
			
			# step 2: get random tile from list
			var tile : Vector2i = Utility.choose_weighted(atlas_coords, probabilities)
			startRoom.set_cell(coords, 0, tile)
