with open("lib/main.dart", "r", encoding="utf-8") as f:
    d = f.read()

# 1. Lock & hide Live Gym UI until logged in + subscribed + AI workout plan generated
gym_anchor = """    Color phaseColor = BMColors.neonCyan;
    if (activeStep.phase == 'warmup') {
      phaseColor = BMColors.flameOrange;
    } else if (activeStep.phase == 'cooldown') {
      phaseColor = BMColors.electricBlue;
    }

    return ListView("""

gym_locked_gate = r"""    Color phaseColor = BMColors.neonCyan;
    if (activeStep.phase == 'warmup') {
      phaseColor = BMColors.flameOrange;
    } else if (activeStep.phase == 'cooldown') {
      phaseColor = BMColors.electricBlue;
    }

    final bool canAccessGym = c.profile.isAdmin ||
        (c.profile.isLoggedIn && c.profile.hasActiveSubscription);
    final bool noWorkoutInForm =
        bmGlobalDaysPerWeek <= 0 || c.profile.workoutDaysPerWeek == 'none';
    final bool gymQuotaExhausted =
        !c.profile.isAdmin && bmIsWorkoutQuotaExhausted();

    if (!canAccessGym || bmAiCustomWorkouts.isEmpty) {
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
                  !canAccessGym ? '🔒🏋️‍♂️' : '🏋️‍♂️🤖',
                  style: const TextStyle(fontSize: 42),
                ),
                const SizedBox(height: 12),
                Text(
                  !canAccessGym
                      ? 'باشگاه زنده قفله رفیق!'
                      : 'هنوز برنامه ورزشی اختصاصیت رو دریافت نکردی!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                    color: bmTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  !canAccessGym
                      ? 'برای دریافت برنامه ورزشی اختصاصی و باز شدن باشگاه زنده، اول از تب پروفایل وارد حسابت شو و اشتراکت رو فعال کن! 💪🔥'
                      : 'روی دکمه زیر بزن تا مربی هوشمند بر اساس تجهیزات و هدف تو، برنامه ورزشی اختصاصی این هفته‌ت رو بسازه (سهمیه: هفته‌ای ۱ بار).',
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
                    onPressed: (!canAccessGym ||
                            noWorkoutInForm ||
                            gymQuotaExhausted ||
                            bmIsGeneratingWorkout)
                        ? null
                        : () => bmGenerateAiWorkoutPlan(
                              context,
                              onDone: () {
                                if (mounted) setState(() {});
                              },
                            ),
                    icon: bmIsGeneratingWorkout
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.fitness_center_rounded, size: 19),
                    label: Text(
                      !canAccessGym
                          ? 'ابتدا وارد شو و اشتراک رو فعال کن 🔒'
                          : (noWorkoutInForm
                              ? 'ورزش نداری رفیق 😅'
                              : (gymQuotaExhausted
                                  ? 'سهمیه‌ت تموم شده رفیق 😉'
                                  : (bmIsGeneratingWorkout
                                      ? 'در حال ساخت برنامه ورزشی... ⏳'
                                      : 'دریافت/تمدید برنامه ورزشی'))),
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

    return ListView("""

assert gym_anchor in d, "❌ gym_anchor پیدا نشد!"
d = d.replace(gym_anchor, gym_locked_gate, 1)
print("✅ 1. باشگاه زنده قفل و مخفی شد + دکمه دریافت/تمدید برنامه ورزشی اضافه شد!")

# Rename inside-gym AI button too
d = d.replace("'🤖 بروزرسانی با AI'", "'دریافت/تمدید برنامه ورزشی'")

# 2. Rename Weekly Meal Plan button
d = d.replace(
    "'درخواست چینش مجدد برنامه ۷ روزه متنوع از AI 🔄'",
    "'دریافت/تمدید برنامه غذایی'"
)
d = d.replace(
    "'دریافت برنامه غذایی ۷ روزه متنوع از هوش مصنوعی 🚀'",
    "'دریافت/تمدید برنامه غذایی'"
)
print("✅ 2. اسم دکمه برنامه غذایی شد: دریافت/تمدید برنامه غذایی")

# 3. Insert lightweight Google search hint box right below muscleGroup in Live Gym
muscle_anchor = """              Text(
                '🎯 عضله هدف: ${bmExStr(safeIdx, 'muscle', activeStep.muscleGroup)} • تکرار: ${activeStep.repsOrDuration}',
                style: TextStyle(fontSize: 12.5, color: bmTextSubColor),
              ),
              const SizedBox(height: 12),"""

google_hint_box = muscle_anchor + r"""
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: bmSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BMColors.neonCyan.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Text('🔍', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'میتونی اسم تمرین رو توی گوگل سرچ کنی و ببینی چطوری انجام میشه',
                        style: TextStyle(
                          fontSize: 11.8,
                          fontWeight: FontWeight.w700,
                          color: bmTextSubColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),"""

assert muscle_anchor in d, "❌ خط عضله هدف در باشگاه زنده پیدا نشد!"
d = d.replace(muscle_anchor, google_hint_box, 1)
print("✅ 3. راهنمای سرچ گوگل زیر هر حرکت اضافه شد!")

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(d)

print("\n🎉 همه‌چیز ۱۰۰٪ تراز و آماده انتشار شد!")
