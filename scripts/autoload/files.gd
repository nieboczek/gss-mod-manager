extends Node


## Copies from `from` to `to` recursively, `to` must exist
## Returns error code
func copy_recursive(from: String, to: String, folder_name: String = "") -> Error:
	var err = DirAccess.make_dir_absolute(to + folder_name)
	if err != OK and err != ERR_ALREADY_EXISTS:
		return err
	var dir = DirAccess.open(from + folder_name)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var full_path = from + folder_name + "/" + file_name
		while file_name != "":
			if dir.current_is_dir():
				err = copy_recursive(from, to, folder_name + "/" + file_name)
				if err:
					return err
			else:
				err = DirAccess.copy_absolute(full_path, to + folder_name + "/" + file_name)
				if err:
					return err

				print("Copied %s to %s/%s" % [full_path, to + folder_name, file_name])
			file_name = dir.get_next()
			full_path = from + folder_name + "/" + file_name
		return OK
	return DirAccess.get_open_error()


## Deletes directories and files recursively in `path`. `path` is deleted too.
## Returns error code
func remove_recursive(path: String) -> Error:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var full_path = path + "/" + file_name
		while file_name != "":
			if dir.current_is_dir():
				var err = remove_recursive(full_path)
				if err:
					return err
			else:
				var err = DirAccess.remove_absolute(full_path)
				if err:
					return err

				print("Removed ", full_path)
			file_name = dir.get_next()
			full_path = path + "/" + file_name

		var error = DirAccess.remove_absolute(path)
		if error:
			return error
		return OK
	return DirAccess.get_open_error()


func remove_mod(ue_root: String, mod_name: String) -> Error:
	var err = remove_recursive(ue_root + "/Mods/" + mod_name)
	if err:
		return err
	var file = FileAccess.open(ue_root + "/Mods/mods.txt", FileAccess.READ)
	if file:
		var lines = []
		while not file.eof_reached():
			lines.append(file.get_line())
		file.close()

		var new_lines = []
		for line in lines:
			if not line.begins_with(mod_name + " : "):
				new_lines.append(line)

		file = FileAccess.open(ue_root + "/Mods/mods.txt", FileAccess.WRITE)
		if file:
			for i in range(len(new_lines)):
				file.store_string(new_lines[i])
				if i < len(new_lines) - 1:
					file.store_string("\n")

			file.close()
			return OK
		return FileAccess.get_open_error()
	return FileAccess.get_open_error()


func toggle_mod(ue_root: String, mod_name: String, on: bool) -> Error:
	var file = FileAccess.open(ue_root + "/Mods/mods.txt", FileAccess.READ)
	if file:
		var lines = []
		while not file.eof_reached():
			lines.append(file.get_line())
		file.close()

		for i in range(len(lines)):
			if lines[i].begins_with(mod_name + " : "):
				var new_value = "1" if on else "0"
				lines[i] = mod_name + " : " + new_value
				break

		file = FileAccess.open(ue_root + "/Mods/mods.txt", FileAccess.WRITE)
		if file:
			for i in range(len(lines)):
				file.store_string(lines[i])
				if i < len(lines) - 1:
					file.store_string("\n")

			file.close()
			return OK
		return FileAccess.get_open_error()
	return FileAccess.get_open_error()


func save_config(ue_root: String, mod_name: String, config_changes: Dictionary) -> Error:
	print("Changes to config: ", config_changes)
	var file = FileAccess.open(ue_root + "/Mods/%s/Scripts/config.lua" % mod_name, FileAccess.READ)
	if file:
		var lines = []
		while not file.eof_reached():
			lines.append(file.get_line())
		file.close()

		for i in range(len(lines)):
			var line = lines[i].strip_edges()
			for field_name in config_changes:
				if line.begins_with(field_name):
					lines[i] = "\t%s = %s," % [field_name, config_changes[field_name]]
					break

		file = FileAccess.open(ue_root + "/Mods/%s/Scripts/config.lua" % mod_name, FileAccess.WRITE)
		if file:
			for i in range(len(lines)):
				file.store_string(lines[i])
				if i < len(lines) - 1:
					file.store_string("\n")

			file.close()
			return OK
		return FileAccess.get_open_error()
	return FileAccess.get_open_error()
