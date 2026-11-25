import os

DART_PATH = "lib/main.dart"
WORKER_PATH = "worker.js"

def patch_file(path, patches):
    if not os.path.exists(path):
        print(f"❌ فایل پیدا نشد: {path}")
        return False
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    ok_count = 0
    for name, old, new in patches:
        if old in content:
            content = content.replace(old, new, 1)
            print(f"✅ [{path}] {name}")
            ok_count += 1
        elif new in content:
            print(f"ℹ️ [{path}] قبلاً اعمال شده بود: {name}")
            ok_count += 1
        else:
            print(f"⚠️ [{path}] الگو پیدا نشد: {name}")

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"📦 نتیجه {path}: {ok_count}/{len(patches)} پچ اعمال شد.\n")
    return ok_count == len(patches)

# ==============================================================================
# 1. پچ‌های فایل lib/main.dart
# ==============================================================================
dart_patches = [
    (
        "افزودن متغیرهای برنامه ورزشی ۷ روزه و عضلات هدف",
        "String bmAiSurplusSnack = '';\nList> bmAiCustomWorkouts = [];\nbool bmIsGeneratingWorkout = false;",
        "String bmAiSurplusSnack = '';\nList> bmAiCustomWorkouts = [];\nList<String> bmGlobalTargetMuscles = ['کل بدن'];\nconst List<String> bmTargetMuscleOptions = ['کل بدن', 'سینه', 'شکم', 'بازو', 'پشت و سرشانه', 'ران و باسن'];\nconst List<String> bmWorkoutWeekDays = ['شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'];\nMap<String, Map<String, dynamic>> bmAiWeeklyWorkouts = {};\nint bmSelectedWorkoutDayIdx = 0;\nbool bmIsGeneratingWorkout = false;"
    ),
    (
        "بارگذاری برنامه ورزشی ۷ روزه و عضلات هدف از حافظه",
        """    final savedJson = prefs.getString('bm_ai_custom_workouts_v1');
    if (savedJson != null && savedJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(savedJson);
      bmAiCustomWorkouts = decoded.map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))).toList();
    }""",
        """    final savedMuscles = prefs.getStringList('bm_target_muscles_v1');
    if (savedMuscles != null && savedMuscles.isNotEmpty) {
      bmGlobalTargetMuscles = List<String>.from(savedMuscles);
    }
    final savedWeeklyJson = prefs.getString('bm_ai_weekly_workouts_v1');
    if (savedWeeklyJson != null && savedWeeklyJson.isNotEmpty) {
      final Map<String, dynamic> wDecoded = jsonDecode(savedWeeklyJson);
      bmAiWeeklyWorkouts = wDecoded.map((k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)));
      for (int i = 0; i < bmWorkoutWeekDays.length; i++) {
        final dObj = bmAiWeeklyWorkouts[bmWorkoutWeekDays[i]];
        if (dObj != null && dObj['is_rest'] != true && dObj['exercises'] is List && (dObj['exercises'] as List).isNotEmpty) {
          bmSelectedWorkoutDayIdx = i;
          bmAiCustomWorkouts = (dObj['exercises'] as List).map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))).toList();
          break;
        }
      }
    }
    final savedJson = prefs.getString('bm_ai_custom_workouts_v1');
    if (bmAiCustomWorkouts.isEmpty && savedJson != null && savedJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(savedJson);
      bmAiCustomWorkouts = decoded.map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))).toList();
    }"""
    ),
    (
        "آپدیت پرامپت هوش مصنوعی ورزش به برنامه ۷ روزه علمی + عضلات هدف",
        """    final prompt = 'تو مربی حرفه‌ای بادی‌مود هستی. مشخصات کاربر: وزن ' + bmGlobalWeight.round().toString() + ' کیلو، قد ' + bmGlobalHeight.round().toString() + '، سن ' + bmGlobalAge.toString() + '، تمرین در هفته: ' + bmGlobalDaysPerWeek.toString() + ' روز، هدف: ' + gl + '.' + varietyRule
        + 'محاسبه مخفی پس‌زمینه (فقط برای اطلاع خودت جهت ایجاد تعادل کالری؛ این عدد روزمره را به کاربر نگو): کالری کارهای عادی روزانه مثل راه رفتن و صحبت کردن و تحرک هفتگی = ' + hiddenRoutineKcal.toString() + ' کالری. '
        + 'قانون تجهیزات: ' + eqRule + ' '
        + 'فقط و فقط یک آبجکت JSON خالص با این ۳ کلید برگردان: '
        + '{"workout_calories": ' + estWorkoutKcal.toString() + ', "surplus_snack": "پیشنهاد دقیق خوراکی و میان‌وعده پرکالری (بیشتر از کالری سوخته شده) برای ایجاد کالری مازاد و تعادل با تمرین و فعالیت روزانه", "exercises": [۷ آبجکت حرکت ورزشی به ترتیب گرم کردن، ست اصلی، سرد کردن با کلیدهای title و muscle و breath و tip]}';
    final reqHeaders = <String, String>{'Content-Type': 'application/json'};
    if (authHeaders != null) reqHeaders.addAll(authHeaders);
    final res = await http.post(
      Uri.parse('${AppConfig.serverBaseUrl}/api/ai/workout-plan'),
      headers: reqHeaders,
      body: jsonEncode({'message': prompt, 'prompt': prompt, 'mode': 'workout_plan', 'model': 'gemini-3.1-flash-lite'}),
    ).timeout(const Duration(seconds: 30));""",
        """    final musclesStr = bmGlobalTargetMuscles.isEmpty ? 'کل بدن' : bmGlobalTargetMuscles.join('، ');
    final splitRule = bmGlobalDaysPerWeek <= 2
        ? 'چون کاربر فقط ' + bmGlobalDaysPerWeek.toString() + ' روز در هفته تمرین می‌کنه، در روزهای تمرینی برنامه کل بدن (Full Body) بده و بقیه روزهای هفته رو is_rest: true بذار.'
        : 'چون کاربر ' + bmGlobalDaysPerWeek.toString() + ' روز در هفته تمرین می‌کنه، برنامه ۷ روزه علمی با تفکیک عضلات مرتبط بچین (مثلاً بالاتنه/پایین‌تنه یا Push/Pull/Legs) طوری که عضله‌ای که دیروز تمرین کرده، فرداش حتماً استراحت کنه و دو روز پشت سر هم یک عضله تمرین داده نشه! دقیقاً ' + bmGlobalDaysPerWeek.toString() + ' روز تمرینی (is_rest: false) و بقیه روزها استراحت (is_rest: true) باشه.';
    final prompt = 'تو مربی حرفه‌ای بادی‌مود هستی. مشخصات کاربر: وزن ' + bmGlobalWeight.round().toString() + ' کیلو، قد ' + bmGlobalHeight.round().toString() + '، سن ' + bmGlobalAge.toString() + '، تمرین در هفته: ' + bmGlobalDaysPerWeek.toString() + ' روز، هدف: ' + gl + '، عضلات و نواحی هدف کاربر: ' + musclesStr + '.' + varietyRule
        + 'قانون علمی تقسیم روزهای هفته: ' + splitRule + ' '
        + 'محاسبه مخفی پس‌زمینه (فقط برای اطلاع خودت جهت ایجاد تعادل کالری؛ این عدد روزمره را به کاربر نگو): کالری کارهای عادی روزانه مثل راه رفتن و صحبت کردن و تحرک هفتگی = ' + hiddenRoutineKcal.toString() + ' کالری. '
        + 'قانون تجهیزات: ' + eqRule + ' '
        + 'فقط و فقط یک آبجکت JSON خالص با این ۳ کلید برگردان: '
        + '{"workout_calories": ' + estWorkoutKcal.toString() + ', "surplus_snack": "پیشنهاد دقیق خوراکی و میان‌وعده برای ایجاد کالری مازاد یا ریکاوری", "weekly_plan": {"شنبه": {"is_rest": false, "focus": "عنوان عضله هدف این روز", "exercises": [۷ آبجکت حرکت به ترتیب گرم کردن، ست اصلی، سرد کردن با کلیدهای title و muscle و breath و tip]}, "یکشنبه": ..., "دوشنبه": ..., "سه‌شنبه": ..., "چهارشنبه": ..., "پنجشنبه": ..., "جمعه": ...}} (برای روزهای استراحت is_rest را true و exercises را [] بگذار).';
    final reqHeaders = <String, String>{'Content-Type': 'application/json'};
    if (authHeaders != null) reqHeaders.addAll(authHeaders);
    final res = await http.post(
      Uri.parse('${AppConfig.serverBaseUrl}/api/ai/workout-plan'),
      headers: reqHeaders,
      body: jsonEncode({'message': prompt, 'prompt': prompt, 'mode': 'workout_plan', 'model': 'gemini-3.1-flash-lite'}),
    ).timeout(const Duration(seconds: 45));"""
    ),
    (
        "پارس کردن و ذخیره برنامه ورزشی ۷ روزه در کلاینت",
        """        if (parsed['exercises'] is List && (parsed['exercises'] as List).isNotEmpty) {
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
        }""",
        """        bool savedAnyWorkout = false;
        if (parsed['weekly_plan'] is Map && (parsed['weekly_plan'] as Map).isNotEmpty) {
          final Map<String, dynamic> wp = Map<String, dynamic>.from(parsed['weekly_plan'] as Map);
          bmAiWeeklyWorkouts = {};
          for (final d in bmWorkoutWeekDays) {
            if (wp[d] is Map) {
              bmAiWeeklyWorkouts[d] = Map<String, dynamic>.from(wp[d] as Map);
            }
          }
          if (bmAiWeeklyWorkouts.isNotEmpty) {
            await prefs.setString('bm_ai_weekly_workouts_v1', jsonEncode(bmAiWeeklyWorkouts));
            for (int i = 0; i < bmWorkoutWeekDays.length; i++) {
              final dObj = bmAiWeeklyWorkouts[bmWorkoutWeekDays[i]];
              if (dObj != null && dObj['is_rest'] != true && dObj['exercises'] is List && (dObj['exercises'] as List).isNotEmpty) {
                bmSelectedWorkoutDayIdx = i;
                bmAiCustomWorkouts = (dObj['exercises'] as List).map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))).toList();
                await prefs.setString('bm_ai_custom_workouts_v1', jsonEncode(bmAiCustomWorkouts));
                break;
              }
            }
            savedAnyWorkout = true;
          }
        }
        if (!savedAnyWorkout && parsed['exercises'] is List && (parsed['exercises'] as List).isNotEmpty) {
          final List<dynamic> arr = parsed['exercises'];
          bmAiCustomWorkouts = arr.map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))).toList();
          await prefs.setString('bm_ai_custom_workouts_v1', jsonEncode(bmAiCustomWorkouts));
          savedAnyWorkout = true;
        }
        if (savedAnyWorkout) {
          bmWorkoutQuotaWeekUsedGlobal = bmCurrentIranWeekKey();
          bmRemainingWorkoutQuotaGlobal = 0;
          await prefs.setString('bm_workout_quota_week_v1', bmWorkoutQuotaWeekUsedGlobal);
          bmIsGeneratingWorkout = false;
          if (onDone != null) onDone();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ برنامه تمرینی ۷ روزه علمی، کالری‌سوزی و میان‌وعده توسط هوش مصنوعی تنظیم شد! 💪🔥'), backgroundColor: Color(0xFF00C896)));
          }
          return true;
        }"""
    ),
    (
        "افزودن فیلد targetMuscles به UserProfileModel",
        "  String workoutPlace; // 'home_dumbbell', 'gym', 'bodyweight'",
        "  String workoutPlace; // 'home_dumbbell', 'gym', 'bodyweight'\n  List<String> targetMuscles;"
    ),
    (
        "افزودن targetMuscles به سازنده UserProfileModel",
        "    this.workoutPlace = 'home_dumbbell',",
        "    this.workoutPlace = 'home_dumbbell',\n    this.targetMuscles = const ['کل بدن'],"
    ),
    (
        "افزودن targetMuscles به toJson",
        "    'workoutPlace': workoutPlace,",
        "    'workoutPlace': workoutPlace,\n    'targetMuscles': targetMuscles,"
    ),
    (
        "افزودن targetMuscles به fromJson",
        "      workoutPlace: (json['workoutPlace'] ?? 'home_dumbbell').toString(),",
        "      workoutPlace: (json['workoutPlace'] ?? 'home_dumbbell').toString(),\n      targetMuscles: (json['targetMuscles'] is List && (json['targetMuscles'] as List).isNotEmpty)\n          ? (json['targetMuscles'] as List).map((e) => e.toString()).toList()\n          : const ['کل بدن'],"
    ),
    (
        "بازیابی برنامه ورزشی ۷ روزه و عضلات هدف از سرور در _applyServerAuthData",
        """    final srvWp = serverProfile['workoutPlan'];
    if (srvWp is Map && srvWp['exercises'] is List && (srvWp['exercises'] as List).isNotEmpty) {
      bmAiCustomWorkouts = (srvWp['exercises'] as List)
          .whereType()
          .map((e) => Map<String, String>.from(e.map((k, v) => MapEntry(k.toString(), v.toString()))))
          .toList();
      if (srvWp['workout_calories'] != null) {
        bmWorkoutBurnKcal = int.tryParse(srvWp['workout_calories'].toString()) ?? bmWorkoutBurnKcal;
      }
      if (srvWp['surplus_snack'] != null && srvWp['surplus_snack'].toString().trim().isNotEmpty) {
        bmAiSurplusSnack = srvWp['surplus_snack'].toString().trim();
      }
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('bm_ai_custom_workouts_v1', jsonEncode(bmAiCustomWorkouts));
        if (bmWorkoutBurnKcal > 0) prefs.setInt('bm_ai_workout_burn_kcal', bmWorkoutBurnKcal);
        if (bmAiSurplusSnack.isNotEmpty) prefs.setString('bm_ai_surplus_snack', bmAiSurplusSnack);
      });
    }""",
        """    if (profile.targetMuscles.isNotEmpty) {
      bmGlobalTargetMuscles = List<String>.from(profile.targetMuscles);
    }
    final srvWp = serverProfile['workoutPlan'];
    if (srvWp is Map) {
      if (srvWp['workout_calories'] != null) {
        bmWorkoutBurnKcal = int.tryParse(srvWp['workout_calories'].toString()) ?? bmWorkoutBurnKcal;
      }
      if (srvWp['surplus_snack'] != null && srvWp['surplus_snack'].toString().trim().isNotEmpty) {
        bmAiSurplusSnack = srvWp['surplus_snack'].toString().trim();
      }
      if (srvWp['weekly_plan'] is Map && (srvWp['weekly_plan'] as Map).isNotEmpty) {
        final wpMap = Map<String, dynamic>.from(srvWp['weekly_plan'] as Map);
        bmAiWeeklyWorkouts = {};
        for (final d in bmWorkoutWeekDays) {
          if (wpMap[d] is Map) {
            bmAiWeeklyWorkouts[d] = Map<String, dynamic>.from(wpMap[d] as Map);
          }
        }
        for (int i = 0; i < bmWorkoutWeekDays.length; i++) {
          final dObj = bmAiWeeklyWorkouts[bmWorkoutWeekDays[i]];
          if (dObj != null && dObj['is_rest'] != true && dObj['exercises'] is List && (dObj['exercises'] as List).isNotEmpty) {
            bmSelectedWorkoutDayIdx = i;
            bmAiCustomWorkouts = (dObj['exercises'] as List)
                .whereType()
                .map((e) => Map<String, String>.from(e.map((k, v) => MapEntry(k.toString(), v.toString()))))
                .toList();
            break;
          }
        }
      } else if (srvWp['exercises'] is List && (srvWp['exercises'] as List).isNotEmpty) {
        bmAiCustomWorkouts = (srvWp['exercises'] as List)
            .whereType()
            .map((e) => Map<String, String>.from(e.map((k, v) => MapEntry(k.toString(), v.toString()))))
            .toList();
      }
      SharedPreferences.getInstance().then((prefs) {
        if (bmAiWeeklyWorkouts.isNotEmpty) prefs.setString('bm_ai_weekly_workouts_v1', jsonEncode(bmAiWeeklyWorkouts));
        if (bmAiCustomWorkouts.isNotEmpty) prefs.setString('bm_ai_custom_workouts_v1', jsonEncode(bmAiCustomWorkouts));
        if (bmWorkoutBurnKcal > 0) prefs.setInt('bm_ai_workout_burn_kcal', bmWorkoutBurnKcal);
        if (bmAiSurplusSnack.isNotEmpty) prefs.setString('bm_ai_surplus_snack', bmAiSurplusSnack);
      });
    }"""
    ),
    (
        "پاکسازی bmAiWeeklyWorkouts هنگام خروج از حساب",
        "    bmAiCustomWorkouts = [];",
        "    bmAiCustomWorkouts = [];\n    bmAiWeeklyWorkouts = {};\n    bmSelectedWorkoutDayIdx = 0;\n    bmGlobalTargetMuscles = ['کل بدن'];"
    ),
    (
        "پاکسازی کلید bm_ai_weekly_workouts_v1 در خروج از حساب",
        "      await prefs.remove('bm_ai_custom_workouts_v1');",
        "      await prefs.remove('bm_ai_custom_workouts_v1');\n      await prefs.remove('bm_ai_weekly_workouts_v1');\n      await prefs.remove('bm_target_muscles_v1');"
    ),
    (
        "ذخیره targetMuscles و روزهای تمرین در saveAndSyncBodyProfileForm",
        """    required String workoutPlace,
    required String budgetTier,
    required String supplementPreference,
    required String aiCoachMemory,
    String city = '',
  }) async {""",
        """    required String workoutPlace,
    List<String> targetMuscles = const ['کل بدن'],
    required String budgetTier,
    required String supplementPreference,
    required String aiCoachMemory,
    String city = '',
  }) async {"""
    ),
    (
        "ثبت targetMuscles و bmGlobalDaysPerWeek در بدنه saveAndSyncBodyProfileForm",
        """    profile.workoutDaysPerWeek = goal == 'gain_bulk' ? 'none' : workoutDaysPerWeek;
    profile.workoutPlace = noWorkout ? 'none' : workoutPlace;""",
        """    profile.workoutDaysPerWeek = goal == 'gain_bulk' ? 'none' : workoutDaysPerWeek;
    profile.workoutPlace = noWorkout ? 'none' : workoutPlace;
    profile.targetMuscles = noWorkout ? const [] : (targetMuscles.isEmpty ? const ['کل بدن'] : List<String>.from(targetMuscles));
    bmGlobalTargetMuscles = List<String>.from(profile.targetMuscles);
    bmGlobalDaysPerWeek = profile.workoutDaysPerWeek == 'none' ? 0 : (int.tryParse(profile.workoutDaysPerWeek.replaceAll(RegExp(r'[^0-9]'), '')) ?? 3);
    bmGlobalWeight = weightKg;
    bmGlobalHeight = heightCm;
    bmGlobalAge = age;
    bmGlobalGoal = AppConfig.goalLabel(goal);
    _prefs?.setStringList('bm_target_muscles_v1', bmGlobalTargetMuscles);"""
    ),
    (
        "افزودن state انتخاب چندتایی عضلات در فرم ثبت‌نام",
        "  late String _selectedWorkoutPlace;",
        "  late String _selectedWorkoutPlace;\n  late List<String> _selectedTargetMuscles;"
    ),
    (
        "مقداردهی اولیه عضلات هدف در initState فرم",
        "    _selectedWorkoutPlace = validPlaces.contains(p.workoutPlace) ? p.workoutPlace : 'bodyweight';",
        "    _selectedWorkoutPlace = validPlaces.contains(p.workoutPlace) ? p.workoutPlace : 'bodyweight';\n    _selectedTargetMuscles = p.targetMuscles.isNotEmpty ? List<String>.from(p.targetMuscles) : ['کل بدن'];"
    ),
    (
        "افزودن UI چندانتخابی عضلات هدف به فرم ثبت‌نام",
        """        const SizedBox(height: 12),

        // ۴ سطح وضعیت اقتصادی و میزان درآمد ماهانه""",
        """        const SizedBox(height: 12),

        // انتخاب چندتایی عضلات و نواحی هدف برای تقویت
        Opacity(
          opacity: (_selectedGoal == 'gain_bulk' || _selectedWorkoutDays == 'none') ? 0.42 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💪 کدوم قسمت‌های بدنت رو می‌خوای تقویت کنی؟ (چندانتخابی؛ هرچند تا دوست داری انتخاب کن!)',
                style: TextStyle(
                  fontSize: 12.2,
                  fontWeight: FontWeight.w800,
                  color: (_selectedGoal == 'gain_bulk' || _selectedWorkoutDays == 'none') ? bmTextMutedColor : BMColors.neonCyan,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: bmTargetMuscleOptions.map((m) {
                  final isSel = _selectedTargetMuscles.contains(m);
                  final disabled = _selectedGoal == 'gain_bulk' || _selectedWorkoutDays == 'none';
                  return FilterChip(
                    selected: isSel,
                    selectedColor: BMColors.neonGreen,
                    checkmarkColor: Colors.black,
                    label: Text(
                      m,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: isSel ? Colors.black : bmTextColor,
                      ),
                    ),
                    onSelected: disabled
                        ? null
                        : (val) {
                            setState(() {
                              if (val) {
                                if (!_selectedTargetMuscles.contains(m)) {
                                  _selectedTargetMuscles.add(m);
                                }
                              } else {
                                _selectedTargetMuscles.remove(m);
                                if (_selectedTargetMuscles.isEmpty) {
                                  _selectedTargetMuscles.add('کل بدن');
                                }
                              }
                            });
                          },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ۴ سطح وضعیت اقتصادی و میزان درآمد ماهانه"""
    ),
    (
        "اصلاح بند ۶ حریم خصوصی (حذف جمله فروش به تبلیغات طبق پیشنهاد مبین)",
        "'۶. اطلاعاتت پیش ما امانته 🔒 مشخصات بدنی، شماره/جیمیل و غذاهای سفارشی تو فقط برای این ذخیره می‌شه که برنامه‌ت دقیق باشه و حسابت نپره؛ عمراً به شرکت‌های تبلیغاتی یا هیچ‌کس دیگه بفروشیم!'",
        "'۶. اطلاعاتت کاملاً محرمانه‌ست و فقط برای ساخت برنامه‌ی اختصاصی خودت و ذخیره شدن حسابت استفاده می‌شه 🔒'"
    ),
    (
        "ارسال _selectedTargetMuscles هنگام ثبت فرم",
        "                workoutPlace: noWorkoutSelected ? 'none' : _selectedWorkoutPlace,",
        "                workoutPlace: noWorkoutSelected ? 'none' : _selectedWorkoutPlace,\n                targetMuscles: noWorkoutSelected ? const [] : _selectedTargetMuscles,"
    ),
    (
        "بررسی وجود برنامه هفتگی در شرط قفل باشگاه زنده",
        "    if (!canAccessGym || bmAiCustomWorkouts.isEmpty) {",
        "    if (!canAccessGym || (bmAiCustomWorkouts.isEmpty && bmAiWeeklyWorkouts.isEmpty)) {"
    ),
    (
        "افزودن نوار ۷ روز هفته و کارت روز استراحت به UI باشگاه زنده",
        """        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bmCardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF00E5A3).withOpacity(0.4))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 20), const SizedBox(width: 6), Text('کالری مصرفی این تمرین: ${bmGetVisibleWorkoutCalories()} کالری 🔥', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: bmTextColor))]),InkWell(onTap: (bmGlobalDaysPerWeek <= 0 || bmIsWorkoutQuotaExhausted()) ? null : () => bmGenerateAiWorkoutPlan(context, authHeaders: c._authHeaders, onDone: () => setState(() {})), borderRadius: BorderRadius.circular(8), child: Opacity(opacity: (bmGlobalDaysPerWeek <= 0 || bmIsWorkoutQuotaExhausted()) ? 0.45 : 1.0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: (bmGlobalDaysPerWeek <= 0 || bmIsWorkoutQuotaExhausted()) ? Colors.grey : const Color(0xFF00E5A3), borderRadius: BorderRadius.circular(8), border: Border.all(color: (bmGlobalDaysPerWeek <= 0 || bmIsWorkoutQuotaExhausted()) ? Colors.grey : const Color(0xFF00E5A3))), child: ValueListenableBuilder<int>(valueListenable: bmAiCooldownSec, builder: (_, sec, __) => Text(bmGlobalDaysPerWeek <= 0 ? 'ورزش نداری رفیق 😅' : (bmIsWorkoutQuotaExhausted() ? 'سهمیه‌ت تموم شده رفیق 😉' : (bmIsGeneratingWorkout ? 'در حال محاسبه AI... ⏳' : (sec > 0 ? '⏳ صبر کن ($sec)' : 'دریافت/تمدید برنامه ورزشی'))), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black)))))),]),const SizedBox(height: 8),Text(bmGetSurplusRecommendation(), style: TextStyle(fontSize: 11.5, color: bmTextSubColor, height: 1.45)),])), Column(""",
        """        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (bmAiWeeklyWorkouts.isNotEmpty) ...[
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: bmWorkoutWeekDays.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, idx) {
                final dName = bmWorkoutWeekDays[idx];
                final dObj = bmAiWeeklyWorkouts[dName];
                final isRest = dObj == null || dObj['is_rest'] == true;
                final isSel = idx == bmSelectedWorkoutDayIdx;
                return ChoiceChip(
                  selected: isSel,
                  selectedColor: isRest ? BMColors.electricBlue : BMColors.neonCyan,
                  label: Text(
                    isRest ? '$dName 😴' : '$dName 💪',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: isSel ? Colors.black : bmTextColor,
                    ),
                  ),
                  onSelected: (_) {
                    setState(() {
                      bmSelectedWorkoutDayIdx = idx;
                      _activeStepIndex = 0;
                      _currentSet = 1;
                      _previewPhase = null;
                      if (!isRest && dObj['exercises'] is List) {
                        bmAiCustomWorkouts = (dObj['exercises'] as List)
                            .whereType()
                            .map((e) => Map<String, String>.from(e.map((k, v) => MapEntry(k.toString(), v.toString()))))
                            .toList();
                      }
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Builder(builder: (_) {
            final dName = bmWorkoutWeekDays[bmSelectedWorkoutDayIdx.clamp(0, 6)];
            final dObj = bmAiWeeklyWorkouts[dName];
            final isRest = dObj == null || dObj['is_rest'] == true;
            final focusTxt = (dObj?['focus'] ?? (isRest ? 'استراحت و ریکاوری عضلات 😴🌿' : 'تمرین اختصاصی روز $dName 💪')).toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isRest ? BMColors.electricBlue.withOpacity(0.14) : BMColors.neonCyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isRest ? BMColors.electricBlue : BMColors.neonCyan),
              ),
              child: Row(
                children: [
                  Text(isRest ? '😴🌿' : '🎯💪', style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRest ? '$dName: روز استراحت و ریکاوری' : 'تمرکز تمرین $dName:',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isRest ? BMColors.electricBlue : BMColors.neonCyan),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isRest
                              ? '$focusTxt — عضلات دیروزت امروز دارن رشد می‌کنن! آب کافی بخور و کشش سبک انجام بده 💧'
                              : focusTxt,
                          style: TextStyle(fontSize: 12, color: bmTextColor, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bmCardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF00E5A3).withOpacity(0.4))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 20), const SizedBox(width: 6), Text('کالری مصرفی این تمرین: ${bmGetVisibleWorkoutCalories()} کالری 🔥', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: bmTextColor))]),InkWell(onTap: (bmGlobalDaysPerWeek <= 0 || bmIsWorkoutQuotaExhausted()) ? null : () => bmGenerateAiWorkoutPlan(context, authHeaders: c._authHeaders, onDone: () => setState(() {})), borderRadius: BorderRadius.circular(8), child: Opacity(opacity: (bmGlobalDaysPerWeek <= 0 || bmIsWorkoutQuotaExhausted()) ? 0.45 : 1.0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: (bmGlobalDaysPerWeek <= 0 || bmIsWorkoutQuotaExhausted()) ? Colors.grey : const Color(0xFF00E5A3), borderRadius: BorderRadius.circular(8), border: Border.all(color: (bmGlobalDaysPerWeek <= 0 || bmIsWorkoutQuotaExhausted()) ? Colors.grey : const Color(0xFF00E5A3))), child: ValueListenableBuilder<int>(valueListenable: bmAiCooldownSec, builder: (_, sec, __) => Text(bmGlobalDaysPerWeek <= 0 ? 'ورزش نداری رفیق 😅' : (bmIsWorkoutQuotaExhausted() ? 'سهمیه‌ت تموم شده رفیق 😉' : (bmIsGeneratingWorkout ? 'در حال محاسبه AI... ⏳' : (sec > 0 ? '⏳ صبر کن ($sec)' : 'دریافت/تمدید برنامه ورزشی'))), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black)))))),]),const SizedBox(height: 8),Text(bmGetSurplusRecommendation(), style: TextStyle(fontSize: 11.5, color: bmTextSubColor, height: 1.45)),])), Column("""
    ),
]

# ==============================================================================
# 2. پچ‌های فایل worker.js
# ==============================================================================
worker_patches = [
    (
        "ذخیره targetMuscles در پروفایل کلودفلر",
        "            workoutPlace: finalWorkoutPlace,",
        "            workoutPlace: finalWorkoutPlace,\n            targetMuscles: Array.isArray(payload.targetMuscles) ? payload.targetMuscles : (currentProfile.targetMuscles || [\"کل بدن\"]),"
    ),
    (
        "افزودن targetMuscles به لیست safeFields در /api/ai",
        '            "workoutPlace", "budgetTier", "supplementPref", "aiMemory", "city",',
        '            "workoutPlace", "targetMuscles", "budgetTier", "supplementPref", "aiMemory", "city",'
    ),
    (
        "آپدیت System Instruction برای برنامه ورزشی ۷ روزه علمی در worker.js",
        '        const agentSystemInstruction = isWorkoutPlanReq\n          ? "تو مربی حرفه‌ای بدنسازی اپلیکیشن «بادی‌مود» هستی (همیشه بنویس بادی‌مود و هرگز سرهم ننویس). برنامه ورزشی باید مثل برنامه غذایی بسیار متنوع، خلاقانه و غیرتکراری باشه و حرکات مختلفی برای زوایای مختلف عضلات بچینی. فقط و فقط یک آبجکت JSON خالص و معتبر بدون هیچ متن اضافه برگردان با دقیقاً این ۳ کلید: workout_calories (عدد), surplus_snack (متن فارسی), exercises (آرایه‌ای از ۷ آبجکت که هر کدام کلیدهای title, muscle, breath, tip دارند)."',
        '        const agentSystemInstruction = isWorkoutPlanReq\n          ? "تو مربی حرفه‌ای بدنسازی اپلیکیشن «بادی‌مود» هستی (همیشه بنویس بادی‌مود و هرگز سرهم ننویس). برنامه ورزشی باید یک برنامه ۷ روزه علمی (شنبه تا جمعه) با تفکیک دقیق عضلات مرتبط باشه (مثلاً بالاتنه/پایین‌تنه یا Push/Pull/Legs) طوری که عضله‌ای که دیروز تمرین داده شده، فرداش استراحت کنه؛ و اگر کاربر فقط ۱ یا ۲ روز در هفته تمرین می‌کنه، برنامه کل بدن (Full Body) بده. عضلات هدف انتخابی کاربر رو در اولویت بذار. فقط و فقط یک آبجکت JSON خالص و معتبر بدون هیچ متن اضافه برگردان با دقیقاً این ۳ کلید: workout_calories (عدد), surplus_snack (متن فارسی), weekly_plan (آبجکتی با کلیدهای شنبه، یکشنبه، دوشنبه، سه‌شنبه، چهارشنبه، پنجشنبه، جمعه که هر روز دارای is_rest (بولین)، focus (متن فارسی عنوان عضله هدف یا استراحت)، و exercises (آرایه‌ای از ۷ آبجکت با کلیدهای title, muscle, breath, tip برای روزهای تمرین و [] برای روزهای استراحت) باشد)."'
    ),
    (
        "ذخیره weekly_plan در پروفایل KV در worker.js",
        "              if (parsedWp && Array.isArray(parsedWp.exercises) && parsedWp.exercises.length > 0) {",
        "              if (parsedWp && ((parsedWp.weekly_plan && typeof parsedWp.weekly_plan === \"object\") || (Array.isArray(parsedWp.exercises) && parsedWp.exercises.length > 0))) {"
    ),
    (
        "افزودن عضلات هدف کاربر به پرامپت مربی در worker.js",
        '    "- محل تمرین و تجهیزات: " + ((profile.goal === "gain_bulk" || profile.workoutDaysPerWeek === "none" || profile.workoutPlace === "none") ? "بدون تمرین ورزشی" : (profile.workoutPlace === "gym" ? "باشگاه بدنسازی کامل" : (profile.workoutPlace === "home_dumbbell" ? "در خانه با دمبل" : "در خانه بدون تجهیزات (وزن بدن)"))),',
        '    "- محل تمرین و تجهیزات: " + ((profile.goal === "gain_bulk" || profile.workoutDaysPerWeek === "none" || profile.workoutPlace === "none") ? "بدون تمرین ورزشی" : (profile.workoutPlace === "gym" ? "باشگاه بدنسازی کامل" : (profile.workoutPlace === "home_dumbbell" ? "در خانه با دمبل" : "در خانه بدون تجهیزات (وزن بدن)"))),\n    "- عضلات و نواحی هدف کاربر برای تقویت: " + (Array.isArray(profile.targetMuscles) && profile.targetMuscles.length > 0 ? profile.targetMuscles.join("، ") : "کل بدن"),'
    ),
]

ok1 = patch_file(DART_PATH, dart_patches)
ok2 = patch_file(WORKER_PATH, worker_patches)

if ok1 and ok2:
    print("🎉 همه تغییرات با موفقیت ۱۰۰٪ روی هر دو فایل اعمال شد! آماده‌ی دیپلوی کلودفلر و بیلد فلاتر هستی 🚀🔥")
else:
    print("⚠️ بعضی پچ‌ها اعمال نشدن؛ خروجی بالا رو برام بفرست تا دقیق فیکسش کنم!")
