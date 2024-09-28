class_name ModLoaderContainer extends HBoxContainer

@onready var mod_loader_install_button = $ModLoaderInstallButton
@onready var mod_loader_label = $ModLoaderLabel

var is_installed := false
var mm: ModManager

func _on_mod_loader_install_button_pressed() -> void:
	if is_installed:
		Files.remove_recursive("%s/Simulatorita/Binaries/Win64/Mods" % mm.gss_path)
		DirAccess.remove_absolute("%s/Simulatorita/Binaries/Win64/UE4SS.dll" % mm.gss_path)
		DirAccess.remove_absolute("%s/Simulatorita/Binaries/Win64/UE4SS-settings.ini" % mm.gss_path)
		DirAccess.remove_absolute("%s/Simulatorita/Binaries/Win64/dwmapi.dll" % mm.gss_path)
	else:
		Files.copy_recursive("%s/UE4SS" % mm.root_path, "%s/Simulatorita/Binaries/Win64" % mm.gss_path)
	set_installed(!is_installed)
	mm.update_mod_list()

func check_installed() -> void:
	var installed = FileAccess.file_exists("%s/Simulatorita/Binaries/Win64/UE4SS.dll" % mm.gss_path)
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
