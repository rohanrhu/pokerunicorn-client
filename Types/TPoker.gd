# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends Object
class_name TPoker

const CARD_KINDS: Array[String] = ["H", "C", "D", "S"];
const CARDS: Array[int] = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];
const CARD_SYMBOLS: Array[String] = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"];

enum STATE {
	CREATED = 0,
	W4P,
	STARTING,
	SMALL_BLIND,
	BIG_BLIND,
	PREFLOP,
	FLOP,
	TURN,
	RIVER,
	DONE
};

enum CARD_KIND {
	HEART = 0,
	CLUB,
	DIAMOND,
	SPADE
};

enum HAND_KIND {
	PREFLOP = 0,
	FLOP,
	TURN,
	RIVER
};

enum ACTION_KIND {
	SMALL_BLIND = 0,
	BIG_BLIND,
	RAISE,
	CHECK,
	FOLD
};

class TCard:
	var index: int
	var kind: CARD_KIND
