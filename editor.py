import re

files = [
    "lib/store_billing.dart",
    ".github/workflows/build-cafebazaar.yml",
    ".github/workflows/build-myket.yml",
]

for path in files:
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    new_text = re.sub(r"static\s+Future[^\n]*purchase\(", "static Future purchase(", text)
    new_text = re.sub(r"Completer[^\n]*\(\)", "Completer()", new_text)
    new_text = new_text.replace("if (!connected) return null;", "if (connected != true) return null;")

    if new_text != text:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_text)
        print(f"✅ [{path}] فیکس شد!")
    else:
        print(f"ℹ️ [{path}] از قبل سالم بود.")

    for line in new_text.splitlines():
        if "static Future" in line or "Completer(" in line:
            print(f"   ↳ {line.strip()}")

print("🚀 همه‌ی فایل‌ها تمیز شدن! آماده پوش!")
