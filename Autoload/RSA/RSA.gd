# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

class_name RSA
extends Object

static var BITS = 16
static var EXPONENT = 65537
static var BLOCK_SIZE = 4
static var BLOCK_SIZE_LENGTH = 1

class RSAKey extends RefCounted:
	var exponent = null
	var modulus = null
	
	func _init(p_exponent: BigCat.BigNumber, p_modulus: BigCat.BigNumber) -> void:
		self.exponent = p_exponent
		self.modulus = p_modulus

class RSAKeyPair extends RefCounted:
	var public_key: RSAKey = null
	var private_key: RSAKey = null 
	
	func _init(p_public_key: RSAKey, p_private_key: RSAKey) -> void:
		self.public_key = p_public_key
		self.private_key = p_private_key

	static func from_test() -> RSAKeyPair:
		var pubkey = RSAKey.new(BigCat.BigNumber.from_uint(7), BigCat.BigNumber.from_uint(33))
		var privkey = RSAKey.new(BigCat.BigNumber.from_uint(3), BigCat.BigNumber.from_uint(33))

		return RSAKeyPair.new(pubkey, privkey)

	static func from_test_bigger() -> RSAKeyPair:
		var pubkey = RSAKey.new(BigCat.BigNumber.from_uint(17), BigCat.BigNumber.from_uint(3233))
		var privkey = RSAKey.new(BigCat.BigNumber.from_uint(2753), BigCat.BigNumber.from_uint(3233))

		return RSAKeyPair.new(pubkey, privkey)

	static func from_random() -> RSAKeyPair:
		var p = BigCat.BigNumber.generate_prime(RSA.BITS) # BigCat.BigNumber.from_uint(2147483647)
		var q = BigCat.BigNumber.generate_prime(RSA.BITS) # BigCat.BigNumber.from_uint(4294967291)
		print("p: ", p.to_string())
		print("q: ", q.to_string())
		var n = p.multiply(q)
		var phi = p.subtract(BigCat.BigNumber.from_uint(1)).multiply(q.subtract(BigCat.BigNumber.from_uint(1)))
		var e = BigCat.BigNumber.from_uint(RSA.EXPONENT)
		print("e: ", e.to_string())
		print("phi: ", phi.to_string())
		var d = e.inverse_modulo(phi)
		print("d: ", d.to_string())

		var pubkey = RSAKey.new(e, n)
		var privkey = RSAKey.new(d, n)

		return RSAKeyPair.new(pubkey, privkey)

static func generate_keypair() -> RSAKeyPair:
	return RSAKeyPair.from_random()

static func encrypt_scalar(p_scalar: BigCat.BigNumber, p_key: RSAKey) -> BigCat.BigNumber:
	print("Encrypting scalar (", p_scalar.to_string(), ") with key (", p_key.exponent.to_string(), ", ", p_key.modulus.to_string(), "), bytes: ", p_scalar.to_bytes())
	return p_scalar.power_modulo(p_key.exponent, p_key.modulus)

static func decrypt_scalar(p_scalar: BigCat.BigNumber, p_key: RSAKey) -> BigCat.BigNumber:
	print("Decrypting scalar (", p_scalar.to_string(), ") with key (", p_key.exponent.to_string(), ", ", p_key.modulus.to_string(), "), bytes: ", p_scalar.to_bytes())
	return p_scalar.power_modulo(p_key.exponent, p_key.modulus)

static func encrypt(p_data: PackedByteArray, p_key: RSAKey) -> PackedByteArray:
	var encrypted_data = []
	
	var pages = p_data.size() / BLOCK_SIZE
	if p_data.size() % BLOCK_SIZE != 0:
		pages += 1
	
	var page_size
	var page_offset = 0

	for i in range(pages):
		if i == pages-1:
			page_size = p_data.size() % BLOCK_SIZE
		else:
			page_size = BLOCK_SIZE
		
		print("Slice: (", page_offset, ", ", page_offset + page_size, ")" )
		print("Encrypting page size: ", page_size)
		var block = p_data.slice(page_offset, page_offset + page_size)
		print("Encrypting block (", page_offset, ", ", page_offset + page_size, "): ", block)
		var scalar = BigCat.BigNumber.from_bytes(block)
		var encrypted = RSA.encrypt_scalar(scalar, p_key)
		var encrypted_page_size = encrypted.to_bytes().size()

		var big_page_size = BigCat.BigNumber.from_uint(encrypted_page_size)
		var page_size_length = big_page_size.to_bytes().size()
		var pads = BLOCK_SIZE_LENGTH - page_size_length

		encrypted_data.append_array(big_page_size.to_bytes())
		for j in range(pads):
			encrypted_data.append(0)

		print("Encrypted block: ", encrypted.to_bytes())
		print("Encrypted scalar: ", encrypted._to_string())
		encrypted_data.append_array(encrypted.to_bytes())

		page_offset += page_size
	
	print("Encrypted data: ", encrypted_data)
	return encrypted_data

static func decrypt(p_data: PackedByteArray, p_key: RSAKey) -> Array:
	var decrypted_data = []
	
	var page_size
	var page_offset = 0
	while page_offset < p_data.size():
		page_size = BigCat.BigNumber.from_bytes(p_data.slice(page_offset, page_offset + BLOCK_SIZE_LENGTH)).to_uint()
		page_offset += BLOCK_SIZE_LENGTH
		print("Decrypting page size: ", page_size)
		
		var block = p_data.slice(page_offset, page_offset + page_size)
		print("Decrypting block (", page_offset, ", ", page_offset + page_size, "): ", block)
		var scalar = BigCat.BigNumber.from_bytes(block)
		var decrypted = RSA.decrypt_scalar(scalar, p_key)
		print("Decrypted scalar: ", decrypted._to_string())

		decrypted_data.append_array(decrypted.to_bytes())
		
		page_offset += page_size
		

	return decrypted_data
