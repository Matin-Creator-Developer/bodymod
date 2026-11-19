path = "lib/main.dart"
with open(path, "r", encoding="utf-8") as f:
    code = f.read()

# ۱. فیکس خط شکسته‌ی بنر ۳ روز اشتراک رایگان
broken1 = "'۳ روز اشتراک رایگان بهت تعلق گرفت 😍 (باقی‌مانده: $daysLeft روز)\nمیتونی از همه امکانات هوش مصنوعی هم استفاده کنی، ولی بعد از تموم شدن باید اشتراک بخری 😂',"
fixed1 = r"'۳ روز اشتراک رایگان بهت تعلق گرفت 😍 (باقی‌مانده: $daysLeft روز)\nمیتونی از همه امکانات هوش مصنوعی هم استفاده کنی، ولی بعد از تموم شدن باید اشتراک بخری 😂',"

if broken1 in code:
    code = code.replace(broken1, fixed1)
    print("✅ بنر ۳ روز اشتراک رایگان فیکس شد!")
else:
    print("ℹ️ بنر ۳ روز رایگان از قبل سالم بود.")

# ۲. فیکس خط شکسته‌ی پنجره‌ی دعوت از دوست
broken2 = "'کد یا لینک دعوت خودت رو بفرست برای رفیقت:\n'"
fixed2 = r"'کد یا لینک دعوت خودت رو بفرست برای رفیقت:\n'"

broken3 = "'• دوستت با زدن کد تو ۳۰٪ تخفیف اشتراک می‌گیره (۳۴۹,۳۰۰ تومان به جای ۴۹۹,۰۰۰ تومان) 🎉\n'"
fixed3 = r"'• دوستت با زدن کد تو ۳۰٪ تخفیف اشتراک می‌گیره (۳۴۹,۳۰۰ تومان به جای ۴۹۹,۰۰۰ تومان) 🎉\n'"

if broken2 in code:
    code = code.replace(broken2, fixed2)
    print("✅ خط اول پنجره‌ی دعوت از دوست فیکس شد!")
if broken3 in code:
    code = code.replace(broken3, fixed3)
    print("✅ خط دوم پنجره‌ی دعوت از دوست فیکس شد!")

with open(path, "w", encoding="utf-8") as f:
    f.write(code)

# ۳. چک کردن اینکه هیچ خطی کوتیشن باز نداشته باشه
bad_lines = []
for idx, line in enumerate(code.splitlines(), 1):
    s = line.strip()
    if s.startswith("//") or s.startswith("*") or "'''" in s or '"""' in s:
        continue
    # حذف کاراکترهای escape شده
    clean = s.replace(r"\'", "").replace(r'\"', "")
    # حذف کامنت آخر خط (ساده)
    if "//" in clean and not "http://" in clean and not "https://" in clean and not "bodymod://" in clean:
        clean = clean.split("//")[0]
    if clean.count("'") % 2 != 0:
        bad_lines.append((idx, s[:60]))

if bad_lines:
    print("⚠️ این خطوط ممکنه کوتیشن باز داشته باشن:")
    for ln, txt in bad_lines[:10]:
        print(f"   خط {ln}: {txt}")
else:
    print("🚀 عالی! هیچ رشته‌ی شکسته‌ای توی کل lib/main.dart وجود نداره!")
