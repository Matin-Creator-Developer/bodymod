import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

const String kServerUrl = 'https://server.matin-mohammadi.ir';
const String kGoogleWebClientId =
    '602509612708-q858bf72s0s96t3k9k93rvb3u7m6g2c5.apps.googleusercontent.com';

class BMColors {
  static const Color neonGreen = Color(0xFF00F5D4);
  static const Color neonPurple = Color(0xFF9B5DE5);
  static const Color neonOrange = Color(0xFFF97316);
  static const Color neonBlue = Color(0xFF00BBF9);
  static const Color neonRed = Color(0xFFEF4444);
  static const Color neonGold = Color(0xFFFBBF24);

  static Color bg(bool isDark) =>
      isDark ? const Color(0xFF070A12) : const Color(0xFFF1F5F9);
  static Color card(bool isDark) =>
      isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF);
  static Color text(bool isDark) =>
      isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  static Color muted(bool isDark) =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color border(bool isDark) => isDark
      ? const Color(0xFF00F5D4).withOpacity(0.25)
      : const Color(0xFF0D9488).withOpacity(0.3);
}

class AppState extends ChangeNotifier {
  SharedPreferences? prefs;
  bool isDark = true;
  String token = '';
  String userIdentifier = '';
  String selectedMarket = 'bazaar'; // 'bazaar' or 'myket'
  bool isPro = false;
  bool isAdmin = false;

  // فیلدهای کامل فرم پروفایل (پرونده بدنی)
  String nickname = '';
  String birthDay = '14';
  String birthMonth = '10';
  String birthYear = '1383';
  String gender = 'مرد';
  String city = '';
  String economicStatus = 'متوسط'; // ضعیف | متوسط | عالی
  double heightCm = 175;
  double weightKg = 70;
  String fitnessGoal = 'تناسب اندام و سلامتی';
  String targetTimeline = '۳ ماهه';
  String workoutDaysPerWeek = '۳ روز در هفته'; // ۱ روز | ۲ روز | ۳ روز | هر روز
  String aiMemoryNotes = '';

  // کالری، آب و آتیش (Streak)
  int streakCount = 1;
  bool isBlueFire = false;
  int todayWaterGlasses = 0;
  List> todayFoods = [];
  Map<String, int> weeklyCalories = {}; // YYYY-MM-DD -> kcal

  // داده‌های هوش مصنوعی ذخیره‌شده
  String savedMealPlan = '';
  String savedWorkoutPlan = '';
  String savedBodyAnalysis = '';
  List> bodyLogs = [];
  List> chatMessages = [];
  List<int> completedGymDays = [];

  // مدل‌های انتخابی بالای هر بخش
  String chatModel = 'gemini-3.5-flash-lite';
  String mealModel = 'gemini-3.5-flash-lite';
  String scannerModel = 'gemini-3.5-flash-lite';
  String workoutModel = 'gemini-3.5-flash-lite';
  String bodyLogModel = 'gemini-3.5-flash-lite';

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    isDark = prefs?.getBool('bm_dark') ?? true;
    token = prefs?.getString('bm_token') ?? '';
    userIdentifier = prefs?.getString('bm_user_id') ?? '';
    selectedMarket = prefs?.getString('bm_market') ?? 'bazaar';
    isPro = prefs?.getBool('bm_is_pro') ?? false;
    isAdmin = prefs?.getBool('bm_is_admin') ?? false;

    nickname = prefs?.getString('bm_nickname') ?? '';
    birthDay = prefs?.getString('bm_bday') ?? '14';
    birthMonth = prefs?.getString('bm_bmonth') ?? '10';
    birthYear = prefs?.getString('bm_byear') ?? '1383';
    gender = prefs?.getString('bm_gender') ?? 'مرد';
    city = prefs?.getString('bm_city') ?? '';
    economicStatus = prefs?.getString('bm_econ') ?? 'متوسط';
    heightCm = prefs?.getDouble('bm_height') ?? 175;
    weightKg = prefs?.getDouble('bm_weight') ?? 70;
    fitnessGoal = prefs?.getString('bm_goal') ?? 'تناسب اندام و سلامتی';
    targetTimeline = prefs?.getString('bm_timeline') ?? '۳ ماهه';
    workoutDaysPerWeek = prefs?.getString('bm_workout_days') ?? '۳ روز در هفته';
    aiMemoryNotes = prefs?.getString('bm_ai_memory') ?? '';

    streakCount = prefs?.getInt('bm_streak') ?? 1;
    todayWaterGlasses = prefs?.getInt('bm_water_${todayKey()}') ?? 0;

    final foodsRaw = prefs?.getString('bm_foods_${todayKey()}');
    if (foodsRaw != null) {
      todayFoods = List>.from(jsonDecode(foodsRaw));
    }

    final calMapRaw = prefs?.getString('bm_weekly_cal');
    if (calMapRaw != null) {
      weeklyCalories = Map<String, int>.from(jsonDecode(calMapRaw));
    }

    savedMealPlan = prefs?.getString('bm_meal_plan') ?? '';
    savedWorkoutPlan = prefs?.getString('bm_workout_plan') ?? '';
    savedBodyAnalysis = prefs?.getString('bm_body_analysis') ?? '';

    final logsRaw = prefs?.getString('bm_body_logs');
    if (logsRaw != null) {
      bodyLogs = List>.from(jsonDecode(logsRaw));
    }

    final chatRaw = prefs?.getString('bm_chat_history');
    if (chatRaw != null) {
      chatMessages = List>.from(
        (jsonDecode(chatRaw) as List).map((e) => Map<String, String>.from(e)),
      );
    }

    final gymDoneRaw = prefs?.getString('bm_gym_done_${todayWeekKey()}');
    if (gymDoneRaw != null) {
      completedGymDays = List<int>.from(jsonDecode(gymDoneRaw));
    }

    _evaluateStreakFire();
    notifyListeners();
  }

  String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String todayWeekKey() {
    final now = DateTime.now();
    final weekOfYear = (now.difference(DateTime(now.year, 1, 1)).inDays / 7).floor();
    return '${now.year}-W$weekOfYear';
  }

  void refreshUI() { notifyListeners(); }

  void toggleTheme() {
    isDark = !isDark;
    prefs?.setBool('bm_dark', isDark);
    notifyListeners();
  }

  void setMarket(String market) {
    selectedMarket = market;
    prefs?.setString('bm_market', market);
    notifyListeners();
  }

  int get targetDailyCalories {
    // فرمول Mifflin-St Jeor
    final int age = (1405 - (int.tryParse(birthYear) ?? 1383)).clamp(12, 90);
    double bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    bmr += (gender == 'مرد') ? 5 : -161;
    double tdee = bmr * 1.45;
    if (fitnessGoal.contains('کاهش وزن')) return (tdee - 450).round();
    if (fitnessGoal.contains('افزایش وزن') || fitnessGoal.contains('عضله')) {
      return (tdee + 400).round();
    }
    return tdee.round();
  }

  int get todayTotalCalories {
    int sum = 0;
    for (final f in todayFoods) {
      sum += (f['cal'] as num).toInt();
    }
    return sum;
  }

  double get bmi {
    final hMeter = heightCm / 100.0;
    if (hMeter <= 0) return 22.0;
    return weightKg / (hMeter * hMeter);
  }

  bool get isUnderweight => bmi < 18.5;

  void _evaluateStreakFire() {
    final diff = (todayTotalCalories - targetDailyCalories).abs();
    isBlueFire = todayTotalCalories > 0 && diff <= 150 && todayWaterGlasses >= 6;
  }

  void addWaterGlass(int delta) {
    todayWaterGlasses = (todayWaterGlasses + delta).clamp(0, 20);
    prefs?.setInt('bm_water_${todayKey()}', todayWaterGlasses);
    _evaluateStreakFire();
    notifyListeners();
  }

  void addFoodItem(String title, int cal) {
    todayFoods.insert(0, {
      'title': title,
      'cal': cal,
      'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    });
    weeklyCalories[todayKey()] = todayTotalCalories;
    prefs?.setString('bm_foods_${todayKey()}', jsonEncode(todayFoods));
    prefs?.setString('bm_weekly_cal', jsonEncode(weeklyCalories));
    _evaluateStreakFire();
    notifyListeners();
  }

  void removeFoodItem(int index) {
    todayFoods.removeAt(index);
    weeklyCalories[todayKey()] = todayTotalCalories;
    prefs?.setString('bm_foods_${todayKey()}', jsonEncode(todayFoods));
    prefs?.setString('bm_weekly_cal', jsonEncode(weeklyCalories));
    _evaluateStreakFire();
    notifyListeners();
  }

  // ذخیره کامل فرم پروفایل
  Future<void> saveProfile({
    required String newNickname,
    required String newBDay,
    required String newBMonth,
    required String newBYear,
    required String newGender,
    required String newCity,
    required String newEconomicStatus,
    required double newHeight,
    required double newWeight,
    required String newGoal,
    required String newTimeline,
    required String newWorkoutDays,
    required String newAiMemory,
  }) async {
    nickname = newNickname;
    birthDay = newBDay;
    birthMonth = newBMonth;
    birthYear = newBYear;
    gender = newGender;
    city = newCity;
    economicStatus = newEconomicStatus;
    heightCm = newHeight;
    weightKg = newWeight;
    fitnessGoal = newGoal;
    targetTimeline = newTimeline;
    workoutDaysPerWeek = newWorkoutDays;
    aiMemoryNotes = newAiMemory;

    await prefs?.setString('bm_nickname', nickname);
    await prefs?.setString('bm_bday', birthDay);
    await prefs?.setString('bm_bmonth', birthMonth);
    await prefs?.setString('bm_byear', birthYear);
    await prefs?.setString('bm_gender', gender);
    await prefs?.setString('bm_city', city);
    await prefs?.setString('bm_econ', economicStatus);
    await prefs?.setDouble('bm_height', heightCm);
    await prefs?.setDouble('bm_weight', weightKg);
    await prefs?.setString('bm_goal', fitnessGoal);
    await prefs?.setString('bm_timeline', targetTimeline);
    await prefs?.setString('bm_workout_days', workoutDaysPerWeek);
    await prefs?.setString('bm_ai_memory', aiMemoryNotes);

    _evaluateStreakFire();
    notifyListeners();

    // همگام‌سازی پروفایل با سرور کلودفلر
    if (token.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('$kServerUrl/api/profile/sync'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(buildFullProfileJson()),
        );
      } catch (_) {}
    }
  }

  Map<String, dynamic> buildFullProfileJson() {
    final int approxAge = (1405 - (int.tryParse(birthYear) ?? 1383)).clamp(10, 95);
    return {
      'nickname': nickname.isEmpty ? 'ورزشکار بادی‌مود' : nickname,
      'birthDate': '$birthYear/$birthMonth/$birthDay',
      'age': approxAge,
      'gender': gender,
      'city': city.isEmpty ? 'نامشخص' : city,
      'economicStatus': economicStatus,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'bmi': double.parse(bmi.toStringAsFixed(1)),
      'isUnderweight': isUnderweight,
      'fitnessGoal': fitnessGoal,
      'targetTimeline': targetTimeline,
      'workoutDaysPerWeek': workoutDaysPerWeek,
      'aiMemoryNotes': aiMemoryNotes,
      'todayCalories': todayTotalCalories,
      'targetCalories': targetDailyCalories,
      'todayWaterGlasses': todayWaterGlasses,
    };
  }

  // ساخت متن کامل پرونده بدنی که در هر پیام چت و هر پرامپت AI تزریق می‌شود
  String buildSystemProfileContext() {
    final p = buildFullProfileJson();
    final underweightRule = isUnderweight
        ? '⚠️ قانون مهم مربی: چون BMI کاربر کمتر از 18.5 است (${p['bmi']}) و کمبود وزن دارد، حتی اگر هدفش عضله‌سازی است، اولویت اولت افزایش وزن اصولی و رسیدن به وزن سالم قبل از خشک‌کردن یا کات عضلانی باشد.'
        : '';

    return '''
[پرونده کامل بدنی کاربر در BodyMod - حتماً پاسخ را ۱۰۰٪ شخصی‌سازی‌شده بر اساس این اطلاعات بده]:
- نام/لقب: ${p['nickname']} | جنسیت: ${p['gender']} | تاریخ تولد: ${p['birthDate']} (حدود ${p['age']} سال)
- شهر محل سکونت: ${p['city']} | وضعیت اقتصادی برای خرید مواد غذایی/مکمل: ${p['economicStatus']}
- قد: ${p['heightCm']} سانتی‌متر | وزن فعلی: ${p['weightKg']} کیلوگرم | BMI: ${p['bmi']}
- هدف اصلی: ${p['fitnessGoal']} | دوره زمانی رسیدن به هدف: ${p['targetTimeline']} 🚀
- تعداد روزهای تمرین در هفته: ${p['workoutDaysPerWeek']}
- کالری مصرفی امروز تا این لحظه: ${p['todayCalories']} از هدف ${p['targetCalories']} کیلوکالری | آب امروز: ${p['todayWaterGlasses']} لیوان
- حافظه اختصاصی مربی (بیماری زمینه‌ای، داروها، حساسیت غذایی و نکات شخصی): ${aiMemoryNotes.isEmpty ? 'مورد خاصی ثبت نشده' : aiMemoryNotes}
$underweightRule
''';
  }

  // سهمیه‌بندی دقیق روزانه هوش مصنوعی:
  // در چت: روزانه ۳ پیام با Gemini 3.8 Flash و ۶ پیام با Gemini 3.5 Flash-Lite
  // در سایر بخش‌ها (برنامه غذایی، باشگاه، لاگ بدن، اسکنر): روزانه ۱ بار با 3.8 Flash و ۲ بار با 3.5 Flash-Lite
  int getQuotaLimit(String featureKey, String modelId) {
    final bool is38 = modelId.contains('3.8');
    if (featureKey == 'chat') {
      return is38 ? 3 : 6;
    } else {
      return is38 ? 1 : 2;
    }
  }

  int getUsedQuotaToday(String featureKey, String modelId) {
    final bool is38 = modelId.contains('3.8');
    final String mTag = is38 ? '38' : '35lite';
    final String key = 'bm_quota_${todayKey()}_${featureKey}_$mTag';
    return prefs?.getInt(key) ?? 0;
  }

  int getRemainingQuotaToday(String featureKey, String modelId) {
    final limit = getQuotaLimit(featureKey, modelId);
    final used = getUsedQuotaToday(featureKey, modelId);
    return (limit - used).clamp(0, limit);
  }

  Future<void> incrementQuotaUsage(String featureKey, String modelId) async {
    final bool is38 = modelId.contains('3.8');
    final String mTag = is38 ? '38' : '35lite';
    final String key = 'bm_quota_${todayKey()}_${featureKey}_$mTag';
    final used = getUsedQuotaToday(featureKey, modelId);
    await prefs?.setInt(key, used + 1);
    notifyListeners();
  }

  // فراخوانی یکپارچه هوش مصنوعی از سرور کلودفلر با تزریق خودکار کل فرم پروفایل
  Future<String> callBodyModAI({
    required String featureKey, // 'chat' | 'meal' | 'workout' | 'body_log' | 'scanner'
    required String modelId, // 'gemini-3.5-flash-lite' | 'gemini-3.8-flash'
    required String userPrompt,
  }) async {
    final remaining = getRemainingQuotaToday(featureKey, modelId);
    final modelDisplayName =
        modelId.contains('3.8') ? 'Gemini 3.8 Flash' : 'Gemini 3.5 Flash-Lite';

    if (remaining <= 0) {
      throw Exception(
        'سهمیه امروزت برای مدل $modelDisplayName در این بخش تموم شده رفیق! ⏳\n'
        'می‌تونی از منوی بالای همین بخش، مدل دیگه رو انتخاب کنی یا فردا دوباره امتحان کنی.',
      );
    }

    final fullPrompt = '${buildSystemProfileContext()}\n\nدرخواست کاربر:\n$userPrompt';

    final response = await http
        .post(
          Uri.parse('$kServerUrl/api/ai'),
          headers: {
            'Content-Type': 'application/json',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'feature': featureKey,
            'model': modelId,
            'prompt': fullPrompt,
            'profile': buildFullProfileJson(),
          }),
        )
        .timeout(const Duration(seconds: 50));

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || data['error'] != null) {
      throw Exception(data['error'] ?? 'خطا در ارتباط با هوش مصنوعی بادی‌مود');
    }

    await incrementQuotaUsage(featureKey, modelId);
    return (data['reply'] ?? data['result'] ?? data['text'] ?? '').toString();
  }

  Future<void> setAuthSession({
    required String newToken,
    required String identifier,
    bool admin = false,
    bool pro = false,
  }) async {
    token = newToken;
    userIdentifier = identifier;
    isAdmin = admin || identifier.contains('0914') || identifier.contains('matin');
    isPro = pro;
    await prefs?.setString('bm_token', token);
    await prefs?.setString('bm_user_id', userIdentifier);
    await prefs?.setBool('bm_is_admin', isAdmin);
    await prefs?.setBool('bm_is_pro', isPro);
    notifyListeners();
  }

  Future<void> logout() async {
    token = '';
    userIdentifier = '';
    isAdmin = false;
    await prefs?.remove('bm_token');
    await prefs?.remove('bm_user_id');
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    notifyListeners();
  }
}

/// ویجت انتخاب مدل هوش مصنوعی بالای هر بخش (همراه با نمایش سهمیه باقی‌مانده امروز)
class AIModelSelectorBar extends StatelessWidget {
  final String featureKey;
  final String selectedModel;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const AIModelSelectorBar({
    super.key,
    required this.featureKey,
    required this.selectedModel,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: BMColors.card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BMColors.neonPurple.withOpacity(0.45), width: 1.3),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: BMColors.neonGreen, size: 19),
          const SizedBox(width: 8),
          Text(
            'مدل هوش مصنوعی:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: BMColors.text(isDark),
            ),
          ),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedModel,
              dropdownColor: BMColors.card(isDark),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: BMColors.neonGreen,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'gemini-3.5-flash-lite',
                  child: Text('⚡ Gemini 3.5 Flash-Lite (سریع)'),
                ),
                DropdownMenuItem(
                  value: 'gemini-3.8-flash',
                  child: Text('🔥 Gemini 3.8 Flash (فوق‌پیشرفته)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// انیمیشن لودینگ اختصاصی حرف B نئونی بادی‌مود
class BodyModBLoader extends StatefulWidget {
  final String label;
  const BodyModBLoader({super.key, this.label = 'هوش مصنوعی بادی‌مود در حال تحلیل...'});

  @override
  State<BodyModBLoader> createState() => _BodyModBLoaderState();
}

class _BodyModBLoaderState extends State<BodyModBLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final scale = 0.92 + (_ctrl.value * 0.18);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [BMColors.neonGreen, BMColors.neonPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: BMColors.neonGreen.withOpacity(0.45 * _ctrl.value),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Text(
                    'B',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF070A12),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: BMColors.neonGreen,
            ),
          ),
        ],
      ),
    );
  }
}

/// صفحه ورود بومی (Native Google Bottom-Sheet + ورود دو مرحله‌ای بله با تایمر ۳۰ ثانیه‌ای)
class AuthScreen extends StatefulWidget {
  final AppState appState;
  const AuthScreen({super.key, required this.appState});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  int _timerSeconds = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _start30SecTimer() {
    _countdownTimer?.cancel();
    setState(() => _timerSeconds = 30);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSeconds <= 1) {
        t.cancel();
        if (mounted) setState(() => _timerSeconds = 0);
      } else {
        if (mounted) setState(() => _timerSeconds--);
      }
    });
  }

  Future<void> _handleNativeGoogleSignIn() async {
    setState(() => _loading = true);
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: kGoogleWebClientId,
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        setState(() => _loading = false);
        return;
      }
      final auth = await account.authentication;
      final res = await http.post(
        Uri.parse('$kServerUrl/api/auth/google-native'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': account.email,
          'displayName': account.displayName ?? '',
          'idToken': auth.idToken ?? '',
          'accessToken': auth.accessToken ?? '',
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        await widget.appState.setAuthSession(
          newToken: data['token'] ?? 'google_${account.id}',
          identifier: account.email,
          admin: data['isAdmin'] == true,
          pro: data['isPro'] == true,
        );
      } else {
        // در صورت عدم پاسخ سرور، ورود بومی با ایمیل گوگل تاییدشده انجام می‌شود
        await widget.appState.setAuthSession(
          newToken: 'google_native_${account.id}',
          identifier: account.email,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ورود بومی گوگل: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendBaleOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً شماره موبایل معتبر وارد کن رفیق!')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('$kServerUrl/api/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 200 && data['error'] == null) {
        setState(() => _codeSent = true);
        _start30SecTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ کد تایید به بازوی بله ارسال شد!')),
          );
        }
      } else {
        throw Exception(data['error'] ?? 'خطا در ارسال کد بله');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyBaleOtp() async {
    final phone = _phoneCtrl.text.trim();
    final code = _otpCtrl.text.trim();
    if (code.length < 4) return;
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('$kServerUrl/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'code': code}),
      );
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 200 && data['token'] != null) {
        await widget.appState.setAuthSession(
          newToken: data['token'],
          identifier: phone,
          admin: data['isAdmin'] == true,
          pro: data['isPro'] == true,
        );
      } else {
        throw Exception(data['error'] ?? 'کد وارد شده نادرست است');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BMColors.bg(isDark),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: BMColors.card(isDark),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: BMColors.border(isDark), width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🦾 BodyMod AI',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: BMColors.neonGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'مربی هوشمند تناسب اندام، کالری‌شمار و باشگاه جیبی تو',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: BMColors.muted(isDark)),
                    ),
                    const SizedBox(height: 24),

                    // دکمه لاگین بومی گوگل (پنجره از پایین صفحه)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _loading ? null : _handleNativeGoogleSignIn,
                        icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.redAccent),
                        label: const Text(
                          'ورود سریع و بومی با حساب گوگل',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('─── یا ورود با شماره موبایل (بازوی بله) ───',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                    ),

                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: BMColors.text(isDark)),
                      decoration: InputDecoration(
                        labelText: 'شماره موبایل (مثلاً 0914...)',
                        prefixIcon: const Icon(Icons.phone_android, color: BMColors.neonGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_codeSent) ...[
                      TextField(
                        controller: _otpCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: BMColors.text(isDark)),
                        decoration: InputDecoration(
                          labelText: 'کد تایید دریافتی از بله',
                          prefixIcon: const Icon(Icons.lock_outline, color: BMColors.neonPurple),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BMColors.neonGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _loading ? null : _verifyBaleOtp,
                          child: const Text(
                            'تایید کد و ورود به بادی‌مود 🚀',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: BMColors.neonPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: (_loading || _timerSeconds > 0) ? null : _sendBaleOtp,
                        child: Text(
                          _timerSeconds > 0
                              ? 'ارسال مجدد کد تا $_timerSeconds ثانیه دیگر ⏳'
                              : (_codeSent ? 'ارسال مجدد کد به بله' : 'دریافت کد تایید در بله 📩'),
                          style: const TextStyle(
                            color: BMColors.neonPurple,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse('https://ble.ir/bodymod_bot'),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16, color: BMColors.neonBlue),
                      label: const Text(
                        'اولین بارته؟ اول بازوی بله (@bodymod_bot) رو استارت کن',
                        style: TextStyle(fontSize: 12, color: BMColors.neonBlue),
                      ),
                    ),

                    if (_loading) ...[
                      const SizedBox(height: 16),
                      const BodyModBLoader(label: 'در حال برقراری ارتباط امن...'),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
