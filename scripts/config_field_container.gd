class_name ConfigFieldContainer extends VBoxContainer

signal write_value(config_field_name: String, value: String)

var config_field: ConfigParser.ConfigField
var last_valid_string: String = ""
var child: Node


static func with(cfg_field: ConfigParser.ConfigField) -> ConfigFieldContainer:
	var cfg_field_container = preload("res://scenes/config_field_container.tscn").instantiate()
	cfg_field_container.config_field = cfg_field
	cfg_field_container.post_set_config_field()
	return cfg_field_container


func to_ue(key) -> String:
	match key:
		KEY_0:
			return "ZERO"
		KEY_1:
			return "ONE"
		KEY_2:
			return "TWO"
		KEY_3:
			return "THREE"
		KEY_4:
			return "FOUR"
		KEY_5:
			return "FIVE"
		KEY_6:
			return "SIX"
		KEY_7:
			return "SEVEN"
		KEY_8:
			return "EIGHT"
		KEY_9:
			return "NINE"
		KEY_ESCAPE:
			return "ESCAPE"
		KEY_TAB:
			return "TAB"
		KEY_BACKSPACE:
			return "BACKSPACE"
		KEY_ENTER:
			return "RETURN"
		KEY_PAUSE:
			return "PAUSE"
		KEY_PRINT:
			return "PRINT_SCREEN"
		KEY_CLEAR:
			return "CLEAR"
		KEY_HOME:
			return "HOME"
		KEY_END:
			return "END"
		KEY_LEFT:
			return "LEFT_ARROW"
		KEY_UP:
			return "UP_ARROW"
		KEY_RIGHT:
			return "RIGHT_ARROW"
		KEY_DOWN:
			return "DOWN_ARROW"
		KEY_PAGEUP:
			return "PAGE_UP"
		KEY_PAGEDOWN:
			return "PAGE_DOWN"
		KEY_CAPSLOCK:
			return "CAPS_LOCK"
		KEY_NUMLOCK:
			return "NUM_LOCK"
		KEY_SCROLLLOCK:
			return "SCROLL_LOCK"
		KEY_F1:
			return "F1"
		KEY_F2:
			return "F2"
		KEY_F3:
			return "F3"
		KEY_F4:
			return "F4"
		KEY_F5:
			return "F5"
		KEY_F6:
			return "F6"
		KEY_F7:
			return "F7"
		KEY_F8:
			return "F8"
		KEY_F9:
			return "F9"
		KEY_F10:
			return "F10"
		KEY_F11:
			return "F11"
		KEY_F12:
			return "F12"
		KEY_F13:
			return "F13"
		KEY_F14:
			return "F14"
		KEY_F15:
			return "F15"
		KEY_F16:
			return "F16"
		KEY_F17:
			return "F17"
		KEY_F18:
			return "F18"
		KEY_F19:
			return "F19"
		KEY_F20:
			return "F20"
		KEY_F21:
			return "F21"
		KEY_F22:
			return "F22"
		KEY_F23:
			return "F23"
		KEY_F24:
			return "F24"
		KEY_KP_MULTIPLY:
			return "MULTIPLY"
		KEY_KP_DIVIDE:
			return "DIVIDE"
		KEY_KP_SUBTRACT:
			return "SUBTRACT"
		KEY_KP_PERIOD:
			return "DECIMAL"
		KEY_KP_ADD:
			return "ADD"
		KEY_KP_0:
			return "NUM_ZERO"
		KEY_KP_1:
			return "NUM_ONE"
		KEY_KP_2:
			return "NUM_TWO"
		KEY_KP_3:
			return "NUM_THREE"
		KEY_KP_4:
			return "NUM_FOUR"
		KEY_KP_5:
			return "NUM_FIVE"
		KEY_KP_6:
			return "NUM_SIX"
		KEY_KP_7:
			return "NUM_SEVEN"
		KEY_KP_8:
			return "NUM_EIGHT"
		KEY_KP_9:
			return "NUM_NINE"
		KEY_HELP:
			return "HELP"
		KEY_VOLUMEDOWN:
			return "VOLUME_DOWN"
		KEY_VOLUMEMUTE:
			return "VOLUME_MUTE"
		KEY_VOLUMEUP:
			return "VOLUME_UP"
		KEY_MEDIAPLAY:
			return "MEDIA_PLAY_PAUSE"
		KEY_MEDIASTOP:
			return "MEDIA_STOP"
		KEY_MEDIANEXT:
			return "MEDIA_NEXT_TRACK"
		KEY_MEDIAPREVIOUS:
			return "MEDIA_PREV_TRACK"
		KEY_LAUNCHMAIL:
			return "LAUNCH_MAIL"
		KEY_LAUNCHMEDIA:
			return "LAUNCH_MEDIA_SELECT"
		KEY_PLUS:
			return "OEM_PLUS"
		KEY_COMMA:
			return "OEM_COMMA"
		KEY_MINUS:
			return "OEM_MINUS"
		KEY_PERIOD:
			return "OEM_PERIOD"
		KEY_INSERT:
			return "INS"
		KEY_DELETE:
			return "DEL"
		KEY_PRINT:
			return "PRINT_SCREEN"
		KEY_HOMEPAGE:
			return "BROWSER_HOME"
		KEY_LAUNCH0:
			return "LAUNCH_APP1"
		KEY_LAUNCH1:
			return "LAUNCH_APP2"
		KEY_FAVORITES:
			return "BROWSER_FAVORITES"
		KEY_SEARCH:
			return "BROWSER_SEARCH"
		KEY_FORWARD:
			return "BROWSER_FORWARD"
		KEY_BACK:
			return "BROWSER_BACK"
		_:
			# Handle single-letter key codes
			var string = OS.get_keycode_string(key)
			if string.length() == 1:
				return string
			return ""


func post_set_config_field() -> void:
	match config_field.type.string_representation:
		"string":
			child = LineEdit.new()
			child.placeholder_text = "text (string)"
			child.text_submitted.connect(_text_submitted)
		"int":
			child = LineEdit.new()
			child.placeholder_text = "number (integer)"
			child.text_submitted.connect(_int_submitted)
		"float":
			child = LineEdit.new()
			child.placeholder_text = "floating-point number (float)"
			child.text_submitted.connect(_float_submitted)
		"bool":
			child = CheckBox.new()
			child.toggled.connect(_bool_submitted)
		"Key":
			child = Button.new()
			child.pressed.connect(_key_button_pressed)
		"list":
			if config_field.type.list_type == "ModifierKey":
				child = ModifierKeySelect.with(config_field.value)
				child.modifier_keys_selected.connect(_on_modifier_keys_selected)
			else:
				print("Lists are currently not supported for type: ", config_field.type.list_type)
		_:
			print(
				"Unsupported type for ConfigFieldContainer: ",
				config_field.type.string_representation
			)

	if child is LineEdit:
		if config_field.type.string_representation == "string":
			child.text = config_field.value.left(-1).right(-1)
		else:
			child.text = config_field.value
			last_valid_string = child.text
	elif child is CheckBox:
		child.button_pressed = config_field.value == "true"
	elif child is Button:
		child.text = config_field.value.replace("Key.", "") + " (Press to set key)"
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _ready() -> void:
	set_process_input(false)
	$OptionsContainer/FieldNameLabel.text = config_field.name.capitalize()
	$DescriptionLabel.text = config_field.description
	$OptionsContainer/Placeholder.replace_by(child)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var ue = to_ue(event.keycode)
		if ue.is_empty():
			child.text = "No key code found for pressed key. Waiting for key press..."
		else:
			child.text = ue + " (Press to set key)"
			set_process_input(false)
			write_value.emit(config_field.name, "Key." + ue)


func _on_modifier_keys_selected(list: String) -> void:
	write_value.emit(config_field.name, list)


func _bool_submitted(toggled_on: bool) -> void:
	write_value.emit(config_field.name, str(toggled_on))


func _key_button_pressed() -> void:
	child.text = "Waiting for key press..."
	set_process_input(true)


func _int_submitted(text: String) -> void:
	if !text.is_valid_int():
		child.text = last_valid_string
	else:
		child.text = text
		last_valid_string = text
		write_value.emit(config_field.name, text)


func _float_submitted(text: String) -> void:
	var regex = RegEx.create_from_string(r"^\d+(\.(?<after_dot>\d+))?$").search(text)
	if regex != null:
		var chars_after_dot = regex.get_string("after_dot").length()

		match config_field.type.arg_enum:
			ConfigParser.ArgEnum.FLOAT_PRECISION:
				if chars_after_dot > config_field.type.precision:
					child.text = last_valid_string
					return
			ConfigParser.ArgEnum.FLOAT_PRECISION_RANGE:
				var float_num = float(text)
				if (
					chars_after_dot > config_field.type.precision
					or float_num > config_field.type.range_max_float
					or float_num < config_field.type.range_min_float
				):
					child.text = last_valid_string
					return
			ConfigParser.ArgEnum.FLOAT_RANGE:
				var float_num = float(text)
				if (
					float_num > config_field.type.range_max_float
					or float_num < config_field.type.range_min_float
				):
					child.text = last_valid_string
					return

		last_valid_string = text
		write_value.emit(config_field.name, text)
	else:
		child.text = last_valid_string


func _text_submitted(text: String) -> void:
	write_value.emit(config_field.name, '"%s"' % text.c_escape())


func _on_reset_to_default_button_pressed() -> void:
	if child is LineEdit:
		if config_field.type.string_representation == "string":
			child.text = config_field.default.left(-1).right(-1)
		else:
			child.text = config_field.default
		last_valid_string = child.text
	elif child is CheckBox:
		child.button_pressed = config_field.default == "true"
	elif child is Button:
		child.text = config_field.default.replace("Key.", "") + " (Press to set key)"
	elif child is ModifierKeySelect:
		child.change_value(config_field.default)
	write_value.emit(config_field.name, config_field.default)
