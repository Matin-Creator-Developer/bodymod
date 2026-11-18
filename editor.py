# -*- coding: utf-8 -*-
import os, re, shutil, sys

def shift_ai_models(text):
    if "3.8" in text or "۳.۸" in text:
        text = text.replace("gemini-3.5-flash-lite", "__TMP_MODEL_3_1_LITE__")
        text = re.sub(r"Gemini\s*3\.5\s*Flash[\s-]*Lite", "__TMP_LABEL_3_1_EN__", text)
        text = re.sub(r"3\.5\s*Flash[\s-]*Lite", "__TMP_SHORT_3_1_EN__", text)
        text = text.replace("۳.۵ فلش لایت", "__TMP_LABEL_3_1_FA__")
        text = text.replace("3.5 فلش لایت", "__TMP_LABEL_3_1_FA__")

        text = text.replace("gemini-3.8-flash", "gemini-3.5-flash-lite")
        text = re.sub(r"gemini-3\.5-flash(?!-lite)", "gemini-3.5-flash-lite", text)
        text = re.sub(r"Gemini\s*3\.8\s*Flash(?:\s*Lite)?", "Gemini 3.5 Flash Lite", text)
        text = re.sub(r"3\.8\s*Flash(?:\s*Lite)?", "3.5 Flash Lite", text)
        text = text.replace("۳.۸ فلش", "۳.۵ فلش لایت")
        text = text.replace("3.8 فلش", "۳.۵ فلش لایت")

        text = text.replace("__TMP_MODEL_3_1_LITE__", "gemini-3.1-flash-lite")
        text = text.replace("__TMP_LABEL_3_1_EN__", "Gemini 3.1 Flash Lite")
        text = text.replace("__TMP_SHORT_3_1_EN__", "3.1 Flash Lite")
        text = text.replace("__TMP_LABEL_3_1_FA__", "۳.۱ فلش لایت")
    return text

# ==============================================================================
# بخش ۱: آپدیت فایل worker.js کلودفلر (مدل‌های 3.1/3.5 + شمارشگر ۱۰۰۰ نفری بتا + سیستم دعوت دوست ۳۰٪ تخفیف / ۳ روز رایگان)
# ==============================================================================
W_FILE = "worker.js"
if os.path.exists(W_FILE):
    with open(W_FILE, "r", encoding="utf-8") as wf:
        w_code = wf.read()

    w_code = shift_ai_models(w_code)
    w_code = w_code.replace("const BM_BETA_MAX_CAP = 5000;", "const BM_BETA_MAX_CAP = 1000;")
    w_code = w_code.replace("ظرفیت ۵۰۰۰ نفری فاز بتا", "ظرفیت ۱۰۰۰ نفری فاز بتا")

    BETA_AND_REFERRAL_WORKER = "\n".join([
        "// --- [BODYMOD 1000-USER BETA COUNTDOWN & REFERRAL (30% OFF + 3 DAYS VIP) KV ENGINE] ---",
        "const BM_BETA_MAX_CAP = 1000;",
        "function bmExtractLast6(str) {",
        "  const digits = String(str || '').replace(/\\D/g, '');",
        "  return digits.length >= 6 ? digits.slice(-6) : digits;",
        "}",
        "async function bmGetBetaStatus(env, userPhone) {",
        "  let sold = 1;",
        "  let invCount = 0;",
        "  let bonusDays = 0;",
        "  let bonusExpireTs = 0;",
        "  let appliedRef = '';",
        "  try {",
        "    if (env && env.BODYMOD_DB_KV) {",
        "      const raw = await env.BODYMOD_DB_KV.get('GLOBAL_BETA_SUBSCRIBERS_COUNT');",
        "      if (raw !== null && raw !== undefined) {",
        "        const parsed = parseInt(raw, 10);",
        "        if (!isNaN(parsed) && parsed >= 1) sold = parsed;",
        "      }",
        "      const u6 = bmExtractLast6(userPhone);",
        "      if (u6 && u6.length === 6) {",
        "        invCount = parseInt((await env.BODYMOD_DB_KV.get('REF_INVITED_CNT_' + u6)) || '0', 10) || 0;",
        "        bonusDays = parseInt((await env.BODYMOD_DB_KV.get('REF_BONUS_DAYS_' + u6)) || '0', 10) || 0;",
        "        bonusExpireTs = parseInt((await env.BODYMOD_DB_KV.get('REF_VIP_UNTIL_' + u6)) || '0', 10) || 0;",
        "        appliedRef = (await env.BODYMOD_DB_KV.get('REF_USED_BY_' + u6)) || '';",
        "      }",
        "    }",
        "  } catch (e) {}",
        "  const rem = Math.max(0, BM_BETA_MAX_CAP - sold);",
        "  const nowMs = Date.now();",
        "  const activeBonusDaysLeft = bonusExpireTs > nowMs ? Math.ceil((bonusExpireTs - nowMs) / 86400000) : 0;",
        "  return {",
        "    ok: true,",
        "    betaCap: BM_BETA_MAX_CAP,",
        "    betaSold: sold,",
        "    betaRemaining: rem,",
        "    isFull: rem <= 0,",
        "    invitedCount: invCount,",
        "    bonusDaysEarned: bonusDays,",
        "    activeBonusDaysLeft: activeBonusDaysLeft,",
        "    hasBonusVip: activeBonusDaysLeft > 0,",
        "    appliedReferralCode: appliedRef,",
        "    discountPercent: appliedRef ? 30 : 0,",
        "    finalSubPrice: appliedRef ? 132300 : 189000",
        "  };",
        "}",
        "async function bmApplyReferralCode(env, userPhone, rawRefCode) {",
        "  const u6 = bmExtractLast6(userPhone);",
        "  const ref6 = bmExtractLast6(rawRefCode);",
        "  if (!u6 || u6.length < 6) {",
        "    return { ok: false, error: 'رفیق اول با شماره موبایلت وارد حساب شو تا کد تخفیف روی اکانتت قفل بشه! 📱' };",
        "  }",
        "  if (!ref6 || ref6.length !== 6) {",
        "    return { ok: false, error: 'کد معرف نامعتبره! کد معرف باید شامل ۶ رقم آخر شماره دوستت باشه (مثلاً BM-586834).' };",
        "  }",
        "  if (u6 === ref6) {",
        "    return { ok: false, error: 'ای کلک! 😂 نمی‌تونی کد معرف خودت رو برای خودت بزنی رفیق!' };",
        "  }",
        "  if (env && env.BODYMOD_DB_KV) {",
        "    await env.BODYMOD_DB_KV.put('REF_USED_BY_' + u6, 'BM-' + ref6);",
        "  }",
        "  const st = await bmGetBetaStatus(env, userPhone);",
        "  return {",
        "    ...st,",
        "    ok: true,",
        "    discountPercent: 30,",
        "    finalSubPrice: 132300,",
        "    message: 'ایول! 🎉 کد معرف ثبت شد و ۳۰٪ تخفیف اشتراک فاز بتا (۱۳۲,۳۰۰ تومان به جای ۱۸۹,۰۰۰ تومان) برات فعال شد! به محض خرید اشتراک، ۳ روز اشتراک رایگان هم به رفیقت هدیه داده میشه! 🤝🔥'",
        "  };",
        "}",
        "async function bmRegisterBetaSubscriber(env, userPhone) {",
        "  const st = await bmGetBetaStatus(env, userPhone);",
        "  if (st.isFull) return st;",
        "  try {",
        "    if (env && env.BODYMOD_DB_KV) {",
        "      const u6 = bmExtractLast6(userPhone) || String(userPhone || 'anon').trim();",
        "      const uTag = 'BETA_SUB_LOCK_' + u6;",
        "      const already = await env.BODYMOD_DB_KV.get(uTag);",
        "      if (!already) {",
        "        const nextSold = Math.min(BM_BETA_MAX_CAP, st.betaSold + 1);",
        "        await env.BODYMOD_DB_KV.put('GLOBAL_BETA_SUBSCRIBERS_COUNT', String(nextSold));",
        "        await env.BODYMOD_DB_KV.put(uTag, new Date().toISOString());",
        "        // اگر این کاربر با کد معرف دوستش آمده، ۳ روز اشتراک رایگان به دعوت‌کننده (کاربر الف) اضافه کن!",
        "        const usedRef = await env.BODYMOD_DB_KV.get('REF_USED_BY_' + u6);",
        "        const rewardedFlag = await env.BODYMOD_DB_KV.get('REF_REWARDED_' + u6);",
        "        if (usedRef && !rewardedFlag) {",
        "          const inv6 = bmExtractLast6(usedRef);",
        "          if (inv6 && inv6.length === 6 && inv6 !== u6) {",
        "            const prevCnt = parseInt((await env.BODYMOD_DB_KV.get('REF_INVITED_CNT_' + inv6)) || '0', 10) || 0;",
        "            const prevDays = parseInt((await env.BODYMOD_DB_KV.get('REF_BONUS_DAYS_' + inv6)) || '0', 10) || 0;",
        "            const prevUntil = parseInt((await env.BODYMOD_DB_KV.get('REF_VIP_UNTIL_' + inv6)) || '0', 10) || 0;",
        "            const baseTime = prevUntil > Date.now() ? prevUntil : Date.now();",
        "            const newUntil = baseTime + (3 * 86400 * 1000);",
        "            await env.BODYMOD_DB_KV.put('REF_INVITED_CNT_' + inv6, String(prevCnt + 1));",
        "            await env.BODYMOD_DB_KV.put('REF_BONUS_DAYS_' + inv6, String(prevDays + 3));",
        "            await env.BODYMOD_DB_KV.put('REF_VIP_UNTIL_' + inv6, String(newUntil));",
        "            await env.BODYMOD_DB_KV.put('REF_REWARDED_' + u6, 'true');",
        "          }",
        "        }",
        "      }",
        "    }",
        "  } catch (e) {}",
        "  return await bmGetBetaStatus(env, userPhone);",
        "}",
        "// --- [END BETA & REFERRAL ENGINE] ---",
    ])

    # جایگزینی نسخه قبلی موتور بتا در صورت وجود یا تزریق در ابتدای فایل
    if "bmApplyReferralCode" not in w_code:
        if "// --- [BODYMOD" in w_code and "// --- [END BETA COUNTDOWN ENGINE] ---" in w_code:
            s_i = w_code.find("// --- [BODYMOD")
            e_i = w_code.find("// --- [END BETA COUNTDOWN ENGINE] ---") + len("// --- [END BETA COUNTDOWN ENGINE] ---")
            w_code = w_code[:s_i] + BETA_AND_REFERRAL_WORKER + w_code[e_i:]
        else:
            w_code = BETA_AND_REFERRAL_WORKER + "\n" + w_code

    BETA_ROUTE_HANDLER = "\n".join([
        "    // --- روت شمارش معکوس ۱۰۰۰ نفر فاز بتا و سیستم دعوت از دوست (۳۰٪ تخفیف + ۳ روز رایگان) ---",
        "    if (request.url.includes('/api/beta-status') || request.url.includes('/api/referral')) {",
        "      const corsH = { 'Content-Type': 'application/json; charset=utf-8', 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'GET, POST, OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type, Authorization' };",
        "      if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsH });",
        "      const reqUrl = new URL(request.url);",
        "      const qPhone = reqUrl.searchParams.get('phone') || '';",
        "      if (request.method === 'POST') {",
        "        let bodyObj = {};",
        "        try { bodyObj = await request.json(); } catch (e) {}",
        "        const uPhone = bodyObj.phone || bodyObj.userId || qPhone;",
        "        if (bodyObj.action === 'apply_referral') {",
        "          const resObj = await bmApplyReferralCode(env, uPhone, bodyObj.referralCode || bodyObj.code || '');",
        "          return new Response(JSON.stringify(resObj), { status: resObj.ok ? 200 : 400, headers: corsH });",
        "        }",
        "        if (bodyObj.action === 'subscribe') {",
        "          const cur = await bmGetBetaStatus(env, uPhone);",
        "          if (cur.isFull) {",
        "            return new Response(JSON.stringify({ ok: false, error: 'رفیق ظرفیت ۱۰۰۰ نفری فاز بتا تکمیل شده و اشتراک جدیدی فروخته نمیشه! 🚀', ...cur }), { status: 403, headers: corsH });",
        "          }",
        "          const updated = await bmRegisterBetaSubscriber(env, uPhone || 'user_' + Date.now());",
        "          return new Response(JSON.stringify(updated), { status: 200, headers: corsH });",
        "        }",
        "      }",
        "      const st = await bmGetBetaStatus(env, qPhone);",
        "      return new Response(JSON.stringify(st), { status: 200, headers: corsH });",
        "    }",
    ])

    if "apply_referral" not in w_code:
        if "// --- روت شمارش معکوس" in w_code:
            r_s = w_code.find("    // --- روت شمارش معکوس")
            r_e = w_code.find("      return new Response(JSON.stringify(st), { status: 200, headers: corsH });\n    }", r_s)
            if r_e != -1:
                r_e += len("      return new Response(JSON.stringify(st), { status: 200, headers: corsH });\n    }")
                w_code = w_code[:r_s] + BETA_ROUTE_HANDLER + w_code[r_e:]
        else:
            w_code = re.sub(
                r"(async\s+fetch\s*\(\s*request\s*,\s*env(?:\s*,\s*ctx)?\s*\)\s*\{)",
                r"\1\n" + BETA_ROUTE_HANDLER,
                w_code,
                count=1,
            )

    with open(W_FILE, "w", encoding="utf-8") as wf:
        wf.write(w_code)
    print("✅ فایل worker.js با سیستم دعوت دوست (۳۰٪ تخفیف برای دوست + ۳ روز اشتراک رایگان برای دعوت‌کننده پس از خرید) آپدیت شد!")

# ==============================================================================
# بخش ۲: آپدیت فایل lib/main.dart (کارت دعوت دوست ۳۰٪ تخفیف / ۳ روز رایگان + شمارشگر ۱۰۰۰ نفری + کنتراست دارک/لایت)
# ==============================================================================
F = "lib/main.dart"
if not os.path.exists(F):
    sys.exit("❌ فایل lib/main.dart پیدا نشد!")

tmp_bak = "/data/data/com.termux/files/usr/tmp/main_dart_bak_v5.dart" if os.path.exists("/data/data/com.termux/files/usr/tmp") else "/tmp/main_dart_bak_v5.dart"
shutil.copyfile(F, tmp_bak)

with open(F, "r", encoding="utf-8") as f:
    c = f.read()

orig_parens = c.count("(") - c.count(")")
orig_braces = c.count("{") - c.count("}")
orig_bracks = c.count("[") - c.count("]")

if "import 'package:flutter/services.dart';" not in c and 'import "package:flutter/services.dart";' not in c:
    c = "import 'package:flutter/services.dart';\n" + c

c = shift_ai_models(c)
c = c.replace("int bmBetaCap = 5000;", "int bmBetaCap = 1000;")
c = c.replace("int bmBetaRemaining = 4999;", "int bmBetaRemaining = 999;")
c = c.replace("d['betaCap'] ?? 5000", "d['betaCap'] ?? 1000")
c = c.replace(") ?? 5000;", ") ?? 1000;")
c = c.replace("ظرفیت ۵۰۰۰ نفری فاز بتا", "ظرفیت ۱۰۰۰ نفری فاز بتا")
c = c.replace("فقط به ۵۰۰۰ نفر اشتراک", "فقط به ۱۰۰۰ نفر اشتراک")

url_m = re.search(r"https://[a-zA-Z0-9_.-]+\.workers\.dev", c)
worker_url = url_m.group(0) if url_m else "https://bodymod-core.matin-mohammadi.workers.dev"

dark_vars = re.findall(r"\b(_?[a-zA-Z0-9_]*(?:[dD]ark|[tT]heme)[a-zA-Z0-9_]*)\b", c)
dark_bool_var = None
for dv in dark_vars:
    if dv in ("dark", "darkTheme", "theme", "ThemeData", "ThemeMode", "bmIsDarkTheme"):
        continue
    if re.search(rf"bool\s+{re.escape(dv)}\b", c):
        dark_bool_var = dv
        break

main_idx = c.find("void main(")
if main_idx != -1:
    before_main = c[:main_idx]
    after_main = c[main_idx:]
    if dark_bool_var and f"(bmIsDarkTheme = {dark_bool_var})" not in after_main:
        after_main = re.sub(
            rf"\b{re.escape(dark_bool_var)}\s*\?",
            rf"(bmIsDarkTheme = {dark_bool_var}) ?",
            after_main,
        )
    c = before_main + after_main

main_idx = c.find("void main(")
top_part = c[:main_idx] if main_idx != -1 else ""
body_part = c[main_idx:] if main_idx != -1 else c

def replace_dark_hex_colors(match_obj):
    full_str = match_obj.group(0)
    hex_str = match_obj.group(1)
    val = int(hex_str, 16)
    r = (val >> 16) & 0xFF
    g = (val >> 8) & 0xFF
    b = val & 0xFF
    if r <= 0x12 and g <= 0x16 and b <= 0x20 and (r + g + b) > 0:
        return "bmBgColor"
    if r <= 0x1D and g <= 0x24 and b <= 0x34 and b >= r:
        return "bmCardColor"
    if r <= 0x2E and g <= 0x38 and b <= 0x4E and b > r:
        return "bmSurfaceColor"
    return full_str

body_part = re.sub(r"(?:const\s+)?Color\(\s*0xFF([0-9a-fA-F]{6})\s*\)", replace_dark_hex_colors, body_part)

body_part = re.sub(
    r"Colors\.(?:amber|yellow|orange|orangeAccent|amberAccent)\.withOpacity\(\s*0\.[0-4][0-9]*\s*\)",
    "bmYellowBoxColor",
    body_part,
)
body_part = re.sub(
    r"(?:const\s+)?Color\(\s*0xFF(?:F59E0B|FBBF24|FFA000|FF9800|FFB300|FBC02D)\s*\)\.withOpacity\(\s*0\.[0-4][0-9]*\s*\)",
    "bmYellowBoxColor",
    body_part,
)
body_part = re.sub(
    r"(?:const\s+)?Color\(\s*0xFF00(?:E5A3|FF66|C896)\s*\)\.withOpacity\(\s*0\.1[0-9]*\s*\)",
    "const Color(0xFF00E5A3)",
    body_part,
)
body_part = body_part.replace(
    "style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00E5A3))",
    "style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)",
)
body_part = body_part.replace(
    "style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00E5A3))",
    "style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)",
)

def fix_yellow_box_contrast(text):
    idx = 0
    while True:
        pos = text.find("bmYellowBoxColor", idx)
        if pos == -1:
            break
        end_w = min(len(text), pos + 650)
        seg = text[pos:end_w]
        seg_new = re.sub(
            r"color\s*:\s*(?:Colors\.(?:white|white70|white60|amber|amberAccent|orange|orangeAccent|yellow)|(?:const\s+)?Color\(0xFF(?:FFFFFF|F59E0B|FBBF24|FFA000|FFD54F|FFE082)\)|bmTextColor|bmTextSubColor)",
            "color: bmOnYellowBoxColor",
            seg,
        )
        text = text[:pos] + seg_new + text[end_w:]
        idx = pos + len(seg_new)
    return text

body_part = fix_yellow_box_contrast(body_part)

body_part = re.sub(r"\bColors\.white70\b", "bmTextSubColor", body_part)
body_part = re.sub(r"\bColors\.white60\b", "bmTextSubColor", body_part)
body_part = re.sub(r"\bColors\.white54\b", "bmTextMutedColor", body_part)
body_part = re.sub(r"\bColors\.white38\b", "bmTextMutedColor", body_part)
body_part = re.sub(r"\bColors\.white24\b", "bmBorderColor", body_part)
body_part = re.sub(r"\bColors\.white12\b", "bmBorderColor", body_part)
body_part = re.sub(r"\bColors\.white10\b", "bmBorderColor", body_part)
body_part = re.sub(r"(TextStyle\([^)]*?\bcolor\s*:\s*)Colors\.white\b", r"\1bmTextColor", body_part)
body_part = re.sub(r"(Icon\([^)]*?\bcolor\s*:\s*)Colors\.white\b", r"\1bmTextColor", body_part)

if "bmIsDarkTheme" in top_part:
    eng_end = top_part.find("// --- [END THEME ENGINE] ---")
    if eng_end != -1:
        t_head = top_part[:eng_end + 29]
        t_rest = top_part[eng_end + 29:]
        t_rest = re.sub(r"(?:const\s+)?Color\(\s*0xFF151922\s*\)", "bmCardColor", t_rest)
        t_rest = re.sub(r"(?:const\s+)?Color\(\s*0xFF161B26\s*\)", "bmCardColor", t_rest)
        t_rest = re.sub(r"(?:const\s+)?Color\(\s*0xFF1E2638\s*\)", "bmSurfaceColor", t_rest)
        t_rest = re.sub(r"\bColors\.white70\b", "bmTextSubColor", t_rest)
        t_rest = re.sub(r"\bColors\.white54\b", "bmTextMutedColor", t_rest)
        t_rest = re.sub(r"\bColors\.white38\b", "bmTextMutedColor", t_rest)
        t_rest = re.sub(r"\bColors\.white24\b", "bmBorderColor", t_rest)
        t_rest = re.sub(r"(TextStyle\([^)]*?\bcolor\s*:\s*)Colors\.white\b", r"\1bmTextColor", t_rest)
        top_part = t_head + t_rest

c = top_part + body_part
c = re.sub(r"(?:static\s+)?const\s+Color\s+([a-zA-Z0-9_]+)\s*=\s*(bm[a-zA-Z0-9_]+)\s*;", r"Color get \1 => \2;", c)

BETA_AND_REF_DART_ENGINE = "\n".join([
    "// --- [BODYMOD LIVE 1000-USER BETA COUNTDOWN & REFERRAL ENGINE] ---",
    "int bmBetaCap = 1000;",
    "int bmBetaSold = 1;",
    "int bmBetaRemaining = 999;",
    "bool bmBetaIsFull = false;",
    "String bmUserPhoneGlobal = '';",
    "int bmRefInvitedCount = 0;",
    "int bmRefBonusDays = 0;",
    "int bmRefActiveDaysLeft = 0;",
    "String bmAppliedRefCode = '';",
    "int bmDiscountPercent = 0;",
    "int bmFinalSubPrice = 189000;",
    "final TextEditingController bmRefInputCtrl = TextEditingController();",
    "bool bmRefSubmitting = false;",
    "",
    "String bmGetMyReferralCode() {",
    "  final digits = bmUserPhoneGlobal.replaceAll(RegExp(r'\\D'), '');",
    "  if (digits.length >= 6) return 'BM-' + digits.substring(digits.length - 6);",
    "  return 'BM-VIP100';",
    "}",
    "",
    "Future<void> bmSyncBetaCountdown({VoidCallback? onUpdated}) async {",
    "  try {",
    "    final prefs = await SharedPreferences.getInstance();",
    "    bmBetaSold = prefs.getInt('bm_beta_sold_v1') ?? bmBetaSold;",
    "    bmBetaRemaining = (bmBetaCap - bmBetaSold).clamp(0, bmBetaCap);",
    "    bmAppliedRefCode = prefs.getString('bm_applied_ref_code') ?? bmAppliedRefCode;",
    "    if (bmAppliedRefCode.isNotEmpty) { bmDiscountPercent = 30; bmFinalSubPrice = 132300; }",
    "    for (final k in prefs.getKeys()) {",
    "      final v = prefs.get(k);",
    "      if (v is String && RegExp(r'^(?:98|09|\\+98)\\d{8,10}$').hasMatch(v.trim())) {",
    "        bmUserPhoneGlobal = v.trim();",
    "        break;",
    "      }",
    "    }",
    "    final uri = Uri.parse('" + worker_url + "/api/beta-status?phone=' + Uri.encodeComponent(bmUserPhoneGlobal));",
    "    final res = await http.get(uri).timeout(const Duration(seconds: 10));",
    "    if (res.statusCode == 200) {",
    "      final d = jsonDecode(res.body);",
    "      if (d is Map) {",
    "        bmBetaCap = int.tryParse((d['betaCap'] ?? 1000).toString()) ?? 1000;",
    "        bmBetaSold = int.tryParse((d['betaSold'] ?? 1).toString()) ?? 1;",
    "        bmBetaRemaining = int.tryParse((d['betaRemaining'] ?? (bmBetaCap - bmBetaSold)).toString()) ?? (bmBetaCap - bmBetaSold);",
    "        bmBetaIsFull = bmBetaRemaining <= 0;",
    "        bmRefInvitedCount = int.tryParse((d['invitedCount'] ?? 0).toString()) ?? 0;",
    "        bmRefBonusDays = int.tryParse((d['bonusDaysEarned'] ?? 0).toString()) ?? 0;",
    "        bmRefActiveDaysLeft = int.tryParse((d['activeBonusDaysLeft'] ?? 0).toString()) ?? 0;",
    "        final srvRef = (d['appliedReferralCode'] ?? '').toString().trim();",
    "        if (srvRef.isNotEmpty) {",
    "          bmAppliedRefCode = srvRef;",
    "          bmDiscountPercent = 30;",
    "          bmFinalSubPrice = 132300;",
    "          await prefs.setString('bm_applied_ref_code', srvRef);",
    "        }",
    "        await prefs.setInt('bm_beta_sold_v1', bmBetaSold);",
    "        if (onUpdated != null) onUpdated();",
    "      }",
    "    }",
    "  } catch (_) {}",
    "}",
    "",
    "Future<void> bmSubmitFriendReferralCode(BuildContext context, VoidCallback onRefresh) async {",
    "  final rawCode = bmRefInputCtrl.text.trim();",
    "  if (rawCode.isEmpty) {",
    "    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رفیق اول کد معرف دوستت رو وارد کن! ✍️')));",
    "    return;",
    "  }",
    "  bmRefSubmitting = true;",
    "  onRefresh();",
    "  try {",
    "    await bmSyncBetaCountdown();",
    "    final res = await http.post(",
    "      Uri.parse('" + worker_url + "/api/referral'),",
    "      headers: {'Content-Type': 'application/json'},",
    "      body: jsonEncode({'action': 'apply_referral', 'phone': bmUserPhoneGlobal, 'referralCode': rawCode}),",
    "    ).timeout(const Duration(seconds: 12));",
    "    final d = jsonDecode(res.body);",
    "    if (res.statusCode == 200 && d['ok'] == true) {",
    "      final prefs = await SharedPreferences.getInstance();",
    "      bmAppliedRefCode = (d['appliedReferralCode'] ?? rawCode).toString();",
    "      bmDiscountPercent = 30;",
    "      bmFinalSubPrice = 132300;",
    "      await prefs.setString('bm_applied_ref_code', bmAppliedRefCode);",
    "      if (context.mounted) {",
    "        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((d['message'] ?? 'تبریک! ۳۰٪ تخفیف فاز بتا برات فعال شد! 🎉').toString()), backgroundColor: const Color(0xFF00C896)));",
    "      }",
    "    } else {",
    "      if (context.mounted) {",
    "        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((d['error'] ?? 'کد معرف نامعتبره رفیق!').toString()), backgroundColor: Colors.redAccent));",
    "      }",
    "    }",
    "  } catch (_) {",
    "    if (context.mounted) {",
    "      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطا در ارتباط با سرور کلودفلر! اینترنتت رو چک کن رفیق.'), backgroundColor: Colors.redAccent));",
    "    }",
    "  }",
    "  bmRefSubmitting = false;",
    "  onRefresh();",
    "}",
    "",
    "Widget bmBuildBetaCountdownBanner(VoidCallback onRefresh) {",
    "  final double ratio = (bmBetaRemaining / bmBetaCap).clamp(0.0, 1.0);",
    "  final myCode = bmGetMyReferralCode();",
    "  return Column(",
    "    crossAxisAlignment: CrossAxisAlignment.stretch,",
    "    children: [",
    "      Container(",
    "        margin: const EdgeInsets.only(top: 10, bottom: 10),",
    "        padding: const EdgeInsets.all(12),",
    "        decoration: BoxDecoration(",
    "          color: bmYellowBoxColor,",
    "          borderRadius: BorderRadius.circular(14),",
    "          border: Border.all(color: Colors.black26, width: 1.2),",
    "        ),",
    "        child: Column(",
    "          crossAxisAlignment: CrossAxisAlignment.start,",
    "          children: [",
    "            Row(",
    "              mainAxisAlignment: MainAxisAlignment.spaceBetween,",
    "              children: [",
    "                Expanded(",
    "                  child: Text(",
    "                    bmBetaIsFull ? '⛔ ظرفیت ۱۰۰۰ نفری فاز بتا تکمیل شد!' : '⏳ ظرفیت باقی‌مانده فاز بتا: $bmBetaRemaining از $bmBetaCap نفر 🔥',",
    "                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: bmOnYellowBoxColor),",
    "                  ),",
    "                ),",
    "                InkWell(",
    "                  onTap: () => bmSyncBetaCountdown(onUpdated: onRefresh),",
    "                  child: Icon(Icons.sync_rounded, size: 18, color: bmOnYellowBoxColor),",
    "                ),",
    "              ],",
    "            ),",
    "            const SizedBox(height: 6),",
    "            ClipRRect(",
    "              borderRadius: BorderRadius.circular(6),",
    "              child: LinearProgressIndicator(",
    "                value: ratio,",
    "                minHeight: 7,",
    "                backgroundColor: Colors.black26,",
    "                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),",
    "              ),",
    "            ),",
    "            const SizedBox(height: 6),",
    "            Text(",
    "              bmDiscountPercent == 30",
    "                  ? '🎉 ۳۰٪ تخفیف دعوت دوست برات فعاله! مبلغ اشتراک تو: ۱۳۲,۳۰۰ تومان (به جای ۱۸۹,۰۰۰ تومان)'",
    "                  : 'توی فاز بتا فقط به ۱۰۰۰ نفر اشتراک فروخته میشه! شمارشگر زنده به سرور کلودفلر وصله ⚡',",
    "              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: bmOnYellowBoxColor),",
    "            ),",
    "          ],",
    "        ),",
    "      ),",
    "      Container(",
    "        margin: const EdgeInsets.only(bottom: 12),",
    "        padding: const EdgeInsets.all(12),",
    "        decoration: BoxDecoration(",
    "          color: bmSurfaceColor,",
    "          borderRadius: BorderRadius.circular(14),",
    "          border: Border.all(color: const Color(0xFF00E5A3).withOpacity(0.55)),",
    "        ),",
    "        child: Column(",
    "          crossAxisAlignment: CrossAxisAlignment.stretch,",
    "          children: [",
    "            Row(",
    "              children: [",
    "                const Icon(Icons.card_giftcard_rounded, color: Color(0xFF00E5A3), size: 20),",
    "                const SizedBox(width: 6),",
    "                Expanded(",
    "                  child: Text(",
    "                    'دعوت از رفیق: ۳۰٪ تخفیف برای دوستت + ۳ روز اشتراک رایگان برای تو! 🎁🤝',",
    "                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: bmTextColor),",
    "                  ),",
    "                ),",
    "              ],",
    "            ),",
    "            const SizedBox(height: 6),",
    "            Text(",
    "              'کد دعوت اختصاصی خودت رو بفرست برای رفیقت؛ وقتی با کد تو ثبت‌نام کنه ۳۰٪ تخفیف اشتراک فاز بتا می‌گیره (۱۳۲,۳۰۰ تومان) و به محض اینکه اشتراک رو بخره، ۳ روز اشتراک کامل رایگان به اکانت تو اضافه میشه! 🔥',",
    "              style: TextStyle(fontSize: 11, color: bmTextSubColor, height: 1.45),",
    "            ),",
    "            const SizedBox(height: 8),",
    "            Container(",
    "              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),",
    "              decoration: BoxDecoration(color: bmCardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: bmBorderColor)),",
    "              child: Row(",
    "                mainAxisAlignment: MainAxisAlignment.spaceBetween,",
    "                children: [",
    "                  Text('کد دعوت تو: $myCode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: bmTextColor)),",
    "                  ElevatedButton.icon(",
    "                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5A3), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),",
    "                    onPressed: () {",
    "                      final inviteMsg = 'رفیق بیا توی برنامه بادی‌مود (مربی هوشمند بدنسازی و تغذیه)! 💪🔥 موقع خرید اشتراک فاز بتا کد دعوت من ($myCode) رو بزن تا ۳۰٪ تخفیف بگیری (۱۳۲,۳۰۰ تومن به جای ۱۸۹,۰۰۰ تومن) و ۳ روز هم به من اشتراک رایگان هدیه بده! 🚀\\nhttps://matin-mohammadi.ir/?ref=$myCode';",
    "                      Clipboard.setData(ClipboardData(text: inviteMsg));",
    "                    },",
    "                    icon: const Icon(Icons.copy_rounded, size: 15, color: Colors.black),",
    "                    label: const Text('کپی لینک و کد دعوت', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),",
    "                  ),",
    "                ],",
    "              ),",
    "            ),",
    "            if (bmRefInvitedCount > 0 || bmRefBonusDays > 0) ...[",
    "              const SizedBox(height: 6),",
    "              Text('🏆 دوستان خریدکرده با کد تو: $bmRefInvitedCount نفر | هدیه تو: $bmRefBonusDays روز اشتراک رایگان (فعال: $bmRefActiveDaysLeft روز)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00E5A3))),",
    "            ],",
    "            const SizedBox(height: 10),",
    "            Row(",
    "              children: [",
    "                Expanded(",
    "                  child: TextField(",
    "                    controller: bmRefInputCtrl,",
    "                    style: TextStyle(fontSize: 12.5, color: bmTextColor),",
    "                    decoration: InputDecoration(",
    "                      hintText: bmAppliedRefCode.isNotEmpty ? 'کد فعال: $bmAppliedRefCode (۳۰٪ تخفیف)' : 'کد دعوت رفیقت رو داری؟ (مثلاً BM-586834)',",
    "                      hintStyle: TextStyle(fontSize: 11, color: bmTextMutedColor),",
    "                      isDense: true,",
    "                      filled: true,",
    "                      fillColor: bmCardColor,",
    "                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),",
    "                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bmBorderColor)),",
    "                    ),",
    "                  ),",
    "                ),",
    "                const SizedBox(width: 8),",
    "                 Builder(",
    "                  builder: (btnCtx) => ElevatedButton(",
    "                    style: ElevatedButton.styleFrom(backgroundColor: bmYellowBoxColor, foregroundColor: bmOnYellowBoxColor, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),",
    "                    onPressed: bmRefSubmitting ? null : () => bmSubmitFriendReferralCode(btnCtx, onRefresh),",
    "                    child: Text(bmRefSubmitting ? '...' : 'دریافت ۳۰٪ تخفیف', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: bmOnYellowBoxColor)),",
    "                  ),",
    "                ),",
    "              ],",
    "            ),",
    "          ],",
    "        ),",
    "      ),",
    "    ],",
    "  );",
    "}",
    "// --- [END BETA COUNTDOWN ENGINE] ---",
])

if "bmSubmitFriendReferralCode" not in c:
    if "// --- [BODYMOD LIVE" in c and "// --- [END BETA COUNTDOWN ENGINE] ---" in c:
        b_s = c.find("// --- [BODYMOD LIVE")
        b_e = c.find("// --- [END BETA COUNTDOWN ENGINE] ---") + len("// --- [END BETA COUNTDOWN ENGINE] ---")
        c = c[:b_s] + BETA_AND_REF_DART_ENGINE + c[b_e:]
    else:
        c = c.replace("void main(", BETA_AND_REF_DART_ENGINE + "\nvoid main(", 1)
        c = re.sub(
            r"(WidgetsFlutterBinding\.ensureInitialized\(\)\s*;)",
            r"\1 bmSyncBetaCountdown();",
            c,
            count=1,
        )

sub_idx = c.find("اشتراک ۱ ماهه بادی‌مود")
if sub_idx != -1 and "bmBuildBetaCountdownBanner" not in c:
    post_sub = c[sub_idx:min(len(c), sub_idx + 800)]
    sb_m = re.search(r"SizedBox\(\s*height\s*:\s*\d+(?:\.\d+)?\s*\)\s*,", post_sub)
    if sb_m:
        ins_pos = sub_idx + sb_m.end()
        c = c[:ins_pos] + " bmBuildBetaCountdownBanner(() => setState(() {}))," + c[ins_pos:]
        print("✅ بنر شمارش معکوس ۱۰۰۰ نفری + کارت دعوت از دوست (۳۰٪ تخفیف / ۳ روز اشتراک رایگان) به پروفایل اضافه شد!")

def strip_invalid_consts(text):
    dyn_tokens = (
        "bmCardColor", "bmSurfaceColor", "bmBgColor", "bmTextColor",
        "bmTextSubColor", "bmTextMutedColor", "bmBorderColor",
        "bmYellowBoxColor", "bmOnYellowBoxColor", "bmAccentColor",
        "bmExStr", "bmBuildBetaCountdownBanner", "bmBetaRemaining",
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
                if text[i] == open_ch:
                    depth += 1
                elif text[i] == close_ch:
                    depth -= 1
                    if depth == 0:
                        close_pos = i + 1
                        break
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

THEME_ENGINE = "\n".join([
    "// --- [BODYMOD HIGH-CONTRAST DARK & LIGHT THEME ENGINE] ---",
    "bool bmIsDarkTheme = true;",
    "Color get bmBgColor => bmIsDarkTheme ? const Color(0xFF0B0F17) : const Color(0xFFF1F5F9);",
    "Color get bmCardColor => bmIsDarkTheme ? const Color(0xFF151B26) : const Color(0xFFFFFFFF);",
    "Color get bmSurfaceColor => bmIsDarkTheme ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0);",
    "Color get bmTextColor => bmIsDarkTheme ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);",
    "Color get bmTextSubColor => bmIsDarkTheme ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);",
    "Color get bmTextMutedColor => bmIsDarkTheme ? const Color(0xFFCBD5E1) : const Color(0xFF334155);",
    "Color get bmBorderColor => bmIsDarkTheme ? const Color(0xFF334155) : const Color(0xFFCBD5E1);",
    "Color get bmAccentColor => bmIsDarkTheme ? const Color(0xFF00E5A3) : const Color(0xFF059669);",
    "Color get bmOnAccentColor => bmIsDarkTheme ? const Color(0xFF000000) : const Color(0xFFFFFFFF);",
    "Color get bmYellowBoxColor => const Color(0xFFFBBF24);",
    "Color get bmOnYellowBoxColor => const Color(0xFF0F172A);",
    "// --- [END THEME ENGINE] ---",
])

if "bool bmIsDarkTheme" not in c:
    c = c.replace("void main(", THEME_ENGINE + "\nvoid main(", 1)

if (c.count("(") - c.count(")")) != orig_parens or (c.count("{") - c.count("}")) != orig_braces or (c.count("[") - c.count("]")) != orig_bracks:
    sys.exit("❌ خطا در توازن پرانتز/آکولاد در lib/main.dart! فایل تغییر نکرد.")

with open(F, "w", encoding="utf-8") as f:
    f.write(c)

print("🎉 آپدیت کامل سیستم دعوت از دوست (۳۰٪ تخفیف برای دوست + ۳ روز اشتراک رایگان برای دعوت‌کننده)، شمارشگر ۱۰۰۰ نفری بتا و کنتراست دارک/لایت انجام شد!")
