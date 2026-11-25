import os
import re

NEW_BUSY_MSG = (
    "رفیق الان ترافیک سرورهای هوش مصنوعی خیلی بالاست! 😅 "
    "مشکل از برنامه ما نیست و سهمیه‌ات هم اصلاً کم نشده؛ "
    "چند دقیقه دیگه دوباره امتحان کن تا جوابت رو بدم! ❤️🙏"
)

# ==============================================================================
# 1. اصلاح worker.js (حذف کامل سری 2 + زنجیره 3.5 -> 3.1 + پیام "چند دقیقه")
# ==============================================================================
with open("worker.js", "r", encoding="utf-8") as f:
    worker = f.read()

# حذف کامل سری 2 و قفل کردن زنجیره روی 3.5 و 3.1
worker = re.sub(
    r'const\s+candidateModels\s*=\s*\[[^\]]+\];',
    'const candidateModels = ["gemini-3.5-flash-lite", "gemini-3.1-flash-lite"];',
    worker
)
worker = worker.replace('"gemini-2.5-flash-lite"', '"gemini-3.1-flash-lite"')
worker = worker.replace('"gemini-2.5-flash"', '"gemini-3.1-flash-lite"')

# آپدیت پیام‌های شلوغی و خطا به "چند دقیقه"
worker = re.sub(
    r'رفیق الان ترافیک سرورهای هوش مصنوعی خیلی بالاست!.*?❤️🙏',
    NEW_BUSY_MSG,
    worker
)
worker = worker.replace("یه دقیقه دیگه دوباره بزن رو دکمه", "چند دقیقه دیگه دوباره امتحان کن")
worker = worker.replace("یه دقیقه دیگه دوباره امتحان کن", "چند دقیقه دیگه دوباره امتحان کن")
worker = worker.replace("چند ثانیه دیگه دوباره امتحان کن", "چند دقیقه دیگه دوباره امتحان کن")
worker = worker.replace("شلوغی یا خطای سرورهای گوگل (3.5 -> 3.1 -> 2.5)", "شلوغی یا خطای سرورهای گوگل (3.5 -> 3.1)")

with open("worker.js", "w", encoding="utf-8") as f:
    f.write(worker)
print("✅ [worker.js] سری ۲ حذف شد، زنجیره روی 3.5 -> 3.1 قفل شد و پیام «چند دقیقه» ست شد!")

# ==============================================================================
# 2. اصلاح lib/main.dart (پیام «چند دقیقه» برای همه ارورهای AI + تایم‌اوت ۴۵ ثانیه)
# ==============================================================================
with open("lib/main.dart", "r", encoding="utf-8") as f:
    dart = f.read()

dart = dart.replace("gemini-2.5-flash-lite", "gemini-3.1-flash-lite")
dart = dart.replace("gemini-2.5-flash", "gemini-3.1-flash-lite")

dart = re.sub(
    r'رفیق الان ترافیک سرورهای هوش مصنوعی خیلی بالاست!.*?❤️🙏',
    NEW_BUSY_MSG,
    dart
)
dart = dart.replace(
    "خطا در ساخت برنامه ورزشی از هوش مصنوعی! چند ثانیه دیگه دوباره امتحان کن رفیق.",
    NEW_BUSY_MSG
)
dart = dart.replace(
    "الان سرورهای هوش مصنوعی گوگل خیلی شلوغه رفیق! 😅 سهمیه‌ت اصلاً کم نشده، چند ثانیه دیگه دوباره بزن 🙏",
    NEW_BUSY_MSG
)
dart = dart.replace("چند ثانیه دیگه دوباره امتحان کن", "چند دقیقه دیگه دوباره امتحان کن")
dart = dart.replace("یه دقیقه دیگه دوباره امتحان کن", "چند دقیقه دیگه دوباره امتحان کن")
dart = dart.replace(".timeout(const Duration(seconds: 20))", ".timeout(const Duration(seconds: 45))")

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(dart)
print("✅ [lib/main.dart] پیام‌های ارور هوش مصنوعی روی «چند دقیقه» و تایم‌اوت روی ۴۵ ثانیه تنظیم شد!")

# ==============================================================================
# 3. اصلاح ورک‌فلوهای گیت‌هاب برای رفع ارور Publish Release
# ==============================================================================
workflow_configs = [
    (".github/workflows/build-myket.yml", "v2.43.76-myket"),
    (".github/workflows/build-cafebazaar.yml", "v2.43.76-cafebazaar"),
]

for wf_path, tag_val in workflow_configs:
    if not os.path.exists(wf_path):
        continue
    with open(wf_path, "r", encoding="utf-8") as f:
        wf = f.read()

    if "permissions:" not in wf:
        wf = wf.replace("on:", "permissions:\n  contents: write\n\non:", 1)

    if "softprops/action-gh-release@v2" in wf and "tag_name:" not in wf:
        wf = wf.replace(
            "uses: softprops/action-gh-release@v2\n        with:",
            f"uses: softprops/action-gh-release@v2\n        with:\n          tag_name: {tag_val}",
            1
        )
        print(f"✅ [{wf_path}] تگ انتشار ({tag_val}) برای رفع ارور Publish Release اضافه شد!")
    else:
        print(f"ℹ️ [{wf_path}] تنظیمات انتشار از قبل بررسی شد.")

    with open(wf_path, "w", encoding="utf-8") as f:
        f.write(wf)

print("\n🎉 تمام اصلاحات با موفقیت ۱۰۰٪ انجام شد!")
