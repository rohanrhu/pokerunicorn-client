extends Node
class_name Arg

static func get_arg(arg: String, default):
	var is_exists = false
	
	for _arg in OS.get_cmdline_args():
		if _arg == arg:
			is_exists = true
			continue
		
		if is_exists:
			return _arg
	
	return default
