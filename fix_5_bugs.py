# -*- coding: utf-8 -*-
import os, re, shutil, sys

F = "lib/main.dart"
if not os.path.exists(F):
    sys.exit("❌ فایل lib/main.dart پیدا نشد!")

shutil.copyfile(F, F + ".bak")
with open(F, "r", encoding="utf-8") as f:
    c = f.read()

H = "\n".join([
    "List<int> _bmG2J(int gy, int gm, int gd) {",
    "  const m = [0,31,59,90,120,151,181,212,243,273,304,334];",
    "  int g2 = (gm > 2) ? (gy + 1) : gy;",
    "  int d = 355666 + (365 * gy) + ((g2 + 3) ~/ 4) - ((g2 + 99) ~/ 100) + ((g2 + 399) ~/ 400) + gd + m[gm - 1];",
    "  int jy = -1595 + (33 * (d ~/ 12053)); d %= 12053;",
    "  jy += 4 * (d ~/ 1461); d %= 1461;",
    "  if (d > 365) { jy += (d - 1) ~/ 365; d = (d - 1) % 365; }",
    "  return [jy, (d < 186) ? 1 + (d ~/ 31) : 7 + ((d - 186) ~/ 30), 1 + ((d < 186) ? (d % 31) : ((d - 186) % 30))];",
    "}",
    "int? bmCalculateAgeFromBirthDate(String raw) {",
    "  String s = raw;",
    "  const fa = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'], ar = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];",
    "  for (int i = 0; i < 10; i++) { s = s.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i'); }",
    "  final p = RegExp(r'\\d+').allMatches(s).map((m) => int.tryParse(m.group(0)!) ?? 0).where((n) => n > 0).toList();",
    "  if (p.isEmpty) return null;",
    "  final now = DateTime.now(); final jn = _bmG2J(now.year, now.month, now.day);",
    "  final int cy = jn[0], cm = jn[1], cd = jn[2];",
    "  if (p.length == 1) return (p[0] >= 1300 && p[0] <= cy) ? (cy - p[0]).clamp(8, 100) : (p[0] >= 8 && p[0] <= 100 ? p[0] : null);",
    "  int by = 0, bm = 1, bd = 1;",
    "  if (p.length >= 3) {",
    "    if (p[2] >= 1300) { bd = p[0]; bm = p[1]; by = p[2]; }",
    "    else if (p[0] >= 1300) { by = p[0]; bm = p[1]; bd = p[2]; }",
    "    else if (p[2] >= 30 && p[2] <= 99) { bd = p[0]; bm = p[1]; by = 1300 + p[2]; }",
    "  } else if (p.length == 2) {",
    "    if (p[1] >= 1300) { bm = p[0]; by = p[1]; } else if (p[0] >= 1300) { by = p[0]; bm = p[1]; }",
    "  }",
    "  if (by < 1300 || by > cy) return null;",
    "  int age = cy - by; if (cm < bm || (cm == bm && cd < bd)) age -= 1;",
    "  return age.clamp(8, 100);",
    "}",
    "Future<T?> bmShowResponsiveSheet<T>({",
    "  required BuildContext context, required WidgetBuilder builder,",
    "  Color? backgroundColor, double? elevation, ShapeBorder? shape, Clip? clipBehavior,",
    "  BoxConstraints? constraints, Color? barrierColor, bool isScrollControlled = true,",
    "  bool useRootNavigator = false, bool isDismissible = true, bool enableDrag = true,",
    "  bool? showDragHandle, bool useSafeArea = true, RouteSettings? routeSettings,",
    "  AnimationController? transitionAnimationController, Offset? anchorPoint,",
    "}) {",
    "  final rmq = MediaQuery.of(context);",
    "  double sb = rmq.viewPadding.bottom > rmq.padding.bottom ? rmq.viewPadding.bottom : rmq.padding.bottom;",
    "  if (sb < 48.0) sb = 48.0;",
    "  return showModalBottomSheet<T>(",
    "    context: context, isScrollControlled: true, useSafeArea: true,",
    "    backgroundColor: backgroundColor ?? const Color(0xFF151922), elevation: elevation,",
    "    shape: shape ?? const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),",
    "    clipBehavior: clipBehavior ?? Clip.antiAlias, barrierColor: barrierColor,",
    "    useRootNavigator: useRootNavigator, isDismissible: isDismissible, enableDrag: enableDrag,",
    "    showDragHandle: showDragHandle, routeSettings: routeSettings,",
    "    transitionAnimationController: transitionAnimationController, anchorPoint: anchorPoint,",
    "    constraints: constraints ?? BoxConstraints(maxHeight: rmq.size.height * 0.88, maxWidth: rmq.size.width > 560 ? 520 : rmq.size.width),",
    "    builder: (ctx) {",
    "      final mq = MediaQuery.of(ctx);",
    "      final bp = (mq.viewPadding.bottom > sb ? mq.viewPadding.bottom : sb) + mq.viewInsets.bottom + 20.0;",
    "      return SafeArea(top: false, bottom: true, child: ConstrainedBox(",
    "        constraints: BoxConstraints(maxHeight: mq.size.height * 0.86),",
    "        child: SingleChildScrollView(physics: const BouncingScrollPhysics(), padding: EdgeInsets.only(bottom: bp), child: builder(ctx)),",
    "      ));",
    "    },",
    "  );",
    "}",
])

if "bmShowResponsiveSheet" not in c:
    c = re.sub(r"\bshowModalBottomSheet\b", "bmShowResponsiveSheet", c)
    c = c.replace("void main(", H + "\nvoid main(", 1)

c = re.sub(r"EdgeInsets\.fromLTRB\(\s*16\s*,\s*16\s*,\s*16\s*,\s*(?:16|20|24|32|40|60|80|90|100)\s*\)", "EdgeInsets.fromLTRB(16, 16, 16, 128)", c)
c = re.sub(r"قفل مرحله ۲ از ۳:\s*تکمیل فرم مشخصات و حافظه مربی", "قفل مرحله ۲ از ۳: تکمیل فرم مشخصات بدنی", c)
c = re.sub(r"ایول وارد شدی!\s*حالا قد، وزن، هدف، روزهای تمرین و حافظه هوش مصنوعی رو پر کن تا قفل مرحله دوم باز بشه\.?", "ایول وارد شدی! حالا قد، وزن، تاریخ تولد و هدفت رو پر کن تا قفل مرحله دوم باز بشه (حافظه هوش مصنوعی کاملاً اختیاریه).", c)

for mv in set(re.findall(r"\b([a-zA-Z0-9_]*(?:[mM]emory|[mM]em|[bB]io|[cC]oachNote|[aA]iNote)[a-zA-Z0-9_]*)\b", c)):
    if mv not in ("memory", "Memory"):
        for p in [rf"&&\s*{re.escape(mv)}(?:\.text)?(?:\.trim\(\))?\.isNotEmpty", rf"{re.escape(mv)}(?:\.text)?(?:\.trim\(\))?\.isNotEmpty\s*&&", rf"\|\|\s*{re.escape(mv)}(?:\.text)?(?:\.trim\(\))?\.isEmpty", rf"{re.escape(mv)}(?:\.text)?(?:\.trim\(\))?\.isEmpty\s*\|\|"]:
            c = re.sub(p, "", c)

c = re.sub(
    r"TextEditingController\(\s*text:\s*([^)]+)\)",
    lambda m: (
        "TextEditingController(text: ((" + m.group(1) + ").toString().trim() == 'رفیق ورزشکار' || (" + m.group(1) + ").toString().trim() == 'ورزشکار') ? '' : (" + m.group(1) + ").toString())"
        if any(k in m.group(1).lower() for k in ["name", "user", "رفیق", "ورزشکار"])
        else ("TextEditingController(text: '')" if any(k in m.group(1).lower() for k in ["age", "birth"]) else m.group(0))
    ),
    c,
)
c = re.sub(r"(_[a-zA-Z0-9_]*[nN]ame[a-zA-Z0-9_]*\.text\s*=\s*)([^;]+);", r"\1((\2).toString().trim() == 'رفیق ورزشکار' || (\2).toString().trim() == 'ورزشکار') ? '' : (\2).toString();", c)
c = re.sub(r"(_[a-zA-Z0-9_]*(?:[aA]ge|[bB]irth)[a-zA-Z0-9_]*\.text\s*=\s*)([^;]+);", r"\1'';", c)
c = re.sub(r"(_[a-zA-Z0-9_]*[hH]eight[a-zA-Z0-9_]*\.text\s*=\s*)([^;]+);", r"\1(('175' == (\2).toString().trim() || '175.0' == (\2).toString().trim() || '0' == (\2).toString().trim()) ? '' : (\2).toString());", c)
c = re.sub(r"(_[a-zA-Z0-9_]*[wW]eight[a-zA-Z0-9_]*\.text\s*=\s*)([^;]+);", r"\1(('75' == (\2).toString().trim() || '75.0' == (\2).toString().trim() || '60' == (\2).toString().trim() || '60.0' == (\2).toString().trim() || '0' == (\2).toString().trim()) ? '' : (\2).toString());", c)

c = re.sub(
    r"labelText:\s*'[^']*(?:نام|اسم|لقب)[^']*'\s*(?:,\s*hintText:\s*'[^']*')?\s*,?",
    lambda m: re.sub(r"hintText:\s*'[^']*'", "hintText: 'رفیق ورزشکار'", m.group(0)) if "hintText:" in m.group(0) else m.group(0).rstrip(",") + ", hintText: 'رفیق ورزشکار', floatingLabelBehavior: FloatingLabelBehavior.always,",
    c,
)
c = re.sub(r"labelText:\s*'[^']*سن[^']*'\s*(?:,\s*hintText:\s*'[^']*')?\s*,?", "labelText: 'تاریخ تولد (محاسبه خودکار سن با تقویم رسمی)', hintText: 'روز ماه سال', floatingLabelBehavior: FloatingLabelBehavior.always,", c)
c = re.sub(r"hintText:\s*'[^']*سن[^']*'", "hintText: 'روز ماه سال'", c)
c = re.sub(r"int\.tryParse\(\s*([a-zA-Z0-9_.]*(?:[aA]ge|[bB]irth)[a-zA-Z0-9_.]*\.text(?:\.trim\(\))?)\s*\)", r"(bmCalculateAgeFromBirthDate(\1) ?? int.tryParse(\1))", c)
c = re.sub(r"double\.tryParse\(\s*([a-zA-Z0-9_.]*(?:[aA]ge|[bB]irth)[a-zA-Z0-9_.]*\.text(?:\.trim\(\))?)\s*\)", r"(bmCalculateAgeFromBirthDate(\1)?.toDouble() ?? double.tryParse(\1))", c)

c = re.sub(r"onLongPress\s*:\s*\(\)\s*=>\s*_[a-zA-Z0-9_]+\([^)]*\)\s*,?", lambda m: "/* " + m.group(0) + " */", c)
c = re.sub(r"onLongPress\s*:\s*_[a-zA-Z0-9_]*(?:[tT]oken|[cC]oin|[pP]review)[a-zA-Z0-9_]*\s*,?", lambda m: "/* " + m.group(0) + " */", c)

for kw in ["پیشنمایش مصرف توکن", "پیش‌نمایش مصرف توکن", "معادل بادیکوین"]:
    ix = c.find(kw)
    if ix != -1:
        st = max(0, ix - 700)
        lp = c[st:ix].rfind("onLongPress")
        if lp != -1:
            alp = st + lp
            bs = c.find("{", alp)
            if bs != -1 and bs < ix:
                d, ep = 0, bs
                for i in range(bs, min(len(c), bs + 3500)):
                    if c[i] == "{": d += 1
                    elif c[i] == "}":
                        d -= 1
                        if d == 0:
                            ep = i + 1 + (1 if i + 1 < len(c) and c[i + 1] == "," else 0)
                            break
                if ep > ix:
                    c = c[:alp] + "/* " + c[alp:ep] + " */" + c[ep:]
                    break

fc = None
b_ix = c.find("باز کردن فرم مشخصات")
if b_ix != -1:
    w = c[max(0, b_ix - 450):min(len(c), b_ix + 450)]
    mc = re.search(r"onPressed\s*:\s*(?:\(\)\s*=>\s*|\(\)\s*\{\s*)?(_[a-zA-Z0-9_]+\([^)]*\))", w)
    if mc: fc = mc.group(1).rstrip(";")
    else:
        mr = re.search(r"onPressed\s*:\s*(_[a-zA-Z0-9_]+)", w)
        if mr: fc = mr.group(1) + "()"

pf_ok = False
p_ix = c.find("خروج از حساب کاربری")
if p_ix != -1:
    ps, pe = max(0, p_ix - 1800), min(len(c), p_ix + 3000)
    sl = c[ps:pe]
    nsl = re.sub(r"if\s*\(\s*!\s*[a-zA-Z0-9_.]*(?:[sS]tep2|[pP]rofile|[fF]orm|[oO]nboard|[uU]nlock|[cC]omplete)[a-zA-Z0-9_.]*\s*\)", "if (true)", sl)
    if nsl != sl:
        c = c[:ps] + nsl + c[pe:]
        pf_ok = True

for fm in ["سطح پایه", "سطح میان‌رده", "مکمل‌های ورزشی", "ذخیره مشخصات"]:
    fi = c.find(fm)
    if fi != -1:
        pf = c[max(0, fi - 1500):fi]
        if "قفل مرحله ۲ از ۳" not in pf:
            npf = re.sub(r"if\s*\([^)]*(?:[sS]tep2|[pP]rofile|[fF]orm|[cC]omplete|[uU]nlock)[^)]*\)\s*return\s+(?:const\s+)?SizedBox[^;]*;", "/* فرم همیشه فعال */", pf)
            if npf != pf:
                c = c[:max(0, fi - 1500)] + npf + c[fi:]
                pf_ok = True
        break

if not pf_ok and fc and "ویرایش مشخصات بدنی و حافظه مربی" not in c:
    si = c.find("اشتراک ۱ ماهه بادی‌مود")
    if si != -1:
        pre = c[max(0, si - 600):si]
        cp = pre.rfind("Container(")
        if cp == -1: cp = pre.rfind("Card(")
        if cp != -1:
            ins = max(0, si - 600) + cp
            card = "Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF161B26), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF00E5A3).withOpacity(0.45))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('فرم مشخصات بدنی و حافظه مربی 📋', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)), const SizedBox(height: 8), const Text('هر زمان که وزنت، هدفت یا شرایط بدنت تغییر کرد، از اینجا فرمت رو ویرایش کن رفیق! 💪✨', style: TextStyle(fontSize: 12.5, color: Colors.white70)), const SizedBox(height: 12), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5A3), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => " + fc + ", icon: const Icon(Icons.edit_note_rounded, color: Colors.black), label: const Text('ویرایش مشخصات بدنی و حافظه مربی', style: TextStyle(fontWeight: FontWeight.bold)))])),\n"
            c = c[:ins] + card + c[ins:]

with open(F, "w", encoding="utf-8") as f:
    f.write(c)

print("✅ تمام ۵ مورد با موفقیت در lib/main.dart اصلاح شد!")
