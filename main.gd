extends Control

@export var encode: Button
@export var decode: Button
@export var plaintext: TextEdit
@export var ciphertext: TextEdit
@export var key: LineEdit

func _ready() -> void:
	encode.pressed.connect(_on_encode_pressed)
	decode.pressed.connect(_on_decode_pressed)
	key.text_submitted.connect(_on_key_text_submitted)

func _on_key_text_submitted(text: String) -> void:
	if not RoarCodec.is_valid_codec(key.text):
		key.text = "嗷呜啊~"

func _on_encode_pressed() -> void:
	var encoded := RoarCodec.encode(plaintext.text, key.text)
	if encoded.is_empty():
		ciphertext.text = "加密错误，密钥无效"
	else:
		ciphertext.text = encoded

func _on_decode_pressed() -> void:
	var decoded := RoarCodec.decode(ciphertext.text)
	if decoded.is_empty():
		plaintext.text = "解密错误，密文无效"
	else:
		plaintext.text = decoded
