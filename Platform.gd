# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends Object
class_name Platform

static func is_web() -> bool:
	if "--pretend-web" in OS.get_cmdline_args():
		return true
	return OS.get_name() == "Web"
