# -*- coding: utf-8 -*-
import os, re, shutil, sys

F = "lib/main.dart"
if not os.path.exists(F):
    sys.exit("❌ فایل lib/main.dart پیدا نشد!")

tmp_bak = "/data/data/com.termux/files/usr/tmp/main_dart_theme_bak.dart" if os.path.exists("/data/data/com.termux/files/usr/tmp") else "/tmp/main_dart_theme_bak.dart"
shutil.copyfile(F, tmp_bak)

with open(F, "r", encoding="utf-8") as f:
    c = f.read()

orig_parens = c.count("(") - c.count(")")
orig_braces = c.count("{") - c.count("}")
orig_bracks = c.count("[") - c.count("]")

# ۱. پیدا کردن متغیر دارک‌مود در برنامه اصلی و همگام‌سازی خودکار با bmIsDarkTheme
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
    if dark_bool_var:
        # همگام‌سازی درون‌خطی و امن در تمام عبارات شرطی دارک‌مود بدون به هم زدن بدنه کلاس‌ها
        after_main = re.sub(
            rf"\b{re.escape(dark_bool_var)}\s*\?",
            rf"(bmIsDarkTheme = {dark_bool_var}) ?",
            after_main,
        )
    else:
        after_main = re.sub(
            r"(Widget\s+build\s*\(\s*BuildContext\s+context\s*\)\s*\{)",
            r"\1 bmIsDarkTheme = Theme.of(context).brightness == Brightness.dark;",
            after_main,
        )
    c = before_main + after_main

# ۲. تبدیل باکس‌های زرد/نارنجی کم‌رنگ با متن سفید به باکس زرد پررنگ با کنتراست بالا و متن مشکی
c = re.sub(
    r"Colors\.(?:amber|yellow|orange|orangeAccent|amberAccent)\.withOpacity\(\s*0\.[0-4][0-9]*\s*\)",
    "bmYellowBoxColor",
    c,
)
c = re.sub(
    r"(?:const\s+)?Color\(\s*0xFF(?:F59E0B|FBBF24|FFA000|FF9800|FFB300|FBC02D)\s*\)\.withOpacity\(\s*0\.[0-4][0-9]*\s*\)",
    "bmYellowBoxColor",
    c,
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
            r"color\s*:\s*(?:Colors\.(?:white|white70|white60|amber|amberAccent|orange|orangeAccent|yellow)|(?:const\s+)?Color\(0xFF(?:FFFFFF|F59E0B|FBBF24|FFA000|FFD54F|FFE082)\))",
            "color: bmOnYellowBoxColor",
            seg,
        )
        text = text[:pos] + seg_new + text[end_w:]
        idx = pos + len(seg_new)
    return text

c = fix_yellow_box_contrast(c)

# ۳. تبدیل رنگ‌های پس‌زمینه و متون ثابت به رنگ‌های دوگانه دارک/لایت با کنتراست بالا (قبل از تزریق THEME_ENGINE)
for hex_card in ["0xFF151922", "0xFF161B26", "0xFF1A1A24", "0xFF161B22", "0xFF141824", "0xFF151B26"]:
    c = re.sub(rf"(?:const\s+)?Color\(\s*{hex_card}\s*\)", "bmCardColor", c)

for hex_surf in ["0xFF1E2638", "0xFF1E293B", "0xFF21262D", "0xFF252B3B"]:
    c = re.sub(rf"(?:const\s+)?Color\(\s*{hex_surf}\s*\)", "bmSurfaceColor", c)

for hex_bg in ["0xFF0D0D11", "0xFF0B0F17", "0xFF0D1117", "0xFF090D16"]:
    c = re.sub(rf"(?:const\s+)?Color\(\s*{hex_bg}\s*\)", "bmBgColor", c)

c = re.sub(r"(?:static\s+)?const\s+Color\s+([a-zA-Z0-9_]+)\s*=\s*(bm[a-zA-Z0-9_]+)\s*;", r"Color get \1 => \2;", c)

c = re.sub(r"\bColors\.white70\b", "bmTextSubColor", c)
c = re.sub(r"\bColors\.white60\b", "bmTextSubColor", c)
c = re.sub(r"\bColors\.white54\b", "bmTextMutedColor", c)
c = re.sub(r"\bColors\.white38\b", "bmTextMutedColor", c)
c = re.sub(r"\bColors\.white24\b", "bmBorderColor", c)
c = re.sub(r"\bColors\.white12\b", "bmBorderColor", c)
c = re.sub(r"\bColors\.white10\b", "bmBorderColor", c)

c = re.sub(r"(TextStyle\([^)]*?\bcolor\s*:\s*)Colors\.white\b", r"\1bmTextColor", c)
c = re.sub(r"(Icon\([^)]*?\bcolor\s*:\s*)Colors\.white\b", r"\1bmTextColor", c)

c = re.sub(
    r"(backgroundColor\s*:\s*(?:const\s+)?Color\(0xFF00(?:E5A3|FF66|C896)\)\s*,\s*foregroundColor\s*:\s*)Colors\.white\b",
    r"\1Colors.black",
    c,
)

# ۴. حذف هوشمند کلمه کلیدی const از هر عبارت (...) یا [...] که داخل آن از متغیرهای پویا (bm...) استفاده شده است
def strip_invalid_consts(text):
    dyn_tokens = ("bmCardColor", "bmSurfaceColor", "bmBgColor", "bmTextColor", "bmTextSubColor", "bmTextMutedColor", "bmBorderColor", "bmYellowBoxColor", "bmOnYellowBoxColor", "bmAccentColor", "bmExStr")
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
            for i in range(open_pos, min(len(text), open_pos + 6000)):
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

# ۵. تزریق موتور استاندارد دارک‌مود و لایت‌مود در بالای void main
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
    sys.exit("❌ خطا در توازن پرانتز/آکولاد! فایل تغییر نکرد.")

with open(F, "w", encoding="utf-8") as f:
    f.write(c)

print("✅ استانداردسازی کامل دارک‌مود و لایت‌مود با کنتراست بالا با موفقیت در lib/main.dart اعمال شد!")
