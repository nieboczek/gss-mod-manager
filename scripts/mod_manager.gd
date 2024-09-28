class_name ModManager extends Control

@onready var main = $MarginContainer/MainContainer
@onready var file_dialog = $FileDialog
@onready var config_panel = $ConfigPanel
@onready var mod_containers: Control = main.get_node("ScrollContainer/MarginContainer")

@onready var path_container: PathContainer = main.get_node("PathContainer")
@onready var mod_loader_container: ModLoaderContainer = main.get_node("ModLoaderContainer")
@onready var mod_list_container: ModListContainer = main.get_node("ModListContainer")

const BUILTIN_MODS: Array[String] = [
	"ActorDumperMod", "BPML_GenericFunctions", "BPModLoaderMod",
	"CheatManagerEnablerMod", "ConsoleCommandsMod", "ConsoleEnablerMod",
	"jsbLuaProfilerMod", "Keybinds", "LineTraceMod", "SplitScreenMod"
]

var root_path := OS.get_executable_path().get_base_dir()
var gss_path: String:
	set(value):
		gss_path = value
		config.set_value("main", "gss_path", gss_path)
		config.save("user://config")
		path_container.post_path_change()
		update_mod_list()
var config: ConfigFile
var config_editor_path: String
var editor_thread := Thread.new()

# NOTE: Only test in exported! (Unless you find a way to do it in the editor)

# TODO: Make editor for editing config configurable
# ^^^^^ Alternate solution: Try to make a standard on how to comment your config.
# ^^^^^ Then make the config editor built in (Topic to discuss)
# TODO: Clean up this mess
# TODO: Get icon

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
	if !mod_loader_container.is_installed:
		for child in mod_containers.get_children():
			child.queue_free()
		return
	
	for child in mod_containers.get_children():
		child.queue_free()
	
	var list = get_mod_list()
	var non_builtin_mod_count = 0
	for mod in list:
		if mod in BUILTIN_MODS:
			continue
		var container = ModContainer.with(mod)
		mod_containers.add_child(container)
		
		container.set_toggled(list[mod])
		container.configure.connect(_on_configure_mod)
		container.delete.connect(_on_delete_mod)
		container.toggled.connect(_on_toggle_mod)
		non_builtin_mod_count += 1
	
	mod_list_container.set_count(non_builtin_mod_count)

func run_config_editor() -> void:
	var err = OS.execute("notepad", [config_editor_path])
	os_error("Execute config editor", err)

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

func _on_configure_button_pressed() -> void:
	config_panel.visible = !config_panel.visible

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

func _on_file_dialog_gss_path_selected(dir: String) -> void:
	gss_path = dir

func _process(_delta: float) -> void:
	if editor_thread.is_started() and !editor_thread.is_alive():
		editor_thread.wait_to_finish()

func _ready() -> void:
	# Set self as the ModManager in containers
	path_container.mm = self
	mod_loader_container.mm = self
	mod_list_container.mm = self
	
	config = ConfigFile.new()
	var err = config.load("user://config")
	if err == ERR_FILE_NOT_FOUND:
		path_container.detect_gss()
	else:
		error("Read user config", err)
	
	var path: String = config.get_value("main", "gss_path")
	if path == null:
		path_container.detect_gss()
	else:
		gss_path = path

## Returns a boolean that if is true, action didn't complete successfully
func error(action: String, err: int) -> bool:
	if err:
		print("%s status: %s [%s]" % [action, error_string(err), err])
		return true
	return false

## `error` function, but suited for OS errors (not handled by Godot)
func os_error(action: String, err: int) -> bool:
	if err:
		print("%s exit code: FAILED [%s]" % [action, err])
		return true
	return false
