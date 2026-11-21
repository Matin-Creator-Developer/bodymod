with open("lib/main.dart", "r", encoding="utf-8") as f:
    d = f.read()

# 1. Fix bmGenerateAiWorkoutPlan: send real _authHeaders + real endpoint + strict success & quota lock
old_gym_sig = "Future<bool> bmGenerateAiWorkoutPlan(BuildContext context, {VoidCallback? onDone}) async {"
new_gym_sig = "Future<bool> bmGenerateAiWorkoutPlan(BuildContext context, {VoidCallback? onDone, Map<String, String>? authHeaders}) async {"
assert old_gym_sig in d, "❌ امضای bmGenerateAiWorkoutPlan پیدا نشد!"
d = d.replace(old_gym_sig, new_gym_sig, 1)

old_gym_post = """    final res = await http.post(
      Uri.parse('https://server.matin-mohammadi.ir/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': prompt, 'prompt': prompt, 'mode': 'workout_plan', 'model': 'gemini-3.1-flash-lite'}),
    ).timeout(const Duration(seconds: 25));"""

new_gym_post = """    final reqHeaders = <String, String>{'Content-Type': 'application/json'};
    if (authHeaders != null) reqHeaders.addAll(authHeaders);
    final res = await http.post(
      Uri.parse('${AppConfig.serverBaseUrl}/api/ai/workout-plan'),
      headers: reqHeaders,
      body: jsonEncode({'message': prompt, 'prompt': prompt, 'mode': 'workout_plan', 'model': 'gemini-3.1-flash-lite'}),
    ).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      String errMsg = 'خطا در ساخت برنامه ورزشی! مطمئن شو وارد شدی و اشتراکت فعاله 🔒';
      try {
        final errData = jsonDecode(utf8.decode(res.bodyBytes));
        if (errData is Map && errData['error'] != null) {
          errMsg = errData['error'].toString();
        }
      } catch (_) {}
      bmIsGeneratingWorkout = false;
      if (onDone != null) onDone();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errMsg)));
      }
      return false;
    }"""

assert old_gym_post in d, "❌ بخش http.post در bmGenerateAiWorkoutPlan پیدا نشد!"
d = d.replace(old_gym_post, new_gym_post, 1)

# Only show green snackbar & return true if exercises list is actually non-empty!
old_gym_success = """        if (parsed['exercises'] is List && (parsed['exercises'] as List).isNotEmpty) {
          final List<dynamic> arr = parsed['exercises'];
          bmAiCustomWorkouts = arr.map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))).toList();
          await prefs.setString('bm_ai_custom_workouts_v1', jsonEncode(bmAiCustomWorkouts));
          bmWorkoutQuotaWeekUsedGlobal = bmCurrentIranWeekKey();
          bmRemainingWorkoutQuotaGlobal = 0;
          await prefs.setString('bm_workout_quota_week_v1', bmWorkoutQuotaWeekUsedGlobal);
        }
        bmIsGeneratingWorkout = false;
        if (onDone != null) onDone();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ برنامه تمرینی، کالری‌سوزی و میان‌وعده کالری مازاد توسط هوش مصنوعی تنظیم شد! 💪🔥'), backgroundColor: Color(0xFF00C896)));
        }
        return true;"""

new_gym_success = """        if (parsed['exercises'] is List && (parsed['exercises'] as List).isNotEmpty) {
          final List<dynamic> arr = parsed['exercises'];
          bmAiCustomWorkouts = arr.map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))).toList();
          await prefs.setString('bm_ai_custom_workouts_v1', jsonEncode(bmAiCustomWorkouts));
          bmWorkoutQuotaWeekUsedGlobal = bmCurrentIranWeekKey();
          bmRemainingWorkoutQuotaGlobal = 0;
          await prefs.setString('bm_workout_quota_week_v1', bmWorkoutQuotaWeekUsedGlobal);
          bmIsGeneratingWorkout = false;
          if (onDone != null) onDone();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ برنامه تمرینی، کالری‌سوزی و میان‌وعده کالری مازاد توسط هوش مصنوعی تنظیم شد! 💪🔥'), backgroundColor: Color(0xFF00C896)));
          }
          return true;
        }"""

assert old_gym_success in d, "❌ بخش موفقیت bmGenerateAiWorkoutPlan پیدا نشد!"
d = d.replace(old_gym_success, new_gym_success, 1)

# Pass c._authHeaders at both call sites of bmGenerateAiWorkoutPlan
d = d.replace(
    "bmGenerateAiWorkoutPlan(context, onDone: () => setState(() {}))",
    "bmGenerateAiWorkoutPlan(context, authHeaders: c._authHeaders, onDone: () => setState(() {}))"
)
d = d.replace(
    """                        : () => bmGenerateAiWorkoutPlan(
                              context,
                              onDone: () {""",
    """                        : () => bmGenerateAiWorkoutPlan(
                              context,
                              authHeaders: c._authHeaders,
                              onDone: () {"""
)
print("✅ 1. باشگاه زنده فیکس شد (ارسال هدر احراز هویت + باز شدن فوری UI + قفل قطعی هفتگی)!")

# 2. Clear local cached data on signOutAccount (Cloudflare KV keeps user's real data & AI memory safe!)
old_signout = """    profile = UserProfileModel();
    appliedDiscountCode = '';
    appliedDiscountPercent = 0;
    discountedSubscriptionPriceToman = AppConfig.monthlySubscriptionPriceToman;
    await saveAllToDisk();
    notifyListeners();"""

new_signout = """    profile = UserProfileModel();
    weeklyMealPlan = {};
    chatMessages = [];
    customAiFoods = [];
    todayFoodLogs = [];
    bodyLogsHistory = [];
    bmAiCustomWorkouts = [];
    bmAccountIdGlobal = '';
    bmIsAdminGlobal = false;
    bmWorkoutQuotaWeekUsedGlobal = '';
    bmRemainingWorkoutQuotaGlobal = 1;
    bmWorkoutBurnKcal = 0;
    bmAiSurplusSnack = '';
    appliedDiscountCode = '';
    appliedDiscountPercent = 0;
    discountedSubscriptionPriceToman = AppConfig.monthlySubscriptionPriceToman;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('bm_ai_custom_workouts_v1');
      await prefs.remove('bm_workout_quota_week_v1');
      await prefs.remove('bm_ai_workout_burn_kcal');
      await prefs.remove('bm_ai_surplus_snack');
    } catch (_) {}
    await saveAllToDisk();
    notifyListeners();"""

assert old_signout in d, "❌ تابع signOutAccount پیدا نشد!"
d = d.replace(old_signout, new_signout, 1)
print("✅ 2. پاکسازی کش محلی در لاگ‌اوت اضافه شد (اطلاعات و حافظه هوش مصنوعی در کلودفلر امن می‌مونه)!")

# 3. Lock & hide WeeklyMealPlanTab until logged in + subscribed + meal plan generated
old_meal_head = """    final bool hasPlan = c.weeklyMealPlan.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 95),"""

new_meal_head = r"""    final bool hasPlan = c.weeklyMealPlan.isNotEmpty;
    final bool canAccessMeal = c.profile.isAdmin ||
        (c.profile.isLoggedIn && c.profile.hasActiveSubscription);
    final bool mealQuotaExhausted =
        !c.profile.isAdmin && c.remainingMealPlanQuota <= 0;

    if (!canAccessMeal || !hasPlan) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 95),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bmCardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: BMColors.neonCyan.withOpacity(0.45)),
            ),
            child: Column(
              children: [
                Text(
                  !canAccessMeal ? '🔒🥗' : '🥗🤖',
                  style: const TextStyle(fontSize: 42),
                ),
                const SizedBox(height: 12),
                Text(
                  !canAccessMeal
                      ? 'برنامه غذایی قفله رفیق!'
                      : 'هنوز برنامه غذایی اختصاصیت رو دریافت نکردی!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                    color: bmTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  !canAccessMeal
                      ? 'برای دریافت برنامه غذایی ۷ روزه متنوع با هوش مصنوعی، اول از تب پروفایل وارد حسابت شو و اشتراکت رو فعال کن! 💪🔥'
                      : 'روی دکمه زیر بزن تا مربی هوشمند بر اساس هدف، بودجه و حافظه مربی تو، برنامه غذایی ۷ روزه اختصاصی این هفته‌ت رو بسازه (سهمیه: هفته‌ای ۱ بار).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: bmTextSubColor,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BMColors.neonCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: (!canAccessMeal ||
                            mealQuotaExhausted ||
                            c.isLoadingAi)
                        ? null
                        : () async {
                            final ok = await c.requestAiWeeklyMealPlan(context);
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'برنامه غذایی ۷ روزه اختصاصیت ساخته شد! 🔥🥗',
                                  ),
                                ),
                              );
                            }
                          },
                    icon: c.isLoadingAi
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.restaurant_menu_rounded, size: 19),
                    label: Text(
                      !canAccessMeal
                          ? 'ابتدا وارد شو و اشتراک رو فعال کن 🔒'
                          : (mealQuotaExhausted
                              ? 'سهمیه‌ت تموم شده رفیق 😉'
                              : (c.isLoadingAi
                                  ? 'در حال ساخت برنامه غذایی... ⏳'
                                  : 'دریافت/تمدید برنامه غذایی')),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 95),"""

assert old_meal_head in d, "❌ بخش WeeklyMealPlanTab پیدا نشد!"
d = d.replace(old_meal_head, new_meal_head, 1)
print("✅ 3. تب برنامه غذایی دقیقاً مثل باشگاه زنده قفل و خالی شد!")

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(d)

print("\n🎉 تمام ۳ فیکس نهایی با موفقیت و بدون ارور اعمال شد!")

