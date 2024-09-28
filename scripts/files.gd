extends Node

## Copies from path to destination_path recursively, destination_path must exist
## Returns error code
func copy_recursive(from: String, to: String, folder_name: String = "") -> int:
	var err = DirAccess.make_dir_absolute("%s%s" % [to, folder_name])
	if err != OK and err != ERR_ALREADY_EXISTS:
		return err
	var dir = DirAccess.open("%s%s" % [from, folder_name])
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var full_path = "%s%s/%s" % [from, folder_name, file_name]
		while file_name != "":
			if dir.current_is_dir():
				err = copy_recursive(from, to, "%s/%s" % [folder_name, file_name])
				if err:
					return err
			else:
				err = DirAccess.copy_absolute(full_path, "%s%s/%s" % [to, folder_name, file_name])
				if err:
					return err
				else:
					print("Copied %s to %s%s/%s" % [full_path, to, folder_name, file_name])
			file_name = dir.get_next()
			full_path = "%s%s/%s" % [from, folder_name, file_name]
	else:
		return DirAccess.get_open_error()
	return OK

## Deletes directories recursively
## Returns error code
func remove_recursive(path: String) -> int:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var full_path = "%s/%s" % [path, file_name]
		while file_name != "":
			if dir.current_is_dir():
				remove_recursive(full_path)
			else:
				var err = DirAccess.remove_absolute(full_path)
				if err:
					return err
				else:
					print("Removed %s" % [full_path])
			file_name = dir.get_next()
			full_path = "%s/%s" % [path, file_name]
		DirAccess.remove_absolute(path)
	else:
		return DirAccess.get_open_error()
	return OK
