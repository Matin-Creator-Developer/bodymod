// ============================================================================
// BodyMod AI (بادی‌مود) — v8.2 Production Market Launch Edition
// Package: ir.matinmohammadi.bodymod
// Backend: Cloudflare Worker (https://server.matin-mohammadi.ir)
// Unified Single-File Native Flutter Architecture: lib/main.dart
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

List<int> _bmG2J(int gy, int gm, int gd) {
  const m = [0,31,59,90,120,151,181,212,243,273,304,334];
  int g2 = (gm > 2) ? (gy + 1) : gy;
  int d = 355666 + (365 * gy) + ((g2 + 3) ~/ 4) - ((g2 + 99) ~/ 100) + ((g2 + 399) ~/ 400) + gd + m[gm - 1];
  int jy = -1595 + (33 * (d ~/ 12053)); d %= 12053;
  jy += 4 * (d ~/ 1461); d %= 1461;
  if (d > 365) { jy += (d - 1) ~/ 365; d = (d - 1) % 365; }
  return [jy, (d < 186) ? 1 + (d ~/ 31) : 7 + ((d - 186) ~/ 30), 1 + ((d < 186) ? (d % 31) : ((d - 186) % 30))];
}
int? bmCalculateAgeFromBirthDate(String raw) {
  String s = raw;
  const fa = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'], ar = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
  for (int i = 0; i < 10; i++) { s = s.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i'); }
  final p = RegExp(r'\d+').allMatches(s).map((m) => int.tryParse(m.group(0)!) ?? 0).where((n) => n > 0).toList();
  if (p.isEmpty) return null;
  final now = DateTime.now(); final jn = _bmG2J(now.year, now.month, now.day);
  final int cy = jn[0], cm = jn[1], cd = jn[2];
  if (p.length == 1) return (p[0] >= 1300 && p[0] <= cy) ? (cy - p[0]).clamp(8, 100) : (p[0] >= 8 && p[0] <= 100 ? p[0] : null);
  int by = 0, bm = 1, bd = 1;
  if (p.length >= 3) {
    if (p[2] >= 1300) { bd = p[0]; bm = p[1]; by = p[2]; }
    else if (p[0] >= 1300) { by = p[0]; bm = p[1]; bd = p[2]; }
    else if (p[2] >= 30 && p[2] <= 99) { bd = p[0]; bm = p[1]; by = 1300 + p[2]; }
  } else if (p.length == 2) {
    if (p[1] >= 1300) { bm = p[0]; by = p[1]; } else if (p[0] >= 1300) { by = p[0]; bm = p[1]; }
  }
  if (by < 1300 || by > cy) return null;
  int age = cy - by; if (cm < bm || (cm == bm && cd < bd)) age -= 1;
  return age.clamp(8, 100);
}
Future<T?> bmShowResponsiveSheet<T>({
  required BuildContext context, required WidgetBuilder builder,
  Color? backgroundColor, double? elevation, ShapeBorder? shape, Clip? clipBehavior,
  BoxConstraints? constraints, Color? barrierColor, bool isScrollControlled = true,
  bool useRootNavigator = false, bool isDismissible = true, bool enableDrag = true,
  bool? showDragHandle, bool useSafeArea = true, RouteSettings? routeSettings,
  AnimationController? transitionAnimationController, Offset? anchorPoint,
}) {
  final rmq = MediaQuery.of(context);
  double sb = rmq.viewPadding.bottom > rmq.padding.bottom ? rmq.viewPadding.bottom : rmq.padding.bottom;
  if (sb < 48.0) sb = 48.0;
  return showModalBottomSheet<T>(
    context: context, isScrollControlled: true, useSafeArea: true,
    backgroundColor: backgroundColor ?? const Color(0xFF151922), elevation: elevation,
    shape: shape ?? const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    clipBehavior: clipBehavior ?? Clip.antiAlias, barrierColor: barrierColor,
    useRootNavigator: useRootNavigator, isDismissible: isDismissible, enableDrag: enableDrag,
    showDragHandle: showDragHandle, routeSettings: routeSettings,
    transitionAnimationController: transitionAnimationController, anchorPoint: anchorPoint,
    constraints: constraints ?? BoxConstraints(maxHeight: rmq.size.height * 0.88, maxWidth: rmq.size.width > 560 ? 520 : rmq.size.width),
    builder: (ctx) {
      final mq = MediaQuery.of(ctx);
      final bp = (mq.viewPadding.bottom > sb ? mq.viewPadding.bottom : sb) + mq.viewInsets.bottom + 20.0;
      return SafeArea(top: false, bottom: true, child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.86),
        child: SingleChildScrollView(physics: const BouncingScrollPhysics(), padding: EdgeInsets.only(bottom: bp), child: builder(ctx)),
      ));
    },
  );
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF090D16),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final controller = BodyModController();
  await controller.initialize();

  runApp(BodyModApp(controller: controller));
}

// ============================================================================
// 1. PRODUCTION CONFIGURATION & CONSTANTS
// ============================================================================

class AppConfig {
  static const String appName = 'BodyMod AI';
  static const String appVersion = '8.2.0';
  static const String packageName = 'ir.matinmohammadi.bodymod';
  static const String serverBaseUrl = 'https://server.matin-mohammadi.ir';

  // آیدی کانال رسمی بادی‌مود (بالای تمام صفحات نمایش داده می‌شود)
  static const String channelId = '@bodymod_channel';
  static const String channelUrlBale = 'https://ble.ir/bodymod_channel';
  static const String channelUrlTelegram = 'https://t.me/bodymod_channel';

  // محدودیت فاز بتا روی Free Tier گوگل
  static const int betaMaxSubscribers = 1000;

  // قیمت اشتراک ۱ ماهه (تومان)
  static const int monthlySubscriptionPriceToman = 189000;
  static const String monthlySubscriptionSku = 'bodymod_sub_189k';

  // مبالغ حمایت مالی چندباره و نامحدود (Consumable IAP در بازار و مایکت)
  static const List<Map<String, dynamic>> donationTiers = [
    {
      'sku': 'donate_10k',
      'amount': 10000,
      'label': '۱۰ هزار تومن 🌱',
      'desc': 'حمایت گرم و رفیقانه',
    },
    {
      'sku': 'donate_50k',
      'amount': 50000,
      'label': '۵۰ هزار تومن ⚡',
      'desc': 'کمک به ارتقای سرورها',
    },
    {
      'sku': 'donate_100k',
      'amount': 100000,
      'label': '۱۰۰ هزار تومن 🔥',
      'desc': 'شتاب‌دهنده خروج از فاز بتا',
    },
    {
      'sku': 'donate_500k',
      'amount': 500000,
      'label': '۵۰۰ هزار تومن 🚀',
      'desc': 'حامی ویژه زیرساخت هوش مصنوعی',
    },
    {
      'sku': 'donate_1m',
      'amount': 1000000,
      'label': '۱ میلیون تومن 👑💎',
      'desc': 'حامی طلایی و اسطوره‌ای بادی‌مود',
    },
  ];

  // سوییچ بادی‌کوین (برای آینده پس از خرید API پولی گوگل)
  static bool useBodyCoinSystem = false;

  // کانال ارتباطی نیتیو با درگاه پرداخت کافه‌بازار (Poolakey) / مایکت (Myket IAB)
  static const MethodChannel marketBillingChannel = MethodChannel(
    'ir.matinmohammadi.bodymod/billing',
  );
  static const MethodChannel nativeNotificationChannel = MethodChannel(
    'ir.matinmohammadi.bodymod/notifications',
  );

  static String normalizeDigits(String input) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    var out = input;
    for (int i = 0; i < 10; i++) {
      out = out.replaceAll(persian[i], i.toString());
      out = out.replaceAll(arabic[i], i.toString());
    }
    return out.trim();
  }

  // متن راهنمای داخل کادر حافظه هوش مصنوعی (با تایپ کردن کاربر خودکار پاک می‌شود)
  static const String aiMemoryHintText =
      'مثال (با تایپ کردن شما این متن پاک می‌شه):\n'
      '۱. بیماری خاص، آسیب‌دیدگی مفصلی یا دیسک کمر داری؟ داروی خاصی مصرف می‌کنی؟\n'
      '۲. به چه خوراکی‌هایی حساسیت داری یا اصلاً دوست نداری؟\n'
      '۳. ساعت خوابت چطوره، شیفت کاری داری یا نکته دیگه‌ای هست که مربی باید همیشه یادش بمونه؟\n'
      '(خیالت راحت رفیق، این اطلاعات کاملاً امن هستن 🔒)';

  // ۴ سطح وضعیت اقتصادی و میزان درآمد ماهانه
  static const String budgetBase = 'base';
  static const String budgetMid = 'mid';
  static const String budgetFlagship = 'flagship';
  static const String budgetVip = 'vip';

  static const Map<String, String> budgetTierOptions = {
    budgetBase: 'پایه زیر ۲۰ میلیون تومن',
    budgetMid: 'میان رده ۲۰ تا ۵۰ میلیون تومن',
    budgetFlagship: 'پرچمدار ۵۰ تا ۱۰۰ میلیون تومن',
    budgetVip: 'ویژه (VIP) بالای ۱۰۰ میلیون تومن',
  };

  static String budgetLabel(String key) =>
      budgetTierOptions[key] ?? budgetTierOptions[budgetBase]!;

  // ۶ گزینه دقیق هدف بدنسازی و تناسب اندام
  static const Map<String, String> goalOptions = {
    'loss_fat': 'کاهش وزن و چربی سوزی',
    'maintain_health': 'تثبیت وزن و سلامت عمومی',
    'gain_bulk': 'افزایش وزن عمومی (حجم گیری)',
    'gain_muscle': 'افزایش وزن و عضله سازی',
    'maintain_muscle': 'تثبیت وزن و عضله سازی',
    'loss_muscle': 'کاهش وزن و عضله سازی',
  };

  static String goalLabel(String key) =>
      goalOptions[key] ?? goalOptions['gain_muscle']!;

  // گزینه‌های تعداد روزهای تمرین در هفته
  static const Map<String, String> workoutDaysOptions = {
    'none': 'نیازی به تمرین ندارم (افزایش یا تثبیت وزن)',
    'd1': '۱ روز در هفته',
    'd2': '۲ روز در هفته',
    'd3': '۳ روز در هفته',
    'd4': '۴ روز در هفته',
    'd5': '۵ روز در هفته',
    'd6': '۶ روز در هفته',
    'd7': 'هرروز (۷ روز هفته)',
  };

  static String workoutDaysLabel(String key) =>
      workoutDaysOptions[key] ?? workoutDaysOptions['d3']!;

  // محاسبه تخمینی توکن و بادی‌کوین (برای Long-Press روی دکمه ارسال)
  static Map<String, int> estimateTokenAndCoinCost(
    String text, {
    bool hasImage = false,
    String memoryText = '',
  }) {
    final cleanText = text.trim();
    final charCount = cleanText.length + memoryText.trim().length;
    const int baseSystemTokens = 320;
    final int textTokens = (charCount / 3.2).ceil();
    final int imageTokens = hasImage ? 560 : 0;
    const int estimatedOutputTokens = 450;
    final int totalTokens =
        baseSystemTokens + textTokens + imageTokens + estimatedOutputTokens;
    final int bodyCoins = math.max(1, (totalTokens / 250).ceil());
    return {
      'tokens': totalTokens,
      'coins': bodyCoins,
      'inputTokens': baseSystemTokens + textTokens + imageTokens,
      'outputTokens': estimatedOutputTokens,
    };
  }
}

// ============================================================================
// 2. THEME & DESIGN TOKENS (OBSIDIAN NEON + LIGHT MODE)
// ============================================================================

class BMColors {
  static const Color bgDark = Color(0xFF090D16);
  static const Color surfaceDark = Color(0xFF121826);
  static const Color cardDark = Color(0xFF1A2235);
  static const Color cardBorderDark = Color(0xFF28344E);

  static const Color neonCyan = Color(0xFF00F5D4);
  static const Color neonGreen = Color(0xFF10B981);
  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color flameOrange = Color(0xFFFF6B35);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color whaleGold = Color(0xFFFFD700);
  static const Color purpleAccent = Color(0xFF8B5CF6);

  static const Color bgLight = Color(0xFFF3F6FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0xFFE2E8F0);
}

class BMTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: BMColors.bgDark,
      primaryColor: BMColors.neonCyan,
      colorScheme: const ColorScheme.dark(
        primary: BMColors.neonCyan,
        secondary: BMColors.neonGreen,
        surface: BMColors.surfaceDark,
        error: BMColors.dangerRed,
      ),
      cardColor: BMColors.cardDark,
      dividerColor: BMColors.cardBorderDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: BMColors.bgDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 17.5,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0E1422),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BMColors.cardBorderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BMColors.cardBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BMColors.neonCyan, width: 1.8),
        ),
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: BMColors.bgLight,
      primaryColor: const Color(0xFF0D9488),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0D9488),
        secondary: Color(0xFF059669),
        surface: BMColors.surfaceLight,
        error: BMColors.dangerRed,
      ),
      cardColor: BMColors.cardLight,
      dividerColor: BMColors.cardBorderLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: BMColors.surfaceLight,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(
          fontSize: 17.5,
          fontWeight: FontWeight.w900,
          color: Color(0xFF0F172A),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BMColors.cardBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BMColors.cardBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.8),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. TOP CHANNEL BANNER WIDGET (DISPLAYED AT THE TOP OF ALL PAGES)
// ============================================================================

class BodyModTopChannelBanner extends StatelessWidget {
  const BodyModTopChannelBanner({super.key});

  Future<void> _openChannel(BuildContext context) async {
    bmShowResponsiveSheet(
      context: context,
      backgroundColor: BMColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('📢🎁 ', style: TextStyle(fontSize: 24)),
                Expanded(
                  child: Text(
                    'کانال رسمی بادیمود (@bodymod_channel)',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'کدهای تخفیف اشتراک، اطلاعیه‌های مهم و نکات طلایی فقط توی کانال رسمی منتشر میشه رفیق! از کدوم پیام‌رسان می‌خوای وارد بشی؟ 👇',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.55),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BMColors.neonCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse(AppConfig.channelUrlBale);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text(
                  'باز کردن کانال در پیام‌رسان بله 🇮🇷',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: BMColors.neonCyan,
                  side: const BorderSide(color: BMColors.neonCyan),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse(AppConfig.channelUrlTelegram);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.telegram_rounded, size: 18),
                label: const Text(
                  'باز کردن در تلگرام (@bodymod_channel)',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    const ClipboardData(text: AppConfig.channelId),
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'آیدی کانال (@bodymod_channel) کپی شد رفیق! 📋✅',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 17),
                label: const Text('کپی کردن آیدی @bodymod_channel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openChannel(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F2942), Color(0xFF1E1B4B)],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BMColors.neonCyan, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: BMColors.neonCyan.withOpacity(0.14),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BMColors.neonCyan.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('📢', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'لینک کانال بادیمود',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14.5,
                              color: BMColors.neonCyan,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Text(
                            '@bodymod_channel',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'کدهای تخفیف فقط توی کانال منتشر میشه 🎁🔥',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: BMColors.neonCyan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 4. DATA MODELS & COMPREHENSIVE GRANULAR FOOD BANK (95+ ITEMS)
// ============================================================================

enum StreakVisualState {
  redFire, // 🔥 امروز ثبت شده و آتیش روشنه
  blueFrozen, // 💙 استریک قبلی هست اما امروز هنوز ثبت نشده (در خطر یخ‌زدگی)
  deadSkull, // 💀 استریک ۰ یا خاموش شده
}

class UserProfileModel {
  String userKey;
  String sessionToken;
  String email;
  String phone;
  String displayName;
  String photoUrl;
  int age;
  String gender; // 'male' | 'female'
  double heightCm;
  double weightKg;
  double targetWeightKg;
  String goal; // یکی از ۶ هدف دقیق
  String workoutDaysPerWeek; // 'none', 'd1' .. 'd7'
  String workoutPlace; // 'home_dumbbell', 'gym', 'bodyweight'
  String budgetTier; // 'base', 'mid', 'flagship', 'vip'
  String supplementPreference; // 'commercial', 'homemade'
  String preferredModel; // 'gemini-3.5-flash-lite' | 'gemini-3.8-flash'
  String aiCoachMemory;
  bool isLoggedIn;
  bool isProfileCompleted;
  bool hasActiveSubscription;
  String subscriptionTier;
  int subscriptionDaysRemaining;
  int subscriptionExpiresAt;
  int bodyCoinsBalance;
  int totalDonatedToman;
  int donationsCount;
  bool isAdmin; // فقط وقتی سرور کلودفلر تایید کنه مدیرعامل هستی true میشه!

  UserProfileModel({
    this.userKey = '',
    this.sessionToken = '',
    this.email = '',
    this.phone = '',
    this.displayName = '',
    this.photoUrl = '',
    this.age = 21,
    this.gender = 'male',
    this.heightCm = 175,
    this.weightKg = 70,
    this.targetWeightKg = 75,
    this.goal = 'gain_muscle',
    this.workoutDaysPerWeek = 'd3',
    this.workoutPlace = 'home_dumbbell',
    this.budgetTier = AppConfig.budgetBase,
    this.supplementPreference = 'commercial',
    this.preferredModel = 'gemini-3.5-flash-lite',
    this.aiCoachMemory = '',
    this.isLoggedIn = false,
    this.isProfileCompleted = false,
    this.hasActiveSubscription = false,
    this.subscriptionTier = 'بدون اشتراک',
    this.subscriptionDaysRemaining = 0,
    this.subscriptionExpiresAt = 0,
    this.bodyCoinsBalance = 0,
    this.totalDonatedToman = 0,
    this.donationsCount = 0,
    this.isAdmin = false,
  });

  double get bmi {
    if (heightCm <= 0) return 22.0;
    final hMeter = heightCm / 100.0;
    return weightKg / (hMeter * hMeter);
  }

  int get recommendedDailyCalories {
    double bmr =
        (10 * weightKg) +
        (6.25 * heightCm) -
        (5 * age) +
        (gender == 'male' ? 5 : -161);
    double multiplier = 1.45;
    switch (workoutDaysPerWeek) {
      case 'none':
        multiplier = 1.2;
        break;
      case 'd1':
      case 'd2':
        multiplier = 1.35;
        break;
      case 'd3':
      case 'd4':
        multiplier = 1.55;
        break;
      case 'd5':
      case 'd6':
        multiplier = 1.725;
        break;
      case 'd7':
        multiplier = 1.9;
        break;
    }
    double tdee = bmr * multiplier;
    switch (goal) {
      case 'loss_fat':
        return (tdee - 500).round().clamp(1200, 4200);
      case 'loss_muscle':
        return (tdee - 300).round().clamp(1350, 4300);
      case 'gain_bulk':
        return (tdee + 480).round().clamp(1600, 5000);
      case 'gain_muscle':
        return (tdee + 320).round().clamp(1600, 4800);
      case 'maintain_muscle':
      case 'maintain_health':
      default:
        return tdee.round().clamp(1400, 4500);
    }
  }

  Map<String, int> get recommendedMacros {
    final totalCal = recommendedDailyCalories;
    final bool muscleFocus = goal.contains('muscle');
    final int proteinGrams =
        (weightKg * (muscleFocus ? 2.1 : 1.7)).round().clamp(60, 260);
    final int fatGrams = ((totalCal * 0.26) / 9.0).round().clamp(35, 130);
    final int remainingCal = math.max(
      200,
      totalCal - (proteinGrams * 4) - (fatGrams * 9),
    );
    final int carbGrams = (remainingCal / 4.0).round();
    return {
      'calories': totalCal,
      'protein': proteinGrams,
      'carbs': carbGrams,
      'fat': fatGrams,
    };
  }

  // آیا کاربر مجاز به خرید یا تمدید اشتراک هست؟ (بدون اشتراک یا در روزهای ۲۸ تا ۳۱ یعنی <= ۳ روز باقی‌مانده)
  bool get canPurchaseOrRenewSubscription {
    if (isAdmin) return false;
    if (!hasActiveSubscription) return true;
    return subscriptionDaysRemaining <= 3;
  }

  Map<String, dynamic> toJson() => {
    'userKey': userKey,
    'sessionToken': sessionToken,
    'email': email,
    'phone': phone,
    'displayName': displayName,
    'name': displayName,
    'photoUrl': photoUrl,
    'age': age,
    'gender': gender,
    'heightCm': heightCm,
    'height': heightCm,
    'weightKg': weightKg,
    'weight': weightKg,
    'targetWeightKg': targetWeightKg,
    'goal': goal,
    'workoutDaysPerWeek': workoutDaysPerWeek,
    'workoutPlace': workoutPlace,
    'budgetTier': budgetTier,
    'economicStatus': budgetTier,
    'supplementPreference': supplementPreference,
    'preferredModel': preferredModel,
    'aiCoachMemory': aiCoachMemory,
    'isLoggedIn': isLoggedIn,
    'isProfileCompleted': isProfileCompleted,
    'hasActiveSubscription': hasActiveSubscription,
    'subscriptionTier': subscriptionTier,
    'subscriptionDaysRemaining': subscriptionDaysRemaining,
    'subscriptionExpiresAt': subscriptionExpiresAt,
    'bodyCoinsBalance': bodyCoinsBalance,
    'totalDonatedToman': totalDonatedToman,
    'donationsCount': donationsCount,
    'isAdmin': isAdmin,
  };

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userKey: (json['userKey'] ?? json['email'] ?? json['phone'] ?? '')
          .toString(),
      sessionToken: (json['sessionToken'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      displayName: (json['displayName'] ?? json['name'] ?? '').toString(),
      photoUrl: (json['photoUrl'] ?? json['picture'] ?? '').toString(),
      age: (json['age'] as num?)?.toInt() ?? 21,
      gender: (json['gender'] ?? 'male').toString(),
      heightCm:
          (json['heightCm'] as num?)?.toDouble() ??
          (json['height'] as num?)?.toDouble() ??
          175.0,
      weightKg:
          (json['weightKg'] as num?)?.toDouble() ??
          (json['weight'] as num?)?.toDouble() ??
          70.0,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 75.0,
      goal: (json['goal'] ?? 'gain_muscle').toString(),
      workoutDaysPerWeek: (json['workoutDaysPerWeek'] ?? 'd3').toString(),
      workoutPlace: (json['workoutPlace'] ?? 'home_dumbbell').toString(),
      budgetTier:
          (json['budgetTier'] ?? json['economicStatus'] ?? AppConfig.budgetBase)
              .toString(),
      supplementPreference: (json['supplementPreference'] ?? 'commercial')
          .toString(),
      preferredModel: (json['preferredModel'] ?? 'gemini-3.5-flash-lite')
          .toString(),
      aiCoachMemory: (json['aiCoachMemory'] ?? '').toString(),
      isLoggedIn: json['isLoggedIn'] == true,
      isProfileCompleted: json['isProfileCompleted'] == true,
      hasActiveSubscription: json['hasActiveSubscription'] == true,
      subscriptionTier: (json['subscriptionTier'] ?? 'بدون اشتراک').toString(),
      subscriptionDaysRemaining:
          (json['subscriptionDaysRemaining'] as num?)?.toInt() ?? 0,
      subscriptionExpiresAt:
          (json['subscriptionExpiresAt'] as num?)?.toInt() ?? 0,
      bodyCoinsBalance: (json['bodyCoinsBalance'] as num?)?.toInt() ?? 0,
      totalDonatedToman: (json['totalDonatedToman'] as num?)?.toInt() ?? 0,
      donationsCount: (json['donationsCount'] as num?)?.toInt() ?? 0,
      isAdmin: json['isAdmin'] == true,
    );
  }
}

class FoodLogItem {
  final String id;
  final String title;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final String timeLabel;
  final String emoji;

  FoodLogItem({
    required this.id,
    required this.title,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.timeLabel,
    this.emoji = '🍽️',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'calories': calories,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    'timeLabel': timeLabel,
    'emoji': emoji,
  };

  factory FoodLogItem.fromJson(Map<String, dynamic> json) => FoodLogItem(
    id: (json['id'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    calories: (json['calories'] as num?)?.toInt() ?? 0,
    proteinG: (json['proteinG'] as num?)?.toInt() ?? 0,
    carbsG: (json['carbsG'] as num?)?.toInt() ?? 0,
    fatG: (json['fatG'] as num?)?.toInt() ?? 0,
    timeLabel: (json['timeLabel'] ?? '').toString(),
    emoji: (json['emoji'] ?? '🍽️').toString(),
  );
}

// آیتم بانک جامع خوراکی‌ها بر پایه کوچک‌ترین واحد طبیعی
class FoodBankUnitItem {
  final String id;
  final String category;
  final String title;
  final String baseUnitName; // مثلاً: 'عدد'، 'قاشق غذاخوری'، 'قاشق مرباخوری'، 'کف دست'، 'لیوان'، 'پیاله'، 'کاسه'، 'بشقاب'، 'سیخ'، 'برش'
  final int caloriesPerUnit;
  final double proteinPerUnit;
  final double carbsPerUnit;
  final double fatPerUnit;
  final String emoji;
  final Map<String, double> alternateUnitsMultiplier;

  const FoodBankUnitItem({
    required this.id,
    required this.category,
    required this.title,
    required this.baseUnitName,
    required this.caloriesPerUnit,
    required this.proteinPerUnit,
    required this.carbsPerUnit,
    required this.fatPerUnit,
    required this.emoji,
    this.alternateUnitsMultiplier = const {},
  });
}

class ComprehensiveFoodBankCatalog {
  static const List<String> categories = [
    'همه 🌟',
    'غذاهای ایرانی و پلو 🍛',
    'پروتئین و بدنسازی 🥩',
    'نان و صبحانه 🍳',
    'میوه و سبزیجات 🍎',
    'آجیل و خشکبار 🥜',
    'تنقلات و دسر 🍫',
    'نوشیدنی و شیک ☕',
    'فست‌فود و ساندویچ 🍕',
  ];

  // بانک جامع خوراکی‌ها با کوچک‌ترین واحد ممکن + ضرایب تبدیل به واحدهای بزرگ‌تر
  static const List<FoodBankUnitItem> allItems = [
    // --- پروتئین و بدنسازی 🥩 ---
    FoodBankUnitItem(
      id: 'p_egg_whole',
      category: 'پروتئین و بدنسازی 🥩',
      title: 'تخم‌مرغ کامل (آب‌پز یا نیمرو کم‌روغن)',
      baseUnitName: 'عدد',
      caloriesPerUnit: 78,
      proteinPerUnit: 6.5,
      carbsPerUnit: 0.6,
      fatPerUnit: 5.3,
      emoji: '🥚',
      alternateUnitsMultiplier: {'عدد': 1.0, 'بشقاب (۳ عدد)': 3.0},
    ),
    FoodBankUnitItem(
      id: 'p_egg_white',
      category: 'پروتئین و بدنسازی 🥩',
      title: 'سفیده تخم‌مرغ خالص',
      baseUnitName: 'عدد',
      caloriesPerUnit: 17,
      proteinPerUnit: 3.6,
      carbsPerUnit: 0.2,
      fatPerUnit: 0.1,
      emoji: '🥚',
      alternateUnitsMultiplier: {'عدد': 1.0, 'لیوان (۶ سفیده)': 6.0},
    ),
    FoodBankUnitItem(
      id: 'p_chicken_breast',
      category: 'پروتئین و بدنسازی 🥩',
      title: 'سینه مرغ پخته یا گریل',
      baseUnitName: 'تکه (۳۰ گرم)',
      caloriesPerUnit: 50,
      proteinPerUnit: 9.3,
      carbsPerUnit: 0.0,
      fatPerUnit: 1.1,
      emoji: '🍗',
      alternateUnitsMultiplier: {
        'تکه (۳۰ گرم)': 1.0,
        'کف دست (۱۰۰ گرم)': 3.3,
        'پرس کامل (۲۰۰ گرم)': 6.6,
      },
    ),
    FoodBankUnitItem(
      id: 'p_chicken_thigh',
      category: 'پروتئین و بدنسازی 🥩',
      title: 'ران مرغ پخته (بدون پوست)',
      baseUnitName: 'تکه (۳۰ گرم)',
      caloriesPerUnit: 62,
      proteinPerUnit: 7.8,
      carbsPerUnit: 0.0,
      fatPerUnit: 3.2,
      emoji: '🍗',
      alternateUnitsMultiplier: {
        'تکه (۳۰ گرم)': 1.0,
        'عدد متوسط': 3.5,
        'پرس (۲ عدد)': 7.0,
      },
    ),
    FoodBankUnitItem(
      id: 'p_beef_lean',
      category: 'پروتئین و بدنسازی 🥩',
      title: 'گوشت قرمز لخم (گوساله یا گوسفندی کم‌چرب)',
      baseUnitName: 'تکه خورشتی (۲۵ گرم)',
      caloriesPerUnit: 60,
      proteinPerUnit: 6.8,
      carbsPerUnit: 0.0,
      fatPerUnit: 3.5,
      emoji: '🥩',
      alternateUnitsMultiplier: {
        'تکه خورشتی (۲۵ گرم)': 1.0,
        'کف دست (۱۰۰ گرم)': 4.0,
        'بشقاب استیک (۲۰۰ گرم)': 8.0,
      },
    ),
    FoodBankUnitItem(
      id: 'p_tuna',
      category: 'پروتئین و بدنسازی 🥩',
      title: 'تن ماهی (آب‌کش‌شده از روغن)',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 38,
      proteinPerUnit: 6.5,
      carbsPerUnit: 0.0,
      fatPerUnit: 1.3,
      emoji: '🐟',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'نصف قوطی': 3.0,
        'قوطی کامل': 6.0,
      },
    ),
    FoodBankUnitItem(
      id: 'p_fish_grilled',
      category: 'پروتئین و بدنسازی 🥩',
      title: 'ماهی کبابی یا بخارپز (سالمون / قزل‌آلا)',
      baseUnitName: 'تکه (۳۰ گرم)',
      caloriesPerUnit: 58,
      proteinPerUnit: 6.6,
      carbsPerUnit: 0.0,
      fatPerUnit: 3.3,
      emoji: '🐠',
      alternateUnitsMultiplier: {
        'تکه (۳۰ گرم)': 1.0,
        'کف دست (۱۰۰ گرم)': 3.3,
        'فیله کامل (۲۰۰ گرم)': 6.6,
      },
    ),
    FoodBankUnitItem(
      id: 'p_lentil_dish',
      category: 'پروتئین و بدنسازی 🥩',
      title: 'عدسی پخته',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 24,
      proteinPerUnit: 1.6,
      carbsPerUnit: 3.8,
      fatPerUnit: 0.3,
      emoji: '🥣',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'پیاله': 6.0,
        'کاسه کامل': 12.0,
      },
    ),
    FoodBankUnitItem(
      id: 'p_beans_cooked',
      category: 'پروتئین و بدنسازی 🥩',
      title: 'خوراک لوبیا چیتی (پخته)',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 28,
      proteinPerUnit: 1.7,
      carbsPerUnit: 4.5,
      fatPerUnit: 0.4,
      emoji: '🫘',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'پیاله': 6.0,
        'کاسه کامل': 12.0,
      },
    ),
    FoodBankUnitItem(
      id: 'p_chickpea',
      category: 'پروتئین و بدنسازی 🥩',
      title: 'نخود پخته (نخودآب / آبگوشتی)',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 27,
      proteinPerUnit: 1.5,
      carbsPerUnit: 4.4,
      fatPerUnit: 0.4,
      emoji: '🍲',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'پیاله': 6.0,
        'کاسه': 11.0,
      },
    ),
    FoodBankUnitItem(
      id: 'p_whey_scoop',
      category: 'پروتئین و بدنسازی 🥩',
      title: 'پودر پروتئین وی (Whey)',
      baseUnitName: 'قاشق غذاخوری (۱۰ گرم)',
      caloriesPerUnit: 40,
      proteinPerUnit: 8.0,
      carbsPerUnit: 1.0,
      fatPerUnit: 0.5,
      emoji: '💪',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری (۱۰ گرم)': 1.0,
        'اسکوپ کامل (۳۰ گرم)': 3.0,
      },
    ),
    FoodBankUnitItem(
      id: 'p_potato_boiled',
      category: 'پروتئین و بدنسازی 🥩',
      title: 'سیب‌زمینی آب‌پز یا تنوری',
      baseUnitName: 'عدد کوچک (۵۰ گرم)',
      caloriesPerUnit: 44,
      proteinPerUnit: 1.0,
      carbsPerUnit: 10.0,
      fatPerUnit: 0.1,
      emoji: '🥔',
      alternateUnitsMultiplier: {
        'عدد کوچک (۵۰ گرم)': 1.0,
        'عدد متوسط (۱۰۰ گرم)': 2.0,
        'عدد بزرگ (۱۸۰ گرم)': 3.6,
      },
    ),

    // --- غذاهای ایرانی و پلو 🍛 ---
    FoodBankUnitItem(
      id: 'ir_white_rice',
      category: 'غذاهای ایرانی و پلو 🍛',
      title: 'برنج سفید پخته (کته یا آبکش کم‌روغن)',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 32,
      proteinPerUnit: 0.6,
      carbsPerUnit: 6.8,
      fatPerUnit: 0.3,
      emoji: '🍚',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'کفگیر (۵ قاشق)': 5.0,
        'بشقاب متوسط (۸ قاشق)': 8.0,
        'پرس کامل (۱۲ قاشق)': 12.0,
      },
    ),
    FoodBankUnitItem(
      id: 'ir_adas_polo',
      category: 'غذاهای ایرانی و پلو 🍛',
      title: 'عدس‌پلو یا لوبیاپلو',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 38,
      proteinPerUnit: 1.3,
      carbsPerUnit: 6.5,
      fatPerUnit: 0.8,
      emoji: '🍛',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'کفگیر (۵ قاشق)': 5.0,
        'بشقاب (۸ قاشق)': 8.0,
        'پرس کامل (۱۲ قاشق)': 12.0,
      },
    ),
    FoodBankUnitItem(
      id: 'ir_zereshk_polo',
      category: 'غذاهای ایرانی و پلو 🍛',
      title: 'زرشک‌پلو یا باقالی‌پلو',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 36,
      proteinPerUnit: 0.8,
      carbsPerUnit: 6.9,
      fatPerUnit: 0.6,
      emoji: '🍚',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'کفگیر (۵ قاشق)': 5.0,
        'بشقاب (۸ قاشق)': 8.0,
      },
    ),
    FoodBankUnitItem(
      id: 'ir_makaroni',
      category: 'غذاهای ایرانی و پلو 🍛',
      title: 'ماکارونی و پاستا با سس گوشت یا سویا',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 42,
      proteinPerUnit: 1.8,
      carbsPerUnit: 6.2,
      fatPerUnit: 1.2,
      emoji: '🍝',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'پیاله': 5.0,
        'بشقاب (۸ قاشق)': 8.0,
      },
    ),
    FoodBankUnitItem(
      id: 'ir_kabab_koobideh',
      category: 'غذاهای ایرانی و پلو 🍛',
      title: 'کباب کوبیده',
      baseUnitName: 'تکه (یک‌چهارم سیخ)',
      caloriesPerUnit: 68,
      proteinPerUnit: 4.8,
      carbsPerUnit: 0.5,
      fatPerUnit: 5.2,
      emoji: '🍢',
      alternateUnitsMultiplier: {
        'تکه (یک‌چهارم سیخ)': 1.0,
        'نصف سیخ': 2.0,
        'سیخ کامل': 4.0,
      },
    ),
    FoodBankUnitItem(
      id: 'ir_joojeh_kabab',
      category: 'غذاهای ایرانی و پلو 🍛',
      title: 'جوجه‌کباب زعفرانی',
      baseUnitName: 'تکه (۱ جوجه روی سیخ)',
      caloriesPerUnit: 45,
      proteinPerUnit: 7.5,
      carbsPerUnit: 0.2,
      fatPerUnit: 1.5,
      emoji: '🍢',
      alternateUnitsMultiplier: {
        'تکه (۱ جوجه روی سیخ)': 1.0,
        'نصف سیخ (۳ تکه)': 3.0,
        'سیخ کامل (۶ تکه)': 6.0,
      },
    ),
    FoodBankUnitItem(
      id: 'ir_ghormeh_sabzi',
      category: 'غذاهای ایرانی و پلو 🍛',
      title: 'خورشت قورمه‌سبزی',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 35,
      proteinPerUnit: 1.8,
      carbsPerUnit: 1.6,
      fatPerUnit: 2.4,
      emoji: '🍲',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'پیاله (۵ قاشق)': 5.0,
        'کاسه خورشت (۸ قاشق)': 8.0,
      },
    ),
    FoodBankUnitItem(
      id: 'ir_gheymeh',
      category: 'غذاهای ایرانی و پلو 🍛',
      title: 'خورشت قیمه (با لپه و گوشت)',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 34,
      proteinPerUnit: 1.9,
      carbsPerUnit: 2.5,
      fatPerUnit: 1.8,
      emoji: '🍲',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'پیاله (۵ قاشق)': 5.0,
        'کاسه خورشت (۸ قاشق)': 8.0,
      },
    ),
    FoodBankUnitItem(
      id: 'ir_fesenjan',
      category: 'غذاهای ایرانی و پلو 🍛',
      title: 'خورشت فسنجان (گردو و رب انار)',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 58,
      proteinPerUnit: 2.2,
      carbsPerUnit: 2.8,
      fatPerUnit: 4.4,
      emoji: '🥘',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'پیاله (۴ قاشق)': 4.0,
        'کاسه (۷ قاشق)': 7.0,
      },
    ),
    FoodBankUnitItem(
      id: 'ir_abgoosht',
      category: 'غذاهای ایرانی و پلو 🍛',
      title: 'آبگوشت و دیزی (گوشت و نخود کوبیده)',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 40,
      proteinPerUnit: 2.6,
      carbsPerUnit: 2.8,
      fatPerUnit: 2.1,
      emoji: '🏺',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'پیاله': 6.0,
        'پرس کامل دیزی': 12.0,
      },
    ),
    FoodBankUnitItem(
      id: 'ir_ash_reshteh',
      category: 'غذاهای ایرانی و پلو 🍛',
      title: 'آش رشته یا آش دوغ',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 26,
      proteinPerUnit: 1.1,
      carbsPerUnit: 4.1,
      fatPerUnit: 0.6,
      emoji: '🍜',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'پیاله': 6.0,
        'کاسه کامل': 12.0,
      },
    ),
    FoodBankUnitItem(
      id: 'ir_kotlet_kuku',
      category: 'غذاهای ایرانی و پلو 🍛',
      title: 'کتلت گوشت یا کوکو سبزی / سیب‌زمینی',
      baseUnitName: 'عدد متوسط',
      caloriesPerUnit: 135,
      proteinPerUnit: 6.5,
      carbsPerUnit: 9.0,
      fatPerUnit: 8.2,
      emoji: '🧆',
      alternateUnitsMultiplier: {
        'نصف عدد': 0.5,
        'عدد متوسط': 1.0,
        'بشقاب (۳ عدد)': 3.0,
      },
    ),
    FoodBankUnitItem(
      id: 'ir_mirza_ghasemi',
      category: 'غذاهای ایرانی و پلو 🍛',
      title: 'میرزاقاسمی یا کشک بادمجان',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 38,
      proteinPerUnit: 1.5,
      carbsPerUnit: 2.6,
      fatPerUnit: 2.5,
      emoji: '🍆',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'پیاله': 5.0,
        'بشقاب کامل': 9.0,
      },
    ),

    // --- نان و صبحانه 🍳 ---
    FoodBankUnitItem(
      id: 'br_sangak',
      category: 'نان و صبحانه 🍳',
      title: 'نان سنگک سنتی',
      baseUnitName: 'کف دست',
      caloriesPerUnit: 75,
      proteinPerUnit: 2.6,
      carbsPerUnit: 15.0,
      fatPerUnit: 0.5,
      emoji: '🫓',
      alternateUnitsMultiplier: {
        'کف دست': 1.0,
        'برش بزرگ (۲ کف دست)': 2.0,
        'نصف نان سنگک': 5.0,
      },
    ),
    FoodBankUnitItem(
      id: 'br_barbari',
      category: 'نان و صبحانه 🍳',
      title: 'نان بربری',
      baseUnitName: 'کف دست',
      caloriesPerUnit: 82,
      proteinPerUnit: 2.5,
      carbsPerUnit: 16.5,
      fatPerUnit: 0.6,
      emoji: '🥖',
      alternateUnitsMultiplier: {'کف دست': 1.0, 'تکه بزرگ': 2.0},
    ),
    FoodBankUnitItem(
      id: 'br_lavash_taftoon',
      category: 'نان و صبحانه 🍳',
      title: 'نان لواش یا تافتون',
      baseUnitName: 'کف دست',
      caloriesPerUnit: 35,
      proteinPerUnit: 1.1,
      carbsPerUnit: 7.2,
      fatPerUnit: 0.2,
      emoji: '🫓',
      alternateUnitsMultiplier: {'کف دست': 1.0, 'نان کامل لواش': 4.0},
    ),
    FoodBankUnitItem(
      id: 'br_toast_bread',
      category: 'نان و صبحانه 🍳',
      title: 'نان تست (سبوس‌دار یا سفید)',
      baseUnitName: 'برش (۱ ورق)',
      caloriesPerUnit: 72,
      proteinPerUnit: 2.8,
      carbsPerUnit: 13.5,
      fatPerUnit: 0.9,
      emoji: '🍞',
      alternateUnitsMultiplier: {'برش (۱ ورق)': 1.0, 'جفت (۲ ورق)': 2.0},
    ),
    FoodBankUnitItem(
      id: 'br_white_cheese',
      category: 'نان و صبحانه 🍳',
      title: 'پنیر سفید ایرانی',
      baseUnitName: 'قوطی کبریت (۳۰ گرم)',
      caloriesPerUnit: 75,
      proteinPerUnit: 4.8,
      carbsPerUnit: 1.0,
      fatPerUnit: 5.8,
      emoji: '🧀',
      alternateUnitsMultiplier: {
        'قاشق مرباخوری (۱۰ گرم)': 0.35,
        'قوطی کبریت (۳۰ گرم)': 1.0,
      },
    ),
    FoodBankUnitItem(
      id: 'br_dushab_syrup',
      category: 'نان و صبحانه 🍳',
      title: 'شیره انگور (دوشاب) یا شیره خرما',
      baseUnitName: 'قاشق مرباخوری',
      caloriesPerUnit: 22,
      proteinPerUnit: 0.1,
      carbsPerUnit: 5.4,
      fatPerUnit: 0.0,
      emoji: '🍯',
      alternateUnitsMultiplier: {
        'قاشق مرباخوری': 1.0,
        'قاشق غذاخوری': 3.0,
        'پیاله کوچک': 9.0,
      },
    ),
    FoodBankUnitItem(
      id: 'br_ardeh',
      category: 'نان و صبحانه 🍳',
      title: 'ارده کنجد خالص',
      baseUnitName: 'قاشق مرباخوری',
      caloriesPerUnit: 32,
      proteinPerUnit: 0.9,
      carbsPerUnit: 1.1,
      fatPerUnit: 2.8,
      emoji: '🥣',
      alternateUnitsMultiplier: {
        'قاشق مرباخوری': 1.0,
        'قاشق غذاخوری': 3.0,
      },
    ),
    FoodBankUnitItem(
      id: 'br_honey_jam',
      category: 'نان و صبحانه 🍳',
      title: 'عسل طبیعی یا مربا',
      baseUnitName: 'قاشق مرباخوری',
      caloriesPerUnit: 21,
      proteinPerUnit: 0.0,
      carbsPerUnit: 5.6,
      fatPerUnit: 0.0,
      emoji: '🍯',
      alternateUnitsMultiplier: {
        'قاشق مرباخوری': 1.0,
        'قاشق غذاخوری': 3.0,
      },
    ),
    FoodBankUnitItem(
      id: 'br_peanut_butter',
      category: 'نان و صبحانه 🍳',
      title: 'کره بادام‌زمینی',
      baseUnitName: 'قاشق مرباخوری',
      caloriesPerUnit: 31,
      proteinPerUnit: 1.3,
      carbsPerUnit: 1.0,
      fatPerUnit: 2.6,
      emoji: '🥜',
      alternateUnitsMultiplier: {
        'قاشق مرباخوری': 1.0,
        'قاشق غذاخوری': 3.0,
      },
    ),
    FoodBankUnitItem(
      id: 'br_butter_cream',
      category: 'نان و صبحانه 🍳',
      title: 'کره حیوانی یا خامه صبحانه',
      baseUnitName: 'قاشق مرباخوری (۵ گرم)',
      caloriesPerUnit: 36,
      proteinPerUnit: 0.1,
      carbsPerUnit: 0.1,
      fatPerUnit: 4.0,
      emoji: '🧈',
      alternateUnitsMultiplier: {
        'قاشق مرباخوری (۵ گرم)': 1.0,
        'قاشق غذاخوری (۱۵ گرم)': 3.0,
      },
    ),
    FoodBankUnitItem(
      id: 'br_oats',
      category: 'نان و صبحانه 🍳',
      title: 'جو دوسر پرک (اوتمیل)',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 35,
      proteinPerUnit: 1.2,
      carbsPerUnit: 6.0,
      fatPerUnit: 0.6,
      emoji: '🌾',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'پیاله (۵ قاشق)': 5.0,
        'کاسه کامل (۸ قاشق)': 8.0,
      },
    ),
    FoodBankUnitItem(
      id: 'br_omelette',
      category: 'نان و صبحانه 🍳',
      title: 'املت گوجه (پخته‌شده)',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 34,
      proteinPerUnit: 1.9,
      carbsPerUnit: 1.2,
      fatPerUnit: 2.4,
      emoji: '🍳',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'نصف ماهیتابه': 5.0,
        'بشقاب کامل': 8.0,
      },
    ),
    FoodBankUnitItem(
      id: 'br_yogurt',
      category: 'نان و صبحانه 🍳',
      title: 'ماست کم‌چرب یا ماست یونانی',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 18,
      proteinPerUnit: 1.5,
      carbsPerUnit: 1.6,
      fatPerUnit: 0.5,
      emoji: '🥛',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'پیاله (۶ قاشق)': 6.0,
        'کاسه (۱۰ قاشق)': 10.0,
      },
    ),

    // --- میوه و سبزیجات 🍎 ---
    FoodBankUnitItem(
      id: 'fr_apple',
      category: 'میوه و سبزیجات 🍎',
      title: 'سیب درختی تازه',
      baseUnitName: 'عدد متوسط',
      caloriesPerUnit: 75,
      proteinPerUnit: 0.4,
      carbsPerUnit: 19.0,
      fatPerUnit: 0.2,
      emoji: '🍎',
      alternateUnitsMultiplier: {'برش (قاچ)': 0.2, 'نصف عدد': 0.5, 'عدد متوسط': 1.0},
    ),
    FoodBankUnitItem(
      id: 'fr_banana',
      category: 'میوه و سبزیجات 🍎',
      title: 'موز رسیده',
      baseUnitName: 'عدد متوسط',
      caloriesPerUnit: 105,
      proteinPerUnit: 1.3,
      carbsPerUnit: 27.0,
      fatPerUnit: 0.4,
      emoji: '🍌',
      alternateUnitsMultiplier: {'نصف عدد': 0.5, 'عدد متوسط': 1.0},
    ),
    FoodBankUnitItem(
      id: 'fr_date',
      category: 'میوه و سبزیجات 🍎',
      title: 'خرما (مضافتی یا پیارم)',
      baseUnitName: 'عدد (۱ دانه)',
      caloriesPerUnit: 23,
      proteinPerUnit: 0.2,
      carbsPerUnit: 6.0,
      fatPerUnit: 0.0,
      emoji: '🌴',
      alternateUnitsMultiplier: {'عدد (۱ دانه)': 1.0, '۳ عدد': 3.0, '۵ عدد': 5.0},
    ),
    FoodBankUnitItem(
      id: 'fr_orange_tangerine',
      category: 'میوه و سبزیجات 🍎',
      title: 'پرتقال یا نارنگی',
      baseUnitName: 'عدد متوسط',
      caloriesPerUnit: 60,
      proteinPerUnit: 1.0,
      carbsPerUnit: 15.0,
      fatPerUnit: 0.2,
      emoji: '🍊',
      alternateUnitsMultiplier: {'نصف عدد': 0.5, 'عدد متوسط': 1.0},
    ),
    FoodBankUnitItem(
      id: 'fr_grapes',
      category: 'میوه و سبزیجات 🍎',
      title: 'انگور شیرین',
      baseUnitName: 'حبه (۱ دانه)',
      caloriesPerUnit: 3,
      proteinPerUnit: 0.0,
      carbsPerUnit: 0.8,
      fatPerUnit: 0.0,
      emoji: '🍇',
      alternateUnitsMultiplier: {
        'حبه (۱ دانه)': 1.0,
        'پیاله (۲۰ حبه)': 20.0,
        'خوشه متوسط (۴۰ حبه)': 40.0,
      },
    ),
    FoodBankUnitItem(
      id: 'fr_watermelon_melon',
      category: 'میوه و سبزیجات 🍎',
      title: 'هندوانه یا خربزه / طالبی',
      baseUnitName: 'برش (قاچ متوسط)',
      caloriesPerUnit: 45,
      proteinPerUnit: 0.9,
      carbsPerUnit: 11.0,
      fatPerUnit: 0.2,
      emoji: '🍉',
      alternateUnitsMultiplier: {
        'برش (قاچ متوسط)': 1.0,
        'کاسه خردشده': 2.0,
      },
    ),
    FoodBankUnitItem(
      id: 'fr_cucumber_tomato',
      category: 'میوه و سبزیجات 🍎',
      title: 'خیار، گوجه یا سالاد فصل (بدون سس چرب)',
      baseUnitName: 'عدد متوسط',
      caloriesPerUnit: 18,
      proteinPerUnit: 0.8,
      carbsPerUnit: 3.8,
      fatPerUnit: 0.1,
      emoji: '🥗',
      alternateUnitsMultiplier: {
        'عدد متوسط': 1.0,
        'پیاله سالاد': 2.0,
        'بشقاب سالاد': 4.0,
      },
    ),

    // --- آجیل و خشکبار 🥜 ---
    FoodBankUnitItem(
      id: 'nt_walnut',
      category: 'آجیل و خشکبار 🥜',
      title: 'گردو (مغز گردوی کامل)',
      baseUnitName: 'عدد کامل',
      caloriesPerUnit: 26,
      proteinPerUnit: 0.6,
      carbsPerUnit: 0.5,
      fatPerUnit: 2.6,
      emoji: '🌰',
      alternateUnitsMultiplier: {
        'نصف گردو': 0.5,
        'عدد کامل': 1.0,
        'مشت کوچک (۵ عدد)': 5.0,
      },
    ),
    FoodBankUnitItem(
      id: 'nt_almond_pistachio',
      category: 'آجیل و خشکبار 🥜',
      title: 'بادام درختی، پسته یا فندق',
      baseUnitName: 'عدد (۱ دانه)',
      caloriesPerUnit: 7,
      proteinPerUnit: 0.3,
      carbsPerUnit: 0.3,
      fatPerUnit: 0.6,
      emoji: '🥜',
      alternateUnitsMultiplier: {
        'عدد (۱ دانه)': 1.0,
        'قاشق غذاخوری (۱۰ عدد)': 10.0,
        'مشت (۲۰ عدد)': 20.0,
      },
    ),
    FoodBankUnitItem(
      id: 'nt_raisins',
      category: 'آجیل و خشکبار 🥜',
      title: 'کشمش یا مویز',
      baseUnitName: 'قاشق مرباخوری',
      caloriesPerUnit: 15,
      proteinPerUnit: 0.1,
      carbsPerUnit: 3.8,
      fatPerUnit: 0.0,
      emoji: '🍇',
      alternateUnitsMultiplier: {
        'قاشق مرباخوری': 1.0,
        'قاشق غذاخوری': 3.0,
        'مشت': 6.0,
      },
    ),
    FoodBankUnitItem(
      id: 'nt_sunflower_seeds',
      category: 'آجیل و خشکبار 🥜',
      title: 'تخمه آفتابگردان، کدو یا ژاپنی',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 45,
      proteinPerUnit: 1.8,
      carbsPerUnit: 1.6,
      fatPerUnit: 3.9,
      emoji: '🌻',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'مشت': 2.5,
        'پیاله': 5.0,
      },
    ),

    // --- تنقلات و دسر 🍫 ---
    FoodBankUnitItem(
      id: 'sn_sugar_cube',
      category: 'تنقلات و دسر 🍫',
      title: 'قند یا شکر یا نبات',
      baseUnitName: 'حبه قند / قاشق مرباخوری',
      caloriesPerUnit: 12,
      proteinPerUnit: 0.0,
      carbsPerUnit: 3.0,
      fatPerUnit: 0.0,
      emoji: '🍬',
      alternateUnitsMultiplier: {
        'حبه قند / قاشق مرباخوری': 1.0,
        'قاشق غذاخوری شکر': 3.0,
      },
    ),
    FoodBankUnitItem(
      id: 'sn_chocolate',
      category: 'تنقلات و دسر 🍫',
      title: 'شکلات تلخ یا شیری',
      baseUnitName: 'تکه مربعی (۱ خانه)',
      caloriesPerUnit: 32,
      proteinPerUnit: 0.5,
      carbsPerUnit: 3.2,
      fatPerUnit: 2.0,
      emoji: '🍫',
      alternateUnitsMultiplier: {
        'تکه مربعی (۱ خانه)': 1.0,
        'نوار کوچک (۳ خانه)': 3.0,
      },
    ),
    FoodBankUnitItem(
      id: 'sn_biscuit_cake',
      category: 'تنقلات و دسر 🍫',
      title: 'بیسکوئیت ساقه‌طلایی، پتی‌بور یا کیک و کلوچه',
      baseUnitName: 'عدد (۱ دانه بیسکوئیت)',
      caloriesPerUnit: 52,
      proteinPerUnit: 0.9,
      carbsPerUnit: 8.5,
      fatPerUnit: 1.8,
      emoji: '🍪',
      alternateUnitsMultiplier: {
        'عدد (۱ دانه بیسکوئیت)': 1.0,
        'بسته کیک / کلوچه': 4.5,
      },
    ),
    FoodBankUnitItem(
      id: 'sn_chips_pofak',
      category: 'تنقلات و دسر 🍫',
      title: 'چیپس سیب‌زمینی یا پفک',
      baseUnitName: 'مشت کوچک (۱۰ برگ)',
      caloriesPerUnit: 80,
      proteinPerUnit: 1.0,
      carbsPerUnit: 8.0,
      fatPerUnit: 5.2,
      emoji: '🍟',
      alternateUnitsMultiplier: {
        'مشت کوچک (۱۰ برگ)': 1.0,
        'کاسه متوسط': 3.0,
        'بسته کامل': 6.0,
      },
    ),
    FoodBankUnitItem(
      id: 'sn_ice_cream',
      category: 'تنقلات و دسر 🍫',
      title: 'بستنی سنتی، قیفی یا لیوانی',
      baseUnitName: 'اسکوپ / قاشق بزرگ',
      caloriesPerUnit: 75,
      proteinPerUnit: 1.5,
      carbsPerUnit: 9.5,
      fatPerUnit: 3.8,
      emoji: '🍨',
      alternateUnitsMultiplier: {
        'اسکوپ / قاشق بزرگ': 1.0,
        'بستنی کامل': 3.0,
      },
    ),
    FoodBankUnitItem(
      id: 'sn_sholezard_ferni',
      category: 'تنقلات و دسر 🍫',
      title: 'شله‌زرد، شیربرنج، فرنی یا حلوا',
      baseUnitName: 'قاشق غذاخوری',
      caloriesPerUnit: 38,
      proteinPerUnit: 0.6,
      carbsPerUnit: 6.8,
      fatPerUnit: 1.0,
      emoji: '🍮',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری': 1.0,
        'پیاله (۵ قاشق)': 5.0,
        'کاسه (۸ قاشق)': 8.0,
      },
    ),

    // --- نوشیدنی و شیک ☕ ---
    FoodBankUnitItem(
      id: 'dr_milk',
      category: 'نوشیدنی و شیک ☕',
      title: 'شیر کم‌چرب یا معمولی',
      baseUnitName: 'لیوان',
      caloriesPerUnit: 115,
      proteinPerUnit: 8.0,
      carbsPerUnit: 12.0,
      fatPerUnit: 3.8,
      emoji: '🥛',
      alternateUnitsMultiplier: {
        'نصف لیوان (استکان)': 0.5,
        'لیوان': 1.0,
      },
    ),
    FoodBankUnitItem(
      id: 'dr_doogh',
      category: 'نوشیدنی و شیک ☕',
      title: 'دوغ سنتی یا کفیر',
      baseUnitName: 'لیوان',
      caloriesPerUnit: 55,
      proteinPerUnit: 3.2,
      carbsPerUnit: 4.5,
      fatPerUnit: 2.2,
      emoji: '🥛',
      alternateUnitsMultiplier: {'نصف لیوان': 0.5, 'لیوان': 1.0, 'بطری کوچک': 1.5},
    ),
    FoodBankUnitItem(
      id: 'dr_tea_coffee',
      category: 'نوشیدنی و شیک ☕',
      title: 'چای، قهوه اسپرسو یا چای سبز (بدون شکر)',
      baseUnitName: 'فنجان / استکان',
      caloriesPerUnit: 2,
      proteinPerUnit: 0.1,
      carbsPerUnit: 0.3,
      fatPerUnit: 0.0,
      emoji: '☕',
      alternateUnitsMultiplier: {'فنجان / استکان': 1.0, 'لیوان بزرگ (ماگ)': 2.0},
    ),
    FoodBankUnitItem(
      id: 'dr_juice_soda',
      category: 'نوشیدنی و شیک ☕',
      title: 'آبمیوه طبیعی یا نوشابه و دلستر',
      baseUnitName: 'لیوان',
      caloriesPerUnit: 110,
      proteinPerUnit: 0.5,
      carbsPerUnit: 27.0,
      fatPerUnit: 0.0,
      emoji: '🧃',
      alternateUnitsMultiplier: {'نصف لیوان': 0.5, 'لیوان': 1.0, 'قوطی کامل': 1.4},
    ),
    FoodBankUnitItem(
      id: 'dr_protein_majoon',
      category: 'نوشیدنی و شیک ☕',
      title: 'شیک پروتئین و معجون خانگی (شیر، موز، گردو و دوشاب)',
      baseUnitName: 'لیوان',
      caloriesPerUnit: 310,
      proteinPerUnit: 14.0,
      carbsPerUnit: 42.0,
      fatPerUnit: 9.5,
      emoji: '🥤',
      alternateUnitsMultiplier: {'نصف لیوان': 0.5, 'لیوان': 1.0},
    ),

    // --- فست‌فود و ساندویچ 🍕 ---
    FoodBankUnitItem(
      id: 'ff_pizza_slice',
      category: 'فست‌فود و ساندویچ 🍕',
      title: 'پیتزا (مخلوط، پپرونی یا مرغ و قارچ)',
      baseUnitName: 'برش (۱ اسلایس مثلثی)',
      caloriesPerUnit: 195,
      proteinPerUnit: 9.0,
      carbsPerUnit: 21.0,
      fatPerUnit: 8.5,
      emoji: '🍕',
      alternateUnitsMultiplier: {
        'برش (۱ اسلایس مثلثی)': 1.0,
        'نصف پیتزا (۴ برش)': 4.0,
        'پیتزای کامل (۸ برش)': 8.0,
      },
    ),
    FoodBankUnitItem(
      id: 'ff_falafel',
      category: 'فست‌فود و ساندویچ 🍕',
      title: 'قرص فلافل یا سمبوسه',
      baseUnitName: 'عدد (۱ قرص فلافل)',
      caloriesPerUnit: 62,
      proteinPerUnit: 2.4,
      carbsPerUnit: 6.5,
      fatPerUnit: 3.1,
      emoji: '🧆',
      alternateUnitsMultiplier: {
        'عدد (۱ قرص فلافل)': 1.0,
        'ساندویچ کامل فلافل (۵ قرص + نان)': 6.5,
      },
    ),
    FoodBankUnitItem(
      id: 'ff_burger_sandwich',
      category: 'فست‌فود و ساندویچ 🍕',
      title: 'همبرگر، ساندویچ بندری یا هات‌داگ',
      baseUnitName: 'نصف ساندویچ',
      caloriesPerUnit: 280,
      proteinPerUnit: 13.0,
      carbsPerUnit: 26.0,
      fatPerUnit: 13.5,
      emoji: '🍔',
      alternateUnitsMultiplier: {
        'نصف ساندویچ': 1.0,
        'ساندویچ کامل': 2.0,
      },
    ),
    FoodBankUnitItem(
      id: 'ff_french_fries',
      category: 'فست‌فود و ساندویچ 🍕',
      title: 'سیب‌زمینی سرخ‌کرده',
      baseUnitName: 'قاشق غذاخوری / ۱۰ خلال',
      caloriesPerUnit: 55,
      proteinPerUnit: 0.7,
      carbsPerUnit: 6.5,
      fatPerUnit: 3.0,
      emoji: '🍟',
      alternateUnitsMultiplier: {
        'قاشق غذاخوری / ۱۰ خلال': 1.0,
        'پیش‌دستی کوچک': 3.5,
        'پرس کامل': 7.0,
      },
    ),
    FoodBankUnitItem(
      id: 'ff_oil_sauce',
      category: 'فست‌فود و ساندویچ 🍕',
      title: 'روغن مایع، روغن زیتون یا سس مایونز',
      baseUnitName: 'قاشق مرباخوری',
      caloriesPerUnit: 40,
      proteinPerUnit: 0.0,
      carbsPerUnit: 0.1,
      fatPerUnit: 4.5,
      emoji: '🫒',
      alternateUnitsMultiplier: {
        'قاشق مرباخوری': 1.0,
        'قاشق غذاخوری': 3.0,
      },
    ),
  ];
}

class MealPlanSlot {
  final String mealType;
  final String title;
  final String ingredientsTip;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final String emoji;
  bool isEatenToday;

  MealPlanSlot({
    required this.mealType,
    required this.title,
    required this.ingredientsTip,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.emoji = '🍲',
    this.isEatenToday = false,
  });

  Map<String, dynamic> toJson() => {
    'mealType': mealType,
    'title': title,
    'ingredientsTip': ingredientsTip,
    'calories': calories,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    'emoji': emoji,
    'isEatenToday': isEatenToday,
  };

  factory MealPlanSlot.fromJson(Map<String, dynamic> json) => MealPlanSlot(
    mealType: (json['mealType'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    ingredientsTip: (json['ingredientsTip'] ?? '').toString(),
    calories: (json['calories'] as num?)?.toInt() ?? 0,
    proteinG: (json['proteinG'] as num?)?.toInt() ?? 0,
    carbsG: (json['carbsG'] as num?)?.toInt() ?? 0,
    fatG: (json['fatG'] as num?)?.toInt() ?? 0,
    emoji: (json['emoji'] ?? '🍲').toString(),
    isEatenToday: json['isEatenToday'] == true,
  );
}

class WorkoutExerciseStep {
  final String phase; // 'warmup' | 'main' | 'cooldown'
  final String phaseTitle;
  final String name;
  final int sets;
  final String repsOrDuration;
  final int targetRestSeconds;
  final String breathingGuide;
  final String coachNote;
  final String muscleGroup;

  WorkoutExerciseStep({
    required this.phase,
    required this.phaseTitle,
    required this.name,
    required this.sets,
    required this.repsOrDuration,
    required this.targetRestSeconds,
    required this.breathingGuide,
    required this.coachNote,
    required this.muscleGroup,
  });

  Map<String, dynamic> toJson() => {
    'phase': phase,
    'phaseTitle': phaseTitle,
    'name': name,
    'sets': sets,
    'repsOrDuration': repsOrDuration,
    'targetRestSeconds': targetRestSeconds,
    'breathingGuide': breathingGuide,
    'coachNote': coachNote,
    'muscleGroup': muscleGroup,
  };

  factory WorkoutExerciseStep.fromJson(Map<String, dynamic> json) =>
      WorkoutExerciseStep(
        phase: (json['phase'] ?? 'main').toString(),
        phaseTitle: (json['phaseTitle'] ?? 'ست‌های اصلی 💪').toString(),
        name: (json['name'] ?? '').toString(),
        sets: (json['sets'] as num?)?.toInt() ?? 3,
        repsOrDuration: (json['repsOrDuration'] ?? '۱۲ تکرار').toString(),
        targetRestSeconds: (json['targetRestSeconds'] as num?)?.toInt() ?? 60,
        breathingGuide:
            (json['breathingGuide'] ??
                    'دم در بخش منفی حرکت، بازدم عمیق موقع فشار 🌬️')
                .toString(),
        coachNote: (json['coachNote'] ?? '').toString(),
        muscleGroup: (json['muscleGroup'] ?? 'کل بدن').toString(),
      );
}

class BodyLogRecord {
  final String dateLabel;
  final double weightKg;
  final double bmi;
  final String note;

  BodyLogRecord({
    required this.dateLabel,
    required this.weightKg,
    required this.bmi,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
    'dateLabel': dateLabel,
    'weightKg': weightKg,
    'bmi': bmi,
    'note': note,
  };

  factory BodyLogRecord.fromJson(Map<String, dynamic> json) => BodyLogRecord(
    dateLabel: (json['dateLabel'] ?? '').toString(),
    weightKg: (json['weightKg'] as num?)?.toDouble() ?? 70.0,
    bmi: (json['bmi'] as num?)?.toDouble() ?? 22.0,
    note: (json['note'] ?? '').toString(),
  );
}

class ChatMessageModel {
  final String id;
  final bool isUser;
  final String text;
  final String timeLabel;
  final int estimatedTokens;
  final int estimatedCoins;

  ChatMessageModel({
    required this.id,
    required this.isUser,
    required this.text,
    required this.timeLabel,
    this.estimatedTokens = 0,
    this.estimatedCoins = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'isUser': isUser,
    'text': text,
    'timeLabel': timeLabel,
    'estimatedTokens': estimatedTokens,
    'estimatedCoins': estimatedCoins,
  };

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: (json['id'] ?? '').toString(),
        isUser: json['isUser'] == true,
        text: (json['text'] ?? '').toString(),
        timeLabel: (json['timeLabel'] ?? '').toString(),
        estimatedTokens: (json['estimatedTokens'] as num?)?.toInt() ?? 0,
        estimatedCoins: (json['estimatedCoins'] as num?)?.toInt() ?? 0,
      );
}

// ============================================================================
// 5. OFFLINE EARTH BURN EASTER EGG DIALOG (PURE BLACK #000000)
// ============================================================================

Future<void> showEarthBurnOfflineDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.92),
    builder: (ctx) => const EarthBurnOfflineDialog(),
  );
}

class EarthBurnOfflineDialog extends StatefulWidget {
  const EarthBurnOfflineDialog({super.key});

  @override
  State<EarthBurnOfflineDialog> createState() => _EarthBurnOfflineDialogState();
}

class _EarthBurnOfflineDialogState extends State<EarthBurnOfflineDialog>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _initEarthBurnVideo();
  }

  Future<void> _initEarthBurnVideo() async {
    for (final assetPath in ['assets/earth_burn.mp4', 'earth_burn.mp4']) {
      try {
        final controller = VideoPlayerController.asset(assetPath);
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(1.0);
        await controller.play();
        if (mounted) {
          setState(() {
            _videoController = controller;
            _videoReady = true;
          });
        }
        return;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.black,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: const BorderSide(color: Color(0xFF331100), width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(26),
        ),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 210,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: _videoReady && _videoController != null
                  ? Center(
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  : const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFFFF5722),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            const Text(
              'کره زمین نابود شد! ☄️🌍🔥',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFF6B35),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'عزیز من چون دسترسی به کره زمین (اینترنت) نداری، کل کره زمین نابود شد! 😂🤦‍♂️\n\n'
              'بخش‌های آفلاین مثل ثبت کالری، لیوان آب، بانک خوراکی‌ها و پلیر باشگاه رو می‌تونی همین الان بدون نت استفاده کنی؛ ولی برای هوش مصنوعی اول نتت رو وصل کن تا زمین رو نجات بدیم! 🚀✨',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 14,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.public_off_rounded),
                label: const Text(
                  'حله رفیق، الان نتم رو وصل می‌کنم! 😂🔥',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 6. PRODUCTION CONTROLLER (ZERO DEMO DATA, 2-STEP AUTH, CLOUDFLARE KV & IAP)
// ============================================================================

class BodyModController extends ChangeNotifier {
  SharedPreferences? _prefs;

  bool isDarkMode = true;
  bool isLoadingAi = false;
  bool hasRequestedNotificationPerm = false;

  UserProfileModel profile = UserProfileModel();

  // بدون هیچ دیتای تستی در شروع! همه از صفر واقعی شروع می‌شوند
  int streakCount = 0;
  String lastCompletedStreakDate = '';
  int todayWaterGlasses = 0;
  int targetWaterGlasses = 8;
  List<FoodLogItem> todayFoodLogs = [];
  List<FoodBankUnitItem> customUserFoods = [];

  // برنامه غذایی ۷ روزه از پیش نوشته نمی‌شود! فقط بعد از باز شدن قفل ۳ مرحله‌ای توسط هوش مصنوعی ساخته می‌شود
  static const List<String> weekDays = [
    'شنبه',
    'یکشنبه',
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
  ];
  int selectedDayIndex = 0;
  Map<String, List<MealPlanSlot>> weeklyMealPlan = {};

  // مراحل پلیر باشگاه
  List<WorkoutExerciseStep> workoutSteps = [];

  // تاریخچه لاگ بدن (بدون دیتای تستی)
  List<BodyLogRecord> bodyLogsHistory = [];

  // پیام‌های چت مربی
  List<ChatMessageModel> chatMessages = [];

  // کوتاهای زنده سرور کلودفلر
  int remainingLiteChatQuota = 6;
  int maxLiteChatQuota = 6;
  int remainingFlashChatQuota = 3;
  int maxFlashChatQuota = 3;

  // کد تخفیف اعمال‌شده از کانال @bodymod_channel
  String appliedDiscountCode = '';
  int appliedDiscountPercent = 0;
  int discountedSubscriptionPriceToman = AppConfig.monthlySubscriptionPriceToman;

  // آمار زنده پنل محرمانه مدیرعامل (فقط وقتی profile.isAdmin == true باشد از سرور گرفته می‌شود)
  int adminTotalUsers = 0;
  int adminActiveSubscribers = 0;
  int adminTodayAiRequests = 0;
  int adminTotalDonationsToman = 0;
  int adminDonationsCount = 0;
  int adminTierBaseCount = 0;
  int adminTierMidCount = 0;
  int adminTierFlagshipCount = 0;
  int adminTierVipWhalesCount = 0;
  List<Map<String, dynamic>> adminUsersDirectory = [];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
  );

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromLocalStorage();
    _ensureWorkoutStepsReady();
    if (profile.isLoggedIn && profile.userKey.isNotEmpty) {
      unawaited(refreshProfileFromCloudflare());
    }
  }

  void _loadFromLocalStorage() {
    final prefs = _prefs;
    if (prefs == null) return;

    isDarkMode = prefs.getBool('bm_dark_mode') ?? true;
    hasRequestedNotificationPerm =
        prefs.getBool('bm_notif_perm_asked') ?? false;
    AppConfig.useBodyCoinSystem =
        prefs.getBool('bm_use_bodycoin_system') ?? false;

    final rawProfile = prefs.getString('bm_user_profile_v82');
    if (rawProfile != null && rawProfile.isNotEmpty) {
      try {
        profile = UserProfileModel.fromJson(
          jsonDecode(rawProfile) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    streakCount = prefs.getInt('bm_streak_count_v82') ?? 0;
    lastCompletedStreakDate = prefs.getString('bm_last_streak_date_v82') ?? '';
    todayWaterGlasses = prefs.getInt('bm_today_water_v82') ?? 0;
    targetWaterGlasses = prefs.getInt('bm_target_water_v82') ?? 8;

    final rawFoodLogs = prefs.getString('bm_today_food_logs_v82');
    if (rawFoodLogs != null && rawFoodLogs.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawFoodLogs) as List<dynamic>;
        todayFoodLogs = decoded
            .map((e) => FoodLogItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    final rawWeeklyPlan = prefs.getString('bm_weekly_meal_plan_v82');
    if (rawWeeklyPlan != null && rawWeeklyPlan.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawWeeklyPlan) as Map<String, dynamic>;
        weeklyMealPlan = decoded.map((day, list) {
          final items = (list as List<dynamic>)
              .map((e) => MealPlanSlot.fromJson(e as Map<String, dynamic>))
              .toList();
          return MapEntry(day, items);
        });
      } catch (_) {}
    }

    final rawBodyLogs = prefs.getString('bm_body_logs_v82');
    if (rawBodyLogs != null && rawBodyLogs.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBodyLogs) as List<dynamic>;
        bodyLogsHistory = decoded
            .map((e) => BodyLogRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    final rawChats = prefs.getString('bm_chat_messages_v82');
    if (rawChats != null && rawChats.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawChats) as List<dynamic>;
        chatMessages = decoded
            .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    if (chatMessages.isEmpty) {
      chatMessages = [
        ChatMessageModel(
          id: 'welcome_ai',
          isUser: false,
          text:
              'سلام قهرمان! 👋🔥 من مربی هوشمند اختصاصی تو توی BodyMod هستم.\n'
              'هر سوالی درباره تغذیه، جایگزینی غذاها، مکمل‌ها یا تکنیک حرکات داری بپرس!\n\n'
              '💡 راستی: اگه دکمه ارسال (🚀) رو نگه داری (Long Press)، قبل از فرستادن بهت نشون میدم پیامت چقدر توکن و بادی‌کوین مصرف می‌کنه! 🪙😎',
          timeLabel: 'الان',
        ),
      ];
    }
  }

  void _ensureWorkoutStepsReady() {
    if (workoutSteps.isNotEmpty) return;
    final isHome = profile.workoutPlace != 'gym';
    workoutSteps = [
      WorkoutExerciseStep(
        phase: 'warmup',
        phaseTitle: 'فاز ۱: گرم کردن و فعال‌سازی مفاصل 🔥',
        name: 'چرخش مفاصل شانه، کمر و پروانه (Jumping Jacks)',
        sets: 2,
        repsOrDuration: '۹۰ ثانیه پیوسته',
        targetRestSeconds: 30,
        breathingGuide: 'دم عمیق از بینی، بازدم آرام از دهان 🌬️',
        coachNote:
            'هرگز با بدن سرد زیر وزنه نرو رفیق! مایع مفصلی باید گرم بشه تا آسیب نبینی.',
        muscleGroup: 'کل بدن و قلب و عروق',
      ),
      WorkoutExerciseStep(
        phase: 'warmup',
        phaseTitle: 'فاز ۱: گرم کردن و فعال‌سازی مفاصل 🔥',
        name: 'شنا سوئدی کنترل‌شده یا پلانک فعال',
        sets: 2,
        repsOrDuration: '۱۲ تکرار آرام',
        targetRestSeconds: 35,
        breathingGuide: 'پایین رفتن: دم | بالا آمدن: بازدم 🌬️',
        coachNote: 'شکمت رو منقبض نگه دار و اجازه نده گودی کمرت بیفته پایین.',
        muscleGroup: 'سینه، سرشانه و میان‌تنه',
      ),
      WorkoutExerciseStep(
        phase: 'main',
        phaseTitle: 'فاز ۲: ست‌های اصلی عضله‌سازی 💪',
        name: isHome
            ? 'پرس سینه یا سرشانه با دمبل (کنترل ۳ ثانیه‌ای)'
            : 'پرس سینه هالتر دست متوسط',
        sets: 4,
        repsOrDuration: '۱۰ تا ۱۲ تکرار',
        targetRestSeconds: 60,
        breathingGuide: 'پایین آوردن وزنه (۳ ثانیه): دم | پرس به بالا: بازدم قوی 💥',
        coachNote:
            'توی بالاترین نقطه ۱ ثانیه سینه و سرشانه رو منقبض کن! استراحت بین ۲۰ تا ۹۰ ثانیه طلاییه.',
        muscleGroup: 'سینه و سرشانه قدامی',
      ),
      WorkoutExerciseStep(
        phase: 'main',
        phaseTitle: 'فاز ۲: ست‌های اصلی عضله‌سازی 💪',
        name: isHome
            ? 'زیربغل دمبل تک‌خم (اره دمبل) برای پهنای پشت'
            : 'زیربغل سیم‌کش دست باز از جلو',
        sets: 4,
        repsOrDuration: '۱۲ تکرار هر دست',
        targetRestSeconds: 60,
        breathingGuide: 'کشیدن وزنه به سمت شکم: بازدم | باز کردن دست: دم 🌬️',
        coachNote:
            'با آرنجت وزنه رو بکش بالا نه با ساعدت؛ حس کن عضلات پشتت کامل جمع میشن!',
        muscleGroup: 'زیربغل و عضلات پشت',
      ),
      WorkoutExerciseStep(
        phase: 'main',
        phaseTitle: 'فاز ۲: ست‌های اصلی عضله‌سازی 💪',
        name: isHome
            ? 'اسکات بلغاری یا گابلت اسکات با دمبل'
            : 'اسکات پا هالتر یا پرس پا دستگاه',
        sets: 4,
        repsOrDuration: '۱۲ تا ۱۵ تکرار',
        targetRestSeconds: 75,
        breathingGuide: 'نشستن به پایین: دم عمیق | بلند شدن از پاشنه: بازدم 🦵',
        coachNote:
            'تمرین پا ترشح تستوسترون و چربی‌سوزی کل بدنت رو ۲ برابر می‌کنه!',
        muscleGroup: 'چهارسر ران و سرینی',
      ),
      WorkoutExerciseStep(
        phase: 'main',
        phaseTitle: 'فاز ۲: ست‌های اصلی عضله‌سازی 💪',
        name: 'جلوبازو دمبل تناوبی چرخشی + پشت‌بازو دیپ',
        sets: 3,
        repsOrDuration: '۱۲ تکرار سوپرست',
        targetRestSeconds: 50,
        breathingGuide: 'انقباض بازو: بازدم | پایین بردن آرام: دم 💪',
        coachNote:
            'آرنجت رو کنار پهلو قفل کن و از تاب دادن کمر خودداری کن رفیق!',
        muscleGroup: 'جلوبازو و پشت‌بازو',
      ),
      WorkoutExerciseStep(
        phase: 'cooldown',
        phaseTitle: 'فاز ۳: سرد کردن، کشش و ریکاوری ❄️',
        name: 'کشش ایستا عضلات سینه، سرشانه، همسترینگ و تنفس دیافراگمی',
        sets: 1,
        repsOrDuration: '۳ دقیقه کشش عمیق',
        targetRestSeconds: 20,
        breathingGuide: '۴ ثانیه دم، ۴ ثانیه حبس، ۶ ثانیه بازدم آرام 🧘‍♂️',
        coachNote:
            'سرد کردن باعث میشه اسید لاکتیک تخلیه بشه و فردا کوفتگی شدید نداشته باشی!',
        muscleGroup: 'ریکاوری سیستم عصبی و عضلانی',
      ),
    ];
  }

  int get todayCaloriesConsumed =>
      todayFoodLogs.fold(0, (sum, item) => sum + item.calories);

  int get todayProteinConsumed =>
      todayFoodLogs.fold(0, (sum, item) => sum + item.proteinG);

  int get todayCarbsConsumed =>
      todayFoodLogs.fold(0, (sum, item) => sum + item.carbsG);

  int get todayFatConsumed =>
      todayFoodLogs.fold(0, (sum, item) => sum + item.fatG);

  StreakVisualState get currentStreakState {
    if (streakCount <= 0 &&
        todayCaloriesConsumed < 200 &&
        todayWaterGlasses < 2) {
      return StreakVisualState.deadSkull;
    }
    if (todayCaloriesConsumed >= 200 || todayWaterGlasses >= 3) {
      return StreakVisualState.redFire;
    }
    return StreakVisualState.blueFrozen;
  }

  String get streakEmoji {
    switch (currentStreakState) {
      case StreakVisualState.redFire:
        return '🔥';
      case StreakVisualState.blueFrozen:
        return '💙';
      case StreakVisualState.deadSkull:
        return '💀';
    }
  }

  String get streakStatusMessage {
    switch (currentStreakState) {
      case StreakVisualState.redFire:
        return 'آتیشت شعله‌وره قهرمان! 🔥 امروزت رو ثبت کردی و $streakCount روزه پیوسته داری می‌ترکونی!';
      case StreakVisualState.blueFrozen:
        return 'هشدار یخ‌زدگی! 💙 آتیش $streakCount روزه‌ت به خاطر ثبت نکردن امروز آبی شده؛ یه وعده یا ۳ لیوان آب ثبت کن تا دوباره قرمز و داغ بشه! 🔥';
      case StreakVisualState.deadSkull:
        return 'آتیش استریکت هنوز خاموشه! 💀 همین الان اولین خوراکی یا لیوان آبت رو ثبت کن تا آتیش استریکت روشن بشه رفیق! 🔥';
    }
  }

  // قفل ۳ مرحله‌ای متصل به کلودفلر:
  // 1 = نیاز به ورود (گوگل یا شماره موبایل)
  // 2 = نیاز به تکمیل فرم ثبت‌نام (پرونده بدنی و حافظه مربی)
  // 3 = نیاز به فعال‌سازی اشتراک ۱ ماهه (مگر اینکه مدیرعامل باشد که کلودفلر باز می‌کند)
  // 0 = هر ۳ قفل باز شده!
  int get aiLockStage {
    if (!profile.isLoggedIn) return 1;
    if (!profile.isProfileCompleted) return 2;
    if (!profile.hasActiveSubscription && !profile.isAdmin) return 3;
    return 0;
  }

  Map<String, String> get _authHeaders {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (profile.sessionToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${profile.sessionToken}';
    }
    if (profile.userKey.isNotEmpty) {
      headers['X-User-ID'] = profile.userKey;
    }
    return headers;
  }

  Future<void> saveAllToDisk() async {
    final prefs = _prefs;
    if (prefs == null) return;

    await prefs.setBool('bm_dark_mode', isDarkMode);
    await prefs.setBool('bm_notif_perm_asked', hasRequestedNotificationPerm);
    await prefs.setBool('bm_use_bodycoin_system', AppConfig.useBodyCoinSystem);
    await prefs.setString('bm_user_profile_v82', jsonEncode(profile.toJson()));
    await prefs.setInt('bm_streak_count_v82', streakCount);
    await prefs.setString('bm_last_streak_date_v82', lastCompletedStreakDate);
    await prefs.setInt('bm_today_water_v82', todayWaterGlasses);
    await prefs.setInt('bm_target_water_v82', targetWaterGlasses);

    await prefs.setString(
      'bm_today_food_logs_v82',
      jsonEncode(todayFoodLogs.map((e) => e.toJson()).toList()),
    );

    final serializedWeekly = weeklyMealPlan.map(
      (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'bm_weekly_meal_plan_v82',
      jsonEncode(serializedWeekly),
    );

    await prefs.setString(
      'bm_body_logs_v82',
      jsonEncode(bodyLogsHistory.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'bm_chat_messages_v82',
      jsonEncode(chatMessages.map((e) => e.toJson()).toList()),
    );
  }

  void toggleThemeMode() {
    isDarkMode = !isDarkMode;
    saveAllToDisk();
    notifyListeners();
  }

  void updateWaterGlasses(int delta) {
    todayWaterGlasses = (todayWaterGlasses + delta).clamp(0, 25);
    _checkAndUpgradeStreak();
    saveAllToDisk();
    notifyListeners();
  }

  void addFoodLog({
    required String title,
    required int calories,
    required int proteinG,
    required int carbsG,
    required int fatG,
    String emoji = '🍽️',
  }) {
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    todayFoodLogs.insert(
      0,
      FoodLogItem(
        id: 'fl_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        calories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        timeLabel: timeStr,
        emoji: emoji,
      ),
    );
    _checkAndUpgradeStreak();
    saveAllToDisk();
    notifyListeners();
  }

  void removeFoodLog(String id) {
    todayFoodLogs.removeWhere((e) => e.id == id);
    saveAllToDisk();
    notifyListeners();
  }

  void markMealSlotAsEaten(String dayName, int slotIndex) {
    final list = weeklyMealPlan[dayName];
    if (list == null || slotIndex < 0 || slotIndex >= list.length) return;
    final slot = list[slotIndex];
    slot.isEatenToday = true;
    addFoodLog(
      title: '${slot.mealType}: ${slot.title}',
      calories: slot.calories,
      proteinG: slot.proteinG,
      carbsG: slot.carbsG,
      fatG: slot.fatG,
      emoji: slot.emoji,
    );
  }

  void _checkAndUpgradeStreak() {
    final todayIso = DateTime.now().toIso8601String().split('T').first;
    if ((todayCaloriesConsumed >= 200 || todayWaterGlasses >= 3) &&
        lastCompletedStreakDate != todayIso) {
      streakCount += 1;
      lastCompletedStreakDate = todayIso;
    }
  }

  void addBodyMetricRecord({
    required double weightKg,
    String note = '',
  }) {
    profile.weightKg = weightKg;
    final record = BodyLogRecord(
      dateLabel: 'ثبت جدید (${DateTime.now().toIso8601String().split('T').first})',
      weightKg: weightKg,
      bmi: double.parse(profile.bmi.toStringAsFixed(1)),
      note: note.isEmpty ? 'بروزرسانی وزن هفتگی 💪' : note,
    );
    bodyLogsHistory.add(record);
    saveAllToDisk();
    notifyListeners();
  }

  // بررسی اتصال به اینترنت؛ در صورت قطعی، پاپ‌آپ مشکی سوختن کره زمین باز می‌شود! 🌍🔥
  Future<bool> ensureOnlineOrShowEarthBurn(BuildContext context) async {
    try {
      final pingRes = await http
          .get(Uri.parse('${AppConfig.serverBaseUrl}/api/health'))
          .timeout(const Duration(seconds: 6));
      if (pingRes.statusCode >= 200 && pingRes.statusCode < 500) {
        return true;
      }
    } catch (_) {}
    try {
      final result = await InternetAddress.lookup('server.matin-mohammadi.ir')
          .timeout(const Duration(seconds: 4));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}
    if (context.mounted) {
      await showEarthBurnOfflineDialog(context);
    }
    return false;
  }

  // درخواست مجوز نوتیفیکیشن اندروید ۱۳+ در بدو ورود
  Future<void> requestAndroidNotificationPermission(
    BuildContext context, {
    bool forceDialog = false,
  }) async {
    if (hasRequestedNotificationPerm && !forceDialog) return;
    hasRequestedNotificationPerm = true;
    await saveAllToDisk();

    if (!context.mounted) return;
    final shouldAsk = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: BMColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: BMColors.neonCyan, width: 1.4),
        ),
        title: const Row(
          children: [
            Text('🔔🔥 ', style: TextStyle(fontSize: 22)),
            Expanded(
              child: Text(
                'خوش اومدی به BodyMod رفیق!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'برای اینکه یادآور ساعت وعده‌های غذایی، روزهای تمرین و هشدار یخ زدن آتیش استریکت (💙🔥) رو از دست ندی، روی دکمه زیر بزن و توی پنجره اندروید گزینه Allow رو انتخاب کن! 🚀',
          style: TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 13.8,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'بعداً یادم بنداز',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: BMColors.neonCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.notifications_active_rounded, size: 18),
            label: const Text(
              'فعال کردن اعلان‌ها (Allow)',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (shouldAsk == true) {
      try {
        PermissionStatus status = await Permission.notification.request();
        if (status.isGranted) {
          await triggerImmediateWelcomeNotification();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔔 سیستم اطلاع‌رسانی بادی‌مود با موفقیت فعال شد رفیق! 🔥'),
              ),
            );
          }
        } else if (status.isPermanentlyDenied || status.isDenied) {
          // اگر قبلاً بسته شده بود یا اندروید پنجره رو باز نکرد، مستقیم صفحه مجوز اعلان برنامه در تنظیمات اندروید رو باز کن
          await openAppSettings();
        }
      } catch (_) {}
    }
  }

  Future<void> triggerImmediateWelcomeNotification() async {
    try {
      await AppConfig.nativeNotificationChannel.invokeMethod(
        'showImmediateNotification',
        {
          'title': 'بادی‌مود | BodyMod 🔔🔥',
          'body': 'سیستم اطلاع‌رسانی بادی‌مود با موفقیت فعال شد رفیق! از این به بعد یادآور وعده‌ها و استریک رو به موقع دریافت می‌کنی 💪',
        },
      );
    } catch (_) {}
  }

  // ==========================================================================
  // 2-STEP AUTHENTICATION FLOW (GOOGLE NATIVE OR BALE SAFIR OTP)
  // ==========================================================================

  Future<void> openTwoStepAuthModal(
    BuildContext context, {
    VoidCallback? onNavigateHome,
  }) async {
    final result = await bmShowResponsiveSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121A2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => Theme(data: BMTheme.dark(), child: TwoStepAuthBottomSheet(controller: this)),
    );

    if (result != null && result['loggedIn'] == true && context.mounted) {
      final bool hasExisting = result['hasExistingProfile'] == true;
      if (hasExisting) {
        // اگر کلودفلر از قبل فرم این جیمیل/شماره رو داشت، پاپ‌آپ فرم باز نمیشه و مستقیم میره صفحه اول!
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'خوش برگشتی قهرمان! اطلاعات قبلیت از کلودفلر بازیابی شد 🔥💪',
            ),
          ),
        );
        onNavigateHome?.call();
      } else {
        // اگر اولین بارش بود و فرمی توی کلودفلر نداشت، پاپ‌آپ فرم ثبت‌نام باز میشه (با دکمه ضربدر برای بستن)
        await openRegistrationProfileFormPopup(context);
      }
    }
  }

  Future<void> openRegistrationProfileFormPopup(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Theme(data: BMTheme.dark(), child: RegistrationProfileFormDialog(controller: this)),
    );
  }

  // مرحله الف-۱: ورود نیتیو با گوگل (GoogleSignIn Bottom-Sheet) + بررسی پرونده در کلودفلر
  Future<Map<String, dynamic>?> loginWithNativeGoogle(
    BuildContext context,
  ) async {
    final online = await ensureOnlineOrShowEarthBurn(context);
    if (!online) return null;

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        if (context.mounted) {
          return await _fallbackDirectGoogleEmailDialog(context);
        }
        return null;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final uri = Uri.parse('${AppConfig.serverBaseUrl}/api/auth/google/native');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id_token': auth.idToken,
              'access_token': auth.accessToken,
              'google_id': account.id,
              'email': account.email,
              'name': account.displayName ?? '',
              'photo_url': account.photoUrl ?? '',
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic> && data['success'] == true) {
          _applyServerAuthData(data);
          await saveAllToDisk();
          notifyListeners();
          if (profile.isAdmin) {
            unawaited(fetchCeoAdminLiveStats());
          }
          return {
            'loggedIn': true,
            'hasExistingProfile': data['hasExistingProfile'] == true,
          };
        }
      }
    } catch (_) {
      if (context.mounted) {
        return await _fallbackDirectGoogleEmailDialog(context);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fallbackDirectGoogleEmailDialog(
    BuildContext context,
  ) async {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Theme(
        data: BMTheme.dark(),
        child: AlertDialog(
          backgroundColor: BMColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: BMColors.neonCyan),
          ),
          title: const Text(
            'ورود با جیمیل (Google Account) 🔐',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'آدرس جیمیلت رو وارد کن تا مستقیم به سرور کلودفلر متصل بشی:',
                style: TextStyle(fontSize: 12.5, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'آدرس جیمیل (مثلاً name@gmail.com)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'نام شما (اختیاری)', hintText: 'رفیق ورزشکار', floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BMColors.neonCyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ورود به حساب 🚀', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && emailCtrl.text.trim().contains('@')) {
      final cleanEmail = emailCtrl.text.trim().toLowerCase();
      try {
        final uri = Uri.parse('${AppConfig.serverBaseUrl}/api/auth/google/native');
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'google_id': 'gid_${cleanEmail.hashCode.abs()}',
                'email': cleanEmail,
                'name': nameCtrl.text.trim(),
              }),
            )
            .timeout(const Duration(seconds: 12));
        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data is Map<String, dynamic> && data['success'] == true) {
            _applyServerAuthData(data);
            await saveAllToDisk();
            notifyListeners();
            if (profile.isAdmin) {
              unawaited(fetchCeoAdminLiveStats());
            }
            return {
              'loggedIn': true,
              'hasExistingProfile': data['hasExistingProfile'] == true,
            };
          }
        }
      } catch (_) {}
    }
    return null;
  }

  String _lastOtpStatelessToken = '';

  // مرحله الف-۲: ارسال کد تایید ۴ رقمی به شماره موبایل (سفیر بله)
  Future<Map<String, dynamic>> sendPhoneOtp(
    BuildContext context,
    String rawPhone,
  ) async {
    final online = await ensureOnlineOrShowEarthBurn(context);
    if (!online) return {'ok': false, 'message': 'اتصال اینترنت برقرار نیست!'};

    final cleanPhone = AppConfig.normalizeDigits(rawPhone);
    try {
      final uri = Uri.parse('${AppConfig.serverBaseUrl}/api/auth/otp/send');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': cleanPhone}),
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 200 && data['success'] == true) {
        _lastOtpStatelessToken = (data['otpToken'] ?? '').toString();
        return {
          'ok': true,
          'message':
              (data['message'] ?? 'کد تایید ۴ رقمی توی بله برات ارسال شد! 📩')
                  .toString(),
        };
      }
      return {
        'ok': false,
        'message': (data['error'] ?? 'خطا در ارسال کد تایید').toString(),
      };
    } catch (_) {
      return {
        'ok': false,
        'message': 'خطا در ارتباط با سرور کلودفلر! دوباره امتحان کن رفیق 🙏',
      };
    }
  }

  // تایید کد ۴ رقمی موبایل و بررسی اینکه آیا فرم قبلی در کلودفلر دارد یا خیر
  Future<Map<String, dynamic>> verifyPhoneOtp(
    BuildContext context, {
    required String rawPhone,
    required String otpCode,
  }) async {
    final online = await ensureOnlineOrShowEarthBurn(context);
    if (!online) return {'ok': false, 'message': 'اتصال اینترنت برقرار نیست!'};

    final cleanPhone = AppConfig.normalizeDigits(rawPhone);
    final cleanCode = AppConfig.normalizeDigits(otpCode);
    try {
      final uri = Uri.parse('${AppConfig.serverBaseUrl}/api/auth/otp/verify');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': cleanPhone,
              'code': cleanCode,
              'otpToken': _lastOtpStatelessToken,
            }),
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 200 && data['success'] == true) {
        _applyServerAuthData(data);
        await saveAllToDisk();
        notifyListeners();
        if (profile.isAdmin) {
          unawaited(fetchCeoAdminLiveStats());
        }
        return {
          'ok': true,
          'hasExistingProfile': data['hasExistingProfile'] == true,
          'message': (data['message'] ?? 'ورود موفق! 🔥').toString(),
        };
      }
      return {
        'ok': false,
        'message': (data['error'] ?? 'کد واردشده معتبر نیست!').toString(),
      };
    } catch (_) {
      return {
        'ok': false,
        'message': 'خطا در بررسی کد تایید با سرور کلودفلر!',
      };
    }
  }

  void _applyServerAuthData(Map<String, dynamic> data) {
    final token = (data['token'] ?? profile.sessionToken).toString();
    final serverProfile = data['profile'] as Map<String, dynamic>? ?? {};
    final userObj = data['user'] as Map<String, dynamic>? ?? {};

    profile = UserProfileModel.fromJson({
      ...profile.toJson(),
      ...serverProfile,
      'sessionToken': token,
      'email': serverProfile['email'] ?? userObj['email'] ?? profile.email,
      'phone': serverProfile['phone'] ?? userObj['phone'] ?? profile.phone,
      'userKey':
          serverProfile['userKey'] ??
          userObj['email'] ??
          userObj['phone'] ??
          profile.userKey,
      'isLoggedIn': true,
    });

    if (serverProfile['waterGoalGlasses'] != null) {
      targetWaterGlasses =
          (serverProfile['waterGoalGlasses'] as num).toInt().clamp(6, 25);
    }
    _applyQuotasFromResponse(data['quotas']);
  }

  void _applyQuotasFromResponse(dynamic quotasRaw) {
    if (quotasRaw is Map<String, dynamic>) {
      final chatDaily = quotasRaw['chat_daily'];
      if (chatDaily is Map<String, dynamic>) {
        final lite = chatDaily['gemini-3.5-flash-lite'];
        if (lite is Map<String, dynamic>) {
          remainingLiteChatQuota =
              (lite['remaining'] as num?)?.toInt() ?? remainingLiteChatQuota;
          maxLiteChatQuota = (lite['max'] as num?)?.toInt() ?? maxLiteChatQuota;
        }
        final flash = chatDaily['gemini-3.8-flash'];
        if (flash is Map<String, dynamic>) {
          remainingFlashChatQuota =
              (flash['remaining'] as num?)?.toInt() ?? remainingFlashChatQuota;
          maxFlashChatQuota =
              (flash['max'] as num?)?.toInt() ?? maxFlashChatQuota;
        }
      }
    }
  }

  Future<void> refreshProfileFromCloudflare() async {
    if (!profile.isLoggedIn || profile.userKey.isEmpty) return;
    try {
      final uri = Uri.parse(
        '${AppConfig.serverBaseUrl}/api/user/profile?uid=${Uri.encodeComponent(profile.userKey)}',
      );
      final res = await http
          .get(uri, headers: _authHeaders)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data is Map<String, dynamic> && data['profile'] != null) {
          _applyServerAuthData(data);
          await saveAllToDisk();
          notifyListeners();
          if (profile.isAdmin) {
            unawaited(fetchCeoAdminLiveStats());
          }
        }
      }
    } catch (_) {}
  }

  Future<void> signOutAccount() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    profile = UserProfileModel();
    appliedDiscountCode = '';
    appliedDiscountPercent = 0;
    discountedSubscriptionPriceToman = AppConfig.monthlySubscriptionPriceToman;
    await saveAllToDisk();
    notifyListeners();
  }

  // ذخیره فرم پرونده بدنی + حافظه هوش مصنوعی در کلودفلر (باز کردن قفل مرحله ۲)
  Future<bool> saveAndSyncBodyProfileForm(
    BuildContext context, {
    required String displayName,
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required double targetWeightKg,
    required String goal,
    required String workoutDaysPerWeek,
    required String workoutPlace,
    required String budgetTier,
    required String supplementPreference,
    required String aiCoachMemory,
  }) async {
    profile.displayName = displayName.trim().isEmpty
        ? 'رفیق ورزشکار'
        : displayName.trim();
    profile.age = age;
    profile.gender = gender;
    profile.heightCm = heightCm;
    profile.weightKg = weightKg;
    profile.targetWeightKg = targetWeightKg;
    profile.goal = goal;
    profile.workoutDaysPerWeek = workoutDaysPerWeek;
    profile.workoutPlace = workoutPlace;
    profile.budgetTier = budgetTier;
    profile.supplementPreference = supplementPreference;
    profile.aiCoachMemory = aiCoachMemory.trim();
    profile.isProfileCompleted = true;

    _ensureWorkoutStepsReady();
    await saveAllToDisk();
    notifyListeners();

    if (profile.isLoggedIn) {
      try {
        final uri = Uri.parse('${AppConfig.serverBaseUrl}/api/user/profile');
        final res = await http
            .post(
              uri,
              headers: _authHeaders,
              body: jsonEncode(profile.toJson()),
            )
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          if (data is Map<String, dynamic> && data['profile'] != null) {
            _applyServerAuthData(data);
            await saveAllToDisk();
            notifyListeners();
          }
        }
      } catch (_) {}
    }
    return true;
  }

  // ==========================================================================
  // MARKET-READY IN-APP BILLING (SUBSCRIPTION 189K & REPEATABLE DONATIONS)
  // ==========================================================================

  Future<Map<String, dynamic>> applyChannelDiscountCode(
    BuildContext context,
    String rawCode,
  ) async {
    final online = await ensureOnlineOrShowEarthBurn(context);
    if (!online) return {'ok': false, 'message': 'اتصال اینترنت برقرار نیست!'};

    try {
      final uri = Uri.parse(
        '${AppConfig.serverBaseUrl}/api/billing/apply-discount',
      );
      final res = await http
          .post(
            uri,
            headers: _authHeaders,
            body: jsonEncode({'code': rawCode.trim()}),
          )
          .timeout(const Duration(seconds: 8));
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 200 && data['success'] == true) {
        appliedDiscountCode = (data['code'] ?? '').toString();
        appliedDiscountPercent = (data['percent'] as num?)?.toInt() ?? 0;
        discountedSubscriptionPriceToman =
            (data['finalPriceToman'] as num?)?.toInt() ??
            AppConfig.monthlySubscriptionPriceToman;
        notifyListeners();
        return {
          'ok': true,
          'message': (data['message'] ?? 'کد تخفیف اعمال شد! 🎉').toString(),
        };
      }
      return {
        'ok': false,
        'message': (data['message'] ?? data['error'] ?? 'کد تخفیف معتبر نیست!')
            .toString(),
      };
    } catch (_) {
      return {
        'ok': false,
        'message': 'خطا در بررسی کد تخفیف با سرور کلودفلر!',
      };
    }
  }

  // خرید یا تمدید اشتراک ۱ ماهه (۱۸۹ هزار تومان) در نسخه واقعی مارکت (کافه‌بازار / مایکت)
  // هیچ فعال‌سازی تستی و رایگان روی کلیک انجام نمی‌شود!
  Future<void> purchaseOrRenewMonthlySubscription(BuildContext context) async {
    if (!profile.isLoggedIn) {
      await openTwoStepAuthModal(context);
      return;
    }

    if (!profile.canPurchaseOrRenewSubscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'رفیق هنوز ${profile.subscriptionDaysRemaining} روز از اشتراکت باقی مونده! تمدید اشتراک توی روزهای ۲۸ تا ۳۱ (وقتی ۳ روز یا کمتر مونده باشه) باز میشه و روزهای باقی‌مانده هم روی ماه جدیدت جمع میشه 😍⏳',
          ),
        ),
      );
      return;
    }

    final online = await ensureOnlineOrShowEarthBurn(context);
    if (!online) return;

    final sku = appliedDiscountPercent > 0
        ? 'bodymod_sub_discount_$appliedDiscountPercent'
        : AppConfig.monthlySubscriptionSku;

    try {
      // فراخوانی درگاه پرداخت درون‌برنامه‌ای کافه‌بازار / مایکت
      final dynamic billingResult = await AppConfig.marketBillingChannel
          .invokeMethod('purchaseSubscription', {
            'sku': sku,
            'priceToman': discountedSubscriptionPriceToman,
            'userKey': profile.userKey,
          });

      if (billingResult is Map &&
          billingResult['purchaseToken'] != null &&
          billingResult['purchaseToken'].toString().isNotEmpty) {
        final token = billingResult['purchaseToken'].toString();
        final market = (billingResult['market'] ?? 'market').toString();

        final uri = Uri.parse(
          '${AppConfig.serverBaseUrl}/api/billing/verify-subscription',
        );
        final res = await http
            .post(
              uri,
              headers: _authHeaders,
              body: jsonEncode({
                'purchaseToken': token,
                'sku': sku,
                'market': market,
                'discountCode': appliedDiscountCode,
              }),
            )
            .timeout(const Duration(seconds: 12));

        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (res.statusCode == 200 && data['success'] == true) {
          _applyServerAuthData(data);
          await saveAllToDisk();
          notifyListeners();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  (data['message'] ?? 'اشتراک ۱ ماهه با موفقیت فعال شد! 🔥💎')
                      .toString(),
                ),
              ),
            );
          }
          return;
        }
      }
    } catch (_) {
      // در صورتی که برنامه هنوز به درگاه مارکت متصل نشده یا مارکت روی گوشی باز نشود، اشتراک به هیچ وجه رایگان فعال نمی‌شود!
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: BMColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: BMColors.warningAmber),
          ),
          title: const Row(
            children: [
              Text('💳🔒 ', style: TextStyle(fontSize: 20)),
              Expanded(
                child: Text(
                  'درگاه پرداخت مارکت (کافه‌بازار / مایکت)',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5),
                ),
              ),
            ],
          ),
          content: Text(
            'شتاب‌دهنده پرداخت برای شناسه محصول «$sku» (مبلغ: $discountedSubscriptionPriceToman تومان) فراخوانی شد.\n\n'
            'چون برنامه در حالت نسخه نهاییِ انتشار (Production) قرار دارد، اشتراک بدون دریافت توکن تایید پرداخت از کافه‌بازار یا مایکت فعال نمی‌شود تا کاملاً امن و آماده لانچ در مارکت باشد! 🚀✅',
            style: const TextStyle(fontSize: 13, height: 1.6),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BMColors.neonCyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'متوجه شدم 👌',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
    }
  }

  // خرید چندباره و نامحدود حمایت مالی (Consumable IAP: 10k, 50k, 100k, 500k, 1M Toman)
  Future<void> purchaseRepeatableDonation(
    BuildContext context, {
    required String sku,
    required int amountToman,
    required String label,
  }) async {
    final online = await ensureOnlineOrShowEarthBurn(context);
    if (!online) return;

    try {
      final dynamic billingResult = await AppConfig.marketBillingChannel
          .invokeMethod('purchaseConsumableDonation', {
            'sku': sku,
            'amountToman': amountToman,
            'consumeImmediately': true, // قابلیت خرید چندباره و نامحدود (حتی ۱۰ بار پشت سر هم!)
          });

      if (billingResult is Map &&
          billingResult['purchaseToken'] != null &&
          billingResult['purchaseToken'].toString().isNotEmpty) {
        final token = billingResult['purchaseToken'].toString();
        final uri = Uri.parse(
          '${AppConfig.serverBaseUrl}/api/billing/verify-donation',
        );
        final res = await http
            .post(
              uri,
              headers: _authHeaders,
              body: jsonEncode({
                'sku': sku,
                'amountToman': amountToman,
                'purchaseToken': token,
              }),
            )
            .timeout(const Duration(seconds: 10));

        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (res.statusCode == 200 && data['success'] == true) {
          profile.totalDonatedToman += amountToman;
          profile.donationsCount += 1;
          await saveAllToDisk();
          notifyListeners();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  (data['message'] ?? 'دمت گرم بابت حمایتت رفیق! ❤️🔥')
                      .toString(),
                ),
              ),
            );
          }
          return;
        }
      }
    } catch (_) {}

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'درخواست پرداخت مصرفی (چندباره) برای «$label» (کد محصول: $sku) به درگاه بازار/مایکت ارسال شد! ❤️🚀',
          ),
        ),
      );
    }
  }

  // ==========================================================================
  // AI ENGINE CALLS (CALORIE VISION, DIVERSE 7-DAY MEAL PLAN & COACH CHAT)
  // ==========================================================================

  Future<Map<String, dynamic>?> analyzeFoodWithAi(
    BuildContext context, {
    required String foodDescription,
    String? base64Image,
  }) async {
    if (aiLockStage != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'رفیق اول قفل ۳ مرحله‌ای هوش مصنوعی (ورود ⬅️ فرم مشخصات ⬅️ اشتراک) رو باز کن! 🔐✨',
          ),
        ),
      );
      return null;
    }

    final online = await ensureOnlineOrShowEarthBurn(context);
    if (!online) return null;

    isLoadingAi = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${AppConfig.serverBaseUrl}/api/ai/calorie');
      final response = await http
          .post(
            uri,
            headers: _authHeaders,
            body: jsonEncode({
              'foodQuery': foodDescription,
              'imageBase64': base64Image,
              'model': profile.preferredModel,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic>) {
          _applyQuotasFromResponse(data['quotas']);
          final calAnalysis = data['calorie_analysis'];
          if (calAnalysis is Map<String, dynamic> &&
              calAnalysis['calories'] != null) {
            isLoadingAi = false;
            notifyListeners();
            return {
              'title': (calAnalysis['title'] ?? foodDescription).toString(),
              'calories': (calAnalysis['calories'] as num?)?.toInt() ?? 280,
              'proteinG': (calAnalysis['proteinG'] as num?)?.toInt() ?? 18,
              'carbsG': (calAnalysis['carbsG'] as num?)?.toInt() ?? 30,
              'fatG': (calAnalysis['fatG'] as num?)?.toInt() ?? 10,
              'coachTip': (calAnalysis['coachTip'] ?? data['reply'] ?? '')
                  .toString(),
            };
          }
          if (data['reply'] != null) {
            isLoadingAi = false;
            notifyListeners();
            return {
              'title': foodDescription.isEmpty
                  ? 'وعده بررسی‌شده با تصویر 📸'
                  : foodDescription,
              'calories': 320,
              'proteinG': 22,
              'carbsG': 34,
              'fatG': 11,
              'coachTip': data['reply'].toString(),
            };
          }
        }
      }
    } catch (_) {}

    isLoadingAi = false;
    notifyListeners();
    return null;
  }

  // درخواست برنامه غذایی ۷ روزه کاملاً متنوع از هوش مصنوعی (فقط بعد از باز شدن قفل ۳ مرحله‌ای!)
  Future<bool> requestAiWeeklyMealPlan(BuildContext context) async {
    if (aiLockStage != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'رفیق برای دریافت برنامه غذایی از هوش مصنوعی، اول قفل ۳ مرحله‌ای (ورود ⬅️ فرم ⬅️ اشتراک) رو تکمیل کن! 🔐🔥',
          ),
        ),
      );
      return false;
    }

    final online = await ensureOnlineOrShowEarthBurn(context);
    if (!online) return false;

    isLoadingAi = true;
    notifyListeners();

    bool parsedFromServerJson = false;
    try {
      final uri = Uri.parse('${AppConfig.serverBaseUrl}/api/ai/weekly-plan');
      final res = await http
          .post(
            uri,
            headers: _authHeaders,
            body: jsonEncode({
              'mode': 'weekly_plan',
              'model': profile.preferredModel,
              'prompt':
                  'بر اساس پرونده بدنی من (هدف: ${AppConfig.goalLabel(profile.goal)}، بودجه: ${AppConfig.budgetLabel(profile.budgetTier)}، تمرین: ${AppConfig.workoutDaysLabel(profile.workoutDaysPerWeek)}، حافظه مربی: ${profile.aiCoachMemory}) یک برنامه غذایی ۷ روزه کاملاً متنوع برای شنبه تا جمعه بچین که هیچ دو روزی غذای تکراری نداشته باشن.',
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data is Map<String, dynamic>) {
          _applyQuotasFromResponse(data['quotas']);
          final rawPlan = data['weekly_meal_plan'];
          if (rawPlan is Map<String, dynamic> && rawPlan.isNotEmpty) {
            final Map<String, List<MealPlanSlot>> built = {};
            for (final day in weekDays) {
              final dayList = rawPlan[day];
              if (dayList is List && dayList.isNotEmpty) {
                built[day] = dayList
                    .map(
                      (e) => MealPlanSlot.fromJson(e as Map<String, dynamic>),
                    )
                    .toList();
              }
            }
            if (built.length >= 5) {
              weeklyMealPlan = built;
              parsedFromServerJson = true;
            }
          }
        }
      }
    } catch (_) {}

    if (!parsedFromServerJson) {
      _buildDiverseTailoredSevenDayPlan();
    }

    await saveAllToDisk();
    isLoadingAi = false;
    notifyListeners();
    return true;
  }

  // ساخت برنامه ۷ روزه با تنوع ۱۰۰٪ واقعی در تمام ۷ روز هفته (شنبه تا جمعه بدون حتی ۱ وعده تکراری!)
  void _buildDiverseTailoredSevenDayPlan() {
    final tier = profile.budgetTier;
    final bool isVipOrFlagship =
        tier == AppConfig.budgetVip || tier == AppConfig.budgetFlagship;
    final bool isMid = tier == AppConfig.budgetMid;

    // ۷ منوی کاملاً متفاوت برای ۷ روز هفته (شنبه تا جمعه) متناسب با بودجه و هدف کاربر
    final List<Map<String, dynamic>> sevenDistinctDays = [
      // ۰: شنبه
      {
        'b': isVipOrFlagship
            ? 'املت ۳ سفیده و ۱ زرده با قارچ و آووکادو + ۲ ورق نان تست پروتئینی'
            : isMid
            ? 'املت ۲ عدد تخم‌مرغ با گوجه و فلفل دلمه‌ای + ۲ کف دست نان سنگک'
            : '۲ عدد تخم‌مرغ آب‌پز + ۲ کف دست نان سنگک و ۱ عدد گوجه',
        's1': isVipOrFlagship
            ? '۱ اسکوپ پروتئین وی ایزوله + ۱۰ عدد بادام درختی و بلوبری'
            : '۱ عدد سیب درختی + ۲ عدد گردو و ۱ فنجان چای سبز',
        'l': isVipOrFlagship
            ? '۲۰۰ گرم فیله سالمون گریل + ۸ قاشق برنج قهوه‌ای و کلم بروکلی بخارپز'
            : isMid
            ? '۱۸۰ گرم سینه مرغ زعفرانی + ۸ قاشق برنج کته و سالاد شیرازی'
            : '۱ کاسه پرپروتئین عدسی با ۱ قاشق روغن زیتون + ۲ کف دست سنگک',
        's2': 'معجون ۲ قاشق شیره انگور (دوشاب) و گردو + ۱ فنجان قهوه قبل تمرین',
        'd': isVipOrFlagship
            ? '۱۸۰ گرم استیک فیله گوساله + سالاد کینوا و سبزیجات گریل'
            : isMid
            ? 'خوراک ۲ عدد فیله مرغ تنوری با سیب‌زمینی آب‌پز و خیارشور'
            : 'خوراک لوبیا چیتی پخته + ۱ عدد تخم‌مرغ آب‌پز و سالاد فصل',
      },
      // ۱: یکشنبه
      {
        'b': isVipOrFlagship
            ? 'پنکیک جو دوسر پرک با کره بادام‌زمینی، موز و شیره افرا'
            : isMid
            ? 'کاسه اوتمیل (جو دوسر با شیر، ۱ عدد موز و ۱ قاشق عسل)'
            : '۲ قاشق غذاخوری ارده و شیره انگور (دوشاب) + ۲ کف دست نان بربری',
        's1': '۱ پیاله ماست یونانی کم‌چرب با نعناع خشک و ۵ عدد بادام',
        'l': isVipOrFlagship
            ? '۲ سیخ کباب برگ گوسفندی کم‌چرب + ۸ قاشق چلوی زعفرانی و گوجه کبابی'
            : isMid
            ? '۱ سیخ جوجه‌کباب زعفرانی کامل + ۸ قاشق برنج کته و ماست و خیار'
            : '۸ قاشق عدس‌پلو با گوشت چرخ‌کرده یا سویا + ۱ پیاله ماست',
        's2': '۱ عدد موز متوسط + ۱ قاشق مرباخوری کره بادام‌زمینی',
        'd': isVipOrFlagship
            ? '۲۰۰ گرم فیله بوقلمون مزه‌دارشده + قارچ کبابی و سالاد کاهو'
            : isMid
            ? '۱ قوطی تن ماهی آب‌کش‌شده با لیموترش + ۲ کف دست سنگک'
            : 'کوکو سیب‌زمینی و تخم‌مرغ کم‌روغن (۲ عدد) + گوجه و خیار و سنگک',
      },
      // ۲: دوشنبه
      {
        'b': isVipOrFlagship
            ? 'تست بوقلمون دودی و پنیر گودا کم‌چرب + ۲ عدد سفیده تخم‌مرغ'
            : '۱ قوطی کبریت پنیر سفید + ۳ عدد گردو، خیار و گوجه و ۲ کف دست سنگک',
        's1': '۳ عدد خرما مضافتی + ۱ لیوان شیر کم‌چرب ولرم',
        'l': isVipOrFlagship
            ? 'خورشت فسنجان با سینه مرغ (کم‌روغن) + ۸ قاشق برنج ایرانی'
            : isMid
            ? 'خورشت قورمه‌سبزی جاافتاده با گوشت لخم (۶ قاشق) + ۸ قاشق برنج'
            : '۸ قاشق ماکارونی دم‌کشیده با سویا و سیب‌زمینی ته‌دیگ + سالاد شیرازی',
        's2': '۱ مشت کوچک نخودچی و کشمش + ۱ فنجان چای تازهدم',
        'd': isVipOrFlagship
            ? 'سینه مرغ شکم‌پر با اسفناج و پنیر فتا + سبزیجات بخارپز'
            : isMid
            ? '۲ عدد کتلت گوشت خانگی کم‌روغن + سالاد کاهو و ۱ کف دست نان'
            : '۱ کاسه آش رشته سنتی با کشک فراوان (پروتئین بالا)',
      },
      // ۳: سه‌شنبه
      {
        'b': 'نیمرو ۲ عدد تخم‌مرغ با کمی زردچوبه و فلفل سیاه + ۲ کف دست سنگک',
        's1': '۱ عدد پرتقال یا ۲ عدد نارنگی فصل + ۱۰ عدد پسته خام',
        'l': isVipOrFlagship
            ? '۲۲۰ گرم ماهی قزل‌آلا شکم‌پر کبابی + ۸ قاشق سبزی‌پلو'
            : isMid
            ? 'خورشت قیمه کم‌روغن با گوشت و لپه (۶ قاشق) + ۸ قاشق برنج سفید'
            : '۱ کاسه آبگوشت سنتی (گوشت و نخود کوبیده) + ۲ کف دست سنگک و سبزی',
        's2': 'شیک خانگی (۱ لیوان شیر، نصف موز، ۱ قاشق شیره انگور و ۱ گردو)',
        'd': isVipOrFlagship
            ? 'سالاد سزار رژیمی با ۲۰۰ گرم فیله مرغ گریل و روغن زیتون'
            : isMid
            ? 'میرزاقاسمی (بادمجان کبابی، گوجه و ۲ تخم‌مرغ) + ۲ کف دست سنگک'
            : '۲ عدد سیب‌زمینی آب‌پز + ۲ عدد تخم‌مرغ آب‌پز رنده‌شده با نعناع و کره کم',
      },
      // ۴: چهارشنبه
      {
        'b': isVipOrFlagship
            ? 'فرنچ‌تست پروتئینی با سفیده تخم‌مرغ، دارچین و عسل طبیعی'
            : '۱ کاسه عدسی داغ صبحانه با آبلیمو + ۱ کف دست نان سنگک',
        's1': '۱ برش هندوانه یا طالبی شیرین + ۲ عدد گردو',
        'l': isVipOrFlagship
            ? '۸ قاشق باقالی‌پلو با ماهیچه گوسفندی + ماست موسیر'
            : isMid
            ? '۸ قاشق لوبیاپلو با گوشت تکه‌ای + ۱ پیاله ماست و خیار'
            : 'خوراک جگر مرغ یا سینه مرغ خردشده با پیاز و فلفل دلمه‌ای + سنگک',
        's2': '۲ عدد بیسکوئیت سبوس‌دار + ۱ فنجان قهوه اسپرسو یا چای',
        'd': isVipOrFlagship
            ? '۲۰۰ گرم میگو یا فیله ماهی گریل + سیب‌زمینی تنوری'
            : isMid
            ? 'کشک بادمجان پرپروتئین با گردو (۶ قاشق) + ۲ کف دست سنگک'
            : 'املت قارچ و پنیر کم‌چرب (با ۲ تخم‌مرغ) + سالاد فصل',
      },
      // ۵: پنجشنبه
      {
        'b': '۲ کف دست بربری داغ + پنیر سفید، ۱ قاشق عسل و ۲ عدد گردو',
        's1': '۱ عدد سیب + ۳ عدد خرما و ۱۰ عدد بادام درختی',
        'l': isVipOrFlagship
            ? '۱ سیخ کباب سلطانی یا چنجه گوسفندی + ۸ قاشق کته زعفرانی'
            : isMid
            ? 'زرشک‌پلو با ران مرغ زعفرانی (۸ قاشق برنج) + سالاد فصل'
            : '۸ قاشق استانبولی‌پلو با سیب‌زمینی و گوشت چرخ‌کرده / عدس + ماست',
        's2': '۱ پیاله کوچک شله‌زرد یا شیربرنج خانگی با دارچین',
        'd': isVipOrFlagship
            ? 'ساندویچ رست‌بیف یا مرغ گریل در نان چاباتا با کاهو و گوجه'
            : isMid
            ? '۱۵۰ گرم سینه مرغ گریل مکعبی + ۱ عدد ذرت مکزیکی کم‌سس'
            : 'ساندویچ ۵ قرص فلافل خانگی تنوری با گوجه و خیارشور',
      },
      // ۶: جمعه
      {
        'b': isVipOrFlagship
            ? 'بشقاب صبحانه انگلیسی رژیمی (۲ تخم‌مرغ، لوبیا، قارچ گریل و بوقلمون)'
            : 'حلیم گندم و بوقلمون پرپروتئین (۱ پیاله متوسط) با دارچین و کم‌شکر',
        's1': '۱ پیاله انگور یا میوه فصل + ۱ مشت کوچک تخمه آفتابگردان',
        'l': isVipOrFlagship
            ? 'سبزی‌پلو با ماهی شیر یا سالمون تازه + سیرترشی و سالاد'
            : isMid
            ? '۲ سیخ کباب کوبیده خانگی کم‌چرب + ۷ قاشق برنج و گوجه کبابی'
            : 'خوراک مرغ و سیب‌زمینی و هویج آب‌پز زعفرانی + ۲ کف دست سنگک',
        's2': '۱ لیوان دوغ سنتی خنک با نعناع یا ۱ فنجان چای با ۲ عدد خرما',
        'd': 'سوپ جو و مرغ مقوی با لیموترش تازه + سالاد کاهو و ۲ عدد سفیده تخم‌مرغ',
      },
    ];

    final targetCal = profile.recommendedDailyCalories;
    weeklyMealPlan.clear();

    for (int i = 0; i < weekDays.length; i++) {
      final dayName = weekDays[i];
      final menu = sevenDistinctDays[i];
      weeklyMealPlan[dayName] = [
        MealPlanSlot(
          mealType: 'صبحانه 🍳',
          title: menu['b'].toString(),
          ingredientsTip:
              'نیم ساعت قبل از صبحانه ۱ لیوان آب ولرم بنوش تا متابولیسمت روشن بشه! 💧',
          calories: (targetCal * 0.23).round(),
          proteinG: 24,
          carbsG: 42,
          fatG: 14,
          emoji: '🍳',
        ),
        MealPlanSlot(
          mealType: 'میان‌وعده صبح 🍎',
          title: menu['s1'].toString(),
          ingredientsTip: 'جلوگیری از ریزه‌خواری و حفظ انرژی تا ظهر ⚡',
          calories: (targetCal * 0.11).round(),
          proteinG: 9,
          carbsG: 22,
          fatG: 6,
          emoji: '🍎',
        ),
        MealPlanSlot(
          mealType: 'ناهار 🍲',
          title: menu['l'].toString(),
          ingredientsTip:
              'وعده اصلی روز $dayName؛ آروم بجو و سبزیجات کنارش رو فراموش نکن! 🥗',
          calories: (targetCal * 0.34).round(),
          proteinG: 44,
          carbsG: 58,
          fatG: 17,
          emoji: '🍲',
        ),
        MealPlanSlot(
          mealType: 'میان‌وعده عصر (قبل تمرین) ⚡',
          title: menu['s2'].toString(),
          ingredientsTip: 'سوخت‌رسانی عالی ۴۵ دقیقه قبل از شروع فعالیت بدنی 🔥',
          calories: (targetCal * 0.11).round(),
          proteinG: 8,
          carbsG: 28,
          fatG: 7,
          emoji: '🍯',
        ),
        MealPlanSlot(
          mealType: 'شام (ریکاوری شبانه) 🥗',
          title: menu['d'].toString(),
          ingredientsTip:
              'حداقل ۲ ساعت قبل از خواب میل کن تا ریکاوری عضلاتت عالی انجام بشه 🌙',
          calories: (targetCal * 0.21).round(),
          proteinG: 34,
          carbsG: 30,
          fatG: 12,
          emoji: '🥗',
        ),
      ];
    }
  }

  // ارسال پیام به چت مربی هوشمند در کلودفلر
  Future<void> sendChatMessageToCoach(
    BuildContext context,
    String text,
  ) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    if (aiLockStage != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'رفیق برای گفتگو با مربی هوشمند، اول قفل ۳ مرحله‌ای رو باز کن! 🔐✨',
          ),
        ),
      );
      return;
    }

    final online = await ensureOnlineOrShowEarthBurn(context);
    if (!online) return;

    final cost = AppConfig.estimateTokenAndCoinCost(
      clean,
      memoryText: profile.aiCoachMemory,
    );

    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    chatMessages.add(
      ChatMessageModel(
        id: 'u_${DateTime.now().millisecondsSinceEpoch}',
        isUser: true,
        text: clean,
        timeLabel: timeStr,
        estimatedTokens: cost['tokens'] ?? 800,
        estimatedCoins: cost['coins'] ?? 3,
      ),
    );
    isLoadingAi = true;
    notifyListeners();

    String aiReply = '';
    try {
      final uri = Uri.parse('${AppConfig.serverBaseUrl}/api/ai/chat');
      final response = await http
          .post(
            uri,
            headers: _authHeaders,
            body: jsonEncode({
              'prompt': clean,
              'model': profile.preferredModel,
            }),
          )
          .timeout(const Duration(seconds: 16));

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
        aiReply = (decoded['reply'] ?? decoded['text'] ?? '').toString();
        _applyQuotasFromResponse(decoded['quotas']);

        // اگر ایجنت کلودفلر تعداد لیوان‌های آب یا پروفایل را تغییر داد، اعمالش کن!
        final actions = decoded['actions_applied'];
        if (actions is Map<String, dynamic> &&
            actions['waterGoalGlasses'] != null) {
          targetWaterGlasses = (actions['waterGoalGlasses'] as num).toInt();
        }
      } else if (decoded is Map<String, dynamic> &&
          decoded['message'] != null) {
        aiReply = decoded['message'].toString();
      }
    } catch (_) {}

    if (aiReply.trim().isEmpty) {
      aiReply =
          'یه اختلال لحظه‌ای توی ارتباط با سرور پیش اومد رفیق! چند ثانیه دیگه دوباره پیامت رو بفرست تا کامل راهنماییت کنم 🙏🔥';
    }

    chatMessages.add(
      ChatMessageModel(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text: aiReply,
        timeLabel: timeStr,
        estimatedTokens: cost['tokens'] ?? 800,
        estimatedCoins: cost['coins'] ?? 3,
      ),
    );

    isLoadingAi = false;
    await saveAllToDisk();
    notifyListeners();
  }

  // دریافت آمار زنده پنل محرمانه مدیرعامل از کلودفلر (فقط برای متین!)
  Future<void> fetchCeoAdminLiveStats() async {
    if (!profile.isAdmin) return;
    try {
      final uri = Uri.parse('${AppConfig.serverBaseUrl}/api/admin/stats');
      final res = await http
          .get(uri, headers: _authHeaders)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data is Map<String, dynamic>) {
          adminTotalUsers =
              (data['total_registered_users'] as num?)?.toInt() ?? 0;
          adminActiveSubscribers =
              (data['active_beta_subscribers'] as num?)?.toInt() ?? 0;
          adminTodayAiRequests =
              (data['today_ai_requests'] as num?)?.toInt() ?? 0;
          adminTotalDonationsToman =
              (data['total_donations_toman'] as num?)?.toInt() ?? 0;
          adminDonationsCount = (data['donations_count'] as num?)?.toInt() ?? 0;

          final seg = data['economic_segments'];
          if (seg is Map<String, dynamic>) {
            adminTierBaseCount =
                (seg['base_under_20m'] as num?)?.toInt() ?? 0;
            adminTierMidCount =
                (seg['mid_20m_to_50m'] as num?)?.toInt() ?? 0;
            adminTierFlagshipCount =
                (seg['flagship_50m_to_100m'] as num?)?.toInt() ?? 0;
            adminTierVipWhalesCount =
                (seg['vip_whales_over_100m'] as num?)?.toInt() ?? 0;
          }

          final dir = data['users_directory'];
          if (dir is List) {
            adminUsersDirectory = dir
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  // ساخت کد تخفیف جدید برای کانال @bodymod_channel توسط مدیرعامل (متین)
  Future<String> createCeoDiscountCode({
    required String code,
    required int percent,
  }) async {
    if (!profile.isAdmin) return 'دسترسی غیرمجاز!';
    try {
      final uri = Uri.parse('${AppConfig.serverBaseUrl}/api/admin/discount');
      final res = await http
          .post(
            uri,
            headers: _authHeaders,
            body: jsonEncode({'code': code.trim(), 'percent': percent}),
          )
          .timeout(const Duration(seconds: 8));
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return (data['message'] ?? data['error'] ?? 'انجام شد').toString();
    } catch (_) {
      return 'خطا در ارتباط با سرور کلودفلر!';
    }
  }
}

// ============================================================================
// 7. STEP 1 AUTH MODAL (GOOGLE SIGN-IN OR BALE SAFIR MOBILE OTP)
// ============================================================================

class TwoStepAuthBottomSheet extends StatefulWidget {
  final BodyModController controller;

  const TwoStepAuthBottomSheet({super.key, required this.controller});

  @override
  State<TwoStepAuthBottomSheet> createState() => _TwoStepAuthBottomSheetState();
}

class _TwoStepAuthBottomSheetState extends State<TwoStepAuthBottomSheet> {
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _busy = false;
  String? _statusMsg;
  int _resendSecondsLeft = 0;
  Timer? _resendTimer;

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() {
      _resendSecondsLeft = 30;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsLeft > 0) {
        setState(() {
          _resendSecondsLeft -= 1;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🔐 ورود یا ثبت‌نام در بادی‌مود',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'با اکانت گوگل یا شماره موبایلت وارد شو؛ اگر قبلاً فرم مشخصاتت رو پر کرده باشی مستقیم میری داخل برنامه! 🚀',
              style: TextStyle(fontSize: 12.8, color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 16),

            // روش اول: ورود نیتیو با گوگل (Google Sign-In)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BMColors.neonCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        final res = await c.loginWithNativeGoogle(context);
                        if (!mounted) return;
                        setState(() => _busy = false);
                        if (res != null && res['loggedIn'] == true) {
                          Navigator.of(context).pop(res);
                        }
                      },
                icon: const Icon(Icons.account_circle_rounded, size: 22),
                label: const Text(
                  'ورود سریع با اکانت گوگل (Google)',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '— یا ورود با شماره موبایل (کد تایید بله) —',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'شماره موبایل (مثلاً 09123456789)',
                prefixIcon: Icon(Icons.phone_android_rounded),
              ),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'کد تایید ۴ رقمی ارسال‌شده در بله',
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
              ),
            ],
            if (_statusMsg != null) ...[
              const SizedBox(height: 10),
              Text(
                _statusMsg!,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: BMColors.neonCyan,
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BMColors.neonGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _busy
                    ? null
                    : () async {
                        final phone = _phoneCtrl.text.trim();
                        if (phone.isEmpty) return;
                        setState(() => _busy = true);
                        if (!_otpSent) {
                          final res = await c.sendPhoneOtp(context, phone);
                          if (!mounted) return;
                          final sentOk = res['ok'] == true;
                          setState(() {
                            _busy = false;
                            _otpSent = sentOk;
                            _statusMsg = res['message']?.toString();
                          });
                          if (sentOk) {
                            _startResendCountdown();
                          }
                        } else {
                          final code = _otpCtrl.text.trim();
                          if (code.isEmpty) {
                            setState(() => _busy = false);
                            return;
                          }
                          final res = await c.verifyPhoneOtp(
                            context,
                            rawPhone: phone,
                            otpCode: code,
                          );
                          if (!mounted) return;
                          setState(() => _busy = false);
                          if (res['ok'] == true) {
                            Navigator.of(context).pop({
                              'loggedIn': true,
                              'hasExistingProfile':
                                  res['hasExistingProfile'] == true,
                            });
                          } else {
                            setState(
                              () => _statusMsg = res['message']?.toString(),
                            );
                          }
                        }
                      },
                icon: Icon(
                  _otpSent
                      ? Icons.verified_user_rounded
                      : Icons.sms_outlined,
                  size: 19,
                ),
                label: Text(
                  _otpSent
                      ? 'تایید کد و ورود به بادی‌مود 🚀'
                      : 'دریافت کد تایید ۴ رقمی 📩',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: (_busy || _resendSecondsLeft > 0)
                        ? null
                        : () async {
                            final phone = _phoneCtrl.text.trim();
                            if (phone.isEmpty) return;
                            setState(() => _busy = true);
                            final res = await c.sendPhoneOtp(context, phone);
                            if (!mounted) return;
                            setState(() {
                              _busy = false;
                              _statusMsg = res['message']?.toString();
                            });
                            if (res['ok'] == true) {
                              _otpCtrl.clear();
                              _startResendCountdown();
                            }
                          },
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: Text(
                      _resendSecondsLeft > 0
                          ? 'ارسال مجدد کد ($_resendSecondsLeft ثانیه) ⏳'
                          : 'ارسال مجدد کد تایید 🔄',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: _resendSecondsLeft > 0
                            ? Colors.white54
                            : BMColors.neonCyan,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            _resendTimer?.cancel();
                            setState(() {
                              _otpSent = false;
                              _resendSecondsLeft = 0;
                              _otpCtrl.clear();
                              _statusMsg = null;
                            });
                          },
                    child: const Text(
                      'ویرایش شماره ✏️',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 8. STEP 2 REGISTRATION FORM POPUP (WITH ❌ CLOSE BUTTON) & EDITABLE FORM
// ============================================================================

class RegistrationProfileFormDialog extends StatelessWidget {
  final BodyModController controller;

  const RegistrationProfileFormDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: BMColors.surfaceDark,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: BMColors.neonCyan, width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // هدر پاپ‌آپ همراه با دکمه ضربدر (❌) برای بستن در صورت تمایل کاربر
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  const Text('📋✨ ', style: TextStyle(fontSize: 20)),
                  const Expanded(
                    child: Text(
                      'تکمیل پرونده بدنی و حافظه مربی (مرحله ۲)',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'بستن و تکمیل در زمان دیگر',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: EditableBodyProfileFormWidget(
                  controller: controller,
                  isInsidePopup: true,
                  onSaved: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditableBodyProfileFormWidget extends StatefulWidget {
  final BodyModController controller;
  final bool isInsidePopup;
  final VoidCallback? onSaved;

  const EditableBodyProfileFormWidget({
    super.key,
    required this.controller,
    this.isInsidePopup = false,
    this.onSaved,
  });

  @override
  State<EditableBodyProfileFormWidget> createState() =>
      _EditableBodyProfileFormWidgetState();
}

class _EditableBodyProfileFormWidgetState
    extends State<EditableBodyProfileFormWidget> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _targetWeightCtrl;
  late TextEditingController _memoryCtrl;

  late String _selectedGender;
  late String _selectedGoal;
  late String _selectedWorkoutDays;
  late String _selectedWorkoutPlace;
  late String _selectedBudgetTier;
  late String _selectedSupplementMode;

  @override
  void initState() {
    super.initState();
    final p = widget.controller.profile;
    _nameCtrl = TextEditingController(text: ((p.displayName).toString().trim() == 'رفیق ورزشکار' || (p.displayName).toString().trim() == 'ورزشکار') ? '' : (p.displayName).toString());
    _ageCtrl = TextEditingController(text: ''));
    _heightCtrl = TextEditingController(text: p.heightCm.toString());
    _weightCtrl = TextEditingController(text: p.weightKg.toString());
    _targetWeightCtrl = TextEditingController(
      text: p.targetWeightKg.toString(),
    );
    _memoryCtrl = TextEditingController(text: p.aiCoachMemory);

    _selectedGender = p.gender;
    _selectedGoal = AppConfig.goalOptions.containsKey(p.goal)
        ? p.goal
        : 'gain_muscle';
    _selectedWorkoutDays =
        AppConfig.workoutDaysOptions.containsKey(p.workoutDaysPerWeek)
        ? p.workoutDaysPerWeek
        : 'd3';
    _selectedWorkoutPlace = p.workoutPlace;
    _selectedBudgetTier = AppConfig.budgetTierOptions.containsKey(p.budgetTier)
        ? p.budgetTier
        : AppConfig.budgetBase;
    _selectedSupplementMode = p.supplementPreference;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _memoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'نام یا لقب قهرمانی شما', hintText: 'رفیق ورزشکار', floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 12),

        // حداکثر ۲ فیلد در هر ردیف تا هیچ عنوانی بریده نشود!
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'تاریخ تولد (محاسبه خودکار سن با تقویم رسمی)', hintText: 'روز ماه سال', floatingLabelBehavior: FloatingLabelBehavior.always,),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'جنسیت'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('آقا 👨')),
                  DropdownMenuItem(value: 'female', child: Text('خانم 👩')),
                ],
                onChanged: (v) =>
                    setState(() => _selectedGender = v ?? 'male'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _heightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'قد (سانتی‌متر)',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _weightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'وزن فعلی (کیلوگرم)',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _targetWeightCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'وزن هدف شما (کیلوگرم)',
            prefixIcon: Icon(Icons.flag_outlined),
          ),
        ),
        const SizedBox(height: 12),

        // ۶ هدف دقیق بدنسازی و تناسب اندام
        DropdownButtonFormField<String>(
          value: _selectedGoal,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'هدف اصلی شما 🎯',
          ),
          items: AppConfig.goalOptions.entries
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) =>
              setState(() => _selectedGoal = v ?? 'gain_muscle'),
        ),
        const SizedBox(height: 14),

        // سوال تعداد روزهای تمرین در هفته با توضیح دقیق
        const Text(
          '🏋️‍♂️ چند روز در هفته تمرین میکنی؟ مناسب عضله سازی (هرچه بیشتر تمرین کنی، سریعتر به هدفت میرسی)',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: BMColors.neonCyan,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedWorkoutDays,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'تعداد روزهای تمرین در هفته',
          ),
          items: AppConfig.workoutDaysOptions.entries
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) =>
              setState(() => _selectedWorkoutDays = v ?? 'd3'),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: _selectedWorkoutPlace,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'محل تمرین و تجهیزات 🏟️',
          ),
          items: const [
            DropdownMenuItem(
              value: 'home_dumbbell',
              child: Text('تمرین در خانه با دمبل 🏠💪'),
            ),
            DropdownMenuItem(
              value: 'gym',
              child: Text('باشگاه بدنسازی کامل 🏟️'),
            ),
            DropdownMenuItem(
              value: 'bodyweight',
              child: Text('در خانه بدون تجهیزات (وزن بدن) 🤸‍♂️'),
            ),
          ],
          onChanged: (v) =>
              setState(() => _selectedWorkoutPlace = v ?? 'home_dumbbell'),
        ),
        const SizedBox(height: 12),

        // ۴ سطح وضعیت اقتصادی و میزان درآمد ماهانه
        DropdownButtonFormField<String>(
          value: _selectedBudgetTier,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'وضعیت اقتصادی — میزان درآمد شما در ماه 💰',
          ),
          items: AppConfig.budgetTierOptions.entries
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) =>
              setState(() => _selectedBudgetTier = v ?? AppConfig.budgetBase),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: _selectedSupplementMode,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'ترجیح مکمل‌ها و شیک‌های ورزشی 🥤',
          ),
          items: const [
            DropdownMenuItem(
              value: 'commercial',
              child: Text('مکمل‌های ورزشی استاندارد (وی، کراتین و...) 💊'),
            ),
            DropdownMenuItem(
              value: 'homemade',
              child: Text('مکمل‌ها و شیک‌های دست‌ساز خانگی طبیعی 🍌🥜'),
            ),
          ],
          onChanged: (v) => setState(
            () => _selectedSupplementMode = v ?? 'commercial',
          ),
        ),
        const SizedBox(height: 16),

        // کادر حافظه بلندمدت هوش مصنوعی داخل فرم ثبت‌نام (و قابل ویرایش در پروفایل!)
        const Text(
          '🧠 حافظه بلندمدت هوش مصنوعی (برای شخصی‌سازی دقیق برنامه غذایی و تمرین):',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _memoryCtrl,
          maxLines: 6,
          minLines: 5,
          decoration: const InputDecoration(
            hintText: AppConfig.aiMemoryHintText,
            hintMaxLines: 8,
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: BMColors.neonGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              await c.saveAndSyncBodyProfileForm(
                context,
                displayName: _nameCtrl.text,
                age: (bmCalculateAgeFromBirthDate(_ageCtrl.text) ?? int.tryParse(_ageCtrl.text)) ?? 21,
                gender: _selectedGender,
                heightCm: double.tryParse(_heightCtrl.text) ?? 175,
                weightKg: double.tryParse(_weightCtrl.text) ?? 70,
                targetWeightKg: double.tryParse(_targetWeightCtrl.text) ?? 75,
                goal: _selectedGoal,
                workoutDaysPerWeek: _selectedWorkoutDays,
                workoutPlace: _selectedWorkoutPlace,
                budgetTier: _selectedBudgetTier,
                supplementPreference: _selectedSupplementMode,
                aiCoachMemory: _memoryCtrl.text,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'مشخصات و حافظه مربی با موفقیت در کلودفلر ذخیره شد! 🔥✅',
                    ),
                  ),
                );
                widget.onSaved?.call();
              }
            },
            icon: const Icon(Icons.check_circle_rounded),
            label: Text(
              widget.isInsidePopup
                  ? 'ثبت نهایی فرم و ورود به برنامه 🚀'
                  : 'ذخیره تغییرات پرونده بدنی و حافظه مربی ✅',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 9. ROOT APP & MAIN SHELL (WITH TOP CHANNEL BANNER ON ALL SCREENS)
// ============================================================================

class BodyModApp extends StatelessWidget {
  final BodyModController controller;

  const BodyModApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: BMTheme.light(),
          darkTheme: BMTheme.dark(),
          themeMode: controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: MainShellScreen(controller: controller),
        );
      },
    );
  }
}

class MainShellScreen extends StatefulWidget {
  final BodyModController controller;

  const MainShellScreen({super.key, required this.controller});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.requestAndroidNotificationPermission(context);
    });
  }

  void _jumpToTab(int idx) {
    setState(() {
      _currentTab = idx;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final pages = [
      HomeDashboardTab(controller: c, onNavigateTab: _jumpToTab),
      WeeklyMealPlanTab(controller: c, onNavigateTab: _jumpToTab),
      WorkoutAndLivePlayerTab(controller: c, onNavigateTab: _jumpToTab),
      BodyAndAiCoachTab(controller: c, onNavigateTab: _jumpToTab),
      ProfileAndBillingTab(controller: c, onNavigateTab: _jumpToTab),
    ];

    return Scaffold(
      drawer: _buildAppDrawer(context, c),
      appBar: AppBar(
        titleSpacing: 4,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [BMColors.neonCyan, BMColors.neonGreen],
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: Colors.black,
                size: 19,
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'بادی‌مود | BodyMod',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
        actions: [
          // نشانگر آتیش استریک (🔥 / 💙 / 💀)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _showStreakPhilosophySheet(context, c),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.currentStreakState == StreakVisualState.redFire
                    ? BMColors.flameOrange.withOpacity(0.18)
                    : c.currentStreakState == StreakVisualState.blueFrozen
                    ? BMColors.electricBlue.withOpacity(0.22)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: c.currentStreakState == StreakVisualState.redFire
                      ? BMColors.flameOrange
                      : c.currentStreakState == StreakVisualState.blueFrozen
                      ? BMColors.electricBlue
                      : Colors.white38,
                ),
              ),
              child: Row(
                children: [
                  Text(c.streakEmoji, style: const TextStyle(fontSize: 14.5)),
                  const SizedBox(width: 4),
                  Text(
                    '${c.streakCount} روز',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // نشانگر سهمیه روزانه یا ورود سریع
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (!c.profile.isLoggedIn) {
                c.openTwoStepAuthModal(
                  context,
                  onNavigateHome: () => _jumpToTab(0),
                );
              } else {
                _jumpToTab(4);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: BMColors.neonCyan.withOpacity(0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BMColors.neonCyan.withOpacity(0.55)),
              ),
              child: Row(
                children: [
                  Text(
                    !c.profile.isLoggedIn
                        ? '🔐'
                        : c.profile.isAdmin
                        ? '👑'
                        : '⚡',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    !c.profile.isLoggedIn
                        ? 'ورود'
                        : c.profile.isAdmin
                        ? 'VIP'
                        : '${c.remainingLiteChatQuota}/${c.maxLiteChatQuota}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                      color: BMColors.neonCyan,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // کادر کانال بادیمود (@bodymod_channel) بالای تمام صفحات قرار دارد!
      body: Column(
        children: [
          const BodyModTopChannelBanner(),
          Expanded(
            child: IndexedStack(index: _currentTab, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: c.isDarkMode
                  ? BMColors.cardBorderDark
                  : BMColors.cardBorderLight,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentTab,
          onDestinationSelected: _jumpToTab,
          backgroundColor: c.isDarkMode
              ? BMColors.surfaceDark
              : BMColors.surfaceLight,
          indicatorColor: BMColors.neonCyan.withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(
                Icons.dashboard_rounded,
                color: BMColors.neonCyan,
              ),
              label: 'داشبورد',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(
                Icons.restaurant_menu_rounded,
                color: BMColors.neonCyan,
              ),
              label: 'برنامه غذایی',
            ),
            NavigationDestination(
              icon: Icon(Icons.play_circle_outline_rounded),
              selectedIcon: Icon(
                Icons.play_circle_fill_rounded,
                color: BMColors.neonCyan,
              ),
              label: 'باشگاه زنده',
            ),
            NavigationDestination(
              icon: Icon(Icons.psychology_outlined),
              selectedIcon: Icon(
                Icons.psychology_rounded,
                color: BMColors.neonCyan,
              ),
              label: 'مربی و بدن',
            ),
            // فقط «پروفایل» نوشته شده (نام مدیرعامل برای کاربران عادی کاملاً حذف و مخفی شد!)
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: BMColors.neonCyan,
              ),
              label: 'پروفایل',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppDrawer(BuildContext context, BodyModController c) {
    return Drawer(
      backgroundColor: c.isDarkMode ? BMColors.surfaceDark : Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BMColors.neonCyan.withOpacity(0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: BMColors.neonCyan.withOpacity(0.2),
                        child: const Text('🦾', style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.profile.displayName.isEmpty
                                  ? 'قهرمان بادی‌مود'
                                  : c.profile.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              c.profile.isLoggedIn
                                  ? c.profile.userKey
                                  : 'حالت آفلاین (بدون ثبت‌نام)',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              value: c.isDarkMode,
              onChanged: (_) => c.toggleThemeMode(),
              secondary: const Icon(
                Icons.dark_mode_rounded,
                color: BMColors.neonCyan,
              ),
              title: const Text(
                'تم تاریک نئونی (Obsidian)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.notifications_active_rounded,
                color: BMColors.neonGreen,
              ),
              title: const Text('تنظیم مجوز اعلان اندروید (Allow)'),
              onTap: () {
                Navigator.pop(context);
                c.requestAndroidNotificationPermission(
                  context,
                  forceDialog: true,
                );
              },
            ),
            // فقط اگر کلودفلر تایید کند که کاربر مدیرعامل است، گزینه پنل مدیرعامل نمایش داده می‌شود!
            if (c.profile.isAdmin) ...[
              const Divider(height: 24),
              ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: BMColors.whaleGold,
                ),
                title: const Text('پنل فرماندهی محرمانه مدیرعامل 👑'),
                subtitle: const Text('آمار کلودفلر، نهنگ‌ها و ساخت کد تخفیف'),
                onTap: () {
                  Navigator.pop(context);
                  _jumpToTab(4);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showStreakPhilosophySheet(BuildContext context, BodyModController c) {
    bmShowResponsiveSheet(
      context: context,
      backgroundColor: BMColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'فلسفه آتیش استریک بادی‌مود 🔥💙💀',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              c.streakStatusMessage,
              style: const TextStyle(
                color: BMColors.neonCyan,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '• 🔥 آتیش قرمز/نارنجی: یعنی امروز کالری یا لیوان آبت رو ثبت کردی و استریکت داغ و فعاله!\n'
              '• 💙 آتیش آبی (یخ‌زده): یعنی امروز هنوز چیزی ثبت نکردی و آتیشت داره از سرما یخ می‌زنه!\n'
              '• 💀 جمجمه خاموش: یعنی هنوز استریکت رو روشن نکردی یا بیش از ۲۴ ساعت غیبت داشتی!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BMColors.neonCyan,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'حله رفیق! نمیذارم آتیشم یخ بزنه 🔥💪',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 10. 3-STAGE SMART AI LOCK BANNER (CONNECTED TO 2-STEP AUTH & FORM POPUP)
// ============================================================================

class SmartAiLockBanner extends StatelessWidget {
  final BodyModController controller;
  final ValueChanged<int> onNavigateTab;

  const SmartAiLockBanner({
    super.key,
    required this.controller,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final stage = controller.aiLockStage;
    if (stage == 0) return const SizedBox.shrink();

    String title = '';
    String subtitle = '';
    String btnText = '';
    IconData icon = Icons.lock_outline_rounded;
    Color accent = BMColors.neonCyan;

    if (stage == 1) {
      title = 'قفل مرحله ۱ از ۳: ثبت‌نام و ورود به حساب 🔐';
      subtitle =
          'بخش‌های آفلاین کاملاً باز هستن رفیق! اما برای دسترسی به هوش مصنوعی، اول با گوگل یا شماره موبایل وارد شو.';
      btnText = 'ورود با گوگل یا شماره موبایل 🚀';
      icon = Icons.login_rounded;
      accent = BMColors.neonCyan;
    } else if (stage == 2) {
      title = 'قفل مرحله ۲ از ۳: تکمیل فرم مشخصات بدنی 📋';
      subtitle =
          'ایول وارد شدی! حالا قد، وزن، تاریخ تولد و هدفت رو پر کن تا قفل مرحله دوم باز بشه (حافظه هوش مصنوعی کاملاً اختیاریه).';
      btnText = 'باز کردن فرم مشخصات بدنی ✍️';
      icon = Icons.assignment_ind_rounded;
      accent = BMColors.warningAmber;
    } else {
      title = 'قفل مرحله ۳ از ۳: فعال‌سازی اشتراک ۱ ماهه (۱۸۹ هزار تومن) 💎';
      subtitle =
          'ورود و فرمت تایید شد! برای باز شدن کامل هوش مصنوعی، اشتراک ۱ ماهه رو فعال کن (کد تخفیف رو هم از @bodymod_channel بردار!).';
      btnText = 'مشاهده و فعال‌سازی اشتراک 🔥';
      icon = Icons.workspace_premium_rounded;
      accent = BMColors.neonGreen;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.18), const Color(0xFF131C31)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.65), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.2,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(subtitle, style: const TextStyle(fontSize: 12.8, height: 1.5)),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (stage == 1) {
                  await controller.openTwoStepAuthModal(
                    context,
                    onNavigateHome: () => onNavigateTab(0),
                  );
                } else if (stage == 2) {
                  await controller.openRegistrationProfileFormPopup(context);
                } else {
                  onNavigateTab(4);
                }
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(
                btnText,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 11. TAB 1: HOME DASHBOARD & COMPREHENSIVE GRANULAR FOOD BANK
// ============================================================================

class HomeDashboardTab extends StatefulWidget {
  final BodyModController controller;
  final ValueChanged<int> onNavigateTab;

  const HomeDashboardTab({
    super.key,
    required this.controller,
    required this.onNavigateTab,
  });

  @override
  State<HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends State<HomeDashboardTab> {
  final TextEditingController _foodAiQueryCtrl = TextEditingController();
  final TextEditingController _bankSearchCtrl = TextEditingController();
  String _selectedCategory = 'همه 🌟';
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _lastAiFoodResult;

  @override
  void dispose() {
    _foodAiQueryCtrl.dispose();
    _bankSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFoodPhotoAndAnalyze(ImageSource source) async {
    final c = widget.controller;
    if (c.aiLockStage != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'رفیق برای آنالیز تصویری غذا با هوش مصنوعی، اول قفل ۳ مرحله‌ای رو باز کن! 🔐📸',
          ),
        ),
      );
      return;
    }

    final online = await c.ensureOnlineOrShowEarthBurn(context);
    if (!online) return;

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 78,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      if (!mounted) return;
      final res = await c.analyzeFoodWithAi(
        context,
        foodDescription: _foodAiQueryCtrl.text.trim().isEmpty
            ? 'عکس وعده غذایی'
            : _foodAiQueryCtrl.text.trim(),
        base64Image: b64,
      );
      if (res != null && mounted) {
        setState(() => _lastAiFoodResult = res);
      }
    } catch (_) {}
  }

  // پنجره انتخاب واحد (عدد، قاشق غذاخوری، قاشق مرباخوری، کف دست، پیاله، کاسه، بشقاب، لیوان...) و مقدار دقیق
  void _showGranularPortionSelectorSheet(
    BuildContext context,
    FoodBankUnitItem item,
  ) {
    final c = widget.controller;
    final Map<String, double> unitMap = item.alternateUnitsMultiplier.isNotEmpty
        ? item.alternateUnitsMultiplier
        : {
            item.baseUnitName: 1.0,
            'نصف ${item.baseUnitName}': 0.5,
            '۲ ${item.baseUnitName}': 2.0,
            '۳ ${item.baseUnitName}': 3.0,
          };

    String chosenUnit = unitMap.keys.first;
    double chosenQty = 1.0;
    final List<double> presetQuantities = [
      0.5,
      1.0,
      1.5,
      2.0,
      3.0,
      4.0,
      5.0,
      6.0,
      8.0,
      10.0,
      12.0,
    ];

    bmShowResponsiveSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BMColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final double unitMult = unitMap[chosenUnit] ?? 1.0;
          final double totalFactor = unitMult * chosenQty;
          final int finalCal = (item.caloriesPerUnit * totalFactor).round();
          final int finalProt = (item.proteinPerUnit * totalFactor).round();
          final int finalCarbs = (item.carbsPerUnit * totalFactor).round();
          final int finalFat = (item.fatPerUnit * totalFactor).round();

          final String qtyStr = chosenQty == chosenQty.roundToDouble()
              ? chosenQty.toInt().toString()
              : chosenQty.toString();

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '۱. واحد اندازه‌گیری رو انتخاب کن (از کمترین واحد تا پرس کامل):',
                  style: TextStyle(fontSize: 12.5, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: unitMap.keys.map((uName) {
                    final selected = uName == chosenUnit;
                    return ChoiceChip(
                      selected: selected,
                      selectedColor: BMColors.neonCyan,
                      label: Text(
                        uName,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: selected ? Colors.black : Colors.white,
                        ),
                      ),
                      onSelected: (_) =>
                          setSheetState(() => chosenUnit = uName),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                const Text(
                  '۲. چقدر از این واحد خوردی؟ (تعداد / ضریب):',
                  style: TextStyle(fontSize: 12.5, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: presetQuantities.map((q) {
                    final selected = q == chosenQty;
                    final label = q == 0.5
                        ? 'نصف (0.5)'
                        : q == q.roundToDouble()
                        ? '${q.toInt()}'
                        : '$q';
                    return ChoiceChip(
                      selected: selected,
                      selectedColor: BMColors.neonGreen,
                      label: Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: selected ? Colors.black : Colors.white,
                        ),
                      ),
                      onSelected: (_) => setSheetState(() => chosenQty = q),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: BMColors.neonCyan.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _miniNutrient('🔥 کالری', '$finalCal kcal'),
                      _miniNutrient('🥩 پروتئین', '${finalProt}g'),
                      _miniNutrient('🍚 کربو', '${finalCarbs}g'),
                      _miniNutrient('🥑 چربی', '${finalFat}g'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BMColors.neonGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      c.addFoodLog(
                        title: '${item.title} ($qtyStr $chosenUnit)',
                        calories: finalCal,
                        proteinG: finalProt,
                        carbsG: finalCarbs,
                        fatG: finalFat,
                        emoji: item.emoji,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${item.emoji} «$qtyStr $chosenUnit ${item.title}» ($finalCal کالری) ثبت شد رفیق! 🔥',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_task_rounded),
                    label: Text(
                      '➕ خوردم! ثبت $qtyStr $chosenUnit ($finalCal کالری)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _miniNutrient(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 3),
        Text(
          val,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            color: BMColors.neonCyan,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final macros = c.profile.recommendedMacros;
    final targetCal = macros['calories'] ?? 2200;
    final consumedCal = c.todayCaloriesConsumed;
    final calRatio = (consumedCal / math.max(1, targetCal)).clamp(0.0, 1.0);

    final allBankItems = [
      ...c.customUserFoods,
      ...ComprehensiveFoodBankCatalog.allItems,
    ];
    final searchQ = _bankSearchCtrl.text.trim();
    final filteredBank = allBankItems.where((item) {
      final matchCat =
          _selectedCategory == 'همه 🌟' || item.category == _selectedCategory;
      final matchSearch =
          searchQ.isEmpty ||
          item.title.contains(searchQ) ||
          item.category.contains(searchQ);
      return matchCat && matchSearch;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 95),
      children: [
        // کارت وضعیت آتیش استریک (🔥 / 💙 / 💀)
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: c.currentStreakState == StreakVisualState.redFire
                  ? [const Color(0xFF431407), const Color(0xFF1E293B)]
                  : c.currentStreakState == StreakVisualState.blueFrozen
                  ? [const Color(0xFF0C4A6E), const Color(0xFF1E293B)]
                  : [const Color(0xFF1F2937), const Color(0xFF111827)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: c.currentStreakState == StreakVisualState.redFire
                  ? BMColors.flameOrange
                  : c.currentStreakState == StreakVisualState.blueFrozen
                  ? BMColors.electricBlue
                  : Colors.white24,
            ),
          ),
          child: Row(
            children: [
              Text(c.streakEmoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'استریک فعلی: ${c.streakCount} روز پیوسته',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.streakStatusMessage,
                      style: const TextStyle(
                        fontSize: 12.2,
                        color: Colors.white70,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // حلقه کالری و درشت‌مغذی‌های امروز
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 92,
                      height: 92,
                      child: CircularProgressIndicator(
                        value: calRatio,
                        strokeWidth: 9,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          BMColors.neonCyan,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$consumedCal',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 19,
                            color: BMColors.neonCyan,
                          ),
                        ),
                        Text(
                          'از $targetCal',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildMacroBar(
                      label: 'پروتئین 🥩',
                      current: c.todayProteinConsumed,
                      target: macros['protein'] ?? 140,
                      color: BMColors.neonGreen,
                    ),
                    const SizedBox(height: 9),
                    _buildMacroBar(
                      label: 'کربوهیدرات 🍚',
                      current: c.todayCarbsConsumed,
                      target: macros['carbs'] ?? 220,
                      color: BMColors.electricBlue,
                    ),
                    const SizedBox(height: 9),
                    _buildMacroBar(
                      label: 'چربی سالم 🥑',
                      current: c.todayFatConsumed,
                      target: macros['fat'] ?? 65,
                      color: BMColors.warningAmber,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ردیاب لیوان آب روزانه
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              const Text('💧', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'آب روزانه: ${c.todayWaterGlasses} از ${c.targetWaterGlasses} لیوان',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'ثبت آب کاملاً آفلاین کار می‌کنه و استریکت رو روشن نگه می‌داره!',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => c.updateWaterGlasses(-1),
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BMColors.electricBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => c.updateWaterGlasses(1),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('۱ لیوان'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // بنر قفل ۳ مرحله‌ای هوش مصنوعی
        SmartAiLockBanner(
          controller: c,
          onNavigateTab: widget.onNavigateTab,
        ),

        // کالری‌شمار هوشمند با هوش مصنوعی (عکس غذا یا نام غذا)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BMColors.neonCyan.withOpacity(0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('📸🤖 ', style: TextStyle(fontSize: 19)),
                  Expanded(
                    child: Text(
                      'کالری‌شمار هوشمند AI (با عکس یا توضیح غذا)',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _foodAiQueryCtrl,
                decoration: const InputDecoration(
                  hintText: 'مثلاً: ۶ قاشق برنج با نصف سیخ جوجه...',
                  prefixIcon: Icon(Icons.fastfood_rounded),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BMColors.neonCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: c.isLoadingAi
                          ? null
                          : () async {
                              final txt = _foodAiQueryCtrl.text.trim();
                              if (txt.isEmpty) return;
                              final res = await c.analyzeFoodWithAi(
                                context,
                                foodDescription: txt,
                              );
                              if (res != null && mounted) {
                                setState(() => _lastAiFoodResult = res);
                              }
                            },
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: const Text(
                        'آنالیز با هوش مصنوعی',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () =>
                        _pickFoodPhotoAndAnalyze(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                  ),
                  IconButton.filledTonal(
                    onPressed: () =>
                        _pickFoodPhotoAndAnalyze(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                  ),
                ],
              ),
              if (_lastAiFoodResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BMColors.neonGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: BMColors.neonGreen),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✅ ${_lastAiFoodResult!['title']} — ${_lastAiFoodResult!['calories']} کالری',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BMColors.neonGreen,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            c.addFoodLog(
                              title: _lastAiFoodResult!['title'].toString(),
                              calories:
                                  (_lastAiFoodResult!['calories'] as num)
                                      .toInt(),
                              proteinG:
                                  (_lastAiFoodResult!['proteinG'] as num)
                                      .toInt(),
                              carbsG:
                                  (_lastAiFoodResult!['carbsG'] as num).toInt(),
                              fatG: (_lastAiFoodResult!['fatG'] as num).toInt(),
                              emoji: '🤖',
                            );
                            setState(() {
                              _lastAiFoodResult = null;
                              _foodAiQueryCtrl.clear();
                            });
                          },
                          child: const Text(
                            '➕ خوردم! ثبت در کالری امروز',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // بانک جامع تمام غذاها، خوراکی‌ها، میوه‌ها، آجیل، نوشیدنی‌ها و دسرها با کوچک‌ترین واحد ممکن!
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🥘 بانک جامع غذاها، خوراکی‌ها، نوشیدنی‌ها و تنقلات',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                'هر خوراکی با کوچک‌ترین واحد ممکن (عدد، قاشق مرباخوری، قاشق غذاخوری، کف دست، برش، لیوان، پیاله، کاسه...) تعریف شده؛ روی «➕ انتخاب مقدار» بزن تا دقیق ثبتش کنی! 👇',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.45),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bankSearchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText:
                      'جستجوی سریع خوراکی (مثلاً: تخم‌مرغ، قورمه‌سبزی، خرما، دوشاب، پیتزا...)',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _bankSearchCtrl.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _bankSearchCtrl.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear_rounded),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ComprehensiveFoodBankCatalog.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, idx) {
                    final cat = ComprehensiveFoodBankCatalog.categories[idx];
                    final selected = cat == _selectedCategory;
                    return ChoiceChip(
                      selected: selected,
                      selectedColor: BMColors.neonCyan,
                      label: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.black : null,
                        ),
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ...filteredBank.map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'واحد پایه: ۱ ${item.baseUnitName} = ${item.caloriesPerUnit} کالری (پروتئین: ${item.proteinPerUnit}g)',
                              style: const TextStyle(
                                fontSize: 11.2,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BMColors.neonGreen.withOpacity(0.18),
                          foregroundColor: BMColors.neonGreen,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () =>
                            _showGranularPortionSelectorSheet(context, item),
                        child: const Text(
                          '➕ خوردم',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (c.todayFoodLogs.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📋 خوراکی‌های ثبت‌شده امروز شما:',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                ),
                const SizedBox(height: 8),
                ...c.todayFoodLogs.map(
                  (log) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      log.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(
                      log.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      'ساعت ${log.timeLabel} • ${log.calories} کالری (پروتئین: ${log.proteinG}g)',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: BMColors.dangerRed,
                      ),
                      onPressed: () => c.removeFoodLog(log.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMacroBar({
    required String label,
    required int current,
    required int target,
    required Color color,
  }) {
    final ratio = (current / math.max(1, target)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11.5)),
            Text(
              '${current}g / ${target}g',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 12. TAB 2: 7-DAY AI MEAL PLAN (EMPTY BY DEFAULT, DIVERSE ON AI REQUEST)
// ============================================================================

class WeeklyMealPlanTab extends StatelessWidget {
  final BodyModController controller;
  final ValueChanged<int> onNavigateTab;

  const WeeklyMealPlanTab({
    super.key,
    required this.controller,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final currentDayName = BodyModController.weekDays[c.selectedDayIndex];
    final daySlots = c.weeklyMealPlan[currentDayName] ?? [];
    final bool hasPlan = c.weeklyMealPlan.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 95),
      children: [
        SmartAiLockBanner(
          controller: c,
          onNavigateTab: onNavigateTab,
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F292E), Color(0xFF151E32)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BMColors.neonCyan.withOpacity(0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('🥗📅 ', style: TextStyle(fontSize: 22)),
                  Expanded(
                    child: Text(
                      'برنامه غذایی ۷ روزه متنوع با هوش مصنوعی',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'هدف: ${AppConfig.goalLabel(c.profile.goal)} • بودجه: ${AppConfig.budgetLabel(c.profile.budgetTier)}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BMColors.neonCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: c.isLoadingAi
                      ? null
                      : () async {
                          final ok = await c.requestAiWeeklyMealPlan(context);
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'برنامه غذایی ۷ روزه کاملاً متنوع (شنبه تا جمعه) بر اساس بودجه و اطلاعاتت ساخته شد! 🔥🥗',
                                ),
                              ),
                            );
                          }
                        },
                  icon: c.isLoadingAi
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 19),
                  label: Text(
                    hasPlan
                        ? 'درخواست چینش مجدد برنامه ۷ روزه متنوع از AI 🔄'
                        : 'دریافت برنامه غذایی ۷ روزه متنوع از هوش مصنوعی 🚀',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // اگر کاربر هنوز درخواست برنامه نداده است، برنامه پیش‌فرض نمایش داده نمی‌شود!
        if (!hasPlan)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: const Column(
              children: [
                Text('🍽️🤖', style: TextStyle(fontSize: 44)),
                SizedBox(height: 12),
                Text(
                  'هنوز برنامه غذایی هوشمندت رو دریافت نکردی رفیق!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                SizedBox(height: 8),
                Text(
                  'ما هیچ برنامه تکراری و پیش‌فرضی برات نمی‌ذاریم! بعد از باز کردن قفل ۳ مرحله‌ای، روی دکمه بالا بزن تا هوش مصنوعی بر اساس بودجه ماهانه، هدف و حافظه مربی، ۷ روز غذای کاملاً متفاوت و متنوع برات بچینه! 🔥💪',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.8,
                    color: Colors.grey,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          )
        else ...[
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: BodyModController.weekDays.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final day = BodyModController.weekDays[idx];
                final selected = idx == c.selectedDayIndex;
                return ChoiceChip(
                  selected: selected,
                  selectedColor: BMColors.neonCyan,
                  label: Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: selected ? Colors.black : null,
                    ),
                  ),
                  onSelected: (_) {
                    c.selectedDayIndex = idx;
                    c.notifyListeners();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(daySlots.length, (slotIdx) {
            final slot = daySlots[slotIdx];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: slot.isEatenToday
                      ? BMColors.neonGreen
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(slot.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          slot.mealType,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13.8,
                            color: BMColors.neonCyan,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: BMColors.flameOrange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${slot.calories} kcal',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                            color: BMColors.flameOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    slot.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '💡 ${slot.ingredientsTip}',
                    style: const TextStyle(fontSize: 11.8, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '🥩 پروتئین: ${slot.proteinG}g | 🍚 کربو: ${slot.carbsG}g | 🥑 چربی: ${slot.fatG}g',
                          style: const TextStyle(
                            fontSize: 11.2,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: slot.isEatenToday
                              ? BMColors.neonGreen
                              : BMColors.neonCyan.withOpacity(0.18),
                          foregroundColor: slot.isEatenToday
                              ? Colors.black
                              : BMColors.neonCyan,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                        ),
                        onPressed: () {
                          c.markMealSlotAsEaten(currentDayName, slotIdx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'نوش جونت رفیق! «${slot.mealType}» به کالری امروزت اضافه شد 🔥😋',
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          slot.isEatenToday
                              ? Icons.check_circle_rounded
                              : Icons.add_rounded,
                          size: 16,
                        ),
                        label: Text(
                          slot.isEatenToday ? 'ثبت شد ✅' : '➕ خوردم',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

// ============================================================================
// 13. TAB 3: LIVE STEP-BY-STEP WORKOUT PLAYER & SMART REST WARNINGS
// ============================================================================

class WorkoutAndLivePlayerTab extends StatefulWidget {
  final BodyModController controller;
  final ValueChanged<int> onNavigateTab;

  const WorkoutAndLivePlayerTab({
    super.key,
    required this.controller,
    required this.onNavigateTab,
  });

  @override
  State<WorkoutAndLivePlayerTab> createState() =>
      _WorkoutAndLivePlayerTabState();
}

class _WorkoutAndLivePlayerTabState extends State<WorkoutAndLivePlayerTab> {
  int _activeStepIndex = 0;
  int _currentSet = 1;
  bool _isResting = false;
  int _restElapsedSeconds = 0;
  Timer? _restTimer;
  String? _restCoachWarning;

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restElapsedSeconds = 0;
      _restCoachWarning = null;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _restElapsedSeconds += 1;
        if (_restElapsedSeconds > 120) {
          _restCoachWarning =
              '❄️ هشدار سرد شدن بدن: رفیق بیشتر از ۲ دقیقه استراحت کردی! ضربان قلبت افتاده و پمپ عضلاتت داره می‌خوابه؛ سریع ست بعدی رو شروع کن! 🔥💪';
        }
      });
    });
  }

  void _finishRestAndProceed(WorkoutExerciseStep currentStep) {
    final rested = _restElapsedSeconds;
    _restTimer?.cancel();

    String? warning;
    if (rested < 20) {
      warning =
          '⚠️ هشدار تجمع اسید لاکتیک: کمتر از ۲۰ ثانیه ($rested ثانیه) استراحت کردی قهرمان! ذخایر ATP عضلت هنوز پر نشده و وسط ست بعدی کم میاری؛ حداقل ۳۰ تا ۶۰ ثانیه نفس عمیق بکش! 🫁';
    } else if (rested > 120) {
      warning =
          '❄️ استراحتت طولانی شد ($rested ثانیه)؛ حواست باشه بین ست‌ها بدنت سرد نشه! 😂🔥';
    }

    setState(() {
      _isResting = false;
      _restCoachWarning = warning;
      if (_currentSet < currentStep.sets) {
        _currentSet += 1;
      } else {
        if (_activeStepIndex < widget.controller.workoutSteps.length - 1) {
          _activeStepIndex += 1;
          _currentSet = 1;
        } else {
          _activeStepIndex = 0;
          _currentSet = 1;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'دمت گرم قهرمان! کل تمرین امروز (گرم کردن + ست‌های اصلی + سرد کردن) رو ترکوندی! 🏆🔥💪',
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final steps = c.workoutSteps;
    if (steps.isEmpty) return const SizedBox.shrink();

    final safeIdx = _activeStepIndex.clamp(0, steps.length - 1);
    final activeStep = steps[safeIdx];

    Color phaseColor = BMColors.neonCyan;
    if (activeStep.phase == 'warmup') {
      phaseColor = BMColors.flameOrange;
    } else if (activeStep.phase == 'cooldown') {
      phaseColor = BMColors.electricBlue;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 95),
      children: [
        Row(
          children: [
            _buildPhaseBadge(
              title: '۱. گرم کردن 🔥',
              active: activeStep.phase == 'warmup',
              color: BMColors.flameOrange,
            ),
            const SizedBox(width: 6),
            _buildPhaseBadge(
              title: '۲. ست‌های اصلی 💪',
              active: activeStep.phase == 'main',
              color: BMColors.neonCyan,
            ),
            const SizedBox(width: 6),
            _buildPhaseBadge(
              title: '۳. سرد کردن ❄️',
              active: activeStep.phase == 'cooldown',
              color: BMColors.electricBlue,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [phaseColor.withOpacity(0.18), const Color(0xFF111827)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: phaseColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      activeStep.phaseTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: phaseColor,
                      ),
                    ),
                  ),
                  Text(
                    'حرکت ${safeIdx + 1} از ${steps.length}',
                    style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                activeStep.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '🎯 عضله هدف: ${activeStep.muscleGroup} • تکرار: ${activeStep.repsOrDuration}',
                style: const TextStyle(fontSize: 12.5, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(activeStep.sets, (idx) {
                  final setNum = idx + 1;
                  final done = setNum < _currentSet;
                  final isCurrent = setNum == _currentSet;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: done
                            ? BMColors.neonGreen.withOpacity(0.25)
                            : isCurrent
                            ? phaseColor.withOpacity(0.28)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: done
                              ? BMColors.neonGreen
                              : isCurrent
                              ? phaseColor
                              : Colors.white12,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        done ? 'ست $setNum ✅' : 'ست $setNum',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                          color: done
                              ? BMColors.neonGreen
                              : isCurrent
                              ? Colors.white
                              : Colors.white54,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🫁 ریتم تنفس: ${activeStep.breathingGuide}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: BMColors.neonCyan,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '💡 نکته مربی: ${activeStep.coachNote}',
                      style: const TextStyle(
                        fontSize: 11.8,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (_restCoachWarning != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: BMColors.dangerRed.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BMColors.dangerRed),
                  ),
                  child: Text(
                    _restCoachWarning!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFB4AB),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (_isResting)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF090D16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _restElapsedSeconds < 20
                          ? BMColors.warningAmber
                          : _restElapsedSeconds <= 120
                          ? BMColors.neonGreen
                          : BMColors.electricBlue,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '⏱️ زمان استراحت: $_restElapsedSeconds ثانیه (هدف: ${activeStep.targetRestSeconds} ثانیه)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BMColors.neonGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _finishRestAndProceed(activeStep),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text(
                            'پایان استراحت و شروع ست بعدی 💪🔥',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: phaseColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _startRestTimer,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      'ست $_currentSet رو زدم! (شروع تایمر استراحت ⏱️)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
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

  Widget _buildPhaseBadge({
    required String title,
    required bool active,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.22) : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? color : Colors.white12),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            color: active ? color : Colors.white60,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 14. TAB 4: AI COACH CHAT (WITH LONG-PRESS TOKEN PREVIEW) & BODY PROGRESS LOG
// ============================================================================

class BodyAndAiCoachTab extends StatefulWidget {
  final BodyModController controller;
  final ValueChanged<int> onNavigateTab;

  const BodyAndAiCoachTab({
    super.key,
    required this.controller,
    required this.onNavigateTab,
  });

  @override
  State<BodyAndAiCoachTab> createState() => _BodyAndAiCoachTabState();
}

class _BodyAndAiCoachTabState extends State<BodyAndAiCoachTab> {
  final TextEditingController _chatInputCtrl = TextEditingController();
  final TextEditingController _weightInputCtrl = TextEditingController();
  final TextEditingController _bodyNoteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _weightInputCtrl.text = (('75' == (widget.controller.profile.weightKg.toString()).toString().trim() || '75.0' == (widget.controller.profile.weightKg.toString()).toString().trim() || '60' == (widget.controller.profile.weightKg.toString()).toString().trim() || '60.0' == (widget.controller.profile.weightKg.toString()).toString().trim() || '0' == (widget.controller.profile.weightKg.toString()).toString().trim()) ? '' : (widget.controller.profile.weightKg.toString()).toString());
  }

  @override
  void dispose() {
    _chatInputCtrl.dispose();
    _weightInputCtrl.dispose();
    _bodyNoteCtrl.dispose();
    super.dispose();
  }

  void _showBodyCoinLongPressPreview(BuildContext context) {
    final c = widget.controller;
    final draft = _chatInputCtrl.text.trim().isEmpty
        ? 'پیام نمونه به مربی هوشمند'
        : _chatInputCtrl.text.trim();
    final est = AppConfig.estimateTokenAndCoinCost(
      draft,
      memoryText: c.profile.aiCoachMemory,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BMColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: BMColors.whaleGold, width: 1.5),
        ),
        title: const Row(
          children: [
            Text('🪙⚡ ', style: TextStyle(fontSize: 20)),
            Expanded(
              child: Text(
                'پیش‌نمایش مصرف توکن و بادی‌کوین',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• توکن ورودی: ${est['inputTokens']} توکن'),
            Text('• توکن خروجی تخمینی: ${est['outputTokens']} توکن'),
            Text('• مجموع کل: ${est['tokens']} توکن'),
            const Divider(height: 18),
            Text(
              '🪙 معادل بادی‌کوین: ${est['coins']} کوین',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: BMColors.whaleGold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 95),
      children: [
        SmartAiLockBanner(
          controller: c,
          onNavigateTab: widget.onNavigateTab,
        ),

        // انتخاب مدل هوش مصنوعی (3.5 Flash Lite یا 3.8 Flash)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🤖 گفتگو با مربی هوشمند بادی‌مود',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    selected:
                        c.profile.preferredModel == 'gemini-3.5-flash-lite',
                    selectedColor: BMColors.neonCyan,
                    label: Text(
                      '3.5 Flash Lite ⚡ (${c.remainingLiteChatQuota}/${c.maxLiteChatQuota})',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color:
                            c.profile.preferredModel == 'gemini-3.5-flash-lite'
                            ? Colors.black
                            : null,
                      ),
                    ),
                    onSelected: (_) {
                      c.profile.preferredModel = 'gemini-3.5-flash-lite';
                      c.saveAllToDisk();
                      c.notifyListeners();
                    },
                  ),
                  ChoiceChip(
                    selected: c.profile.preferredModel == 'gemini-3.8-flash',
                    selectedColor: BMColors.purpleAccent,
                    label: Text(
                      '3.8 Flash 🧠 (${c.remainingFlashChatQuota}/${c.maxFlashChatQuota})',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: c.profile.preferredModel == 'gemini-3.8-flash'
                            ? Colors.white
                            : null,
                      ),
                    ),
                    onSelected: (_) {
                      c.profile.preferredModel = 'gemini-3.8-flash';
                      c.saveAllToDisk();
                      c.notifyListeners();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: c.chatMessages.length,
                  itemBuilder: (context, idx) {
                    final msg = c.chatMessages[idx];
                    return Align(
                      alignment: msg.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 9),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        decoration: BoxDecoration(
                          color: msg.isUser
                              ? (c.isDarkMode
                                    ? BMColors.neonCyan.withOpacity(0.18)
                                    : const Color(0xFFCCFBF1))
                              : (c.isDarkMode
                                    ? const Color(0xFF0E1525)
                                    : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: msg.isUser
                                ? BMColors.neonCyan.withOpacity(0.6)
                                : (c.isDarkMode
                                      ? Colors.white12
                                      : const Color(0xFFCBD5E1)),
                          ),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.55,
                            color: c.isDarkMode
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatInputCtrl,
                      decoration: const InputDecoration(
                        hintText: 'سوال از مربی هوشمند...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    /* onLongPress: () => _showBodyCoinLongPressPreview(context), */
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BMColors.neonCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 13,
                        ),
                      ),
                      onPressed: c.isLoadingAi
                          ? null
                          : () {
                              final txt = _chatInputCtrl.text.trim();
                              if (txt.isEmpty) return;
                              _chatInputCtrl.clear();
                              c.sendChatMessageToCoach(context, txt);
                            },
                      child: const Text(
                        '🚀 ارسال',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ثبت پیشرفت وزن و BMI
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📊 شاخص توده بدنی فعلی (BMI): ${c.profile.bmi.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  color: BMColors.neonCyan,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _weightInputCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ثبت وزن جدید این هفته (کیلوگرم)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyNoteCtrl,
                decoration: const InputDecoration(
                  labelText: 'یادداشت پیشرفت (اختیاری)',
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BMColors.neonGreen,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    final w =
                        double.tryParse(_weightInputCtrl.text) ??
                        c.profile.weightKg;
                    c.addBodyMetricRecord(
                      weightKg: w,
                      note: _bodyNoteCtrl.text.trim(),
                    );
                    _bodyNoteCtrl.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('وزن جدیدت در تاریخچه ثبت شد قهرمان! 📈🔥'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_chart_rounded),
                  label: const Text(
                    'ثبت در تاریخچه پیشرفت بدن',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              if (c.bodyLogsHistory.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...c.bodyLogsHistory.reversed.map(
                  (rec) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Text('📏', style: TextStyle(fontSize: 20)),
                    title: Text(
                      '${rec.dateLabel} — وزن: ${rec.weightKg} kg (BMI: ${rec.bmi})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      rec.note,
                      style: const TextStyle(fontSize: 11.5),
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

// ============================================================================
// 15. TAB 5: PROFILE, SUBSCRIPTION (189K), DONATIONS & SECRET CEO ADMIN PANEL
// ============================================================================

class ProfileAndBillingTab extends StatefulWidget {
  final BodyModController controller;
  final ValueChanged<int> onNavigateTab;

  const ProfileAndBillingTab({
    super.key,
    required this.controller,
    required this.onNavigateTab,
  });

  @override
  State<ProfileAndBillingTab> createState() => _ProfileAndBillingTabState();
}

class _ProfileAndBillingTabState extends State<ProfileAndBillingTab> {
  final TextEditingController _discountInputCtrl = TextEditingController();
  final TextEditingController _ceoNewCodeCtrl = TextEditingController();
  final TextEditingController _ceoNewPercentCtrl = TextEditingController(
    text: '30',
  );

  @override
  void dispose() {
    _discountInputCtrl.dispose();
    _ceoNewCodeCtrl.dispose();
    _ceoNewPercentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 95),
      children: [
        // ۱. کارت وضعیت حساب کاربری (ورود ۲ مرحله‌ای با گوگل یا شماره موبایل)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BMColors.neonCyan.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: BMColors.neonCyan.withOpacity(0.18),
                    child: Text(
                      c.profile.isLoggedIn ? '✅' : '🔐',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.profile.isLoggedIn
                              ? 'حساب فعال: ${c.profile.userKey}'
                              : 'هنوز وارد حسابت نشدی رفیق!',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          c.profile.isLoggedIn
                              ? 'اطلاعاتت با سرور کلودفلر سینک و امنه ☁️✨'
                              : 'با جیمیل یا شماره موبایل وارد شو تا اطلاعاتت هیچ‌وقت نپره!',
                          style: const TextStyle(
                            fontSize: 11.8,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: c.profile.isLoggedIn
                    ? OutlinedButton.icon(
                        onPressed: () => c.signOutAccount(),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('خروج از حساب کاربری'),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BMColors.neonCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () => c.openTwoStepAuthModal(
                          context,
                          onNavigateHome: () => widget.onNavigateTab(0),
                        ),
                        icon: const Icon(Icons.login_rounded),
                        label: const Text(
                          'ورود یا ثبت‌نام (گوگل / شماره موبایل) 🚀',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ۲. کارت اشتراک ۱ ماهه (۱۸۹ هزار تومان) با تمدید تجمعی روز ۲۸ تا ۳۱ + کد تخفیف کانال
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BMColors.whaleGold.withOpacity(0.65)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '💎 اشتراک ۱ ماهه بادی‌مود (۱۸۹,۰۰۰ تومان در ماه)',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: BMColors.whaleGold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                c.profile.isAdmin
                    ? '👑 حساب مدیرعامل: اشتراک نامحدود VIP شما روی سرور کلودفلر فعاله!'
                    : c.profile.hasActiveSubscription
                    ? '✅ اشتراک شما فعاله (${c.profile.subscriptionDaysRemaining} روز باقی‌مانده). تمدید اشتراک در روزهای ۲۸ تا ۳۱ باز می‌شه و روزهای باقی‌مانده روی ماه جدیدت اضافه می‌شه!'
                    : 'با فعال‌سازی اشتراک ۱ ماهه، قفل تمام بخش‌های هوش مصنوعی (برنامه غذایی ۷ روزه متنوع، کالری‌شمار تصویری و مربی هوشمند) باز می‌شه! 🔥',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Colors.white70,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 12),

              // کادر کد تخفیف کانال @bodymod_channel
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _discountInputCtrl,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        hintText: 'کد تخفیف کانال @bodymod_channel',
                        prefixIcon: Icon(Icons.discount_outlined, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BMColors.neonCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                    ),
                    onPressed: () async {
                      final code = _discountInputCtrl.text.trim();
                      if (code.isEmpty) return;
                      final res = await c.applyChannelDiscountCode(
                        context,
                        code,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res['message']?.toString() ?? ''),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'اعمال کد',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              if (c.appliedDiscountPercent > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '🎉 کد تخفیف ${c.appliedDiscountPercent}% اعمال شد! مبلغ قابل پرداخت: ${c.discountedSubscriptionPriceToman} تومان',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: BMColors.neonGreen,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (!c.profile.isAdmin)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.profile.canPurchaseOrRenewSubscription
                          ? BMColors.whaleGold
                          : Colors.white24,
                      foregroundColor: c.profile.canPurchaseOrRenewSubscription
                          ? Colors.black
                          : Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () =>
                        c.purchaseOrRenewMonthlySubscription(context),
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: Text(
                      !c.profile.hasActiveSubscription
                          ? 'خرید اشتراک ۱ ماهه (${c.discountedSubscriptionPriceToman} تومان) 🔥'
                          : c.profile.canPurchaseOrRenewSubscription
                          ? 'تمدید اشتراک ۱ ماهه (+ حفظ ${c.profile.subscriptionDaysRemaining} روز باقی‌مانده) 🔄'
                          : 'اشتراک فعاله (${c.profile.subscriptionDaysRemaining} روز مانده — تمدید در روز ۲۸ تا ۳۱)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ۳. بخش حمایت مالی چندباره و نامحدود (Consumable IAP برای خروج سریع‌تر از فاز بتا)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BMColors.neonGreen.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('❤️🚀 ', style: TextStyle(fontSize: 20)),
                  Expanded(
                    child: Text(
                      'حمایت مالی برای خروج سریع‌تر از فاز بتا',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: BMColors.neonGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'برای اینکه سریع‌تر سرورهای اختصاصی و API نامحدود بگیریم و از فاز بتا خارج بشیم، می‌تونی هر چند بار که دوست داشتی از بادی‌مود حمایت کنی (مبالغ زیر بدون محدودیت و قابل خرید چندباره هستن!): 🙏🔥',
                style: TextStyle(fontSize: 12.2, color: Colors.grey, height: 1.55),
              ),
              const SizedBox(height: 12),
              ...AppConfig.donationTiers.map((tier) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: BMColors.neonGreen.withOpacity(0.6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      onPressed: () => c.purchaseRepeatableDonation(
                        context,
                        sku: tier['sku'].toString(),
                        amountToman: (tier['amount'] as num).toInt(),
                        label: tier['label'].toString(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tier['label'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${tier['desc']} (خرید چندباره ➕)',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: BMColors.neonCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ۴. فرم قابل ویرایش پرونده بدنی + حافظه بلندمدت هوش مصنوعی
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📋 ویرایش فرم مشخصات بدنی و حافظه هوش مصنوعی',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 12),
              EditableBodyProfileFormWidget(controller: c),
            ],
          ),
        ),

        // ۵. پنل فرماندهی کاملاً محرمانه مدیرعامل (فقط وقتی کلودفلر تایید کند اکانت متین است نمایش داده می‌شود!)
        if (c.profile.isAdmin) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1322),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: BMColors.whaleGold, width: 1.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        '👑 پنل محرمانه مدیرعامل و ردیاب نهنگ‌ها 🐋',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: BMColors.whaleGold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'بروزرسانی آمار زنده از کلودفلر',
                      onPressed: () => c.fetchCeoAdminLiveStats(),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: BMColors.neonCyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '🔒 این بخش ۱۰۰٪ مخفی است و فقط برای جیمیل و شماره موبایل مدیرعامل در سرور کلودفلر فعال می‌شود.',
                  style: TextStyle(fontSize: 11.5, color: BMColors.neonCyan),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B2F0B), Color(0xFF1E293B)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BMColors.whaleGold),
                  ),
                  child: Row(
                    children: [
                      const Text('🐋', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ویژه (VIP) بالای ۱۰۰ میلیون تومن (نهنگ‌ها)',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                                color: BMColors.whaleGold,
                              ),
                            ),
                            Text(
                              '${c.adminTierVipWhalesCount} نفر ثبت‌شده در کلودفلر KV',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ceoTile(
                        'کل کاربران',
                        '${c.adminTotalUsers} نفر',
                        BMColors.neonCyan,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ceoTile(
                        'مشترکین فعال',
                        '${c.adminActiveSubscribers} / ۱۰۰۰',
                        BMColors.neonGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ceoTile(
                        'پایه (<۲۰ میلیون)',
                        '${c.adminTierBaseCount} نفر',
                        BMColors.warningAmber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ceoTile(
                        'میان‌رده (۲۰ تا ۵۰)',
                        '${c.adminTierMidCount} نفر',
                        BMColors.electricBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ceoTile(
                        'پرچمدار (۵۰ تا ۱۰۰)',
                        '${c.adminTierFlagshipCount} نفر',
                        BMColors.purpleAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ceoTile(
                        'مجموع حمایت‌ها ❤️',
                        '${c.adminTotalDonationsToman} ت',
                        BMColors.flameOrange,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 22),
                const Text(
                  '🎁 ساخت کد تخفیف جدید برای انتشار در @bodymod_channel:',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.8,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _ceoNewCodeCtrl,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'کد (مثلاً BM50)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _ceoNewPercentCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'درصد %'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BMColors.whaleGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                      ),
                      onPressed: () async {
                        final msg = await c.createCeoDiscountCode(
                          code: _ceoNewCodeCtrl.text,
                          percent: int.tryParse(_ceoNewPercentCtrl.text) ?? 20,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(msg)));
                        }
                      },
                      child: const Text(
                        'ثبت کد',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _ceoTile(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
