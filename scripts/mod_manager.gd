class_name ModManager extends Control

@onready var http = $HTTPRequest
@onready var main = $MarginContainer/MainContainer
@onready var file_dialog = $FileDialog
@onready var config_panel = $PanelMarginContainer
@onready
var mod_manager_config_container = $PanelMarginContainer/PanelContainer/MarginContainer/ConfigContainer/ModManagerConfigContainer
@onready
var mod_config_container = $PanelMarginContainer/PanelContainer/MarginContainer/ConfigContainer/ScrollContainer/ModConfigContainer
@onready
var mod_config_scroll_container = $PanelMarginContainer/PanelContainer/MarginContainer/ConfigContainer/ScrollContainer
@onready
var copy_log_button = $PanelMarginContainer/PanelContainer/MarginContainer/ConfigContainer/ConfigControls/CopyLogButton
@onready
var open_update_link_button = $PopupMarginContainer/PanelContainer/MainContainer/ControlsContainer/OpenUpdateLinkButton
@onready
var update_description_label = $PopupMarginContainer/PanelContainer/MainContainer/UpdateDescriptionMargin/UpdateDescriptionLabel
@onready var header_label = $PopupMarginContainer/PanelContainer/MainContainer/HeaderLabel
@onready var popup = $PopupMarginContainer
@onready var mod_containers: Control = main.get_node("MarginContainer/ScrollContainer/ModContainers")

@onready var mod_manager_label := main.get_node("ModManagerContainer/ModManagerLabel")
@onready var path_container: PathContainer = main.get_node("PathContainer")
@onready var mod_loader_container: ModLoaderContainer = main.get_node("ModLoaderContainer")
@onready var mod_list_container: ModListContainer = main.get_node("ModListContainer")

var exe_path := OS.get_executable_path().get_base_dir()
var ue_root: String
var gss_path: String:
	set(value):
		gss_path = value
		if DirAccess.dir_exists_absolute(gss_path + "/Simulatorita/Binaries/Win64/ue4ss"):
			ue_root = gss_path + "/Simulatorita/Binaries/Win64/ue4ss"
		else:
			ue_root = gss_path + "/Simulatorita/Binaries/Win64"

		config.set_value("main", "gss_path", gss_path)
		config.save("user://config")
		path_container.post_path_change()
		update_mod_list()
var config_changes: Dictionary = {}
var configured_mod: String
var config: ConfigFile

const BUILTIN_MODS: Array[String] = [
	"ActorDumperMod",
	"BPML_GenericFunctions",
	"BPModLoaderMod",
	"CheatManagerEnablerMod",
	"ConsoleCommandsMod",
	"ConsoleEnablerMod",
	"jsbLuaProfilerMod",
	"Keybinds",
	"LineTraceMod",
	"SplitScreenMod"
]
const VERSION: String = "v0.6.1"

# NOTE: Things like installing the mod loader and mods only work in exported.

# TODO: Get icon


## Returns the list of Lua mods
## Returns dictionary with the schema { mod_name (String): toggled_on (bool) }
func get_mod_list() -> Dictionary:
	var enabled: Dictionary = {}
	var file = FileAccess.open(ue_root + "/Mods/mods.txt", FileAccess.READ)
	if file:
		var lines = file.get_as_text(true).split("\n")
		for line in lines:
			var split = line.split(" : ")
			if len(split) != 2:
				continue

			var mod_name = split[0]
			var toggled_on = split[1] == "1"
			enabled[mod_name] = toggled_on
	else:
		var err = FileAccess.get_open_error()
		error("Opening mods.txt file", err)
	return enabled


## `get_mod_list`, but returns list of Blueprint mods
func get_blueprint_mod_list() -> Dictionary:
	if DirAccess.dir_exists_absolute(gss_path + "/Simulatorita/Content/Paks/LogicMods"):
		var mods := {}
		var fs_mods := DirAccess.get_files_at(gss_path + "/Simulatorita/Content/Paks/LogicMods")

		for mod in fs_mods:
			if mod.ends_with(".pak"):
				mod = mod.trim_suffix(".pak")
				mods[mod] = true
			elif mod.ends_with(".pak.disabled"):
				mod = mod.trim_suffix(".pak.disabled")
				mods[mod] = false
		return mods
	else:
		var err = DirAccess.make_dir_absolute(gss_path + "/Simulatorita/Content/Paks/LogicMods")
		if error("Create LogicMods directory", err):
			return {}
		return get_blueprint_mod_list()


## Updates the UI for mods not built-in
func update_mod_list() -> void:
	if !mod_loader_container.is_installed:
		for child in mod_containers.get_children():
			child.queue_free()
		return

	for child in mod_containers.get_children():
		child.queue_free()

	var mods = get_mod_list()
	var bp_mods = get_blueprint_mod_list()
	var non_builtin_mod_count = 0
	for mod in mods:
		if mod in BUILTIN_MODS:
			continue
		var container := ModContainer.with(mod)
		mod_containers.add_child(container)

		container.set_toggled(mods[mod])
		container.set_configurable(
			FileAccess.file_exists(ue_root + "/Mods/%s/Scripts/config.lua" % mod)
		)
		container.configure.connect(_on_configure_mod)
		container.delete.connect(_on_delete_mod)
		container.toggled.connect(_on_toggle_mod)

		non_builtin_mod_count += 1

	for mod in bp_mods:
		var container := ModContainer.with(mod)
		mod_containers.add_child(container)

		container.blueprint = true
		container.set_toggled(bp_mods[mod])
		container.set_configurable(false)
		container.blueprint_delete.connect(_on_delete_blueprint_mod)
		container.blueprint_toggled.connect(_on_toggle_blueprint_mod)

		non_builtin_mod_count += 1

	mod_list_container.set_count(non_builtin_mod_count)


func _on_configure_button_pressed() -> void:
	config_panel.show()
	mod_manager_config_container.show()
	main.hide()


func _on_configure_mod(mod_name: String) -> void:
	configured_mod = mod_name
	var fields = ConfigParser.parse(ue_root, mod_name)
	if fields.is_empty():
		var label = Label.new()
		label.text = (
			"Couldn't parse config, a new notepad window has been opened.\n"
			+ "Edit the config in notepad, then save and close notepad.\n\n"
			+ "Config parser log (there's a Copy log button below, send to #support on Discord):\n"
			+ ConfigParser.logs
		)

		copy_log_button.show()
		mod_config_container.add_child(label)
		config_panel.show()
		mod_config_scroll_container.show()
		main.hide()

		OS.execute_with_pipe("notepad", [ue_root + "/Mods/%s/Scripts/config.lua" % mod_name])
	else:
		for field in fields:
			var container = ConfigFieldContainer.with(field)
			container.write_value.connect(
				func(field_name: String, value: String): config_changes[field_name] = value
			)
			mod_config_container.add_child(container)
	config_panel.show()
	mod_config_scroll_container.show()
	main.hide()


func _on_delete_mod(mod_name: String) -> void:
	if not error("Remove mod", Files.remove_mod(ue_root, mod_name)):
		update_mod_list()


func _on_delete_blueprint_mod(mod_name: String) -> void:
	var mod_path := gss_path + "/Simulatorita/Content/Paks/LogicMods/" + mod_name
	var err := DirAccess.remove_absolute(mod_path + ".pak")
	error("Delete Blueprint .pak", err)
	err = DirAccess.remove_absolute(mod_path + ".utoc")
	error("Delete Blueprint .utoc", err)
	err = DirAccess.remove_absolute(mod_path + ".ucas")
	error("Delete Blueprint .ucas", err)
	update_mod_list()


func _on_toggle_blueprint_mod(mod_name: String, on: bool) -> void:
	var mod_path := gss_path + "/Simulatorita/Content/Paks/LogicMods/" + mod_name
	if on:
		var err := DirAccess.rename_absolute(mod_path + ".pak.disabled", mod_path + ".pak")
		error("Rename Blueprint .pak", err)
		err = DirAccess.rename_absolute(mod_path + ".utoc.disabled", mod_path + ".utoc")
		error("Rename Blueprint .utoc", err)
		err = DirAccess.rename_absolute(mod_path + ".ucas.disabled", mod_path + ".ucas")
		error("Rename Blueprint .ucas", err)
	else:
		var err := DirAccess.rename_absolute(mod_path + ".pak", mod_path + ".pak.disabled")
		error("Disable Blueprint .pak", err)
		err = DirAccess.rename_absolute(mod_path + ".utoc", mod_path + ".utoc.disabled")
		error("Disable Blueprint .utoc", err)
		err = DirAccess.rename_absolute(mod_path + ".ucas", mod_path + ".ucas.disabled")
		error("Disable Blueprint .ucas", err)


func _on_toggle_mod(mod_name: String, on: bool) -> void:
	error("Toggle mod", Files.toggle_mod(ue_root, mod_name, on))


func _on_file_dialog_gss_path_selected(dir: String) -> void:
	gss_path = dir


func _ready() -> void:
	# Set self as the ModManager in containers
	path_container.mm = self
	mod_loader_container.mm = self
	mod_list_container.mm = self

	config = ConfigFile.new()
	var err := config.load("user://config")
	if err == ERR_FILE_NOT_FOUND:
		path_container.detect_gss()
	elif err != OK:
		error("Read user config", err)

	var path: String = config.get_value("main", "gss_path")
	if path == null:
		path_container.detect_gss()
	else:
		gss_path = path

	error("Read mod manager config", mod_manager_config_container.load_from(ue_root, config))
	mod_manager_label.text = "GSS Mod Manager " + VERSION

	if mod_manager_config_container.check_for_updates:
		err = http.request("https://api.github.com/repos/nieboczek/gss-mod-manager/releases/latest")
		error("Initiate HTTP request", err)


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
	if configured_mod:
		Files.save_config(ue_root, configured_mod, config_changes)
		configured_mod = ""
		hide_config_ui()
	else:
		error("Save mod manager config", mod_manager_config_container.save(ue_root, config))
		hide_config_ui()


func _on_cancel_config_button_pressed() -> void:
	if configured_mod.is_empty():
		mod_manager_config_container.cancel()
	hide_config_ui()


func hide_config_ui() -> void:
	main.show()
	config_panel.hide()
	copy_log_button.hide()
	if mod_config_scroll_container.visible:
		mod_config_scroll_container.hide()
		for child in mod_config_container.get_children():
			mod_config_container.remove_child(child)
	mod_manager_config_container.hide()


func _on_copy_log_button_pressed() -> void:
	DisplayServer.clipboard_set("Config parser log:\n```d\n%s```" % ConfigParser.logs)


func _on_http_request_completed(
	result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	if !error("Request update data", result):
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json["tag_name"] != VERSION:
			header_label.text = (
				"A new version of GSS Mod Manager is avaliable!\n"
				+ "(current: %s; latest: %s)\n" % [VERSION, json["tag_name"]]
				+ "Update description:"
			)
			update_description_label.text = json["body"]
			open_update_link_button.show()
			popup.show()


func _on_open_update_link_button_pressed() -> void:
	OS.shell_open("https://github.com/nieboczek/gss-mod-manager/releases/latest")


func _on_close_button_pressed() -> void:
	open_update_link_button.hide()
	popup.hide()
