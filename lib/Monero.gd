extends Object
class_name Monero

static func pico2xmr(p_amount: int) -> float:
	return p_amount / 1000000000000.0

static func pico2label(p_amount: int) -> String:
	return str(pico2xmr(p_amount)) + " XMR"
