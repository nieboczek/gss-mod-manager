extends VBoxContainer

@onready var check_for_updates_checkbox = $CheckForUpdates/OptionsContainer/CheckBox
@onready
var launch_gss_with_gui_console_checkbox = $LaunchGSSWithGUIConsole/OptionsContainer/CheckBox

var changed_values: Dictionary = {}
var ue4ss_setting_lines: Array[String] = []
var check_for_updates: bool


func save(ue_root: String, config: ConfigFile) -> Error:
	for value_name in changed_values:
		var value = changed_values[value_name]
		match value_name:
			"check_for_updates":
				check_for_updates = value
			"launch_gss_with_gui_console":
				var err = save_launch_gss_with_gui_console(ue_root, value)
				if err:
					return err
				continue
			_:
				push_error("Unknown value name with no handler: " + value_name)
				return ERR_METHOD_NOT_FOUND

		config.set_value("main", value_name, value)

	config.save("user://config")
	return OK


func cancel() -> void:
	changed_values = {}


func load_from(ue_root: String, config: ConfigFile) -> Error:
	check_for_updates = config.get_value("main", "check_for_updates", true)
	check_for_updates_checkbox.button_pressed = check_for_updates

	var err = load_launch_gss_with_gui_console(ue_root)
	if err:
		return err

	return OK


func save_launch_gss_with_gui_console(ue_root: String, value: bool) -> Error:
	var file = FileAccess.open(ue_root + "/UE4SS-settings.ini", FileAccess.WRITE)
	if file:
		for i in range(len(ue4ss_setting_lines)):
			if ue4ss_setting_lines[i].begins_with("GuiConsoleVisible"):
				ue4ss_setting_lines[i] = "GuiConsoleVisible = " + "1" if value else "0"

			file.store_string(ue4ss_setting_lines[i])
			if i < len(ue4ss_setting_lines) - 1:
				file.store_string("\n")

		file.close()
		return OK
	else:
		return FileAccess.get_open_error()


func load_launch_gss_with_gui_console(ue_root: String) -> Error:
	var file = FileAccess.open(ue_root + "/UE4SS-settings.ini", FileAccess.READ)
	if file:
		while not file.eof_reached():
			ue4ss_setting_lines.append(file.get_line())
		file.close()

		for i in range(len(ue4ss_setting_lines)):
			if ue4ss_setting_lines[i].begins_with("GuiConsoleVisible"):
				launch_gss_with_gui_console_checkbox.button_pressed = (
					ue4ss_setting_lines[i].replace("GuiConsoleVisible = ", "") == "1"
				)
				break

		return OK
	else:
		return FileAccess.get_open_error()


func _on_check_for_updates_toggled(toggled_on: bool) -> void:
	changed_values["check_for_updates"] = toggled_on


func _on_reset_check_for_updates_pressed() -> void:
	changed_values["check_for_updates"] = true


func _on_launch_gss_with_gui_console_toggled(toggled_on: bool) -> void:
	changed_values["launch_gss_with_gui_console"] = toggled_on


func _on_reset_launch_gss_with_gui_console_pressed() -> void:
	changed_values["launch_gss_with_gui_console"] = false
