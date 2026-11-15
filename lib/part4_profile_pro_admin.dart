import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'part1_core.dart';

/// تب ۶: پرونده کامل بدنی + حافظه مربی (بدون بحث اقتصاد در حافظه)
class ProfileTab extends StatefulWidget {
  final AppState appState;
  const ProfileTab({super.key, required this.appState});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late TextEditingController _nickCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _memoryCtrl;

  late String _bDay;
  late String _bMonth;
  late String _bYear;
  late String _gender;
  late String _econ;
  late String _goal;
  late String _timeline;
  late String _workoutDays;
  bool _saving = false;

  final List<String> _daysList =
      List.generate(31, (i) => (i + 1).toString().padLeft(2, '0'));
  final List<String> _monthsList =
      List.generate(12, (i) => (i + 1).toString().padLeft(2, '0'));
  final List<String> _yearsList =
      List.generate(75, (i) => (1395 - i).toString());

  static const List<String> _econOptions = ['ضعیف', 'متوسط', 'عالی'];
  static const List<String> _goalOptions = [
    'کاهش وزن و چربی‌سوزی',
    'افزایش وزن و حجم',
    'عضله‌سازی خشک و فیتنس',
    'تناسب اندام و سلامتی',
  ];
  static const List<String> _timelineOptions = [
    '۱ ماهه (فشرده)',
    '۳ ماهه',
    '۶ ماهه',
    '۱ ساله (اصولی و ماندگار)',
  ];
  static const List<String> _workoutDaysOptions = [
    '۱ روز در هفته',
    '۲ روز در هفته',
    '۳ روز در هفته',
    'هر روز',
  ];

  @override
  void initState() {
    super.initState();
    final st = widget.appState;
    _nickCtrl = TextEditingController(text: st.nickname);
    _cityCtrl = TextEditingController(text: st.city);
    _heightCtrl = TextEditingController(text: st.heightCm.toStringAsFixed(0));
    _weightCtrl = TextEditingController(text: st.weightKg.toStringAsFixed(1));
    _memoryCtrl = TextEditingController(text: st.aiMemoryNotes);

    _bDay = _daysList.contains(st.birthDay) ? st.birthDay : '14';
    _bMonth = _monthsList.contains(st.birthMonth) ? st.birthMonth : '10';
    _bYear = _yearsList.contains(st.birthYear) ? st.birthYear : '1383';
    _gender = (st.gender == 'زن') ? 'زن' : 'مرد';
    _econ = _econOptions.contains(st.economicStatus) ? st.economicStatus : 'متوسط';
    _goal = _goalOptions.contains(st.fitnessGoal)
        ? st.fitnessGoal
        : 'تناسب اندام و سلامتی';
    _timeline = _timelineOptions.contains(st.targetTimeline)
        ? st.targetTimeline
        : '۳ ماهه';
    _workoutDays = _workoutDaysOptions.contains(st.workoutDaysPerWeek)
        ? st.workoutDaysPerWeek
        : '۳ روز در هفته';
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    _cityCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _memoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    final h = double.tryParse(_heightCtrl.text.trim()) ?? 175;
    final w = double.tryParse(_weightCtrl.text.trim()) ?? 70;
    if (h < 100 || h > 240 || w < 25 || w > 250) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قد و وزن رو در محدوده معتبر وارد کن رفیق! 📏')),
      );
      return;
    }

    setState(() => _saving = true);
    await widget.appState.saveProfile(
      newNickname: _nickCtrl.text.trim(),
      newBDay: _bDay,
      newBMonth: _bMonth,
      newBYear: _bYear,
      newGender: _gender,
      newCity: _cityCtrl.text.trim(),
      newEconomicStatus: _econ,
      newHeight: h,
      newWeight: w,
      newGoal: _goal,
      newTimeline: _timeline,
      newWorkoutDays: _workoutDays,
      newAiMemory: _memoryCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ پرونده بدنی ذخیره شد! از این لحظه در تمام پاسخ‌های AI اعمال می‌شه 🚀'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.appState;
    final isDark = st.isDark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BMColors.card(isDark),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BMColors.border(isDark)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.badge_outlined, color: BMColors.neonGreen),
                  const SizedBox(width: 8),
                  Text(
                    'پرونده کامل بدنی و شخصی‌سازی AI',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: BMColors.text(isDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'تمامی اطلاعات این فرم در هر سوال چت و هر برنامه غذایی/تمرینی به هوش مصنوعی ارسال می‌شه.',
                style: TextStyle(fontSize: 11.5, color: BMColors.muted(isDark)),
              ),
              const SizedBox(height: 14),

              // نام و شهر
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nickCtrl,
                      style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'نام یا لقب ورزشکار',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _cityCtrl,
                      style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'شهر محل سکونت',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // تاریخ تولد شمسی (روز / ماه / سال)
              Text(
                '🎂 تاریخ تولد شمسی:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: BMColors.text(isDark),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _bDay,
                      dropdownColor: BMColors.card(isDark),
                      style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'روز',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _daysList
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) => setState(() => _bDay = v ?? '14'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _bMonth,
                      dropdownColor: BMColors.card(isDark),
                      style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'ماه',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _monthsList
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setState(() => _bMonth = v ?? '10'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _bYear,
                      dropdownColor: BMColors.card(isDark),
                      style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'سال',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _yearsList
                          .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                          .toList(),
                      onChanged: (v) => setState(() => _bYear = v ?? '1383'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // جنسیت و وضعیت اقتصادی (اجباری)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      dropdownColor: BMColors.card(isDark),
                      style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'جنسیت',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'مرد', child: Text('👨 مرد')),
                        DropdownMenuItem(value: 'زن', child: Text('👩 زن')),
                      ],
                      onChanged: (v) => setState(() => _gender = v ?? 'مرد'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _econ,
                      dropdownColor: BMColors.card(isDark),
                      style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'وضعیت اقتصادی *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _econOptions
                          .map((e) => DropdownMenuItem(value: e, child: Text('💳 $e')))
                          .toList(),
                      onChanged: (v) => setState(() => _econ = v ?? 'متوسط'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // قد و وزن
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _heightCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'قد (سانتی‌متر)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'وزن فعلی (کیلوگرم)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // هدف تناسب اندام
              DropdownButtonFormField<String>(
                value: _goal,
                dropdownColor: BMColors.card(isDark),
                style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                decoration: InputDecoration(
                  labelText: '🎯 هدف اصلی تو',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _goalOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _goal = v ?? _goalOptions.last),
              ),
              if (st.isUnderweight)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '💡 چون BMI شما کمتر از ۱۸.۵ است، هوش مصنوعی به صورت هوشمند اولویت اول را روی افزایش وزن اصولی و رسیدن به وزن سالم قرار می‌دهد.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: BMColors.neonOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // دوره زمانی رسیدن به هدف (با ایموجی موشک 🚀)
              DropdownButtonFormField<String>(
                value: _timeline,
                dropdownColor: BMColors.card(isDark),
                style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                decoration: InputDecoration(
                  labelText: '🚀 دوره زمانی رسیدن به هدف',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _timelineOptions
                    .map((t) => DropdownMenuItem(value: t, child: Text('🚀 $t')))
                    .toList(),
                onChanged: (v) => setState(() => _timeline = v ?? '۳ ماهه'),
              ),
              const SizedBox(height: 12),

              // چند روز در هفته می‌خوای تمرین کنی؟
              DropdownButtonFormField<String>(
                value: _workoutDays,
                dropdownColor: BMColors.card(isDark),
                style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                decoration: InputDecoration(
                  labelText: '🏋️ چند روز در هفته می‌خوای تمرین کنی؟',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _workoutDaysOptions
                    .map((w) => DropdownMenuItem(value: w, child: Text('📅 $w')))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _workoutDays = v ?? '۳ روز در هفته'),
              ),
              const SizedBox(height: 16),

              // حافظه اختصاصی مربی هوشمند (بدون هیچ اشاره‌ای به اقتصاد!)
              Text(
                '🧠 حافظه اختصاصی مربی هوشمند (نکات مهم بدنی و تغذیه‌ای):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: BMColors.neonGreen,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: BMColors.neonPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BMColors.neonPurple.withOpacity(0.35)),
                ),
                child: Text(
                  '💡 راهنمای تکمیل حافظه مربی:\n'
                  '۱) اگه بیماری زمینه‌ای، دیسک کمر یا آسیب‌دیدگی مفصلی داری بنویس.\n'
                  '۲) اگه دارو یا مکمل خاصی مصرف می‌کنی اشاره کن.\n'
                  '۳) اگه به ماده غذایی خاصی حساسیت داری یا دوست نداری (مثلاً لاکتوز، تخم‌مرغ، ماهی) بنویس.\n'
                  '۴) ساعت خواب، شیفت کاری یا هر نکته‌ای که مربی باید همیشه یادش بمونه رو وارد کن.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.65,
                    color: BMColors.text(isDark),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _memoryCtrl,
                maxLines: 4,
                style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'مثلاً: زانوی راستم کمی درد می‌کنه، به شیر حساسیت دارم و شب‌کار هستم...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BMColors.neonGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _saving ? null : _saveForm,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    _saving ? 'در حال ذخیره...' : 'ذخیره پرونده و بروزرسانی حافظه AI 🚀',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // خروج از حساب
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: BMColors.neonRed),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => st.logout(),
          icon: const Icon(Icons.logout, color: BMColors.neonRed),
          label: const Text(
            'خروج از حساب کاربری',
            style: TextStyle(color: BMColors.neonRed, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

/// تب ۷: اشتراک ویژه بازار و مایکت + پاپ‌آپ سایر برنامه‌ها
class SubscriptionAndAppsTab extends StatelessWidget {
  final AppState appState;
  const SubscriptionAndAppsTab({super.key, required this.appState});

  void _showOtherAppsModal(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: BMColors.card(isDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: BMColors.neonPurple, width: 1.8),
            ),
            title: const Row(
              children: [
                Text('🚀 '),
                Expanded(
                  child: Text(
                    'سایر برنامه‌های کاربردی ما',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: BMColors.neonGreen,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'سایر برنامه‌های ما (مثل ماشین‌حساب نجومی و بی‌نهایت MegaCalc) رو می‌خوای چطوری و از کدوم مارکت نصب کنی رفیق؟',
              style: TextStyle(
                fontSize: 13,
                height: 1.65,
                color: BMColors.text(isDark),
              ),
            ),
            actions: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      launchUrl(
                        Uri.parse('https://cafebazaar.ir/app/ir.matinmohammadi.megacalc'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text(
                      'مشاهده و نصب از کافه‌بازار',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      launchUrl(
                        Uri.parse('https://myket.ir/app/ir.matinmohammadi.megacalc'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    icon: const Icon(Icons.apps),
                    label: const Text(
                      'مشاهده و نصب از مایکت',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('بستن پنجره ✕'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appState.isDark;
    final market = appState.selectedMarket;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: BMColors.card(isDark),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BMColors.neonGold.withOpacity(0.55), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('👑', style: TextStyle(fontSize: 26)),
                  SizedBox(width: 8),
                  Text(
                    'اشتراک ویژه BodyMod Pro',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: BMColors.neonGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '• دسترسی کامل به مدل فوق‌پیشرفته Gemini 3.8 Flash\n'
                '• دریافت برنامه غذایی و برنامه تمرینی اختصاصی\n'
                '• اسکنر هوشمند کالری و تحلیل ۷ روزه لاگ بدن\n'
                '• پشتیبانی مستقیم درون‌برنامه‌ای از طریق کافه‌بازار و مایکت',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.8,
                  color: BMColors.text(isDark),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('🛒 نسخه کافه‌بازار'),
                      selected: market == 'bazaar',
                      onSelected: (_) => appState.setMarket('bazaar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('🟦 نسخه مایکت'),
                      selected: market == 'myket',
                      onSelected: (_) => appState.setMarket('myket'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BMColors.neonGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    final url = market == 'bazaar'
                        ? 'https://cafebazaar.ir/app/ir.matinmohammadi.bodymod'
                        : 'https://myket.ir/app/ir.matinmohammadi.bodymod';
                    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.workspace_premium),
                  label: Text(
                    market == 'bazaar'
                        ? 'فعال‌سازی اشتراک از طریق کافه‌بازار'
                        : 'فعال‌سازی اشتراک از طریق مایکت',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // دکمه سایر برنامه‌ها
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BMColors.card(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BMColors.neonPurple.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Text(
                '📱 سایر برنامه‌های کاربردی تیم ما',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: BMColors.text(isDark),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ماشین‌حساب نجومی و بی‌نهایت MegaCalc و ابزارهای بعدی رو از اینجا ببین!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: BMColors.muted(isDark)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: BMColors.neonPurple, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _showOtherAppsModal(context, isDark),
                  icon: const Icon(Icons.grid_view_rounded, color: BMColors.neonPurple),
                  label: const Text(
                    'مشاهده سایر برنامه‌ها (بازار / مایکت)',
                    style: TextStyle(
                      color: BMColors.neonPurple,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// تب ۸: پنل مدیرعامل (مخصوص متین - همراه با آمار وضعیت اقتصادی کاربران)
class CEOAdminTab extends StatefulWidget {
  final AppState appState;
  const CEOAdminTab({super.key, required this.appState});

  @override
  State<CEOAdminTab> createState() => _CEOAdminTabState();
}

class _CEOAdminTabState extends State<CEOAdminTab> {
  bool _loading = false;
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'proUsers': 0,
    'todayAiRequests': 0,
    'econWeak': 0,
    'econMedium': 0,
    'econHigh': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchAdminStats();
  }

  Future<void> _fetchAdminStats() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('$kServerUrl/api/admin/stats'),
        headers: {
          if (widget.appState.token.isNotEmpty)
            'Authorization': 'Bearer ${widget.appState.token}',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (mounted) {
          setState(() {
            _stats = {
              'totalUsers': data['totalUsers'] ?? 1,
              'proUsers': data['proUsers'] ?? 0,
              'todayAiRequests': data['todayAiRequests'] ?? 0,
              'econWeak': data['econWeak'] ?? 0,
              'econMedium': data['econMedium'] ?? 1,
              'econHigh': data['econHigh'] ?? 0,
            };
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDark;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BMColors.card(isDark),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BMColors.neonGreen),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '👑 پنل فرماندهی مدیرعامل (متین)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: BMColors.text(isDark),
                    ),
                  ),
                  IconButton(
                    onPressed: _fetchAdminStats,
                    icon: const Icon(Icons.refresh, color: BMColors.neonGreen),
                  ),
                ],
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: BodyModBLoader(label: 'در حال دریافت آمار زنده از کلودفلر...'),
                )
              else ...[
                const SizedBox(height: 10),
                _statRow('👥 کل کاربران ثبت‌نامی:', '${_stats['totalUsers']} نفر', isDark),
                _statRow('💎 کاربران دارای اشتراک Pro:', '${_stats['proUsers']} نفر', isDark),
                _statRow('⚡ درخواست‌های AI امروز:', '${_stats['todayAiRequests']} درخواست', isDark),
                const Divider(height: 24),
                Text(
                  '📊 تفکیک وضعیت اقتصادی کاربران (از فرم پروفایل):',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: BMColors.neonBlue,
                  ),
                ),
                const SizedBox(height: 8),
                _statRow('🔸 وضعیت اقتصادی ضعیف:', '${_stats['econWeak']} نفر', isDark),
                _statRow('🔹 وضعیت اقتصادی متوسط:', '${_stats['econMedium']} نفر', isDark),
                _statRow('🌟 وضعیت اقتصادی عالی:', '${_stats['econHigh']} نفر', isDark),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _statRow(String title, String val, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: BMColors.muted(isDark))),
          Text(
            val,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: BMColors.text(isDark),
            ),
          ),
        ],
      ),
    );
  }
}
