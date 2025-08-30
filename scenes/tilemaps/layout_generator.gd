class_name LayoutGenerator

extends Node2D

@export_range(0, 100) var difficulty : float = 0
@export_range(10, 30) var iters : int = 10

@onready var tileLibrary : Node2D = load("res://scenes/tilemaps/tile_library.tscn").instantiate()

func addTiles(tileElement : TileLibraryElement, depth : int, used_coords : Vector2i):
	# This is a recursive function
	# Step 0: if the depth is too big, return 
	if depth > iters:
		# TODO: spawn an endroom here
		return
	
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
				))
		# Step 4.1: sort by proximity to difficulty
		potentialTileElements.sort_custom(func(a : TileLibraryElement, b : TileLibraryElement):
			return abs(a.difficulty - difficulty) < abs(b.difficulty - difficulty)
			)
			
		
		# Step 5: for each potential, place to see if there are any overlaps
		for potentialTileElement : TileLibraryElement in potentialTileElements:
			# get the start position(s)
			var potentialEnterTiles = potentialTileElement.get_used_cells().filter(func(a : Vector2i):
				return potentialTileElement.get_cell_tile_data(a).get_custom_data("type") == targetType
				)
			
			# for each potential start position
			for potentialEnterTile : Vector2i in potentialEnterTiles:
				
				# TODO: check for collisions!
				var newTileElement : TileLibraryElement = potentialTileElement.duplicate()
				newTileElement.position = (exitTile - potentialEnterTile) * 128
				tileElement.add_child(newTileElement)
				
				addTiles(newTileElement, depth + 1, potentialEnterTile)
				break
			break

# Called when the node enters the scene tree for the first time.
func _ready():
	addTiles($"Start Room", 0, Vector2i.ZERO)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
