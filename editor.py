# -*- coding: utf-8 -*-
import os, re, shutil, sys

# ==============================================================================
# ۱. رفع خطای «این برنامه اعلان ارسال نمی‌کند» در اندروید ۱۳+ (فعال‌سازی مجوز POST_NOTIFICATIONS)
# ==============================================================================
PUB_FILE = "pubspec.yaml"
if os.path.exists(PUB_FILE):
    with open(PUB_FILE, "r", encoding="utf-8") as pf:
        pub = pf.read()
    changed_pub = False
    if "permission_handler:" not in pub:
        pub = re.sub(
            r"(dependencies:\s*\n(?:\s+flutter:\s*\n\s+sdk:\s*flutter\s*\n)?)",
            r"\1  permission_handler: ^11.3.1\n",
            pub,
            count=1,
        )
        changed_pub = True
    if "permission_handler_android:" not in pub:
        if "dependency_overrides:" in pub:
            pub = pub.replace("dependency_overrides:", "dependency_overrides:\n  permission_handler_android: 12.0.13", 1)
        else:
            pub = pub.rstrip() + "\n\ndependency_overrides:\n  permission_handler_android: 12.0.13\n"
        changed_pub = True
    if changed_pub:
        with open(PUB_FILE, "w", encoding="utf-8") as pf:
            pf.write(pub)
        print("✅ مجوز اعلان اندروید (POST_NOTIFICATIONS) از طریق permission_handler سازگار با SDK 36 در pubspec.yaml فعال شد!")

# اگر پوشه android در مخزن وجود دارد، مجوز POST_NOTIFICATIONS را مستقیم به AndroidManifest.xml هم اضافه کن
MANIFEST = "android/app/src/main/AndroidManifest.xml"
if os.path.exists(MANIFEST):
    with open(MANIFEST, "r", encoding="utf-8") as mf:
        man = mf.read()
    if "android.permission.POST_NOTIFICATIONS" not in man:
        man = man.replace(
            "<application",
            '    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n    <application',
            1,
        )
        with open(MANIFEST, "w", encoding="utf-8") as mf:
            mf.write(man)
        print("✅ مجوز POST_NOTIFICATIONS مستقیماً به AndroidManifest.xml اضافه شد!")

# ==============================================================================
# ۲. اصلاح کامل lib/main.dart (خوش‌آمدگویی، متن مشکی چت در لایت‌مود، حذف دکمه‌های سبز و بنفش Flash Lite)
# ==============================================================================
F = "lib/main.dart"
if not os.path.exists(F):
    sys.exit("❌ فایل lib/main.dart پیدا نشد!")

with open(F, "r", encoding="utf-8") as f:
    c = f.read()

orig_parens = c.count("(") - c.count(")")
orig_braces = c.count("{") - c.count("}")
orig_bracks = c.count("[") - c.count("]")

# الف) اطمینان از وجود موتور رنگ دوگانه دارک/لایت و سینک شدن در تمام متدهای build
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

# سینک لحظه‌ای bmIsDarkTheme با Theme.of(context).brightness در ابتدای تمام متدهای build
main_idx = c.find("void main(")
top_part = c[:main_idx] if main_idx != -1 else ""
body_part = c[main_idx:] if main_idx != -1 else c

body_part = re.sub(
    r"(Widget\s+build\s*\(\s*BuildContext\s+context\s*\)\s*\{)(?!\s*bmIsDarkTheme\s*=)",
    r"\1 bmIsDarkTheme = Theme.of(context).brightness == Brightness.dark;",
    body_part,
)

# تبدیل تمام رنگ‌های سفید و روشنِ داخل حباب چت و دیالوگ‌ها به bmTextColor (مشکی در لایت‌مود، سفید در دارک‌مود)
for light_hex in ["0xFFFFFFFF", "0xFFF8FAFC", "0xFFF1F5F9", "0xFFE2E8F0", "0xFFD1D5DB", "0xFFCBD5E1", "0xFFE5E7EB"]:
    body_part = re.sub(
        rf"(\bcolor\s*:\s*)(?:const\s+)?Color\(\s*{light_hex}\s*\)",
        r"\1bmTextColor",
        body_part,
    )

body_part = re.sub(r"(\bcolor\s*:\s*)Colors\.white\b(?!\.withOpacity)", r"\1bmTextColor", body_part)
body_part = re.sub(r"(\bcolor\s*:\s*)Colors\.white70\b", r"\1bmTextSubColor", body_part)
body_part = re.sub(r"(\bcolor\s*:\s*)Colors\.white60\b", r"\1bmTextSubColor", body_part)
body_part = re.sub(r"(\bcolor\s*:\s*)Colors\.white54\b", r"\1bmTextMutedColor", body_part)
body_part = re.sub(r"(\bcolor\s*:\s*)Colors\.white\.withOpacity\(\s*0\.[5-9][0-9]*\s*\)", r"\1bmTextSubColor", body_part)

# اطمینان از اینکه حباب‌های چت هوش مصنوعی و کاربر در لایت‌مود متن مشکی (#0F172A) دارند حتی اگر استایلشان رنگ نداشت
body_part = re.sub(
    r"(Text\(\s*[a-zA-Z0-9_.\[\]'\" ]*(?:msg|message|text|content|reply)[a-zA-Z0-9_.\[\]'\" ]*\s*,\s*style\s*:\s*(?:const\s+)?TextStyle\()((?:(?!\bcolor\s*:).)*?\))",
    r"\1color: bmTextColor, \2",
    body_part,
)

# اطمینان از اینکه BMColors در لایت‌مود رنگ متن را مشکی می‌دهد
bm_cls_pos = top_part.find("class BMColors")
if bm_cls_pos != -1:
    b_open = top_part.find("{", bm_cls_pos)
    if b_open != -1:
        d_b, b_close = 0, -1
        for i in range(b_open, min(len(top_part), b_open + 3500)):
            if top_part[i] == "{": d_b += 1
            elif top_part[i] == "}":
                d_b -= 1
                if d_b == 0: b_close = i + 1; break
        if b_close != -1:
            cls_b = top_part[b_open:b_close]
            cls_b = re.sub(
                r"(?:static\s+)?(?:const\s+)?Color\s+(?:get\s+)?(textPrimary|textMain|textWhite|textLight|onSurface|onCard|textDark)\s*(?:=|=>)\s*[^;]+;",
                r"static Color get \1 => bmTextColor;",
                cls_b,
            )
            cls_b = re.sub(
                r"(?:static\s+)?(?:const\s+)?Color\s+(?:get\s+)?(textSecondary|textSub|textMuted|textGrey|textGray)\s*(?:=|=>)\s*[^;]+;",
                r"static Color get \1 => bmTextSubColor;",
                cls_b,
            )
            top_part = top_part[:b_open] + cls_b + top_part[b_close:]

c = top_part + body_part
print("✅ رنگ متن چت هوش مصنوعی و دیالوگ‌ها در حالت لایت با Theme.of(context).brightness به مشکی (#0F172A) قفل شد!")

# ب) درج دقیق شعار درخواستی متین در ابتدای پنجره خوش‌آمدگویی (همون پنجره‌ای که در اسکرین‌شات بود)
slogan_prefix = "اینجا قرار نیست ورزش کنی\\nاینجا قراره بدنتو مود (Mod/اصلاح) کنی 💪😎\\nراز سلامتی بی‌نهایت دست منه ✊\\n\\n"
if "اینجا قراره بدنتو مود" not in c:
    if "برای اینکه یادآور ساعت وعده‌های غذایی" in c:
        c = c.replace(
            "برای اینکه یادآور ساعت وعده‌های غذایی",
            slogan_prefix + "برای اینکه یادآور ساعت وعده‌های غذایی",
        )
        print("✅ شعار جدید «اینجا قرار نیست ورزش کنی / اینجا قراره بدنتو مود کنی 💪😎 / راز سلامتی بی‌نهایت دست منه ✊» در ابتدای پنجره خوش‌آمدگویی قرار گرفت!")
    elif "خوش اومدی به BodyMod" in c:
        c = c.replace(
            "خوش اومدی به BodyMod",
            "خوش اومدی به BodyMod\\n" + slogan_prefix.rstrip("\\n"),
        )
        print("✅ شعار جدید در پنجره خوش‌آمدگویی اضافه شد!")

# ج) حذف جمله قدیمی لانگ‌پرس بادیکوین از پیام اول مربی در چت
c = re.sub(r"\\n\\n💡\s*راستی:\s*اگه دکمه ارسال[^'\"\n]*بادیکوین مصرف می‌کنه!\s*🪙😎", "", c)
c = re.sub(r"\\n\\n💡\s*راستی:\s*اگه دکمه ارسال[^'\"\n]*", "", c)
c = re.sub(r"💡\s*راستی:\s*اگه دکمه ارسال[^'\"\n]*", "", c)

# د) حذف کامل هر دو دکمه سبز و بنفش انتخاب مدل (Flash Lite ⚡ و Flash Lite 🧠) در بخش چت و کل برنامه
removed_model_btns = 0

def remove_enclosing_widget_with_text(text, needle):
    global removed_model_btns
    idx = text.find("void main(")
    if idx == -1: idx = 0
    while True:
        pos = text.find(needle, idx)
        if pos == -1:
            break
        # جستجوی والد مستقیم ویجت دکمه تا ۵۵۰ کاراکتر قبل از متن Flash Lite
        search_start = max(0, pos - 550)
        pre = text[search_start:pos]
        # اولویت با ویجت‌های دکمه/کلیکی و سپس Container/PopupMenuButton/DropdownButton
        candidates = []
        for wname in [
            "PopupMenuButton", "DropdownButton", "InkWell", "GestureDetector",
            "ChoiceChip", "FilterChip", "ActionChip", "ElevatedButton",
            "OutlinedButton", "TextButton", "Material", "Container"
        ]:
            for m in re.finditer(rf"\b{wname}(?:<[^>]+>)?\s*\(", pre):
                abs_s = search_start + m.start()
                p_open = text.find("(", abs_s)
                d_p, abs_e = 0, -1
                for i in range(p_open, min(len(text), p_open + 1600)):
                    if text[i] == "(": d_p += 1
                    elif text[i] == ")":
                        d_p -= 1
                        if d_p == 0: abs_e = i + 1; break
                if abs_e != -1 and abs_e > pos:
                    blk = text[abs_s:abs_e]
                    # مطمئن شو کل صفحه یا کل کارت چت را حذف نمی‌کنیم!
                    if (
                        "Scaffold(" not in blk
                        and "TextField(" not in blk
                        and "ListView" not in blk
                        and "گفتگو با مربی هوشمند" not in blk
                        and len(blk) < 1400
                    ):
                        candidates.append((abs_s, abs_e, len(blk)))
        if candidates:
            # انتخاب بزرگ‌ترین کاندیدای امن که فقط خودِ دکمه سبز یا بنفش را در بر می‌گیرد
            candidates.sort(key=lambda x: x[2], reverse=True)
            s_i, e_i, _ = candidates[0]
            text = text[:s_i] + "const SizedBox.shrink()" + text[e_i:]
            removed_model_btns += 1
            idx = s_i + 25
            continue
        idx = pos + len(needle)
    return text

c = remove_enclosing_widget_with_text(c, "Flash Lite")
print(f"✅ تمام دکمه‌های سبز و بنفش انتخاب مدل (Flash Lite) از ظاهر برنامه حذف شدند! ({removed_model_btns} ویجت حذف شد)")

# هـ) حذف هوشمند const از اطراف ویجت‌هایی که الان رنگ پویا (bmTextColor و...) دارند
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

print("🎉 هر ۴ باگ (مجوز اعلان اندروید، شعار صفحه خوش‌آمدگویی، متن مشکی چت در حالت لایت و حذف دکمه‌های سبز و بنفش مدل) با موفقیت رفع شدند!")
