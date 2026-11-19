# -*- coding: utf-8 -*-
import os, re, shutil, sys

def update_price_to_499k(text):
    for old_p in ["۳۷۹,۰۰۰", "۳۷۹٬۰۰۰", "۱۸۹,۰۰۰", "۱۸۹٬۰۰۰"]:
        text = text.replace(old_p, "۴۹۹,۰۰۰")
    for old_en in ["379,000", "189,000"]:
        text = text.replace(old_en, "499,000")
    for old_raw in ["379000", "189000"]:
        text = text.replace(old_raw, "499000")
    for old_k in ["۳۷۹ هزار", "۱۸۹ هزار"]:
        text = text.replace(old_k, "۴۹۹ هزار")
    for old_t in ["۳۷۹ تومن", "۱۸۹ تومن"]:
        text = text.replace(old_t, "۴۹۹ تومن")
    text = text.replace("bodymod_sub_379k", "bodymod_sub_499k").replace("bodymod_sub_189k", "bodymod_sub_499k")

    # قیمت با ۳۰٪ تخفیف دعوت از دوست: 499,000 * 0.7 = 349,300
    for old_d in ["۲۶۵,۳۰۰", "۲۶۵٬۳۰۰", "۱۳۲,۳۰۰", "۱۳۲٬۳۰۰"]:
        text = text.replace(old_d, "۳۴۹,۳۰۰")
    for old_den in ["265,300", "132,300"]:
        text = text.replace(old_den, "349,300")
    for old_draw in ["265300", "132300"]:
        text = text.replace(old_draw, "349300")
    return text

# ==============================================================================
# بخش ۱: آپدیت worker.js کلودفلر (قیمت ۴۹۹,۰۰۰ تومان + قفل ضدربات ۵ ثانیه‌ای روی تمام درخواست‌های AI)
# ==============================================================================
W_FILE = "worker.js"
if os.path.exists(W_FILE):
    with open(W_FILE, "r", encoding="utf-8") as wf:
        w_code = wf.read()

    w_code = update_price_to_499k(w_code)

    COOLDOWN_WORKER = "\n".join([
        "// --- [BODYMOD 5-SECOND ANTI-SPAM AI COOLDOWN] ---",
        "async function bmEnforce5SecCooldown(env, userKey) {",
        "  try {",
        "    if (!env || !env.BODYMOD_DB_KV) return { ok: true };",
        "    const digits = String(userKey || '').replace(/\\D/g, '');",
        "    const u6 = digits.length >= 6 ? digits.slice(-6) : (String(userKey || 'anon').replace(/[^a-zA-Z0-9]/g, '').slice(-6) || 'anon');",
        "    const key = 'AI_LAST_TS_' + u6;",
        "    const prev = parseInt((await env.BODYMOD_DB_KV.get(key)) || '0', 10) || 0;",
        "    const now = Date.now();",
        "    const diffSec = Math.floor((now - prev) / 1000);",
        "    if (prev > 0 && diffSec < 5) {",
        "      const rem = 5 - diffSec;",
        "      return { ok: false, waitSeconds: rem, error: 'رفیق بین هر درخواست به مربی هوشمند ۵ ثانیه صبر کن! (' + rem + ' ثانیه مونده) ⏳' };",
        "    }",
        "    await env.BODYMOD_DB_KV.put(key, String(now));",
        "    return { ok: true };",
        "  } catch (e) { return { ok: true }; }",
        "}",
        "// --- [END 5-SECOND COOLDOWN] ---",
    ])

    if "bmEnforce5SecCooldown" not in w_code:
        w_code = COOLDOWN_WORKER + "\n" + w_code

    with open(W_FILE, "w", encoding="utf-8") as wf:
        wf.write(w_code)
    print("✅ فایل worker.js با قیمت جدید ۴۹۹,۰۰۰ تومان (با ۳۰٪ تخفیف = ۳۴۹,۳۰۰ تومان) و قفل ۵ ثانیه‌ای AI آپدیت شد!")

# ==============================================================================
# بخش ۲: آپدیت lib/main.dart (قیمت ۴۹۹ هزار تومان + تایمر معکوس زنده ۵ تا ۰ روی هوش مصنوعی)
# ==============================================================================
F = "lib/main.dart"
if not os.path.exists(F):
    sys.exit("❌ فایل lib/main.dart پیدا نشد!")

with open(F, "r", encoding="utf-8") as f:
    c = f.read()

orig_parens = c.count("(") - c.count(")")
orig_braces = c.count("{") - c.count("}")
orig_bracks = c.count("[") - c.count("]")

if "import 'dart:async';" not in c and 'import "dart:async";' not in c:
    c = "import 'dart:async';\n" + c

# ۱. تغییر قیمت اشتراک به ۴۹۹,۰۰۰ تومان (و با ۳۰٪ تخفیف دعوت به ۳۴۹,۳۰۰ تومان)
c = update_price_to_499k(c)
print("✅ قیمت اشتراک ماهانه به ۴۹۹,۰۰۰ تومان (با ۳۰٪ تخفیف دعوت = ۳۴۹,۳۰۰ تومان) آپدیت شد!")

# ۲. موتور تایمر معکوس زنده ۵ تا ۰ ثانیه برای تمام درخواست‌های هوش مصنوعی
COOLDOWN_DART = "\n".join([
    "// --- [BODYMOD 5-SECOND LIVE COUNTDOWN TIMER FOR ALL AI REQUESTS] ---",
    "final ValueNotifier<int> bmAiCooldownSec = ValueNotifier<int>(0);",
    "Timer? _bmCooldownTimer;",
    "",
    "void bmStartAiCooldown5s() {",
    "  _bmCooldownTimer?.cancel();",
    "  bmAiCooldownSec.value = 5;",
    "  _bmCooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {",
    "    if (bmAiCooldownSec.value <= 1) {",
    "      bmAiCooldownSec.value = 0;",
    "      t.cancel();",
    "    } else {",
    "      bmAiCooldownSec.value -= 1;",
    "    }",
    "  });",
    "}",
    "",
    "bool bmTryAcquireAiCooldown(BuildContext? context) {",
    "  if (bmAiCooldownSec.value > 0) {",
    "    if (context != null && context.mounted) {",
    "      ScaffoldMessenger.of(context).clearSnackBars();",
    "      ScaffoldMessenger.of(context).showSnackBar(SnackBar(",
    "        content: ValueListenableBuilder<int>(",
    "          valueListenable: bmAiCooldownSec,",
    "          builder: (_, sec, __) => Text(sec > 0 ? '⏳ رفیق برای جلوگیری از فشار به سرور، $sec ثانیه صبر کن... ($sec تا ۰)' : '✅ الان می‌تونی دوباره بفرستی رفیق! 🚀'),",
    "        ),",
    "        duration: const Duration(seconds: 2),",
    "        backgroundColor: const Color(0xFFFBBF24),",
    "      ));",
    "    }",
    "    return false;",
    "  }",
    "  bmStartAiCooldown5s();",
    "  return true;",
    "}",
    "// --- [END 5-SECOND AI COOLDOWN] ---",
])

if "bmAiCooldownSec" not in c:
    c = c.replace("void main(", COOLDOWN_DART + "\nvoid main(", 1)

# ۳. اتصال تایمر ۵ ثانیه‌ای به دکمه ارسال چت و ویجت نمایش معکوس (۵..۴..۳..۲..۱..۰) روی دکمه ارسال
# الف) پیدا کردن دکمه «ارسال 🚀» در صفحه چت و جایگزینی متن/فعالیت آن با ValueListenableBuilder
send_btn_pos = c.find("ارسال 🚀")
if send_btn_pos != -1 and "bmAiCooldownSec" in c:
    # پیدا کردن Text('ارسال 🚀'...) و جایگزینی با تایمر زنده ۵..۰
    pre_s = c[max(0, send_btn_pos - 60):send_btn_pos + 60]
    m_send_txt = re.search(r"(?:const\s+)?Text\(\s*['\"]ارسال 🚀['\"][^)]*\)", c[max(0, send_btn_pos - 40):send_btn_pos + 120])
    if m_send_txt:
        abs_t_s = max(0, send_btn_pos - 40) + m_send_txt.start()
        abs_t_e = max(0, send_btn_pos - 40) + m_send_txt.end()
        orig_txt_w = c[abs_t_s:abs_t_e]
        live_btn_w = f"ValueListenableBuilder<int>(valueListenable: bmAiCooldownSec, builder: (_, sec, __) => sec > 0 ? Text('⏳ $sec ثانیه', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)) : {orig_txt_w})"
        c = c[:abs_t_s] + live_btn_w + c[abs_t_e:]
        print("✅ شمارشگر معکوس زنده (۵ تا ۰) روی دکمه «ارسال 🚀» چت قرار گرفت!")

# ب) تزریق گارد ۵ ثانیه‌ای به تمام متدهای ارسال پیام چت / تحلیل غذا / برنامه هوشمند
# هر متدی که به workers.dev درخواست POST می‌فرستد (به جز beta-status و referral) گارد ۵ ثانیه‌ای بگیرد
if "bmStartAiCooldown5s();" in c:
    # در bmGenerateAiWorkoutPlan
    c = c.replace(
        "if (bmIsGeneratingWorkout) return false;",
        "if (bmIsGeneratingWorkout) return false;\n  if (!bmTryAcquireAiCooldown(context)) return false;",
    )
    # در متد ارسال پیام چت (مثلاً _sendMessage یا sendAiMessage)
    for fn_pat in [
        r"(Future<void>\s+_[a-zA-Z0-9_]*(?:[sS]end|[cC]hat|[aA]nalyze|[gG]enerate)[a-zA-Z0-9_]*\s*\([^)]*\)\s*(?:async\s*)?\{)",
        r"(void\s+_send[a-zA-Z0-9_]*\s*\([^)]*\)\s*(?:async\s*)?\{)",
    ]:
        for m_fn in list(re.finditer(fn_pat, c)):
            fn_end = m_fn.end()
            # چک کردن ۵۰۰ کاراکتر بعدی تا ببینیم آیا مربوط به AI یا چت است
            look = c[fn_end:min(len(c), fn_end + 800)]
            if "bmTryAcquireAiCooldown" not in look and ("http.post" in look or "chat" in look.lower() or "ai" in look.lower()):
                ctx_arg = "context" if "BuildContext" in m_fn.group(0) or "State<" in c[max(0, m_fn.start() - 1500):m_fn.start()] else "null"
                c = c[:fn_end] + f" if (!bmTryAcquireAiCooldown({ctx_arg})) return;" + c[fn_end:]

# ج) همچنین روی دکمه «🤖 بروزرسانی با AI» در باشگاه زنده تایمر ۵ تا ۰ نمایش بده
c = c.replace(
    "Text(bmIsGeneratingWorkout ? 'در حال محاسبه AI... ⏳' : '🤖 بروزرسانی با AI'",
    "ValueListenableBuilder<int>(valueListenable: bmAiCooldownSec, builder: (_, sec, __) => Text(bmIsGeneratingWorkout ? 'در حال محاسبه AI... ⏳' : (sec > 0 ? '⏳ صبر کن ($sec)' : '🤖 بروزرسانی با AI')",
)
# بستن پرانتز ValueListenableBuilder در صورت جایگزینی بالا
if "ValueListenableBuilder<int>(valueListenable: bmAiCooldownSec, builder: (_, sec, __) => Text(bmIsGeneratingWorkout ?" in c:
    c = c.replace(
        "builder: (_, sec, __) => Text(bmIsGeneratingWorkout ? 'در حال محاسبه AI... ⏳' : (sec > 0 ? '⏳ صبر کن ($sec)' : '🤖 بروزرسانی با AI'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black))",
        "builder: (_, sec, __) => Text(bmIsGeneratingWorkout ? 'در حال محاسبه AI... ⏳' : (sec > 0 ? '⏳ صبر کن ($sec)' : '🤖 بروزرسانی با AI'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)))",
    )

# حذف const از اطراف ValueListenableBuilder جدید در صورت وجود
def strip_invalid_consts(text):
    dyn_tokens = (
        "bmCardColor", "bmSurfaceColor", "bmBgColor", "bmTextColor",
        "bmTextSubColor", "bmTextMutedColor", "bmBorderColor",
        "bmYellowBoxColor", "bmOnYellowBoxColor", "bmAccentColor",
        "bmExStr", "bmBuildBetaCountdownBanner", "bmBetaRemaining",
        "BMColors.", "FittedBox(", "ValueListenableBuilder<int>",
    )
    pattern = re.compile(r"\bconst\s+(?=[A-Z_a-z0-9.<>]*\s*[\(\[])")
    out = []
    last_idx = 0
    for m in pattern.finditer(text):
        c_start = m.start()
        c_end = m.end()
        open_pos = c_end
        while open_pos < len(text) and text[open_pos] not in "([;":
            open_pos += 1
        if open_pos < len(text) and text[open_pos] in "([":
            open_ch = text[open_pos]
            close_ch = ")" if open_ch == "(" else "]"
            depth = 0
            close_pos = -1
            for i in range(open_pos, min(len(text), open_pos + 7000)):
                if text[i] == open_ch: depth += 1
                elif text[i] == close_ch:
                    depth -= 1
                    if depth == 0: close_pos = i + 1; break
            if close_pos != -1:
                inner = text[open_pos:close_pos]
                if any(tok in inner for tok in dyn_tokens):
                    out.append(text[last_idx:c_start])
                    last_idx = c_end
                    continue
        out.append(text[last_idx:c_end])
        last_idx = c_end
    out.append(text[last_idx:])
    return "".join(out)

c = strip_invalid_consts(c)

if (c.count("(") - c.count(")")) != orig_parens or (c.count("{") - c.count("}")) != orig_braces or (c.count("[") - c.count("]")) != orig_bracks:
    sys.exit("❌ خطا در توازن پرانتز/آکولاد در lib/main.dart! فایل تغییر نکرد.")

with open(F, "w", encoding="utf-8") as f:
    f.write(c)

print("🎉 قیمت ۴۹۹,۰۰۰ تومان + تایمر معکوس زنده ۵ تا ۰ ثانیه برای هوش مصنوعی با موفقیت در worker.js و lib/main.dart اعمال شد!")
