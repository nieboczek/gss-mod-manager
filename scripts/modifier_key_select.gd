class_name ModifierKeySelect extends VBoxContainer

signal modifier_keys_selected(list: String)

var control_toggled: bool
var shift_toggled: bool
var alt_toggled: bool

static func with(value: String) -> ModifierKeySelect:
	var select = preload("res://scenes/modifier_key_select.tscn").instantiate()
	var keys = value.replace('{', "").replace('}', "").split(',')
	
	for key in keys:
		key = key.strip_edges()
		match key:
			"ModifierKey.CONTROL":
				select.control_toggled = true
				select.get_node("ControlCheck").button_pressed = true
			"ModifierKey.SHIFT":
				select.shift_toggled = true
				select.get_node("ShiftCheck").button_pressed = true
			"ModifierKey.ALT":
				select.alt_toggled = true
				select.get_node("AltCheck").button_pressed = true
	
	return select

func emit() -> void:
	var selected_keys: PackedStringArray = []
	
	if control_toggled: selected_keys.append("ModifierKey.CONTROL")
	if shift_toggled: selected_keys.append("ModifierKey.SHIFT")
	if alt_toggled: selected_keys.append("ModifierKey.ALT")
	
	modifier_keys_selected.emit("{ %s }" % ", ".join(selected_keys))

func _on_control_check_toggled(toggled_on: bool) -> void:
	control_toggled = toggled_on
	emit()

func _on_shift_check_toggled(toggled_on: bool) -> void:
	shift_toggled = toggled_on
	emit()

func _on_alt_check_toggled(toggled_on: bool) -> void:
	alt_toggled = toggled_on
	emit()
