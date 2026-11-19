import re

LT = chr(60)
GT = chr(62)

# ============================================================================
# 1. FIX lib/main.dart (isLoggedIn + parsedResult type)
# ============================================================================
main_path = "lib/main.dart"
with open(main_path, "r", encoding="utf-8") as f:
    dart = f.read()

dart = dart.replace(
    "if (!isLoggedIn) return;",
    "if (profile.userKey.trim().isEmpty || profile.userKey == 'anonymous') return;",
)

dart = re.sub(
    r"Map\?\s+parsedResult;",
    f"Map{LT}String, dynamic{GT}? parsedResult;",
    dart,
)

with open(main_path, "w", encoding="utf-8") as f:
    f.write(dart)

print("✅ [lib/main.dart] ارور isLoggedIn و parsedResult کامل فیکس شد!")

# ============================================================================
# 2. FIX build-cafebazaar.yml (Replace deprecated jcenter() in flutter_poolakey)
# ============================================================================
bazaar_yml = ".github/workflows/build-cafebazaar.yml"
with open(bazaar_yml, "r", encoding="utf-8") as f:
    b_code = f.read()

target = 'pg = re.sub(r"compileSdkVersion\\\\s+\\\\d+", "compileSdkVersion 34", pg)'
replacement = (
    'pg = re.sub(r"jcenter\\s*\\(\\s*\\)", "mavenCentral()", pg)\n'
    '                  pg = re.sub(r"compileSdkVersion\\\\s+\\\\d+", "compileSdkVersion 34", pg)'
)

if "jcenter" not in b_code:
    if target in b_code:
        b_code = b_code.replace(target, replacement, 1)
        print("✅ [build-cafebazaar.yml] حذف jcenter() به پچ Poolakey اضافه شد!")
    else:
        # حالت جایگزین اگر بک‌اسلش‌ها تکی باشند
        alt_target = 'pg = re.sub(r"compileSdkVersion\\s+\\d+", "compileSdkVersion 34", pg)'
        if alt_target in b_code:
            b_code = b_code.replace(
                alt_target,
                'pg = re.sub(r"jcenter\\s*\\(\\s*\\)", "mavenCentral()", pg)\n                  ' + alt_target,
                1,
            )
            print("✅ [build-cafebazaar.yml] حذف jcenter() به پچ Poolakey اضافه شد!")
        else:
            print("⚠️ [build-cafebazaar.yml] خط هدف پیدا نشد — بگو چکش کنیم!")
    with open(bazaar_yml, "w", encoding="utf-8") as f:
        f.write(b_code)
else:
    print("ℹ️ [build-cafebazaar.yml] پچ jcenter از قبل وجود دارد.")

print("🚀 همه‌چیز آماده بیلد سبزِ مایکت و کافه‌بازار!")
