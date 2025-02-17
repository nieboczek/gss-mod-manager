class_name ModListContainer extends HBoxContainer

@onready var install_mod_button = $InstallModButton
@onready var mod_list_label = $ModListLabel

var mm: ModManager


func _on_refresh_button_pressed() -> void:
	mm.update_mod_list()


func _on_install_mod_button_pressed() -> void:
	mm.file_dialog.file_mode = FileDialog.FileMode.FILE_MODE_OPEN_FILE
	mm.file_dialog.root_subfolder = OS.get_environment("USERPROFILE") + "/Downloads"
	mm.file_dialog.popup()


func set_install_disabled(disabled: bool) -> void:
	install_mod_button.disabled = disabled


func set_count(count: int) -> void:
	mod_list_label.text = "Mod list [%s]" % count


func _on_file_dialog_mod_selected(path: String) -> void:
	var mods := DirAccess.get_directories_at(mm.ue_root + "/Mods")

	# Use 7z to unzip the archive and copy it to Mods folder
	var err = OS.execute("%s/7z.exe" % mm.exe_path, ["x", path, "-y", "-o%s/Mods" % mm.ue_root])
	if mm.os_error("Execute 7z", err):
		return

	var mod_name: String
	var new_mods := DirAccess.get_directories_at(mm.ue_root + "/Mods")
	for mod in new_mods:
		if mod not in mods:
			mod_name = mod

	var bp_mods := DirAccess.get_files_at(mm.ue_root + "/Mods")
	for mod in bp_mods:
		if mod.ends_with(".utoc") or mod.ends_with(".pak") or mod.ends_with(".ucas"):
			err = DirAccess.rename_absolute(
				mm.ue_root + "/Mods/" + mod,
				mm.gss_path + "/Simulatorita/Content/Paks/LogicMods/" + mod
			)
			if mm.error("Move Blueprint mod files", err):
				return

	if mod_name:
		# Add "mod_name : 1" to mods.txt
		var file = FileAccess.open(mm.ue_root + "/Mods/mods.txt", FileAccess.READ)
		if file:
			var lines = []
			while not file.eof_reached():
				lines.append(file.get_line())
			file.close()
			lines.append(mod_name + " : 1")

			file = FileAccess.open(mm.ue_root + "/Mods/mods.txt", FileAccess.WRITE)
			if file:
				for i in range(len(lines)):
					file.store_string(lines[i])
					if i < len(lines) - 1:
						file.store_string("\n")
				file.close()
				mm.update_mod_list()
			else:
				mm.error("Open mods.txt file for write", FileAccess.get_open_error())
		else:
			mm.error("Open mods.txt file for read", FileAccess.get_open_error())
