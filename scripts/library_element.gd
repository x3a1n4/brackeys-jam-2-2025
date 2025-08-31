class_name TileLibraryElement

extends TileMapLayer

@export_range(0, 100) var difficulty : float

@onready var tile_map : TileMapLayer = $"Tile Map"
@onready var physics_map : TileMapLayer = $"."

#region Tiling
func set_corner(dict : Dictionary[Vector2i, String], loc : Vector2i, index : int):
	dict.get_or_add(loc, "0000")
	var array = dict[loc].split()
	array[index] = "1"
	dict[loc] = "".join(array)

func find_tile_with_custom_data(tile_set_source: TileSetAtlasSource, key: String, value) -> Vector2i:
	# Step 1: get list of tiles
	var coords : Array[Vector2i] = []
	var probabilities : Array[float] = []
	for i : int in tile_set_source.get_tiles_count():
		var atlas_coords = tile_set_source.get_tile_id(i)
		var data = tile_set_source.get_tile_data(atlas_coords, 0) # 0 = alternative index
		if data.get_custom_data(key) == value:
			coords.append(atlas_coords)
			probabilities.append(data.probability)
	
	# step 2: get random tile from list
	var tile : Vector2i = Utility.choose_weighted(coords, probabilities)
	return tile

# Called when the node enters the scene tree for the first time.
func _ready():
	# autotile physics map with tilemap
	# STEP 1: get all blocks
	var tile_positions = physics_map.get_used_cells().filter(func(a : Vector2i):
		return physics_map.get_cell_tile_data(a).get_custom_data("type") == "block"
	)
	
	# STEP 2: log blocks in map
	var corners : Dictionary[Vector2i, String] = {}
	for loc : Vector2i in tile_positions:
		set_corner(corners, loc + Vector2i(0, 0), 3)
		set_corner(corners, loc + Vector2i(1, 0), 2)
		set_corner(corners, loc + Vector2i(0, 1), 1)
		set_corner(corners, loc + Vector2i(1, 1), 0)
	
	# for each item in corners, create that tile map
	# STEP 3: tile
	for tile_pos in corners:
		var tile_atlas_coords = find_tile_with_custom_data(tile_map.tile_set.get_source(0), "Corners", corners[tile_pos])
		if tile_atlas_coords != Vector2i(-1, -1):
			tile_map.set_cell(tile_pos, 0, tile_atlas_coords)
	

func hide_tiles():
	# STEP 5: hide tool tiles
	for tile in physics_map.get_used_cells():
		match physics_map.get_cell_tile_data(tile).get_custom_data("type"):
			"block":
				# hide tile
				physics_map.set_cell(tile, 0, Vector2i(6, 0))
			"exit_bottom", "exit_top", "exit_left", "exit_right":
				physics_map.set_cell(tile, 0, Vector2i(7, 0))
			"inside":
				physics_map.set_cell(tile, 0, Vector2i(7, 3))
