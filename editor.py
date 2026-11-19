import glob
import os
import re
import shutil

# ============================================================================
# 1. PATCH lib/main.dart (Theme, Server URL, Food Bank, Live Workout)
# ============================================================================
main_path = "lib/main.dart"
if os.path.exists(main_path):
    shutil.copyfile(main_path, main_path + ".bak")
    print(f"✅ Backup created: {main_path}.bak")

    with open(main_path, "r", encoding="utf-8") as f:
        code = f.read()

    # الف) اصلاح آدرس سرور کلودفلر به ساب‌دامین اختصاصی
    old_worker = "https://bodymod-core.matin-mohammadi.workers.dev"
    new_worker = "https://server.matin-mohammadi.ir"
    if old_worker in code:
        code = code.replace(old_worker, new_worker)
        print("✅ Server URLs unified to server.matin-mohammadi.ir")

    # ب) حذف دستکاری خطرناک bmIsDarkTheme از داخل متدهای build
    code = code.replace("bmIsDarkTheme = Theme.of(context).brightness == Brightness.dark;", "")

    # ج) اصلاح BMColors برای کنتراست عالی در هر دو حالت دارک و لایت
    old_bmcolors = """class BMColors {
  static Color get bgDark => bmBgColor;
  static Color get surfaceDark => bmCardColor;
  static Color get cardDark => bmSurfaceColor;
  static Color get cardBorderDark => bmSurfaceColor;

  static const Color neonCyan = Color(0xFF00F5D4);
  static const Color neonGreen = Color(0xFF10B981);
  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color flameOrange = Color(0xFFFF6B35);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color whaleGold = Color(0xFFFFD700);
  static const Color purpleAccent = Color(0xFF8B5CF6);

  static const Color bgLight = Color(0xFFF3F6FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0xFFE2E8F0);
}"""

    new_bmcolors = """class BMColors {
  static Color get bgDark => bmBgColor;
  static Color get surfaceDark => bmCardColor;
  static Color get cardDark => bmCardColor;
  static Color get cardBorderDark => bmBorderColor;

  static Color get neonCyan => bmIsDarkTheme ? const Color(0xFF00F5D4) : const Color(0xFF0D9488);
  static Color get neonGreen => bmIsDarkTheme ? const Color(0xFF10B981) : const Color(0xFF059669);
  static const Color electricBlue = Color(0xFF2563EB);
  static const Color flameOrange = Color(0xFFEA580C);
  static const Color dangerRed = Color(0xFFDC2626);
  static Color get warningAmber => bmIsDarkTheme ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
  static Color get whaleGold => bmIsDarkTheme ? const Color(0xFFFFD700) : const Color(0xFFB45309);
  static const Color purpleAccent = Color(0xFF7C3AED);

  static const Color bgLight = Color(0xFFF1F5F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0xFFCBD5E1);
}"""

    if old_bmcolors in code:
        code = code.replace(old_bmcolors, new_bmcolors, 1)
        print("✅ BMColors patched")

    # د) اصلاح کامل BMTheme.dark() و BMTheme.light()
    old_bmtheme = """class BMTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: BMColors.bgDark,
      primaryColor: BMColors.neonCyan,
      colorScheme: ColorScheme.dark(
        primary: BMColors.neonCyan,
        secondary: BMColors.neonGreen,
        surface: BMColors.surfaceDark,
        error: BMColors.dangerRed,
      ),
      cardColor: BMColors.cardDark,
      dividerColor: BMColors.cardBorderDark,
      appBarTheme: AppBarTheme(
        backgroundColor: BMColors.bgDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 17.5,
          fontWeight: FontWeight.w900,
          color: bmTextColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bmCardColor,
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: BMColors.cardBorderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: BMColors.cardBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: BMColors.neonCyan, width: 1.8),
        ),
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: BMColors.bgLight,
      primaryColor: const Color(0xFF0D9488),
      colorScheme: ColorScheme.light(
        primary: Color(0xFF0D9488),
        secondary: Color(0xFF059669),
        surface: BMColors.surfaceLight,
        error: BMColors.dangerRed,
      ),
      cardColor: BMColors.cardLight,
      dividerColor: BMColors.cardBorderLight,
      appBarTheme: AppBarTheme(
        backgroundColor: BMColors.surfaceLight,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: bmCardColor),
        titleTextStyle: TextStyle(
          fontSize: 17.5,
          fontWeight: FontWeight.w900,
          color: bmCardColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: BMColors.cardBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: BMColors.cardBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.8),
        ),
      ),
    );
  }
}"""

    new_bmtheme = """class BMTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0F17),
      primaryColor: const Color(0xFF00F5D4),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00F5D4),
        secondary: Color(0xFF10B981),
        surface: Color(0xFF151B26),
        onSurface: Color(0xFFFFFFFF),
        error: Color(0xFFEF4444),
      ),
      cardColor: const Color(0xFF151B26),
      dividerColor: const Color(0xFF334155),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B0F17),
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontSize: 17.5,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF151B26),
        labelStyle: const TextStyle(color: Color(0xFFE2E8F0)),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00F5D4), width: 1.8),
        ),
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      primaryColor: const Color(0xFF0D9488),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0D9488),
        secondary: Color(0xFF059669),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF0F172A),
        error: Color(0xFFDC2626),
      ),
      cardColor: const Color(0xFFFFFFFF),
      dividerColor: const Color(0xFFCBD5E1),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(
          fontSize: 17.5,
          fontWeight: FontWeight.w900,
          color: Color(0xFF0F172A),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        labelStyle: const TextStyle(color: Color(0xFF334155)),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.8),
        ),
      ),
    );
  }
}"""

    if old_bmtheme in code:
        code = code.replace(old_bmtheme, new_bmtheme, 1)
        print("✅ BMTheme patched")

    # ه) آپدیت bmIsDarkTheme و آیکون‌های نوار وضعیت گوشی در لحظه‌ی سوییچ تم
    old_toggle = """  void toggleThemeMode() {
    isDarkMode = !isDarkMode;
    saveAllToDisk();
    notifyListeners();
  }"""

    new_toggle = """  void toggleThemeMode() {
    isDarkMode = !isDarkMode;
    bmIsDarkTheme = isDarkMode;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: bmBgColor,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
    saveAllToDisk();
    notifyListeners();
  }"""

    if old_toggle in code:
        code = code.replace(old_toggle, new_toggle, 1)

    old_app_builder = """      builder: (context, _) {
        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: BMTheme.light(),
          darkTheme: BMTheme.dark(),
          themeMode: (bmIsDarkTheme = controller.isDarkMode) ? ThemeMode.dark : ThemeMode.light,"""

    new_app_builder = """      builder: (context, _) {
        bmIsDarkTheme = controller.isDarkMode;
        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: BMTheme.light(),
          darkTheme: BMTheme.dark(),
          themeMode: controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,"""

    if old_app_builder in code:
        code = code.replace(old_app_builder, new_app_builder, 1)

    # و) حذف اجبار به دارک‌مود در دیالوگ‌ها
    code = code.replace(
        "builder: (ctx) => Theme(data: BMTheme.dark(), child: TwoStepAuthBottomSheet(controller: this)),",
        "builder: (ctx) => TwoStepAuthBottomSheet(controller: this),",
    )
    code = code.replace(
        "builder: (ctx) => Theme(data: BMTheme.dark(), child: RegistrationProfileFormDialog(controller: this)),",
        "builder: (ctx) => RegistrationProfileFormDialog(controller: this),",
    )
    old_fallback_dialog = """      builder: (ctx) => Theme(
        data: BMTheme.dark(),
        child: AlertDialog("""
    if old_fallback_dialog in code:
        code = code.replace(old_fallback_dialog, "      builder: (ctx) => AlertDialog(", 1)
        code = code.replace(
            """            ),
          ],
        ),
      ),
    );""",
            """            ),
          ],
        ),
    );""",
            1,
        )

    # ز) رفع رنگ‌های متن هاردکد شده و اتصال باشگاه زنده به bmExStr
    replacements = [
        (
            """                            color: (bmIsDarkTheme = c.isDarkMode) ? Colors.white
                                : bmCardColor,""",
            "                            color: bmTextColor,",
        ),
        (
            "color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold",
            "color: sel ? Colors.black : bmTextColor, fontWeight: FontWeight.bold",
        ),
        (
            "color: ok ? Colors.white : bmTextMutedColor",
            "color: ok ? bmTextColor : bmTextMutedColor",
        ),
        (
            "color: selected ? Colors.black : Colors.white,",
            "color: selected ? Colors.black : bmTextColor,",
        ),
        (
            """              colors: c.currentStreakState == StreakVisualState.redFire
                  ? [const Color(0xFF431407), bmSurfaceColor]
                  : c.currentStreakState == StreakVisualState.blueFrozen
                  ? [const Color(0xFF0C4A6E), bmSurfaceColor]
                  : [bmSurfaceColor, bmCardColor],""",
            """              colors: c.currentStreakState == StreakVisualState.redFire
                  ? (bmIsDarkTheme ? [const Color(0xFF431407), bmSurfaceColor] : [const Color(0xFFFFEDD5), bmCardColor])
                  : c.currentStreakState == StreakVisualState.blueFrozen
                  ? (bmIsDarkTheme ? [const Color(0xFF0C4A6E), bmSurfaceColor] : [const Color(0xFFE0F2FE), bmCardColor])
                  : [bmSurfaceColor, bmCardColor],""",
        ),
        (
            "color: Colors.black.withOpacity(0.35),",
            "color: bmIsDarkTheme ? Colors.black.withOpacity(0.35) : const Color(0xFFF1F5F9),",
        ),
        (
            "color: Color(0xFFFFB4AB),",
            "color: bmIsDarkTheme ? const Color(0xFFFFB4AB) : const Color(0xFFB91C1C),",
        ),
        (
            """                              : isCurrent
                              ? Colors.white
                              : bmTextMutedColor,""",
            """                              : isCurrent
                              ? bmTextColor
                              : bmTextMutedColor,""",
        ),
        (
            "color: Colors.black38,",
            "color: bmIsDarkTheme ? Colors.black38 : Colors.black12,",
        ),
        (
            "colors: [Color(0xFF3B2F0B), bmSurfaceColor],",
            "colors: bmIsDarkTheme ? [const Color(0xFF3B2F0B), bmSurfaceColor] : [const Color(0xFFFEF3C7), bmCardColor],",
        ),
        (
            "color: Colors.white.withOpacity(0.03),",
            "color: bmIsDarkTheme ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),",
        ),
        (
            "                activeStep.name,",
            "                bmExStr(safeIdx, 'title', activeStep.name),",
        ),
        (
            "'🎯 عضله هدف: ${activeStep.muscleGroup} • تکرار: ${activeStep.repsOrDuration}',",
            "'🎯 عضله هدف: ${bmExStr(safeIdx, 'muscle', activeStep.muscleGroup)} • تکرار: ${activeStep.repsOrDuration}',",
        ),
        (
            "'🫁 ریتم تنفس: ${activeStep.breathingGuide}',",
            "'🫁 ریتم تنفس: ${bmExStr(safeIdx, 'breath', activeStep.breathingGuide)}',",
        ),
        (
            "'💡 نکته مربی: ${activeStep.coachNote}',",
            "'💡 نکته مربی: ${bmExStr(safeIdx, 'tip', activeStep.coachNote)}',",
        ),
    ]
    for old, new in replacements:
        code = code.replace(old, new)

    # ح) رفع باگ کیک خامه‌ای ۷ کالری در بانک غذا
    bad_food_pattern = re.compile(
        r"FoodBankUnitItem\(\s*id:\s*'nt_almond_pistachio',.*?FoodBankUnitItem\(\s*id:\s*'nt_raisins',",
        re.DOTALL,
    )
    fixed_foods = """FoodBankUnitItem(
      id: 'nt_almond',
      category: 'آجیل و خشکبار 🥜',
      title: 'بادام درختی (خام یا بوداده)',
      baseUnitName: 'عدد (۱ دانه)',
      caloriesPerUnit: 7,
      proteinPerUnit: 0.3,
      carbsPerUnit: 0.3,
      fatPerUnit: 0.6,
      emoji: '🌰',
      alternateUnitsMultiplier: {'عدد (۱ دانه)': 1.0, 'قاشق غذاخوری (۱۰ عدد)': 10.0, 'مشت (۲۰ عدد)': 20.0},
    ),
    FoodBankUnitItem(
      id: 'nt_peanut',
      category: 'آجیل و خشکبار 🥜',
      title: 'بادام زمینی (خام یا بوداده)',
      baseUnitName: 'عدد (۱ دانه)',
      caloriesPerUnit: 6,
      proteinPerUnit: 0.3,
      carbsPerUnit: 0.2,
      fatPerUnit: 0.5,
      emoji: '🥜',
      alternateUnitsMultiplier: {'عدد (۱ دانه)': 1.0, 'قاشق غذاخوری (۱۰ عدد)': 10.0, 'مشت (۲۰ عدد)': 20.0},
    ),
    FoodBankUnitItem(
      id: 'nt_pistachio',
      category: 'آجیل و خشکبار 🥜',
      title: 'پسته (خام یا شور)',
      baseUnitName: 'عدد (۱ دانه)',
      caloriesPerUnit: 4,
      proteinPerUnit: 0.2,
      carbsPerUnit: 0.2,
      fatPerUnit: 0.3,
      emoji: '🌰',
      alternateUnitsMultiplier: {'عدد (۱ دانه)': 1.0, 'مشت کوچک (۱۵ عدد)': 15.0, 'مشت بزرگ (۳۰ عدد)': 30.0},
    ),
    FoodBankUnitItem(
      id: 'nt_hazelnut',
      category: 'آجیل و خشکبار 🥜',
      title: 'فندق (خام یا بوداده)',
      baseUnitName: 'عدد (۱ دانه)',
      caloriesPerUnit: 9,
      proteinPerUnit: 0.2,
      carbsPerUnit: 0.2,
      fatPerUnit: 0.8,
      emoji: '🌰',
      alternateUnitsMultiplier: {'عدد (۱ دانه)': 1.0, 'مشت کوچک (۱۰ عدد)': 10.0, 'مشت بزرگ (۲۰ عدد)': 20.0},
    ),
    FoodBankUnitItem(
      id: 'nt_cashew',
      category: 'آجیل و خشکبار 🥜',
      title: 'بادام هندی (کاجو)',
      baseUnitName: 'عدد (۱ دانه)',
      caloriesPerUnit: 9,
      proteinPerUnit: 0.3,
      carbsPerUnit: 0.5,
      fatPerUnit: 0.7,
      emoji: '🥜',
      alternateUnitsMultiplier: {'عدد (۱ دانه)': 1.0, 'مشت کوچک (۱۰ عدد)': 10.0, 'مشت بزرگ (۲۰ عدد)': 20.0},
    ),
    FoodBankUnitItem(
      id: 'nt_mixed_nuts',
      category: 'آجیل و خشکبار 🥜',
      title: 'آجیل چهارمغز مخلوط',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 65,
      proteinPerUnit: 2.0,
      carbsPerUnit: 2.2,
      fatPerUnit: 5.5,
      emoji: '🥣',
      alternateUnitsMultiplier: {'قاشق غذاخوری': 1.0, 'مشت (۳ قاشق)': 3.0, 'پیاله (۵ قاشق)': 5.0},
    ),
    FoodBankUnitItem(
      id: 'sn_sponge_cake',
      category: 'تنقلات و دسر 🍫',
      title: 'کیک خانگی یا اسفنجی ساده',
      baseUnitName: 'برش متوسط (۵۰ گرم)',
      caloriesPerUnit: 165,
      proteinPerUnit: 3.0,
      carbsPerUnit: 24.0,
      fatPerUnit: 6.5,
      emoji: '🍰',
      alternateUnitsMultiplier: {'نصف برش': 0.5, 'برش متوسط (۵۰ گرم)': 1.0, 'برش بزرگ (۱۰۰ گرم)': 2.0},
    ),
    FoodBankUnitItem(
      id: 'sn_choco_cake',
      category: 'تنقلات و دسر 🍫',
      title: 'کیک شکلاتی یا خامه‌ای',
      baseUnitName: 'برش متوسط (۷۰ گرم)',
      caloriesPerUnit: 260,
      proteinPerUnit: 3.5,
      carbsPerUnit: 34.0,
      fatPerUnit: 12.5,
      emoji: '🎂',
      alternateUnitsMultiplier: {'نصف برش': 0.5, 'برش متوسط (۷۰ گرم)': 1.0, 'برش بزرگ': 1.5},
    ),
    FoodBankUnitItem(
      id: 'sn_dry_pastry',
      category: 'تنقلات و دسر 🍫',
      title: 'شیرینی خشک یا دانمارکی',
      baseUnitName: 'عدد متوسط',
      caloriesPerUnit: 145,
      proteinPerUnit: 2.2,
      carbsPerUnit: 19.0,
      fatPerUnit: 6.8,
      emoji: '🥐',
      alternateUnitsMultiplier: {'نصف عدد': 0.5, 'عدد متوسط': 1.0, '۲ عدد': 2.0},
    ),
    FoodBankUnitItem(
      id: 'sn_cream_pastry',
      category: 'تنقلات و دسر 🍫',
      title: 'شیرینی تر خامه‌ای (رولت / ناپلئونی)',
      baseUnitName: 'عدد متوسط',
      caloriesPerUnit: 240,
      proteinPerUnit: 3.0,
      carbsPerUnit: 27.0,
      fatPerUnit: 13.5,
      emoji: '🧁',
      alternateUnitsMultiplier: {'نصف عدد': 0.5, 'عدد متوسط': 1.0, '۲ عدد': 2.0},
    ),
    FoodBankUnitItem(
      id: 'sn_koloocheh',
      category: 'تنقلات و دسر 🍫',
      title: 'کلوچه یا کاپ‌کیک',
      baseUnitName: 'عدد (۱ دانه)',
      caloriesPerUnit: 210,
      proteinPerUnit: 3.2,
      carbsPerUnit: 32.0,
      fatPerUnit: 7.5,
      emoji: '🍪',
      alternateUnitsMultiplier: {'نصف عدد': 0.5, 'عدد (۱ دانه)': 1.0},
    ),
    FoodBankUnitItem(
      id: 'nt_raisins',"""

    code, c_food = bad_food_pattern.subn(fixed_foods, code, count=1)
    if c_food:
        print("✅ Food bank calories fixed")

    with open(main_path, "w", encoding="utf-8") as f:
        f.write(code)
    print("🚀 lib/main.dart updated successfully!")

# ============================================================================
# 2. PATCH Local AndroidManifest.xml (if present)
# ============================================================================
manifest_path = "android/app/src/main/AndroidManifest.xml"
perm_tag = '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>'
if os.path.exists(manifest_path):
    with open(manifest_path, "r", encoding="utf-8") as f:
        m_code = f.read()
    if "POST_NOTIFICATIONS" not in m_code:
        shutil.copyfile(manifest_path, manifest_path + ".bak")
        m_code = m_code.replace("<application", f"    {perm_tag}\n    <application", 1)
        with open(manifest_path, "w", encoding="utf-8") as f:
            f.write(m_code)
        print("✅ POST_NOTIFICATIONS added to local AndroidManifest.xml")
    else:
        print("ℹ️ Local AndroidManifest.xml already has POST_NOTIFICATIONS")

# ============================================================================
# 3. PATCH GitHub Actions Workflow YAML (.github/workflows/*.yml)
# ============================================================================
yml_files = glob.glob(".github/workflows/*.yml") + glob.glob(".github/workflows/*.yaml")
for yml_path in yml_files:
    with open(yml_path, "r", encoding="utf-8") as f:
        yml = f.read()
    if "POST_NOTIFICATIONS" in yml:
        print(f"ℹ️ {yml_path} already has POST_NOTIFICATIONS")
        continue
    lines = yml.splitlines(True)
    build_idx = next((i for i, l in enumerate(lines) if "flutter build" in l), None)
    if build_idx is not None:
        step_idx = build_idx
        while step_idx > 0 and not re.match(r"^\s*-\s+", lines[step_idx]):
            step_idx -= 1
        m = re.match(r"^(\s*)-\s+", lines[step_idx])
        if m:
            shutil.copyfile(yml_path, yml_path + ".bak")
            indent = m.group(1)
            inject = (
                f"{indent}- name: Inject Android 13+ POST_NOTIFICATIONS Permission\n"
                f"{indent}  run: |\n"
                f"{indent}    MANIFEST=\"android/app/src/main/AndroidManifest.xml\"\n"
                f"{indent}    if [ -f \"$MANIFEST\" ] && ! grep -q \"POST_NOTIFICATIONS\" \"$MANIFEST\"; then\n"
                f"{indent}      sed -i 's/<application/<uses-permission android:name=\"android.permission.POST_NOTIFICATIONS\"\\/>\\n    <application/' \"$MANIFEST\"\n"
                f"{indent}    fi\n"
            )
            lines.insert(step_idx, inject)
            with open(yml_path, "w", encoding="utf-8") as f:
                f.writelines(lines)
            print(f"✅ Patched GitHub Workflow YAML: {yml_path}")
    else:
        print(f"⚠️ No 'flutter build' step found in {yml_path}")

print("🎉 تموم شد متین! الان git push بزن و بیلد جدید رو تست کن! 🔥🚀")
