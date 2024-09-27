class_name ModContainer extends HBoxContainer

signal toggled(mod_name: String, on: bool)
signal delete(mod_name: String)
signal configure(mod_name: String)

@onready var mod_name_label = $ModNameLabel
@onready var configure_button = $ConfigureButton
@onready var toggle = $Toggle

var mod_name: String

static func with(new_mod_name: String) -> ModContainer:
	var container = preload("res://mod_container.tscn").instantiate()
	container.mod_name = new_mod_name
	return container

func _ready() -> void:
	mod_name_label.text = mod_name

func set_configurable(yes: bool):
	configure_button.disabled = !yes

func set_toggled(yes: bool):
	toggle.button_pressed = yes

func _on_toggle_toggled(toggled_on: bool) -> void:
	toggled.emit(mod_name, toggled_on)

func _on_delete_button_pressed() -> void:
	delete.emit(mod_name)

func _on_configure_button_pressed() -> void:
	configure.emit(mod_name)
