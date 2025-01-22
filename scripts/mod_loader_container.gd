class_name ModLoaderContainer extends HBoxContainer

@onready var mod_loader_install_button = $ModLoaderInstallButton
@onready var mod_loader_label = $ModLoaderLabel

var is_installed := false
var mm: ModManager


func _on_mod_loader_install_button_pressed() -> void:
	if is_installed:
		Files.remove_recursive(mm.ue_root + "/Mods")
		DirAccess.remove_absolute(mm.ue_root + "/UE4SS.dll")
		DirAccess.remove_absolute(mm.ue_root + "/UE4SS-settings.ini")
		DirAccess.remove_absolute(mm.ue_root + "/dwmapi.dll")
	else:
		Files.copy_recursive(mm.exe_path + "/UE4SS", mm.ue_root)
	set_installed(!is_installed)
	mm.update_mod_list()


func check_installed() -> void:
	var installed = FileAccess.file_exists(mm.ue_root + "/UE4SS.dll")
	set_installed(installed)


func set_install_disabled(disabled: bool) -> void:
	mod_loader_install_button.disabled = disabled


func set_installed(installed: bool) -> void:
	is_installed = installed
	if installed:
		mod_loader_label.text = "Mod loader installed"
		mod_loader_label.add_theme_color_override("font_color", Color.GREEN)
		mod_loader_install_button.text = "Uninstall mod loader"
		mm.mod_list_container.set_install_disabled(false)
	else:
		mod_loader_label.text = "Mod loader not installed"
		mod_loader_label.add_theme_color_override("font_color", Color.RED)
		mod_loader_install_button.text = "Install mod loader"
		mm.mod_list_container.set_install_disabled(false)
