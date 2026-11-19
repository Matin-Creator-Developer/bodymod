import re

path = "lib/main.dart"
with open(path, "r", encoding="utf-8") as f:
    code = f.read()

runtime_tokens = [
    "bmIsDarkTheme",
    "bmBgColor",
    "bmCardColor",
    "bmSurfaceColor",
    "bmTextColor",
    "bmTextSubColor",
    "bmTextMutedColor",
    "bmBorderColor",
    "bmAccentColor",
    "bmExStr",
    "BMColors.bgDark",
    "BMColors.surfaceDark",
    "BMColors.cardDark",
    "BMColors.cardBorderDark",
    "BMColors.neonCyan",
    "BMColors.neonGreen",
    "BMColors.warningAmber",
    "BMColors.whaleGold",
]

def find_matching_close(src, open_idx, open_ch, close_ch):
    depth = 0
    i = open_idx
    n = len(src)
    in_s = in_d = esc = False
    while i < n:
        ch = src[i]
        if in_s:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == "'":
                in_s = False
        elif in_d:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                in_d = False
        else:
            if ch == "'":
                in_s = True
            elif ch == '"':
                in_d = True
            elif ch == open_ch:
                depth += 1
            elif ch == close_ch:
                depth -= 1
                if depth == 0:
                    return i
        i += 1
    return -1

# پیدا کردن همه const Widget(...) و const [...] که داخلشون متغیرهای غیرثابت تم رفته
pattern = re.compile(r"\bconst\s+(?:[A-Za-z_]\w*(?:<[^>]+>)?(?:\.[A-Za-z_]\w*)?\s*\(|\[)")
to_remove = []

for m in pattern.finditer(code):
    end_ch = code[m.end() - 1]
    close_ch = ")" if end_ch == "(" else "]"
    close_idx = find_matching_close(code, m.end() - 1, end_ch, close_ch)
    if close_idx != -1:
        block = code[m.start():close_idx + 1]
        if any(tok in block for tok in runtime_tokens):
            # فقط کلمه "const " را حذف می‌کنیم
            const_end = m.start() + len("const")
            while const_end < len(code) and code[const_end] == " ":
                const_end += 1
            line_no = code.count("\n", 0, m.start()) + 1
            to_remove.append((m.start(), const_end, line_no))

# حذف از آخر به اول تا ایندکس‌ها به هم نریزن
for start, end, line_no in reversed(to_remove):
    code = code[:start] + code[end:]
    print(f"✅ حذف const نامعتبر در خط {line_no}")

with open(path, "w", encoding="utf-8") as f:
    f.write(code)

print(f"🚀 تمام شد! تعداد {len(to_remove)} مورد const نامعتبر پاکسازی شد.")
