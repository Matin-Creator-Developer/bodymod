# -*- coding: utf-8 -*-
import os, re, shutil, sys

F = "lib/main.dart"
BAK2 = "lib/main.dart.bak2"

if not os.path.exists(F):
    sys.exit("❌ فایل lib/main.dart پیدا نشد!")

if os.path.exists(BAK2):
    shutil.copyfile(BAK2, F)
    print("✅ نسخه پایه از lib/main.dart.bak2 بازیابی شد تا تکراری‌ها کامل پاک شوند.")
else:
    shutil.copyfile(F, BAK2)

with open(F, "r", encoding="utf-8") as f:
    c = f.read()

c = c.replace("TextEditingController(text: ''));", "TextEditingController(text: '');")
orig_parens = c.count("(") - c.count(")")
orig_braces = c.count("{") - c.count("}")

BIRTH_WIDGET = "\n".join([
    "String _bmSavedBirthStr = '';",
    "class BmBirthDateThreeBoxes extends StatefulWidget {",
    "  final TextEditingController controller;",
    "  const BmBirthDateThreeBoxes({super.key, required this.controller});",
    "  @override",
    "  State<BmBirthDateThreeBoxes> createState() => _BmBirthDateThreeBoxesState();",
    "}",
    "class _BmBirthDateThreeBoxesState extends State<BmBirthDateThreeBoxes> {",
    "  int? _day, _month, _year;",
    "  static const List<String> _mNames = ['فروردین','اردیبهشت','خرداد','تیر','مرداد','شهریور','مهر','آبان','آذر','دی','بهمن','اسفند'];",
    "  @override",
    "  void initState() { super.initState(); _parseInitial(); }",
    "  void _parseInitial() {",
    "    String raw = widget.controller.text.trim();",
    "    if (raw.isEmpty || !raw.contains('/')) raw = _bmSavedBirthStr;",
    "    if (raw.contains('/')) {",
    "      final p = raw.split('/').map((e) => int.tryParse(e.trim()) ?? 0).toList();",
    "      if (p.length >= 3) {",
    "        if (p[2] >= 1300) { _day = p[0]; _month = p[1]; _year = p[2]; }",
    "        else if (p[0] >= 1300) { _year = p[0]; _month = p[1]; _day = p[2]; }",
    "      }",
    "    }",
    "  }",
    "  void _updateCtrl() {",
    "    if (_day != null && _month != null && _year != null) {",
    "      _bmSavedBirthStr = '$_day/$_month/$_year';",
    "      widget.controller.text = _bmSavedBirthStr;",
    "    }",
    "    setState(() {});",
    "  }",
    "  Future<void> _pickNum(String title, int minV, int maxV, int? cur, ValueChanged<int> onPick, {bool isM = false, bool rev = false}) async {",
    "    final items = <int>[];",
    "    if (rev) { for (int i = maxV; i >= minV; i--) items.add(i); } else { for (int i = minV; i <= maxV; i++) items.add(i); }",
    "    await bmShowResponsiveSheet(",
    "      context: context,",
    "      builder: (ctx) => Padding(",
    "        padding: const EdgeInsets.all(16),",
    "        child: Column(mainAxisSize: MainAxisSize.min, children: [",
    "          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),",
    "          const SizedBox(height: 12),",
    "          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: items.map((val) {",
    "            final sel = val == cur;",
    "            final lbl = isM ? '$val (${_mNames[val - 1]})' : '$val';",
    "            return InkWell(",
    "              onTap: () { onPick(val); Navigator.pop(ctx); },",
    "              borderRadius: BorderRadius.circular(10),",
    "              child: Container(",
    "                padding: EdgeInsets.symmetric(horizontal: isM ? 12 : 14, vertical: 9),",
    "                decoration: BoxDecoration(color: sel ? const Color(0xFF00E5A3) : const Color(0xFF1E2638), borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? const Color(0xFF00E5A3) : Colors.white24)),",
    "                child: Text(lbl, style: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),",
    "              ),",
    "            );",
    "          }).toList()),",
    "        ]),",
    "      ),",
    "    );",
    "  }",
    "  Widget _box(String lbl, String? val, VoidCallback onTap) {",
    "    final ok = val != null && val.isNotEmpty;",
    "    return Expanded(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(",
    "      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),",
    "      decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(12), border: Border.all(color: ok ? const Color(0xFF00E5A3).withOpacity(0.75) : Colors.white24)),",
    "      child: Column(mainAxisSize: MainAxisSize.min, children: [",
    "        Text(lbl, style: const TextStyle(fontSize: 10, color: Colors.white54)),",
    "        const SizedBox(height: 2),",
    "        Text(ok ? val : 'انتخاب', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: ok ? Colors.white : Colors.white38)),",
    "      ]),",
    "    )));",
    "  }",
    "  @override",
    "  Widget build(BuildContext context) {",
    "    final age = (_day != null && _month != null && _year != null) ? bmCalculateAgeFromBirthDate('$_day/$_month/$_year') : null;",
    "    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [",
    "      Padding(padding: const EdgeInsets.only(bottom: 5, right: 2), child: Text(age != null ? 'تاریخ تولد (سن: $age سال 🎂)' : 'تاریخ تولد (کادر روز / ماه / سال)', style: const TextStyle(fontSize: 11, color: Colors.white70))),",
    "      Row(children: [",
    "        _box('روز', _day?.toString(), () => _pickNum('انتخاب روز تولد', 1, 31, _day, (v) { _day = v; _updateCtrl(); })),",
    "        const SizedBox(width: 5),",
    "        _box('ماه', _month?.toString(), () => _pickNum('انتخاب ماه تولد', 1, 12, _month, (v) { _month = v; _updateCtrl(); }, isM: true)),",
    "        const SizedBox(width: 5),",
    "        _box('سال', _year?.toString(), () => _pickNum('انتخاب سال تولد (شمسی)', 1325, 1396, _year, (v) { _year = v; _updateCtrl(); }, rev: true)),",
    "      ]),",
    "    ]);",
    "  }",
    "}",
])

if "BmBirthDateThreeBoxes" not in c:
    c = c.replace("void main(", BIRTH_WIDGET + "\nvoid main(", 1)

for marker in ["تاریخ تولد (محاسبه خودکار سن", "hintText: 'روز ماه سال'", "labelText: 'سن"]:
    m_pos = c.find(marker)
    if m_pos != -1:
        pre = c[max(0, m_pos - 350):m_pos]
        tf_idx = pre.rfind("TextField(")
        if tf_idx == -1: tf_idx = pre.rfind("TextFormField(")
        if tf_idx != -1:
            abs_s = max(0, m_pos - 350) + tf_idx
            p_open = c.find("(", abs_s)
            d, abs_e = 0, -1
            for i in range(p_open, min(len(c), p_open + 1200)):
                if c[i] == "(": d += 1
                elif c[i] == ")":
                    d -= 1
                    if d == 0: abs_e = i + 1; break
            if abs_e != -1:
                cm = re.search(r"controller\s*:\s*([a-zA-Z0-9_.]+)", c[abs_s:abs_e])
                if cm:
                    c = c[:abs_s] + f"BmBirthDateThreeBoxes(controller: {cm.group(1)})" + c[abs_e:]
                    es = max(0, abs_s - 80)
                    esub = c[es:abs_s]
                    if "Expanded(" in esub and "flex:" not in esub:
                        c = c[:es] + esub.replace("Expanded(", "Expanded(flex: 2, ", 1) + c[abs_s:]
                    break

c = re.sub(r"\s*\(\s*دوشاب\s*\)", "", c)
c = re.sub(r"دوشاب\s*\(\s*شیره انگور و خرما\s*\)", "شیره انگور و شیره خرما", c)
c = re.sub(r"شیره انگور\s*(?:و|یا|/)\s*خرما\s*(?:\(\s*دوشاب\s*\))?", "شیره انگور و شیره خرما", c)
c = c.replace("دوشاب", "شیره انگور و شیره خرما")

def extract_item(text, pos):
    pre = text[max(0, pos - 280):pos]
    bi, pi = pre.rfind("{"), pre.rfind("(")
    if bi != -1 and bi > pi:
        st = max(0, pos - 280) + bi
        d = 0
        for i in range(st, min(len(text), st + 1600)):
            if text[i] == "{": d += 1
            elif text[i] == "}":
                d -= 1
                if d == 0: return st, i + 1, text[st:i + 1]
    elif pi != -1:
        ap = max(0, pos - 280) + pi
        ks = ap
        while ks > 0 and (text[ks - 1].isalnum() or text[ks - 1] in "_."): ks -= 1
        d = 0
        for i in range(ap, min(len(text), ap + 1600)):
            if text[i] == "(": d += 1
            elif text[i] == ")":
                d -= 1
                if d == 0: return ks, i + 1, text[ks:i + 1]
    return -1, -1, None

apos = c.find("بادام درختی")
if apos != -1:
    si, ei, tpl = extract_item(c, apos)
    if tpl:
        tm = re.search(r"(['\"][^'\"]*بادام درختی[^'\"]*['\"])", tpl)
        if tm:
            ot = tm.group(1)
            q = ot[0]
            base_almond = tpl.replace(ot, f"{q}بادام درختی (خام یا بوداده){q}", 1).replace("'🥜'", "'🌰'").replace('"🥜"', '"🌰"')

            def build_cloned_item(new_title, big_emoji, cat_override=None):
                item = tpl.replace(ot, f"{q}{new_title}{q}", 1)
                item = item.replace("'🥜'", f"'{big_emoji}'").replace('"🥜"', f'"{big_emoji}"')
                if cat_override:
                    item = re.sub(r"(['\"])[^'\"]*آجیل[^'\"]*(['\"])", rf"\1{cat_override}\2", item, count=1)
                    item = item.replace("۱ عدد (۱ دانه)", "۱ برش (متوسط)")
                return item

            nut_defs = [
                ("بادام زمینی (خام یا بوداده)", "🥜"),
                ("پسته (خام یا شور)", "🌰"),
                ("فندق (خام یا بوداده)", "🌰"),
                ("بادام هندی (کاجو)", "🥜"),
                ("تخمه آفتابگردان یا کدو", "🌻"),
                ("آجیل چهارمغز مخلوط", "🥣"),
            ]
            all_items = [base_almond]
            for n_title, n_icon in nut_defs:
                all_items.append(build_cloned_item(n_title, n_icon))

            scm = re.search(r"['\"]([^'\"]*تنقلات[^'\"]*)['\"]", c)
            sc_name = scm.group(1) if scm else "تنقلات و دسر"

            snack_defs = [
                ("کیک خانگی یا اسفنجی ساده", "🍰"),
                ("کیک شکلاتی یا خامه‌ای", "🎂"),
                ("شیرینی خشک یا دانمارکی", "🥐"),
                ("شیرینی تر خامه‌ای", "🧁"),
                ("کلوچه یا کاپ‌کیک", "🍪"),
            ]
            for s_title, s_icon in snack_defs:
                all_items.append(build_cloned_item(s_title, s_icon, cat_override=sc_name))

            c = c[:si] + ",\n      ".join(all_items) + c[ei:]
            print("✅ گردوی تکراری حذف شد و ایموجی بزرگ سمت راست برای هر آیتم جایگزین بادام‌زمینی شد!")

if (c.count("(") - c.count(")")) != orig_parens or (c.count("{") - c.count("}")) != orig_braces:
    sys.exit("❌ خطا در توازن پرانتز/آکولاد! فایل تغییر نکرد.")

with open(F, "w", encoding="utf-8") as f:
    f.write(c)

print("🎉 تمام اصلاحات با موفقیت در lib/main.dart ذخیره شد!")
