class_name ModContainer extends HBoxContainer

signal toggled(mod_name: String, on: bool)
signal delete(mod_name: String)
signal configure(mod_name: String)
signal blueprint_toggled(mod_name: String, on: bool)
signal blueprint_delete(mod_name: String)

@onready var mod_name_label = $ModNameLabel
@onready var configure_button = $ConfigureButton
@onready var toggle = $Toggle

var mod_name: String
var blueprint: bool = false:
	set(value):
		configure_button.queue_free()
		blueprint = value
		mod_name_label.add_theme_color_override("font_color", Color(0.1255, 0.5, 1))

static func with(new_mod_name: String) -> ModContainer:
	var container = preload("res://scenes/mod_container.tscn").instantiate()
	container.mod_name = new_mod_name
	return container

func _ready() -> void:
	mod_name_label.text = mod_name

func set_configurable(yes: bool) -> void:
	configure_button.disabled = !yes

func set_toggled(yes: bool) -> void:
	toggle.button_pressed = yes

func _on_toggle_toggled(toggled_on: bool) -> void:
	if blueprint:
		blueprint_toggled.emit(mod_name, toggled_on)
	else:
		toggled.emit(mod_name, toggled_on)

func _on_delete_button_pressed() -> void:
	if blueprint:
		blueprint_delete.emit(mod_name)
	else:
		delete.emit(mod_name)

func _on_configure_button_pressed() -> void:
	configure.emit(mod_name)
