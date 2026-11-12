import 'package:flutter/material.dart';
import 'part1_core.dart';

/// تب ۱: داشبورد اصلی (آتیش قرمز/آبی، تقویم ۷ روزه، کالری‌شمار و آب‌شمار)
class DashboardTab extends StatefulWidget {
  final AppState appState;
  const DashboardTab({super.key, required this.appState});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final TextEditingController _foodNameCtrl = TextEditingController();
  final TextEditingController _foodCalCtrl = TextEditingController();

  @override
  void dispose() {
    _foodNameCtrl.dispose();
    _foodCalCtrl.dispose();
    super.dispose();
  }

  void _addFood() {
    final name = _foodNameCtrl.text.trim();
    final cal = int.tryParse(_foodCalCtrl.text.trim()) ?? 0;
    if (name.isEmpty || cal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نام خوراکی و مقدار کالری رو درست وارد کن رفیق! 🍎')),
      );
      return;
    }
    widget.appState.addFoodItem(name, cal);
    _foodNameCtrl.clear();
    _foodCalCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  List<Map<String, dynamic>> _getLast7DaysData() {
    final List<Map<String, dynamic>> list = [];
    final now = DateTime.now();
    const weekDaysFa = ['د', 'س', 'چ', 'پ', 'ج', 'ش', 'ی'];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final cal = (i == 0)
          ? widget.appState.todayTotalCalories
          : (widget.appState.weeklyCalories[key] ?? 0);
      final dayName = weekDaysFa[(d.weekday - 1) % 7];
      list.add({
        'label': i == 0 ? 'امروز' : dayName,
        'dayNum': d.day.toString(),
        'cal': cal,
        'isToday': i == 0,
      });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.appState;
    final isDark = st.isDark;
    final int eaten = st.todayTotalCalories;
    final int target = st.targetDailyCalories;
    final double progress = (eaten / (target > 0 ? target : 2000)).clamp(0.0, 1.0);
    final bool blueFire = st.isBlueFire;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // کارت خوش‌آمدگویی و آتیش استریک (قرمز / آبی نئونی)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BMColors.card(isDark),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: blueFire ? BMColors.neonBlue : BMColors.neonOrange.withOpacity(0.5),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: (blueFire ? BMColors.neonBlue : BMColors.neonOrange).withOpacity(0.15),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (blueFire ? BMColors.neonBlue : BMColors.neonOrange).withOpacity(0.15),
                ),
                child: Text(
                  blueFire ? '💙🔥' : '🔥',
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      st.nickname.isEmpty
                          ? 'سلام قهرمان بادی‌مود! 👋'
                          : 'سلام ${st.nickname} عزیز! 👋',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: BMColors.text(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      blueFire
                          ? 'آتیش آبی روشن شد! کالری و آب امروزت دقیقاً روی هدفه! ⚡'
                          : 'استریک فعلی: ${st.streakCount} روز متوالی | کالری و آب رو به هدف برسون تا آتیشت آبی بشه!',
                      style: TextStyle(
                        fontSize: 12,
                        color: blueFire ? BMColors.neonBlue : BMColors.muted(isDark),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // تقویم ۷ روزه کالری
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BMColors.card(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BMColors.border(isDark)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month, color: BMColors.neonPurple, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'عملکرد ۷ روز گذشته',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: BMColors.text(isDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _getLast7DaysData().map((d) {
                  final bool isToday = d['isToday'] as bool;
                  final int cal = d['cal'] as int;
                  final bool hitGoal =
                      cal > 0 && (cal - target).abs() <= 200;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isToday
                            ? BMColors.neonGreen.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isToday
                              ? BMColors.neonGreen
                              : (hitGoal
                                  ? BMColors.neonBlue.withOpacity(0.6)
                                  : Colors.grey.withOpacity(0.25)),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            d['label'],
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isToday ? BMColors.neonGreen : BMColors.muted(isDark),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d['dayNum'],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: BMColors.text(isDark),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cal > 0 ? '$cal' : '-',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: hitGoal ? BMColors.neonBlue : BMColors.muted(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // حلقه و نوار کالری‌شمار امروز
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: BMColors.card(isDark),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BMColors.border(isDark)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🎯 کالری هدف روزانه: $target kcal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: BMColors.muted(isDark),
                    ),
                  ),
                  Text(
                    'مصرف‌شده: $eaten kcal',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: BMColors.neonGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 14,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    eaten > target + 150 ? BMColors.neonRed : BMColors.neonGreen,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                eaten <= target
                    ? 'می‌تونی تا ${target - eaten} کالری دیگه امروز مصرف کنی 💪'
                    : '⚠️ ${eaten - target} کالری بیشتر از هدف روزانه مصرف کردی!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: eaten <= target ? BMColors.text(isDark) : BMColors.neonRed,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // آب‌شمار هوشمند
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BMColors.card(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BMColors.neonBlue.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Text('💧', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'آب‌شمار روزانه (${st.todayWaterGlasses} از ۸ لیوان)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: BMColors.text(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'حداقل ۶ لیوان آب برای روشن شدن آتیش آبی لازمه!',
                      style: TextStyle(fontSize: 11.5, color: BMColors.muted(isDark)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => st.addWaterGlass(-1),
                icon: const Icon(Icons.remove_circle_outline, color: BMColors.neonRed),
              ),
              IconButton(
                onPressed: () => st.addWaterGlass(1),
                icon: const Icon(Icons.add_circle, color: BMColors.neonBlue, size: 30),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ثبت خوراکی جدید
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BMColors.card(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BMColors.border(isDark)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🍽️ ثبت وعده و خوراکی امروز',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: BMColors.text(isDark),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _foodNameCtrl,
                      style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'مثلاً: ۲ کفگیر برنج و مرغ',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _foodCalCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'کالری',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BMColors.neonGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    ),
                    onPressed: _addFood,
                    child: const Text('ثبت +', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (st.todayFoods.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'هنوز خوراکی‌ای برای امروز ثبت نکردی رفیق!',
                    style: TextStyle(fontSize: 12, color: BMColors.muted(isDark)),
                  ),
                )
              else
                ...List.generate(st.todayFoods.length, (idx) {
                  final item = st.todayFoods[idx];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.fastfood, color: BMColors.neonOrange, size: 20),
                    title: Text(
                      item['title'].toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: BMColors.text(isDark),
                      ),
                    ),
                    subtitle: Text(
                      'ساعت ${item['time']} • ${item['cal']} کیلوکالری',
                      style: TextStyle(fontSize: 11.5, color: BMColors.muted(isDark)),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: BMColors.neonRed, size: 20),
                      onPressed: () => st.removeFoodItem(idx),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

/// تب ۲: برنامه غذایی هفتگی هوش مصنوعی + اسکنر هوشمند خوراکی‌ها
class MealPlanAndScannerTab extends StatefulWidget {
  final AppState appState;
  const MealPlanAndScannerTab({super.key, required this.appState});

  @override
  State<MealPlanAndScannerTab> createState() => _MealPlanAndScannerTabState();
}

class _MealPlanAndScannerTabState extends State<MealPlanAndScannerTab> {
  bool _loadingMeal = false;
  bool _loadingScan = false;
  final TextEditingController _mealPrefCtrl = TextEditingController();
  final TextEditingController _scanInputCtrl = TextEditingController();
  String _scanResult = '';

  @override
  void dispose() {
    _mealPrefCtrl.dispose();
    _scanInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateWeeklyMealPlan() async {
    final st = widget.appState;
    setState(() => _loadingMeal = true);
    try {
      final extraPref = _mealPrefCtrl.text.trim();
      final prompt = '''
یک برنامه غذایی دقیق ۷ روزه (شنبه تا جمعه) شامل صبحانه، میان‌وعده، ناهار و شام متناسب با وضعیت اقتصادی کاربر (${st.economicStatus})، شهر محل سکونت (${st.city})، هدف (${st.fitnessGoal}) و کالری هدف روزانه (${st.targetDailyCalories} کیلوکالری) طراحی کن.
برای هر وعده مقدار دقیق به گرم یا قاشق/کفگیر و کالری حدودی آن را بنویس.
${extraPref.isNotEmpty ? 'ترجیحات غذایی اضافه کاربر: $extraPref' : ''}
''';
      final reply = await st.callBodyModAI(
        featureKey: 'meal',
        modelId: st.mealModel,
        userPrompt: prompt,
      );
      st.savedMealPlan = reply;
      await st.prefs?.setString('bm_meal_plan', reply);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loadingMeal = false);
    }
  }

  Future<void> _scanFoodNutrition() async {
    final st = widget.appState;
    final query = _scanInputCtrl.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نام غذا یا ترکیباتش رو بنویس تا اسکن کنم! 🔍')),
      );
      return;
    }
    setState(() => _loadingScan = true);
    try {
      final prompt = '''
خوراکی یا وعده زیر را به صورت دقیق اسکن و کالری‌شماری کن:
"$query"
لطفاً موارد زیر را به زبان فارسی صمیمی و دقیق بنویس:
1) مجموع کالری تقریبی
2) مقدار پروتئین، کربوهیدرات و چربی (به گرم)
3) آیا این وعده برای هدف فعلی من (${st.fitnessGoal}) و وضعیت بدنی من مناسب است یا نه؟
''';
      final reply = await st.callBodyModAI(
        featureKey: 'scanner',
        modelId: st.scannerModel,
        userPrompt: prompt,
      );
      if (mounted) setState(() => _scanResult = reply);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loadingScan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.appState;
    final isDark = st.isDark;
    final int mealQuota = st.getRemainingQuotaToday('meal', st.mealModel);
    final int scanQuota = st.getRemainingQuotaToday('scanner', st.scannerModel);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // بخش ۱: برنامه غذایی هفتگی هوش مصنوعی
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🥗 برنامه غذایی هفتگی هوشمند',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: BMColors.text(isDark),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: BMColors.neonGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'سهمیه امروز: $mealQuota بار',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: BMColors.neonGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // انتخابگر مدل هوش مصنوعی بالای دریافت برنامه غذایی
              AIModelSelectorBar(
                featureKey: 'meal',
                selectedModel: st.mealModel,
                isDark: isDark,
                onChanged: (val) => setState(() => st.mealModel = val),
              ),

              TextField(
                controller: _mealPrefCtrl,
                style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'غذاهای مورد علاقه یا در دسترس خونه (اختیاری)...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BMColors.neonGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _loadingMeal ? null : _generateWeeklyMealPlan,
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text(
                    'دریافت برنامه غذایی ۷ روزه اختصاصی 🚀',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),

              if (_loadingMeal) ...[
                const SizedBox(height: 16),
                const BodyModBLoader(label: 'در حال چیدن سفره ۷ روزه متناسب با بودجه و هدفت...'),
              ] else if (st.savedMealPlan.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BMColors.bg(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BMColors.neonGreen.withOpacity(0.3)),
                  ),
                  child: SelectableText(
                    st.savedMealPlan,
                    style: TextStyle(
                      fontSize: 13.2,
                      height: 1.75,
                      color: BMColors.text(isDark),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),

        // بخش ۲: اسکنر هوشمند خوراکی و کالری‌شمار آنی
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BMColors.card(isDark),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BMColors.neonPurple.withOpacity(0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🔍 اسکنر و تحلیلگر خوراکی AI',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: BMColors.text(isDark),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: BMColors.neonPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'سهمیه امروز: $scanQuota بار',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: BMColors.neonPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // انتخابگر مدل هوش مصنوعی بالای اسکنر خوراکی
              AIModelSelectorBar(
                featureKey: 'scanner',
                selectedModel: st.scannerModel,
                isDark: isDark,
                onChanged: (val) => setState(() => st.scannerModel = val),
              ),

              TextField(
                controller: _scanInputCtrl,
                style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'مثلاً: یک بشقاب قرمه‌سبزی با ۲ کفگیر برنج و دوغ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BMColors.neonPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _loadingScan ? null : _scanFoodNutrition,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text(
                    'اسکن کالری و ارزش غذایی با هوش مصنوعی ⚡',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),

              if (_loadingScan) ...[
                const SizedBox(height: 16),
                const BodyModBLoader(label: 'در حال آنالیز دقیق کالری و ماکروها...'),
              ] else if (_scanResult.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BMColors.bg(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BMColors.neonPurple.withOpacity(0.4)),
                  ),
                  child: SelectableText(
                    _scanResult,
                    style: TextStyle(
                      fontSize: 13.2,
                      height: 1.75,
                      color: BMColors.text(isDark),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
