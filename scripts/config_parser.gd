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

enum RangeEnum { FLOAT, INT, NONE }

class Type:
	var validation_func: Callable
	var range_min_int: int
	var range_max_int: int
	var range_min_float: float
	var range_max_float: float
	var range_enum: RangeEnum = RangeEnum.NONE
	
	static func integer(validation_function: Callable, range_min: int, range_max: int) -> Type:
		var type = new()
		type.validation_func = validation_function
		type.range_min_int = range_min
		type.range_max_int = range_max
		type.range_enum = RangeEnum.INT
		return type
	
	static func float_num(validation_function: Callable, range_min: float, range_max: float) -> Type:
		var type = new()
		type.validation_func = validation_function
		type.range_min_float = range_min
		type.range_max_float = range_max
		type.range_enum = RangeEnum.FLOAT
		return type
	
	static func with(validation_function: Callable) -> Type:
		var type = new()
		type.validation_func = validation_function
		return type
	
	func validate(string: String) -> bool:
		if range_enum == RangeEnum.INT:
			return validation_func.call(string, range_min_int, range_max_int)
		elif range_enum == RangeEnum.FLOAT:
			return validation_func.call(string, range_min_float, range_max_float)
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

func parse(path: String) -> void:
	# CAUTION: Welcome to RegEx hell! Please consider using https://regexr.com/
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var regex = RegEx.new()
		var text = file.get_as_text(true)
		var lines := text.split('\n')
		
		regex.compile(r"(local )?.+ ?= ?{[ \t]*(?!.)")
		var re_match = regex.search(lines[0])
		
		if !re_match.get_string():
			print("@ConfigParser: Expected first line to start the variable assignment")
			return
		
		lines.remove_at(0)
		
		var current_field := ConfigField.new()
		var line_number := 2
		
		for line in lines:
			line = line.lstrip(" \t").rstrip(" \t")
			if line.begins_with("--@description "):
				if current_field.description:
					print("@ConfigParser: Doubled --@description [Line %s]" % line_number)
					return
				current_field.description = line.trim_prefix("--@description ")
			
			
			elif line.begins_with("--@type "):
				if current_field.type:
					print("@ConfigParser: Doubled --@type [Line %s]" % line_number)
					return
				
				regex.compile(r"(?!--@type)(?<type>int|float) (?<range_min>[+-]?\d+)\.\.(?<range_max>[+-]?\d+)")
				re_match = regex.search(line)
				
				if re_match:
					var range_min = re_match.get_string("range_min")
					var range_max = re_match.get_string("range_max")
					if re_match.get_string("type") == "int":
						current_field.type = Type.integer(validate_with_range_int, int(range_min), int(range_max))
					else:
						current_field.type = Type.float_num(validate_with_range_float, float(range_min), float(range_max))
					
					# Increment line_number, because we continue
					line_number += 1
					continue
				
				regex.compile(r"(?!--@type) list\[(?<type>.+)\]")
				re_match = regex.search(line)
				
				if re_match:
					var type = re_match.get_string("type")
					# TODO: Implement the rest
				
				var type = line.trim_prefix("--@type ")
				match type:
					"Key":
						current_field.type = Type.with(func(string: String): return string in VALID_KEYS)
					"int":
						current_field.type = Type.with(func(string: String): return string.is_valid_int())
					"float":
						current_field.type = Type.with(func(string: String): return string.is_valid_float())
					"string":
						current_field.type = Type.with(validate_string)
					_:
						print("@ConfigParser: Unsupported type: %s [Line %s]" % [type, line_number])
						return
				
				if current_field.default:
					if !current_field.type.validate(current_field.default):
						print("@ConfigParser: Invalid default value: %s [Line %s]" % [current_field.default, line_number])
						return
			
			
			elif line.begins_with("--@default "):
				if current_field.default:
					print("@ConfigParser: Doubled --@default [Line %s]" % line_number)
					return
					
				var default = line.trim_prefix("--@default ")
				current_field.default = default
				if current_field.type:
					if !current_field.type.validate(current_field.default):
						print("@ConfigParser: Invalid default value: %s [Line %s]" % [current_field.default, line_number])
						return
			
			if '}' in line:
				break
			else:
				regex.compile(r"^[ \t]*(?<name>[a-zA-Z_]\w*)[ \t]*=[ \t]*(?<value>.*?),?[ \t]*$")
				re_match = regex.search(line)
				if re_match:
					var value = re_match.get_string("value")
					if !current_field.type.validate(value):
						print("@ConfigParser: Invalid value: %s [Line %s]" % [value, line_number])
						return
					current_field.name = re_match.get_string("name")
					# TODO: Consider not dropping current_field
					current_field = ConfigField.new()
			
			line_number += 1
	else:
		return FileAccess.get_open_error()

func validate_string(string: String) -> bool:
	var regex = RegEx.new()
	regex.compile(r"^'[^']*(?:\\'[^']*)*'$")
	var result1 = regex.search(string) != null
	regex.compile("^\"[^\"]*(?:\\\\\"[^\"]*)*\"$")
	var result2 = regex.search(string) != null
	return result1 or result2

func validate_with_range_int(string: String, range_min: int, range_max: int) -> bool:
	var integer = int(string)
	return integer >= range_min and integer <= range_max

func validate_with_range_float(string: String, range_min: float, range_max: float) -> bool:
	var float_num = float(string)
	return float_num >= range_min and float_num <= range_max
