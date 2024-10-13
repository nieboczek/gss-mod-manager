class_name ConfigFieldContainer extends VBoxContainer

signal write_value(config_field_name: String, value: String)

var config_field: ConfigParser.ConfigField
var last_valid_string: String = ""
var child: Node

const ArgEnum = ConfigParser.ArgEnum

static func with(cfg_field: ConfigParser.ConfigField) -> ConfigFieldContainer:
	var cfg_field_container = preload("res://scenes/config_field_container.tscn").instantiate()
	cfg_field_container.config_field = cfg_field
	cfg_field_container.post_set_config_field()
	return cfg_field_container

func post_set_config_field() -> void:
	match config_field.type.string_representation:
		"string":
			child = LineEdit.new()
			child.text_submitted.connect(_text_submitted)
		"int":
			child = LineEdit.new()
			child.text_submitted.connect(_int_submitted)
		"float":
			child = LineEdit.new()
			child.text_submitted.connect(_float_submitted)
		"Key":
			# TODO: Use something user-friendlier
			# TODO: So you can see the list of keys or something
			child = LineEdit.new()
			child.text_submitted.connect(_key_submitted)
		"list":
			pass  # TODO: this
		_:
			print("Unsupported type for ConfigFieldContainer: ", config_field.type.string_representation)

func _ready() -> void:
	$OptionsContainer/FieldNameLabel.text = config_field.name.capitalize()
	$DescriptionLabel.text = config_field.description
	if child:
		child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		$OptionsContainer/Placeholder.replace_by(child)

func _key_submitted(text: String) -> void:
	if text in ConfigParser.VALID_KEYS:
		last_valid_string = text
		write_value.emit(config_field.name, text)
	else:
		child.text = last_valid_string

func _int_submitted(text: String) -> void:
	print("submitted int: (WIP)", text)

func _float_submitted(text: String) -> void:
	print("submitted float: ", text)
	
	var regex = RegEx.create_from_string(r"^\d+(\.(?<after_dot>\d+))?$").search(text)
	if regex != null:
		var after_dot = regex.get_string("after_dot")
		
		match config_field.type.arg_enum:
			ArgEnum.FLOAT_PRECISION:
				if len(after_dot) > config_field.type.precision:
					child.text = last_valid_string
					return
			ArgEnum.FLOAT_PRECISION_RANGE:
				var float_num = float(text)
				if len(after_dot) > config_field.type.precision or \
				   float_num > config_field.type.range_max_float or \
				   float_num < config_field.type.range_min_float:
					child.text = last_valid_string
					return
			ArgEnum.FLOAT_RANGE:
				var float_num = float(text)
				if float_num > config_field.type.range_max_float or \
				   float_num < config_field.type.range_min_float:
					child.text = last_valid_string
					return
		
		last_valid_string = text
		write_value.emit(config_field.name, text)
	else:
		child.text = last_valid_string

func _text_submitted(text: String) -> void:
	print("submitted text: ", text)
	write_value.emit(config_field.name, "\"%s\"" % text)
