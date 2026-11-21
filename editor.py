# =========================================================================
# 1. اصلاح کامل باگ‌ها و آنتی‌چیت‌های worker.js
# =========================================================================
with open("worker.js", "r", encoding="utf-8") as f:
    w = f.read()

# الف) اصلاح ReferenceError: getKv -> getSafeKv در هر ۳ مسیر امنیتی
w = w.replace("getKv(env)", "getSafeKv(env)")

# ب) اضافه کردن X-Admin-Password به CORS
old_cors = '"Access-Control-Allow-Headers": "Content-Type, Authorization, X-Requested-With, X-User-ID, X-Admin-Secret, X-Client-Version, X-Platform, X-Device-ID",'
new_cors = '"Access-Control-Allow-Headers": "Content-Type, Authorization, X-Requested-With, X-User-ID, X-Admin-Secret, X-Admin-Password, X-Client-Version, X-Platform, X-Device-ID",'
assert old_cors in w, "❌ CORS_HEADERS در worker.js پیدا نشد!"
w = w.replace(old_cors, new_cors, 1)

# پ) معافیت اکانت مدیرعامل در /api/security/check-device-account
old_sec_chk = """      if (!devId || !rawId || rawId === 'anonymous') {
        return new Response(JSON.stringify({ ok: true, allowed: true }), { status: 200, headers: corsH });
      }"""
new_sec_chk = old_sec_chk + """
      if (isCeoAdminUser({ email: rawId, phone: rawId, identifier: rawId }, {})) {
        return new Response(JSON.stringify({ ok: true, allowed: true, ceoBypass: true }), { status: 200, headers: corsH });
      }"""
assert old_sec_chk in w, "❌ بخش check-device-account پیدا نشد!"
w = w.replace(old_sec_chk, new_sec_chk, 1)

# ت) اصلاح کرش body.deviceId در /auth/google/callback + معافیت مدیرعامل
old_gcb = 'const gDevId = String(body.deviceId || body.device_id || request.headers.get("X-Device-ID") || "").trim();'
new_gcb = 'const gDevId = String(url.searchParams.get("deviceId") || request.headers.get("X-Device-ID") || "").trim();'
assert old_gcb in w, "❌ خط gDevId در /auth/google/callback پیدا نشد!"
w = w.replace(old_gcb, new_gcb, 1)

old_gcb_if = 'if (gDevId) {'
new_gcb_if = 'if (gDevId && !isCeoAdminUser({ email: gEmailKey }, {})) {'
assert old_gcb_if in w, "❌ شرط gDevId پیدا نشد!"
w = w.replace(old_gcb_if, new_gcb_if, 1)

# ث) اضافه کردن آنتی‌چیت واقعی (۱ اکانت گوگل روی هر گوشی) به /api/auth/google/native (با معافیت مدیرعامل)
old_gnative = """        if (!googleUser || !googleUser.email) {
          return jsonResponse({ error: "توکن گوگل معتبر نیست رفیق! 😅" }, 401);
        }"""
new_gnative = old_gnative + """

        const gnEmail = String(googleUser.email).toLowerCase().trim();
        const gnDevId = String(body.deviceId || body.device_id || request.headers.get("X-Device-ID") || "").trim();
        if (gnDevId && !isCeoAdminUser({ email: gnEmail }, {})) {
          const slotKey = "dev_acc_google:" + gnDevId;
          const boundGoogle = await kv.get(slotKey);
          if (!boundGoogle) {
            await kv.put(slotKey, gnEmail);
          } else if (String(boundGoogle).trim().toLowerCase() !== gnEmail) {
            return jsonResponse({
              success: false,
              error: "DEVICE_ACCOUNT_LIMIT",
              deviceAccountLimit: true,
              message: "نمیتونی سر من کلاه بزاری 😂\\nفقط دوتا اکانت میتونی بسازی، یکی با شماره موبایل، یکی با اکانت گوگلت\\nدکمه برگشت رو بزن و برگرد",
            }, 403);
          }
        }"""
assert old_gnative in w, "❌ بخش /api/auth/google/native پیدا نشد!"
w = w.replace(old_gnative, new_gnative, 1)

# ج) یکپارچه‌سازی آنتی‌چیت شماره موبایل (۱ شماره روی هر گوشی + معافیت مدیرعامل) در /api/auth/otp/verify
old_otp_dev = """        // ضدتقلب واقعی ۲ اکانت روی هر گوشی (با ANDROID_ID) قبل از صدور توکن
        const oDevId = String(body.deviceId || body.device_id || request.headers.get("X-Device-ID") || "").trim();
        if (oDevId) {
          const devKey = "dev_accounts_v2:" + oDevId;
          const rawDev = await kv.get(devKey);
          let devList = [];
          try { devList = rawDev ? JSON.parse(rawDev) : []; } catch (_) { devList = []; }
          if (!devList.includes(normalizedPhone)) {
            if (devList.length >= 2) {
              return jsonResponse({
                success: false,
                error: "DEVICE_ACCOUNT_LIMIT",
                deviceAccountLimit: true,
                message: "روی هر گوشی حداکثر ۲ حساب (۱ گوگل + ۱ شماره موبایل) مجازه رفیق! 🔒",
              }, 403);
            }
            devList.push(normalizedPhone);
            await kv.put(devKey, JSON.stringify(devList));
          }
        }"""
new_otp_dev = """        // ضدتقلب واقعی ۱ اکانت موبایل روی هر گوشی (با معافیت مدیرعامل)
        const oDevId = String(body.deviceId || body.device_id || request.headers.get("X-Device-ID") || "").trim();
        if (oDevId && !isCeoAdminUser({ phone: normalizedPhone, identifier: normalizedPhone }, {})) {
          const slotKey = "dev_acc_phone:" + oDevId;
          const boundPhone = await kv.get(slotKey);
          if (!boundPhone) {
            await kv.put(slotKey, normalizedPhone);
          } else if (String(boundPhone).trim() !== normalizedPhone) {
            return jsonResponse({
              success: false,
              error: "DEVICE_ACCOUNT_LIMIT",
              deviceAccountLimit: true,
              message: "نمیتونی سر من کلاه بزاری 😂\\nفقط دوتا اکانت میتونی بسازی، یکی با شماره موبایل، یکی با اکانت گوگلت\\nدکمه برگشت رو بزن و برگرد",
            }, 403);
          }
        }"""
assert old_otp_dev in w, "❌ بخش آنتی‌چیت OTP در worker.js پیدا نشد!"
w = w.replace(old_otp_dev, new_otp_dev, 1)

# چ) اصلاح سهمیه‌های workout_weekly و food_text_weekly / food_photo_weekly + فعال‌سازی ضداسپم ۵ ثانیه‌ای سمت سرور
old_feat = """        } else if (path === "/api/ai/calorie" || body.mode === "calorie_vision") {
          featureType = "chat_daily";"""
new_feat = """        } else if (path === "/api/ai/workout-plan" || body.mode === "workout_plan") {
          featureType = "workout_weekly";
        } else if (path === "/api/ai/calorie" || body.mode === "calorie_vision") {
          featureType = imageBase64 ? "food_photo_weekly" : "food_text_weekly";"""
assert old_feat in w, "❌ بخش featureType در worker.js پیدا نشد!"
w = w.replace(old_feat, new_feat, 1)

old_quota_chk = """        // مدیرعامل (متین) محدودیت سهمیه ندارد!
        if (!profile.isAdmin) {"""
new_quota_chk = """        // مدیرعامل (متین) محدودیت سهمیه و کول‌داون ۵ ثانیه‌ای ندارد!
        if (!profile.isAdmin) {
          const cdRes = await bmEnforce5SecCooldown(env, userKey);
          if (!cdRes.ok) {
            return jsonResponse({ error: "COOLDOWN", message: cdRes.error }, 429);
          }"""
assert old_quota_chk in w, "❌ بخش checkUserQuota در worker.js پیدا نشد!"
w = w.replace(old_quota_chk, new_quota_chk, 1)

# ح) ثبت خودکار تمام خطاهای پیش‌بینی‌نشده ۵۰۰ در رادار ارورها
old_catch = """    } catch (err) {
      return jsonResponse({ error: "خطای داخلی سرور", message: err.message }, 500);
    }"""
new_catch = """    } catch (err) {
      await logRadarError(kv, {
        path: path,
        userKey: "system",
        status: 500,
        message: "خطای داخلی سرور (500)",
        details: String(err && err.message ? err.message : err).slice(0, 260),
      });
      return jsonResponse({ error: "خطای داخلی سرور", message: err.message }, 500);
    }"""
assert old_catch in w, "❌ بخش catch اصلی در worker.js پیدا نشد!"
w = w.replace(old_catch, new_catch, 1)

with open("worker.js", "w", encoding="utf-8") as f:
    f.write(w)
print("✅ 1. تمام باگ‌ها و آنتی‌چیت‌های worker.js فیکس شد!")

# =========================================================================
# 2. اصلاح کامل آنتی‌چیت‌ها و باگ‌های lib/main.dart
# =========================================================================
with open("lib/main.dart", "r", encoding="utf-8") as f:
    d = f.read()

# الف) فعال‌سازی آنتی‌چیت اصالت فروشگاه (بازار و مایکت) در شروع برنامه
old_init = """    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.requestAndroidNotificationPermission(context);
    });"""
new_init = """    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.requestAndroidNotificationPermission(context);
      bmVerifyStoreIntegrity(context);
    });"""
assert old_init in d, "❌ initState در MainShellScreen پیدا نشد!"
d = d.replace(old_init, new_init, 1)

# ب) ارسال X-Device-ID و deviceId در ورود نیتیو گوگل + نمایش پاپ‌آپ ضدتقلب در صورت 403
old_g_req = """      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id_token': auth.idToken,
              'access_token': auth.accessToken,
              'google_id': account.id,
              'email': account.email,
              'name': account.displayName ?? '',
              'photo_url': account.photoUrl ?? '',
            }),
          )"""
new_g_req = """      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (deviceId.isNotEmpty) 'X-Device-ID': deviceId,
            },
            body: jsonEncode({
              'id_token': auth.idToken,
              'access_token': auth.accessToken,
              'google_id': account.id,
              'email': account.email,
              'name': account.displayName ?? '',
              'photo_url': account.photoUrl ?? '',
              'deviceId': deviceId,
            }),
          )"""
assert old_g_req in d, "❌ درخواست loginWithNativeGoogle پیدا نشد!"
d = d.replace(old_g_req, new_g_req, 1)

old_g_200 = "      if (response.statusCode == 200) {"
new_g_200 = """      if (response.statusCode == 403 && context.mounted) {
        await bmCheckDeviceAccountLimit(context, account.email);
        return null;
      }
      if (response.statusCode == 200) {"""
assert old_g_200 in d, "❌ بررسی statusCode در loginWithNativeGoogle پیدا نشد!"
d = d.replace(old_g_200, new_g_200, 1)

# پ) ارسال X-Device-ID و deviceId در verifyPhoneOtp
old_otp_req = """      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': cleanPhone,
              'code': cleanCode,
              'otpToken': _lastOtpStatelessToken,
            }),
          )"""
new_otp_req = """      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (deviceId.isNotEmpty) 'X-Device-ID': deviceId,
            },
            body: jsonEncode({
              'phone': cleanPhone,
              'code': cleanCode,
              'otpToken': _lastOtpStatelessToken,
              'deviceId': deviceId,
            }),
          )"""
assert old_otp_req in d, "❌ درخواست verifyPhoneOtp پیدا نشد!"
d = d.replace(old_otp_req, new_otp_req, 1)

# ت) پاک کردن رمز و آمار پنل مدیرعامل هنگام خروج از حساب
old_signout = "    bmIsAdminGlobal = false;"
new_signout = "    bmIsAdminGlobal = false;\n    _ceoPanelPassword = '';\n    adminFullStats = {};"
assert old_signout in d, "❌ خط signOutAccount پیدا نشد!"
d = d.replace(old_signout, new_signout, 1)

# ث) اصلاح پیام خطای گمراه‌کننده در باشگاه زنده هنگام شکست
old_gym_err = "ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ برنامه تمرینی و تعادل کالری مازاد بر اساس فرم تو بروزرسانی شد! 💪🔥'), backgroundColor: Color(0xFF00C896)));"
new_gym_err = "ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ خطا در ساخت برنامه ورزشی از هوش مصنوعی! چند ثانیه دیگه دوباره امتحان کن رفیق.'), backgroundColor: Colors.redAccent));"
if old_gym_err in d:
    d = d.replace(old_gym_err, new_gym_err, 1)

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(d)
print("✅ 2. تمام باگ‌ها و آنتی‌چیت‌های lib/main.dart فیکس شد!")
