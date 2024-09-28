class_name ModListContainer extends HBoxContainer

@onready var install_mod_button = $InstallModButton
@onready var mod_list_label = $ModListLabel

var mm: ModManager

func _on_refresh_button_pressed() -> void:
	mm.update_mod_list()

func _on_install_mod_button_pressed() -> void:
	mm.file_dialog.file_mode = FileDialog.FileMode.FILE_MODE_OPEN_FILE
	mm.file_dialog.root_subfolder = "%s\\Downloads" % OS.get_environment("USERPROFILE")
	mm.file_dialog.popup()

func set_install_disabled(disabled: bool) -> void:
	install_mod_button.disabled = disabled

func set_count(count: int) -> void:
	mod_list_label.text = "Mod list [%s]" % count

func _on_file_dialog_mod_selected(path: String) -> void:
	# Use 7z to unzip the archive and copy it to GSS
	var err = OS.execute("%s/7z.exe" % mm.root_path, ["x", path, "-o" + "%s/mod" % mm.root_path, "-y"])
	if mm.os_error("Execute 7z", err): return
	
	var names = DirAccess.get_directories_at("%s/mod" % mm.root_path)
	var mod_name = names[0]  # there can be more, only if the program crashes. sucks to suck
	
	err = DirAccess.make_dir_absolute("%s/Simulatorita/Binaries/Win64/Mods/%s" % [mm.gss_path, mod_name])
	if mm.error("Make directory for mod", err): return
	
	err = Files.copy_recursive(
		"%s/mod/%s" % [mm.root_path, mod_name],
		"%s/Simulatorita/Binaries/Win64/Mods/%s" % [mm.gss_path, mod_name]
	)
	if mm.error("Copy from mod to mods folder", err): return
	err = Files.remove_recursive("%s/mod/%s" % [mm.root_path, mod_name])
	if mm.error("Remove mod", err): return
	
	# Add "mod_name : 1" to mods.txt
	var file = FileAccess.open("%s/Simulatorita/Binaries/Win64/Mods/mods.txt" % mm.gss_path, FileAccess.READ)
	if file:
		var lines = []
		while not file.eof_reached():
			lines.append(file.get_line())
		file.close()
		lines.append(mod_name + " : 1")
		
		file = FileAccess.open("%s/Simulatorita/Binaries/Win64/Mods/mods.txt" % mm.gss_path, FileAccess.WRITE)
		if file:
			for i in range(len(lines)):
				file.store_string(lines[i])
				if i < len(lines) - 1:
					file.store_string("\n")
			file.close()
			mm.update_mod_list()
			print("Mod added successfully")
		else:
			err = FileAccess.get_open_error()
			mm.error("Open mods.txt file", err)
	else:
		err = FileAccess.get_open_error()
		mm.error("Open mods.txt file", err)
