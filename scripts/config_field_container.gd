extends VBoxContainer

signal write_value(config_field_name: String, value)

var config_field: ConfigParser.ConfigField
@onready var options = $OptionsContainer/Options

func with(cfg_field: ConfigParser.ConfigField) -> void:
	config_field = cfg_field

func _ready() -> void:
	$FieldNameLabel.text = config_field.name.capitalize()
	match config_field.type.string_representation:
		"string":
			var line_edit = LineEdit.new()
			line_edit.text_submitted.connect(_text_submitted)
			options.add_child(line_edit)
		"int":
			pass
		"float":
			pass
		"Key":
			pass
		"list;ModifierKey":
			pass
		"float:range":
			pass
		"float:precision":
			pass
		"float:range:precision":
			pass
		_:
			print("Unsupported type for ConfigFieldContainer: %s" % config_field.type.string_representation)

func _text_submitted(text: String):
	# TODO: Warn about bad escaping?
	print('submitted text: %s' % text)
	write_value.emit(config_field.name, "\"%s\"" % text.c_unescape())
