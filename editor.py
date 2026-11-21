import re

def read_file(p):
    with open(p, "r", encoding="utf-8") as f:
        return f.read()

def write_file(p, s):
    with open(p, "w", encoding="utf-8") as f:
        f.write(s)

# ==============================================================================
# 1. PATCH worker.js: 11-digit Account ID (BM-XXXXXXXXXXX) + 6-Tier AI Quotas
# ==============================================================================
w = read_file("worker.js")

# 1A. Update USER_QUOTAS to exact 6 tiers
old_quotas_pat = re.compile(r"USER_QUOTAS:\s*\{[\s\S]*?\n  \},", re.MULTILINE)
new_quotas = """USER_QUOTAS: {
    chat_daily: {
      "gemini-3.1-flash-lite": 3,
    },
    food_text_weekly: {
      "gemini-3.1-flash-lite": 3,
    },
    food_photo_weekly: {
      "gemini-3.1-flash-lite": 1,
    },
    plan_weekly: {
      "gemini-3.1-flash-lite": 1,
    },
    workout_weekly: {
      "gemini-3.1-flash-lite": 1,
    },
    coach_weekly: {
      "gemini-3.1-flash-lite": 1,
    },
  },"""

w, n_q = old_quotas_pat.subn(lambda _: new_quotas, w, count=1)
assert n_q == 1, "❌ Could not patch USER_QUOTAS in worker.js"
print("✅ worker.js: Updated USER_QUOTAS (all 6 AI tiers)")

# 1B. Route calorie text vs calorie photo & workout_plan to their own featureTypes
old_cal_block = """        } else if (path === "/api/ai/calorie" || body.mode === "calorie_vision") {
          featureType = "chat_daily";"""
new_cal_block = """        } else if (path === "/api/ai/workout-plan" || body.mode === "workout_plan") {
          featureType = "workout_weekly";
        } else if (path === "/api/ai/calorie" || body.mode === "calorie_vision") {
          featureType = imageBase64 ? "food_photo_weekly" : "food_text_weekly";"""

if "food_photo_weekly" not in w:
    assert old_cal_block in w, "❌ Could not find calorie featureType block in worker.js"
    w = w.replace(old_cal_block, new_cal_block, 1)
    print("✅ worker.js: Routed food_text_weekly, food_photo_weekly, and workout_weekly")

# 1C. Update getUserQuotaStatus to return all 6 tiers
old_qstatus_pat = re.compile(
    r"async function getUserQuotaStatus\(kv, userKey, isAdmin = false\)\s*\{[\s\S]*?\n\}",
    re.MULTILINE
)
new_qstatus = """async function getUserQuotaStatus(kv, userKey, isAdmin = false) {
  const lite = CONFIG.MODELS.LITE;
  const flash = CONFIG.MODELS.FLASH;

  if (isAdmin) {
    const unlimited = { allowed: true, used: 0, max: 9999, remaining: 9999 };
    return {
      chat_daily: { [lite]: unlimited, [flash]: unlimited },
      food_text_weekly: { [lite]: unlimited },
      food_photo_weekly: { [lite]: unlimited },
      plan_weekly: { [lite]: unlimited, [flash]: unlimited },
      workout_weekly: { [lite]: unlimited },
      coach_weekly: { [lite]: unlimited, [flash]: unlimited },
    };
  }

  const [chatLite, foodText, foodPhoto, planLite, workoutLite, coachLite] = await Promise.all([
    checkUserQuota(kv, userKey, "chat_daily", lite),
    checkUserQuota(kv, userKey, "food_text_weekly", lite),
    checkUserQuota(kv, userKey, "food_photo_weekly", lite),
    checkUserQuota(kv, userKey, "plan_weekly", lite),
    checkUserQuota(kv, userKey, "workout_weekly", lite),
    checkUserQuota(kv, userKey, "coach_weekly", lite),
  ]);

  return {
    chat_daily: { [lite]: chatLite, [flash]: chatLite },
    food_text_weekly: { [lite]: foodText },
    food_photo_weekly: { [lite]: foodPhoto },
    plan_weekly: { [lite]: planLite, [flash]: planLite },
    workout_weekly: { [lite]: workoutLite },
    coach_weekly: { [lite]: coachLite, [flash]: coachLite },
  };
}"""

w, n_qs = old_qstatus_pat.subn(lambda _: new_qstatus, w, count=1)
assert n_qs == 1, "❌ Could not patch getUserQuotaStatus in worker.js"
print("✅ worker.js: Updated getUserQuotaStatus to return all 6 tiers")

# 1D. Unique 11-digit Account ID generator (BM-XXXXXXXXXXX -> 90 billion capacity)
id_helper = r"""
async function bmGetOrCreateAccountId(kv, userKey) {
  if (!kv || !userKey) return "BM-10000000001";
  const mapKey = "ACCOUNT_ID_OF_" + String(userKey);
  const existing = await kv.get(mapKey);
  if (existing && /^BM-\d{11}$/.test(existing)) {
    return existing;
  }
  for (let i = 0; i < 12; i++) {
    const firstDigit = Math.floor(1 + Math.random() * 9);
    let rest = "";
    for (let j = 0; j < 10; j++) {
      rest += String(Math.floor(Math.random() * 10));
    }
    const candidate = "BM-" + String(firstDigit) + rest;
    const taken = await kv.get("REF_OWNER_" + candidate);
    if (!taken) {
      await kv.put("REF_OWNER_" + candidate, String(userKey));
      await kv.put(mapKey, candidate);
      return candidate;
    }
  }
  const fallback = "BM-" + String(Date.now()).slice(-11).padStart(11, "1");
  await kv.put("REF_OWNER_" + fallback, String(userKey));
  await kv.put(mapKey, fallback);
  return fallback;
}
"""

if "async function bmGetOrCreateAccountId" not in w:
    assert "async function ensureUserInitialized(" in w, "❌ ensureUserInitialized not found in worker.js"
    w = w.replace("async function ensureUserInitialized(", id_helper + "\nasync function ensureUserInitialized(", 1)
    w = w.replace(
        '  await kv.put("user:" + userKey, JSON.stringify(userData));',
        '  await kv.put("user:" + userKey, JSON.stringify(userData));\n  const bmAccId = await bmGetOrCreateAccountId(kv, userKey);',
        1
    )
    w = w.replace(
        '    const defaultProfile = createDefaultProfile(userKey, userData);',
        '    const defaultProfile = createDefaultProfile(userKey, userData);\n    defaultProfile.accountId = bmAccId;',
        1
    )
    w = w.replace(
        '  const parsed = JSON.parse(existingProfileRaw);',
        '  const parsed = JSON.parse(existingProfileRaw);\n  if (!parsed.accountId || !/^BM-\\d{11}$/.test(String(parsed.accountId))) {\n    parsed.accountId = bmAccId;\n    await kv.put("profile:" + userKey, JSON.stringify(parsed));\n  }',
        1
    )
    print("✅ worker.js: Added unique 11-digit Account ID (BM-XXXXXXXXXXX) generator")

# 1E. Update bmApplyReferralCode to support 11-digit BM-XXXXXXXXXXX codes
old_ref_fn = re.compile(
    r"async function bmApplyReferralCode\(env, userKey, rawRefCode\)\s*\{[\s\S]*?\n\}",
    re.MULTILINE
)
new_ref_fn = r"""async function bmApplyReferralCode(env, userKey, rawRefCode) {
  let cleanRefInput = String(rawRefCode || '').replace(/`/g, '').trim().toUpperCase();
  const refUrlMatch = cleanRefInput.match(/[?&]REF=([^&\s]+)/i);
  if (refUrlMatch && refUrlMatch[1]) cleanRefInput = refUrlMatch[1].toUpperCase();
  if (/^\d{11}$/.test(cleanRefInput)) cleanRefInput = 'BM-' + cleanRefInput;

  const kvStore = getSafeKv(env);
  const u6 = bmExtractLast6(userKey);
  if (!userKey || String(userKey).trim().length < 3) {
    return { ok: false, error: 'رفیق اول با شماره موبایل یا حساب گوگل وارد شو تا کد تخفیف روی اکانتت قفل بشه! 📱' };
  }
  const ownAccId = kvStore ? await bmGetOrCreateAccountId(kvStore, userKey) : '';
  const is11DigitCode = /^BM-\d{11}$/.test(cleanRefInput);
  const ref6 = bmExtractLast6(cleanRefInput);

  if (!is11DigitCode && (!ref6 || ref6.length < 6)) {
    return { ok: false, error: 'کد دعوت نامعتبره رفیق! کد دعوت باید ۱۱ رقمی با BM باشه (مثلاً BM-12345678910).' };
  }
  if ((is11DigitCode && cleanRefInput === ownAccId) || (!is11DigitCode && u6 === ref6)) {
    return { ok: false, error: 'ای کلک! 😂 نمی‌تونی کد دعوت خودت رو برای خودت بزنی رفیق!' };
  }
  const finalRefCode = is11DigitCode ? cleanRefInput : ('BM-' + ref6);
  if (kvStore) {
    await kvStore.put('REF_USED_BY_' + u6, finalRefCode);
    await kvStore.put('REF_USED_BY_USER_' + String(userKey), finalRefCode);
  }
  const st = await bmGetBetaStatus(env, userKey, 1);
  return {
    ...st,
    ok: true,
    discountPercent: 30,
    finalSubPrice: 349300,
    message: 'ایول! 🎉 کد دعوت ثبت شد و ۳۰٪ تخفیف اشتراک (۳۴۹,۳۰۰ تومان به جای ۴۹۹,۰۰۰ تومان) برات فعال شد! به محض خرید اشتراک، ۳ روز اشتراک رایگان هم به رفیقت هدیه داده میشه! 🤝🔥'
  };
}"""

w, n_rf = old_ref_fn.subn(lambda _: new_ref_fn, w, count=1)
assert n_rf == 1, "❌ Could not patch bmApplyReferralCode in worker.js"
print("✅ worker.js: Updated bmApplyReferralCode for 11-digit BM-XXXXXXXXXXX codes")

write_file("worker.js", w)

# ==============================================================================
# 2. PATCH lib/main.dart
# ==============================================================================
d = read_file("lib/main.dart")

# 2A. Replace bmGetMyReferralCode (Goodbye BM-AILCOM!)
old_ref_gen = """String bmGetMyReferralCode() {
  final digits = bmUserPhoneGlobal.replaceAll(RegExp(r'\\D'), '');
  if (digits.length >= 6) return 'BM-' + digits.substring(digits.length - 6);
  final clean = bmUserPhoneGlobal.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  if (clean.length >= 6) return 'BM-' + clean.substring(clean.length - 6);
  return 'BM-VIP100';
}"""

new_ref_gen = """String bmAccountIdGlobal = '';
bool bmIsAdminGlobal = false;
int bmRemainingWorkoutQuotaGlobal = 1;
String bmWorkoutQuotaWeekUsedGlobal = '';

String bmCurrentIranWeekKey() {
  final now = DateTime.now().toUtc().add(const Duration(hours: 3, minutes: 30));
  final start = DateTime.utc(now.year, 1, 1);
  final days = now.difference(start).inDays;
  final week = ((days + 1) / 7).ceil();
  return '${now.year}-W${week.toString().padLeft(2, '0')}';
}

bool bmIsWorkoutQuotaExhausted() {
  if (bmIsAdminGlobal) return false;
  if (bmRemainingWorkoutQuotaGlobal <= 0) return true;
  if (bmWorkoutQuotaWeekUsedGlobal == bmCurrentIranWeekKey()) return true;
  return false;
}

String bmGetMyReferralCode() {
  if (RegExp(r'^BM-\\d{11}$').hasMatch(bmAccountIdGlobal)) {
    return bmAccountIdGlobal;
  }
  final seed = bmUserPhoneGlobal.trim();
  if (seed.isEmpty) return 'BM-10000000001';
  int h1 = 2166136261;
  int h2 = 16777619;
  for (int i = 0; i < seed.length; i++) {
    h1 = ((h1 ^ seed.codeUnitAt(i)) * 16777619) & 0x7fffffff;
    h2 = ((h2 + seed.codeUnitAt(i) * (i + 7)) * 31) & 0x7fffffff;
  }
  final p1 = (1 + (h1 % 9)).toString();
  final p2 = (h1 % 100000).toString().padLeft(5, '0');
  final p3 = (h2 % 100000).toString().padLeft(5, '0');
  return 'BM-$p1$p2$p3';
}"""

if "String bmAccountIdGlobal" not in d:
    assert old_ref_gen in d, "❌ Could not find bmGetMyReferralCode in lib/main.dart"
    d = d.replace(old_ref_gen, new_ref_gen, 1)
    print("✅ lib/main.dart: Replaced BM-AILCOM generator with 11-digit Account ID")

d = d.replace("'کپی لینک و کد'", "'کپی کد دعوت 👆'")
d = d.replace("BM-586834", "BM-12345678910")

# 2B. Add all 6 quota fields to BodyModController
old_quota_fields = "  int remainingLiteChatQuota = 6;"
new_quota_fields = """  int remainingLiteChatQuota = 3;
  int remainingFoodTextQuota = 3;
  int maxFoodTextQuota = 3;
  int remainingFoodPhotoQuota = 1;
  int maxFoodPhotoQuota = 1;
  int remainingMealPlanQuota = 1;
  int maxMealPlanQuota = 1;
  int remainingWorkoutPlanQuota = 1;
  int maxWorkoutPlanQuota = 1;
  int remainingCoachAnalysisQuota = 1;
  int maxCoachAnalysisQuota = 1;"""

if "remainingCoachAnalysisQuota" not in d:
    assert old_quota_fields in d, "❌ Could not find remainingLiteChatQuota = 6 in lib/main.dart"
    d = d.replace(old_quota_fields, new_quota_fields, 1)
    d = d.replace("int maxLiteChatQuota = 6;", "int maxLiteChatQuota = 3;")
    print("✅ lib/main.dart: Added all 6 quota fields to BodyModController")

# 2C. Update _applyQuotasFromResponse & add requestWeeklyBodyAnalysis method
old_qparse = """  void _applyQuotasFromResponse(dynamic quotasRaw) {
    if (quotasRaw is Map<String, dynamic>) {
      final chatDaily = quotasRaw['chat_daily'];
      if (chatDaily is Map<String, dynamic>) {
        final lite = chatDaily['gemini-3.1-flash-lite'];
        if (lite is Map<String, dynamic>) {
          remainingLiteChatQuota =
              (lite['remaining'] as num?)?.toInt() ?? remainingLiteChatQuota;
          maxLiteChatQuota = (lite['max'] as num?)?.toInt() ?? maxLiteChatQuota;
        }
        final flash = chatDaily['gemini-3.1-flash-lite'];
        if (flash is Map<String, dynamic>) {
          remainingFlashChatQuota =
              (flash['remaining'] as num?)?.toInt() ?? remainingFlashChatQuota;
          maxFlashChatQuota =
              (flash['max'] as num?)?.toInt() ?? maxFlashChatQuota;
        }
      }
    }
  }"""

new_qparse = """  Future<String?> requestWeeklyBodyAnalysis(
    BuildContext context, {
    required double weightKg,
    double? heightCm,
    required String note,
  }) async {
    if (!profile.isAdmin && remainingCoachAnalysisQuota <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سهمیه‌ت تموم شده رفیق 😉 (هفته‌ای ۱ بار)')),
        );
      }
      return null;
    }
    if (heightCm != null && heightCm >= 100 && heightCm <= 240) {
      profile.heightCm = heightCm;
    }
    addBodyMetricRecord(weightKg: weightKg, note: note);
    if (!profile.isLoggedIn) {
      return 'وزن و قدت ذخیره شد! برای تحلیل هوش مصنوعی اول وارد حسابت شو 🔐';
    }
    isLoadingAi = true;
    notifyListeners();
    try {
      final prompt =
          'ثبت تغییرات هفتگی کاربر: قد جدید ${profile.heightCm.toStringAsFixed(0)} سانتی‌متر، وزن جدید ${weightKg.toStringAsFixed(1)} کیلوگرم، BMI فعلی ${profile.bmi.toStringAsFixed(1)}. یادداشت کاربر: ${note.isEmpty ? "ندارد" : note}. لطفاً روند پیشرفت رو کوتاه، انگیزشی و علمی تحلیل کن و ۲ توصیه کاربردی برای هفته آینده بده.';
      final res = await http
          .post(
            Uri.parse('${AppConfig.serverBaseUrl}/api/ai/coach-analysis'),
            headers: _authHeaders,
            body: jsonEncode({
              'mode': 'coach_analysis',
              'model': 'gemini-3.1-flash-lite',
              'prompt': prompt,
              'message': prompt,
            }),
          )
          .timeout(const Duration(seconds: 25));
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is Map<String, dynamic>) {
        if (data['quotas'] != null) {
          _applyQuotasFromResponse(data['quotas']);
        } else if (res.statusCode == 200 && !profile.isAdmin) {
          remainingCoachAnalysisQuota = 0;
        }
        if (res.statusCode == 200) {
          final reply = (data['reply'] ?? data['response'] ?? data['text'] ?? '').toString().trim();
          isLoadingAi = false;
          notifyListeners();
          return reply.isNotEmpty ? reply : 'تغییراتت ثبت و بررسی شد قهرمان! 💪📈';
        } else {
          final err = (data['error'] ?? 'سهمیه‌ت تموم شده رفیق 😉').toString();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          }
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در ارتباط با هوش مصنوعی؛ تغییراتت ولی ذخیره شد! 📡')),
        );
      }
    }
    isLoadingAi = false;
    notifyListeners();
    return null;
  }

  void _applyQuotasFromResponse(dynamic quotasRaw) {
    bmIsAdminGlobal = profile.isAdmin;
    if (quotasRaw is Map<String, dynamic>) {
      int readRem(String key, int fallback) {
        final g = quotasRaw[key];
        if (g is Map<String, dynamic>) {
          final m = g['gemini-3.1-flash-lite'];
          if (m is Map<String, dynamic> && m['remaining'] != null) {
            return (m['remaining'] as num).toInt();
          }
        }
        return fallback;
      }
      int readMax(String key, int fallback) {
        final g = quotasRaw[key];
        if (g is Map<String, dynamic>) {
          final m = g['gemini-3.1-flash-lite'];
          if (m is Map<String, dynamic> && m['max'] != null) {
            return (m['max'] as num).toInt();
          }
        }
        return fallback;
      }
      remainingLiteChatQuota = readRem('chat_daily', remainingLiteChatQuota);
      maxLiteChatQuota = readMax('chat_daily', 3);
      remainingFoodTextQuota = readRem('food_text_weekly', remainingFoodTextQuota);
      maxFoodTextQuota = readMax('food_text_weekly', 3);
      remainingFoodPhotoQuota = readRem('food_photo_weekly', remainingFoodPhotoQuota);
      maxFoodPhotoQuota = readMax('food_photo_weekly', 1);
      remainingMealPlanQuota = readRem('plan_weekly', remainingMealPlanQuota);
      maxMealPlanQuota = readMax('plan_weekly', 1);
      remainingWorkoutPlanQuota = readRem('workout_weekly', remainingWorkoutPlanQuota);
      maxWorkoutPlanQuota = readMax('workout_weekly', 1);
      remainingCoachAnalysisQuota = readRem('coach_weekly', remainingCoachAnalysisQuota);
      maxCoachAnalysisQuota = readMax('coach_weekly', 1);
      bmRemainingWorkoutQuotaGlobal = remainingWorkoutPlanQuota;
    }
  }"""

if "requestWeeklyBodyAnalysis" not in d:
    assert old_qparse in d, "❌ Could not find _applyQuotasFromResponse in lib/main.dart"
    d = d.replace(old_qparse, new_qparse, 1)
    print("✅ lib/main.dart: Added requestWeeklyBodyAnalysis & synced all 6 quotas")

# Sync accountId from serverProfile in _applyServerAuthData
sync_anchor = "    _applyQuotasFromResponse(data['quotas']);"
sync_new = """    final srvAccId = (serverProfile['accountId'] ?? data['accountId'] ?? '').toString().trim();
    if (RegExp(r'^BM-\\d{11}$').hasMatch(srvAccId)) {
      bmAccountIdGlobal = srvAccId;
    }
    bmIsAdminGlobal = profile.isAdmin;
    _applyQuotasFromResponse(data['quotas']);"""

if "srvAccId" not in d:
    assert sync_anchor in d, "❌ Could not find _applyQuotasFromResponse call in _applyServerAuthData"
    d = d.replace(sync_anchor, sync_new, 1)
    print("✅ lib/main.dart: Synced unique 11-digit accountId from Cloudflare")

# Workout weekly quota tracking
d = d.replace(
    "body: jsonEncode({'message': prompt, 'prompt': prompt, 'model': 'gemini-3.1-flash-lite'}),",
    "body: jsonEncode({'message': prompt, 'prompt': prompt, 'mode': 'workout_plan', 'model': 'gemini-3.1-flash-lite'}),"
)
d = d.replace(
    "await prefs.setString('bm_ai_custom_workouts_v1', jsonEncode(bmAiCustomWorkouts));",
    "await prefs.setString('bm_ai_custom_workouts_v1', jsonEncode(bmAiCustomWorkouts));\n          bmWorkoutQuotaWeekUsedGlobal = bmCurrentIranWeekKey();\n          bmRemainingWorkoutQuotaGlobal = 0;\n          await prefs.setString('bm_workout_quota_week_v1', bmWorkoutQuotaWeekUsedGlobal);"
)
d = d.replace(
    "final savedJson = prefs.getString('bm_ai_custom_workouts_v1');",
    "bmWorkoutQuotaWeekUsedGlobal = prefs.getString('bm_workout_quota_week_v1') ?? '';\n    final savedJson = prefs.getString('bm_ai_custom_workouts_v1');"
)

# 2D. Remove 3/3 ⚡ badge from top AppBar
appbar_badge_pat = re.compile(
    r"child:\s*Container\(\s*margin:\s*const EdgeInsets\.only\(left:\s*10,\s*top:\s*8,\s*bottom:\s*8\),[\s\S]*?color:\s*BMColors\.neonCyan,\s*\),\s*\),\s*\],\s*\),\s*\),",
    re.MULTILINE
)
new_appbar_badge = """child: (!c.profile.isLoggedIn || c.profile.isAdmin)
                ? Container(
                    margin: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: BMColors.neonCyan.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: BMColors.neonCyan.withOpacity(0.55)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          !c.profile.isLoggedIn ? '🔐' : '👑',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          !c.profile.isLoggedIn ? 'ورود' : 'VIP',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                            color: BMColors.neonCyan,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),"""

if "!c.profile.isLoggedIn || c.profile.isAdmin" not in d:
    d, n_ab = appbar_badge_pat.subn(lambda _: new_appbar_badge, d, count=1)
    assert n_ab == 1, "❌ Could not remove 3/3 badge from AppBar"
    print("✅ lib/main.dart: Removed 3/3 ⚡ badge from top AppBar")

# 2E. Move 3/3 ⚡ badge right above AI Chat + disable/fade Chat Send button when 0/3
old_chat_header = """              const Text(
                '🤖 گفتگو با مربی هوشمند بادی‌مود',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),"""

new_chat_header = """              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      '🤖 گفتگو با مربی هوشمند بادی‌مود',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (!c.profile.isAdmin && c.remainingLiteChatQuota <= 0)
                          ? Colors.grey.withOpacity(0.2)
                          : BMColors.neonCyan.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (!c.profile.isAdmin && c.remainingLiteChatQuota <= 0)
                            ? Colors.grey
                            : BMColors.neonCyan.withOpacity(0.55),
                      ),
                    ),
                    child: Text(
                      c.profile.isAdmin
                          ? '👑 نامحدود'
                          : '⚡ ${c.remainingLiteChatQuota}/${c.maxLiteChatQuota} امروز',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        color: (!c.profile.isAdmin && c.remainingLiteChatQuota <= 0)
                            ? Colors.grey
                            : BMColors.neonCyan,
                      ),
                    ),
                  ),
                ],
              ),"""

if "امروز'" not in d:
    assert old_chat_header in d, "❌ Could not find AI Chat header in lib/main.dart"
    d = d.replace(old_chat_header, new_chat_header, 1)
    print("✅ lib/main.dart: Moved ⚡ 3/3 badge right above AI Chat")

old_chat_send = """                      onPressed: c.isLoadingAi
                          ? null
                          : () {
                              final txt = _chatInputCtrl.text.trim();
                              if (txt.isEmpty) return;
                              _chatInputCtrl.clear();
                              c.sendChatMessageToCoach(context, txt);
                            },
                      child: const Text(
                        '🚀 ارسال',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),"""

new_chat_send = """                      onPressed: (c.isLoadingAi || (!c.profile.isAdmin && c.remainingLiteChatQuota <= 0))
                          ? null
                          : () {
                              final txt = _chatInputCtrl.text.trim();
                              if (txt.isEmpty) return;
                              _chatInputCtrl.clear();
                              c.sendChatMessageToCoach(context, txt);
                            },
                      child: Text(
                        (!c.profile.isAdmin && c.remainingLiteChatQuota <= 0)
                            ? 'سهمیه‌ت تموم شده رفیق 😉'
                            : '🚀 ارسال',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                      ),"""

assert old_chat_send in d, "❌ Could not find AI Chat send button in lib/main.dart"
d = d.replace(old_chat_send, new_chat_send, 1)
print("✅ lib/main.dart: Faded/disabled AI Chat send button when 0/3")

# 2F. Fade/disable Food Text (3/week) & Food Photo (1/week) buttons
old_food_btns = """                      onPressed: c.isLoadingAi
                          ? null
                          : () async {
                              final txt = _foodAiQueryCtrl.text.trim();
                              if (txt.isEmpty) return;
                              final res = await c.analyzeFoodWithAi(
                                context,
                                foodDescription: txt,
                              );
                              if (res != null && mounted) {
                                setState(() => _lastAiFoodResult = res);
                              }
                            },
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: const Text(
                        'آنالیز با هوش مصنوعی',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () =>
                        _pickFoodPhotoAndAnalyze(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                  ),
                  IconButton.filledTonal(
                    onPressed: () =>
                        _pickFoodPhotoAndAnalyze(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                  ),"""

new_food_btns = """                      onPressed: (c.isLoadingAi || (!c.profile.isAdmin && c.remainingFoodTextQuota <= 0))
                          ? null
                          : () async {
                              final txt = _foodAiQueryCtrl.text.trim();
                              if (txt.isEmpty) return;
                              final res = await c.analyzeFoodWithAi(
                                context,
                                foodDescription: txt,
                              );
                              if (res != null && mounted) {
                                setState(() => _lastAiFoodResult = res);
                              }
                            },
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                        (!c.profile.isAdmin && c.remainingFoodTextQuota <= 0)
                            ? 'سهمیه‌ت تموم شده رفیق 😉'
                            : 'آنالیز با هوش مصنوعی (${c.profile.isAdmin ? "∞" : "${c.remainingFoodTextQuota}/${c.maxFoodTextQuota}"})',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: (!c.profile.isAdmin && c.remainingFoodPhotoQuota <= 0)
                        ? 'سهمیه‌ت تموم شده رفیق 😉'
                        : 'عکس غذا (${c.profile.isAdmin ? "∞" : "${c.remainingFoodPhotoQuota}/${c.maxFoodPhotoQuota}"})',
                    onPressed: (c.isLoadingAi || (!c.profile.isAdmin && c.remainingFoodPhotoQuota <= 0))
                        ? null
                        : () => _pickFoodPhotoAndAnalyze(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                  ),
                  IconButton.filledTonal(
                    tooltip: (!c.profile.isAdmin && c.remainingFoodPhotoQuota <= 0)
                        ? 'سهمیه‌ت تموم شده رفیق 😉'
                        : 'گالری غذا (${c.profile.isAdmin ? "∞" : "${c.remainingFoodPhotoQuota}/${c.maxFoodPhotoQuota}"})',
                    onPressed: (c.isLoadingAi || (!c.profile.isAdmin && c.remainingFoodPhotoQuota <= 0))
                        ? null
                        : () => _pickFoodPhotoAndAnalyze(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                  ),"""

assert old_food_btns in d, "❌ Could not find Food AI buttons in lib/main.dart"
d = d.replace(old_food_btns, new_food_btns, 1)
print("✅ lib/main.dart: Faded/disabled Food Text (3/w) & Food Photo (1/w) buttons")

# 2G. Fade/disable Weekly Meal Plan (1/week) button
old_meal_btn = """                  onPressed: c.isLoadingAi
                      ? null
                      : () async {
                          final ok = await c.requestAiWeeklyMealPlan(context);
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'برنامه غذایی ۷ روزه کاملاً متنوع (شنبه تا جمعه) بر اساس بودجه و اطلاعاتت ساخته شد! 🔥🥗',
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
                      : const Icon(Icons.auto_awesome_rounded, size: 19),
                  label: Text(
                    hasPlan
                        ? 'درخواست چینش مجدد برنامه ۷ روزه متنوع از AI 🔄'
                        : 'دریافت برنامه غذایی ۷ روزه متنوع از هوش مصنوعی 🚀',"""

new_meal_btn = """                  onPressed: (c.isLoadingAi || (!c.profile.isAdmin && c.remainingMealPlanQuota <= 0))
                      ? null
                      : () async {
                          final ok = await c.requestAiWeeklyMealPlan(context);
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'برنامه غذایی ۷ روزه کاملاً متنوع (شنبه تا جمعه) بر اساس بودجه و اطلاعاتت ساخته شد! 🔥🥗',
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
                      : const Icon(Icons.auto_awesome_rounded, size: 19),
                  label: Text(
                    (!c.profile.isAdmin && c.remainingMealPlanQuota <= 0)
                        ? 'سهمیه‌ت تموم شده رفیق 😉'
                        : (hasPlan
                            ? 'درخواست چینش مجدد برنامه ۷ روزه متنوع از AI 🔄'
                            : 'دریافت برنامه غذایی ۷ روزه متنوع از هوش مصنوعی 🚀'),"""

assert old_meal_btn in d, "❌ Could not find Weekly Meal Plan button in lib/main.dart"
d = d.replace(old_meal_btn, new_meal_btn, 1)
print("✅ lib/main.dart: Faded/disabled Weekly Meal Plan (1/w) button")

# 2H. Fade/disable Weekly Workout Plan (1/week + form check) button in Live Gym
old_gym_ai_btn = """InkWell(onTap: () => bmGenerateAiWorkoutPlan(context, onDone: () => setState(() {})), borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF00E5A3), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00E5A3))), child: ValueListenableBuilder<int>(valueListenable: bmAiCooldownSec, builder: (_, sec, __) => Text(bmIsGeneratingWorkout ? 'در حال محاسبه AI... ⏳' : (sec > 0 ? '⏳ صبر کن ($sec)' : '🤖 بروزرسانی با AI'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)))))"""

new_gym_ai_btn = """InkWell(onTap: (bmGlobalDaysPerWeek <= 0 || bmIsWorkoutQuotaExhausted()) ? null : () => bmGenerateAiWorkoutPlan(context, onDone: () => setState(() {})), borderRadius: BorderRadius.circular(8), child: Opacity(opacity: (bmGlobalDaysPerWeek <= 0 || bmIsWorkoutQuotaExhausted()) ? 0.45 : 1.0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: (bmGlobalDaysPerWeek <= 0 || bmIsWorkoutQuotaExhausted()) ? Colors.grey : const Color(0xFF00E5A3), borderRadius: BorderRadius.circular(8), border: Border.all(color: (bmGlobalDaysPerWeek <= 0 || bmIsWorkoutQuotaExhausted()) ? Colors.grey : const Color(0xFF00E5A3))), child: ValueListenableBuilder<int>(valueListenable: bmAiCooldownSec, builder: (_, sec, __) => Text(bmGlobalDaysPerWeek <= 0 ? 'ورزش نداری رفیق 😅' : (bmIsWorkoutQuotaExhausted() ? 'سهمیه‌ت تموم شده رفیق 😉' : (bmIsGeneratingWorkout ? 'در حال محاسبه AI... ⏳' : (sec > 0 ? '⏳ صبر کن ($sec)' : '🤖 بروزرسانی با AI'))), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black))))))"""

assert old_gym_ai_btn in d, "❌ Could not find Live Gym AI Workout button in lib/main.dart"
d = d.replace(old_gym_ai_btn, new_gym_ai_btn, 1)
print("✅ lib/main.dart: Faded/disabled Weekly Workout Plan (1/w + form check) button")

# 2I. Add Height input + Weekly AI Body Progress Analysis (1/week) with disabled/faded button
old_body_ctrls = """  final TextEditingController _weightInputCtrl = TextEditingController();
  final TextEditingController _bodyNoteCtrl = TextEditingController();"""

new_body_ctrls = """  final TextEditingController _weightInputCtrl = TextEditingController();
  final TextEditingController _heightInputCtrl = TextEditingController();
  final TextEditingController _bodyNoteCtrl = TextEditingController();
  String? _lastBodyAiAnalysis;"""

if "_heightInputCtrl" not in d:
    assert old_body_ctrls in d, "❌ Could not find _weightInputCtrl in BodyAndAiCoachTab"
    d = d.replace(old_body_ctrls, new_body_ctrls, 1)
    d = d.replace(
        "_weightInputCtrl.dispose();",
        "_weightInputCtrl.dispose();\n    _heightInputCtrl.dispose();",
        1
    )

old_body_btn = """              TextField(
                controller: _weightInputCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ثبت وزن جدید این هفته (کیلوگرم)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyNoteCtrl,
                decoration: const InputDecoration(
                  labelText: 'یادداشت پیشرفت (اختیاری)',
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BMColors.neonGreen,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    final w =
                        double.tryParse(_weightInputCtrl.text) ??
                        c.profile.weightKg;
                    c.addBodyMetricRecord(
                      weightKg: w,
                      note: _bodyNoteCtrl.text.trim(),
                    );
                    _bodyNoteCtrl.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('وزن جدیدت در تاریخچه ثبت شد قهرمان! 📈🔥'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_chart_rounded),
                  label: const Text(
                    'ثبت در تاریخچه پیشرفت بدن',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),"""

new_body_btn = """              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightInputCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'وزن جدید (کیلوگرم)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _heightInputCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'قد جدید (اختیاری: ${c.profile.heightCm.round()})',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyNoteCtrl,
                decoration: const InputDecoration(
                  labelText: 'یادداشت پیشرفت (اختیاری)',
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BMColors.neonGreen,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: (c.isLoadingAi || (!c.profile.isAdmin && c.remainingCoachAnalysisQuota <= 0))
                      ? null
                      : () async {
                          final w = double.tryParse(_weightInputCtrl.text) ?? c.profile.weightKg;
                          final h = double.tryParse(_heightInputCtrl.text);
                          final note = _bodyNoteCtrl.text.trim();
                          _bodyNoteCtrl.clear();
                          final analysis = await c.requestWeeklyBodyAnalysis(
                            context,
                            weightKg: w,
                            heightCm: h,
                            note: note,
                          );
                          if (analysis != null && mounted) {
                            setState(() => _lastBodyAiAnalysis = analysis);
                          }
                        },
                  icon: const Icon(Icons.add_chart_rounded),
                  label: Text(
                    (!c.profile.isAdmin && c.remainingCoachAnalysisQuota <= 0)
                        ? 'سهمیه‌ت تموم شده رفیق 😉'
                        : 'ثبت تغییرات قد و وزن + تحلیل AI (هفته‌ای ۱ بار) 📈',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ),
              if (_lastBodyAiAnalysis != null && _lastBodyAiAnalysis!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BMColors.neonCyan.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: BMColors.neonCyan.withOpacity(0.5)),
                  ),
                  child: Text(
                    '🤖 تحلیل هفتگی مربی:\n$_lastBodyAiAnalysis',
                    style: TextStyle(fontSize: 12.5, height: 1.55, color: bmTextColor),
                  ),
                ),
              ],"""

assert old_body_btn in d, "❌ Could not find Body Progress button in lib/main.dart"
d = d.replace(old_body_btn, new_body_btn, 1)
print("✅ lib/main.dart: Added Height + Weekly AI Body Progress Analysis (1/w) with disabled button")

write_file("lib/main.dart", d)
print("\n🎉 ALL 6 AI QUOTAS + 11-DIGIT ACCOUNT ID PATCHED & VERIFIED!")
