class_name PathContainer extends HBoxContainer

@onready var path_label: Label = $PathLabel

var valid_path: bool
var mm: ModManager

func _on_change_path_button_pressed() -> void:
	mm.file_dialog.file_mode = FileDialog.FileMode.FILE_MODE_OPEN_DIR
	mm.file_dialog.root_subfolder = mm.gss_path
	mm.file_dialog.popup()

func _on_run_game_button_pressed() -> void:
	var err = OS.shell_open("steam://run/2961880")
	mm.os_error("Open game", err)

func detect_gss() -> void:
	var drive_paths: Array[String] = []
	drive_paths.append("C:/Program Files (x86)/Steam/steamapps/common")
	for idx in range(DirAccess.get_drive_count()):
		var drive_name = DirAccess.get_drive_name(idx)
		if drive_name == "C:": continue
		drive_paths.append(drive_name + "/SteamLibrary/steamapps/common")
	
	for drive_path in drive_paths:
		if "Grocery Store Simulator" in DirAccess.get_directories_at(drive_path):
			print("Found Grocery Store Simulator at ", drive_path)
			mm.gss_path = drive_path + "/Grocery Store Simulator"
			post_path_change()
			return
	print("Didn't find Grocery Store Simulator in Steam directories")

func post_path_change() -> void:
	path_label.text = "GSS Path: " + mm.gss_path
	valid_path = FileAccess.file_exists(mm.gss_path + "/Simulatorita.exe")
	set_valid()
	mm.mod_loader_container.check_installed()

func set_valid() -> void:
	if valid_path:
		path_label.add_theme_color_override("font_color", Color.GREEN)
		mm.mod_loader_container.set_install_disabled(false)
	else:
		path_label.add_theme_color_override("font_color", Color.RED)
		mm.mod_loader_container.set_install_disabled(true)
