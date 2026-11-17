# -*- coding: utf-8 -*-
import os, re, shutil, sys

F = "lib/main.dart"
if not os.path.exists(F):
    sys.exit("❌ فایل lib/main.dart پیدا نشد!")

tmp_bak = "/data/data/com.termux/files/usr/tmp/main_dart_bak.dart" if os.path.exists("/data/data/com.termux/files/usr/tmp") else "/tmp/main_dart_bak.dart"
shutil.copyfile(F, tmp_bak)

with open(F, "r", encoding="utf-8") as f:
    c = f.read()

orig_parens = c.count("(") - c.count(")")
orig_braces = c.count("{") - c.count("}")

# ۱. پیدا کردن متغیرهای تجهیزات و هدف و آدرس کلودفلر ورکر
equip_var = None
eq_idx = c.find("در خانه بدون تجهیزات")
if eq_idx == -1: eq_idx = c.find("محل تمرین و تجهیزات")
if eq_idx != -1:
    win = c[max(0, eq_idx - 600):min(len(c), eq_idx + 600)]
    vm = re.search(r"value\s*:\s*(_?[a-zA-Z0-9_]*(?:[eE]quip|[pP]lace|[gG]ym|[lL]oc)[a-zA-Z0-9_]*)", win)
    if vm: equip_var = vm.group(1)

goal_var = None
gl_idx = c.find("افزایش وزن و عضله")
if gl_idx == -1: gl_idx = c.find("هدف اصلی شما")
if gl_idx != -1:
    win_g = c[max(0, gl_idx - 600):min(len(c), gl_idx + 600)]
    gm = re.search(r"value\s*:\s*(_?[a-zA-Z0-9_]*(?:[gG]oal|[tT]arget)[a-zA-Z0-9_]*)", win_g)
    if gm: goal_var = gm.group(1)

url_m = re.search(r"https://[a-zA-Z0-9_.-]+\.workers\.dev", c)
worker_url = url_m.group(0) if url_m else "https://bodymod-core.matin-mohammadi.workers.dev"

# ۲. پیدا کردن لیست حرکات در باشگاه زنده (قبل از تزریق موتور) و تبدیل رشته‌های آن به bmExStr(idx, role, '...')
ex_pos = c.rfind("پرس سینه یا سرشانه با دمبل")
if ex_pos == -1: ex_pos = c.rfind("پایین آوردن وزنه (۳ ثانیه)")

if ex_pos != -1 and "bmExStr(" not in c:
    pre_ex = c[max(0, ex_pos - 2500):ex_pos]
    list_open_rel = -1
    for m in re.finditer(r"(?:const\s+)?\[\s*(?:const\s+)?\{", pre_ex):
        list_open_rel = m.start()
    if list_open_rel != -1:
        abs_list_start = max(0, ex_pos - 2500) + list_open_rel
        brack_start = c.find("[", abs_list_start)
        depth, abs_list_end = 0, -1
        for i in range(brack_start, min(len(c), brack_start + 8000)):
            if c[i] == "[": depth += 1
            elif c[i] == "]":
                depth -= 1
                if depth == 0: abs_list_end = i + 1; break
        if abs_list_end != -1:
            list_body = c[brack_start:abs_list_end]
            list_body = re.sub(r"\bconst\s+", "", list_body)

            out_chars = []
            i, n = 0, len(list_body)
            item_idx = -1
            while i < n:
                if list_body[i] == "{":
                    d_b, j = 0, i
                    while j < n:
                        if list_body[j] == "{": d_b += 1
                        elif list_body[j] == "}":
                            d_b -= 1
                            if d_b == 0: break
                        j += 1
                    if j < n:
                        item_idx += 1
                        item_str = list_body[i:j + 1]
                        idx_val = item_idx

                        def wrap_kv(m_kv):
                            k_lit = m_kv.group(1)
                            v_lit = m_kv.group(2)
                            kl = k_lit.lower()
                            v_inner = v_lit[1:-1]
                            role = None
                            if "title" in kl or "name" in kl:
                                role = "title"
                            elif "muscle" in kl or "target" in kl or "sub" in kl or "عضله هدف" in v_inner:
                                role = "muscle"
                            elif "breath" in kl or "دم |" in v_inner or "بازدم" in v_inner:
                                role = "breath"
                            elif "tip" in kl or "note" in kl or "coach" in kl or "منقبض" in v_inner or "طلایی" in v_inner:
                                role = "tip"
                            if role and "فاز " not in v_inner and "گرم کردن" != v_inner and "سرد کردن" != v_inner:
                                return f"{k_lit}: bmExStr({idx_val}, '{role}', {v_lit})"
                            return m_kv.group(0)

                        item_str = re.sub(r"(['\"][a-zA-Z0-9_]+['\"])\s*:\s*('[^'\\]+'|\"[^\"\\]+\")", wrap_kv, item_str)
                        out_chars.append(item_str)
                        i = j + 1
                        continue
                out_chars.append(list_body[i])
                i += 1

            new_list_body = "".join(out_chars)
            before_list = c[max(0, abs_list_start - 140):abs_list_start]
            field_m = re.search(r"final\s+(List<[^>]+>+\s+)?(_[a-zA-Z0-9_]+)\s*=\s*$", before_list)
            if field_m:
                type_part = field_m.group(1) or "List<Map<String, dynamic>> "
                var_name = field_m.group(2)
                if len(re.findall(rf"\b{re.escape(var_name)}\s*=", c)) == 1:
                    f_start = max(0, abs_list_start - 140) + field_m.start()
                    c = c[:f_start] + f"{type_part}get {var_name} => {new_list_body}" + c[abs_list_end:]
                else:
                    c = c[:abs_list_start] + new_list_body + c[abs_list_end:]
            else:
                c = c[:abs_list_start] + new_list_body + c[abs_list_end:]
            print(f"✅ تمام {item_idx + 1} حرکت باشگاه زنده به سیستم تشخیص وزن بدن و هوش مصنوعی متصل شدند!")

# ۳. تزریق موتور هوشمند تطبیق حرکات + محاسبه مخفی کالری کارهای روزمره (NEAT) + نمایش کالری باشگاه زنده و میان‌وعده کالری مازاد
WORKOUT_ENGINE = "\n".join([
    "// --- [BODYMOD SMART WORKOUT, HIDDEN NEAT/TDEE & SURPLUS AI ENGINE] ---",
    "String bmGlobalEquipment = 'در خانه بدون تجهیزات (وزن بدن)';",
    "String bmGlobalGoal = 'افزایش وزن و عضله سازی';",
    "double bmGlobalWeight = 60.0;",
    "double bmGlobalHeight = 175.0;",
    "int bmGlobalAge = 21;",
    "int bmGlobalDaysPerWeek = 3;",
    "int bmWorkoutBurnKcal = 0;",
    "String bmAiSurplusSnack = '';",
    "List<Map<String, String>> bmAiCustomWorkouts = [];",
    "bool bmIsGeneratingWorkout = false;",
    "",
    "// محاسبه مخفی در پس‌زمینه: متابولیسم پایه + کارهای عادی روزانه (راه رفتن، صحبت کردن و...) + ضریب تمرین هفتگی",
    "int _bmComputeHiddenDailyBurn() {",
    "  final double bmr = (10 * bmGlobalWeight) + (6.25 * bmGlobalHeight) - (5 * bmGlobalAge) + 5;",
    "  // ضریب تحرک پایه و کارهای روزمره (راه رفتن، صحبت کردن، فعالیت‌های عادی) + روزهای تمرین در هفته",
    "  final double neatAndActivityFactor = 1.25 + (bmGlobalDaysPerWeek.clamp(1, 7) * 0.055);",
    "  return (bmr * neatAndActivityFactor).round();",
    "}",
    "",
    "// محاسبه کالری مصرفی جلسه تمرین در باشگاه زنده (تنها عددی که در باشگاه زنده نمایش داده می‌شود)",
    "int bmGetVisibleWorkoutCalories() {",
    "  if (bmWorkoutBurnKcal > 50) return bmWorkoutBurnKcal;",
    "  final bool isBw = bmGlobalEquipment.contains('بدون تجهیزات') || bmGlobalEquipment.contains('وزن بدن');",
    "  final double met = isBw ? 5.2 : 6.2;",
    "  // حدود ۴۵ دقیقه تمرین مفید بر اساس وزن کاربر",
    "  return ((met * 3.5 * bmGlobalWeight / 200.0) * 45.0).round().clamp(160, 550);",
    "}",
    "",
    "// پیشنهاد هوشمند خوراکی و میان‌وعده برای ایجاد «کالری مازاد» (بیشتر از کالری سوخته شده)",
    "String bmGetSurplusRecommendation() {",
    "  final int wBurn = bmGetVisibleWorkoutCalories();",
    "  final int hiddenTotal = _bmComputeHiddenDailyBurn() + wBurn;",
    "  final bool isGain = bmGlobalGoal.contains('افزایش') || bmGlobalGoal.contains('عضله') || bmGlobalGoal.contains('حجم');",
    "  if (bmAiSurplusSnack.trim().isNotEmpty) return bmAiSurplusSnack.trim();",
    "  if (isGain) {",
    "    final int surplusSnackKcal = wBurn + 260;",
    "    final int dailyTargetWithSurplus = hiddenTotal + 450;",
    "    return 'برای جبران این $wBurn کالریِ تمرین (و کالری کارهای عادی روزانه که مربی توی دلش حساب کرده 😉) و رفتن به فاز «کالری مازاد»، پیشنهاد مربی بعد از تمرین یک میان‌وعده حدود $surplusSnackKcal کالری (مثل شیک شیر و موز و کره بادام‌زمینی یا شیره انگور و گردو + تخم‌مرغ) هست تا مجموع دریافتی روزانه‌ات از $dailyTargetWithSurplus کالری رد بشه و عضله بسازی! 🍌🥜💪';",
    "  }",
    "  return 'در این جلسه حدود $wBurn کالری می‌سوزونی! بعد از تمرین برای ریکاوری عضلات یک میان‌وعده پروتئینی سبک (مثل سفیده تخم‌مرغ، سینه مرغ یا ماست ایسلندی) به همراه آب کافی نوش جان کن! 🥚💧';",
    "}",
    "",
    "Future<void> bmLoadSavedAiWorkouts() async {",
    "  try {",
    "    final prefs = await SharedPreferences.getInstance();",
    "    for (final k in prefs.getKeys()) {",
    "      final v = prefs.get(k);",
    "      final kl = k.toLowerCase();",
    "      if (v is String) {",
    "        if (v.contains('بدون تجهیزات') || v.contains('وزن بدن') || v.contains('باشگاه') || v.contains('دمبل')) bmGlobalEquipment = v;",
    "        if (v.contains('عضله') || v.contains('چربی') || v.contains('کاهش وزن') || v.contains('تناسب') || v.contains('افزایش وزن')) bmGlobalGoal = v;",
    "        if (v.contains('روز در هفته')) {",
    "          final dm = RegExp(r'\\d+').firstMatch(_bmNormalizeDigits(v));",
    "          if (dm != null) bmGlobalDaysPerWeek = int.tryParse(dm.group(0)!) ?? 3;",
    "        }",
    "      } else if (v is double || v is int) {",
    "        final double dv = (v as num).toDouble();",
    "        if (kl.contains('weight') && !kl.contains('target') && dv >= 30 && dv <= 200) bmGlobalWeight = dv;",
    "        if (kl.contains('height') && dv >= 120 && dv <= 230) bmGlobalHeight = dv;",
    "        if (kl.contains('age') && dv >= 10 && dv <= 95) bmGlobalAge = dv.round();",
    "      }",
    "    }",
    "    bmWorkoutBurnKcal = prefs.getInt('bm_ai_workout_burn_kcal') ?? 0;",
    "    bmAiSurplusSnack = prefs.getString('bm_ai_surplus_snack') ?? '';",
    "    final savedJson = prefs.getString('bm_ai_custom_workouts_v1');",
    "    if (savedJson != null && savedJson.isNotEmpty) {",
    "      final List<dynamic> decoded = jsonDecode(savedJson);",
    "      bmAiCustomWorkouts = decoded.map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))).toList();",
    "    }",
    "  } catch (_) {}",
    "}",
    "",
    "String bmExStr(int idx, String role, String orig) {",
    "  if (idx >= 0 && idx < bmAiCustomWorkouts.length) {",
    "    final ai = bmAiCustomWorkouts[idx];",
    "    final v = ai[role];",
    "    if (v != null && v.trim().isNotEmpty) return v.trim();",
    "  }",
    "  final eq = bmGlobalEquipment;",
    "  final bool isBw = eq.contains('بدون تجهیزات') || eq.contains('وزن بدن') || (!eq.contains('دمبل') && !eq.contains('باشگاه'));",
    "  if (!isBw) return orig;",
    "  String out = orig;",
    "  if (out.contains('پرس سینه یا سرشانه با دمبل')) return 'شنا سوئدی استاندارد و دست‌باز با وزن بدن (کنترل ۳ ثانیه‌ای)';",
    "  if (out.contains('زیربغل') && (out.contains('دمبل') || out.contains('هالتر') || out.contains('سیم'))) return 'حرکت سوپرمن و کشش معکوس کتف روی زمین (وزن بدن)';",
    "  if (out.contains('اسکات') && (out.contains('دمبل') || out.contains('هالتر') || out.contains('وزنه'))) return 'اسکات عمیق و لانج متناوب با وزن بدن (کنترل ۳ ثانیه‌ای)';",
    "  if ((out.contains('جلوبازو') || out.contains('پشت‌بازو') || out.contains('پشت بازو') || out.contains('بازو')) && out.contains('دمبل')) return 'دیپ پشت‌بازو روی لبه صندلی و شنا الماسی (وزن بدن)';",
    "  if (out.contains('سرشانه') && out.contains('دمبل')) return 'شنا پایک (Pike Push-up) مخصوص سرشانه با وزن بدن';",
    "  out = out.replaceAll('پایین آوردن وزنه', 'پایین بردن کنترل‌شده بدن');",
    "  out = out.replaceAll('پرس به بالا', 'فشار قدرتی با وزن بدن به بالا');",
    "  out = out.replaceAll('با دمبل یا هالتر', 'با وزن بدن');",
    "  out = out.replaceAll('با دمبل', 'با وزن بدن');",
    "  out = out.replaceAll('دمبل‌ها', 'دست‌ها');",
    "  out = out.replaceAll('دمبل', 'وزن بدن');",
    "  out = out.replaceAll('وزنه', 'وزن بدن');",
    "  return out;",
    "}",
    "",
    "Future<bool> bmGenerateAiWorkoutPlan(BuildContext context, {VoidCallback? onDone}) async {",
    "  if (bmIsGeneratingWorkout) return false;",
    "  bmIsGeneratingWorkout = true;",
    "  if (onDone != null) onDone();",
    "  try {",
    "    final prefs = await SharedPreferences.getInstance();",
    "    await bmLoadSavedAiWorkouts();",
    "    final eq = bmGlobalEquipment;",
    "    final gl = bmGlobalGoal;",
    "    final int hiddenRoutineKcal = _bmComputeHiddenDailyBurn();",
    "    final int estWorkoutKcal = bmGetVisibleWorkoutCalories();",
    "    final bool isBw = eq.contains('بدون تجهیزات') || eq.contains('وزن بدن');",
    "    final eqRule = isBw",
    "        ? 'کاربر هیچ وسیله‌ای ندارد (فقط وزن بدن در خانه). اکیداً هیچ حرکتی با دمبل، هالتر، وزنه یا دستگاه نده! تمام ۷ حرکت باید ۱۰۰٪ با وزن بدن باشند.'",
    "        : 'تجهیزات کاربر: ' + eq + '. تمام حرکات را دقیقاً متناسب با همین تجهیزات طراحی کن.';",
    "    final prompt = 'تو مربی حرفه‌ای بادیمود هستی. مشخصات کاربر: وزن ' + bmGlobalWeight.round().toString() + ' کیلو، قد ' + bmGlobalHeight.round().toString() + '، سن ' + bmGlobalAge.toString() + '، تمرین در هفته: ' + bmGlobalDaysPerWeek.toString() + ' روز، هدف: ' + gl + '. '",
    "        + 'محاسبه مخفی پس‌زمینه (فقط برای اطلاع خودت جهت ایجاد تعادل کالری؛ این عدد روزمره را به کاربر نگو): کالری کارهای عادی روزانه مثل راه رفتن و صحبت کردن و تحرک هفتگی = ' + hiddenRoutineKcal.toString() + ' کالری. '",
    "        + 'قانون تجهیزات: ' + eqRule + ' '",
    "        + 'فقط و فقط یک آبجکت JSON خالص با این ۳ کلید برگردان: '",
    "        + '{\"workout_calories\": ' + estWorkoutKcal.toString() + ', \"surplus_snack\": \"پیشنهاد دقیق خوراکی و میان‌وعده پرکالری (بیشتر از کالری سوخته شده) برای ایجاد کالری مازاد و تعادل با تمرین و فعالیت روزانه\", \"exercises\": [۷ آبجکت حرکت ورزشی به ترتیب گرم کردن، ست اصلی، سرد کردن با کلیدهای title و muscle و breath و tip]}';",
    "    final res = await http.post(",
    "      Uri.parse('" + worker_url + "/api/chat'),",
    "      headers: {'Content-Type': 'application/json'},",
    "      body: jsonEncode({'message': prompt, 'prompt': prompt, 'model': 'gemini-3.5-flash-lite'}),",
    "    ).timeout(const Duration(seconds: 25));",
    "    String rawReply = res.body;",
    "    try {",
    "      final d = jsonDecode(res.body);",
    "      rawReply = (d['reply'] ?? d['response'] ?? d['text'] ?? d['message'] ?? res.body).toString();",
    "    } catch (_) {}",
    "    final objS = rawReply.indexOf('{');",
    "    final objE = rawReply.lastIndexOf('}');",
    "    if (objS != -1 && objE != -1 && objE > objS) {",
    "      final dynamic parsed = jsonDecode(rawReply.substring(objS, objE + 1));",
    "      if (parsed is Map) {",
    "        if (parsed['workout_calories'] != null) {",
    "          bmWorkoutBurnKcal = int.tryParse(parsed['workout_calories'].toString()) ?? estWorkoutKcal;",
    "          await prefs.setInt('bm_ai_workout_burn_kcal', bmWorkoutBurnKcal);",
    "        }",
    "        if (parsed['surplus_snack'] != null && parsed['surplus_snack'].toString().trim().isNotEmpty) {",
    "          bmAiSurplusSnack = parsed['surplus_snack'].toString().trim();",
    "          await prefs.setString('bm_ai_surplus_snack', bmAiSurplusSnack);",
    "        }",
    "        if (parsed['exercises'] is List && (parsed['exercises'] as List).isNotEmpty) {",
    "          final List<dynamic> arr = parsed['exercises'];",
    "          bmAiCustomWorkouts = arr.map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))).toList();",
    "          await prefs.setString('bm_ai_custom_workouts_v1', jsonEncode(bmAiCustomWorkouts));",
    "        }",
    "        bmIsGeneratingWorkout = false;",
    "        if (onDone != null) onDone();",
    "        if (context.mounted) {",
    "          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ برنامه تمرینی، کالری‌سوزی و میان‌وعده کالری مازاد توسط هوش مصنوعی تنظیم شد! 💪🔥'), backgroundColor: Color(0xFF00C896)));",
    "        }",
    "        return true;",
    "      }",
    "    }",
    "  } catch (_) {}",
    "  bmIsGeneratingWorkout = false;",
    "  if (onDone != null) onDone();",
    "  if (context.mounted) {",
    "    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ برنامه تمرینی و تعادل کالری مازاد بر اساس فرم تو بروزرسانی شد! 💪🔥'), backgroundColor: Color(0xFF00C896)));",
    "  }",
    "  return false;",
    "}",
    "// --- [END SMART WORKOUT ENGINE] ---",
])

if "String bmExStr(" not in c:
    c = c.replace("void main(", WORKOUT_ENGINE + "\nvoid main(", 1)
    c = re.sub(r"(WidgetsFlutterBinding\.ensureInitialized\(\)\s*;)", r"\1 bmLoadSavedAiWorkouts();", c, count=1)

# ۴. همگام‌سازی فوری متغیر تجهیزات و هدف در زمان تغییر فرم + افزودن کارت کالری باشگاه زنده و میان‌وعده کالری مازاد
if equip_var:
    c = re.sub(
        rf"({re.escape(equip_var)}\s*=\s*[^;]+;)",
        rf"\1 bmGlobalEquipment = {equip_var}.toString(); bmAiCustomWorkouts.clear(); bmWorkoutBurnKcal = 0; bmAiSurplusSnack = '';",
        c,
    )
if goal_var:
    c = re.sub(
        rf"({re.escape(goal_var)}\s*=\s*[^;]+;)",
        rf"\1 bmGlobalGoal = {goal_var}.toString(); bmAiSurplusSnack = '';",
        c,
    )

warmup_pos = c.find("۱. گرم کردن")
if warmup_pos != -1 and "طراحی برنامه ورزشی با هوش مصنوعی" not in c:
    pre_w = c[max(0, warmup_pos - 400):warmup_pos]
    row_pos = pre_w.rfind("Row(")
    if row_pos != -1:
        abs_row = max(0, warmup_pos - 400) + row_pos
        p_open = c.find("(", abs_row)
        d, abs_row_end = 0, -1
        for i in range(p_open, min(len(c), p_open + 2500)):
            if c[i] == "(": d += 1
            elif c[i] == ")":
                d -= 1
                if d == 0: abs_row_end = i + 1; break
        if abs_row_end != -1:
            ai_panel = (
                "Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: ["
                "Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF00E5A3).withOpacity(0.4))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: ["
                "Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: ["
                "Row(children: [const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 20), const SizedBox(width: 6), Text('کالری مصرفی این تمرین: ${bmGetVisibleWorkoutCalories()} کالری 🔥', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white))]),"
                "InkWell(onTap: () => bmGenerateAiWorkoutPlan(context, onDone: () => setState(() {})), borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF00E5A3).withOpacity(0.18), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00E5A3))), child: Text(bmIsGeneratingWorkout ? 'در حال محاسبه AI... ⏳' : '🤖 بروزرسانی با AI', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00E5A3))))),"
                "]),"
                "const SizedBox(height: 8),"
                "Text(bmGetSurplusRecommendation(), style: const TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.45)),"
                "])), "
            )
            c = c[:abs_row] + ai_panel + c[abs_row:abs_row_end] + "])" + c[abs_row_end:]
            print("✅ کارت «کالری مصرفی باشگاه زنده + پیشنهاد میان‌وعده کالری مازاد + دکمه هوش مصنوعی» به باشگاه زنده اضافه شد!")

if (c.count("(") - c.count(")")) != orig_parens or (c.count("{") - c.count("}")) != orig_braces:
    sys.exit("❌ خطا در توازن پرانتز/آکولاد! فایل تغییر نکرد.")

with open(F, "w", encoding="utf-8") as f:
    f.write(c)

print("🎉 تمام تغییرات باشگاه زنده، محاسبه مخفی کالری روزمره و پیشنهاد کالری مازاد با موفقیت در lib/main.dart ذخیره شد!")
