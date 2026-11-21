import re

def read_file(p):
    with open(p, "r", encoding="utf-8") as f:
        return f.read()

def write_file(p, s):
    with open(p, "w", encoding="utf-8") as f:
        f.write(s)

# ==============================================================================
# 1. PATCH worker.js: Smart hasExistingProfile check for returning users (Sign In)
# ==============================================================================
w = read_file("worker.js")

old_init_ret = """  const parsed = JSON.parse(existingProfileRaw);
  return {
    profile: parsed,
    hasExistingProfile: Boolean(parsed.isProfileCompleted),
  };"""

new_init_ret = """  const parsed = JSON.parse(existingProfileRaw);
  const hasRealBirth = Boolean(parsed.birthDate && String(parsed.birthDate).trim().length >= 4);
  const hasRealName = Boolean(
    parsed.displayName &&
    String(parsed.displayName).trim().length > 0 &&
    String(parsed.displayName).trim() !== "رفیق ورزشکار" &&
    String(parsed.displayName).trim() !== "ورزشکار"
  );
  const isDone = Boolean(parsed.isProfileCompleted || hasRealBirth || (hasRealName && Number(parsed.heightCm) > 0 && Number(parsed.weightKg) > 0));
  if (isDone && !parsed.isProfileCompleted) {
    parsed.isProfileCompleted = true;
    await kv.put("profile:" + userKey, JSON.stringify(parsed));
  }
  return {
    profile: parsed,
    hasExistingProfile: isDone,
  };"""

if "hasRealBirth" not in w:
    assert old_init_ret in w, "❌ worker.js ensureUserInitialized anchor not found!"
    w = w.replace(old_init_ret, new_init_ret, 1)
    write_file("worker.js", w)
    print("✅ Patched worker.js: Returning users with saved profile won't see Sign Up form again!")
else:
    print("ℹ️ worker.js already patched")

# ==============================================================================
# 2. PATCH lib/main.dart
# ==============================================================================
d = read_file("lib/main.dart")

# 2A. Add _previewPhase state field right next to _currentSet
if "String? _previewPhase;" not in d:
    m_set = re.search(r'(int _currentSet\s*=\s*1;)', d)
    assert m_set, "❌ Could not find int _currentSet = 1; in lib/main.dart"
    d = d[:m_set.end()] + "\n  String? _previewPhase;" + d[m_set.end():]
    print("✅ Patched lib/main.dart: Added _previewPhase state for Live Gym phase switcher")

# 2B. Make the 3 phase buttons clickable + show phase exercise list + Refresh button to return to active step
phase_row_pattern = re.compile(
    r"Row\(\s*children:\s*\[\s*_buildPhaseBadge\(\s*title:\s*'۱\. گرم کردن 🔥'[\s\S]*?_buildPhaseBadge\(\s*title:\s*'۳\. سرد کردن ❄️'[\s\S]*?\),\s*\],\s*\)",
    re.MULTILINE
)

interactive_phase_ui = r'''Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _previewPhase = (_previewPhase == 'warmup') ? null : 'warmup'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                      decoration: BoxDecoration(
                        color: (_previewPhase == 'warmup' || (_previewPhase == null && activeStep.phase == 'warmup'))
                            ? BMColors.flameOrange.withOpacity(0.22)
                            : bmSurfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (_previewPhase == 'warmup' || (_previewPhase == null && activeStep.phase == 'warmup'))
                              ? BMColors.flameOrange
                              : bmBorderColor,
                          width: _previewPhase == 'warmup' ? 1.8 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '۱. گرم کردن 🔥',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: (_previewPhase == 'warmup' || (_previewPhase == null && activeStep.phase == 'warmup'))
                              ? BMColors.flameOrange
                              : bmTextSubColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _previewPhase = (_previewPhase == 'main') ? null : 'main'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                      decoration: BoxDecoration(
                        color: (_previewPhase == 'main' || (_previewPhase == null && activeStep.phase == 'main'))
                            ? BMColors.neonCyan.withOpacity(0.22)
                            : bmSurfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (_previewPhase == 'main' || (_previewPhase == null && activeStep.phase == 'main'))
                              ? BMColors.neonCyan
                              : bmBorderColor,
                          width: _previewPhase == 'main' ? 1.8 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '۲. ست‌های اصلی 💪',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: (_previewPhase == 'main' || (_previewPhase == null && activeStep.phase == 'main'))
                              ? BMColors.neonCyan
                              : bmTextSubColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _previewPhase = (_previewPhase == 'cooldown') ? null : 'cooldown'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                      decoration: BoxDecoration(
                        color: (_previewPhase == 'cooldown' || (_previewPhase == null && activeStep.phase == 'cooldown'))
                            ? BMColors.electricBlue.withOpacity(0.22)
                            : bmSurfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (_previewPhase == 'cooldown' || (_previewPhase == null && activeStep.phase == 'cooldown'))
                              ? BMColors.electricBlue
                              : bmBorderColor,
                          width: _previewPhase == 'cooldown' ? 1.8 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '۳. سرد کردن ❄️',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: (_previewPhase == 'cooldown' || (_previewPhase == null && activeStep.phase == 'cooldown'))
                              ? BMColors.electricBlue
                              : bmTextSubColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_previewPhase != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bmCardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BMColors.neonCyan.withOpacity(0.55)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _previewPhase == 'warmup'
                              ? '📋 لیست تمرین‌های گرم کردن 🔥'
                              : (_previewPhase == 'main'
                                  ? '📋 لیست ست‌های اصلی امروز 💪'
                                  : '📋 لیست تمرین‌های سرد کردن ❄️'),
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: BMColors.neonCyan),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _previewPhase = null),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: BMColors.neonGreen.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: BMColors.neonGreen),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh_rounded, size: 15, color: BMColors.neonGreen),
                                const SizedBox(width: 4),
                                Text(
                                  'تمرین فعلی',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: BMColors.neonGreen),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(steps.length, (i) {
                      if (steps[i].phase != _previewPhase) return const SizedBox.shrink();
                      final isNow = i == safeIdx;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isNow ? BMColors.neonGreen.withOpacity(0.14) : bmSurfaceColor,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: isNow ? BMColors.neonGreen : bmBorderColor),
                        ),
                        child: Row(
                          children: [
                            Text(
                              isNow ? '▶️ ' : '${i + 1}. ',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: isNow ? BMColors.neonGreen : bmTextColor),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bmExStr(i, 'title', steps[i].name),
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: bmTextColor),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${steps[i].sets} ست • ${steps[i].repsOrDuration} • ${bmExStr(i, 'muscle', steps[i].muscleGroup)}',
                                    style: TextStyle(fontSize: 11, color: bmTextSubColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        )'''

if "لیست تمرین‌های گرم کردن" not in d:
    d, n_phase = phase_row_pattern.subn(interactive_phase_ui, d, count=1)
    assert n_phase == 1, "❌ Could not match the 3 phase buttons Row in Live Gym!"
    print("✅ Patched lib/main.dart: Made all 3 phase buttons interactive + Refresh button to return to current exercise!")

# 2C. Guarantee BmExerciseDemoBox is inserted right below muscleGroup in Live Gym
if "BmExerciseDemoBox(" not in d:
    gym_muscle_pat = re.compile(
        r"(Text\(\s*'🎯 عضله هدف: \$\{bmExStr\(safeIdx, 'muscle', activeStep\.muscleGroup\)\} • تکرار: \$\{activeStep\.repsOrDuration\}',\s*style:\s*TextStyle\(fontSize:\s*12\.5,\s*color:\s*bmTextSubColor\),\s*\),\s*const SizedBox\(height:\s*12\),)",
        re.MULTILINE
    )
    demo_snippet = r"""\1
              BmExerciseDemoBox(
                exerciseName: bmExStr(safeIdx, 'title', activeStep.name),
                muscleGroup: bmExStr(safeIdx, 'muscle', activeStep.muscleGroup),
                allTodayNames: List.generate(steps.length, (i) => bmExStr(i, 'title', steps[i].name)),
              ),
              const SizedBox(height: 12),"""
    d, n_demo = gym_muscle_pat.subn(demo_snippet, d, count=1)
    assert n_demo == 1, "❌ Could not insert BmExerciseDemoBox in Live Gym!"
    print("✅ Patched lib/main.dart: Inserted BmExerciseDemoBox + Offline Download in Live Gym!")

# 2D. Fix profile form clearing fields when profile is already completed
d = d.replace(
    "final bool isFreshSignUp = widget.isInsidePopup || !p.isProfileCompleted;",
    "final bool isFreshSignUp = !p.isProfileCompleted;"
)

# 2E. Referral messages: Remove matin-mohammadi.ir link, use Account ID code with backticks for one-tap copy in Telegram/Eitaa/Rubika
old_ref1 = "final inviteMsg = 'رفیق بیا توی برنامه بادی‌مود (مربی هوشمند بدنسازی و تغذیه)! 💪🔥 به محض ورود ۱ روز اشتراک رایگان می‌گیری و موقع خرید اشتراک فاز بتا هم کد دعوت من ($myCode) رو بزن تا ۳۰٪ تخفیف بگیری (۳۴۹,۳۰۰ تومن به جای ۴۹۹,۰۰۰ تومن)! 🚀\\nhttps://matin-mohammadi.ir/?ref=$myCode';"
new_ref1 = "final inviteMsg = 'رفیق بیا توی برنامه بادی‌مود (مربی هوشمند بدنسازی و تغذیه)! 💪🔥\\nبه محض ورود ۱ روز اشتراک رایگان می‌گیری و موقع خرید اشتراک هم این کد دعوت (آیدی اکانت من) رو داخل برنامه بزن تا ۳۰٪ تخفیف بگیری (۳۴۹,۳۰۰ تومن به جای ۴۹۹,۰۰۰ تومن)! 🚀\\n\\nکد دعوت من (روش بزن تا کپی بشه 👇):\\n`$myCode`';"

old_ref2 = "'رفیق بیا توی برنامه بادی‌مود (مربی هوشمند بدنسازی و تغذیه)! 💪🔥 موقع خرید اشتراک کد دعوت من ($myCode) رو بزن تا ۳۰٪ تخفیف بگیری (۳۴۹,۳۰۰ تومن به جای ۴۹۹,۰۰۰ تومن)! 🚀\\nhttps://matin-mohammadi.ir/?ref=$myCode';"
new_ref2 = "'رفیق بیا توی برنامه بادی‌مود (مربی هوشمند بدنسازی و تغذیه)! 💪🔥\\nموقع خرید اشتراک این کد دعوت (آیدی اکانت من) رو داخل برنامه وارد کن تا ۳۰٪ تخفیف بگیری (۳۴۹,۳۰۰ تومن به جای ۴۹۹,۰۰۰ تومن)! 🚀\\n\\nکد دعوت من (روش بزن تا کپی بشه 👇):\\n`$myCode`';"

c1 = old_ref1 in d
c2 = old_ref2 in d
d = d.replace(old_ref1, new_ref1)
d = d.replace(old_ref2, new_ref2)
d = d.replace("کپی لینک و کد دعوت", "کپی کد دعوت 👆")
d = d.replace("متن و لینک دعوت اختصاصیت کپی شد!", "کد دعوت اختصاصیت کپی شد!")
d = d.replace("مثلاً BM-586834 یا لینک دعوت", "کد دعوت (آیدی اکانت) رفیقت رو بزن (مثلاً BM-586834)")
print(f"✅ Patched lib/main.dart: Referral one-tap backtick code updated (ref1={c1}, ref2={c2})")

write_file("lib/main.dart", d)
print("\n🎉 ALL V9 PATCHES VERIFIED & APPLIED!")
