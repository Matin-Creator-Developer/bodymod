path = "lib/main.dart"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

target = "bool bmIsGeneratingWorkout = false;"
insert_code = (
    "List<String> bmGlobalTargetMuscles = ['کل بدن'];\n"
    "const List<String> bmTargetMuscleOptions = ['کل بدن', 'سینه', 'شکم', 'بازو', 'پشت و سرشانه', 'ران و باسن'];\n"
    "const List<String> bmWorkoutWeekDays = ['شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'];\n"
    "Map<String, Map<String, dynamic>> bmAiWeeklyWorkouts = {};\n"
    "int bmSelectedWorkoutDayIdx = 0;\n"
    "bool bmIsGeneratingWorkout = false;"
)

if "bmGlobalTargetMuscles" in content and "bmWorkoutWeekDays" in content and "List<String> bmGlobalTargetMuscles" in content:
    print("ℹ️ متغیرها از قبل اضافه شده بودن!")
elif target in content:
    content = content.replace(target, insert_code, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ پچ اول با موفقیت ۱۰۰٪ اعمال شد! الان کد کاملاً آماده بیلده 🚀🔥")
else:
    print("❌ خط هدف پیدا نشد!")
