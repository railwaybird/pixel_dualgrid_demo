extends Node3D

@onready var tile_mmi := $tile_mmi
@onready var shadow_mmi := $shadow_mmi

var borders_array : Array = []
var terr_array : Array[Array] = []
var noise_grass_1 : FastNoiseLite
var noise_grass_2 : FastNoiseLite

enum { STONE, SOIL, GRASS }
enum { Y_COORD, BLOCK_ID, TEX_ID } # индексы для terr_array
var borders_shift : Array[int] = [36, 53, 5]
var overlay_shift : Array[int] = [0, 68, 20]
const CHUNK_SIZE : int = 100 

func _ready() -> void:
	# импорт картинков
	# var tex_array = create_texarray("res://textures", "res://tex_array.tres")
	
	# материалы
	var tex_array = load("res://tex_array.tres")
	var tile_shader = load("res://tile.gdshader")
	var tile_mat = ShaderMaterial.new()
	tile_mat.shader = tile_shader
	tile_mmi.material_override = tile_mat
	tile_mat.set_shader_parameter("tex_array", tex_array)
	
	var shadow_shader = load("res://shadow.gdshader")
	var shadow_mat = ShaderMaterial.new()
	shadow_mat.shader = shadow_shader
	shadow_mmi.material_override = shadow_mat


	# шумы для террейна
	
	var noise_terr := FastNoiseLite.new()
	noise_terr.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_terr.fractal_type = FastNoiseLite.FRACTAL_NONE
	noise_terr.frequency = 0.1
	noise_terr.seed = 1
	
	var noise_stone := FastNoiseLite.new()
	noise_stone.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_stone.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_stone.fractal_octaves = 2
	noise_stone.frequency = 0.1
	noise_stone.seed = 2
	
	# шумы для вариантов травы внутри травы внутри травы
	
	noise_grass_1 = FastNoiseLite.new()
	noise_grass_1.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_grass_1.fractal_type = FastNoiseLite.FRACTAL_NONE
	noise_grass_1.frequency = 0.1
	
	noise_grass_2 = FastNoiseLite.new()
	noise_grass_2.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_grass_2.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_grass_2.fractal_octaves = 4
	noise_grass_2.frequency = 5.0
	
	# матрица [y координата, id блока, id текстуры]
	for x in range(CHUNK_SIZE):
		var row : Array = []
		for z in range(CHUNK_SIZE):
			row.append([floor((noise_terr.get_noise_2d(x, z) + 1) * \
							  (noise_terr.get_noise_2d(x, z) + 1) * 2), \
						   int(noise_stone.get_noise_2d(x, z) < 0.2), 36])
			if row[z][BLOCK_ID] == SOIL:
				if noise_grass_1.get_noise_2d(x,z) > -0.5:
					row[z][BLOCK_ID] = GRASS
		terr_array.append(row)
	
	# обход, создающий массив с границами и травой [Vector3 координаты, id текстуры]
	
	for x in range(1, CHUNK_SIZE - 1):
		for z in range(1, CHUNK_SIZE - 1):
			if terr_array[x][z][BLOCK_ID] == SOIL:
				terr_array[x][z][TEX_ID] = 52 + (randi() & 1)
			elif terr_array[x][z][BLOCK_ID] == GRASS:
				var noise_val : float = (noise_grass_2.get_noise_2d(x, z) + 1.0) * (noise_grass_1.get_noise_2d(x, z) + 1.0) * 0.25
				terr_array[x][z][TEX_ID] = int(noise_val > 0.15) + int(noise_val > 0.2) + int(noise_val > 0.3) + int(noise_val > 0.45) + int(noise_val > 0.6)
			create_borders(x, z, true)
			create_borders(x, z, false)
			
	
	# рендер
	var tile_instance : int = 0
	var shadow_instance : int = 0
	var transform_plane = Transform3D()
	for x in range(CHUNK_SIZE):
		for z in range(CHUNK_SIZE):
			transform_plane.origin = Vector3(x, terr_array[x][z][Y_COORD], z)
			tile_mmi.multimesh.set_instance_transform(tile_instance, transform_plane)
			tile_mmi.multimesh.set_instance_custom_data(tile_instance, Color(terr_array[x][z][TEX_ID], terr_array[x][z][Y_COORD], 0.0, 0.0))
			tile_instance += 1
			
			if x > 0:
				if terr_array[x][z][Y_COORD] < terr_array[x-1][z][Y_COORD]:
					transform_plane.origin = Vector3(x, 9.5, z)
					shadow_mmi.multimesh.set_instance_transform(shadow_instance, transform_plane)
					shadow_instance += 1
			
	for i in borders_array:
		transform_plane.origin = i[0]
		tile_mmi.multimesh.set_instance_transform(tile_instance, transform_plane)
		tile_mmi.multimesh.set_instance_custom_data(tile_instance, Color(i[1], i[0].y, 0.0, 0.0))
		tile_instance += 1
	
	
func _process(delta: float) -> void:
	pass
	
func check_border (x: int, z: int, side: Array, need_high_border: bool, flags: int) -> int:
	var center = terr_array[x][z]
	var right  = terr_array[x+1][z]
	var down   = terr_array[x][z+1]
	var left   = terr_array[x-1][z]
	var bit_id : int = 0
	var tex_id : int = 0
	var coords : Vector3
	
	if ( need_high_border and side[Y_COORD] >  center[Y_COORD]) \
	or (!need_high_border and side[Y_COORD] == center[Y_COORD] and side[BLOCK_ID] > center[BLOCK_ID]):
		if !(flags & 8):
			bit_id = 8
			flags |= 8
		if !(flags & 4) and right[Y_COORD] == side[Y_COORD] and right[BLOCK_ID] == side[BLOCK_ID]:
			bit_id += 4
			flags |= 4
		if !(flags & 2) and down[Y_COORD] == side[Y_COORD] and down[BLOCK_ID] == side[BLOCK_ID]:
			bit_id += 2
			flags |= 2
		if !(flags & 1) and left[Y_COORD] == side[Y_COORD] and left[BLOCK_ID] == side[BLOCK_ID]:
			bit_id += 1
			flags |= 1
		coords = Vector3(x, side[Y_COORD], z)
		if !bit_id:
			return flags
		if need_high_border:
			tex_id = borders_shift[side[BLOCK_ID]] + bit_id
		else:
			tex_id = overlay_shift[side[BLOCK_ID]] + bit_id
		borders_array.append([coords, tex_id])
	return flags
	
func create_borders (x: int, z: int, need_high_border: bool) -> void:
	var up     = terr_array[x][z-1]
	var right  = terr_array[x+1][z]
	var down   = terr_array[x][z+1]
	var left   = terr_array[x-1][z]
	var flags : int = 0
	
	
	flags = check_border(x, z, up,    need_high_border, flags)
	flags |= 8
	flags = check_border(x, z, right, need_high_border, flags)
	flags |= 4
	flags = check_border(x, z, down,  need_high_border, flags)
	flags |= 2
	flags = check_border(x, z, left,  need_high_border, flags)
	
	
func create_overlays (x: int, z: int) -> void:
	var center = terr_array[x][z]
	var up     = terr_array[x][z-1]
	var down   = terr_array[x][z+1]
	var left   = terr_array[x-1][z]
	var right  = terr_array[x+1][z]
	var bit_id : int = 0
	
	if center[Y_COORD] == up[Y_COORD] and (up[BLOCK_ID] == SOIL or up[BLOCK_ID] == GRASS):
		bit_id += 8
	if center[Y_COORD] == right[Y_COORD] and (right[BLOCK_ID] == SOIL or right[BLOCK_ID] == GRASS):
		bit_id += 4
	if center[Y_COORD] == down[Y_COORD] and (down[BLOCK_ID] == SOIL or down[BLOCK_ID] == GRASS):
		bit_id += 2
	if center[Y_COORD] == left[Y_COORD] and (left[BLOCK_ID] == SOIL or left[BLOCK_ID] == GRASS):
		bit_id += 1
		
	if bit_id != 0:
		var coords = Vector3(x, center[Y_COORD] + 0.1, z)
		var tex_id = 68 + bit_id
		borders_array.append([coords, tex_id])

func create_grass (x: int, z: int) -> void:
	var center = terr_array[x][z]
	var up     = terr_array[x][z-1]
	var down   = terr_array[x][z+1]
	var left   = terr_array[x-1][z]
	var right  = terr_array[x+1][z]
	var bit_id : int = 0
	
	if center[Y_COORD] != up[Y_COORD] or center[BLOCK_ID] == up[BLOCK_ID]:
		bit_id += 8
	if center[Y_COORD] != right[Y_COORD] or center[BLOCK_ID] == right[BLOCK_ID]:
		bit_id += 4
	if center[Y_COORD] != down[Y_COORD] or center[BLOCK_ID] == down[BLOCK_ID]:
		bit_id += 2
	if center[Y_COORD] != left[Y_COORD] or center[BLOCK_ID] == left[BLOCK_ID]:
		bit_id += 1
	
	var coords = Vector3(x, center[Y_COORD] + 0.1, z)
	var tex_id : int
	if bit_id != 15:
		tex_id = 21 + bit_id
	else:
		var noise_val : float = (noise_grass_2.get_noise_2d(x, z) + 1.0) * (noise_grass_1.get_noise_2d(x, z) + 1.0) * 0.25
		tex_id = int(noise_val > 0.15) + int(noise_val > 0.2) + int(noise_val > 0.3) + int(noise_val > 0.45) + int(noise_val > 0.6)
		
	borders_array.append([coords, tex_id])
	

func create_texarray (folder: String, save_path: String) -> Texture2DArray:
	var image_paths: Array[String] = []

	var dir := DirAccess.open(folder)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".png"):
				image_paths.append(folder.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()

	# сортировка по алфавиту
	image_paths.sort()

	var images: Array[Image] = []
	for path in image_paths:
		var tex: Texture2D = load(path)
		var img: Image = tex.get_image()
		img.convert(Image.FORMAT_RGBA8)
		images.append(img)

	var tex_array := Texture2DArray.new()
	tex_array.create_from_images(images)

	ResourceSaver.save(tex_array, save_path)

	return tex_array
