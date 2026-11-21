import os
import re

def read_file(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()

def write_file(path, content):
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

# ==============================================================================
# 1. PATCH WORKFLOWS: Inject Native ANDROID_ID + Blue Heart Morning Notification
# ==============================================================================
NATIVE_INJECT_BLOCK = r'''          sed -i 's/android:label="bodymod"/android:label="BodyMod"/g' android/app/src/main/AndroidManifest.xml
          python3 - << 'PY_NATIVE'
import os
manifest_path = "android/app/src/main/AndroidManifest.xml"
m = open(manifest_path, "r", encoding="utf-8").read()
for perm in [
    '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>',
    '<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>'
]:
    if perm not in m:
        m = m.replace("<application", perm + "\n    <application", 1)
receiver_xml = '<receiver android:name=".BmStreakReceiver" android:exported="false" />'
if "BmStreakReceiver" not in m:
    m = m.replace("</application>", "        " + receiver_xml + "\n    </application>", 1)
open(manifest_path, "w", encoding="utf-8").write(m)

kt_dir = "android/app/src/main/kotlin/ir/matinmohammadi/bodymod"
os.makedirs(kt_dir, exist_ok=True)

main_kt = """package ir.matinmohammadi.bodymod

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "ir.matinmohammadi.bodymod/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAndroidId" -> {
                    try {
                        val aid = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID) ?: ""
                        result.success(aid)
                    } catch (e: Exception) {
                        result.success("")
                    }
                }
                "scheduleStreakReminder" -> {
                    try {
                        val delayMillis = (call.argument<Number>("delayMillis")?.toLong()) ?: 43200000L
                        val title = call.argument<String>("title") ?: "بادی‌مود 💙"
                        val body = call.argument<String>("body") ?: ""
                        val intent = Intent(this, BmStreakReceiver::class.java).apply {
                            putExtra("title", title)
                            putExtra("body", body)
                        }
                        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        } else {
                            PendingIntent.FLAG_UPDATE_CURRENT
                        }
                        val pi = PendingIntent.getBroadcast(this, 8842, intent, flags)
                        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        am.set(AlarmManager.RTC_WAKEUP, System.currentTimeMillis() + delayMillis, pi)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
"""
open(os.path.join(kt_dir, "MainActivity.kt"), "w", encoding="utf-8").write(main_kt)

recv_kt = """package ir.matinmohammadi.bodymod

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BmStreakReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val title = intent.getStringExtra("title") ?: "بادی‌مود 💙🔥"
        val body = intent.getStringExtra("body") ?: "امروز تعامل نکردی رفیق!"
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "bm_streak_blue_heart"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(channelId, "یادآور استریک بادی‌مود", NotificationManager.IMPORTANCE_DEFAULT)
            nm.createNotificationChannel(ch)
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        val notif = builder
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setSmallIcon(context.applicationInfo.icon)
            .setAutoCancel(true)
            .build()
        nm.notify(8842, notif)
    }
}
"""
open(os.path.join(kt_dir, "BmStreakReceiver.kt"), "w", encoding="utf-8").write(recv_kt)
PY_NATIVE'''

for wf in [".github/workflows/build-cafebazaar.yml", ".github/workflows/build-myket.yml"]:
    if os.path.exists(wf):
        txt = read_file(wf)
        if "BmStreakReceiver" not in txt:
            target = '          sed -i \'s/android:label="bodymod"/android:label="BodyMod"/g\' android/app/src/main/AndroidManifest.xml'
            if target in txt:
                txt = txt.replace(target, NATIVE_INJECT_BLOCK, 1)
                write_file(wf, txt)
                print(f"✅ Patched workflow: {wf}")
            else:
                print(f"⚠️ Anchor not found in {wf}")
        else:
            print(f"ℹ️ Already patched: {wf}")

# ==============================================================================
# 2. PATCH worker.js: Device 2-Account Gate, SignUp/SignIn, Zero-Token Quota, Iran Streak
# ==============================================================================
w = read_file("worker.js")

# 2A. Anti-cheat 2-account gate inside /api/auth/google/native
g_anchor = '        const sessionToken = crypto.randomUUID();\n        const userData = {\n          id: googleUser.sub,'
g_gate = '''        // ضدتقلب واقعی ۲ اکانت روی هر گوشی (با ANDROID_ID) قبل از صدور توکن
        const gDevId = String(body.deviceId || body.device_id || request.headers.get("X-Device-ID") || "").trim();
        const gEmailKey = String(googleUser.email).toLowerCase().trim();
        if (gDevId) {
          const devKey = "dev_accounts_v2:" + gDevId;
          const rawDev = await kv.get(devKey);
          let devList = [];
          try { devList = rawDev ? JSON.parse(rawDev) : []; } catch (_) { devList = []; }
          if (!devList.includes(gEmailKey)) {
            if (devList.length >= 2) {
              return jsonResponse({
                success: false,
                error: "DEVICE_ACCOUNT_LIMIT",
                deviceAccountLimit: true,
                message: "روی هر گوشی حداکثر ۲ حساب (۱ گوگل + ۱ شماره موبایل) مجازه رفیق! 🔒",
              }, 403);
            }
            devList.push(gEmailKey);
            await kv.put(devKey, JSON.stringify(devList));
          }
        }

        const sessionToken = crypto.randomUUID();
        const userData = {
          id: googleUser.sub,'''

if "dev_accounts_v2:" not in w and g_anchor in w:
    w = w.replace(g_anchor, g_gate, 1)
    print("✅ Patched worker.js: Google native 2-account device gate")

# 2B. Anti-cheat 2-account gate inside /api/auth/otp/verify
otp_anchor = '        const sessionToken = crypto.randomUUID();\n        const userData = {\n          identifier: normalizedPhone,'
otp_gate = '''        // ضدتقلب واقعی ۲ اکانت روی هر گوشی (با ANDROID_ID) قبل از صدور توکن
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
        }

        const sessionToken = crypto.randomUUID();
        const userData = {
          identifier: normalizedPhone,'''

if "const oDevId =" not in w and otp_anchor in w:
    w = w.replace(otp_anchor, otp_gate, 1)
    print("✅ Patched worker.js: OTP verify 2-account device gate")

# 2C. Add authMode (signup vs signin) to auth responses
w = w.replace(
    "hasExistingProfile: initResult.hasExistingProfile,",
    'hasExistingProfile: initResult.hasExistingProfile,\n          authMode: initResult.hasExistingProfile ? "signin" : "signup",'
)

# 2D. Fix bug on line ~1091 that auto-marked default 175/70 profile as completed!
auto_complete_bug = 'if (!rawProfile.isProfileCompleted && (Number(rawProfile.heightCm) > 0 && Number(rawProfile.weightKg) > 0)) {\n            rawProfile.isProfileCompleted = true;'
if auto_complete_bug in w:
    w = w.replace(auto_complete_bug, 'if (false && !rawProfile.isProfileCompleted) {\n            rawProfile.isProfileCompleted = true;', 1)
    print("✅ Fixed worker.js: prevented auto-completing unsubmitted Sign Up profiles")

# 2E. Zero-token fixed message when daily quota is reached
old_quota_msg = ': "رفیق سهمیه‌ات توی این بخش تموم شده! ⏳ بعد از ریست شدن سهمیه دوباره بیا تا با هم ادامه بدیم ❤️";'
new_quota_msg = ': "سهمیه‌ت تموم شده رفیق 😉\\nپیامتو فردا دوباره بفرست";'
if old_quota_msg in w:
    w = w.replace(old_quota_msg, new_quota_msg, 1)
    print("✅ Patched worker.js: Zero-token quota message updated")

# 2F. Server-side Iran Calendar Streak with 3-day Blue Heart Freeze (/api/user/streak)
streak_anchor = '      // 5. User Profile, 3-Stage Lock Check & Cloud Sync\n      if (path === "/api/user/status") {'
streak_route = '''      // 4.5 Server-side Iran Calendar Streak with 3-Day Blue Heart Freeze (💙)
      if (path === "/api/user/streak") {
        const authHeader = request.headers.get("Authorization") || "";
        const bearer = authHeader.replace(/^Bearer\\s+/i, "").trim();
        const sessRaw = bearer ? await kv.get("session:" + bearer) : null;
        if (!sessRaw) return jsonResponse({ error: "Unauthorized" }, 401);
        const sess = JSON.parse(sessRaw);
        const uKey = String(sess.email || sess.phone || sess.identifier || "").toLowerCase().trim();
        const iranNow = new Date(Date.now() + 3.5 * 3600 * 1000);
        const todayStr = iranNow.toISOString().slice(0, 10);
        const sKey = "streak_v2:" + uKey;
        let st = { count: 0, lastDate: "" };
        try {
          const rawSt = await kv.get(sKey);
          if (rawSt) st = JSON.parse(rawSt);
        } catch (_) {}

        let diffDays = 999;
        if (st.lastDate) {
          const d1 = new Date(todayStr + "T00:00:00Z").getTime();
          const d2 = new Date(st.lastDate + "T00:00:00Z").getTime();
          diffDays = Math.floor((d1 - d2) / 86400000);
        }

        if (request.method === "POST") {
          if (diffDays === 0) {
            if (st.count < 1) st.count = 1;
          } else if (diffDays >= 1 && diffDays <= 3 && st.count > 0) {
            st.count = st.count + 1;
          } else {
            st.count = 1;
          }
          st.lastDate = todayStr;
          await kv.put(sKey, JSON.stringify(st));
          return jsonResponse({ success: true, count: st.count, lastDate: st.lastDate, status: "active", emoji: "🔥" });
        } else {
          if (diffDays > 3) {
            st.count = 0;
            return jsonResponse({ success: true, count: 0, lastDate: st.lastDate, status: "reset", emoji: "🔥" });
          } else if (diffDays >= 1 && diffDays <= 3 && st.count > 0) {
            return jsonResponse({ success: true, count: st.count, lastDate: st.lastDate, status: "frozen_blue", emoji: "💙", daysMissed: diffDays });
          } else {
            return jsonResponse({ success: true, count: st.count, lastDate: st.lastDate, status: "active", emoji: "🔥" });
          }
        }
      }

      // 5. User Profile, 3-Stage Lock Check & Cloud Sync
      if (path === "/api/user/status") {'''

if "/api/user/streak" not in w and streak_anchor in w:
    w = w.replace(streak_anchor, streak_route, 1)
    print("✅ Patched worker.js: Added Iran-calendar 3-day Blue Heart streak API")

write_file("worker.js", w)

# ==============================================================================
# 3. PATCH lib/main.dart
# ==============================================================================
d = read_file("lib/main.dart")

# 3A. Ensure MethodChannel native bridge class (ANDROID_ID + Morning Blue Heart Notification)
if "class BmNativeBridge" not in d:
    bridge_code = '''
class BmNativeBridge {
  static const MethodChannel _ch = MethodChannel('ir.matinmohammadi.bodymod/native');

  static Future<String> getHardwareDeviceId(SharedPreferences prefs) async {
    try {
      final String? aid = await _ch.invokeMethod<String>('getAndroidId');
      if (aid != null && aid.trim().isNotEmpty) {
        final full = 'aid_${aid.trim()}';
        await prefs.setString('bm_device_id_v1', full);
        return full;
      }
    } catch (_) {}
    var existing = prefs.getString('bm_device_id_v1') ?? '';
    if (existing.isEmpty) {
      existing = 'dev_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
      await prefs.setString('bm_device_id_v1', existing);
    }
    return existing;
  }

  static Future<void> scheduleBlueHeartMorningReminder() async {
    try {
      final nowUtc = DateTime.now().toUtc();
      final iranNow = nowUtc.add(const Duration(hours: 3, minutes: 30));
      final nextMorningIran = DateTime.utc(iranNow.year, iranNow.month, iranNow.day + 1, 9, 0);
      final delayMs = nextMorningIran.difference(iranNow).inMilliseconds;
      await _ch.invokeMethod('scheduleStreakReminder', {
        'delayMillis': delayMs > 60000 ? delayMs : 43200000,
        'title': 'آتیش استریکت آبی شده! 💙🔥',
        'body': 'من چیزی نمیگم و نصیحتت نمیکنم 😂\\nولی امروز تعامل نکردی، اگه ادامه بدی آتیش استریکت خاموش میشه و از صفر شروع میشه و زحماتت به باد میره',
      });
    } catch (_) {}
  }
}
'''
    # Insert right after imports (before first class/void main)
    m = re.search(r'\n(void main\(|class )', d)
    if m:
        idx = m.start()
        d = d[:idx] + "\n" + bridge_code + d[idx:]
        print("✅ Patched lib/main.dart: Added BmNativeBridge (ANDROID_ID + Morning Notification)")

# Hook hardware ANDROID_ID in both places where bm_device_id_v1 is initialized
old_dev1 = "  var id = prefs.getString('bm_device_id_v1') ?? '';"
if old_dev1 in d:
    d = d.replace(old_dev1, "  var id = await BmNativeBridge.getHardwareDeviceId(prefs);", 1)
    print("✅ Patched lib/main.dart: Hooked hardware ANDROID_ID (helper)")

old_dev2 = "    deviceId = prefs.getString('bm_device_id_v1') ?? '';"
if old_dev2 in d:
    d = d.replace(old_dev2, "    deviceId = await BmNativeBridge.getHardwareDeviceId(prefs);", 1)
    print("✅ Patched lib/main.dart: Hooked hardware ANDROID_ID (controller)")

# 3B. Silent cancel for CafeBazaar/Myket Subscription & Donation
sub_cancel_anchor = "    if (context.mounted) {\n      showDialog(\n        context: context,\n        builder: (ctx) => AlertDialog("
sub_cancel_fix = """    final bmSubErrUp = BmStoreBilling.lastError.toUpperCase();
    if (bmSubErrUp.contains('CANCEL') || bmSubErrUp.isEmpty) {
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog("""
if "bmSubErrUp" not in d and sub_cancel_anchor in d:
    d = d.replace(sub_cancel_anchor, sub_cancel_fix, 1)
    print("✅ Patched lib/main.dart: Silent cancel on Subscription")

don_cancel_anchor = """    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'درخواست پرداخت مصرفی (چندباره) برای «$label» (کد محصول: $sku) به درگاه بازار/مایکت ارسال شد! ❤️🚀',"""
don_cancel_fix = """    final bmDonErrUp = BmStoreBilling.lastError.toUpperCase();
    if (bmDonErrUp.contains('CANCEL') || bmDonErrUp.isEmpty) {
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'درخواست پرداخت مصرفی (چندباره) برای «$label» (کد محصول: $sku) به درگاه بازار/مایکت ارسال شد! ❤️🚀',"""
if "bmDonErrUp" not in d and don_cancel_anchor in d:
    d = d.replace(don_cancel_anchor, don_cancel_fix, 1)
    print("✅ Patched lib/main.dart: Silent cancel on Donation")

# 3C. Show all 4 macros (Calories, Protein, Carbs, Fat) in AI Food Analysis box
food_anchor = """                      Text(
                        '✅ ${_lastAiFoodResult!['title']} — ${_lastAiFoodResult!['calories']} کالری (در غذاهای سفارشی ذخیره شد 💾)',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),"""
food_new = """                      Text(
                        '✅ ${_lastAiFoodResult!['title']} (در غذاهای سفارشی ذخیره شد 💾)',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: BMColors.neonGreen.withOpacity(0.35)),
                        ),
                        child: Text(
                          '🔥 ${_lastAiFoodResult!['calories']} کالری  |  💪 پروتئین: ${_lastAiFoodResult!['proteinG']}g  |  🍞 کربوهیدرات: ${_lastAiFoodResult!['carbsG']}g  |  🥑 چربی: ${_lastAiFoodResult!['fatG']}g',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: BMColors.neonGreen),
                        ),
                      ),"""
if "پروتئین: ${_lastAiFoodResult!" not in d and food_anchor in d:
    d = d.replace(food_anchor, food_new, 1)
    print("✅ Patched lib/main.dart: Added full 4-macro breakdown to AI food box")

# 3D. Registration Form: Empty initial height/weight/target for Sign Up + Hint Texts
old_ctrls = """    _heightCtrl = TextEditingController(text: p.heightCm.toString());
    _weightCtrl = TextEditingController(text: p.weightKg.toString());
    _targetWeightCtrl = TextEditingController(
      text: p.targetWeightKg.toString(),
    );"""
new_ctrls = """    final bool isFreshSignUp = widget.isInsidePopup || !p.isProfileCompleted;
    _heightCtrl = TextEditingController(text: isFreshSignUp ? '' : p.heightCm.toString());
    _weightCtrl = TextEditingController(text: isFreshSignUp ? '' : p.weightKg.toString());
    _targetWeightCtrl = TextEditingController(
      text: isFreshSignUp ? '' : p.targetWeightKg.toString(),
    );"""
if "isFreshSignUp" not in d and old_ctrls in d:
    d = d.replace(old_ctrls, new_ctrls, 1)
    print("✅ Patched lib/main.dart: Empty height/weight/target for Sign Up")

d = d.replace(
    "labelText: 'قد (سانتی‌متر)',",
    "labelText: 'قد (سانتی‌متر)',\n                  hintText: 'مثلاً: ۱۷۵',"
)
d = d.replace(
    "labelText: 'وزن فعلی (کیلوگرم)',",
    "labelText: 'وزن فعلی (کیلوگرم)',\n                  hintText: 'مثلاً: ۷۰',"
)
d = d.replace(
    "labelText: 'وزن هدف شما (کیلوگرم)',",
    "labelText: 'وزن هدف شما (کیلوگرم)',\n            hintText: 'مثلاً: ۷۵',"
)

# 3E. Add Quiz state variables + 6 Casual Rules + 2-Question Yes/No Quiz before Submit
state_anchor = "  late String _selectedSupplementMode;"
state_new = """  late String _selectedSupplementMode;
  bool? _rulesQuizQ1;
  bool? _rulesQuizQ2;
  String _rulesQuizError = '';"""
if "_rulesQuizQ1" not in d and state_anchor in d:
    d = d.replace(state_anchor, state_new, 1)

submit_anchor = """        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: BMColors.neonGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              final bool noWorkoutSelected = _selectedGoal == 'gain_bulk' || _selectedWorkoutDays == 'none';"""

rules_and_submit = """        const SizedBox(height: 16),

        if (widget.isInsidePopup || !c.profile.isProfileCompleted) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.28),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BMColors.neonCyan.withOpacity(0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📜 قوانین خودمونی بادی‌مود (فقط ۶ تاست!)',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: BMColors.neonCyan),
                ),
                const SizedBox(height: 8),
                const Text(
                  'رفیق من خودم هیچوقت قوانین رو نمی‌خوندم 🤣 و به تو هم حق میدم 😂\\nاما اینا هم خیلی مهمه و هم کمه و وقتتو نمی‌گیره؛ فقط همین ۶ تاست که اسکرول کنی می‌بینی 👇',
                  style: TextStyle(fontSize: 12.5, height: 1.55, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const Text(
                  '۱. هوش مصنوعی بادی‌مود دکتر یا متخصص نیست رفیق! 🩺 اگه مریض شدی یا مشکل اورژانسی داری حتماً برو دکتر؛ ولی برای مشورت‌های روزمره‌ی سلامتی، تغذیه و ورزشِ غیراورژانسی، بله می‌تونه جای دکتر یا مربی بدنسازی رو برات بگیره 😂\\n\\n'
                  '۲. عددهای هوش مصنوعی تقریبیه 🤖 کالری، پروتئین، کربوهیدرات و چربی‌هایی که هوش مصنوعی از رو عکس یا متنِ غذات درمیاره ترازوی آزمایشگاهی نیست؛ ولی ۹۹.۹ درصد به واقعیت نزدیکه 😂\\n\\n'
                  '۳. اطلاعاتت رو درست و کامل بگو ✍️ برنامه‌هات دقیقاً رو حساب اطلاعاتی چیده می‌شه که اینجا می‌نویسی (به‌خصوص اطلاعات شخصی‌تر و حساسیت‌هایی که به هوش مصنوعی می‌گی). با اینکه دکتر نیستم ولی پیشنهاداتی که می‌گم براساس خود تو شخصی‌سازی می‌شه؛ اگه اطلاعات واقعی خودتو ندی یا کم‌کاری کنی و ناقص بگی ممکنه پیشنهاد هوش مصنوعی نتیجه برعکس داشته باشه یا حتی خدای نکرده ممکنه بهت آسیب بزنه!\\n\\n'
                  '۴. کلک و تقلب ممنوع! 🕵️‍♂️ رو هر گوشی فقط ۲ تا اکانت (یکی گوگل، یکی شماره موبایل) می‌تونی بسازی. اگه بخوای به خودت کد دعوت بزنی یا از نسخه‌های غیررسمی بیرون بازار و مایکت استفاده کنی، سیستم مچتو می‌گیره و حسابت قفل می‌شه 😉\\n\\n'
                  '۵. خریدا دست بازار و مایکته 💳 همه‌ی پرداخت‌های اشتراک و حمایت مالی فقط از درگاه رسمی کافه‌بازار و مایکت انجام می‌شه و پیگیری یا برگشت پولش هم با قوانین همون مارکت‌هاست.\\n\\n'
                  '۶. اطلاعاتت پیش ما امانته 🔒 مشخصات بدنی، شماره/جیمیل و غذاهای سفارشی تو فقط برای این ذخیره می‌شه که برنامه‌ت دقیق باشه و حسابت نپره؛ عمراً به شرکت‌های تبلیغاتی یا هیچ‌کس دیگه بفروشیم!',
                  style: TextStyle(fontSize: 12, height: 1.65),
                ),
                const Divider(height: 22),
                const Text(
                  '🎓 امتحانِ ریز ببینم واقعاً خوندی یا فقط رد کردی 😂:',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: BMColors.warningAmber),
                ),
                const SizedBox(height: 10),
                const Text('۱. هوش مصنوعی بادی‌مود دکتر یا متخصص هست؟', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _rulesQuizQ1 == true ? BMColors.neonCyan.withOpacity(0.25) : null,
                          side: BorderSide(color: _rulesQuizQ1 == true ? BMColors.neonCyan : Colors.white24),
                        ),
                        onPressed: () => setState(() { _rulesQuizQ1 = true; _rulesQuizError = ''; }),
                        child: const Text('بله'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _rulesQuizQ1 == false ? BMColors.neonCyan.withOpacity(0.25) : null,
                          side: BorderSide(color: _rulesQuizQ1 == false ? BMColors.neonCyan : Colors.white24),
                        ),
                        onPressed: () => setState(() { _rulesQuizQ1 = false; _rulesQuizError = ''; }),
                        child: const Text('خیر'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('۲. می‌تونه جای دکتر رو بگیره؟', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _rulesQuizQ2 == true ? BMColors.neonCyan.withOpacity(0.25) : null,
                          side: BorderSide(color: _rulesQuizQ2 == true ? BMColors.neonCyan : Colors.white24),
                        ),
                        onPressed: () => setState(() { _rulesQuizQ2 = true; _rulesQuizError = ''; }),
                        child: const Text('بله'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _rulesQuizQ2 == false ? BMColors.neonCyan.withOpacity(0.25) : null,
                          side: BorderSide(color: _rulesQuizQ2 == false ? BMColors.neonCyan : Colors.white24),
                        ),
                        onPressed: () => setState(() { _rulesQuizQ2 = false; _rulesQuizError = ''; }),
                        child: const Text('خیر'),
                      ),
                    ),
                  ],
                ),
                if (_rulesQuizError.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _rulesQuizError,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: BMColors.neonGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              final hVal = double.tryParse(_heightCtrl.text.trim());
              final wVal = double.tryParse(_weightCtrl.text.trim());
              final twVal = double.tryParse(_targetWeightCtrl.text.trim());
              if (hVal == null || hVal < 80 || wVal == null || wVal < 25 || twVal == null || twVal < 25) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('رفیق اول قد، وزن فعلی و وزن هدفت رو دقیق وارد کن! ✍️')),
                );
                return;
              }
              if (widget.isInsidePopup || !c.profile.isProfileCompleted) {
                if (_rulesQuizQ1 == null || _rulesQuizQ2 == null) {
                  setState(() {
                    _rulesQuizError = 'رفیق اول به هر دو تا سوال امتحانِ بالا جواب بده تا دکمه باز شه! 😉';
                  });
                  return;
                }
                if (_rulesQuizQ1 != false || _rulesQuizQ2 != true) {
                  setState(() {
                    _rulesQuizError = 'ای کلک! قوانین رو نخوندی فقط یه چیزی زدی 🤣 یه بار دیگه بند ۱ تا ۶ رو بخون بعد جواب درست رو انتخاب کن!';
                  });
                  return;
                }
              }
              BmNativeBridge.scheduleBlueHeartMorningReminder();
              final bool noWorkoutSelected = _selectedGoal == 'gain_bulk' || _selectedWorkoutDays == 'none';"""

if "قوانین خودمونی بادی‌مود" not in d and submit_anchor in d:
    d = d.replace(submit_anchor, rules_and_submit, 1)
    print("✅ Patched lib/main.dart: Added 6 casual rules + 2-question quiz + validation")
else:
    print("ℹ️ Rules/Quiz anchor already applied or not matched")

write_file("lib/main.dart", d)
print("\n🎉 ALL PATCHES COMPLETED SUCCESSFULLY!")
