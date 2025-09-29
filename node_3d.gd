extends Node3D

@onready var dirt_mm := $dirt_mm
@onready var grass_mm := $grass_mm

func _ready() -> void:
	# импорт картинков
	var grass_array = create_grass_texarray()
	var dirt_array = create_texarray("res://textures/dirt", "res://dirt_array.tres")
	var wp_array = create_texarray("res://textures/wild_plants", "res://wp_array.tres")
	
	# материалы
	var shader = load("res://tile.gdshader")
	
	var mat_dirt = ShaderMaterial.new()
	mat_dirt.shader = shader
	dirt_mm.material_override = mat_dirt
	mat_dirt.set_shader_parameter("tex_array", dirt_array)
	mat_dirt.set_shader_parameter("add_tex_array", wp_array)
	
	var mat_grass = ShaderMaterial.new()
	mat_grass.shader = shader
	grass_mm.material_override = mat_grass
	mat_grass.set_shader_parameter("tex_array", grass_array)
	mat_grass.set_shader_parameter("add_tex_array", wp_array)
	
	# делаем грязь
	var i : int = 0
	for x in range(0, 100, 1.0):
		for z in range(0, 100, 1.0):
			var transform_plane = Transform3D()
			transform_plane.origin = Vector3(x, 0, z)
			dirt_mm.multimesh.set_instance_transform(i, transform_plane)
			dirt_mm.multimesh.set_instance_custom_data(i, Color(0.0, 0.0, 0.0, 0.0))
			i += 1
			
			
	# заполняем бинарный грид травы (в основном проекте не через шум, положить на землю, которая видит небо)
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.1
	
	var bin_grass_grid : Array[Array] = []
	
	var null_row: Array = []
	null_row.resize(102)
	null_row.fill(false)
	
	bin_grass_grid.append(null_row)
	for x in range(100):
		var row: Array = []
		row.append(false)
		for z in range(100):
			var value = noise.get_noise_2d(x, z)
			row.append(value > -0.3)
		row.append(false)
		bin_grass_grid.append(row)
	bin_grass_grid.append(null_row)
	
	# заполняем мультимеш и грид с id текстур, генерируем дикоросы	
	
	i = 0
	var id_grass_grid : Array[Array] = []
	var bool_id : int = 0
	var wp_id: int = 0
	for x in range(0, 101, 1.0):
		var row: Array = []
		for z in range(0, 101, 1.0):
			bool_id = (int(bin_grass_grid[x][z]) << 3) | (int(bin_grass_grid[x+1][z]) << 2) | (int(bin_grass_grid[x][z+1]) << 1) | int(bin_grass_grid[x+1][z+1])
			if bool_id:
				wp_id = 0
				if bool_id >= 15:
					bool_id += randi() % 6 
					wp_id = (randi() % 6 + 1) * (randi() & 1)
				row.append([bool_id, wp_id])
				
				var transform_plane = Transform3D()
				transform_plane.origin = Vector3(x-0.5, 0.1, z-0.5)
				grass_mm.multimesh.set_instance_transform(i, transform_plane)
				grass_mm.multimesh.set_instance_custom_data(i, Color(bool_id - 1, 0.0, wp_id, 0.0))
				i += 1
		id_grass_grid.append(row)
	
func _process(delta: float) -> void:
	pass
	
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
		if tex:
			images.append(tex.get_image())

	var tex_array := Texture2DArray.new()
	tex_array.create_from_images(images)

	ResourceSaver.save(tex_array, save_path)

	return tex_array

func create_grass_texarray () -> Texture2DArray:
	var image_paths = [
		"res://textures/grass/grass_4.png",
		"res://textures/grass/grass_3.png",
		"res://textures/grass/grass_3_4.png",
		"res://textures/grass/grass_2.png",
		"res://textures/grass/grass_2_4.png",
		"res://textures/grass/grass_2_3.png",
		"res://textures/grass/grass_2_3_4.png",
		"res://textures/grass/grass_1.png",
		"res://textures/grass/grass_1_4.png",
		"res://textures/grass/grass_1_3.png",
		"res://textures/grass/grass_1_3_4.png",
		"res://textures/grass/grass_1_2.png",
		"res://textures/grass/grass_1_2_4.png",
		"res://textures/grass/grass_1_2_3.png",
		"res://textures/grass/grass0.png",
		"res://textures/grass/grass1.png",
		"res://textures/grass/grass2.png",
		"res://textures/grass/grass3.png",
		"res://textures/grass/grass4.png",
		"res://textures/grass/grass5.png"
	]

	# Загружаем картинки как Image
	var images: Array[Image] = []
	for path in image_paths:
		var tex: Texture2D = load(path)
		var img: Image = tex.get_image()
		img.convert(Image.FORMAT_RGBA8)
		images.append(img)

	# Создаём массив текстур
	var tex_array := Texture2DArray.new()
	tex_array.create_from_images(images)

	# Сохраняем в ресурс для редактора
	ResourceSaver.save(tex_array, "res://grass_array.tres")
	return tex_array
