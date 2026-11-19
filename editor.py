import re

LT = chr(60)
GT = chr(62)

main_path = "lib/main.dart"
stub_path = "lib/store_billing.dart"
worker_path = "worker.js"
bazaar_yml = ".github/workflows/build-cafebazaar.yml"
myket_yml = ".github/workflows/build-myket.yml"

def safe_replace(text, old, new, label, fname):
    if old in text:
        print(f"✅ [{fname}] {label}")
        return text.replace(old, new, 1)
    else:
        print(f"⚠️ [{fname}] Skipped (not found or already patched): {label}")
        return text

# ============================================================================
# 1. PATCH worker.js
#    - Verify official store RSA (BAZAR_RSA_KEY / MYKET_RSA_KEY)
#    - Device ID 2-account limit (1 Google + 1 Phone = 6 days total trial)
#    - Update phone/email after profile completion
#    - Device ID anti-cheat for self-referral
#    - Auto-grant 3-day trial in /api/ai/* (fix Stage-3 lock)
# ============================================================================
with open(worker_path, "r", encoding="utf-8") as f:
    js = f.read()

security_and_account_routes = """    // --- لایه امنیتی چک کلید RSA رسمی بازار و مایکت در کلودفلر ---
    if (request.url.includes('/api/security/verify-store')) {
      const corsH = { 'Content-Type': 'application/json; charset=utf-8', 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Device-ID' };
      if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsH });
      let b = {};
      try { b = await request.json(); } catch (e) {}
      const clean = (s) => String(s || '').replace(/\\s+/g, '');
      const clientKey = clean(b.rsaKey);
      const bazaarKey = clean(env.BAZAR_RSA_KEY || env.BAZAAR_RSA_KEY);
      const myketKey = clean(env.MYKET_RSA_KEY);
      if (!bazaarKey && !myketKey) {
        return new Response(JSON.stringify({ ok: true, valid: true, store: 'unconfigured' }), { status: 200, headers: corsH });
      }
      const isBazaar = Boolean(bazaarKey && clientKey && clientKey === bazaarKey);
      const isMyket = Boolean(myketKey && clientKey && clientKey === myketKey);
      if (isBazaar || isMyket) {
        return new Response(JSON.stringify({ ok: true, valid: true, store: isBazaar ? 'cafebazaar' : 'myket' }), { status: 200, headers: corsH });
      }
      return new Response(JSON.stringify({
        ok: true,
        valid: false,
        message: "فکر کردی میتونی سر من کلاه بزاری؟ 🤣\\nمن از تو هم زرنگترم 😂\\nزود تند سریع برنامه رو پاک کن و از این لینک ها وارد فروشگاه های رسمی بازار یا مایکت شو و برنامه رسمی رو نصب کن 😉"
      }), { status: 200, headers: corsH });
    }

    // --- لایه امنیتی محدودیت ۲ اکانت روی هر گوشی (۱ گوگل + ۱ شماره موبایل = جمعاً ۶ روز رایگان) ---
    if (request.url.includes('/api/security/check-device-account')) {
      const corsH = { 'Content-Type': 'application/json; charset=utf-8', 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Device-ID' };
      if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsH });
      let b = {};
      try { b = await request.json(); } catch (e) {}
      const devId = String(b.deviceId || request.headers.get('X-Device-ID') || '').trim();
      const rawId = String(b.identifier || '').trim().toLowerCase();
      const authType = String(b.authType || (rawId.includes('@') ? 'google' : 'phone')).trim().toLowerCase();
      if (!devId || !rawId || rawId === 'anonymous') {
        return new Response(JSON.stringify({ ok: true, allowed: true }), { status: 200, headers: corsH });
      }
      const kvSec = getKv(env);
      const slotKey = (authType === 'google' ? 'dev_acc_google:' : 'dev_acc_phone:') + devId;
      const boundId = await kvSec.get(slotKey);
      if (!boundId) {
        await kvSec.put(slotKey, rawId);
        return new Response(JSON.stringify({ ok: true, allowed: true, bound: true }), { status: 200, headers: corsH });
      }
      if (String(boundId).trim().toLowerCase() === rawId) {
        return new Response(JSON.stringify({ ok: true, allowed: true }), { status: 200, headers: corsH });
      }
      return new Response(JSON.stringify({
        ok: false,
        allowed: false,
        deviceAccountLimit: true,
        message: "نمیتونی سر من کلاه بزاری 😂\\nفقط دوتا اکانت میتونی بسازی، یکی با شماره موبایل، یکی با اکانت گوگلت\\nدکمه برگشت رو بزن و برگرد"
      }), { status: 403, headers: corsH });
    }

    // --- تغییر شماره موبایل یا جیمیل پس از ثبت‌نام و تکمیل فرم ---
    if (request.url.includes('/api/account/update-contact')) {
      const corsH = { 'Content-Type': 'application/json; charset=utf-8', 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Device-ID' };
      if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsH });
      let b = {};
      try { b = await request.json(); } catch (e) {}
      const kvAcc = getKv(env);
      const devId = String(b.deviceId || request.headers.get('X-Device-ID') || '').trim();
      const contactType = String(b.contactType || '').trim().toLowerCase();
      const newVal = String(b.newValue || '').trim();
      const user = await authenticateRequest(request, env, new URL(request.url));
      const userKey = user ? getUserKey(user) : String(b.currentIdentifier || '').trim();
      if (!userKey || !newVal || (contactType !== 'phone' && contactType !== 'email')) {
        return new Response(JSON.stringify({ ok: false, error: 'لطفاً شماره موبایل یا جیمیل معتبر وارد کن!' }), { status: 400, headers: corsH });
      }
      const rawP = await kvAcc.get('profile:' + userKey);
      const prof = rawP ? JSON.parse(rawP) : null;
      if (!prof || !prof.isProfileCompleted) {
        return new Response(JSON.stringify({ ok: false, error: 'اول فرم مشخصات بدنی‌ت رو کامل کن، بعدش می‌تونی شماره یا جیمیلت رو تغییر بدی 📋' }), { status: 400, headers: corsH });
      }
      if (contactType === 'phone') {
        prof.phone = newVal;
        if (devId) await kvAcc.put('dev_acc_phone:' + devId, newVal.toLowerCase());
      } else {
        prof.email = newVal.toLowerCase();
        if (devId) await kvAcc.put('dev_acc_google:' + devId, newVal.toLowerCase());
      }
      await kvAcc.put('profile:' + userKey, JSON.stringify(prof));
      return new Response(JSON.stringify({
        ok: true,
        message: contactType === 'phone' ? 'شماره موبایلت با موفقیت تغییر کرد و روی کلودفلر ثبت شد ✅' : 'جیمیلت با موفقیت تغییر کرد و روی کلودفلر ثبت شد ✅',
        phone: prof.phone || '',
        email: prof.email || ''
      }), { status: 200, headers: corsH });
    }

    // --- روت شمارش معکوس ۱۰۰۰ نفر بتا، دعوت دوست، ۱ روز هدیه ثبت‌نام و کنترل ورژن ---"""

if "/api/security/verify-store" not in js:
    js = safe_replace(
        js,
        "    // --- روت شمارش معکوس ۱۰۰۰ نفر بتا، دعوت دوست، ۱ روز هدیه ثبت‌نام و کنترل ورژن ---",
        security_and_account_routes,
        "Add RSA verify-store, 2-account device limit & update-contact endpoints",
        "worker.js",
    )

# تفکیک ترایال ۳ روزه به ازای هر نوع اکانت (۱ گوگل + ۱ موبایل = جمعاً ۶ روز روی هر گوشی!)
old_trial_dev_key = 'const deviceTrialKey = deviceId ? ("trial_3day_device:" + deviceId) : "";'
new_trial_dev_key = 'const trialKind = String(userKey || "").includes("@") ? "google" : "phone";\n          const deviceTrialKey = deviceId ? ("trial_3day_device_" + trialKind + ":" + deviceId) : "";'
js = safe_replace(js, old_trial_dev_key, new_trial_dev_key, "Split 3-day trial per device into 1 Google + 1 Phone (6 days total)", "worker.js")

# ضدتقلب دعوت از خودت با Device ID
old_ref_apply = """        if (bodyObj.action === 'apply_referral') {
          const resObj = await bmApplyReferralCode(env, uPhone, bodyObj.referralCode || bodyObj.code || '');"""

new_ref_apply = """        if (bodyObj.action === 'apply_referral') {
          const kvRef = getKv(env);
          const reqDeviceId = String(bodyObj.deviceId || request.headers.get('X-Device-ID') || '').trim();
          const codeUpper = String(bodyObj.referralCode || bodyObj.code || '').trim().toUpperCase();
          if (reqDeviceId && codeUpper) {
            const ownerDevice = await kvRef.get('ref_owner_device:' + codeUpper);
            if (ownerDevice && ownerDevice === reqDeviceId) {
              return new Response(JSON.stringify({
                ok: false,
                selfReferralCheat: true,
                error: "نمیتونی سر من کلاه بزاری 😂\\nبه اکانت خودت نمیتونی دعوت بدی، نمیتونی تقلب کنی 😉\\nکد رو به دوست واقعیت بفرست یا کنسل کن"
              }), { status: 403, headers: corsH });
            }
          }
          const resObj = await bmApplyReferralCode(env, uPhone, bodyObj.referralCode || bodyObj.code || '');
          if (resObj && !resObj.ok && String(resObj.error || '').includes('خودت')) {
            resObj.selfReferralCheat = true;
            resObj.error = "نمیتونی سر من کلاه بزاری 😂\\nبه اکانت خودت نمیتونی دعوت بدی، نمیتونی تقلب کنی 😉\\nکد رو به دوست واقعیت بفرست یا کنسل کن";
          }"""

if "selfReferralCheat" not in js:
    js = safe_replace(js, old_ref_apply, new_ref_apply, "Add Device ID anti-cheat for self-referral", "worker.js")

old_beta_return = """      const resObj = await bmGetBetaAndReferralState(env, qPhone, qVer);
      return new Response(JSON.stringify(resObj), { status: 200, headers: corsH });"""

new_beta_return = """      const resObj = await bmGetBetaAndReferralState(env, qPhone, qVer);
      const qDeviceId = String(reqUrl.searchParams.get('deviceId') || request.headers.get('X-Device-ID') || '').trim();
      const myCode = String(resObj.myReferralCode || resObj.referralCode || '').trim().toUpperCase();
      if (qDeviceId && myCode) {
        try {
          const kvRef = getKv(env);
          await kvRef.put('ref_owner_device:' + myCode, qDeviceId);
        } catch (e) {}
      }
      return new Response(JSON.stringify(resObj), { status: 200, headers: corsH });"""

if "qDeviceId" not in js:
    js = safe_replace(js, old_beta_return, new_beta_return, "Bind user's referral code to Device ID in KV", "worker.js")

# اعطای خودکار اشتراک ۳ روزه هدیه در /api/ai/* (فیکس قفل مرحله ۳!)
old_ai_lock_anchor = """          if (changed) {
            await kv.put("profile:" + userKey, JSON.stringify(rawProfile));
          }
        }

        const profile = enrichProfileWithAccessAndLocks(rawProfile, user);"""

new_ai_lock_anchor = """          if (changed) {
            await kv.put("profile:" + userKey, JSON.stringify(rawProfile));
          }
        }

        // اعطای خودکار ۳ روز اشتراک هدیه (جداگانه برای ۱ گوگل + ۱ موبایل روی هر گوشی = جمعاً ۶ روز)
        if (rawProfile.isProfileCompleted && !rawProfile.isAdmin && !isSubscriptionCurrentlyActive(rawProfile) && !rawProfile.freeTrialClaimed) {
          const aiDevId = String(body.deviceId || request.headers.get("X-Device-ID") || "").trim();
          const aiKind = String(userKey || "").includes("@") ? "google" : "phone";
          const devTrialKey = aiDevId ? ("trial_3day_device_" + aiKind + ":" + aiDevId) : "";
          const devClaimed = devTrialKey ? Boolean(await kv.get(devTrialKey)) : false;
          if (!devClaimed) {
            rawProfile.freeTrialClaimed = true;
            rawProfile.isFreeTrial = true;
            rawProfile.hasActiveSubscription = true;
            rawProfile.subscriptionTier = "اشتراک رایگان ۳ روزه هدیه ثبت‌نام 🎁";
            rawProfile.subscriptionDaysRemaining = 3;
            rawProfile.subscriptionExpiresAt = Date.now() + (3 * 86400 * 1000);
            await kv.put("profile:" + userKey, JSON.stringify(rawProfile));
            if (devTrialKey) {
              await kv.put(devTrialKey, userKey);
            }
          }
        }

        const profile = enrichProfileWithAccessAndLocks(rawProfile, user);"""

if "aiDevId" not in js:
    js = safe_replace(js, old_ai_lock_anchor, new_ai_lock_anchor, "Auto-grant 3-day free trial in /api/ai/* (1 Google + 1 Phone)", "worker.js")

with open(worker_path, "w", encoding="utf-8") as f:
    f.write(js)

# ============================================================================
# 2. PATCH lib/store_billing.dart + build-cafebazaar.yml (BAZAR_RSA_KEY!) + build-myket.yml
# ============================================================================
with open(stub_path, "r", encoding="utf-8") as f:
    st = f.read()
if "static String lastError" not in st:
    st = st.replace(
        "static const String rsaKey =",
        "static String lastError = '';\n  static const String rsaKey =",
    )
    with open(stub_path, "w", encoding="utf-8") as f:
        f.write(st)
    print("✅ [lib/store_billing.dart] Added lastError field")

with open(bazaar_yml, "r", encoding="utf-8") as f:
    b_code = f.read()

# فیکس حیاتی غلط املایی: BAZAAR_RSA_KEY -> BAZAR_RSA_KEY
b_code = safe_replace(
    b_code,
    "STORE_RSA_KEY: ${{ secrets.BAZAAR_RSA_KEY }}",
    "STORE_RSA_KEY: ${{ secrets.BAZAR_RSA_KEY }}",
    "Fix secret name typo: BAZAAR_RSA_KEY -> BAZAR_RSA_KEY",
    "build-cafebazaar.yml",
)

old_bazaar_dart = """          class BmStoreBilling {
            static const String storeFlavor = 'bazaar';
            static const String rsaKey = String.fromEnvironment('STORE_RSA_KEY', defaultValue: '');

            static Future purchase({
              required String sku,
              String payload = '',
              bool consumeImmediately = true,
            }) async {
              if (rsaKey.trim().isEmpty) return null;
              try {
                final completer = Completer();
                await FlutterPoolakey.connect(
                  rsaKey.trim(),
                  onSucceed: () {
                    if (!completer.isCompleted) completer.complete(true);
                  },
                  onFailed: () {
                    if (!completer.isCompleted) completer.complete(false);
                  },
                  onDisconnected: () {},
                );
                final connected = await completer.future.timeout(
                  const Duration(seconds: 8),
                  onTimeout: () => false,
                );
                if (connected != true) return null;

                final purchaseInfo = await FlutterPoolakey.purchase(
                  sku,
                  payload: payload,
                );
                final token = purchaseInfo.purchaseToken;
                if (token.isNotEmpty) {
                  if (consumeImmediately) {
                    try {
                      await FlutterPoolakey.consume(token);
                    } catch (_) {}
                  }
                  return {
                    'purchaseToken': token,
                    'market': 'cafebazaar',
                    'sku': sku,
                  };
                }
              } catch (_) {}
              return null;
            }"""

new_bazaar_dart = """          class BmStoreBilling {
            static const String storeFlavor = 'bazaar';
            static const String rsaKey = String.fromEnvironment('STORE_RSA_KEY', defaultValue: '');
            static String lastError = '';
            static bool _connected = false;

            static Future purchase({
              required String sku,
              String payload = '',
              bool consumeImmediately = true,
            }) async {
              lastError = '';
              final cleanKey = rsaKey.replaceAll(RegExp(r'\\s+'), '');
              if (cleanKey.isEmpty) {
                lastError = 'کلید RSA کافه‌بازار در بیلد خالی است (BAZAR_RSA_KEY)!';
                return null;
              }
              try {
                if (!_connected) {
                  final completer = Completer();
                  await FlutterPoolakey.connect(
                    cleanKey,
                    onSucceed: () {
                      _connected = true;
                      if (!completer.isCompleted) completer.complete(true);
                    },
                    onFailed: () {
                      _connected = false;
                      if (!completer.isCompleted) completer.complete(false);
                    },
                    onDisconnected: () {
                      _connected = false;
                    },
                  );
                  final ok = await completer.future.timeout(
                    const Duration(seconds: 10),
                    onTimeout: () => false,
                  );
                  if (ok != true) {
                    lastError = 'اتصال به اپلیکیشن کافه‌بازار برقرار نشد! مطمئن شو کافه‌بازار روی گوشیت نصب و به‌روزه و توش وارد شدی 🟢';
                    return null;
                  }
                }

                final purchaseInfo = await FlutterPoolakey.purchase(
                  sku,
                  payload: payload,
                );
                final token = purchaseInfo.purchaseToken;
                if (token.isNotEmpty) {
                  if (consumeImmediately) {
                    try {
                      await FlutterPoolakey.consume(token);
                    } catch (_) {}
                  }
                  return {
                    'purchaseToken': token,
                    'market': 'cafebazaar',
                    'sku': sku,
                  };
                }
                lastError = 'پرداخت توسط کاربر لغو شد یا توکن از بازار دریافت نشد.';
              } catch (e) {
                _connected = false;
                lastError = 'خطای درگاه کافه‌بازار: $e';
              }
              return null;
            }"""

b_code = safe_replace(b_code, old_bazaar_dart, new_bazaar_dart, "Upgrade Poolakey billing connect & clean RSA", "build-cafebazaar.yml")
with open(bazaar_yml, "w", encoding="utf-8") as f:
    f.write(b_code)

with open(myket_yml, "r", encoding="utf-8") as f:
    m_code = f.read()
if "static String lastError" not in m_code:
    m_code = m_code.replace(
        "static const String rsaKey = String.fromEnvironment('STORE_RSA_KEY', defaultValue: '');",
        "static const String rsaKey = String.fromEnvironment('STORE_RSA_KEY', defaultValue: '');\n            static String lastError = '';",
    )
    m_code = m_code.replace("rsaKey.trim()", "rsaKey.replaceAll(RegExp(r'\\s+'), '')")
    with open(myket_yml, "w", encoding="utf-8") as f:
        f.write(m_code)
    print("✅ [build-myket.yml] Added lastError & clean RSA key")

# ============================================================================
# 3. PATCH lib/main.dart
#    - Device ID + Uncloseable RSA Store Lock
#    - Device 2-Account Limit Popup (1 Google + 1 Phone) with Back button
#    - Change Phone / Gmail Popup + Button in Profile tab
#    - Self-Referral Anti-Cheat Popup
#    - Exact Bazaar Poolakey error display
# ============================================================================
with open(main_path, "r", encoding="utf-8") as f:
    dart = f.read()

security_helpers = f"""String bmDeviceIdGlobal = '';
bool bmStoreLockDialogShown = false;
bool bmAccountLimitDialogShown = false;

Future{LT}String{GT} bmGetOrCreateDeviceId() async {{
  if (bmDeviceIdGlobal.isNotEmpty) return bmDeviceIdGlobal;
  final prefs = await SharedPreferences.getInstance();
  var id = prefs.getString('bm_device_id_v1') ?? '';
  if (id.isEmpty) {{
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rnd = (now.hashCode ^ 0x5A7C9E).abs().toRadixString(36);
    id = 'BMDEV-$now-$rnd';
    await prefs.setString('bm_device_id_v1', id);
  }}
  bmDeviceIdGlobal = id;
  return id;
}}

Future{LT}void{GT} bmVerifyStoreIntegrity(BuildContext context) async {{
  if (bmStoreLockDialogShown) return;
  try {{
    final devId = await bmGetOrCreateDeviceId();
    final res = await http.post(
      Uri.parse('https://server.matin-mohammadi.ir/api/security/verify-store'),
      headers: {{'Content-Type': 'application/json', 'X-Device-ID': devId}},
      body: jsonEncode({{
        'storeFlavor': BmStoreBilling.storeFlavor,
        'rsaKey': BmStoreBilling.rsaKey,
      }}),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {{
      final d = jsonDecode(utf8.decode(res.bodyBytes));
      if (d is Map && d['valid'] == false && context.mounted && !bmStoreLockDialogShown) {{
        bmStoreLockDialogShown = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PopScope(
            canPop: false,
            child: AlertDialog(
              backgroundColor: const Color(0xFF0E141B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.redAccent, width: 2),
              ),
              title: const Text(
                '🚨 نسخه غیررسمی شناسایی شد!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent),
              ),
              content: const Text(
                'فکر کردی میتونی سر من کلاه بزاری؟ 🤣\\nمن از تو هم زرنگترم 😂\\nزود تند سریع برنامه رو پاک کن و از این لینک ها وارد فروشگاه های رسمی بازار یا مایکت شو و برنامه رسمی رو نصب کن 😉',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.7, fontSize: 14, color: Colors.white),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => launchUrl(
                        Uri.parse('https://cafebazaar.ir/app/ir.matinmohammadi.bodymod'),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.store_rounded),
                      label: const Text('🟢 دانلود رسمی از کافه‌بازار', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => launchUrl(
                        Uri.parse('https://myket.ir/app/ir.matinmohammadi.bodymod'),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.shop_rounded),
                      label: const Text('🔵 دانلود رسمی از مایکت', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }}
    }}
  }} catch (_) {{}}
}}

Future{LT}void{GT} bmCheckDeviceAccountLimit(BuildContext context, String identifier) async {{
  final cleanId = identifier.trim();
  if (cleanId.isEmpty || cleanId == 'anonymous' || bmAccountLimitDialogShown) return;
  try {{
    final devId = await bmGetOrCreateDeviceId();
    final authType = cleanId.contains('@') ? 'google' : 'phone';
    final res = await http.post(
      Uri.parse('https://server.matin-mohammadi.ir/api/security/check-device-account'),
      headers: {{'Content-Type': 'application/json', 'X-Device-ID': devId}},
      body: jsonEncode({{
        'deviceId': devId,
        'authType': authType,
        'identifier': cleanId,
      }}),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 403 && context.mounted && !bmAccountLimitDialogShown) {{
      final d = jsonDecode(utf8.decode(res.bodyBytes));
      if (d is Map && d['deviceAccountLimit'] == true) {{
        bmAccountLimitDialogShown = true;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PopScope(
            canPop: false,
            child: AlertDialog(
              backgroundColor: const Color(0xFF0E141B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.amber, width: 1.8),
              ),
              title: const Text(
                '🕵️‍♂️ محدودیت ساخت اکانت!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.amber),
              ),
              content: const Text(
                'نمیتونی سر من کلاه بزاری 😂\\nفقط دوتا اکانت میتونی بسازی، یکی با شماره موبایل، یکی با اکانت گوگلت\\nدکمه برگشت رو بزن و برگرد',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.7, fontSize: 14, color: Colors.white),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {{
                      bmAccountLimitDialogShown = false;
                      Navigator.pop(ctx);
                    }},
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('برگشت', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        );
      }}
    }}
  }} catch (_) {{}}
}}

Future{LT}void{GT} bmShowChangeContactDialog(BuildContext context) async {{
  String selectedType = 'phone';
  final inputCtrl = TextEditingController();
  bool submitting = false;
  String? statusError;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlgState) => AlertDialog(
        backgroundColor: const Color(0xFF0E141B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
        title: const Text(
          '✏️ تغییر شماره موبایل یا جیمیل',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981), fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'بعد از تکمیل فرم مشخصات، می‌تونی شماره موبایل یا جیمیل اکانتت رو اینجا تغییر بدی و روی کلودفلر آپدیت کنی:',
              style: TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('📱 شماره موبایل'),
                    selected: selectedType == 'phone',
                    onSelected: (_) => setDlgState(() {{
                      selectedType = 'phone';
                      statusError = null;
                    }}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('📧 جیمیل'),
                    selected: selectedType == 'email',
                    onSelected: (_) => setDlgState(() {{
                      selectedType = 'email';
                      statusError = null;
                    }}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: inputCtrl,
              keyboardType: selectedType == 'phone' ? TextInputType.phone : TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: selectedType == 'phone' ? 'مثلاً: 09141234567' : 'مثلاً: name@gmail.com',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF16202A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (statusError != null) ...[
              const SizedBox(height: 8),
              Text(statusError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: submitting ? null : () => Navigator.pop(ctx),
            child: const Text('انصراف', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.black,
            ),
            onPressed: submitting
                ? null
                : () async {{
                    final val = inputCtrl.text.trim();
                    if (selectedType == 'phone' && val.length < 10) {{
                      setDlgState(() => statusError = 'شماره موبایل معتبر نیست!');
                      return;
                    }}
                    if (selectedType == 'email' && !val.contains('@')) {{
                      setDlgState(() => statusError = 'آدرس جیمیل معتبر نیست!');
                      return;
                    }}
                    setDlgState(() {{
                      submitting = true;
                      statusError = null;
                    }});
                    try {{
                      final devId = await bmGetOrCreateDeviceId();
                      final prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('bm_auth_token') ?? prefs.getString('auth_token') ?? '';
                      final res = await http.post(
                        Uri.parse('https://server.matin-mohammadi.ir/api/account/update-contact'),
                        headers: {{
                          'Content-Type': 'application/json',
                          'X-Device-ID': devId,
                          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
                        }},
                        body: jsonEncode({{
                          'deviceId': devId,
                          'currentIdentifier': bmUserPhoneGlobal,
                          'contactType': selectedType,
                          'newValue': val,
                        }}),
                      ).timeout(const Duration(seconds: 12));
                      final d = jsonDecode(utf8.decode(res.bodyBytes));
                      if (res.statusCode == 200 && d is Map && d['ok'] == true) {{
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {{
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text((d['message'] ?? 'با موفقیت ذخیره شد ✅').toString())),
                          );
                        }}
                      }} else {{
                        setDlgState(() {{
                          submitting = false;
                          statusError = (d is Map ? (d['error'] ?? 'خطا در ثبت تغییرات') : 'خطا در ثبت تغییرات').toString();
                        }});
                      }}
                    }} catch (_) {{
                      setDlgState(() {{
                        submitting = false;
                        statusError = 'خطا در اتصال به سرور کلودفلر! اینترنتت رو چک کن 🌐';
                      }});
                    }}
                  }},
            child: Text(submitting ? 'در حال ثبت...' : 'ذخیره تغییرات ✅', style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ),
  );
}}

Future{LT}void{GT} bmSyncBetaCountdown"""

if "bmVerifyStoreIntegrity" not in dart:
    dart = safe_replace(
        dart,
        f"Future{LT}void{GT} bmSyncBetaCountdown",
        security_helpers,
        "Add Device ID, RSA lock, 2-account limit popup, and Change Phone/Gmail dialog",
        "main.dart",
    )

# فراخوانی چک امنیتی RSA + چک محدودیت ۲ اکانت دستگاه داخل bmSyncBetaCountdown
if "bmVerifyStoreIntegrity(context)" not in dart:
    dart = safe_replace(
        dart,
        "  try {\n    final prefs = await SharedPreferences.getInstance();\n    final res = await http.get(\n      Uri.parse('https://server.matin-mohammadi.ir/api/beta-status",
        """  if (context != null) {
    unawaited(bmVerifyStoreIntegrity(context));
    if (bmUserPhoneGlobal.trim().isNotEmpty) {
      unawaited(bmCheckDeviceAccountLimit(context, bmUserPhoneGlobal));
    }
  }
  try {
    final prefs = await SharedPreferences.getInstance();
    final devId = await bmGetOrCreateDeviceId();
    final res = await http.get(
      Uri.parse('https://server.matin-mohammadi.ir/api/beta-status""",
        "Trigger RSA verify & 2-account device check inside bmSyncBetaCountdown",
        "main.dart",
    )
    dart = dart.replace(
        "version=$bmCurrentAppVersion'),",
        "version=$bmCurrentAppVersion&deviceId=$devId'),",
    )

# ارسال deviceId در /api/referral و نمایش پاپ‌آپ ضدتقلب دعوت از خودت
old_ref_post = """    final res = await http.post(
      Uri.parse('https://server.matin-mohammadi.ir/api/referral'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'action': 'apply_referral', 'phone': bmUserPhoneGlobal, 'referralCode': rawCode}),
    ).timeout(const Duration(seconds: 12));
    final d = jsonDecode(res.body);"""

new_ref_post = """    final devId = await bmGetOrCreateDeviceId();
    final res = await http.post(
      Uri.parse('https://server.matin-mohammadi.ir/api/referral'),
      headers: {'Content-Type': 'application/json', 'X-Device-ID': devId},
      body: jsonEncode({'action': 'apply_referral', 'phone': bmUserPhoneGlobal, 'referralCode': rawCode, 'deviceId': devId}),
    ).timeout(const Duration(seconds: 12));
    final d = jsonDecode(utf8.decode(res.bodyBytes));
    if ((d is Map && d['selfReferralCheat'] == true) || res.statusCode == 403) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0E141B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.amber, width: 1.5),
            ),
            title: const Text(
              '🕵️‍♂️ مچت رو گرفتم!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, color: Colors.amber),
            ),
            content: const Text(
              'نمیتونی سر من کلاه بزاری 😂\\nبه اکانت خودت نمیتونی دعوت بدی، نمیتونی تقلب کنی 😉\\nکد رو به دوست واقعیت بفرست یا کنسل کن',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.7, fontSize: 14, color: Colors.white),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('باشه، کنسل کن 😅', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        );
      }
      bmRefSubmitting = false;
      onRefresh();
      return;
    }"""

dart = safe_replace(dart, old_ref_post, new_ref_post, "Send deviceId in referral & show anti-cheat self-referral popup", "main.dart")

# نمایش خطای دقیق کافه‌بازار اگر درگاه باز نشد
old_bazaar_fallback = "شتاب‌دهنده پرداخت برای شناسه محصول"
if "BmStoreBilling.lastError" not in dart:
    dart = dart.replace(
        old_bazaar_fallback,
        "${BmStoreBilling.lastError.isNotEmpty ? '${BmStoreBilling.lastError}\\n\\n' : ''}شتاب‌دهنده پرداخت برای شناسه محصول",
    )
    print("✅ [main.dart] Show exact Bazaar Poolakey error in billing dialog")

# اضافه کردن دکمه «تغییر شماره موبایل یا جیمیل» زیر دکمه «خروج از حساب کاربری» در تب پروفایل
if "bmShowChangeContactDialog(context)" not in dart:
    logout_idx = dart.find("'خروج از حساب کاربری'")
    if logout_idx != -1:
        # پیدا کردن پرانتز بازِ ویجتِ بیرونی‌ترین فرزندِ لیست children
        paren = 0
        bracket = 0
        min_paren = 0
        outer_open = -1
        for i in range(logout_idx, -1, -1):
            ch = dart[i]
            if ch == ')':
                paren += 1
            elif ch == '(':
                paren -= 1
                if paren < min_paren:
                    min_paren = paren
                    outer_open = i
            elif ch == ']':
                bracket += 1
            elif ch == '[':
                bracket -= 1
                if bracket < 0:
                    break
        if outer_open != -1:
            d = 0
            close_pos = -1
            for j in range(outer_open, len(dart)):
                if dart[j] == '(':
                    d += 1
                elif dart[j] == ')':
                    d -= 1
                    if d == 0:
                        close_pos = j
                        break
            if close_pos != -1:
                ins = close_pos + 1
                while ins < len(dart) and dart[ins] in ' \t\r\n':
                    ins += 1
                if ins < len(dart) and dart[ins] == ',':
                    ins += 1
                change_btn = """
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF10B981),
              side: const BorderSide(color: Color(0xFF10B981)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => bmShowChangeContactDialog(context),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text(
              '✏️ تغییر شماره موبایل یا جیمیل',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),"""
                dart = dart[:ins] + change_btn + dart[ins:]
                print("✅ [main.dart] Added 'تغییر شماره موبایل یا جیمیل' button in Profile tab")
            else:
                print("⚠️ [main.dart] Could not find closing paren for logout button")
        else:
            print("⚠️ [main.dart] Could not locate outer widget for logout button")
    else:
        print("⚠️ [main.dart] Could not find 'خروج از حساب کاربری' in main.dart")

with open(main_path, "w", encoding="utf-8") as f:
    f.write(dart)

print("🚀 تموم شد! BAZAR_RSA_KEY + ترایال ۶ روزه (۲ اکانت) + پاپ‌آپ تغییر شماره/جیمیل + قفل RSA + ضدتقلب دعوت آماده شد!")
