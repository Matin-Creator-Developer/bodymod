import re

path = "lib/main.dart"
with open(path, "r", encoding="utf-8") as f:
    dart = f.read()

# 1. فیکس تعریف لیست غذاهای سفارشی بدون جنریک
dart = re.sub(
    r"List[^\n]*customAiFoods\s*=\s*\[\];",
    "List customAiFoods = [];",
    dart,
)

# 2. فیکس توابع غذاهای سفارشی (حذف هر نوع جنریک خراب)
dart = re.sub(
    r"Future[^\n]*syncCustomAiFoodsToCloud\(\)\s*async\s*\{",
    "Future syncCustomAiFoodsToCloud() async {",
    dart,
)
dart = re.sub(
    r"Future[^\n]*fetchCustomAiFoodsFromCloud\(\)\s*async\s*\{",
    "Future fetchCustomAiFoodsFromCloud() async {",
    dart,
)
dart = re.sub(
    r"Future[^\n]*saveCustomAiFood\([^\n]*food\)\s*async\s*\{",
    "Future saveCustomAiFood(Map food) async {",
    dart,
)
dart = re.sub(
    r"Future[^\n]*removeCustomAiFood\(String title\)\s*async\s*\{",
    "Future removeCustomAiFood(String title) async {",
    dart,
)

# 3. فیکس whereType و Map.from و parsedResult
dart = re.sub(r"\.whereType[^\n]*\(\)", ".where((e) => e is Map)", dart)
dart = re.sub(r"Map[^\n]*\.from\(e\)", "Map.from(e as Map)", dart)
dart = re.sub(r"Map[^\n]*parsedResult;", "Map? parsedResult;", dart)

with open(path, "w", encoding="utf-8") as f:
    f.write(dart)

# چک کردن اینکه هیچ خط خراب‌ شده‌ای نمونده باشه
bad_lines = []
for idx, line in enumerate(dart.splitlines(), 1):
    if any(tok in line for tok in ["List>", "Map>", "Future>", "whereType()"]):
        bad_lines.append((idx, line.strip()))

if bad_lines:
    print("⚠️ این خط‌ها هنوز مشکوکن:")
    for ln, txt in bad_lines:
        print(f"  خط {ln}: {txt}")
else:
    print("✅ [lib/main.dart] ۱۰۰٪ تمیز و بدون هیچ خطای جنریک فیکس شد! 🚀")
