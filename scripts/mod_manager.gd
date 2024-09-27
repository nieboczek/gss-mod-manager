extends Control

@onready var main = $MarginContainer/MainContainer
@onready var file_dialog = $FileDialog
@onready var path_label: Label = main.get_node("PathContainer/PathLabel")
@onready var mod_loader_label: Label = main.get_node("ModLoaderContainer/ModLoaderLabel")
@onready var mod_loader_install_button: Button = main.get_node("ModLoaderContainer/ModLoaderInstallButton")
@onready var install_mod_button: Button = main.get_node("ModListContainer/InstallModButton")
@onready var mod_list_label: Label = main.get_node("ModListContainer/ModListLabel")
@onready var mod_containers: Control = main.get_node("ScrollContainer/MarginContainer")
@onready var config_panel = $ConfigPanel

const BUILTIN_MODS: Array[String] = [
	"ActorDumperMod", "BPML_GenericFunctions", "BPModLoaderMod",
	"CheatManagerEnablerMod", "ConsoleCommandsMod", "ConsoleEnablerMod",
	"jsbLuaProfilerMod", "Keybinds", "LineTraceMod", "SplitScreenMod"
]

var root_path := OS.get_executable_path().get_base_dir()
var gss_path: String:
	set(value):
		path_label.text = "GSS Path: %s" % value
		config.set_value("main", "gss_path", value)
		config.save("user://config")
		gss_path = value
		valid_gss_path = FileAccess.file_exists("%s/Simulatorita.exe" % gss_path)
		mod_loader_installed = FileAccess.file_exists("%s/Simulatorita/Binaries/Win64/UE4SS.dll" % gss_path)
		update_mod_list()
var valid_gss_path: bool:
	set(value):
		if value:
			path_label.add_theme_color_override("font_color", Color.GREEN)
			mod_loader_install_button.disabled = false
		else:
			path_label.add_theme_color_override("font_color", Color.RED)
			mod_loader_install_button.disabled = true
		valid_gss_path = value
var mod_loader_installed: bool:
	set(value):
		if value:
			mod_loader_label.text = "Mod loader installed"
			mod_loader_label.add_theme_color_override("font_color", Color.GREEN)
			mod_loader_install_button.text = "Uninstall mod loader"
			install_mod_button.disabled = false
		else:
			mod_loader_label.text = "Mod loader not installed"
			mod_loader_label.add_theme_color_override("font_color", Color.RED)
			mod_loader_install_button.text = "Install mod loader"
			install_mod_button.disabled = true
		mod_loader_installed = value
var config: ConfigFile
var config_editor_path: String
var editor_thread := Thread.new()

# NOTE: Only test in exported! (Unless you find a way to do it in the editor)

# TODO: Make editor for editing config configurable
# TODO: Clean up this mess
# TODO: Get icon

## Searches Steam paths for Grocery Store Simulator
func detect_gss() -> void:
	var drive_paths: Array[String] = []
	drive_paths.append("C:/Program Files (x86)/Steam/steamapps/common")
	for idx in range(DirAccess.get_drive_count()):
		var drive_name = DirAccess.get_drive_name(idx)
		if drive_name == "C:": continue
		drive_paths.append("%s/SteamLibrary/steamapps/common" % drive_name)
	
	for drive_path in drive_paths:
		if "Grocery Store Simulator" in DirAccess.get_directories_at(drive_path):
			print("Found Grocery Store Simulator at %s" % drive_path)
			gss_path = "%s/Grocery Store Simulator" % drive_path
			return
	print("Didn't find Grocery Store Simulator in Steam directories")

## Returns dictionary with the schema { mod_name (String): on (bool) }
func get_mod_list() -> Dictionary:
	var enabled: Dictionary = {}
	
	var file = FileAccess.open("%s/Simulatorita/Binaries/Win64/Mods/mods.txt" % gss_path, FileAccess.READ)
	if file:
		var lines = file.get_as_text(true).split('\n')
		for line in lines:
			var split = line.split(' : ')
			if len(split) != 2: continue
			
			var mod_name = split[0]
			var on = split[1] == '1'
			enabled[mod_name] = on
	else:
		var err = FileAccess.get_open_error()
		error("Opening mods.txt file", err)
	return enabled

## Updates the UI for mods not built-in
func update_mod_list() -> void:
	if !mod_loader_installed:
		for child in mod_containers.get_children():
			child.queue_free()
		return
	
	for child in mod_containers.get_children():
		child.queue_free()
	
	var list = get_mod_list()
	var non_builtin_mod_count = 0
	for mod in list:
		if mod in BUILTIN_MODS: continue
		var container = ModContainer.with(mod)
		mod_containers.add_child(container)
		container.set_toggled(list[mod])
		container.configure.connect(_on_configure_mod)
		container.delete.connect(_on_delete_mod)
		container.toggled.connect(_on_toggle_mod)
		non_builtin_mod_count += 1
	
	mod_list_label.text = "Mod list [%s]" % non_builtin_mod_count

func _on_configure_mod(mod_name: String) -> void:
	for file in DirAccess.get_files_at("%s/Simulatorita/Binaries/Win64/Mods/%s/Scripts" % [gss_path, mod_name]):
		if file.begins_with("config"):
			config_editor_path = "%s/Simulatorita/Binaries/Win64/Mods/%s/Scripts/%s" % [gss_path, mod_name, file]
			var err = editor_thread.start(run_config_editor, Thread.PRIORITY_LOW)
			error("Execute notepad in thread", err)
			return

func _on_delete_mod(mod_name: String) -> void:
	Files.remove_recursive("%s/Simulatorita/Binaries/Win64/Mods/%s" % [gss_path, mod_name])
	var file = FileAccess.open("%s/Simulatorita/Binaries/Win64/Mods/mods.txt" % gss_path, FileAccess.READ)
	if file:
		var lines = []
		while not file.eof_reached():
			lines.append(file.get_line())
		file.close()
		
		var new_lines = []
		for line in lines:
			if not line.begins_with(mod_name + " : "):
				new_lines.append(line)
		
		file = FileAccess.open("%s/Simulatorita/Binaries/Win64/Mods/mods.txt" % gss_path, FileAccess.WRITE)
		if file:
			for i in range(len(new_lines)):
				file.store_string(lines[i])
				if i < len(new_lines) - 1:
					file.store_string("\n")
			
			file.close()
			update_mod_list()
			print("Mod deleted successfully")
		else:
			var err = FileAccess.get_open_error()
			error("Open mods.txt file", err)
	else:
		var err = FileAccess.get_open_error()
		error("Open mods.txt file", err)

func _on_toggle_mod(mod_name: String, on: bool) -> void:
	var file = FileAccess.open("%s/Simulatorita/Binaries/Win64/Mods/mods.txt" % gss_path, FileAccess.READ)
	if file:
		var lines = []
		while not file.eof_reached():
			lines.append(file.get_line())
		file.close()
		
		for i in range(len(lines)):
			if lines[i].begins_with(mod_name + " : "):
				var new_value = '1' if on else '0'
				lines[i] = mod_name + " : " + new_value
				break
		
		file = FileAccess.open("%s/Simulatorita/Binaries/Win64/Mods/mods.txt" % gss_path, FileAccess.WRITE)
		if file:
			for i in range(len(lines)):
				file.store_string(lines[i])
				if i < len(lines) - 1:
					file.store_string("\n")
			
			file.close()
			print("Mod toggled succesfully")
		else:
			var err = FileAccess.get_open_error()
			error("Opening mods.txt file", err)
	else:
		var err = FileAccess.get_open_error()
		error("Opening mods.txt file", err)

func _process(_delta: float) -> void:
	if editor_thread.is_started() and !editor_thread.is_alive():
		editor_thread.wait_to_finish()

func _ready() -> void:
	config = ConfigFile.new()
	var err = config.load("user://config")
	if err == ERR_FILE_NOT_FOUND:
		detect_gss()
	else:
		error("Read user config", err)
	
	var path: String = config.get_value("main", "gss_path")
	if path == null:
		detect_gss()
	else:
		gss_path = path

func _on_mod_loader_install_button_pressed() -> void:
	if mod_loader_installed:
		Files.remove_recursive("%s/Simulatorita/Binaries/Win64/Mods" % gss_path)
		DirAccess.remove_absolute("%s/Simulatorita/Binaries/Win64/UE4SS.dll" % gss_path)
		DirAccess.remove_absolute("%s/Simulatorita/Binaries/Win64/UE4SS-settings.ini" % gss_path)
		DirAccess.remove_absolute("%s/Simulatorita/Binaries/Win64/dwmapi.dll" % gss_path)
	else:
		Files.copy_recursive("%s/UE4SS" % root_path, "%s/Simulatorita/Binaries/Win64" % gss_path)
	mod_loader_installed = !mod_loader_installed
	update_mod_list()

func _on_change_path_button_pressed() -> void:
	file_dialog.file_mode = FileDialog.FileMode.FILE_MODE_OPEN_DIR
	file_dialog.root_subfolder = gss_path
	file_dialog.popup()

func _on_file_dialog_dir_selected(dir: String) -> void:
	gss_path = dir

func run_config_editor() -> void:
	var err = OS.execute("notepad", [config_editor_path])
	os_error("Execute config editor", err)

func _on_install_mod_button_pressed() -> void:
	file_dialog.file_mode = FileDialog.FileMode.FILE_MODE_OPEN_FILE
	file_dialog.root_subfolder = "%s\\Downloads" % OS.get_environment("USERPROFILE")
	file_dialog.popup()

func _on_configure_button_pressed() -> void:
	config_panel.visible = !config_panel.visible

func _on_refresh_list_button_pressed() -> void:
	update_mod_list()

func _on_file_dialog_file_selected(path: String) -> void:
	var err = OS.execute("%s/7z.exe" % root_path, ["x", path, "-o" + "%s/mod" % root_path, "-y"])
	if os_error("Execute 7z", err): return
	
	var names = DirAccess.get_directories_at("%s/mod" % root_path)
	var mod_name = names[0]  # there can be more, only if the program crashes. sucks to suck
	
	err = DirAccess.make_dir_absolute("%s/Simulatorita/Binaries/Win64/Mods/%s" % [gss_path, mod_name])
	if error("Make directory for mod", err): return
	
	err = Files.copy_recursive(
		"%s/mod/%s" % [root_path, mod_name],
		"%s/Simulatorita/Binaries/Win64/Mods/%s" % [gss_path, mod_name]
	)
	if error("Copy from mod to mods folder", err): return
	err = Files.remove_recursive("%s/mod/%s" % [root_path, mod_name])
	if error("Remove mod", err): return
	
	var file = FileAccess.open("%s/Simulatorita/Binaries/Win64/Mods/mods.txt" % gss_path, FileAccess.READ)
	if file:
		var lines = []
		while not file.eof_reached():
			lines.append(file.get_line())
		file.close()
		lines.append(mod_name + " : 1")
		
		file = FileAccess.open("%s/Simulatorita/Binaries/Win64/Mods/mods.txt" % gss_path, FileAccess.WRITE)
		if file:
			for i in range(len(lines)):
				file.store_string(lines[i])
				if i < len(lines) - 1:
					file.store_string("\n")
			file.close()
			update_mod_list()
			print("Mod added successfully")
		else:
			err = FileAccess.get_open_error()
			error("Open mods.txt file", err)
	else:
		err = FileAccess.get_open_error()
		error("Open mods.txt file", err)

## Returns a boolean that if is true, action didn't complete successfully
func error(action: String, err: int) -> bool:
	if err:
		print("%s status: %s [%s]" % [action, error_string(err), err])
		return true
	return false

## `error` function, but suited for `OS.execute` returns
func os_error(action: String, err: int) -> bool:
	if err:
		print("%s exit code: FAILED [%s]" % [action, err])
		return true
	return false
