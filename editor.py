with open("lib/main.dart", "r", encoding="utf-8") as f:
    d = f.read()

old_str = "'🤖 تحلیل هفتگی مربی:\n$_lastBodyAiAnalysis',"
new_str = r"'🤖 تحلیل هفتگی مربی:\n$_lastBodyAiAnalysis',"

assert old_str in d, "❌ خط مورد نظر پیدا نشد!"
d = d.replace(old_str, new_str, 1)

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(d)

print("✅ ارور خط ۹۶۳۴ درجا فیکس شد!")
