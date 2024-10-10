extends Node

const KEY_REGEX := r"^Key.\b(LEFT_MOUSE_BUTTON|RIGHT_MOUSE_BUTTON|CANCEL|MIDDLE_MOUSE_BUTTON|XBUTTON_ONE|XBUTTON_TWO|BACKSPACE|TAB|CLEAR|RETURN|PAUSE|CAPS_LOCK|IME_KANA|IME_HANGUEL|IME_HANGUL|IME_ON|IME_JUNJA|IME_FINAL|IME_HANJA|IME_KANJI|IME_OFF|ESCAPE|IME_CONVERT|IME_NONCONVERT|IME_ACCEPT|IME_MODECHANGE|SPACE|PAGE_UP|PAGE_DOWN|END|HOME|LEFT_ARROW|UP_ARROW|RIGHT_ARROW|DOWN_ARROW|SELECT|PRINT|EXECUTE|PRINT_SCREEN|INS|DEL|HELP|ZERO|ONE|TWO|THREE|FOUR|FIVE|SIX|SEVEN|EIGHT|NINE|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|LEFT_WIN|RIGHT_WIN|APPS|SLEEP|NUM_ZERO|NUM_ONE|NUM_TWO|NUM_THREE|NUM_FOUR|NUM_FIVE|NUM_SIX|NUM_SEVEN|NUM_EIGHT|NUM_NINE|MULTIPLY|ADD|SEPARATOR|SUBTRACT|DECIMAL|DIVIDE|F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|F13|F14|F15|F16|F17|F18|F19|F20|F21|F22|F23|F24|NUM_LOCK|SCROLL_LOCK|BROWSER_BACK|BROWSER_FORWARD|BROWSER_REFRESH|BROWSER_STOP|BROWSER_SEARCH|BROWSER_FAVORITES|BROWSER_HOME|VOLUME_MUTE|VOLUME_DOWN|VOLUME_UP|MEDIA_NEXT_TRACK|MEDIA_PREV_TRACK|MEDIA_STOP|MEDIA_PLAY_PAUSE|LAUNCH_MAIL|LAUNCH_MEDIA_SELECT|LAUNCH_APP1|LAUNCH_APP2|OEM_ONE|OEM_PLUS|OEM_COMMA|OEM_MINUS|OEM_PERIOD|OEM_TWO|OEM_THREE|OEM_FOUR|OEM_FIVE|OEM_SIX|OEM_SEVEN|OEM_EIGHT|OEM_102|IME_PROCESS|PACKET|ATTN|CRSEL|EXSEL|EREOF|PLAY|ZOOM|PA1|OEM_CLEAR)\b$"
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
	
	static func list(as_string: String, validation_function: Callable, list_lua_type: String) -> Type:
		var type = new()
		type.string_representation = as_string
		type.validation_func = validation_function
		type.list_type = list_lua_type
		return type
	
	static func integer(as_string: String, validation_function: Callable, range_min: int, range_max: int) -> Type:
		var type = new()
		type.string_representation = as_string
		type.validation_func = validation_function
		type.range_min_int = range_min
		type.range_max_int = range_max
		type.arg_enum = ArgEnum.INT_RANGE
		return type
	
	static func float_num(as_string: String, validation_function: Callable, range_min: float, range_max: float, max_precision: int, argument_enum: ArgEnum) -> Type:
		var type = new()
		type.string_representation = as_string
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
	var default: String
	static func with(desc: String, field_type: Type, field_default: String) -> ConfigField:
		var config_field = new()
		config_field.description = desc
		config_field.type = field_type
		config_field.default = field_default
		return config_field
	
	func _to_string() -> String:
		return "ConfigField(%s)" % name


func parse(path: String) -> Array[ConfigField]:
	# CAUTION: Welcome to RegEx hell! Please consider using https://regexr.com/
	var fields: Array[ConfigField] = []
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var regex = RegEx.new()
		var text = file.get_as_text(true)
		var lines := text.split('\n')
		
		regex.compile(r"^\s*(local )?[a-zA-Z_]\w* ?= ?{\s*(?!.)$")
		var re_match = regex.search(lines[0])
		
		if !re_match.get_string():
			print("@ConfigParser: Expected first line to start the variable assignment")
			return []
		
		lines.remove_at(0)
		
		var current_field := ConfigField.new()
		var line_number := 2
		
		for line in lines:
			line = line.lstrip(" \t").rstrip(" \t")
			if line.begins_with("--@description "):
				if current_field.description:
					current_field.description += "\n%s" % line.trim_prefix("--@description ")
				else:
					current_field.description = line.trim_prefix("--@description ")
			
			
			elif line.begins_with("--@type "):
				if current_field.type:
					print("@ConfigParser: Doubled --@type [Line %s]" % line_number)
					return []
				
				regex.compile(r"(?!--@type)(?<type>int|float)( precision=(?<precision>\d+))?( range=(?<range_min>[+-]?\d+)\.\.(?<range_max>[+-]?\d+))?")
				re_match = regex.search(line)
				
				if re_match:
					var range_min = re_match.get_string("range_min")
					var range_max = re_match.get_string("range_max")
					var precision = re_match.get_string("precision")
					var has_precision_or_range = not range_min.is_empty() or not precision.is_empty()
					if has_precision_or_range:
						if re_match.get_string("type") == "int":
							if precision != "":
								print("@ConfigParser: Precision not allowed with int")
								return []
							current_field.type = Type.integer("int", validate_with_range_int, int(range_min), int(range_max))
						else:
							if precision == "":
								current_field.type = Type.float_num("float", validate_with_range_float, float(range_min), float(range_max), 0, ArgEnum.FLOAT_RANGE)
							elif range_min == "":
								current_field.type = Type.float_num("float", validate_with_precision_float, 0, 0, int(precision), ArgEnum.FLOAT_PRECISION)
							else:
								current_field.type = Type.float_num("float", validate_with_range_precision_float, float(range_min), float(range_max), int(precision), ArgEnum.FLOAT_PRECISION_RANGE)
						
						# Increment line_number, because we continue
						line_number += 1
						continue
				
				regex.compile(r"(?!--@type) list\[(?<type>.+)\]")
				re_match = regex.search(line)
				
				if re_match:
					var re_type = re_match.get_string("type")
					regex.compile("^(int|float|string|ModifierKey)$")
					if regex.search(re_type) != null:
						current_field.type = Type.list("list:%s" % re_type, validate_list, re_type)
						# Increment line_number, because we continue
						line_number += 1
						continue
					else:
						print("@ConfigParser: Unsupported type for list: %s [Line %s]" % [re_type, line_number])
						return []
				
				var type = line.trim_prefix("--@type ")
				match type:
					"Key":
						current_field.type = Type.with("Key", func(string: String): return string.trim_prefix("Key.") in VALID_KEYS)
					"int":
						current_field.type = Type.with("int", func(string: String): return string.is_valid_int())
					"float":
						current_field.type = Type.with("float", func(string: String): return string.is_valid_float())
					"string":
						current_field.type = Type.with("string", validate_string)
					_:
						print("@ConfigParser: Unsupported type: %s [Line %s]" % [type, line_number])
						return []
				
				if current_field.default:
					if !current_field.type.validate(current_field.default):
						print("@ConfigParser: Invalid default value: %s [Line %s]" % [current_field.default, line_number])
						return []
			
			
			elif line.begins_with("--@default "):
				if current_field.default:
					print("@ConfigParser: Doubled --@default [Line %s]" % line_number)
					return []
					
				var default = line.trim_prefix("--@default ")
				current_field.default = default
				if current_field.type:
					if !current_field.type.validate(current_field.default):
						print("@ConfigParser: Invalid default value: %s [Line %s]" % [current_field.default, line_number])
						return []
			
			else:
				regex.compile(r"^\s*(?<name>[a-zA-Z_]\w*)\s*=\s*(?<value>.*?),?\s*$")
				re_match = regex.search(line)
				if re_match:
					if !current_field.description:
						print("@ConfigParser: Missing @description declaration")
						return []
					if !current_field.type:
						print("@ConfigParser: Missing @type declaration")
						return []
					if !current_field.default:
						print("@ConfigParser: Missing @default declaration")
						return []
					
					var value = re_match.get_string("value")
					if !current_field.type.validate(value):
						print("@ConfigParser: Invalid value: %s [Line %s]" % [value, line_number])
						return []
					current_field.name = re_match.get_string("name")
					fields.append(current_field)
					current_field = ConfigField.new()
			
			line_number += 1
		
		return fields
	else:
		var err = FileAccess.get_open_error()
		print("Open config status: %s [%s]" % [error_string(err), err])
	return []


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
