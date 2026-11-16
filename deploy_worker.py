```python
#!/usr/bin/env python3
"""
اسکریپت جایگزینی خودکار worker.js و پوش کردن به کلودفلر در ترموکس (Termux)
نحوه اجرا در پوشه ~/bodymod:
    python deploy_worker.py
"""

import os
import subprocess
import sys

OLD_Paths = ["worker.js", "server/worker.js"]


def main():
    print("[*] بررسی و پاک کردن فایل worker.js قبلی...")
    target_path = "worker.js"

    for p in OLD_Paths:
        if os.path.exists(p):
            target_path = p
            # گرفتن بکاپ موقت برای حفظ امنیت کلیدهای احتمالی داخل فایل قبلی
            backup_path = f"{p}.bak"
            with open(p, "r", encoding="utf-8") as src, open(backup_path, "w", encoding="utf-8") as dst:
                dst.write(src.read())
            os.remove(p)
            print(f"[✓] فایل قبلی '{p}' پاک شد (نسخه پشتیبان در '{backup_path}' ذخیره شد).")

    if not os.path.exists("new_worker.js") and not os.path.exists(target_path):
        print(f"[!] لطفاً کد worker.js جدید رو در '{target_path}' قرار بده و دوباره اجرا کن.")
        sys.exit(1)

    if os.path.exists("new_worker.js"):
        with open("new_worker.js", "r", encoding="utf-8") as src, open(target_path, "w", encoding="utf-8") as dst:
            dst.write(src.read())
        os.remove("new_worker.js")
        print(f"[✓] فایل جدید در '{target_path}' جایگزین شد.")

    print("[*] در حال پوش کردن به کلودفلر با cf.py...")
    if os.path.exists("cf.py"):
        res = subprocess.run([sys.executable, "cf.py", "push"])
        if res.returncode == 0:
            print("[✓] پوش به سرور کلودفلر با موفقیت انجام شد! 🚀🔥")
        else:
            print("[!] اجرای مستقیم تابع push از داخل cf.py...")
            subprocess.run([sys.executable, "-c", "import cf; cf.push()"])
    else:
        print("[!] فایل cf.py در این پوشه پیدا نشد! مطمئن شو داخل پوشه ~/bodymod هستی.")


if __name__ == "__main__":
    main()
```
