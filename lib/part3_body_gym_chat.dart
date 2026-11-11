import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'part1_core.dart';

/// تب ۳: لاگ هفتگی بدن و تحلیل هوشمند تغییرات سایز و وزن
class BodyLogTab extends StatefulWidget {
  final AppState appState;
  const BodyLogTab({super.key, required this.appState});

  @override
  State<BodyLogTab> createState() => _BodyLogTabState();
}

class _BodyLogTabState extends State<BodyLogTab> {
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _waistCtrl = TextEditingController();
  final TextEditingController _fatCtrl = TextEditingController();
  bool _loadingAnalysis = false;

  @override
  void initState() {
    super.initState();
    _weightCtrl.text = widget.appState.weightKg.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _waistCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveBodyLog() async {
    final st = widget.appState;
    final double? w = double.tryParse(_weightCtrl.text.trim());
    final double? waist = double.tryParse(_waistCtrl.text.trim());
    final double? fat = double.tryParse(_fatCtrl.text.trim());

    if (w == null || w < 25 || w > 250) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('وزن رو به درستی وارد کن رفیق! ⚖️')),
      );
      return;
    }

    st.weightKg = w;
    await st.prefs?.setDouble('bm_weight', w);

    final entry = {
      'date': st.todayKey(),
      'weight': w,
      'waist': waist ?? 0.0,
      'fat': fat ?? 0.0,
    };

    st.bodyLogs.insert(0, entry);
    if (st.bodyLogs.length > 20) {
      st.bodyLogs = st.bodyLogs.sublist(0, 20);
    }
    await st.prefs?.setString('bm_body_logs', jsonEncode(st.bodyLogs));
    st.refreshUI();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ لاگ جدید بدنت ثبت شد قهرمان!')),
      );
      setState(() {});
    }
  }

  Future<void> _analyzeBodyProgress() async {
    final st = widget.appState;
    setState(() => _loadingAnalysis = true);
    try {
      final logsSummary = st.bodyLogs.isEmpty
          ? 'هنوز سابقه قبلی ثبت نشده، بر اساس وزن و قد فعلی تحلیل کن.'
          : st.bodyLogs
              .take(6)
              .map((e) =>
                  'تاریخ ${e['date']}: وزن ${e['weight']}kg | دور کمر: ${e['waist']}cm | چربی: ${e['fat']}%')
              .join('\n');

      final prompt = '''
سوابق ثبت‌شده تغییرات بدنی کاربر:
$logsSummary

لطفاً به عنوان مربی اختصاصی بادی‌مود، روند تغییرات وزن، BMI (${st.bmi.toStringAsFixed(1)}) و تناسب آن با هدف (${st.fitnessGoal}) و دوره زمانی (${st.targetTimeline}) را تحلیل کن و ۳ نکته طلایی برای هفته آینده بگو.
''';

      final reply = await st.callBodyModAI(
        featureKey: 'body_log',
        modelId: st.bodyLogModel,
        userPrompt: prompt,
      );
      st.savedBodyAnalysis = reply;
      await st.prefs?.setString('bm_body_analysis', reply);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loadingAnalysis = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.appState;
    final isDark = st.isDark;
    final int quota = st.getRemainingQuotaToday('body_log', st.bodyLogModel);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // کارت ثبت لاگ جدید بدن
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
                    '📏 ثبت لاگ هفتگی بدن',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: BMColors.text(isDark),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (st.isUnderweight ? BMColors.neonOrange : BMColors.neonGreen)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'BMI: ${st.bmi.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: st.isUnderweight ? BMColors.neonOrange : BMColors.neonGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'وزن (kg)',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _waistCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'دور کمر (cm)',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _fatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'چربی (%)',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BMColors.neonBlue,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saveBodyLog,
                  icon: const Icon(Icons.save_alt),
                  label: const Text(
                    'ثبت سایز و وزن امروز در پرونده 📊',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // بخش تحلیل هوش مصنوعی لاگ بدن
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
                    '🧠 آنالیز هوشمند تغییرات بدن',
                    style: TextStyle(
                      fontSize: 15,
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
                      'سهمیه امروز: $quota بار',
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

              AIModelSelectorBar(
                featureKey: 'body_log',
                selectedModel: st.bodyLogModel,
                isDark: isDark,
                onChanged: (val) => setState(() => st.bodyLogModel = val),
              ),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BMColors.neonPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _loadingAnalysis ? null : _analyzeBodyProgress,
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text(
                    'تحلیل ۷ روزه بدن با هوش مصنوعی ⚡',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),

              if (_loadingAnalysis) ...[
                const SizedBox(height: 16),
                const BodyModBLoader(label: 'در حال بررسی نمودار وزن و فرم بدنی...'),
              ] else if (st.savedBodyAnalysis.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BMColors.bg(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BMColors.neonPurple.withOpacity(0.35)),
                  ),
                  child: SelectableText(
                    st.savedBodyAnalysis,
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
        const SizedBox(height: 16),

        // تاریخچه لاگ‌های ثبت‌شده
        if (st.bodyLogs.isNotEmpty)
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
                  '🗂️ تاریخچه ثبت‌های اخیر',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: BMColors.text(isDark),
                  ),
                ),
                const SizedBox(height: 8),
                ...st.bodyLogs.take(8).map((log) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.monitor_weight, color: BMColors.neonGreen),
                    title: Text(
                      'وزن: ${log['weight']} کیلوگرم',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: BMColors.text(isDark),
                      ),
                    ),
                    subtitle: Text(
                      'تاریخ: ${log['date']} • دور کمر: ${log['waist']}cm • چربی: ${log['fat']}%',
                      style: TextStyle(fontSize: 11.5, color: BMColors.muted(isDark)),
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

/// تب ۴: باشگاه هوشمند با تایمر استراحت بین ست‌ها و روزهای تمرینی
class SmartGymTab extends StatefulWidget {
  final AppState appState;
  const SmartGymTab({super.key, required this.appState});

  @override
  State<SmartGymTab> createState() => _SmartGymTabState();
}

class _SmartGymTabState extends State<SmartGymTab> {
  bool _loadingWorkout = false;
  String _workoutPlace = 'در خانه (بدون وسیله یا دمبل ساده)';
  int _restSeconds = 0;
  Timer? _restTimer;

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRestTimer(int sec) {
    _restTimer?.cancel();
    setState(() => _restSeconds = sec);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restSeconds <= 1) {
        t.cancel();
        if (mounted) {
          setState(() => _restSeconds = 0);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🔔 تایم استراحت تموم شد قهرمان! برو ست بعدی 💪')),
          );
        }
      } else {
        if (mounted) setState(() => _restSeconds--);
      }
    });
  }

  Future<void> _generateWorkoutPlan() async {
    final st = widget.appState;
    setState(() => _loadingWorkout = true);
    try {
      final prompt = '''
یک برنامه تمرینی استاندارد و حرفه‌ای متناسب با تعداد روزهای انتخابی کاربر در هفته (${st.workoutDaysPerWeek})، محیط تمرین ($_workoutPlace)، هدف (${st.fitnessGoal}) و دوره زمانی (${st.targetTimeline}) طراحی کن.
برای هر جلسه تمرینی:
- گرم کردن (۵ دقیقه)
- لیست حرکات اصلی همراه با تعداد ست، تعداد تکرار و زمان استراحت بین هر ست
- نکات ایمنی متناسب با حافظه پزشکی کاربر
''';
      final reply = await st.callBodyModAI(
        featureKey: 'workout',
        modelId: st.workoutModel,
        userPrompt: prompt,
      );
      st.savedWorkoutPlan = reply;
      await st.prefs?.setString('bm_workout_plan', reply);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loadingWorkout = false);
    }
  }

  Future<void> _toggleGymDay(int dayIdx) async {
    final st = widget.appState;
    if (st.completedGymDays.contains(dayIdx)) {
      st.completedGymDays.remove(dayIdx);
    } else {
      st.completedGymDays.add(dayIdx);
    }
    await st.prefs?.setString(
      'bm_gym_done_${st.todayWeekKey()}',
      jsonEncode(st.completedGymDays),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.appState;
    final isDark = st.isDark;
    final int quota = st.getRemainingQuotaToday('workout', st.workoutModel);
    const daysName = ['شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // تایمر استراحت بین ست‌ها
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BMColors.card(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BMColors.neonOrange.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '⏱️ تایمر استراحت بین ست‌ها',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: BMColors.text(isDark),
                    ),
                  ),
                  Text(
                    _restSeconds > 0 ? '$_restSeconds ثانیه ⏳' : 'آماده شروع!',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _restSeconds > 0 ? BMColors.neonOrange : BMColors.neonGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _startRestTimer(30),
                      child: const Text('۳۰ ثانیه'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _startRestTimer(60),
                      child: const Text('۶۰ ثانیه'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _startRestTimer(90),
                      child: const Text('۹۰ ثانیه'),
                    ),
                  ),
                  if (_restSeconds > 0) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () {
                        _restTimer?.cancel();
                        setState(() => _restSeconds = 0);
                      },
                      icon: const Icon(Icons.stop_circle, color: BMColors.neonRed),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // وضعیت روزهای تمرین این هفته (قفل / تکمیل‌شده)
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
              Text(
                '🗓️ چک‌لیست جلسات تمرین این هفته (${st.workoutDaysPerWeek})',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: BMColors.text(isDark),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (idx) {
                  final done = st.completedGymDays.contains(idx);
                  return InkWell(
                    onTap: () => _toggleGymDay(idx),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                      decoration: BoxDecoration(
                        color: done
                            ? BMColors.neonGreen.withOpacity(0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: done ? BMColors.neonGreen : Colors.grey.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            done ? Icons.check_circle : Icons.fitness_center,
                            size: 16,
                            color: done ? BMColors.neonGreen : BMColors.muted(isDark),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            daysName[idx],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: done ? BMColors.neonGreen : BMColors.text(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // دریافت برنامه تمرینی هوشمند با انتخابگر مدل AI
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
                    '🏋️‍♂️ طراحی برنامه تمرینی هوشمند',
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
                      'سهمیه امروز: $quota بار',
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

              // انتخابگر مدل هوش مصنوعی بالای دریافت برنامه تمرینی
              AIModelSelectorBar(
                featureKey: 'workout',
                selectedModel: st.workoutModel,
                isDark: isDark,
                onChanged: (val) => setState(() => st.workoutModel = val),
              ),

              DropdownButtonFormField<String>(
                value: _workoutPlace,
                dropdownColor: BMColors.card(isDark),
                style: TextStyle(color: BMColors.text(isDark), fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'محیط و تجهیزات تمرین',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'در خانه (بدون وسیله یا دمبل ساده)',
                    child: Text('🏠 تمرین در خانه (وزن بدن / دمبل)'),
                  ),
                  DropdownMenuItem(
                    value: 'باشگاه بدنسازی (با دستگاه‌های کامل)',
                    child: Text('🏋️ باشگاه بدنسازی (فول تجهیزات)'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _workoutPlace = v);
                },
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
                  onPressed: _loadingWorkout ? null : _generateWorkoutPlan,
                  icon: const Icon(Icons.bolt),
                  label: Text(
                    'دریافت برنامه تمرینی (${st.workoutDaysPerWeek}) 🚀',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),

              if (_loadingWorkout) ...[
                const SizedBox(height: 16),
                const BodyModBLoader(label: 'در حال طراحی ست‌ها و حرکات اختصاصی تو...'),
              ] else if (st.savedWorkoutPlan.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BMColors.bg(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BMColors.neonGreen.withOpacity(0.35)),
                  ),
                  child: SelectableText(
                    st.savedWorkoutPlan,
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

/// تب ۵: چت صمیمی با مربی هوشمند (ارسال کل فرم در هر پیام + سهمیه ۳ پیام 3.8 و ۶ پیام 3.5)
class AICoachChatTab extends StatefulWidget {
  final AppState appState;
  const AICoachChatTab({super.key, required this.appState});

  @override
  State<AICoachChatTab> createState() => _AICoachChatTabState();
}

class _AICoachChatTabState extends State<AICoachChatTab> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final st = widget.appState;
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    _msgCtrl.clear();
    st.chatMessages.add({
      'role': 'user',
      'text': text,
      'model': st.chatModel,
    });
    setState(() => _sending = true);

    try {
      // ارسال سوال کاربر به همراه کل پرونده بدنی (که داخل callBodyModAI خودکار تزریق می‌شود)
      final reply = await st.callBodyModAI(
        featureKey: 'chat',
        modelId: st.chatModel,
        userPrompt: text,
      );
      st.chatMessages.add({
        'role': 'ai',
        'text': reply,
        'model': st.chatModel,
      });
      if (st.chatMessages.length > 40) {
        st.chatMessages = st.chatMessages.sublist(st.chatMessages.length - 40);
      }
      await st.prefs?.setString('bm_chat_history', jsonEncode(st.chatMessages));
    } catch (e) {
      st.chatMessages.add({
        'role': 'ai',
        'text': '⚠️ $e',
        'model': st.chatModel,
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        Future.delayed(const Duration(milliseconds: 120), () {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.appState;
    final isDark = st.isDark;
    final int rem38 = st.getRemainingQuotaToday('chat', 'gemini-3.8-flash');
    final int rem35 = st.getRemainingQuotaToday('chat', 'gemini-3.5-flash-lite');

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // نوار نمایش سهمیه روزانه هر دو مدل + انتخابگر مدل
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: BMColors.card(isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BMColors.border(isDark)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  '🔥 3.8 Flash: $rem38 از 3 پیام',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: BMColors.neonOrange,
                  ),
                ),
                Text(
                  '⚡ 3.5 Flash-Lite: $rem35 از 6 پیام',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: BMColors.neonGreen,
                  ),
                ),
              ],
            ),
          ),

          AIModelSelectorBar(
            featureKey: 'chat',
            selectedModel: st.chatModel,
            isDark: isDark,
            onChanged: (val) => setState(() => st.chatModel = val),
          ),

          // لیست پیام‌های چت
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BMColors.card(isDark),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BMColors.border(isDark)),
              ),
              child: st.chatMessages.isEmpty
                  ? Center(
                      child: Text(
                        'سلام ${st.nickname.isEmpty ? "قهرمان" : st.nickname}! 👋\n'
                        'من تمام پرونده بدنی، هدفت (${st.fitnessGoal}) و برنامه تمرینی‌ت (${st.workoutDaysPerWeek}) رو بلدم.\n'
                        'هر سوالی درباره تغذیه، مکمل یا تمرین داری بپرس!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.7,
                          color: BMColors.muted(isDark),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      itemCount: st.chatMessages.length,
                      itemBuilder: (ctx, i) {
                        final m = st.chatMessages[i];
                        final isUser = m['role'] == 'user';
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.78,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? BMColors.neonPurple.withOpacity(0.22)
                                  : BMColors.bg(isDark),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isUser
                                    ? BMColors.neonPurple
                                    : BMColors.neonGreen.withOpacity(0.4),
                              ),
                            ),
                            child: SelectableText(
                              m['text'] ?? '',
                              style: TextStyle(
                                fontSize: 13.2,
                                height: 1.65,
                                color: BMColors.text(isDark),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          if (_sending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: BodyModBLoader(label: 'مربی بادی‌مود در حال نوشتن پاسخ...'),
            ),

          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  style: TextStyle(color: BMColors.text(isDark), fontSize: 13.5),
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'سوال ورزشی یا تغذیه‌ای خودت رو بنویس...',
                    filled: true,
                    fillColor: BMColors.card(isDark),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BMColors.neonGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _sending ? null : _sendMessage,
                  child: const Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
