class_name ConfigFieldContainer extends VBoxContainer

signal write_value(config_field_name: String, value)

var config_field: ConfigParser.ConfigField
var last_valid_key_string: String = ""
var child: Node

const ArgEnum = ConfigParser.ArgEnum

static func with(cfg_field: ConfigParser.ConfigField) -> ConfigFieldContainer:
	var cfg_field_container = preload("res://scenes/config_field_container.tscn").instantiate()
	cfg_field_container.config_field = cfg_field
	cfg_field_container.post_set_config_field()
	return cfg_field_container

func post_set_config_field() -> void:
	# TODO: Replace SpinBox with something that won't add 0000000001 at the end
	match config_field.type.string_representation:
		"string":
			child = LineEdit.new()
			child.text_submitted.connect(_text_submitted)
		"int":
			child = SpinBox.new()
			child.value_changed.connect(_number_submitted)
			if config_field.type.arg_enum == ArgEnum.INT_RANGE:
				child.min_value = config_field.type.range_min_int
				child.max_value = config_field.type.range_max_int
			else:
				child.allow_lesser = true
				child.allow_greater = true
		"float":
			child = SpinBox.new()
			child.value_changed.connect(_number_submitted)
			
			if config_field.type.arg_enum == ArgEnum.FLOAT_RANGE or config_field.type.arg_enum == ArgEnum.FLOAT_PRECISION_RANGE:
				child.min_value = config_field.type.range_min_float
				child.max_value = config_field.type.range_max_float
			else:
				child.allow_lesser = true
				child.allow_greater = true
			
			if config_field.type.arg_enum == ArgEnum.FLOAT_PRECISION or config_field.type.arg_enum == ArgEnum.FLOAT_PRECISION_RANGE:
				child.step = 0.1 ** config_field.type.precision
			else:
				child.step = 0
		"Key":
			# TODO: Use something user-friendlier
			child = LineEdit.new()
			child.text_submitted.connect(_key_submitted)
		"list:ModifierKey":
			pass  # TODO: this
		_:
			print("Unsupported type for ConfigFieldContainer: %s" % config_field.type.string_representation)

func _ready() -> void:
	$OptionsContainer/FieldNameLabel.text = config_field.name.capitalize()
	$DescriptionLabel.text = config_field.description
	if child:
		child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		$OptionsContainer/Placeholder.replace_by(child)

func _key_submitted(text: String):
	if text in ConfigParser.VALID_KEYS:
		last_valid_key_string = text
	else:
		child.text = last_valid_key_string

func _number_submitted(number: float):
	print('submitted number: ', number)
	write_value.emit(config_field.name, number)

func _text_submitted(text: String):
	# TODO: Warn about bad escaping
	print('submitted text: ', text)
	write_value.emit(config_field.name, "\"%s\"" % text.c_unescape())
