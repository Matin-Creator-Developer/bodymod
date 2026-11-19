main_path = "lib/main.dart"
worker_path = "worker.js"
bazaar_yml = ".github/workflows/build-cafebazaar.yml"

def safe_replace(text, old, new, label, fname):
    if old in text:
        print(f"✅ [{fname}] {label}")
        return text.replace(old, new, 1)
    else:
        print(f"⚠️ [{fname}] Skipped (not found or already patched): {label}")
        return text

# ============================================================================
# 1. PATCH build-cafebazaar.yml (Fix flutter_poolakey namespace + jitpack)
# ============================================================================
with open(bazaar_yml, "r", encoding="utf-8") as f:
    b_code = f.read()

old_bazaar_pubget = """        run: |
          flutter pub get
          BUILD_NUM=$((300 + ${{ github.run_number }} * 2))"""

new_bazaar_pubget = """        run: |
          flutter pub get
          python3 - << 'POOLAKEY_FIX_EOF'
          import glob, os, re

          # 1. Add jitpack.io to android/build.gradle(.kts)
          for gfile in ["android/build.gradle.kts", "android/build.gradle"]:
              if os.path.exists(gfile):
                  with open(gfile, "r", encoding="utf-8") as f:
                      g = f.read()
                  if "jitpack.io" not in g:
                      if gfile.endswith(".kts"):
                          g = g.replace("mavenCentral()", 'mavenCentral()\\n        maven { url = uri("https://jitpack.io") }')
                      else:
                          g = g.replace("mavenCentral()", 'mavenCentral()\\n        maven { url "https://jitpack.io" }')
                      with open(gfile, "w", encoding="utf-8") as f:
                          f.write(g)

          # 2. Patch flutter_poolakey plugin build.gradle (add namespace & compileSdk) and AndroidManifest.xml
          pub_cache = os.environ.get("PUB_CACHE", os.path.expanduser("~/.pub-cache"))
          for pdir in glob.glob(os.path.join(pub_cache, "hosted", "*", "flutter_poolakey-*")):
              pgradle = os.path.join(pdir, "android", "build.gradle")
              if os.path.exists(pgradle):
                  with open(pgradle, "r", encoding="utf-8") as f:
                      pg = f.read()
                  if "namespace" not in pg:
                      pg = pg.replace("android {", 'android {\\n    namespace "ir.cafebazaar.flutter_poolakey"', 1)
                  pg = re.sub(r"compileSdkVersion\\s+\\d+", "compileSdkVersion 34", pg)
                  with open(pgradle, "w", encoding="utf-8") as f:
                      f.write(pg)
                  print("Patched Poolakey Gradle:", pgradle)
              pmanifest = os.path.join(pdir, "android", "src", "main", "AndroidManifest.xml")
              if os.path.exists(pmanifest):
                  with open(pmanifest, "r", encoding="utf-8") as f:
                      pm = f.read()
                  pm_new = re.sub(r'\\s+package="[^"]+"', "", pm)
                  if pm_new != pm:
                      with open(pmanifest, "w", encoding="utf-8") as f:
                          f.write(pm_new)
                      print("Patched Poolakey Manifest:", pmanifest)
          POOLAKEY_FIX_EOF
          BUILD_NUM=$((300 + ${{ github.run_number }} * 2))"""

if "POOLAKEY_FIX_EOF" not in b_code:
    b_code = safe_replace(b_code, old_bazaar_pubget, new_bazaar_pubget, "Patch flutter_poolakey AGP8 namespace & jitpack", "build-cafebazaar.yml")
    with open(bazaar_yml, "w", encoding="utf-8") as f:
        f.write(b_code)
else:
    print("ℹ️ [build-cafebazaar.yml] Poolakey fix already present")

# ============================================================================
# 2. PATCH worker.js (Fix Stage-2 lock order + Better Food Prompt + Custom Foods KV)
# ============================================================================
with open(worker_path, "r", encoding="utf-8") as f:
    js = f.read()

old_worker_lock = """        const userKey = getUserKey(user);
        const existingRaw = await kv.get("profile:" + userKey);
        const rawProfile = existingRaw ? JSON.parse(existingRaw) : createDefaultProfile(userKey, user);
        const profile = enrichProfileWithAccessAndLocks(rawProfile, user);
        const lockStatus = buildThreeStageLockStatus(profile);

        // بررسی قفل ۳ مرحله‌ای در سمت سرور کلودفلر!
        if (!lockStatus.aiUnlocked) {
          return jsonResponse(
            {
              error: "AI_LOCKED",
              lockStatus: lockStatus,
              message: lockStatus.lockReasonMessage,
            },
            403
          );
        }

        const body = await request.json();
        if (body.profile && typeof body.profile === "object") {
          Object.assign(profile, body.profile);
        }"""

new_worker_lock = """        const userKey = getUserKey(user);
        const body = await request.json();
        const existingRaw = await kv.get("profile:" + userKey);
        const rawProfile = existingRaw ? JSON.parse(existingRaw) : createDefaultProfile(userKey, user);

        // سینک امن فیلدهای فرم پروفایل از کلاینت قبل از بررسی قفل مرحله ۲
        if (body.profile && typeof body.profile === "object") {
          const safeFields = [
            "name", "gender", "age", "birthYear", "heightCm", "weightKg",
            "targetWeightKg", "goal", "activityLevel", "workoutDaysPerWeek",
            "workoutPlace", "budgetTier", "supplementPref", "aiMemory",
            "preferredModel", "isProfileCompleted"
          ];
          let changed = false;
          for (const k of safeFields) {
            if (body.profile[k] !== undefined && body.profile[k] !== null) {
              if (rawProfile[k] !== body.profile[k]) {
                rawProfile[k] = body.profile[k];
                changed = true;
              }
            }
          }
          if (!rawProfile.isProfileCompleted && (Number(rawProfile.heightCm) > 0 && Number(rawProfile.weightKg) > 0)) {
            rawProfile.isProfileCompleted = true;
            changed = true;
          }
          if (changed) {
            await kv.put("profile:" + userKey, JSON.stringify(rawProfile));
          }
        }

        const profile = enrichProfileWithAccessAndLocks(rawProfile, user);
        const lockStatus = buildThreeStageLockStatus(profile);

        // بررسی قفل ۳ مرحله‌ای در سمت سرور کلودفلر!
        if (!lockStatus.aiUnlocked) {
          return jsonResponse(
            {
              error: "AI_LOCKED",
              lockStatus: lockStatus,
              message: lockStatus.lockReasonMessage,
            },
            403
          );
        }"""

js = safe_replace(js, old_worker_lock, new_worker_lock, "Sync client profile to KV before Stage-2 lock check", "worker.js")

old_cal_prompt = """        } else if (path === "/api/ai/calorie" || body.mode === "calorie_vision") {
          featureType = "chat_daily";
          prompt =
              "کالری و درشت‌مغذی‌های (پروتئین، کربوهیدرات، چربی به گرم) این خوراکی یا تصویر غذا رو دقیق محاسبه کن: " +
              (prompt || "تصویر غذای ارسالی");
        }"""

new_cal_prompt = """        } else if (path === "/api/ai/calorie" || body.mode === "calorie_vision") {
          featureType = "chat_daily";
          prompt =
              "کاربر یک خوراکی یا تصویر غذا فرستاده (حتی اگه فقط اسم ساده یا ترکیبش رو گفته باشه، برای یک وعده استاندارد تخمین دقیق بزن). " +
              "حتماً عنوان دقیق و کوتاه فارسی غذا، کالری (عدد صحیح)، پروتئین، کربوهیدرات، چربی (به گرم) و یک نکته کوتاه مربی رو مشخص کن. " +
              "ورودی کاربر: " + (prompt || "تصویر غذای ارسالی");
        }"""

js = safe_replace(js, old_cal_prompt, new_cal_prompt, "Improve AI food/vision analysis prompt for text & photo", "worker.js")

# اضافه کردن اندپوینت اختصاصی ذخیره و دریافت غذاهای سفارشی کاربر در کلودفلر KV
old_quotas_route = """      if (path === "/api/ai/quotas" && request.method === "GET") {"""

custom_foods_route = """      if (path === "/api/custom-foods" && request.method === "GET") {
        const user = await authenticateRequest(request, env, url);
        if (!user) return jsonResponse({ error: "Unauthorized" }, 401);
        const userKey = getUserKey(user);
        const raw = await kv.get("custom_foods:" + userKey);
        return jsonResponse({ foods: raw ? JSON.parse(raw) : [] });
      }

      if (path === "/api/custom-foods" && request.method === "POST") {
        const user = await authenticateRequest(request, env, url);
        if (!user) return jsonResponse({ error: "Unauthorized" }, 401);
        const userKey = getUserKey(user);
        const body = await request.json();
        const foods = Array.isArray(body.foods) ? body.foods.slice(0, 120) : [];
        await kv.put("custom_foods:" + userKey, JSON.stringify(foods));
        return jsonResponse({ ok: true, count: foods.length });
      }

      if (path === "/api/ai/quotas" && request.method === "GET") {"""

if "/api/custom-foods" not in js:
    js = safe_replace(js, old_quotas_route, custom_foods_route, "Add /api/custom-foods GET/POST endpoints in Cloudflare KV", "worker.js")
else:
    print("ℹ️ [worker.js] /api/custom-foods already present")

with open(worker_path, "w", encoding="utf-8") as f:
    f.write(js)

# ============================================================================
# 3. PATCH lib/main.dart (Food Analyzer Error/Timeout + Offline/Cloud Custom Foods)
# ============================================================================
with open(main_path, "r", encoding="utf-8") as f:
    dart = f.read()

# 3.1 ذخیره و بارگذاری غذاهای سفارشی در SharedPreferences (آفلاین)
if "bm_custom_ai_foods" not in dart:
    dart = safe_replace(
        dart,
        "prefs.getBool('bm_notif_perm_asked_v2') ?? false;",
        """prefs.getBool('bm_notif_perm_asked_v2') ?? false;
      final savedCustomFoods = prefs.getString('bm_custom_ai_foods');
      if (savedCustomFoods != null && savedCustomFoods.isNotEmpty) {
        try {
          final decoded = jsonDecode(savedCustomFoods);
          if (decoded is List) {
            customAiFoods = decoded
                .whereType()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        } catch (_) {}
      }""",
        "Load offline custom AI foods from SharedPreferences",
        "main.dart",
    )
    dart = safe_replace(
        dart,
        "await prefs.setBool('bm_notif_perm_asked_v2', hasRequestedNotificationPerm);",
        """await prefs.setBool('bm_notif_perm_asked_v2', hasRequestedNotificationPerm);
      await prefs.setString('bm_custom_ai_foods', jsonEncode(customAiFoods));""",
        "Save offline custom AI foods to SharedPreferences",
        "main.dart",
    )

# 3.2 تعریف لیست و توابع ذخیره/حذف/سینک غذاهای سفارشی با کلودفلر
if "List> customAiFoods" not in dart:
    custom_food_methods = """  List> customAiFoods = [];

  Future<void> syncCustomAiFoodsToCloud() async {
    if (!isLoggedIn) return;
    try {
      await http
          .post(
            Uri.parse('${AppConfig.serverBaseUrl}/api/custom-foods'),
            headers: _authHeaders,
            body: jsonEncode({'foods': customAiFoods}),
          )
          .timeout(const Duration(seconds: 12));
    } catch (_) {}
  }

  Future<void> fetchCustomAiFoodsFromCloud() async {
    if (!isLoggedIn) return;
    try {
      final res = await http
          .get(
            Uri.parse('${AppConfig.serverBaseUrl}/api/custom-foods'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data is Map && data['foods'] is List) {
          final cloudList = (data['foods'] as List)
              .whereType()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          if (cloudList.isNotEmpty) {
            final existingTitles = customAiFoods
                .map((e) => (e['title'] ?? '').toString().trim())
                .toSet();
            for (final item in cloudList) {
              final t = (item['title'] ?? '').toString().trim();
              if (t.isNotEmpty && !existingTitles.contains(t)) {
                customAiFoods.add(item);
                existingTitles.add(t);
              }
            }
            await saveAllToDisk();
            notifyListeners();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> saveCustomAiFood(Map<String, dynamic> food) async {
    final title = (food['title'] ?? '').toString().trim();
    if (title.isEmpty) return;
    customAiFoods.removeWhere(
      (e) => (e['title'] ?? '').toString().trim() == title,
    );
    customAiFoods.insert(0, {
      'title': title,
      'calories': (food['calories'] as num?)?.toInt() ?? 250,
      'proteinG': (food['proteinG'] as num?)?.toInt() ?? 10,
      'carbsG': (food['carbsG'] as num?)?.toInt() ?? 25,
      'fatG': (food['fatG'] as num?)?.toInt() ?? 8,
      'coachTip': (food['coachTip'] ?? '').toString(),
    });
    if (customAiFoods.length > 100) {
      customAiFoods = customAiFoods.sublist(0, 100);
    }
    await saveAllToDisk();
    notifyListeners();
    unawaited(syncCustomAiFoodsToCloud());
  }

  Future<void> removeCustomAiFood(String title) async {
    customAiFoods.removeWhere(
      (e) => (e['title'] ?? '').toString().trim() == title.trim(),
    );
    await saveAllToDisk();
    notifyListeners();
    unawaited(syncCustomAiFoodsToCloud());
  }

  Future<void> requestAndroidNotificationPermission("""

    dart = safe_replace(
        dart,
        "  Future<void> requestAndroidNotificationPermission(",
        custom_food_methods,
        "Add customAiFoods state & Cloudflare sync helpers",
        "main.dart",
    )

# 3.3 ارتقای تابع analyzeFoodWithAi (تایم‌اوت ۴۵ ثانیه + نمایش خطا + ذخیره خودکار در غذاهای سفارشی)
old_analyze_block = """          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic>) {
          _applyQuotasFromResponse(data['quotas']);
          final calAnalysis = data['calorie_analysis'];
          if (calAnalysis is Map<String, dynamic> &&
              calAnalysis['calories'] != null) {
            isLoadingAi = false;
            notifyListeners();
            return {
              'title': (calAnalysis['title'] ?? foodDescription).toString(),
              'calories': (calAnalysis['calories'] as num?)?.toInt() ?? 280,
              'proteinG': (calAnalysis['proteinG'] as num?)?.toInt() ?? 18,
              'carbsG': (calAnalysis['carbsG'] as num?)?.toInt() ?? 30,
              'fatG': (calAnalysis['fatG'] as num?)?.toInt() ?? 10,
              'coachTip': (calAnalysis['coachTip'] ?? data['reply'] ?? '')
                  .toString(),
            };
          }
          if (data['reply'] != null) {
            isLoadingAi = false;
            notifyListeners();
            return {
              'title': foodDescription.isEmpty
                  ? 'وعده بررسی‌شده با تصویر 📸'
                  : foodDescription,
              'calories': 320,
              'proteinG': 22,
              'carbsG': 34,
              'fatG': 11,
              'coachTip': data['reply'].toString(),
            };
          }
        }
      }
    } catch (_) {}

    isLoadingAi = false;
    notifyListeners();
    return null;"""

new_analyze_block = """          .timeout(const Duration(seconds: 45));

      final rawBody = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        final data = jsonDecode(rawBody);
        if (data is Map<String, dynamic>) {
          _applyQuotasFromResponse(data['quotas']);
          final calAnalysis = data['calorie_analysis'];
          Map<String, dynamic>? parsedResult;
          if (calAnalysis is Map<String, dynamic> &&
              calAnalysis['calories'] != null) {
            parsedResult = {
              'title': (calAnalysis['title'] ?? (foodDescription.isEmpty ? 'وعده بررسی‌شده با تصویر 📸' : foodDescription)).toString(),
              'calories': (calAnalysis['calories'] as num?)?.toInt() ?? 280,
              'proteinG': (calAnalysis['proteinG'] as num?)?.toInt() ?? 18,
              'carbsG': (calAnalysis['carbsG'] as num?)?.toInt() ?? 30,
              'fatG': (calAnalysis['fatG'] as num?)?.toInt() ?? 10,
              'coachTip': (calAnalysis['coachTip'] ?? data['reply'] ?? '')
                  .toString(),
            };
          } else if (data['reply'] != null) {
            final replyStr = data['reply'].toString();
            final calMatch = RegExp(r'(\\d{2,4})\\s*(?:کالری|kcal|کیلوکالری)', caseSensitive: false).firstMatch(replyStr);
            parsedResult = {
              'title': foodDescription.isEmpty
                  ? 'وعده بررسی‌شده با تصویر 📸'
                  : foodDescription,
              'calories': int.tryParse(calMatch?.group(1) ?? '') ?? 300,
              'proteinG': 15,
              'carbsG': 35,
              'fatG': 10,
              'coachTip': replyStr,
            };
          }
          if (parsedResult != null) {
            await saveCustomAiFood(parsedResult);
            isLoadingAi = false;
            notifyListeners();
            return parsedResult;
          }
        }
      } else {
        String errMsg = 'خطا در آنالیز غذا (کد ${response.statusCode}) — دوباره تلاش کن رفیق!';
        try {
          final errData = jsonDecode(rawBody);
          if (errData is Map && (errData['message'] != null || errData['error'] != null)) {
            errMsg = (errData['message'] ?? errData['error']).toString();
          }
        } catch (_) {}
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errMsg)));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('پاسخی از هوش مصنوعی نرسید (احتمالاً اینترنت کند بود) — یه بار دیگه امتحان کن! 🌐'),
          ),
        );
      }
    }

    isLoadingAi = false;
    notifyListeners();
    return null;"""

dart = safe_replace(dart, old_analyze_block, new_analyze_block, "Upgrade analyzeFoodWithAi (45s timeout, auto-save custom food, error SnackBar)", "main.dart")

# 3.4 نمایش بخش «غذاهای سفارشی من (رایگان و آفلاین)» در داشبورد
old_bank_anchor = "        // بانک جامع تمام غذاها، خوراکی‌ها، میوه‌ها، آجیل، نوشیدنی‌ها و دسرها با کوچک‌ترین واحد ممکن!"

custom_foods_ui = """        if (c.customAiFoods.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bmCardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: BMColors.neonCyan.withOpacity(0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🍽️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'غذاهای سفارشی من (رایگان و آفلاین ⚡)',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: BMColors.neonCyan,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'هر غذایی با هوش مصنوعی آنالیز کنی اینجا و روی کلودفلر ذخیره می‌شه؛ دفعات بعد رایگان و حتی بدون اینترنت ثبتش کن!',
                  style: TextStyle(fontSize: 11.5, color: bmTextSubColor),
                ),
                const SizedBox(height: 10),
                ...c.customAiFoods.map((food) {
                  final title = (food['title'] ?? '').toString();
                  final cal = (food['calories'] as num?)?.toInt() ?? 0;
                  final pro = (food['proteinG'] as num?)?.toInt() ?? 0;
                  final carb = (food['carbsG'] as num?)?.toInt() ?? 0;
                  final fat = (food['fatG'] as num?)?.toInt() ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: bmSurfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: bmBorderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$cal کالری | پ: ${pro}g • ک: ${carb}g • چ: ${fat}g',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: bmTextSubColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 19,
                            color: bmTextSubColor,
                          ),
                          onPressed: () => c.removeCustomAiFood(title),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BMColors.neonGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: const Size(0, 34),
                          ),
                          onPressed: () {
                            c.addFoodLog(
                              title: title,
                              calories: cal,
                              proteinG: pro,
                              carbsG: carb,
                              fatG: fat,
                              emoji: '🍽️',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ «$title» ($cal کالری) به صورت رایگان ثبت شد!'),
                              ),
                            );
                          },
                          child: const Text(
                            '➕ خوردم',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // بانک جامع تمام غذاها، خوراکی‌ها، میوه‌ها، آجیل، نوشیدنی‌ها و دسرها با کوچک‌ترین واحد ممکن!"""

if "غذاهای سفارشی من (رایگان و آفلاین" not in dart:
    dart = safe_replace(dart, old_bank_anchor, custom_foods_ui, "Add My Custom Foods (Offline & Free) UI section", "main.dart")

# 3.5 نمایش نکته مربی در باکس نتیجه آنالیز غذا
old_res_title = """                      Text(
                        '✅ ${_lastAiFoodResult!['title']} — ${_lastAiFoodResult!['calories']} کالری',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),"""

new_res_title = """                      Text(
                        '✅ ${_lastAiFoodResult!['title']} — ${_lastAiFoodResult!['calories']} کالری (در غذاهای سفارشی ذخیره شد 💾)',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      if ((_lastAiFoodResult!['coachTip'] ?? '').toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _lastAiFoodResult!['coachTip'].toString(),
                          style: TextStyle(fontSize: 12, color: bmTextSubColor, height: 1.45),
                        ),
                      ],"""

dart = safe_replace(dart, old_res_title, new_res_title, "Show saved badge & coachTip in AI food result card", "main.dart")

# اضافه کردن import dart:async در صورت نبود برای unawaited
if "import 'dart:async';" not in dart:
    dart = "import 'dart:async';\n" + dart
    print("✅ [main.dart] Added import 'dart:async';")

with open(main_path, "w", encoding="utf-8") as f:
    f.write(dart)

print("🚀 همه‌چیز (کافه‌بازار + قفل مرحله ۲ + آنالیز عکس/متن غذا + غذاهای سفارشی کلودفلر/آفلاین) آماده شد!")
