@warning_ignore_start("integer_division")
class_name RoarCodec

static var _fallback := [
	["~呜嗷", "啊"],
	["~嗷汪", "呜"]
]

static func encode(plain_text: String, codec: String) -> String:
	# 验证密钥有效性
	if not is_valid_codec(codec):
		printerr("密钥无效")
		return ""

	var hex: PackedStringArray = []

	for c in plain_text:
		var buffer = c.to_utf16_buffer()  # [低位, 高位]
		buffer.reverse()
		# 反过来写入，高字节在前（大端）
		for byte in buffer:
			var hex_char = "%02X" % byte
			for ch in hex_char:
				hex.append(ch)
	
	var result: PackedStringArray = []
	for i in range(0, hex.size(), 1):
		# 转化为10进制整数
		var value := hex[i].hex_to_int()
		# 加偏移，模16
		value = (value + i % 16) % 16
		# 获取映射
		result.append(codec[value >> 2]) # / 4
		result.append(codec[value & 0b0011]) # % 4

	return codec[3] + codec[1] + codec[0] + "".join(result) + codec[2]

static func decode(encoded_text: String) -> String:
	var segment := _extract_encoded_segment(encoded_text)      
	if not _is_valid_cipher(segment):
		printerr("密文无效")
		return ""

	var key = segment[2] + segment[1] + segment[-1] + segment[0]

	# 提取密文
	var raw := segment.substr(3, segment.length() - 4)

	if raw.length() % 2 != 0:
		printerr("密文无效")
		return ""

	# 恢复hex字符串
	var hex : PackedStringArray = []
	for i in range(0, raw.length() - 1, 2):
		var a := key.find(raw[i])
		var b := key.find(raw[i + 1])
		if a == -1 or b == -1:
			printerr("解码失败")
			return ""

		# (4 * a + b - (i / 2 % 16) + 16) % 16)		
		var index := ((a << 2 | b) - (i / 2 % 16) + 16) % 16
		hex.append("%X" % index)    

	# 恢复明文
	var text : PackedStringArray = []
	for i in range(0, hex.size(), 4):
		if i + 4 > hex.size():
			break
		var part := "".join(hex.slice(i, i + 4))
		text.append(char(part.hex_to_int()))

	return "".join(text)

static func _is_valid_cipher(cipher: String) -> bool:
	if cipher.length() < 4:
		return false

	if _distinct(cipher).size() != 4:
		return false

	return true

# 验证密钥有效性
static func is_valid_codec(codec: String) -> bool:
	# 长度必须为4
	if codec.length() != 4:
		return false

	# 不允许重复
	if _distinct(codec).size() != 4:
		return false

	return true

static func _distinct(input: String) -> PackedStringArray:    
	var result : PackedStringArray = []
	for c in input:        
		if not result.has(c):
			result.append(c)    
	return result

# 兜底措施，使用fallback的密钥来提取密文
static func _extract_encoded_segment(input: String) -> String:
	for key in _fallback:
		if key.size() < 2:
			continue
		var start := input.find(key[0])
		var end := input.rfind(key[1])
		if start != -1 and end > start:
			return input.substr(start, end - start + 1)
	return input
