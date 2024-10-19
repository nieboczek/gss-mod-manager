extends Node

const VALID_KEYS := [
	'LEFT_MOUSE_BUTTON', 'RIGHT_MOUSE_BUTTON', 'CANCEL', 'MIDDLE_MOUSE_BUTTON', 'XBUTTON_ONE',
	'XBUTTON_TWO', 'BACKSPACE', 'TAB', 'CLEAR', 'RETURN', 'PAUSE', 'CAPS_LOCK', 'IME_KANA',
	'IME_HANGUEL', 'IME_HANGUL', 'IME_ON', 'IME_JUNJA', 'IME_FINAL', 'IME_HANJA', 'IME_KANJI',
	'IME_OFF', 'ESCAPE', 'IME_CONVERT', 'IME_NONCONVERT', 'IME_ACCEPT', 'IME_MODECHANGE', 'SPACE',
	'PAGE_UP', 'PAGE_DOWN', 'END', 'HOME', 'LEFT_ARROW', 'UP_ARROW', 'RIGHT_ARROW', 'DOWN_ARROW',
	'SELECT', 'PRINT', 'EXECUTE', 'PRINT_SCREEN', 'INS', 'DEL', 'HELP', 'ZERO', 'ONE', 'TWO',
	'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE', 'A', 'B', 'C', 'D', 'E', 'F', 'G',
	'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
	'LEFT_WIN', 'RIGHT_WIN', 'APPS', 'SLEEP', 'NUM_ZERO', 'NUM_ONE', 'NUM_TWO', 'NUM_THREE',
	'NUM_FOUR', 'NUM_FIVE', 'NUM_SIX', 'NUM_SEVEN', 'NUM_EIGHT', 'NUM_NINE', 'MULTIPLY', 'ADD',
	'SEPARATOR', 'SUBTRACT', 'DECIMAL', 'DIVIDE', 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8',
	'F9', 'F10', 'F11', 'F12', 'F13', 'F14', 'F15', 'F16', 'F17', 'F18', 'F19', 'F20', 'F21', 'F22',
	'F23', 'F24', 'NUM_LOCK', 'SCROLL_LOCK', 'BROWSER_BACK', 'BROWSER_FORWARD', 'BROWSER_REFRESH',
	'BROWSER_STOP', 'BROWSER_SEARCH', 'BROWSER_FAVORITES', 'BROWSER_HOME', 'VOLUME_MUTE',
	'VOLUME_DOWN', 'VOLUME_UP', 'MEDIA_NEXT_TRACK', 'MEDIA_PREV_TRACK', 'MEDIA_STOP', 
	'MEDIA_PLAY_PAUSE', 'LAUNCH_MAIL', 'LAUNCH_MEDIA_SELECT', 'LAUNCH_APP1', 'LAUNCH_APP2',
	'OEM_ONE', 'OEM_PLUS', 'OEM_COMMA', 'OEM_MINUS', 'OEM_PERIOD', 'OEM_TWO', 'OEM_THREE',
	'OEM_FOUR', 'OEM_FIVE', 'OEM_SIX', 'OEM_SEVEN', 'OEM_EIGHT', 'OEM_102', 'IME_PROCESS', 'PACKET',
	'ATTN', 'CRSEL', 'EXSEL', 'EREOF', 'PLAY', 'ZOOM', 'PA1', 'OEM_CLEAR'
]

var logs: String = ""
var bad_config: bool = false

enum ArgEnum { FLOAT_RANGE, INT_RANGE, FLOAT_PRECISION, FLOAT_PRECISION_RANGE, NONE }

class Type:
	var string_representation: String
	var validation_func: Callable
	var list_type: String
	var range_min_int: int
	var range_max_int: int
	var range_min_float: float
	var range_max_float: float
	var precision: int
	var arg_enum: ArgEnum = ArgEnum.NONE
	
	static func list(validation_function: Callable, list_lua_type: String) -> Type:
		var type = new()
		type.string_representation = "list"
		type.validation_func = validation_function
		type.list_type = list_lua_type
		return type
	
	static func integer(validation_function: Callable, range_min: int, range_max: int) -> Type:
		var type = new()
		type.string_representation = "int"
		type.validation_func = validation_function
		type.range_min_int = range_min
		type.range_max_int = range_max
		type.arg_enum = ArgEnum.INT_RANGE
		return type
	
	static func float_num(validation_function: Callable, range_min: float, range_max: float, max_precision: int, argument_enum: ArgEnum) -> Type:
		var type = new()
		type.string_representation = "float"
		type.validation_func = validation_function
		type.range_min_float = range_min
		type.range_max_float = range_max
		type.precision = max_precision
		type.arg_enum = argument_enum
		return type
	
	static func with(as_string: String, validation_function: Callable) -> Type:
		var type = new()
		type.string_representation = as_string
		type.validation_func = validation_function
		return type
	
	func validate(string: String) -> bool:
		if arg_enum == ArgEnum.INT_RANGE:
			return validation_func.call(string, range_min_int, range_max_int)
		elif arg_enum == ArgEnum.FLOAT_RANGE:
			return validation_func.call(string, range_min_float, range_max_float)
		elif arg_enum == ArgEnum.FLOAT_PRECISION:
			return validation_func.call(string, precision)
		elif arg_enum == ArgEnum.FLOAT_PRECISION_RANGE:
			return validation_func.call(string, range_min_float, range_max_float, precision)
		elif list_type:
			return validation_func.call(string, list_type)
		return validation_func.call(string)

class ConfigField:
	var name: String
	var description: String
	var type: Type
	var value: String
	var default: String

func parse(ue_root: String, mod_name: String) -> Array[ConfigField]:
	# CAUTION: Welcome to RegEx hell! Please consider using https://regexr.com/
	logs = ""
	bad_config = false
	var fields: Array[ConfigField] = []
	var file = FileAccess.open(ue_root + "/Mods/%s/Scripts/config.lua" % mod_name, FileAccess.READ)
	if file:
		logs += "@CP: Parsing config for %s...\n" % mod_name
		var regex = RegEx.new()
		var text = file.get_as_text(true)
		var lines := text.split('\n')
		
		if lines[0] != "local config = {":
			warn("Expected first line to be \"local config = {\"")
			return []
		lines.remove_at(0)
		
		var current_field := ConfigField.new()
		var line_number := 2  # Line 1 was removed before
		
		for line in lines:
			line = line.strip_edges()
			if line.begins_with("--@description "):
				if current_field.description:
					current_field.description += '\n' + line.trim_prefix("--@description ")
				else:
					current_field.description = line.trim_prefix("--@description ")
			
			
			elif line.begins_with("--@type "):
				if current_field.type:
					warn("Doubled --@type [Line %s]" % line_number)
				
				regex.compile(r"--@type (?<type>int|float)( precision=(?<precision>\d+))?( range=(?<range_min>[+-]?\d+)\.\.(?<range_max>[+-]?\d+))?( precision=(?<precision2>\d+))?")
				var re_match = regex.search(line)
				
				if re_match:
					var range_min = re_match.get_string("range_min")
					var range_max = re_match.get_string("range_max")
					var precision = re_match.get_string("precision")
					var precision2 = re_match.get_string("precision2")
					var has_precision_or_range = range_min or precision or precision2
					if has_precision_or_range:
						if precision and precision2:
							warn("Doubled precision parameter [Line %s]" % line_number)
						if precision2 and precision.is_empty():
							precision = precision2
						
						if re_match.get_string("type") == "int":
							if precision or precision2:
								warn("Precision not allowed with int [Line %s]" % line_number)
							current_field.type = Type.integer(validate_with_range_int, int(range_min), int(range_max))
						else:
							if precision.is_empty():
								current_field.type = Type.float_num(validate_with_range_float, float(range_min), float(range_max), 0, ArgEnum.FLOAT_RANGE)
							elif range_min.is_empty():
								current_field.type = Type.float_num(validate_with_precision_float, 0, 0, int(precision), ArgEnum.FLOAT_PRECISION)
							else:
								current_field.type = Type.float_num(validate_with_range_precision_float, float(range_min), float(range_max), int(precision), ArgEnum.FLOAT_PRECISION_RANGE)
						
						line_number += 1
						continue
				
				regex.compile(r"--@type list\[(?<type>.+)\]")
				re_match = regex.search(line)
				
				if re_match:
					var re_type = re_match.get_string("type")
					if re_type == "ModifierKey":
						current_field.type = Type.list(validate_list, re_type)
					else:
						warn("Unsupported type for list: %s [Line %s]" % [re_type, line_number])
				else:
					var type = line.trim_prefix("--@type ")
					match type:
						"Key":
							current_field.type = Type.with("Key", func(string: String):
								return string.trim_prefix("Key.") in VALID_KEYS
							)
						"int":
							current_field.type = Type.with("int", func(string: String):
								return string.is_valid_int()
							)
						"float":
							current_field.type = Type.with("float", func(string: String):
								return string.is_valid_float()
							)
						"bool":
							current_field.type = Type.with("bool", func(string: String):
								return string == "true" or string == "false"
							)
						"string":
							current_field.type = Type.with("string", validate_string)
						_:
							warn("Unsupported type: %s [Line %s]" % [type, line_number])
					
					if current_field.default and current_field.type and \
					   !current_field.type.validate(current_field.default):
						warn("Invalid default value: %s [Line %s]" % [current_field.default, line_number])
			
			
			elif line.begins_with("--@default "):
				if current_field.default:
					warn("Doubled --@default [Line %s]" % line_number)
				
				current_field.default = line.trim_prefix("--@default ")
				if current_field.type and !current_field.type.validate(current_field.default):
					warn("Invalid default value: %s [Line %s]" % [current_field.default, line_number])
			
			else:
				regex.compile(r"^\s*(?<name>[a-zA-Z_]\w*)\s*=\s*(?<value>.*?),?\s*$")
				var re_match = regex.search(line)
				if re_match:
					current_field.name = re_match.get_string("name")
					if !current_field.description:
						warn("Missing @description declaration for %s [Line %s]" % [current_field.name, line_number])
					if !current_field.type:
						warn("Missing @type declaration for %s [Line %s]" % [current_field.name, line_number])
					if !current_field.default:
						warn("Missing @default declaration for %s [Line %s]" % [current_field.name, line_number])
					
					var value = re_match.get_string("value")
					if current_field.type and !current_field.type.validate(value):
						warn("Invalid value: %s [Line %s]" % [value, line_number])
					current_field.value = value
					fields.append(current_field)
					current_field = ConfigField.new()
			
			line_number += 1
		
		if bad_config:
			return []
		return fields
	else:
		var err = FileAccess.get_open_error()
		warn("Open config status: %s [%s]" % [error_string(err), err])
	return []

func warn(msg: String) -> void:
	logs += "@CP: %s\n" % msg
	bad_config = true

func validate_list(string: String, type: String) -> bool:
	var allowed_values_regex := ""
	match type:
		"string":
			allowed_values_regex = "('([^'\\\\]|\\\\.)*'|\"([^\"\\\\]|\\\\.)*\")"
		"ModifierKey":
			allowed_values_regex = r"ModifierKey\.(SHIFT|ALT|CONTROL)"
		"int":
			allowed_values_regex = r"\d+"
		"float":
			allowed_values_regex = r"\d+(\.\d+)?"
	assert(allowed_values_regex != "", "No RegEx provided for type %s at validate_list" % type)
	var regex = RegEx.create_from_string(r"^\s*{\s*((%s\s*,\s*)*%s\s*(,\s*)?)?\s*}\s*$" % [allowed_values_regex, allowed_values_regex])
	return regex.search(string) != null

func validate_string(string: String) -> bool:
	var regex = RegEx.create_from_string("^\\s*('([^'\\\\]|\\\\.)*'|\"([^\"\\\\]|\\\\.)*\")\\s*$")
	return regex.search(string) != null

func validate_with_range_int(string: String, range_min: int, range_max: int) -> bool:
	var integer = int(string)
	return integer >= range_min and integer <= range_max

func validate_with_range_float(string: String, range_min: float, range_max: float) -> bool:
	var float_num = float(string)
	return float_num >= range_min and float_num <= range_max

func validate_with_precision_float(string: String, max_precision: int) -> bool:
	var regex = RegEx.create_from_string(r"^\d+(\.\d{1,%s})?$" % max_precision)
	return regex.search(string) != null
	
func validate_with_range_precision_float(string: String, range_min: float, range_max: float, max_precision: int) -> bool:
	var regex = RegEx.create_from_string(r"^\d+(\.\d{1,%s})?$" % max_precision)
	var float_num = float(string)
	return float_num >= range_min and float_num <= range_max and regex.search(string) != null
