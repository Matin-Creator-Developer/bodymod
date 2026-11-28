import os
import shutil

WORKER_PATH = os.path.expanduser("~/bodymod/worker.js")
DART_PATH = os.path.expanduser("~/bodymod/lib/main.dart")

def patch_file(path, replacements, label):
    if not os.path.exists(path):
        print(f"❌ فایل پیدا نشد: {path}")
        return
    shutil.copy2(path, path + ".bak")
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    ok_count = 0
    for name, old, new in replacements:
        if old in content:
            content = content.replace(old, new, 1)
            print(f"✅ [{label}] {name} انجام شد.")
            ok_count += 1
        else:
            print(f"⚠️ [{label}] بخش «{name}» پیدا نشد (شاید قبلاً تغییر کرده).")

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"💾 فایل {label} ذخیره شد ({ok_count}/{len(replacements)} تغییر). بکاپ: {path}.bak\n")

# --- 1. تغییرات بک‌اند (worker.js) ---
worker_helper = """
async function bmSavePendingReferral(kv, userKey, deviceId, rawRefCode) {
  try {
    let clean = String(rawRefCode || '').replace(/`/g, '').trim().toUpperCase();
    const m = clean.match(/[?&]REF=([^&\\s]+)/i);
    if (m && m[1]) clean = m[1].toUpperCase();
    if (/^\\d{11}$/.test(clean)) clean = 'BM-' + clean;
    if (!/^BM-\\d{6,11}$/.test(clean)) return;
    if (deviceId) {
      const ownerDev = await kv.get('ref_owner_device:' + clean);
      if (ownerDev && ownerDev === deviceId) return;
    }
    const ownAcc = await kv.get('ACCOUNT_ID_OF_' + String(userKey));
    if (ownAcc && ownAcc.toUpperCase() === clean) return;
    const already = await kv.get('REF_PENDING_USER_' + String(userKey));
    if (!already) {
      await kv.put('REF_PENDING_USER_' + String(userKey), clean);
      const u6 = bmExtractLast6(userKey);
      if (u6 && u6.length >= 4) {
        await kv.put('REF_USED_BY_' + u6, clean);
      }
    }
  } catch (_) {}
}

async function bmGrantReferralOnProfileComplete(kv, userKey, deviceId, inviteeName) {
  try {
    const rewardedKey = 'REF_FORM_REWARDED_' + String(userKey);
    if (await kv.get(rewardedKey)) return;
    const refCode = await kv.get('REF_PENDING_USER_' + String(userKey));
    if (!refCode) return;
    if (deviceId) {
      const ownerDev = await kv.get('ref_owner_device:' + refCode);
      if (ownerDev && ownerDev === deviceId) return;
    }
    let inviterUserKey = await kv.get('REF_OWNER_' + refCode);
    const inv6 = bmExtractLast6(refCode);
    if (!inviterUserKey && inv6) {
      inviterUserKey = await kv.get('REF_OWNER_' + inv6);
    }
    if (!inviterUserKey || inviterUserKey === String(userKey)) return;

    const inviterAccId = await bmGetOrCreateAccountId(kv, inviterUserKey);
    const listKey = 'REF_INVITED_LIST_' + String(inviterAccId).toUpperCase();
    let invitedList = [];
    try {
      const rawList = await kv.get(listKey);
      if (rawList) invitedList = JSON.parse(rawList);
      if (!Array.isArray(invitedList)) invitedList = [];
    } catch (_) { invitedList = []; }

    const cleanName = String(inviteeName || '').trim() || 'رفیق ورزشکار';
    invitedList.unshift({ name: cleanName });
    await kv.put(listKey, JSON.stringify(invitedList.slice(0, 500)));

    const prevCnt = parseInt((await kv.get('REF_INVITED_CNT_' + inv6)) || '0', 10) || 0;
    const prevDays = parseInt((await kv.get('REF_BONUS_DAYS_' + inv6)) || '0', 10) || 0;
    const prevUntil = parseInt((await kv.get('REF_VIP_UNTIL_' + inv6)) || '0', 10) || 0;
    const baseT = prevUntil > Date.now() ? prevUntil : Date.now();
    const newUntil = baseT + (3 * 86400 * 1000);

    await kv.put('REF_INVITED_CNT_' + inv6, String(prevCnt + 1));
    await kv.put('REF_BONUS_DAYS_' + inv6, String(prevDays + 3));
    await kv.put('REF_VIP_UNTIL_' + inv6, String(newUntil));
    await kv.put(rewardedKey, 'true');

    const invRaw = await kv.get('profile:' + inviterUserKey);
    if (invRaw) {
      const invProfile = JSON.parse(invRaw);
      const curExp = Number(invProfile.subscriptionExpiresAt) || 0;
      const invBase = curExp > Date.now() ? curExp : Date.now();
      invProfile.subscriptionExpiresAt = invBase + (3 * 86400 * 1000);
      invProfile.hasActiveSubscription = true;
      invProfile.subscriptionDaysRemaining = Math.ceil((invProfile.subscriptionExpiresAt - Date.now()) / 86400000);
      if (!invProfile.subscriptionTier || invProfile.subscriptionTier === 'بدون اشتراک') {
        invProfile.subscriptionTier = 'هدیه ۳ روزه دعوت از دوست 🎁';
      }
      await kv.put('profile:' + inviterUserKey, JSON.stringify(invProfile));
    }
  } catch (_) {}
}
"""

invited_list_route = """    // --- روت لیست دعوت شدگان (فقط نام و تعداد بر اساس Account ID) ---
    if (request.url.includes('/api/referral/invited-list')) {
      const corsH = { 'Content-Type': 'application/json; charset=utf-8', 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'GET, OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-User-ID, X-Device-ID' };
      if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsH });
      const user = await authenticateRequest(request, env, new URL(request.url));
      if (!user) {
        return new Response(JSON.stringify({ ok: false, error: 'اول وارد حسابت شو رفیق! 🔐' }), { status: 401, headers: corsH });
      }
      const kvInv = getSafeKv(env);
      const uKey = getUserKey(user);
      const accId = await bmGetOrCreateAccountId(kvInv, uKey);
      const rawList = await kvInv.get('REF_INVITED_LIST_' + String(accId).toUpperCase());
      let list = [];
      try {
        if (rawList) list = JSON.parse(rawList);
        if (!Array.isArray(list)) list = [];
      } catch (_) { list = []; }
      const safeNames = list.map((x) => ({ name: String((x && x.name) ? x.name : 'رفیق ورزشکار') }));
      return new Response(JSON.stringify({ ok: true, count: safeNames.length, invited: safeNames }), { status: 200, headers: corsH });
    }

"""

worker_replacements = [
    (
        "اضافه کردن توابع کمکی رفرال و لیست دعوت‌شدگان",
        "// --- [END BETA & REFERRAL ENGINE] ---",
        worker_helper + "\n// --- [END BETA & REFERRAL ENGINE] ---"
    ),
    (
        "اضافه کردن روت /api/referral/invited-list",
        "    // --- روت شمارش معکوس ۱۰۰۰ نفر بتا، دعوت دوست، ۱ روز هدیه ثبت‌نام و کنترل ورژن ---",
        invited_list_route + "    // --- روت شمارش معکوس ۱۰۰۰ نفر بتا، دعوت دوست، ۱ روز هدیه ثبت‌نام و کنترل ورژن ---"
    ),
    (
        "ثبت کد دعوت در ورود با گوگل",
        """        if (gnDevId && initResult.profile && initResult.profile.accountId) {
          await kv.put("ref_owner_device:" + String(initResult.profile.accountId).toUpperCase(), gnDevId);
        }""",
        """        if (gnDevId && initResult.profile && initResult.profile.accountId) {
          await kv.put("ref_owner_device:" + String(initResult.profile.accountId).toUpperCase(), gnDevId);
        }
        if (!initResult.hasExistingProfile && (body.referralCode || body.referral_code)) {
          await bmSavePendingReferral(kv, userData.email, gnDevId, body.referralCode || body.referral_code);
        }"""
    ),
    (
        "ثبت کد دعوت در ورود با موبایل",
        """        if (oDevId && initResult.profile && initResult.profile.accountId) {
          await kv.put("ref_owner_device:" + String(initResult.profile.accountId).toUpperCase(), oDevId);
        }""",
        """        if (oDevId && initResult.profile && initResult.profile.accountId) {
          await kv.put("ref_owner_device:" + String(initResult.profile.accountId).toUpperCase(), oDevId);
        }
        if (!initResult.hasExistingProfile && (body.referralCode || body.referral_code)) {
          await bmSavePendingReferral(kv, normalizedPhone, oDevId, body.referralCode || body.referral_code);
        }"""
    ),
    (
        "اعطای ۳ روز هدیه و ثبت در لیست دعوت‌شدگان هنگام تکمیل فرم",
        """          const enriched = enrichProfileWithAccessAndLocks(updatedProfile, user);
          await kv.put("profile:" + userKey, JSON.stringify(enriched));
          const quotas = await getUserQuotaStatus(kv, userKey, enriched.isAdmin);""",
        """          const enriched = enrichProfileWithAccessAndLocks(updatedProfile, user);
          await kv.put("profile:" + userKey, JSON.stringify(enriched));
          await bmGrantReferralOnProfileComplete(kv, userKey, deviceId, enriched.displayName || enriched.name);
          const quotas = await getUserQuotaStatus(kv, userKey, enriched.isAdmin);"""
    ),
]

# --- 2. تغییرات فرانت‌اند (lib/main.dart) ---
invited_sheet_dart = """  void _showInvitedUsersSheet(BuildContext context, BodyModController c) {
    if (!c.profile.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رفیق اول وارد حسابت شو تا لیست دعوت‌شدگانت رو ببینی! 🔐')),
      );
      return;
    }
    bmShowResponsiveSheet(
      context: context,
      backgroundColor: BMColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => FutureBuilder<http.Response>(
        future: http
            .get(
              Uri.parse('${AppConfig.serverBaseUrl}/api/referral/invited-list'),
              headers: c._authHeaders,
            )
            .timeout(const Duration(seconds: 12)),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          int totalCount = 0;
          List<String> names = [];
          String? errText;
          if (snap.hasError || !snap.hasData) {
            errText = 'خطا در ارتباط با سرور کلودفلر! اینترنتت رو چک کن 🌐';
          } else if (snap.data!.statusCode == 200) {
            try {
              final d = jsonDecode(utf8.decode(snap.data!.bodyBytes));
              if (d is Map && d['ok'] == true) {
                totalCount = (d['count'] as num?)?.toInt() ?? 0;
                final rawInv = d['invited'];
                if (rawInv is List) {
                  names = rawInv
                      .map((e) => (e is Map ? (e['name'] ?? 'رفیق ورزشکار') : e).toString())
                      .toList();
                }
              } else {
                errText = (d is Map ? (d['error'] ?? 'خطا در دریافت لیست') : 'خطا در دریافت لیست').toString();
              }
            } catch (_) {
              errText = 'خطا در خواندن اطلاعات سرور!';
            }
          } else {
            errText = 'خطا در دریافت لیست (کد ${snap.data!.statusCode})';
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('👥🎁 ', style: TextStyle(fontSize: 22)),
                    Expanded(
                      child: Text(
                        'لیست دعوت شدگان ($totalCount نفر)',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: bmTextColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close_rounded, color: bmTextSubColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (errText != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      errText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  )
                else if (names.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'هنوز کسی با کد دعوت تو ثبت‌نام و تکمیل فرم نکرده رفیق! 😅\nکد دعوتت رو بفرست برای دوستات تا هم اونا تخفیف بگیرن هم تو ۳ روز رایگان! 🚀',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: bmTextSubColor, fontSize: 13, height: 1.6),
                    ),
                  )
                else
                  ...List.generate(names.length, (i) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: bmSurfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: BMColors.neonCyan.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: BMColors.neonGreen.withOpacity(0.2),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: BMColors.neonGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              names[i],
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: bmTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

"""

dart_replacements = [
    (
        "تغییر متن حریم خصوصی در راهنمای حافظه مربی",
        "'(خیالت راحت رفیق، این اطلاعات کاملاً امن هستن 🔒)';",
        "'🔒 خیالت راحت رفیق! اطلاعاتت و حریم خصوصیت به صورت ۱۰۰٪ امن محافظت میشه.';"
    ),
    (
        "اضافه کردن پارامتر referralCode به ورود گوگل",
        """  Future?> loginWithNativeGoogle(
    BuildContext context,
  ) async {""",
        """  Future?> loginWithNativeGoogle(
    BuildContext context, {
    String referralCode = '',
  }) async {"""
    ),
    (
        "ارسال referralCode به سرور در ورود گوگل",
        """              'photo_url': account.photoUrl ?? '',
              'deviceId': deviceId,
            }),""",
        """              'photo_url': account.photoUrl ?? '',
              'deviceId': deviceId,
              if (referralCode.trim().isNotEmpty) 'referralCode': referralCode.trim(),
            }),"""
    ),
    (
        "اضافه کردن پارامتر referralCode به تایید OTP موبایل",
        """  Future> verifyPhoneOtp(
    BuildContext context, {
    required String rawPhone,
    required String otpCode,
  }) async {""",
        """  Future> verifyPhoneOtp(
    BuildContext context, {
    required String rawPhone,
    required String otpCode,
    String referralCode = '',
  }) async {"""
    ),
    (
        "ارسال referralCode به سرور در تایید OTP موبایل",
        """              'otpToken': _lastOtpStatelessToken,
              'deviceId': deviceId,
            }),""",
        """              'otpToken': _lastOtpStatelessToken,
              'deviceId': deviceId,
              if (referralCode.trim().isNotEmpty) 'referralCode': referralCode.trim(),
            }),"""
    ),
    (
        "اضافه کردن کنترلر کد دعوت به پاپ‌آپ ثبت‌نام",
        """  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();""",
        """  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();
  final TextEditingController _refCodeCtrl = TextEditingController();"""
    ),
    (
        "dispose کردن کنترلر کد دعوت",
        """    _phoneCtrl.dispose();
    _otpCtrl.dispose();""",
        """    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _refCodeCtrl.dispose();"""
    ),
    (
        "اضافه کردن کادر کد دعوت و هشدار گوگل در پاپ‌آپ ثبت‌نام",
        """            // روش اول: ورود نیتیو با گوگل (Google Sign-In)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BMColors.neonCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        final res = await c.loginWithNativeGoogle(context);""",
        """            // فیلد اختیاری کد دعوت + هشدار مهم قبل از ورود
            TextField(
              controller: _refCodeCtrl,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'کد دعوت دوستت (اختیاری - مثلاً BM-12345678910)',
                prefixIcon: Icon(Icons.card_giftcard_rounded),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: BMColors.warningAmber.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BMColors.warningAmber.withOpacity(0.6)),
              ),
              child: Text(
                '⚠️ اگه کد دعوت داری و میخای از گوگل استفاده کنی، قبل از زدن دکمه گوگل باید کد دعوتت رو بزنی وگرنه دیگه نمیتونی کد بزنی',
                style: TextStyle(
                  fontSize: 11.8,
                  fontWeight: FontWeight.w800,
                  color: BMColors.warningAmber,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // روش اول: ورود نیتیو با گوگل (Google Sign-In)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BMColors.neonCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        final res = await c.loginWithNativeGoogle(
                          context,
                          referralCode: _refCodeCtrl.text.trim(),
                        );"""
    ),
    (
        "پاس دادن کد دعوت در تایید OTP موبایل",
        """                          final res = await c.verifyPhoneOtp(
                            context,
                            rawPhone: phone,
                            otpCode: code,
                          );""",
        """                          final res = await c.verifyPhoneOtp(
                            context,
                            rawPhone: phone,
                            otpCode: code,
                            referralCode: _refCodeCtrl.text.trim(),
                          );"""
    ),
    (
        "اضافه کردن گزینه «لیست دعوت شدگان» بالای پنل مدیرعامل در منوی همبرگری",
        """            // فقط اگر کلودفلر تایید کند که کاربر مدیرعامل است، گزینه پنل مدیرعامل نمایش داده می‌شود!
            if (c.profile.isAdmin) ...[""",
        """            ListTile(
              leading: Icon(
                Icons.people_alt_rounded,
                color: BMColors.neonCyan,
              ),
              title: const Text(
                'لیست دعوت شدگان 👥',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'مشاهده اسم و تعداد دوستانی که با کد تو اومدن',
                style: TextStyle(fontSize: 11.5),
              ),
              onTap: () {
                Navigator.pop(context);
                _showInvitedUsersSheet(context, c);
              },
            ),
            // فقط اگر کلودفلر تایید کند که کاربر مدیرعامل است، گزینه پنل مدیرعامل نمایش داده می‌شود!
            if (c.profile.isAdmin) ...["""
    ),
    (
        "اضافه کردن پنجره لیست دعوت شدگان",
        "  void _showReferralInviteSheet(BuildContext context, BodyModController c) {",
        invited_sheet_dart + "  void _showReferralInviteSheet(BuildContext context, BodyModController c) {"
    ),
    (
        "آپدیت متن پاپ‌آپ دعوت از دوست",
        "• به محض اینکه دوستت اشتراک بخره، ۳ روز اشتراک رایگان به حساب تو اضافه می‌شه! 🚀💎",
        "• به محض اینکه دوستت با کد تو ثبت‌نام کنه و فرم مشخصاتش رو کامل کنه، ۳ روز اشتراک رایگان به حساب تو اضافه می‌شه! 🚀💎"
    ),
    (
        "حذف کادر وارد کردن کد دعوت از پایین پاپ‌آپ دعوت از دوست",
        """                const Divider(height: 24),
                Text(
                  'کد یا لینک دعوت دوستت رو داری؟ اینجا بزن تا ۳۰٪ تخفیف اشتراک بگیری 👇',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: bmTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: bmRefInputCtrl,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(fontSize: 12.5, color: bmTextColor),
                        decoration: InputDecoration(
                          hintText: bmAppliedRefCode.isNotEmpty
                              ? 'کد فعال: $bmAppliedRefCode (۳۰٪ تخفیف)'
                              : 'کد دعوت (آیدی اکانت) رفیقت رو بزن (مثلاً BM-12345678910)',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bmYellowBoxColor,
                        foregroundColor: bmOnYellowBoxColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: bmRefSubmitting
                          ? null
                          : () async {
                              if (!c.profile.isLoggedIn) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('رفیق اول با گوگل یا شماره موبایل وارد حسابت شو! 🔐'),
                                  ),
                                );
                                return;
                              }
                              bmUserPhoneGlobal = c.profile.userKey;
                              await bmSubmitFriendReferralCode(ctx, () {
                                if (ctx.mounted) setSheetState(() {});
                              });
                              if (bmAppliedRefCode.isNotEmpty) {
                                c.appliedDiscountCode = bmAppliedRefCode;
                                c.appliedDiscountPercent = 30;
                                c.discountedSubscriptionPriceToman = 349300;
                                c.notifyListeners();
                              }
                            },
                      child: Text(
                        bmRefSubmitting ? '...' : 'اعمال ۳۰٪ تخفیف',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: bmOnYellowBoxColor,
                        ),
                      ),
                    ),
                  ],
                ),""",
        ""
    ),
]

patch_file(WORKER_PATH, worker_replacements, "worker.js")
patch_file(DART_PATH, dart_replacements, "main.dart")
print("🚀 تموم شد رفیق! همه تغییرات با موفقیت اعمال شدن.")
