extends Node


# this assumes all vanity sets are in a shared directory
# and each set has its own directory for all parts (code and sprites) e.g.
#
# Vanity Sets
#  L setname
#	 L setnameHead.cs 			code
# 	 L setnameHead.png			inventory sprite
#	 L setnameHead_Head.png		sprite
#	 L setnameHead1.cs			alternative style

func get_set_information(set_directory_path: String) -> Array:
	var set_images := []
	var set_name = ""
	if OS.has_feature("Windows"):
		 set_name = set_directory_path.rsplit("\\", false, 1)[1]
	else:
		 set_name = set_directory_path.rsplit("/", false, 1)[1]
	var dir = Directory.new()
	dir.open(set_directory_path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while file_name != "":
		if not is_png_file(file_name) or not set_name in file_name:
			file_name = dir.get_next()
			continue

		var possible_file_names = [
			set_name + "Head_Head.png", set_name + "Body_Body.png", set_name + "Legs_Legs.png",
		]
		if file_name in possible_file_names: # character sprites end in _Head, _Body ...
			var img = Image.new()
			img.load(set_directory_path + "/" + file_name)
			if img.get_width() == 20 or img.get_width() == 180: # 1px scale
				var size = img.get_size() * 2
				img.resize(size.x, size.y,Image.INTERPOLATE_NEAREST)
			set_images.append({"image": img, "name": file_name.trim_suffix(".png")})

		file_name = dir.get_next()

	return set_images


func is_png_file(file_name: String) -> bool:
	return ".png" in file_name


func is_not_hidden_or_relative_directory(file_name: String) -> bool:
	return file_name[0] == '.' # includes "." and ".." directories


