using Godot;
using System;
using System.Linq;
using System.Text;

public class RoarCodec
{
    private static readonly string[][] _fallback = [
        ["~呜嗷", "啊"],
        ["~嗷汪", "呜"]
    ];
    public static string Encode(string plainText, string codec)
    {
        if (codec.Length != 4 || codec.Distinct().Count() != 4)
            throw new ArgumentException("编码字符必须是4个不同字符");

        // 文本转十六进制
        StringBuilder hex = new StringBuilder();
        foreach (char c in plainText)
            hex.Append(((int)c).ToString("X4"));


        StringBuilder result = new StringBuilder();
        for (int i = 0; i < hex.Length; i++)
        {
            int value = Convert.ToInt32(hex[i].ToString(), 16);
            value = (value + i % 16) % 16;
            result.Append(codec[value / 4]);
            result.Append(codec[value % 4]);
        }

        // 最终密文结构
        return $"{codec[3]}{codec[1]}{codec[0]}{result}{codec[2]}";
    }

    public static string Decode(string encodedText)
    {
        string segment = ExtractEncodedSegment(encodedText);
        if (segment.Length < 4 || segment.Distinct().Count() != 4)
            throw new Exception("密文格式不正确");

        string key = $"{segment[2]}{segment[1]}{segment[^1]}{segment[0]}";

        // 提取编码部分
        string raw = segment.Substring(3, segment.Length - 4);
        
        if (raw.Length % 2 != 0)
            throw new Exception("密文长度无效");

        // 恢复 hex 字符串
        StringBuilder hex = new StringBuilder();
        for (int i = 0; i < raw.Length - 1; i += 2)
        {
            int a = key.IndexOf(raw[i]);
            int b = key.IndexOf(raw[i + 1]);
            if (a == -1 || b == -1)
                throw new Exception("解码失败");

            int index = (4 * a + b - (i / 2 % 16) + 16) % 16;
            hex.Append(index.ToString("X"));
        }

        // 转回字符
        StringBuilder text = new StringBuilder();
        for (int i = 0; i < hex.Length; i += 4)
        {
            string part = hex.ToString(i, 4);            
            text.Append((char)Convert.ToInt32(part, 16));
        }

        return text.ToString();
    }

    private static string ExtractEncodedSegment(string input)
    {
        foreach (var key in _fallback)
        {
            if (key.Length < 2)
                continue;

            var start = input.IndexOf(key[0]);
            var end = input.IndexOf(key[1]);
            if (start != -1 && end > start)
                return input.Substring(start, end - start + 1);
        }        
        return input;
    }
}
