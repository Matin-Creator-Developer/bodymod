import os
import shutil

# ============================================================================
# 0. BACKUP WORKER.JS
# ============================================================================
main_path = "lib/main.dart"
worker_path = "worker.js"

if os.path.exists(worker_path) and not os.path.exists(worker_path + ".v_working_bak"):
    shutil.copyfile(worker_path, worker_path + ".v_working_bak")
    print("✅ Backup created: worker.js.v_working_bak")

# ============================================================================
# 1. PATCH lib/main.dart
# ============================================================================
with open(main_path, "r", encoding="utf-8") as f:
    dart = f.read()

def safe_replace(text, old, new, label):
    if old in text:
        print(f"✅ [main.dart] {label}")
        return text.replace(old, new, 1)
    else:
        print(f"⚠️ [main.dart] Skipped (not found or already patched): {label}")
        return text

# 1.1 اضافه کردن birthDate, isFreeTrial, freeTrialClaimed به UserProfileModel
dart = safe_replace(
    dart,
    "  String photoUrl;\n  int age;",
    "  String photoUrl;\n  String birthDate;\n  int age;",
    "Add birthDate field",
)
dart = safe_replace(
    dart,
    "  bool hasActiveSubscription;\n  String subscriptionTier;",
    "  bool hasActiveSubscription;\n  bool isFreeTrial;\n  bool freeTrialClaimed;\n  String subscriptionTier;",
    "Add freeTrial fields",
)
dart = safe_replace(
    dart,
    "    this.photoUrl = '',\n    this.age = 21,",
    "    this.photoUrl = '',\n    this.birthDate = '',\n    this.age = 21,",
    "Add birthDate to constructor",
)
dart = safe_replace(
    dart,
    "    this.hasActiveSubscription = false,\n    this.subscriptionTier = 'بدون اشتراک',",
    "    this.hasActiveSubscription = false,\n    this.isFreeTrial = false,\n    this.freeTrialClaimed = false,\n    this.subscriptionTier = 'بدون اشتراک',",
    "Add freeTrial to constructor",
)
dart = safe_replace(
    dart,
    "    'photoUrl': photoUrl,\n    'age': age,",
    "    'photoUrl': photoUrl,\n    'birthDate': birthDate,\n    'age': age,",
    "Add birthDate to toJson",
)
dart = safe_replace(
    dart,
    "    'hasActiveSubscription': hasActiveSubscription,\n    'subscriptionTier': subscriptionTier,",
    "    'hasActiveSubscription': hasActiveSubscription,\n    'isFreeTrial': isFreeTrial,\n    'freeTrialClaimed': freeTrialClaimed,\n    'subscriptionTier': subscriptionTier,",
    "Add freeTrial to toJson",
)
dart = safe_replace(
    dart,
    "      photoUrl: (json['photoUrl'] ?? json['picture'] ?? '').toString(),\n      age: (json['age'] as num?)?.toInt() ?? 21,",
    "      photoUrl: (json['photoUrl'] ?? json['picture'] ?? '').toString(),\n      birthDate: (json['birthDate'] ?? '').toString(),\n      age: (json['age'] as num?)?.toInt() ?? 21,",
    "Add birthDate to fromJson",
)
dart = safe_replace(
    dart,
    "      hasActiveSubscription: json['hasActiveSubscription'] == true,\n      subscriptionTier: (json['subscriptionTier'] ?? 'بدون اشتراک').toString(),",
    "      hasActiveSubscription: json['hasActiveSubscription'] == true,\n      isFreeTrial: json['isFreeTrial'] == true,\n      freeTrialClaimed: json['freeTrialClaimed'] == true,\n      subscriptionTier: (json['subscriptionTier'] ?? 'بدون اشتراک').toString(),",
    "Add freeTrial to fromJson",
)

# 1.2 اضافه کردن deviceId و بازیابی birthDate و چک کردن انقضای اشتراک در BodyModController
dart = safe_replace(
    dart,
    "  bool isDarkMode = true;\n  bool isLoadingAi = false;",
    "  bool isDarkMode = true;\n  bool isLoadingAi = false;\n  String deviceId = '';",
    "Add deviceId to controller",
)

old_load_end = """    final rawProfile = prefs.getString('bm_user_profile_v82');
    if (rawProfile != null && rawProfile.isNotEmpty) {
      try {
        profile = UserProfileModel.fromJson(
          jsonDecode(rawProfile) as Map<String, dynamic>,
        );
      } catch (_) {}
    }"""

new_load_end = """    deviceId = prefs.getString('bm_device_id_v1') ?? '';
    if (deviceId.isEmpty) {
      final rnd = math.Random();
      deviceId = 'dev_${DateTime.now().millisecondsSinceEpoch}_${rnd.nextInt(999999)}';
      prefs.setString('bm_device_id_v1', deviceId);
    }

    final rawProfile = prefs.getString('bm_user_profile_v82');
    if (rawProfile != null && rawProfile.isNotEmpty) {
      try {
        profile = UserProfileModel.fromJson(
          jsonDecode(rawProfile) as Map<String, dynamic>,
        );
        if (profile.birthDate.isNotEmpty) {
          _bmSavedBirthStr = profile.birthDate;
        }
        if (!profile.isAdmin && profile.hasActiveSubscription && profile.subscriptionExpiresAt > 0) {
          final remMs = profile.subscriptionExpiresAt - DateTime.now().millisecondsSinceEpoch;
          if (remMs <= 0) {
            profile.hasActiveSubscription = false;
            profile.isFreeTrial = false;
            profile.subscriptionDaysRemaining = 0;
          } else {
            profile.subscriptionDaysRemaining = (remMs / 86400000).ceil();
          }
        }
      } catch (_) {}
    }"""

dart = safe_replace(dart, old_load_end, new_load_end, "Load deviceId, birthDate & check trial expiry")

# ارسال X-Device-ID در هدرهای سرور
dart = safe_replace(
    dart,
    """    if (profile.userKey.isNotEmpty) {
      headers['X-User-ID'] = profile.userKey;
    }
    return headers;""",
    """    if (profile.userKey.isNotEmpty) {
      headers['X-User-ID'] = profile.userKey;
    }
    if (deviceId.isNotEmpty) {
      headers['X-Device-ID'] = deviceId;
    }
    return headers;""",
    "Add X-Device-ID header",
)

# 1.3 جلوگیری از پاک شدن فرم لوکال وقتی کلودفلر پروفایل خالی برمی‌گردونه
old_apply_auth = """  void _applyServerAuthData(Map<String, dynamic> data) {
    final token = (data['token'] ?? profile.sessionToken).toString();
    final serverProfile = data['profile'] as Map<String, dynamic>? ?? {};
    final userObj = data['user'] as Map<String, dynamic>? ?? {};

    profile = UserProfileModel.fromJson({
      ...profile.toJson(),
      ...serverProfile,
      'sessionToken': token,
      'email': serverProfile['email'] ?? userObj['email'] ?? profile.email,
      'phone': serverProfile['phone'] ?? userObj['phone'] ?? profile.phone,
      'userKey':
          serverProfile['userKey'] ??
          userObj['email'] ??
          userObj['phone'] ??
          profile.userKey,
      'isLoggedIn': true,
    });"""

new_apply_auth = """  void _applyServerAuthData(Map<String, dynamic> data) {
    final token = (data['token'] ?? profile.sessionToken).toString();
    final serverProfile = Map<String, dynamic>.from(
      data['profile'] as Map<String, dynamic>? ?? {},
    );
    final userObj = data['user'] as Map<String, dynamic>? ?? {};

    // اگر کاربر همین الان روی گوشی فرمش رو کامل کرده ولی سرور هنوز پروفایل پیش‌فرض/خالی برگردوند، اطلاعات لوکال رو خراب نکن!
    final bool localDone = profile.isProfileCompleted;
    final bool serverDone = serverProfile['isProfileCompleted'] == true;
    final Map<String, dynamic> merged = (localDone && !serverDone)
        ? {
            ...serverProfile,
            ...profile.toJson(),
            'isAdmin': serverProfile['isAdmin'] == true || profile.isAdmin,
            'hasActiveSubscription':
                serverProfile['hasActiveSubscription'] == true || profile.hasActiveSubscription,
            'subscriptionDaysRemaining': math.max(
              (serverProfile['subscriptionDaysRemaining'] as num?)?.toInt() ?? 0,
              profile.subscriptionDaysRemaining,
            ),
            'subscriptionExpiresAt': math.max(
              (serverProfile['subscriptionExpiresAt'] as num?)?.toInt() ?? 0,
              profile.subscriptionExpiresAt,
            ),
            'isFreeTrial':
                serverProfile['isFreeTrial'] == true || profile.isFreeTrial,
            'freeTrialClaimed':
                serverProfile['freeTrialClaimed'] == true || profile.freeTrialClaimed,
          }
        : {
            ...profile.toJson(),
            ...serverProfile,
          };

    profile = UserProfileModel.fromJson({
      ...merged,
      'sessionToken': token,
      'email': serverProfile['email'] ?? userObj['email'] ?? profile.email,
      'phone': serverProfile['phone'] ?? userObj['phone'] ?? profile.phone,
      'userKey':
          serverProfile['userKey'] ??
          userObj['email'] ??
          userObj['phone'] ??
          profile.userKey,
      'birthDate': (merged['birthDate'] ?? profile.birthDate).toString(),
      'isLoggedIn': true,
    });
    if (profile.birthDate.isNotEmpty) {
      _bmSavedBirthStr = profile.birthDate;
    }"""

dart = safe_replace(dart, old_apply_auth, new_apply_auth, "Fix _applyServerAuthData overwrite bug")

# 1.4 آپدیت saveAndSyncBodyProfileForm برای ذخیره تاریخ تولد + ۳ روز رایگان + همگام‌سازی کامل
old_save_form = """  // ذخیره فرم پرونده بدنی + حافظه هوش مصنوعی در کلودفلر (باز کردن قفل مرحله ۲)
  Future<bool> saveAndSyncBodyProfileForm(
    BuildContext context, {
    required String displayName,
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required double targetWeightKg,
    required String goal,
    required String workoutDaysPerWeek,
    required String workoutPlace,
    required String budgetTier,
    required String supplementPreference,
    required String aiCoachMemory,
  }) async {
    profile.displayName = displayName.trim().isEmpty
        ? 'رفیق ورزشکار'
        : displayName.trim();
    profile.age = age;
    profile.gender = gender;
    profile.heightCm = heightCm;
    profile.weightKg = weightKg;
    profile.targetWeightKg = targetWeightKg;
    profile.goal = goal;
    profile.workoutDaysPerWeek = workoutDaysPerWeek;
    profile.workoutPlace = workoutPlace;
    profile.budgetTier = budgetTier;
    profile.supplementPreference = supplementPreference;
    profile.aiCoachMemory = aiCoachMemory.trim();
    profile.isProfileCompleted = true;

    _ensureWorkoutStepsReady();
    await saveAllToDisk();
    notifyListeners();

    if (profile.isLoggedIn) {
      try {
        final uri = Uri.parse('${AppConfig.serverBaseUrl}/api/user/profile');
        final res = await http
            .post(
              uri,
              headers: _authHeaders,
              body: jsonEncode(profile.toJson()),
            )
            .timeout(const Duration(seconds: 10));"""

new_save_form = """  // ذخیره فرم پرونده بدنی + حافظه هوش مصنوعی در کلودفلر + فعال‌سازی ۳ روز اشتراک رایگان
  Future<bool> saveAndSyncBodyProfileForm(
    BuildContext context, {
    required String displayName,
    required String birthDate,
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required double targetWeightKg,
    required String goal,
    required String workoutDaysPerWeek,
    required String workoutPlace,
    required String budgetTier,
    required String supplementPreference,
    required String aiCoachMemory,
  }) async {
    final bool noWorkout = goal == 'gain_bulk' || workoutDaysPerWeek == 'none';
    profile.displayName = displayName.trim().isEmpty
        ? 'رفیق ورزشکار'
        : displayName.trim();
    if (birthDate.trim().isNotEmpty) {
      profile.birthDate = birthDate.trim();
      _bmSavedBirthStr = profile.birthDate;
    }
    profile.age = age;
    profile.gender = gender;
    profile.heightCm = heightCm;
    profile.weightKg = weightKg;
    profile.targetWeightKg = targetWeightKg;
    profile.goal = goal;
    profile.workoutDaysPerWeek = goal == 'gain_bulk' ? 'none' : workoutDaysPerWeek;
    profile.workoutPlace = noWorkout ? 'none' : workoutPlace;
    profile.budgetTier = budgetTier;
    profile.supplementPreference = supplementPreference;
    profile.aiCoachMemory = aiCoachMemory.trim();
    profile.isProfileCompleted = true;

    // اعطای ۳ روز اشتراک رایگان برای اولین تکمیل فرم (در صورتی که قبلاً نگرفته باشد)
    if (!profile.isAdmin && !profile.hasActiveSubscription && !profile.freeTrialClaimed) {
      profile.freeTrialClaimed = true;
      profile.isFreeTrial = true;
      profile.hasActiveSubscription = true;
      profile.subscriptionTier = 'اشتراک رایگان ۳ روزه هدیه ثبت‌نام 🎁';
      profile.subscriptionDaysRemaining = 3;
      profile.subscriptionExpiresAt =
          DateTime.now().millisecondsSinceEpoch + (3 * 86400 * 1000);
    }

    _ensureWorkoutStepsReady();
    await saveAllToDisk();
    notifyListeners();

    if (profile.isLoggedIn) {
      try {
        final uri = Uri.parse('${AppConfig.serverBaseUrl}/api/user/profile');
        final res = await http
            .post(
              uri,
              headers: _authHeaders,
              body: jsonEncode({
                ...profile.toJson(),
                'deviceId': deviceId,
              }),
            )
            .timeout(const Duration(seconds: 10));"""

dart = safe_replace(dart, old_save_form, new_save_form, "Update saveAndSyncBodyProfileForm with 3-day trial & birthDate")

# 1.5 ارسال کل پروفایل به همه‌ی درخواست‌های هوش مصنوعی (چت، برنامه غذایی، کالری‌شمار)
dart = safe_replace(
    dart,
    """            body: jsonEncode({
              'foodQuery': foodDescription,
              'imageBase64': base64Image,
              'model': profile.preferredModel,
            }),""",
    """            body: jsonEncode({
              'foodQuery': foodDescription,
              'imageBase64': base64Image,
              'model': profile.preferredModel,
              'profile': profile.toJson(),
            }),""",
    "Send full profile to /api/ai/calorie",
)
dart = safe_replace(
    dart,
    """            body: jsonEncode({
              'mode': 'weekly_plan',
              'model': profile.preferredModel,
              'prompt':""",
    """            body: jsonEncode({
              'mode': 'weekly_plan',
              'model': profile.preferredModel,
              'profile': profile.toJson(),
              'prompt':""",
    "Send full profile to /api/ai/weekly-plan",
)
dart = safe_replace(
    dart,
    """            body: jsonEncode({
              'prompt': clean,
              'model': profile.preferredModel,
            }),""",
    """            body: jsonEncode({
              'prompt': clean,
              'model': profile.preferredModel,
              'profile': profile.toJson(),
            }),""",
    "Send full profile to /api/ai/chat",
)

# 1.6 اصلاح فرم ثبت‌نام: غیرفعال/خاکستری کردن گزینه‌های تمرین + حفظ تاریخ تولد
old_form_init = """    _ageCtrl = TextEditingController(text: '');
    _heightCtrl = TextEditingController(text: p.heightCm.toString());"""
new_form_init = """    _ageCtrl = TextEditingController(text: p.birthDate.isNotEmpty ? p.birthDate : _bmSavedBirthStr);
    _heightCtrl = TextEditingController(text: p.heightCm.toString());"""
dart = safe_replace(dart, old_form_init, new_form_init, "Restore birthDate in form initState")

old_place_init = """    _selectedWorkoutPlace = p.workoutPlace; bmGlobalEquipment = _selectedWorkoutPlace.toString(); bmAiCustomWorkouts.clear(); bmWorkoutBurnKcal = 0; bmAiSurplusSnack = '';"""
new_place_init = """    const validPlaces = ['home_dumbbell', 'gym', 'bodyweight'];
    _selectedWorkoutPlace = validPlaces.contains(p.workoutPlace) ? p.workoutPlace : 'bodyweight';
    if (_selectedGoal == 'gain_bulk') {
      _selectedWorkoutDays = 'none';
    }
    bmGlobalEquipment = _selectedWorkoutPlace.toString(); bmAiCustomWorkouts.clear(); bmWorkoutBurnKcal = 0; bmAiSurplusSnack = '';"""
dart = safe_replace(dart, old_place_init, new_place_init, "Safe workoutPlace init when 'none'")

old_goal_block = """        // ۶ هدف دقیق بدنسازی و تناسب اندام
        DropdownButtonFormField<String>(
          value: _selectedGoal,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'هدف اصلی شما 🎯',
          ),
          items: AppConfig.goalOptions.entries
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) =>
              setState(() => _selectedGoal = v ?? 'gain_muscle'),
        ),
        const SizedBox(height: 14),

        // سوال تعداد روزهای تمرین در هفته با توضیح دقیق
        Text(
          '🏋️‍♂️ چند روز در هفته تمرین میکنی؟ مناسب عضله سازی (هرچه بیشتر تمرین کنی، سریعتر به هدفت میرسی)',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: BMColors.neonCyan,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedWorkoutDays,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'تعداد روزهای تمرین در هفته',
          ),
          items: AppConfig.workoutDaysOptions.entries
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) =>
              setState(() => _selectedWorkoutDays = v ?? 'd3'),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: _selectedWorkoutPlace,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'محل تمرین و تجهیزات 🏟️',
          ),
          items: const [
            DropdownMenuItem(
              value: 'home_dumbbell',
              child: Text('تمرین در خانه با دمبل 🏠💪'),
            ),
            DropdownMenuItem(
              value: 'gym',
              child: Text('باشگاه بدنسازی کامل 🏟️'),
            ),
            DropdownMenuItem(
              value: 'bodyweight',
              child: Text('در خانه بدون تجهیزات (وزن بدن) 🤸‍♂️'),
            ),
          ],
          onChanged: (v) =>
              setState(() => _selectedWorkoutPlace = v ?? 'home_dumbbell'),
        ),"""

new_goal_block = """        // ۶ هدف دقیق بدنسازی و تناسب اندام
        DropdownButtonFormField<String>(
          value: _selectedGoal,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'هدف اصلی شما 🎯',
          ),
          items: AppConfig.goalOptions.entries
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() {
            _selectedGoal = v ?? 'gain_muscle';
            if (_selectedGoal == 'gain_bulk') {
              _selectedWorkoutDays = 'none';
            }
          }),
        ),
        const SizedBox(height: 14),

        // سوال تعداد روزهای تمرین در هفته (در هدف افزایش وزن عمومی غیرفعال و خاکستری می‌شود)
        Opacity(
          opacity: _selectedGoal == 'gain_bulk' ? 0.42 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedGoal == 'gain_bulk'
                    ? '🏋️‍♂️ برای افزایش وزن عمومی نیازی به تمرین نیست (غیرفعال شد) 🍽️'
                    : '🏋️‍♂️ چند روز در هفته تمرین میکنی؟ مناسب عضله سازی (هرچه بیشتر تمرین کنی، سریعتر به هدفت میرسی)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _selectedGoal == 'gain_bulk' ? bmTextMutedColor : BMColors.neonCyan,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedGoal == 'gain_bulk' ? 'none' : _selectedWorkoutDays,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'تعداد روزهای تمرین در هفته',
                  enabled: _selectedGoal != 'gain_bulk',
                ),
                items: AppConfig.workoutDaysOptions.entries
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: _selectedGoal == 'gain_bulk'
                    ? null
                    : (v) => setState(() => _selectedWorkoutDays = v ?? 'd3'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // محل تمرین و تجهیزات (اگر کاربر تمرین نداشته باشد غیرفعال و خاکستری می‌شود)
        Opacity(
          opacity: (_selectedGoal == 'gain_bulk' || _selectedWorkoutDays == 'none') ? 0.42 : 1.0,
          child: DropdownButtonFormField<String>(
            value: _selectedWorkoutPlace,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: (_selectedGoal == 'gain_bulk' || _selectedWorkoutDays == 'none')
                  ? 'محل تمرین و تجهیزات (نیازی به تمرین نیست) 🏟️'
                  : 'محل تمرین و تجهیزات 🏟️',
              enabled: !(_selectedGoal == 'gain_bulk' || _selectedWorkoutDays == 'none'),
            ),
            items: const [
              DropdownMenuItem(
                value: 'home_dumbbell',
                child: Text('تمرین در خانه با دمبل 🏠💪'),
              ),
              DropdownMenuItem(
                value: 'gym',
                child: Text('باشگاه بدنسازی کامل 🏟️'),
              ),
              DropdownMenuItem(
                value: 'bodyweight',
                child: Text('در خانه بدون تجهیزات (وزن بدن) 🤸‍♂️'),
              ),
            ],
            onChanged: (_selectedGoal == 'gain_bulk' || _selectedWorkoutDays == 'none')
                ? null
                : (v) => setState(() => _selectedWorkoutPlace = v ?? 'home_dumbbell'),
          ),
        ),"""

dart = safe_replace(dart, old_goal_block, new_goal_block, "Add conditional disable/grey-out for workout dropdowns")

old_form_submit = """              await c.saveAndSyncBodyProfileForm(
                context,
                displayName: _nameCtrl.text,
                age: (bmCalculateAgeFromBirthDate(_ageCtrl.text) ?? int.tryParse(_ageCtrl.text)) ?? 21,
                gender: _selectedGender,
                heightCm: double.tryParse(_heightCtrl.text) ?? 175,
                weightKg: double.tryParse(_weightCtrl.text) ?? 70,
                targetWeightKg: double.tryParse(_targetWeightCtrl.text) ?? 75,
                goal: _selectedGoal,
                workoutDaysPerWeek: _selectedWorkoutDays,
                workoutPlace: _selectedWorkoutPlace,
                budgetTier: _selectedBudgetTier,
                supplementPreference: _selectedSupplementMode,
                aiCoachMemory: _memoryCtrl.text,
              );"""

new_form_submit = """              final bool noWorkoutSelected = _selectedGoal == 'gain_bulk' || _selectedWorkoutDays == 'none';
              await c.saveAndSyncBodyProfileForm(
                context,
                displayName: _nameCtrl.text,
                birthDate: _ageCtrl.text.trim(),
                age: (bmCalculateAgeFromBirthDate(_ageCtrl.text) ?? int.tryParse(_ageCtrl.text)) ?? 21,
                gender: _selectedGender,
                heightCm: double.tryParse(_heightCtrl.text) ?? 175,
                weightKg: double.tryParse(_weightCtrl.text) ?? 70,
                targetWeightKg: double.tryParse(_targetWeightCtrl.text) ?? 75,
                goal: _selectedGoal,
                workoutDaysPerWeek: _selectedGoal == 'gain_bulk' ? 'none' : _selectedWorkoutDays,
                workoutPlace: noWorkoutSelected ? 'none' : _selectedWorkoutPlace,
                budgetTier: _selectedBudgetTier,
                supplementPreference: _selectedSupplementMode,
                aiCoachMemory: _memoryCtrl.text,
              );"""

dart = safe_replace(dart, old_form_submit, new_form_submit, "Pass birthDate and noWorkout to saveAndSyncBodyProfileForm")

# 1.7 نمایش بنر تبریک ۳ روز اشتراک رایگان در SmartAiLockBanner
old_lock_zero = """    final stage = controller.aiLockStage;
    if (stage == 0) return const SizedBox.shrink();"""

new_lock_zero = """    final stage = controller.aiLockStage;
    if (stage == 0) {
      if (controller.profile.isFreeTrial &&
          controller.profile.hasActiveSubscription &&
          !controller.profile.isAdmin) {
        final daysLeft = controller.profile.subscriptionDaysRemaining;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [BMColors.neonGreen.withOpacity(0.2), bmCardColor],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BMColors.neonGreen, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🎉🎁 ', style: TextStyle(fontSize: 20)),
                  Expanded(
                    child: Text(
                      'دمت گرم رفیق، ثبت‌نامت با موفقیت انجام شد 👏',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color: BMColors.neonGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                '۳ روز اشتراک رایگان بهت تعلق گرفت 😍 (باقی‌مانده: $daysLeft روز)\nمیتونی از همه امکانات هوش مصنوعی هم استفاده کنی، ولی بعد از تموم شدن باید اشتراک بخری 😂',
                style: TextStyle(fontSize: 12.8, height: 1.55, color: bmTextColor),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BMColors.neonGreen,
                    side: BorderSide(color: BMColors.neonGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => onNavigateTab(4),
                  icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                  label: const Text(
                    'مشاهده وضعیت اشتراک 💎',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }"""

dart = safe_replace(dart, old_lock_zero, new_lock_zero, "Add 3-day free trial celebration banner")

with open(main_path, "w", encoding="utf-8") as f:
    f.write(dart)

# ============================================================================
# 2. PATCH worker.js (KV check, 3-day trial + deviceId anti-spam, full AI profile)
# ============================================================================
with open(worker_path, "r", encoding="utf-8") as f:
    js = f.read()

def safe_replace_js(text, old, new, label):
    if old in text:
        print(f"✅ [worker.js] {label}")
        return text.replace(old, new, 1)
    else:
        print(f"⚠️ [worker.js] Skipped (not found or already patched): {label}")
        return text

# 2.1 اضافه کردن X-Device-ID به CORS و kv_bound به /api/health
js = safe_replace_js(
    js,
    'X-Client-Version, X-Platform"',
    'X-Client-Version, X-Platform, X-Device-ID"',
    "Allow X-Device-ID in CORS",
)
js = safe_replace_js(
    js,
    '          otp_service: "Bale Safir v3",',
    '          kv_bound: Boolean(env && env.BODYMOD_DB_KV && typeof env.BODYMOD_DB_KV.get === "function"),\n          otp_service: "Bale Safir v3",',
    "Add kv_bound status to /api/health",
)

# 2.2 اعطای ۳ روز اشتراک رایگان ضدتقلب (با Device ID) هنگام تکمیل فرم در POST /api/user/profile
old_worker_save = """          const updatedProfile = {
            ...currentProfile,
            ...payload,
            name: payload.name || payload.displayName || currentProfile.name || "رفیق ورزشکار",
            displayName: payload.displayName || payload.name || currentProfile.displayName || "رفیق ورزشکار",
            goal: goalKey,
            goalLabel: FITNESS_GOALS[goalKey] || goalKey,
            workoutDaysPerWeek: workoutDaysKey,
            workoutDaysLabel: WORKOUT_DAYS_LABELS[workoutDaysKey] || workoutDaysKey,
            budgetTier: tierKey,
            economicStatus: tierKey,
            budgetTierLabel: BUDGET_TIERS[tierKey] || BUDGET_TIERS.base,
            aiCoachMemory: payload.aiCoachMemory ?? currentProfile.aiCoachMemory ?? "",
            isProfileCompleted: payload.isProfileCompleted ?? true,
            supplementModeLabel:
              SUPPLEMENT_MODES[payload.supplementPreference || currentProfile.supplementPreference] ||
              SUPPLEMENT_MODES.commercial,
            waterGoalGlasses: payload.waterGoalGlasses || currentProfile.waterGoalGlasses || baseWaterGlasses,
            preferredModel: normalizeModel(payload.preferredModel || currentProfile.preferredModel),
            termsAccepted: payload.termsAccepted ?? currentProfile.termsAccepted ?? true,
            last_sync: Date.now(),
          };"""

new_worker_save = """          const noWorkout = goalKey === "gain_bulk" || workoutDaysKey === "none";
          const finalWorkoutDays = goalKey === "gain_bulk" ? "none" : workoutDaysKey;
          const finalWorkoutPlace = noWorkout ? "none" : (payload.workoutPlace || currentProfile.workoutPlace || "bodyweight");

          // بررسی و اعطای ۳ روز اشتراک رایگان ضدتقلب (بر اساس اکانت + Device ID گوشی)
          const deviceId = String(payload.deviceId || request.headers.get("X-Device-ID") || "").trim();
          const deviceTrialKey = deviceId ? ("trial_3day_device:" + deviceId) : "";
          const deviceAlreadyClaimed = deviceTrialKey ? Boolean(await kv.get(deviceTrialKey)) : false;
          const userAlreadyClaimed = Boolean(currentProfile.freeTrialClaimed);
          let trialFields = {};
          if (!currentProfile.isAdmin && !isSubscriptionCurrentlyActive(currentProfile) && !userAlreadyClaimed && !deviceAlreadyClaimed) {
            const exp3d = Date.now() + (3 * 86400 * 1000);
            trialFields = {
              freeTrialClaimed: true,
              isFreeTrial: true,
              hasActiveSubscription: true,
              subscriptionTier: "اشتراک رایگان ۳ روزه هدیه ثبت‌نام 🎁",
              subscriptionDaysRemaining: 3,
              subscriptionExpiresAt: exp3d,
            };
            if (deviceTrialKey) {
              await kv.put(deviceTrialKey, userKey);
            }
          }

          const updatedProfile = {
            ...currentProfile,
            ...payload,
            ...trialFields,
            name: payload.name || payload.displayName || currentProfile.name || "رفیق ورزشکار",
            displayName: payload.displayName || payload.name || currentProfile.displayName || "رفیق ورزشکار",
            birthDate: payload.birthDate || currentProfile.birthDate || "",
            goal: goalKey,
            goalLabel: FITNESS_GOALS[goalKey] || goalKey,
            workoutDaysPerWeek: finalWorkoutDays,
            workoutDaysLabel: WORKOUT_DAYS_LABELS[finalWorkoutDays] || finalWorkoutDays,
            workoutPlace: finalWorkoutPlace,
            budgetTier: tierKey,
            economicStatus: tierKey,
            budgetTierLabel: BUDGET_TIERS[tierKey] || BUDGET_TIERS.base,
            aiCoachMemory: payload.aiCoachMemory ?? currentProfile.aiCoachMemory ?? "",
            isProfileCompleted: payload.isProfileCompleted ?? true,
            supplementModeLabel:
              SUPPLEMENT_MODES[payload.supplementPreference || currentProfile.supplementPreference] ||
              SUPPLEMENT_MODES.commercial,
            waterGoalGlasses: payload.waterGoalGlasses || currentProfile.waterGoalGlasses || baseWaterGlasses,
            preferredModel: normalizeModel(payload.preferredModel || currentProfile.preferredModel),
            termsAccepted: payload.termsAccepted ?? currentProfile.termsAccepted ?? true,
            last_sync: Date.now(),
          };"""

js = safe_replace_js(js, old_worker_save, new_worker_save, "Add 3-day free trial + Device ID anti-spam in /api/user/profile")

# 2.3 ادغام پروفایل ارسالی از کلاینت در درخواست‌های AI تا هیچ‌وقت اطلاعات فرم ناقص نره برای هوش مصنوعی
old_ai_body = """        const body = await request.json();
        let prompt = body.prompt || body.message || body.foodQuery || "";"""

new_ai_body = """        const body = await request.json();
        if (body.profile && typeof body.profile === "object") {
          Object.assign(profile, body.profile);
        }
        let prompt = body.prompt || body.message || body.foodQuery || "";"""

js = safe_replace_js(js, old_ai_body, new_ai_body, "Merge incoming client profile into AI context")

# 2.4 ارسال تمام فیلدهای فرم (جنسیت، سن، تاریخ تولد، محل تمرین یا بدون تمرین) به پرامپت هوش مصنوعی
old_sys_prompt_lines = """    "مشخصات کامل کاربر توی دیتابیس کلودفلر:",
    "- نام: " + (profile.displayName || profile.name || "رفیق"),
    "- هدف اصلی: " + goalDesc,
    "- تعداد روزهای تمرین در هفته: " + workoutDaysDesc,
    "- وزن فعلی: " + (profile.weightKg || profile.weight || "نامشخص") + " کیلوگرم | وزن هدف: " + (profile.targetWeightKg || "نامشخص") + " کیلوگرم | قد: " + (profile.heightCm || profile.height || "نامشخص") + " سانتی‌متر",
    "- میزان درآمد و بودجه ماهانه: " + budgetDesc,
    "- حافظه بلندمدت مربی (آسیب‌دیدگی، حساسیت غذایی، خواب و نکات شخصی): " + (profile.aiCoachMemory || "مورد خاصی ثبت نشده"),
    "- نوع مکمل انتخابی: " + suppDesc,
    "- هدف فعلی آب روزانه: " + String(profile.waterGoalGlasses || 8) + " لیوان در روز 💧","""

new_sys_prompt_lines = """    "مشخصات کامل کاربر توی دیتابیس کلودفلر:",
    "- نام: " + (profile.displayName || profile.name || "رفیق"),
    "- جنسیت: " + (profile.gender === "female" ? "خانم" : "آقا") + " | سن: " + String(profile.age || "نامشخص") + " سال | تاریخ تولد: " + String(profile.birthDate || "ثبت نشده"),
    "- هدف اصلی: " + goalDesc,
    "- تعداد روزهای تمرین در هفته: " + ((profile.goal === "gain_bulk" || profile.workoutDaysPerWeek === "none") ? "نیازی به تمرین ندارد (کاربر فعلاً ورزش نمی‌کند و فقط روی تغذیه تمرکز دارد)" : workoutDaysDesc),
    "- محل تمرین و تجهیزات: " + ((profile.goal === "gain_bulk" || profile.workoutDaysPerWeek === "none" || profile.workoutPlace === "none") ? "بدون تمرین ورزشی" : (profile.workoutPlace === "gym" ? "باشگاه بدنسازی کامل" : (profile.workoutPlace === "home_dumbbell" ? "در خانه با دمبل" : "در خانه بدون تجهیزات (وزن بدن)"))),
    "- وزن فعلی: " + (profile.weightKg || profile.weight || "نامشخص") + " کیلوگرم | وزن هدف: " + (profile.targetWeightKg || "نامشخص") + " کیلوگرم | قد: " + (profile.heightCm || profile.height || "نامشخص") + " سانتی‌متر",
    "- میزان درآمد و بودجه ماهانه: " + budgetDesc,
    "- حافظه بلندمدت مربی (آسیب‌دیدگی، حساسیت غذایی، خواب و نکات شخصی): " + (profile.aiCoachMemory || "مورد خاصی ثبت نشده"),
    "- نوع مکمل انتخابی: " + suppDesc,
    "- هدف فعلی آب روزانه: " + String(profile.waterGoalGlasses || 8) + " لیوان در روز 💧","""

js = safe_replace_js(js, old_sys_prompt_lines, new_sys_prompt_lines, "Send all form fields to AI system prompt")

with open(worker_path, "w", encoding="utf-8") as f:
    f.write(js)

# ============================================================================
# 3. BALANCE CHECK FOR lib/main.dart
# ============================================================================
def check_balance(src, filename):
    stack = []
    pairs = {')': '(', ']': '[', '}': '{'}
    in_s = in_d = in_lc = in_bc = esc = False
    line = 1
    i, n = 0, len(src)
    while i < n:
        ch = src[i]
        nxt = src[i + 1] if i + 1 < n else ''
        if ch == '\n':
            line += 1
            in_lc = False
            i += 1
            continue
        if in_lc:
            i += 1
            continue
        if in_bc:
            if ch == '*' and nxt == '/':
                in_bc = False
                i += 2
            else:
                i += 1
            continue
        if in_s:
            if esc: esc = False
            elif ch == '\\': esc = True
            elif ch == "'": in_s = False
            i += 1
            continue
        if in_d:
            if esc: esc = False
            elif ch == '\\': esc = True
            elif ch == '"': in_d = False
            i += 1
            continue
        if ch == '/' and nxt == '/':
            in_lc = True; i += 2; continue
        if ch == '/' and nxt == '*':
            in_bc = True; i += 2; continue
        if ch == "'": in_s = True; i += 1; continue
        if ch == '"': in_d = True; i += 1; continue
        if ch in '([{':
            stack.append((ch, line))
        elif ch in ')]}':
            if not stack or stack[-1][0] != pairs[ch]:
                return f"❌ [{filename}] عدم تطابق '{ch}' در خط {line} (باز مانده: {stack[-1] if stack else 'هیچ'})"
            stack.pop()
        i += 1
    if stack:
        return f"❌ [{filename}] پرانتز/آکولاد باز مانده: {stack[-1]}"
    return f"✅ [{filename}] تمام پرانتزها () و آکولادها {{}} ۱۰۰٪ تراز و سالم هستن! 🚀"

print(check_balance(dart, "lib/main.dart"))
print("🎉 جراحی هر دو فایل تموم شد! الان worker رو دیپلوی کن و گیت‌هاب رو پوش بزن! 🔥")
