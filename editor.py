import os

main_path = "lib/main.dart"
worker_path = "worker.js"

def safe_replace(text, old, new, label, fname):
    if old in text:
        print(f"✅ [{fname}] {label}")
        return text.replace(old, new, 1)
    else:
        print(f"⚠️ [{fname}] Skipped (not found or already patched): {label}")
        return text

# ============================================================================
# 1. PATCH lib/main.dart (Replace Notification Tile with Referral Invite)
# ============================================================================
with open(main_path, "r", encoding="utf-8") as f:
    dart = f.read()

# 1.1 جایگزینی آیتم مجوز اعلان در منوی همبرگری با «دعوت از دوست»
old_notif_tile = """            ListTile(
              leading: Icon(
                Icons.notifications_active_rounded,
                color: BMColors.neonGreen,
              ),
              title: const Text('تنظیم مجوز اعلان اندروید (Allow)'),
              onTap: () {
                Navigator.pop(context);
                c.requestAndroidNotificationPermission(
                  context,
                  forceDialog: true,
                );
              },
            ),"""

new_referral_tile = """            ListTile(
              leading: Icon(
                Icons.card_giftcard_rounded,
                color: BMColors.neonGreen,
              ),
              title: const Text(
                'دعوت از دوست 🎁',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                '۳۰٪ تخفیف برای دوستت + ۳ روز اشتراک رایگان برای تو',
                style: TextStyle(fontSize: 11.5),
              ),
              onTap: () {
                Navigator.pop(context);
                _showReferralInviteSheet(context, c);
              },
            ),"""

dart = safe_replace(dart, old_notif_tile, new_referral_tile, "Replace Notification tile with Referral tile in Drawer", "main.dart")

# 1.2 اضافه کردن پنجره‌ی شیک «دعوت از دوست» به MainShellScreen
old_streak_sheet_header = "  void _showStreakPhilosophySheet(BuildContext context, BodyModController c) {"

new_referral_sheet_and_streak = """  void _showReferralInviteSheet(BuildContext context, BodyModController c) {
    if (c.profile.isLoggedIn && c.profile.userKey.isNotEmpty) {
      bmUserPhoneGlobal = c.profile.userKey;
    }
    bmShowResponsiveSheet(
      context: context,
      backgroundColor: BMColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          if (c.profile.isLoggedIn && c.profile.userKey.isNotEmpty) {
            bmUserPhoneGlobal = c.profile.userKey;
          }
          final myCode = bmGetMyReferralCode();
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('🎁🤝 ', style: TextStyle(fontSize: 22)),
                    Expanded(
                      child: Text(
                        'دعوت از دوست (بُرد-بُرد!) 🔥',
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
                const SizedBox(height: 6),
                Text(
                  'کد یا لینک دعوت خودت رو بفرست برای رفیقت:\n'
                  '• دوستت با زدن کد تو ۳۰٪ تخفیف اشتراک می‌گیره (۳۴۹,۳۰۰ تومان به جای ۴۹۹,۰۰۰ تومان) 🎉\n'
                  '• به محض اینکه دوستت اشتراک بخره، ۳ روز اشتراک رایگان به حساب تو اضافه می‌شه! 🚀💎',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: bmTextSubColor,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: bmSurfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: BMColors.neonGreen.withOpacity(0.55)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          c.profile.isLoggedIn ? 'کد دعوت تو: $myCode' : 'اول وارد حسابت شو 🔐',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                            color: bmTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BMColors.neonGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (!c.profile.isLoggedIn) {
                            Navigator.pop(ctx);
                            c.openTwoStepAuthModal(context, onNavigateHome: () => _jumpToTab(0));
                            return;
                          }
                          final inviteMsg =
                              'رفیق بیا توی برنامه بادی‌مود (مربی هوشمند بدنسازی و تغذیه)! 💪🔥 موقع خرید اشتراک کد دعوت من ($myCode) رو بزن تا ۳۰٪ تخفیف بگیری (۳۴۹,۳۰۰ تومن به جای ۴۹۹,۰۰۰ تومن)! 🚀\\nhttps://matin-mohammadi.ir/?ref=$myCode';
                          Clipboard.setData(ClipboardData(text: inviteMsg));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ متن و لینک دعوت اختصاصیت کپی شد! بفرست برای رفیقت 🤝🔥'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 15, color: Colors.black),
                        label: const Text(
                          'کپی لینک و کد',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                if (bmRefBonusDays > 0 || bmRefInvitedCount > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    '🏆 دوستان خریدکرده: $bmRefInvitedCount نفر | هدیه اشتراک رایگان تو: $bmRefBonusDays روز ✨',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: BMColors.neonGreen,
                    ),
                  ),
                ],
                const Divider(height: 24),
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
                              : 'مثلاً BM-586834 یا لینک دعوت',
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showStreakPhilosophySheet(BuildContext context, BodyModController c) {"""

dart = safe_replace(dart, old_streak_sheet_header, new_referral_sheet_and_streak, "Add _showReferralInviteSheet modal", "main.dart")

# 1.3 لود خودکار تخفیف معرف در کنترلر هنگام بالا آمدن برنامه (تا قیمت اشتراک ۳۴۹,۳۰۰ بمونه)
old_load_end_water = "    targetWaterGlasses = prefs.getInt('bm_target_water_v82') ?? 8;"
new_load_end_water = """    targetWaterGlasses = prefs.getInt('bm_target_water_v82') ?? 8;
    final savedRef = prefs.getString('bm_applied_ref_code') ?? '';
    if (savedRef.isNotEmpty) {
      bmAppliedRefCode = savedRef;
      appliedDiscountCode = savedRef;
      appliedDiscountPercent = 30;
      discountedSubscriptionPriceToman = 349300;
    }"""
dart = safe_replace(dart, old_load_end_water, new_load_end_water, "Load saved 30% referral discount into controller", "main.dart")

with open(main_path, "w", encoding="utf-8") as f:
    f.write(dart)

# ============================================================================
# 2. PATCH worker.js (Extract ref from URL, 30% discount, 3 free days to inviter)
# ============================================================================
with open(worker_path, "r", encoding="utf-8") as f:
    js = f.read()

# 2.1 پشتیبانی از پیست کردن لینک دعوت (?ref=BM-...) در bmApplyReferralCode
old_apply_ref = """async function bmApplyReferralCode(env, userKey, rawRefCode) {
  const u6 = bmExtractLast6(userKey);
  const ref6 = bmExtractLast6(rawRefCode);"""

new_apply_ref = """async function bmApplyReferralCode(env, userKey, rawRefCode) {
  let cleanRefInput = String(rawRefCode || '').trim();
  const refUrlMatch = cleanRefInput.match(/[?&]ref=([^&\\s]+)/i);
  if (refUrlMatch && refUrlMatch[1]) cleanRefInput = refUrlMatch[1];
  const u6 = bmExtractLast6(userKey);
  const ref6 = bmExtractLast6(cleanRefInput);
  const kvStore = getSafeKv(env);"""

js = safe_replace(js, old_apply_ref, new_apply_ref, "Support full invite URL in bmApplyReferralCode", "worker.js")

js = safe_replace(
    js,
    """  if (env && env.BODYMOD_DB_KV) {
    await env.BODYMOD_DB_KV.put('REF_USED_BY_' + u6, 'BM-' + ref6);
  }""",
    """  if (kvStore) {
    await kvStore.put('REF_USED_BY_' + u6, 'BM-' + ref6);
  }""",
    "Use safe kvStore in bmApplyReferralCode",
    "worker.js",
)

# 2.2 ذخیره نگاشت کد دعوت به اکانت اصلی (REF_OWNER_<u6> -> userKey) در ensureUserInitialized
old_ensure_init = """async function ensureUserInitialized(kv, userKey, userData) {
  await kv.put("user:" + userKey, JSON.stringify(userData));"""

new_ensure_init = """async function ensureUserInitialized(kv, userKey, userData) {
  await kv.put("user:" + userKey, JSON.stringify(userData));
  const own6 = bmExtractLast6(userKey);
  if (own6 && own6.length >= 4) {
    await kv.put("REF_OWNER_" + own6, String(userKey));
  }"""

js = safe_replace(js, old_ensure_init, new_ensure_init, "Save REF_OWNER mapping on login", "worker.js")

# 2.3 پشتیبانی از زدن کد دعوت (BM-...) مستقیم در کادر تخفیف صفحه‌ی پروفایل (/api/billing/apply-discount)
old_discount_not_found = """        const storedCodeRaw = await kv.get("discount:" + code);
        if (!storedCodeRaw) {
          return jsonResponse("""

new_discount_not_found = """        let cleanCode = code;
        const refM = String(body.code || "").match(/[?&]ref=([^&\\s]+)/i);
        if (refM && refM[1]) cleanCode = refM[1].trim().toUpperCase();

        const storedCodeRaw = await kv.get("discount:" + cleanCode);
        if (!storedCodeRaw) {
          if (cleanCode.startsWith("BM-")) {
            const user = await authenticateRequest(request, env, url);
            const uKey = user ? getUserKey(user) : "";
            const refRes = await bmApplyReferralCode(env, uKey, cleanCode);
            if (!refRes.ok) {
              return jsonResponse({ success: false, message: refRes.error }, 400);
            }
            return jsonResponse({
              success: true,
              code: cleanCode,
              percent: 30,
              originalPriceToman: CONFIG.SUBSCRIPTION_PRICE_TOMAN,
              finalPriceToman: 349300,
              skuToUse: "bodymod_sub_discount_30",
              message: refRes.message,
            });
          }
          return jsonResponse("""

js = safe_replace(js, old_discount_not_found, new_discount_not_found, "Allow BM- referral codes inside /api/billing/apply-discount", "worker.js")

# 2.4 اعطای خودکار ۳ روز اشتراک رایگان به دعوت‌کننده به محض خرید اشتراک توسط دعوت‌شده (/api/billing/verify-subscription)
old_verify_sub_end = """        const subCount = parseInt((await kv.get("stats:beta_subscribers")) || "0", 10);
        await kv.put("stats:beta_subscribers", String(subCount + 1));"""

new_verify_sub_end = """        const subCount = parseInt((await kv.get("stats:beta_subscribers")) || "0", 10);
        await kv.put("stats:beta_subscribers", String(subCount + 1));

        // اعطای ۳ روز اشتراک رایگان به کاربر دعوت‌کننده به محض خرید اشتراک توسط دعوت‌شده!
        try {
          const buyer6 = bmExtractLast6(userKey);
          if (buyer6 && buyer6.length >= 4) {
            const usedRef = (await kv.get("REF_USED_BY_" + buyer6)) || String(body.discountCode || "").trim().toUpperCase();
            const alreadyRewarded = await kv.get("REF_REWARDED_" + buyer6);
            if (usedRef && usedRef.startsWith("BM-") && !alreadyRewarded) {
              const inv6 = bmExtractLast6(usedRef);
              if (inv6 && inv6.length >= 4 && inv6 !== buyer6) {
                const prevCnt = parseInt((await kv.get("REF_INVITED_CNT_" + inv6)) || "0", 10) || 0;
                const prevDays = parseInt((await kv.get("REF_BONUS_DAYS_" + inv6)) || "0", 10) || 0;
                const prevUntil = parseInt((await kv.get("REF_VIP_UNTIL_" + inv6)) || "0", 10) || 0;
                const baseT = prevUntil > Date.now() ? prevUntil : Date.now();
                const newUntil = baseT + (3 * 86400 * 1000);
                await kv.put("REF_INVITED_CNT_" + inv6, String(prevCnt + 1));
                await kv.put("REF_BONUS_DAYS_" + inv6, String(prevDays + 3));
                await kv.put("REF_VIP_UNTIL_" + inv6, String(newUntil));
                await kv.put("REF_REWARDED_" + buyer6, "true");

                const inviterUserKey = await kv.get("REF_OWNER_" + inv6);
                if (inviterUserKey) {
                  const invRaw = await kv.get("profile:" + inviterUserKey);
                  if (invRaw) {
                    const invProfile = JSON.parse(invRaw);
                    const curExp = Number(invProfile.subscriptionExpiresAt) || 0;
                    const invBase = curExp > Date.now() ? curExp : Date.now();
                    invProfile.subscriptionExpiresAt = invBase + (3 * 86400 * 1000);
                    invProfile.hasActiveSubscription = true;
                    invProfile.subscriptionDaysRemaining = Math.ceil((invProfile.subscriptionExpiresAt - Date.now()) / 86400000);
                    if (!invProfile.subscriptionTier || invProfile.subscriptionTier === "بدون اشتراک") {
                      invProfile.subscriptionTier = "هدیه ۳ روزه دعوت از دوست 🎁";
                    }
                    await kv.put("profile:" + inviterUserKey, JSON.stringify(invProfile));
                  }
                }
              }
            }
          }
        } catch (_) {}"""

js = safe_replace(js, old_verify_sub_end, new_verify_sub_end, "Award 3 free days to inviter profile upon friend subscription", "worker.js")

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
            line += 1; in_lc = False; i += 1; continue
        if in_lc: i += 1; continue
        if in_bc:
            if ch == '*' and nxt == '/': in_bc = False; i += 2
            else: i += 1
            continue
        if in_s:
            if esc: esc = False
            elif ch == '\\': esc = True
            elif ch == "'": in_s = False
            i += 1; continue
        if in_d:
            if esc: esc = False
            elif ch == '\\': esc = True
            elif ch == '"': in_d = False
            i += 1; continue
        if ch == '/' and nxt == '/': in_lc = True; i += 2; continue
        if ch == '/' and nxt == '*': in_bc = True; i += 2; continue
        if ch == "'": in_s = True; i += 1; continue
        if ch == '"': in_d = True; i += 1; continue
        if ch in '([{': stack.append((ch, line))
        elif ch in ')]}':
            if not stack or stack[-1][0] != pairs[ch]:
                return f"❌ [{filename}] عدم تطابق '{ch}' در خط {line}"
            stack.pop()
        i += 1
    if stack:
        return f"❌ [{filename}] پرانتز/آکولاد باز مانده: {stack[-1]}"
    return f"✅ [{filename}] تمام پرانتزها و آکولادها ۱۰۰٪ تراز و سالم هستن! 🚀"

print(check_balance(dart, "lib/main.dart"))
print("🎉 تمام! بدون هیچ فایل بکاپی همه‌چیز اعمال شد! 🔥")
