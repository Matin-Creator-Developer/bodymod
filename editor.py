import os

path = "lib/main.dart"
with open(path, "r", encoding="utf-8") as f:
    code = f.read()

# 1. برگرداندن پرانتز گم‌شده در bmShowResponsiveSheet (بنر کانال)
broken_sheet = """                label: const Text('کپی کردن آیدی @bodymod_channel'),
              ),
            ),
          ],
        ),
    );"""

fixed_sheet = """                label: const Text('کپی کردن آیدی @bodymod_channel'),
              ),
            ),
          ],
        ),
      ),
    );"""

if broken_sheet in code:
    code = code.replace(broken_sheet, fixed_sheet, 1)
    print("✅ پرانتز گم‌شده‌ی bmShowResponsiveSheet برگردونده شد!")
else:
    print("ℹ️ بخش bmShowResponsiveSheet از قبل سالم بود یا متفاوت بود.")

# 2. حذف پرانتز اضافه‌ی AlertDialog (فقط وقتی Theme از روش برداشته شده باشه)
broken_dialog = """              child: const Text('ورود به حساب 🚀', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );"""

fixed_dialog = """              child: const Text('ورود به حساب 🚀', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
    );"""

if "builder: (ctx) => AlertDialog(" in code and broken_dialog in code:
    code = code.replace(broken_dialog, fixed_dialog, 1)
    print("✅ پرانتز اضافه‌ی AlertDialog پاک شد!")
else:
    print("ℹ️ بخش AlertDialog از قبل سالم بود.")

with open(path, "w", encoding="utf-8") as f:
    f.write(code)

# 3. تست سلامت و تراز بودن کل پرانتزها و آکولادها در کل فایل
def check_balance(src):
    stack = []
    pairs = {')': '(', ']': '[', '}': '{'}
    in_s, in_d, in_lc, in_bc, esc = False, False, False, False, False
    line = 1
    i, n = 0, len(src)
    while i < n:
        ch = src[i]
        nxt = src[i + 1] if i + 1 < n else ''
        if ch == '\n':
            line += 1
            in_lc = False
            i += 1
            continue
        if in_lc:
            i += 1
            continue
        if in_bc:
            if ch == '*' and nxt == '/':
                in_bc = False
                i += 2
            else:
                i += 1
            continue
        if in_s:
            if esc:
                esc = False
            elif ch == '\\':
                esc = True
            elif ch == "'":
                in_s = False
            i += 1
            continue
        if in_d:
            if esc:
                esc = False
            elif ch == '\\':
                esc = True
            elif ch == '"':
                in_d = False
            i += 1
            continue
        if ch == '/' and nxt == '/':
            in_lc = True
            i += 2
            continue
        if ch == '/' and nxt == '*':
            in_bc = True
            i += 2
            continue
        if ch == "'":
            in_s = True
            i += 1
            continue
        if ch == '"':
            in_d = True
            i += 1
            continue
        if ch in '([{':
            stack.append((ch, line))
        elif ch in ')]}':
            if not stack or stack[-1][0] != pairs[ch]:
                return f"❌ عدم تطابق '{ch}' در خط {line} (باز مانده: {stack[-1] if stack else 'هیچ'})"
            stack.pop()
        i += 1
    if stack:
        return f"❌ پرانتز/آکولاد باز مانده: {stack[-1]}"
    return "✅ عالی! تمام پرانتزها () و آکولادها {} در کل فایل ۱۰۰٪ تراز و سالم هستن! 🚀"

print(check_balance(code))
