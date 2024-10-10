class_name ModManager extends Control

@onready var main = $MarginContainer/MainContainer
@onready var file_dialog = $FileDialog
@onready var config_panel = $PanelMarginContainer
@onready var mod_manager_config_container = $PanelMarginContainer/PanelContainer/MarginContainer/ConfigContainer/ModManagerConfigContainer
@onready var mod_config_container = $PanelMarginContainer/PanelContainer/MarginContainer/ConfigContainer/ScrollContainer/ModConfigContainer
@onready var scroll_container = $PanelMarginContainer/PanelContainer/MarginContainer/ConfigContainer/ScrollContainer
@onready var mod_containers: Control = main.get_node("MarginContainer/ScrollContainer/ModContainers")

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

# NOTE: Only test in exported!

# TODO: Make config editor
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
		container.set_configurable(FileAccess.file_exists(
			"%s/Simulatorita/Binaries/Win64/Mods/%s/Scripts/config.lua" % [gss_path, mod]
		))
		container.configure.connect(_on_configure_mod)
		container.delete.connect(_on_delete_mod)
		container.toggled.connect(_on_toggle_mod)
		non_builtin_mod_count += 1
	
	mod_list_container.set_count(non_builtin_mod_count)

func _on_configure_button_pressed() -> void:
	config_panel.show()
	mod_manager_config_container.show()

func _on_configure_mod(mod_name: String) -> void:
	var fields = ConfigParser.parse("%s/Simulatorita/Binaries/Win64/Mods/%s/Scripts/config.lua" % [gss_path, mod_name])
	for field in fields:
		var container = ConfigFieldContainer.with(field)
		mod_config_container.add_child(container)
	config_panel.show()
	scroll_container.show()

func _on_delete_mod(mod_name: String) -> void:
	if not error("Remove mod", Files.remove_mod(gss_path, mod_name)):
		update_mod_list()

func _on_toggle_mod(mod_name: String, on: bool) -> void:
	error("Toggle mod", Files.toggle_mod(gss_path, mod_name, on))

func _on_file_dialog_gss_path_selected(dir: String) -> void:
	gss_path = dir

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
func error(action: String, err: Error) -> bool:
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

func _on_save_config_button_pressed() -> void:
	print("SAVE BUTTON NOT IMPLEMENTED YET!!!")

func _on_cancel_config_button_pressed() -> void:
	config_panel.hide()
	if scroll_container.visible:
		scroll_container.hide()
		for child in mod_config_container.get_children():
			mod_config_container.remove_child(child)
	mod_manager_config_container.hide()
