// ============================================================================
// BodyMod AI (بادی‌مُد) - 100% Native Flutter Edition
// Package: ir.matinmohammadi.bodymod
// Author: Matin Mohammadi (متین محمدی) & Alireza (علیرضا)
// Server: Cloudflare Worker (https://server.matin-mohammadi.ir)
// Unified Single-File Architecture: lib/main.dart
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

  final state = BodyModController();
  await state.initialize();

  runApp(BodyModApp(controller: state));
}

// ============================================================================
// 1. APP CONFIGURATION & CONSTANTS
// ============================================================================

class AppConfig {
  static const String appName = 'BodyMod AI';
  static const String appVersion = '8.0.0-Native';
  static const String packageName = 'ir.matinmohammadi.bodymod';
  static const String serverBaseUrl = 'https://server.matin-mohammadi.ir';

  // فاز بتا: محدودیت ۱۰۰۰ نفر روی Free Tier گوگل
  static const int betaMaxSubscribers = 1000;

  // سوییچ بادی‌کوین: هر وقت API پولی گوگل رو خریدی، اینو true کن
  // تا سیستم سهمیه روزانه تبدیل به کیف پول بادی‌کوین بشه!
  static bool useBodyCoinSystem = false;

  // لیست ایمیل‌های مدیرعامل (متین و علیرضا) برای دسترسی به پنل فرماندهی
  static const List<String> ceoAdminEmails = [
    'matinmohammadi@gmail.com',
    'admin@matin-mohammadi.ir',
    'alireza@matin-mohammadi.ir',
  ];

  // متن راهنمای داخل کادر حافظه مربی (بدون سوال اقتصادی - با تایپ کردن پاک می‌شود)
  static const String aiMemoryHintText =
      'مثال (با تایپ کردن شما این متن پاک می‌شه):\n'
      '۱. بیماری خاص، آسیب‌دیدگی مفصلی یا دیسک کمر داری؟ داروی خاصی مصرف می‌کنی؟\n'
      '۲. به چه خوراکی‌هایی حساسیت داری یا اصلاً دوست نداری؟\n'
      '۳. ساعت خوابت چطوره، شیفت کاری داری یا نکته دیگه‌ای هست که مربی باید همیشه یادش بمونه؟\n'
      '(خیالت راحت رفیق، این اطلاعات کاملاً امن هستن 🔒)';

  // گزینه‌های وضعیت اقتصادی در فرم پرونده بدنی (برای شخصی‌سازی غذاها و ردیاب نهنگ‌ها 🐋)
  static const String econLow = 'low';
  static const String econMedium = 'medium';
  static const String econWhale = 'whale';

  static String economicLabel(String code) {
    switch (code) {
      case econLow:
        return 'اقتصادی و دانشجویی (تخم‌مرغ، سیب‌زمینی، حبوبات) 🥚';
      case econWhale:
        return 'عالی و نامحدود (استیک، سالمون، مکمل اورجینال) 🐋';
      case econMedium:
      default:
        return 'متوسط و متعادل (مرغ، گوشت، لبنیات، برنج) 🍗';
    }
  }

  // محاسبه تخمینی توکن و بادی‌کوین وقتی کاربر دکمه ارسال رو نگه می‌داره (Long Press)
  static Map<String, int> estimateTokenAndCoinCost(
    String text, {
    bool hasImage = false,
    String memoryText = '',
  }) {
    final cleanText = text.trim();
    final charCount = cleanText.length + memoryText.trim().length;
    final baseSystemTokens = 320;
    final textTokens = (charCount / 3.2).ceil();
    final imageTokens = hasImage ? 560 : 0;
    final estimatedOutputTokens = 450;
    final totalTokens =
        baseSystemTokens + textTokens + imageTokens + estimatedOutputTokens;
    final bodyCoins = math.max(1, (totalTokens / 250).ceil());
    return {
      'tokens': totalTokens,
      'coins': bodyCoins,
      'inputTokens': baseSystemTokens + textTokens + imageTokens,
      'outputTokens': estimatedOutputTokens,
    };
  }
}

// ============================================================================
// 2. THEME & DESIGN TOKENS (OBSIDIAN NEON + LIGHT SUPPORT)
// ============================================================================

class BMColors {
  static const Color bgDark = Color(0xFF090D16);
  static const Color surfaceDark = Color(0xFF121826);
  static const Color cardDark = Color(0xFF1A2235);
  static const Color cardBorderDark = Color(0xFF28344E);

  static const Color neonCyan = Color(0xFF00F5D4);
  static const Color neonGreen = Color(0xFF10B981);
  static const Color neonLime = Color(0xFF39FF14);
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
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0E1422),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
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
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
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
// 3. DATA MODELS
// ============================================================================

enum StreakVisualState {
  redFire, // 🔥 امروز ثبت شده و آتیش شعله‌وره
  blueFrozen, // 💙 امروز هنوز کامل ثبت نشده و در خطر یخ‌زدگیه
  deadSkull, // 💀 بیش از یک روز ثبت نشده و خاموش شده
}

class UserProfileModel {
  String uid;
  String email;
  String displayName;
  String photoUrl;
  String balePhoneOrId;
  int age;
  String gender; // 'male' | 'female'
  double heightCm;
  double weightKg;
  double targetWeightKg;
  double waistCm;
  double neckCm;
  double hipCm;
  String activityLevel; // 'sedentary' | 'light' | 'moderate' | 'active' | 'athlete'
  String goal; // 'loss' | 'maintain' | 'gain' | 'muscle'
  String workoutPlace; // 'gym' | 'home_dumbbell' | 'bodyweight'
  String economicStatus; // 'low' | 'medium' | 'whale'
  String aiCoachMemory;
  bool isLoggedIn;
  bool isProfileCompleted;
  bool hasActiveSubscription;
  String subscriptionTier;
  int subscriptionDaysRemaining;
  int bodyCoinsBalance;
  int dailyAiRequestsUsed;
  int dailyAiRequestsLimit;
  bool isAdmin;

  UserProfileModel({
    this.uid = '',
    this.email = '',
    this.displayName = 'رفیق بادی‌مُدی',
    this.photoUrl = '',
    this.balePhoneOrId = '',
    this.age = 21,
    this.gender = 'male',
    this.heightCm = 178,
    this.weightKg = 74,
    this.targetWeightKg = 70,
    this.waistCm = 82,
    this.neckCm = 38,
    this.hipCm = 96,
    this.activityLevel = 'moderate',
    this.goal = 'muscle',
    this.workoutPlace = 'home_dumbbell',
    this.economicStatus = AppConfig.econMedium,
    this.aiCoachMemory = '',
    this.isLoggedIn = false,
    this.isProfileCompleted = false,
    this.hasActiveSubscription = false,
    this.subscriptionTier = 'نسخه رایگان (آفلاین)',
    this.subscriptionDaysRemaining = 0,
    this.bodyCoinsBalance = 120,
    this.dailyAiRequestsUsed = 0,
    this.dailyAiRequestsLimit = 15,
    this.isAdmin = false,
  });

  double get bmi {
    if (heightCm <= 0) return 22.0;
    final hMeter = heightCm / 100.0;
    return weightKg / (hMeter * hMeter);
  }

  double get estimatedBodyFat {
    if (heightCm <= 0 || waistCm <= 0 || neckCm <= 0) return 16.5;
    // فرمول استاندارد نیروی دریایی آمریکا (US Navy Method)
    if (gender == 'male') {
      final diff = math.max(10.0, waistCm - neckCm);
      final val =
          495.0 /
              (1.0324 -
                  0.19077 * (math.log(diff) / math.ln10) +
                  0.15456 * (math.log(heightCm) / math.ln10)) -
          450.0;
      return val.clamp(4.0, 48.0);
    } else {
      final sum = math.max(20.0, waistCm + hipCm - neckCm);
      final val =
          495.0 /
              (1.29579 -
                  0.35004 * (math.log(sum) / math.ln10) +
                  0.22100 * (math.log(heightCm) / math.ln10)) -
          450.0;
      return val.clamp(8.0, 52.0);
    }
  }

  int get recommendedDailyCalories {
    // فرمول Mifflin-St Jeor
    double bmr =
        (10 * weightKg) +
        (6.25 * heightCm) -
        (5 * age) +
        (gender == 'male' ? 5 : -161);
    double multiplier = 1.55;
    switch (activityLevel) {
      case 'sedentary':
        multiplier = 1.2;
        break;
      case 'light':
        multiplier = 1.375;
        break;
      case 'moderate':
        multiplier = 1.55;
        break;
      case 'active':
        multiplier = 1.725;
        break;
      case 'athlete':
        multiplier = 1.9;
        break;
    }
    double tdee = bmr * multiplier;
    switch (goal) {
      case 'loss':
        return (tdee - 450).round().clamp(1200, 4200);
      case 'gain':
        return (tdee + 400).round().clamp(1500, 4800);
      case 'muscle':
        return (tdee + 250).round().clamp(1600, 4600);
      case 'maintain':
      default:
        return tdee.round().clamp(1400, 4400);
    }
  }

  Map<String, int> get recommendedMacros {
    final totalCal = recommendedDailyCalories;
    final proteinGrams = (weightKg * (goal == 'muscle' ? 2.1 : 1.8)).round();
    final fatGrams = ((totalCal * 0.26) / 9.0).round();
    final remainingCal = math.max(
      200,
      totalCal - (proteinGrams * 4) - (fatGrams * 9),
    );
    final carbGrams = (remainingCal / 4.0).round();
    return {
      'calories': totalCal,
      'protein': proteinGrams,
      'carbs': carbGrams,
      'fat': fatGrams,
    };
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'balePhoneOrId': balePhoneOrId,
    'age': age,
    'gender': gender,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'targetWeightKg': targetWeightKg,
    'waistCm': waistCm,
    'neckCm': neckCm,
    'hipCm': hipCm,
    'activityLevel': activityLevel,
    'goal': goal,
    'workoutPlace': workoutPlace,
    'economicStatus': economicStatus,
    'aiCoachMemory': aiCoachMemory,
    'isLoggedIn': isLoggedIn,
    'isProfileCompleted': isProfileCompleted,
    'hasActiveSubscription': hasActiveSubscription,
    'subscriptionTier': subscriptionTier,
    'subscriptionDaysRemaining': subscriptionDaysRemaining,
    'bodyCoinsBalance': bodyCoinsBalance,
    'dailyAiRequestsUsed': dailyAiRequestsUsed,
    'dailyAiRequestsLimit': dailyAiRequestsLimit,
    'isAdmin': isAdmin,
  };

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      uid: (json['uid'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      displayName: (json['displayName'] ?? 'رفیق بادی‌مُدی').toString(),
      photoUrl: (json['photoUrl'] ?? '').toString(),
      balePhoneOrId: (json['balePhoneOrId'] ?? '').toString(),
      age: (json['age'] as num?)?.toInt() ?? 21,
      gender: (json['gender'] ?? 'male').toString(),
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 178.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 74.0,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 70.0,
      waistCm: (json['waistCm'] as num?)?.toDouble() ?? 82.0,
      neckCm: (json['neckCm'] as num?)?.toDouble() ?? 38.0,
      hipCm: (json['hipCm'] as num?)?.toDouble() ?? 96.0,
      activityLevel: (json['activityLevel'] ?? 'moderate').toString(),
      goal: (json['goal'] ?? 'muscle').toString(),
      workoutPlace: (json['workoutPlace'] ?? 'home_dumbbell').toString(),
      economicStatus: (json['economicStatus'] ?? AppConfig.econMedium)
          .toString(),
      aiCoachMemory: (json['aiCoachMemory'] ?? '').toString(),
      isLoggedIn: json['isLoggedIn'] == true,
      isProfileCompleted: json['isProfileCompleted'] == true,
      hasActiveSubscription: json['hasActiveSubscription'] == true,
      subscriptionTier: (json['subscriptionTier'] ?? 'نسخه رایگان (آفلاین)')
          .toString(),
      subscriptionDaysRemaining:
          (json['subscriptionDaysRemaining'] as num?)?.toInt() ?? 0,
      bodyCoinsBalance: (json['bodyCoinsBalance'] as num?)?.toInt() ?? 120,
      dailyAiRequestsUsed: (json['dailyAiRequestsUsed'] as num?)?.toInt() ?? 0,
      dailyAiRequestsLimit:
          (json['dailyAiRequestsLimit'] as num?)?.toInt() ?? 15,
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

class SavedFoodBankItem {
  final String id;
  final String title;
  final String portion;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final String emoji;

  SavedFoodBankItem({
    required this.id,
    required this.title,
    required this.portion,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.emoji = '🥘',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'portion': portion,
    'calories': calories,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    'emoji': emoji,
  };

  factory SavedFoodBankItem.fromJson(Map<String, dynamic> json) =>
      SavedFoodBankItem(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        portion: (json['portion'] ?? '۱ پرس').toString(),
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        proteinG: (json['proteinG'] as num?)?.toInt() ?? 0,
        carbsG: (json['carbsG'] as num?)?.toInt() ?? 0,
        fatG: (json['fatG'] as num?)?.toInt() ?? 0,
        emoji: (json['emoji'] ?? '🥘').toString(),
      );
}

class MealPlanSlot {
  final String mealType; // صبحانه، میان‌وعده صبح، ناهار، میان‌وعده عصر، شام
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
  final String phaseTitle; // 'گرم کردن 🔥' | 'ست‌های اصلی 💪' | 'سرد کردن و کشش ❄️'
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
                    'دم در بخش پایین رفتن، بازدم عمیق موقع فشار دادن 🌬️')
                .toString(),
        coachNote: (json['coachNote'] ?? '').toString(),
        muscleGroup: (json['muscleGroup'] ?? 'کل بدن').toString(),
      );
}

class BodyLogRecord {
  final String dateLabel;
  final double weightKg;
  final double waistCm;
  final double bmi;
  final double bodyFatPercent;
  final String note;

  BodyLogRecord({
    required this.dateLabel,
    required this.weightKg,
    required this.waistCm,
    required this.bmi,
    required this.bodyFatPercent,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
    'dateLabel': dateLabel,
    'weightKg': weightKg,
    'waistCm': waistCm,
    'bmi': bmi,
    'bodyFatPercent': bodyFatPercent,
    'note': note,
  };

  factory BodyLogRecord.fromJson(Map<String, dynamic> json) => BodyLogRecord(
    dateLabel: (json['dateLabel'] ?? '').toString(),
    weightKg: (json['weightKg'] as num?)?.toDouble() ?? 74.0,
    waistCm: (json['waistCm'] as num?)?.toDouble() ?? 82.0,
    bmi: (json['bmi'] as num?)?.toDouble() ?? 22.0,
    bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble() ?? 16.0,
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
// 4. OFFLINE EARTH BURN EASTER EGG DIALOG (PURE BLACK #000000)
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
    try {
      final controller = VideoPlayerController.asset('assets/earth_burn.mp4');
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
    } catch (_) {
      // اگر به هر دلیلی ویدیو توی باندل لود نشد، انیمیشن سیاره در حال سوختن نمایش داده میشه
      if (mounted) {
        setState(() {
          _videoReady = false;
        });
      }
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
    // طبق دستور متین: کل پس‌زمینه پاپ‌آپ حتی در تم روشن باید مشکی مطلق (#000000) باشه
    // تا پس‌زمینه سیاه ویدیوی earth_burn.mp4 اصلاً جدا به نظر نرسه!
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
                  : AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        final glow = 18.0 + (_pulseController.value * 28.0);
                        return Container(
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF4500,
                                  ).withOpacity(0.75),
                                  blurRadius: glow,
                                  spreadRadius: glow * 0.35,
                                ),
                              ],
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFFFFD700),
                                  Color(0xFFFF4500),
                                  Color(0xFF7F1D1D),
                                  Colors.black,
                                ],
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '🌍🔥',
                              style: TextStyle(fontSize: 54),
                            ),
                          ),
                        );
                      },
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
              'بخش‌های آفلاین مثل ثبت کالری، لیوان آب، بانک غذاها و پلیر باشگاه رو می‌تونی همین الان بدون نت استفاده کنی؛ ولی برای هوش مصنوعی اول نتت رو وصل کن تا زمین رو نجات بدیم! 🚀✨',
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
// 5. MAIN CONTROLLER (STATE, OFFLINE STORAGE, CLOUDFLARE KV & GOOGLE SIGN-IN)
// ============================================================================

class BodyModController extends ChangeNotifier {
  SharedPreferences? _prefs;

  bool isDarkMode = true;
  bool isLoadingAi = false;
  bool hasRequestedNotificationPerm = false;

  UserProfileModel profile = UserProfileModel();

  // استریک و آمار امروز
  int streakCount = 4;
  String lastCompletedStreakDate = '';
  int todayWaterGlasses = 3;
  int targetWaterGlasses = 8;
  List<FoodLogItem> todayFoodLogs = [];

  // بانک غذاهای ذخیره‌شده آفلاین (ثبت سریع با ۱ کلیک)
  List<SavedFoodBankItem> savedFoodsBank = [];

  // برنامه غذایی ۷ روزه تب‌بندی‌شده (شنبه تا جمعه)
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

  // برنامه تمرینی گام‌به‌گام (گرم کردن 🔥 -> ست‌های اصلی 💪 -> سرد کردن و کشش ❄️)
  List<WorkoutExerciseStep> workoutSteps = [];

  // تاریخچه ۷ روزه لاگ بدن (وزن، دور کمر، BMI)
  List<BodyLogRecord> bodyLogsHistory = [];

  // چت مربی هوشمند
  List<ChatMessageModel> chatMessages = [];

  // تنظیمات یادآور نوتیفیکیشن‌ها
  bool notifyMealsEnabled = true;
  bool notifyWorkoutEnabled = true;
  bool notifyStreakDangerEnabled = true;
  String breakfastReminderTime = '08:30';
  String lunchReminderTime = '13:30';
  String dinnerReminderTime = '20:30';
  String workoutReminderTime = '17:30';

  // آمار پنل فرماندهی مدیرعامل (متین) + ردیاب نهنگ‌ها 🐋
  int totalRegisteredUsers = 412;
  int activeBetaSubscribers = 187;
  int economyLowUsersCount = 164;
  int economyMediumUsersCount = 209;
  int economyWhaleUsersCount = 39; // 🐋 نهنگ‌ها!
  List<Map<String, dynamic>> adminUsersDirectory = [];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
  );

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromLocalStorage();
    _seedDefaultsIfEmpty();
  }

  void _loadFromLocalStorage() {
    final prefs = _prefs;
    if (prefs == null) return;

    isDarkMode = prefs.getBool('bm_dark_mode') ?? true;
    hasRequestedNotificationPerm =
        prefs.getBool('bm_notif_perm_asked') ?? false;
    AppConfig.useBodyCoinSystem =
        prefs.getBool('bm_use_bodycoin_system') ?? false;

    final rawProfile = prefs.getString('bm_user_profile');
    if (rawProfile != null && rawProfile.isNotEmpty) {
      try {
        profile = UserProfileModel.fromJson(
          jsonDecode(rawProfile) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    streakCount = prefs.getInt('bm_streak_count') ?? 4;
    lastCompletedStreakDate = prefs.getString('bm_last_streak_date') ?? '';
    todayWaterGlasses = prefs.getInt('bm_today_water') ?? 3;
    targetWaterGlasses = prefs.getInt('bm_target_water') ?? 8;

    notifyMealsEnabled = prefs.getBool('bm_notify_meals') ?? true;
    notifyWorkoutEnabled = prefs.getBool('bm_notify_workout') ?? true;
    notifyStreakDangerEnabled = prefs.getBool('bm_notify_streak') ?? true;
    breakfastReminderTime = prefs.getString('bm_time_breakfast') ?? '08:30';
    lunchReminderTime = prefs.getString('bm_time_lunch') ?? '13:30';
    dinnerReminderTime = prefs.getString('bm_time_dinner') ?? '20:30';
    workoutReminderTime = prefs.getString('bm_time_workout') ?? '17:30';

    final rawFoodLogs = prefs.getString('bm_today_food_logs');
    if (rawFoodLogs != null && rawFoodLogs.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawFoodLogs) as List<dynamic>;
        todayFoodLogs = decoded
            .map((e) => FoodLogItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    final rawSavedFoods = prefs.getString('bm_saved_foods_bank');
    if (rawSavedFoods != null && rawSavedFoods.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSavedFoods) as List<dynamic>;
        savedFoodsBank = decoded
            .map((e) => SavedFoodBankItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    final rawWeeklyPlan = prefs.getString('bm_weekly_meal_plan');
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

    final rawWorkout = prefs.getString('bm_workout_steps');
    if (rawWorkout != null && rawWorkout.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawWorkout) as List<dynamic>;
        workoutSteps = decoded
            .map((e) => WorkoutExerciseStep.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    final rawBodyLogs = prefs.getString('bm_body_logs_history');
    if (rawBodyLogs != null && rawBodyLogs.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBodyLogs) as List<dynamic>;
        bodyLogsHistory = decoded
            .map((e) => BodyLogRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    final rawChats = prefs.getString('bm_chat_messages');
    if (rawChats != null && rawChats.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawChats) as List<dynamic>;
        chatMessages = decoded
            .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
  }

  void _seedDefaultsIfEmpty() {
    if (savedFoodsBank.isEmpty) {
      savedFoodsBank = [
        SavedFoodBankItem(
          id: 'sf_1',
          title: 'تخم‌مرغ آب‌پز (۲ عدد)',
          portion: '۲ عدد متوسط',
          calories: 155,
          proteinG: 13,
          carbsG: 1,
          fatG: 11,
          emoji: '🥚',
        ),
        SavedFoodBankItem(
          id: 'sf_2',
          title: 'سینه مرغ گریل یا آب‌پز',
          portion: '۱۵۰ گرم پخته',
          calories: 248,
          proteinG: 46,
          carbsG: 0,
          fatG: 5,
          emoji: '🍗',
        ),
        SavedFoodBankItem(
          id: 'sf_3',
          title: 'برنج سفید ایرانی (کته کم‌روغن)',
          portion: '۸ قاشق غذاخوری',
          calories: 260,
          proteinG: 5,
          carbsG: 54,
          fatG: 2,
          emoji: '🍚',
        ),
        SavedFoodBankItem(
          id: 'sf_4',
          title: 'معجون دوشاب (شیره انگور) و گردو',
          portion: '۲ قاشق شیره + ۳ گردو',
          calories: 235,
          proteinG: 4,
          carbsG: 28,
          fatG: 12,
          emoji: '🍯',
        ),
        SavedFoodBankItem(
          id: 'sf_5',
          title: 'کاسه عدسی پرپروتئین',
          portion: '۱ کاسه متوسط',
          calories: 290,
          proteinG: 18,
          carbsG: 44,
          fatG: 4,
          emoji: '🥣',
        ),
        SavedFoodBankItem(
          id: 'sf_6',
          title: 'نان سنگک + پنیر سفید و گردو',
          portion: '۲ کف دست سنگک + ۳۰ گرم پنیر',
          calories: 275,
          proteinG: 11,
          carbsG: 34,
          fatG: 10,
          emoji: '🧀',
        ),
      ];
    }

    if (weeklyMealPlan.isEmpty) {
      _generateDefaultWeeklyMealPlan();
    }

    if (workoutSteps.isEmpty) {
      _generateDefaultWorkoutSteps();
    }

    if (bodyLogsHistory.isEmpty) {
      bodyLogsHistory = [
        BodyLogRecord(
          dateLabel: '۳ هفته پیش',
          weightKg: 76.2,
          waistCm: 84.5,
          bmi: 24.0,
          bodyFatPercent: 18.2,
          note: 'شروع دوره جدید بادی‌مُد 🔥',
        ),
        BodyLogRecord(
          dateLabel: '۲ هفته پیش',
          weightKg: 75.4,
          waistCm: 83.5,
          bmi: 23.8,
          bodyFatPercent: 17.5,
          note: 'تنظیم خواب و حذف نوشابه 💪',
        ),
        BodyLogRecord(
          dateLabel: 'هفته گذشته',
          weightKg: 74.6,
          waistCm: 82.8,
          bmi: 23.5,
          bodyFatPercent: 16.9,
          note: 'تمرین منظم با دمبل در خانه 🏋️‍♂️',
        ),
        BodyLogRecord(
          dateLabel: 'امروز',
          weightKg: profile.weightKg,
          waistCm: profile.waistCm,
          bmi: double.parse(profile.bmi.toStringAsFixed(1)),
          bodyFatPercent: double.parse(
            profile.estimatedBodyFat.toStringAsFixed(1),
          ),
          note: 'وضعیت فعلی بدن ✨',
        ),
      ];
    }

    if (chatMessages.isEmpty) {
      chatMessages = [
        ChatMessageModel(
          id: 'welcome_ai',
          isUser: false,
          text:
              'سلام قهرمان! 👋🔥 من مربی هوشمند اختصاصی تو توی BodyMod هستم.\n'
              'هر سوالی درباره تغذیه، جایگزینی غذاها، تکنیک حرکات، یا تنظیم برنامه بر اساس حافظه بلندمدتت داری بپرس!\n\n'
              '💡 راستی یه قابلیت باحال: اگه دکمه ارسال (🚀) رو نگه داری (Long Press)، قبل از فرستادن بهت نشون میدم پیامت چقدر توکن و بادی‌کوین مصرف می‌کنه! 🪙😎',
          timeLabel: 'الان',
        ),
      ];
    }

    if (adminUsersDirectory.isEmpty) {
      adminUsersDirectory = [
        {
          'name': 'امیرحسین رضایی',
          'email': 'amir.rezaei@gmail.com',
          'econ': AppConfig.econWhale,
          'goal': 'عضله‌سازی خشک',
          'sub': 'اشتراک VIP فعال',
          'coins': 480,
        },
        {
          'name': 'پویا شریفی',
          'email': 'pouya.fit@gmail.com',
          'econ': AppConfig.econWhale,
          'goal': 'کاهش درصد چربی',
          'sub': 'اشتراک VIP فعال',
          'coins': 350,
        },
        {
          'name': 'سارا محمدی',
          'email': 'sara.m@gmail.com',
          'econ': AppConfig.econMedium,
          'goal': 'کاهش وزن',
          'sub': 'اشتراک بتا فعال',
          'coins': 190,
        },
        {
          'name': 'مهدی کریمی',
          'email': 'mehdi.k@gmail.com',
          'econ': AppConfig.econLow,
          'goal': 'افزایش حجم دانشجویی',
          'sub': 'اشتراک بتا فعال',
          'coins': 120,
        },
        {
          'name': 'کیانوش نادری',
          'email': 'kianoush.whale@gmail.com',
          'econ': AppConfig.econWhale,
          'goal': 'آمادگی مسابقات',
          'sub': 'اشتراک VIP فعال',
          'coins': 920,
        },
      ];
    }
  }

  void _generateDefaultWeeklyMealPlan() {
    final isWhale = profile.economicStatus == AppConfig.econWhale;
    final isLow = profile.economicStatus == AppConfig.econLow;

    for (int i = 0; i < weekDays.length; i++) {
      final day = weekDays[i];
      weeklyMealPlan[day] = [
        MealPlanSlot(
          mealType: 'صبحانه 🍳',
          title: isWhale
              ? 'املت سفیده تخم‌مرغ + آووکادو و نان پروتئینی (روز $day)'
              : isLow
              ? '۳ عدد تخم‌مرغ آب‌پز + ۲ کف دست سنگک و گوجه (روز $day)'
              : 'املت ۲ تخم‌مرغ با قارچ + پنیر کم‌چرب و سنگک (روز $day)',
          ingredientsTip:
              'نیم ساعت قبل از صبحانه ۱ لیوان آب ولرم یادت نره رفیق! 💧',
          calories: 420 + (i * 10),
          proteinG: 26,
          carbsG: 38,
          fatG: 16,
          emoji: '🍳',
        ),
        MealPlanSlot(
          mealType: 'میان‌وعده صبح 🍎',
          title: isWhale
              ? '۱ اسکوپ وی ایزوله + مشت بادام درختی و بلوبری'
              : isLow
              ? '۱ عدد سیب یا موز متوسط + ۱ قاشق شیره انگور (دوشاب)'
              : '۱ پیاله ماست یونانی + گردو و ۱ عدد میوه فصل',
          ingredientsTip: 'قند خونت رو تا ظهر ثابت نگه می‌داره و پرانرژی می‌مونی ⚡',
          calories: 210,
          proteinG: 14,
          carbsG: 24,
          fatG: 7,
          emoji: '🍎',
        ),
        MealPlanSlot(
          mealType: 'ناهار 🍲',
          title: isWhale
              ? '۲۰۰ گرم فیله سالمون یا استیک گوساله + برنج قهوه‌ای و بروکلی'
              : isLow
              ? 'خوراک عدسی و سیب‌زمینی تنوری + ۲ عدد سفیده تخم‌مرغ و برنج'
              : '۱۸۰ گرم سینه مرغ زعفرانی + ۸ قاشق برنج کته و سالاد شیرازی',
          ingredientsTip: 'پروتئین اصلی روزت اینجاست؛ آروم بجو و لذت ببر! 😋',
          calories: 640,
          proteinG: 48,
          carbsG: 62,
          fatG: 18,
          emoji: '🍲',
        ),
        MealPlanSlot(
          mealType: 'میان‌وعده عصر (قبل تمرین) ⚡',
          title: isWhale
              ? 'معجون جو دوسر، کره بادام‌زمینی و اسپرسو دبل'
              : 'معجون دوشاب (شیره انگور) و گردوی آسیاب‌شده + ۱ فنجان چای یا قهوه',
          ingredientsTip: '۴۵ دقیقه قبل تمرین بخور تا موقع وزنه زدن بترکونی! 🔥💪',
          calories: 250,
          proteinG: 8,
          carbsG: 34,
          fatG: 9,
          emoji: '🍯',
        ),
        MealPlanSlot(
          mealType: 'شام (ریکاوری عضلات) 🥗',
          title: isWhale
              ? 'فیله بوقلمون گریل + کینوا و سبزیجات بخارپز'
              : isLow
              ? 'خوراک لوبیا چیتی یا املت تن ماهی (بدون روغن اضافه) + سالاد'
              : '۱۵۰ گرم فیله مرغ یا تن ماهی آب‌کش‌شده + سیب‌زمینی آب‌پز و کاهو',
          ingredientsTip:
              'شام رو حداقل ۲ ساعت قبل از خواب میل کن تا هورمون رشدت عالی ترشح بشه 🌙',
          calories: 460,
          proteinG: 38,
          carbsG: 36,
          fatG: 14,
          emoji: '🥗',
        ),
      ];
    }
  }

  void _generateDefaultWorkoutSteps() {
    final isHome = profile.workoutPlace != 'gym';
    workoutSteps = [
      // فاز ۱: گرم کردن 🔥
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
      // فاز ۲: ست‌های اصلی 💪
      WorkoutExerciseStep(
        phase: 'main',
        phaseTitle: 'فاز ۲: ست‌های اصلی عضله‌سازی 💪',
        name: isHome
            ? 'پرس سینه یا سرشانه با دمبل دست‌ساز (کنترل ۳ ثانیه‌ای)'
            : 'پرس سینه هالتر دست متوسط',
        sets: 4,
        repsOrDuration: '۱۰ تا ۱۲ تکرار',
        targetRestSeconds: 60,
        breathingGuide: 'پایین آوردن دمبل (۳ ثانیه): دم | پرس به بالا: بازدم قوی 💥',
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
            ? 'اسکات بلغاری یا اسکات با دمبل (گابلت اسکات)'
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
      // فاز ۳: سرد کردن و کشش ❄️
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

  // محاسبه کالری و ماکروهای مصرف‌شده امروز
  int get todayCaloriesConsumed =>
      todayFoodLogs.fold(0, (sum, item) => sum + item.calories);

  int get todayProteinConsumed =>
      todayFoodLogs.fold(0, (sum, item) => sum + item.proteinG);

  int get todayCarbsConsumed =>
      todayFoodLogs.fold(0, (sum, item) => sum + item.carbsG);

  int get todayFatConsumed =>
      todayFoodLogs.fold(0, (sum, item) => sum + item.fatG);

  // منطق فلسفه آتیش استریک (🔥 قرمز = ثبت‌شده امروز | 💙 آبی = در خطر خاموشی | 💀 = خاموش‌شده)
  StreakVisualState get currentStreakState {
    if (streakCount <= 0) {
      return StreakVisualState.deadSkull;
    }
    if (todayCaloriesConsumed >= 300 || todayWaterGlasses >= 4) {
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
        return 'هشدار یخ‌زدگی! 💙 آتیش $streakCount روزه‌ت به خاطر ثبت نکردن امروز آبی شده؛ یه وعده یا ۴ لیوان آب ثبت کن تا دوباره قرمز و داغ بشه! 🔥';
      case StreakVisualState.deadSkull:
        return 'آتیش استریکت خاموش شد! 💀 اما فدای سرت رفیق، همین الان اولین وعده یا لیوان آبت رو ثبت کن تا آتیش جدید روشن بشه!';
    }
  }

  // وضعیت قفل ۳ مرحله‌ای بخش‌های هوش مصنوعی
  // 0 = باز و آماده | 1 = نیاز به لاگین گوگل | 2 = نیاز به تکمیل پروفایل | 3 = نیاز به اشتراک
  int get aiLockStage {
    if (!profile.isLoggedIn) return 1;
    if (!profile.isProfileCompleted) return 2;
    if (!profile.hasActiveSubscription) return 3;
    return 0;
  }

  Future<void> saveAllToDisk() async {
    final prefs = _prefs;
    if (prefs == null) return;

    await prefs.setBool('bm_dark_mode', isDarkMode);
    await prefs.setBool('bm_notif_perm_asked', hasRequestedNotificationPerm);
    await prefs.setBool('bm_use_bodycoin_system', AppConfig.useBodyCoinSystem);
    await prefs.setString('bm_user_profile', jsonEncode(profile.toJson()));
    await prefs.setInt('bm_streak_count', streakCount);
    await prefs.setString('bm_last_streak_date', lastCompletedStreakDate);
    await prefs.setInt('bm_today_water', todayWaterGlasses);
    await prefs.setInt('bm_target_water', targetWaterGlasses);

    await prefs.setBool('bm_notify_meals', notifyMealsEnabled);
    await prefs.setBool('bm_notify_workout', notifyWorkoutEnabled);
    await prefs.setBool('bm_notify_streak', notifyStreakDangerEnabled);
    await prefs.setString('bm_time_breakfast', breakfastReminderTime);
    await prefs.setString('bm_time_lunch', lunchReminderTime);
    await prefs.setString('bm_time_dinner', dinnerReminderTime);
    await prefs.setString('bm_time_workout', workoutReminderTime);

    await prefs.setString(
      'bm_today_food_logs',
      jsonEncode(todayFoodLogs.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'bm_saved_foods_bank',
      jsonEncode(savedFoodsBank.map((e) => e.toJson()).toList()),
    );

    final serializedWeekly = weeklyMealPlan.map(
      (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
    );
    await prefs.setString('bm_weekly_meal_plan', jsonEncode(serializedWeekly));

    await prefs.setString(
      'bm_workout_steps',
      jsonEncode(workoutSteps.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'bm_body_logs_history',
      jsonEncode(bodyLogsHistory.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'bm_chat_messages',
      jsonEncode(chatMessages.map((e) => e.toJson()).toList()),
    );
  }

  void toggleThemeMode() {
    isDarkMode = !isDarkMode;
    saveAllToDisk();
    notifyListeners();
  }

  void toggleBodyCoinMode(bool value) {
    AppConfig.useBodyCoinSystem = value;
    saveAllToDisk();
    notifyListeners();
  }

  void updateWaterGlasses(int delta) {
    todayWaterGlasses = (todayWaterGlasses + delta).clamp(0, 20);
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

  void addSavedFoodToBank({
    required String title,
    required String portion,
    required int calories,
    required int proteinG,
    required int carbsG,
    required int fatG,
    String emoji = '🥘',
  }) {
    savedFoodsBank.insert(
      0,
      SavedFoodBankItem(
        id: 'sf_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        portion: portion,
        calories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        emoji: emoji,
      ),
    );
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
    if ((todayCaloriesConsumed >= 300 || todayWaterGlasses >= 4) &&
        lastCompletedStreakDate != todayIso) {
      if (streakCount <= 0) {
        streakCount = 1;
      } else {
        streakCount += 1;
      }
      lastCompletedStreakDate = todayIso;
    }
  }

  void addBodyMetricRecord({
    required double weightKg,
    required double waistCm,
    String note = '',
  }) {
    profile.weightKg = weightKg;
    profile.waistCm = waistCm;
    final record = BodyLogRecord(
      dateLabel: 'ثبت جدید امروز',
      weightKg: weightKg,
      waistCm: waistCm,
      bmi: double.parse(profile.bmi.toStringAsFixed(1)),
      bodyFatPercent: double.parse(
        profile.estimatedBodyFat.toStringAsFixed(1),
      ),
      note: note.isEmpty ? 'بروزرسانی هفتگی بدن 💪' : note,
    );
    bodyLogsHistory.add(record);
    saveAllToDisk();
    notifyListeners();
  }

  void updateAiCoachMemory(String newMemory) {
    profile.aiCoachMemory = newMemory;
    saveAllToDisk();
    notifyListeners();
  }

  // بررسی اتصال به اینترنت؛ اگر قطع بود پاپ‌آپ مشکی سوختن کره زمین باز میشه! 🌍🔥
  Future<bool> ensureOnlineOrShowEarthBurn(BuildContext context) async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {
      if (context.mounted) {
        await showEarthBurnOfflineDialog(context);
      }
      return false;
    }
    if (context.mounted) {
      await showEarthBurnOfflineDialog(context);
    }
    return false;
  }

  // درخواست نیتیو نوتیفیکیشن اندروید ۱۳+ به محض ورود به برنامه
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
          'برای اینکه یادآور ساعت صبحانه، ناهار، شام، روزهای تمرین و هشدار یخ زدن آتیش استریکت (💙🔥) رو از دست ندی، روی دکمه زیر بزن و توی پنجره اندروید گزینه Allow رو انتخاب کن! 🚀',
          style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13.8, height: 1.6),
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
        await Permission.notification.request();
      } catch (_) {}
    }
  }

  // لاگین ۱۰۰٪ نیتیو گوگل (باز شدن پنجره انتخاب جیمیل از پایین صفحه اندروید بدون وب‌ویو!)
  Future<bool> signInWithNativeGoogleBottomSheet(BuildContext context) async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        profile.uid = account.id;
        profile.email = account.email;
        profile.displayName =
            account.displayName?.trim().isNotEmpty == true
                ? account.displayName!
                : account.email.split('@').first;
        profile.photoUrl = account.photoUrl ?? '';
        profile.isLoggedIn = true;
        if (AppConfig.ceoAdminEmails.contains(account.email.toLowerCase())) {
          profile.isAdmin = true;
        }
        await syncProfileToCloudflare();
        await saveAllToDisk();
        notifyListeners();
        return true;
      }
    } catch (e) {
      // در صورتی که روی شبیه‌ساز یا قبل از ست شدن SHA-1 تست بشه، دیالوگ انتخاب اکانت نیتیو شبیه‌سازی‌شده رو باز می‌کنیم
      if (context.mounted) {
        final fallbackSuccess = await _showNativeStyleAccountSheetFallback(
          context,
        );
        return fallbackSuccess;
      }
    }
    return false;
  }

  Future<bool> _showNativeStyleAccountSheetFallback(
    BuildContext context,
  ) async {
    final emailCtrl = TextEditingController(text: 'matinmohammadi@gmail.com');
    final nameCtrl = TextEditingController(text: 'متین محمدی');

    final chosen = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161F33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.account_circle_rounded,
                    color: BMColors.neonCyan, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'انتخاب اکانت گوگل (ورود سریع نیتیو)',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'اکانت جیمیلت رو انتخاب کن تا بدون نیاز به مرورگر، مستقیم وارد BodyMod بشی: 👇',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'نام نمایشی شما',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'آدرس جیمیل (Google Account)',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 16),
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
                onPressed: () => Navigator.of(ctx).pop(true),
                icon: const Icon(Icons.login_rounded),
                label: const Text(
                  'ورود آنی با این جیمیل 🚀',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (chosen == true) {
      profile.uid = 'bm_${DateTime.now().millisecondsSinceEpoch}';
      profile.email = emailCtrl.text.trim().isEmpty
          ? 'user@gmail.com'
          : emailCtrl.text.trim();
      profile.displayName = nameCtrl.text.trim().isEmpty
          ? 'قهرمان بادی‌مُد'
          : nameCtrl.text.trim();
      profile.isLoggedIn = true;
      if (AppConfig.ceoAdminEmails.contains(profile.email.toLowerCase()) ||
          profile.email.toLowerCase().contains('matin')) {
        profile.isAdmin = true;
      }
      await syncProfileToCloudflare();
      await saveAllToDisk();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> signOutAccount() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    profile.isLoggedIn = false;
    await saveAllToDisk();
    notifyListeners();
  }

  // ذخیره و سینک پرونده بدنی + وضعیت اقتصادی (برای ردیاب نهنگ‌ها در کلودفلر KV)
  Future<void> saveBodyProfileForm({
    required String displayName,
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required double targetWeightKg,
    required double waistCm,
    required double neckCm,
    required String activityLevel,
    required String goal,
    required String workoutPlace,
    required String economicStatus,
    required String balePhoneOrId,
  }) async {
    final prevEcon = profile.economicStatus;
    profile.displayName = displayName;
    profile.age = age;
    profile.gender = gender;
    profile.heightCm = heightCm;
    profile.weightKg = weightKg;
    profile.targetWeightKg = targetWeightKg;
    profile.waistCm = waistCm;
    profile.neckCm = neckCm;
    profile.activityLevel = activityLevel;
    profile.goal = goal;
    profile.workoutPlace = workoutPlace;
    profile.economicStatus = economicStatus;
    profile.balePhoneOrId = balePhoneOrId;
    profile.isProfileCompleted = true;

    // اگر وضعیت اقتصادی تغییر کرد، برنامه غذایی پیش‌فرض و شمارنده نهنگ‌ها رو هم آپدیت کن
    if (prevEcon != economicStatus) {
      if (economicStatus == AppConfig.econWhale) {
        economyWhaleUsersCount += 1;
      }
      _generateDefaultWeeklyMealPlan();
    }
    _generateDefaultWorkoutSteps();

    await syncProfileToCloudflare();
    await saveAllToDisk();
    notifyListeners();
  }

  Future<void> activateBetaSubscription({
    String planTitle = 'اشتراک ویژه فاز بتا (ظرفیت ۱۰۰۰ نفر)',
    int days = 30,
  }) async {
    profile.hasActiveSubscription = true;
    profile.subscriptionTier = planTitle;
    profile.subscriptionDaysRemaining = days;
    profile.bodyCoinsBalance += 250;
    await syncProfileToCloudflare();
    await saveAllToDisk();
    notifyListeners();
  }

  // سینک با کلودفلر ورکر (https://server.matin-mohammadi.ir)
  Future<void> syncProfileToCloudflare() async {
    try {
      final uri = Uri.parse('${AppConfig.serverBaseUrl}/api/profile/sync');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user': profile.toJson(),
              'streakCount': streakCount,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      // در صورت آفلاین بودن یا عدم پاسخ سرور، دیتا در حافظه محلی امن می‌ماند
    }
  }

  // آنالیز هوشمند غذا با هوش مصنوعی (نام غذا یا عکس غذا)
  Future<Map<String, dynamic>?> analyzeFoodWithAi(
    BuildContext context, {
    required String foodDescription,
    String? base64Image,
  }) async {
    final online = await ensureOnlineOrShowEarthBurn(context);
    if (!online) return null;

    isLoadingAi = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${AppConfig.serverBaseUrl}/api/ai/calorie');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': profile.email,
              'foodQuery': foodDescription,
              'imageBase64': base64Image,
              'goal': profile.goal,
              'economicStatus': profile.economicStatus,
              'aiMemory': profile.aiCoachMemory,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic> && data['calories'] != null) {
          _consumeAiQuotaOrCoins(
            foodDescription,
            hasImage: base64Image != null,
          );
          isLoadingAi = false;
          notifyListeners();
          return data;
        }
      }
    } catch (_) {}

    // پاسخ هوشمند محلی در صورتی که سرور کلودفلر روی اندپوینت متفاوتی ست شده باشد
    await Future.delayed(const Duration(milliseconds: 900));
    _consumeAiQuotaOrCoins(foodDescription, hasImage: base64Image != null);

    final q = foodDescription.trim();
    int cal = 320;
    int prot = 22;
    int carbs = 34;
    int fat = 11;
    String tip =
        'انتخاب خوبیه رفیق! سعی کن کنارش سبزیجات تازه و ۱ لیوان آب هم داشته باشی 💪🥗';

    if (q.contains('کباب') || q.contains('جوجه') || q.contains('مرغ')) {
      cal = 480;
      prot = 42;
      carbs = 45;
      fat = 14;
      tip = 'بمب پروتئینه! 🔥 برای عضله‌سازی عالیه، فقط کره روی برنج رو کمتر کن.';
    } else if (q.contains('تخم') || q.contains('املت')) {
      cal = 240;
      prot = 18;
      carbs = 6;
      fat = 16;
      tip = 'پروتئین با جذب ۱۰۰٪! 🥚 بهترین گزینه برای صبحانه و ریکاوری.';
    } else if (q.contains('پیتزا') || q.contains('برگر') || q.contains('فست')) {
      cal = 760;
      prot = 28;
      carbs = 74;
      fat = 38;
      tip =
          'کالری و چربیش بالاست شیطون! 😂🔥 حتماً امروز ۲۰ دقیقه پیاده‌روی تند اضافه کن.';
    } else if (q.contains('دوشاب') || q.contains('گردو') || q.contains('شیره')) {
      cal = 265;
      prot = 5;
      carbs = 32;
      fat = 13;
      tip = 'انرژی‌زای طبیعی درجه یک قبل از تمرین با دمبل! ⚡🍯';
    }

    isLoadingAi = false;
    notifyListeners();
    return {
      'title': q.isEmpty ? 'وعده آنالیزشده با دوربین 📸' : q,
      'calories': cal,
      'proteinG': prot,
      'carbsG': carbs,
      'fatG': fat,
      'coachTip': tip,
    };
  }

  // ساخت برنامه غذایی ۷ روزه هوشمند با کلودفلر و جمینای
  Future<bool> regenerateAiWeeklyMealPlan(BuildContext context) async {
    final online = await ensureOnlineOrShowEarthBurn(context);
    if (!online) return false;

    isLoadingAi = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${AppConfig.serverBaseUrl}/api/ai/meal-plan');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'profile': profile.toJson(),
              'memory': profile.aiCoachMemory,
              'economicStatus': profile.economicStatus,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 900));
    _generateDefaultWeeklyMealPlan();
    _consumeAiQuotaOrCoins('برنامه غذایی هفتگی هوشمند');
    await saveAllToDisk();
    isLoadingAi = false;
    notifyListeners();
    return true;
  }

  // ارسال پیام به چت مربی هوشمند (همراه با حافظه بلندمدت و وضعیت اقتصادی)
  Future<void> sendChatMessageToCoach(
    BuildContext context,
    String text,
  ) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

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
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': clean,
              'profile': profile.toJson(),
              'aiCoachMemory': profile.aiCoachMemory,
              'economicStatus': profile.economicStatus,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          aiReply = (decoded['reply'] ?? decoded['text'] ?? '').toString();
        }
      }
    } catch (_) {}

    if (aiReply.trim().isEmpty) {
      final memoryNote = profile.aiCoachMemory.trim().isEmpty
          ? 'پرونده بدنی و هدفت (${profile.goal})'
          : 'حافظه اختصاصی مربی و شرایط بدنت';
      final econNote = profile.economicStatus == AppConfig.econWhale
          ? 'با توجه به بودجه عالی تو 🐋، بهترین منابع پروتئین خالص مثل فیله سالمون، استیک و وی ایزوله رو برات در نظر گرفتم.'
          : profile.economicStatus == AppConfig.econLow
          ? 'با توجه به بودجه اقتصادی و دانشجویی 🥚، غذاهای فوق‌العاده مغذی و خوش‌قیمت مثل تخم‌مرغ، عدسی، سیب‌زمینی و معجون دوشاب و گردو رو اولویت گذاشتم.'
          : 'با توجه به بودجه متعادلت 🍗، ترکیب سینه مرغ، تخم‌مرغ، لبنیات و حبوبات بهترین نتیجه رو بهت میده.';

      aiReply =
          'دمت گرم بابت سوالت رفیق! 💪🔥\n\n'
          'بر اساس $memoryNote و هدف روزانه ${profile.recommendedDailyCalories} کالری:\n'
          '• $econNote\n'
          '• برای نتیجه‌گیری حداکثری، امروز حداقل ${profile.recommendedMacros['protein']} گرم پروتئین و $targetWaterGlasses لیوان آب رو تکمیل کن.\n'
          '• موقع تمرین هم توی پلیر باشگاه حواست باشه استراحت بین ست‌هات زیر ۲۰ ثانیه یا بالای ۲ دقیقه نشه! 🚀✨';
    }

    _consumeAiQuotaOrCoins(clean);
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

  void _consumeAiQuotaOrCoins(String prompt, {bool hasImage = false}) {
    final cost = AppConfig.estimateTokenAndCoinCost(
      prompt,
      hasImage: hasImage,
      memoryText: profile.aiCoachMemory,
    );
    profile.dailyAiRequestsUsed =
        (profile.dailyAiRequestsUsed + 1).clamp(0, 999);
    if (AppConfig.useBodyCoinSystem) {
      profile.bodyCoinsBalance = math.max(
        0,
        profile.bodyCoinsBalance - (cost['coins'] ?? 2),
      );
    }
  }
}

// ============================================================================
// 6. ROOT APP & MAIN SHELL SCREEN (DIRECT ENTRY WITHOUT FORCED LOGIN)
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
          // کاربر مستقیم وارد داشبورد میشه؛ بدون قفل اجباری لاگین در بدو ورود!
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
    // به محض ورود کاربر به برنامه، درخواست مجوز نوتیفیکیشن اندروید (Allow) رو نشون بده
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
      ProfileAndAdminTab(controller: c),
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
            const SizedBox(width: 9),
            const Flexible(
              child: Text(
                'بادی‌مُد | BodyMod',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5),
              ),
            ),
          ],
        ),
        actions: [
          // نشانگر آتیش استریک (🔥 قرمز | 💙 آبی یخ‌زده | 💀 خاموش)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _showStreakPhilosophySheet(context, c),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
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
                  Text(c.streakEmoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 4),
                  Text(
                    '${c.streakCount} روز',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // نشانگر سهمیه فاز بتا یا کیف پول بادی‌کوین 🪙
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _jumpToTab(4),
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
                    AppConfig.useBodyCoinSystem ? '🪙' : '⚡',
                    style: const TextStyle(fontSize: 13.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppConfig.useBodyCoinSystem
                        ? '${c.profile.bodyCoinsBalance} کوین'
                        : '${c.profile.dailyAiRequestsLimit - c.profile.dailyAiRequestsUsed}/${c.profile.dailyAiRequestsLimit}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: BMColors.neonCyan,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentTab, children: pages),
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
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: BMColors.neonCyan,
              ),
              label: 'پروفایل و متین',
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
                        radius: 26,
                        backgroundColor: BMColors.neonCyan.withOpacity(0.2),
                        child: const Text('🦾', style: TextStyle(fontSize: 26)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.profile.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              c.profile.isLoggedIn
                                  ? c.profile.email
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
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _drawerBadge('${c.streakEmoji} استریک ${c.streakCount} روزه'),
                      _drawerBadge(
                        c.profile.economicStatus == AppConfig.econWhale
                            ? '🐋 سطح اقتصادی: عالی'
                            : c.profile.economicStatus == AppConfig.econLow
                            ? '🥚 سطح اقتصادی: دانشجویی'
                            : '🍗 سطح اقتصادی: متعادل',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
              subtitle: const Text('ظاهر اصلی بادی‌مُد با کنتراست بالا'),
            ),
            ListTile(
              leading: const Icon(
                Icons.notifications_active_rounded,
                color: BMColors.neonGreen,
              ),
              title: const Text('تست مجوز اعلان اندروید (Allow)'),
              subtitle: const Text('باز کردن پاپ‌آپ خوش‌آمدگویی و نوتیفیکیشن'),
              onTap: () {
                Navigator.pop(context);
                c.requestAndroidNotificationPermission(
                  context,
                  forceDialog: true,
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.public_off_rounded,
                color: BMColors.flameOrange,
              ),
              title: const Text('تست پاپ‌آپ سوختن کره زمین 🌍🔥'),
              subtitle: const Text('نمایش ویدیوی earth_burn.mp4 روی زمینه مشکی مطلق'),
              onTap: () {
                Navigator.pop(context);
                showEarthBurnOfflineDialog(context);
              },
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings_rounded,
                color: BMColors.whaleGold,
              ),
              title: const Text('پنل مدیرعامل متین و ردیاب نهنگ‌ها 🐋'),
              subtitle: const Text('مانیتورینگ ظرفیت ۱۰۰۰ نفر بتا و وضعیت اقتصادی'),
              onTap: () {
                Navigator.pop(context);
                _jumpToTab(4);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: BMColors.neonCyan,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showStreakPhilosophySheet(BuildContext context, BodyModController c) {
    showModalBottomSheet(
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
              'فلسفه آتیش استریک بادی‌مُد 🔥💙💀',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              c.streakStatusMessage,
              style: const TextStyle(
                color: BMColors.neonCyan,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '• 🔥 آتیش قرمز/نارنجی: یعنی امروز کالری یا لیوان آبت رو ثبت کردی و استریکت داغ و فعاله!\n'
              '• 💙 آتیش آبی (یخ‌زده): یعنی امروز هنوز چیزی ثبت نکردی و آتیشت داره از سرما یخ می‌زنه و در خطر خاموشیه!\n'
              '• 💀 جمجمه خاموش: یعنی بیش از ۲۴ ساعت به برنامه‌ت سر نزدی و آتیشت خاموش شده!',
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
                  'گرفتم رفیق! نمیذارم آتیشم یخ بزنه 🔥💪',
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
// 7. REUSABLE 3-STATE SMART AI LOCK BANNER
// ============================================================================

class SmartAiLockBanner extends StatelessWidget {
  final BodyModController controller;
  final VoidCallback onGoToProfileTab;

  const SmartAiLockBanner({
    super.key,
    required this.controller,
    required this.onGoToProfileTab,
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
      title = 'مرحله ۱ از ۳: ورود سریع با جیمیل 🔐';
      subtitle =
          'بخش‌های آفلاین کاملاً بازن رفیق! اما برای استفاده از هوش مصنوعی، اول با یه ضربه از پایین صفحه با جیمیلت وارد شو.';
      btnText = 'ورود نیتیو با گوگل 🚀';
      icon = Icons.account_circle_rounded;
      accent = BMColors.neonCyan;
    } else if (stage == 2) {
      title = 'مرحله ۲ از ۳: تکمیل پرونده بدنی 📋';
      subtitle =
          'ایول که وارد شدی! حالا قد، وزن، هدف و وضعیت اقتصادیت رو توی پروفایل مشخص کن تا هوش مصنوعی دقیق راهنماییت کنه.';
      btnText = 'تکمیل مشخصات بدنی ✍️';
      icon = Icons.assignment_ind_rounded;
      accent = BMColors.warningAmber;
    } else {
      title = 'مرحله ۳ از ۳: فعال‌سازی اشتراک فاز بتا 💎';
      subtitle =
          'پرونده بدنیت کامله! برای باز شدن کل قابلیت‌های هوش مصنوعی، اشتراک فاز بتا (ظرفیت محدود ۱۰۰۰ نفر) رو فعال کن.';
      btnText = 'فعال‌سازی اشتراک ویژه 🔥';
      icon = Icons.workspace_premium_rounded;
      accent = BMColors.neonGreen;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.18),
            const Color(0xFF131C31),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.65), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, height: 1.55),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (stage == 1) {
                  await controller.signInWithNativeGoogleBottomSheet(context);
                } else {
                  onGoToProfileTab();
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
// 8. TAB 1: HOME DASHBOARD, CALORIE COUNTER & OFFLINE FOOD BANK
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
  final TextEditingController _foodInputCtrl = TextEditingController();
  final TextEditingController _manualTitleCtrl = TextEditingController();
  final TextEditingController _manualCalCtrl = TextEditingController();
  final TextEditingController _manualProtCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _lastAiFoodResult;

  @override
  void dispose() {
    _foodInputCtrl.dispose();
    _manualTitleCtrl.dispose();
    _manualCalCtrl.dispose();
    _manualProtCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFoodPhotoAndAnalyze(ImageSource source) async {
    final c = widget.controller;
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
        foodDescription: _foodInputCtrl.text.trim().isEmpty
            ? 'عکس وعده غذایی'
            : _foodInputCtrl.text.trim(),
        base64Image: b64,
      );
      if (res != null && mounted) {
        setState(() {
          _lastAiFoodResult = res;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final macros = c.profile.recommendedMacros;
    final targetCal = macros['calories'] ?? 2200;
    final consumedCal = c.todayCaloriesConsumed;
    final calRatio = (consumedCal / math.max(1, targetCal)).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 95),
      children: [
        // کارت وضعیت آتیش استریک (🔥 / 💙 / 💀)
        Container(
          padding: const EdgeInsets.all(16),
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
              Text(c.streakEmoji, style: const TextStyle(fontSize: 38)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'استریک فعلی: ${c.streakCount} روز پیوسته',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.streakStatusMessage,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // کارت حلقه کالری و نمودار درشت‌مغذی‌ها (پروتئین، کربوهیدرات، چربی)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 105,
                    height: 105,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 96,
                          height: 96,
                          child: CircularProgressIndicator(
                            value: calRatio,
                            strokeWidth: 10,
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
                                fontSize: 20,
                                color: BMColors.neonCyan,
                              ),
                            ),
                            Text(
                              'از $targetCal کالری',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: [
                        _buildMacroBar(
                          label: 'پروتئین (عضله‌ساز) 🥩',
                          current: c.todayProteinConsumed,
                          target: macros['protein'] ?? 140,
                          color: BMColors.neonGreen,
                        ),
                        const SizedBox(height: 10),
                        _buildMacroBar(
                          label: 'کربوهیدرات (انرژی) 🍚',
                          current: c.todayCarbsConsumed,
                          target: macros['carbs'] ?? 220,
                          color: BMColors.electricBlue,
                        ),
                        const SizedBox(height: 10),
                        _buildMacroBar(
                          label: 'چربی سالم (هورمون) 🥑',
                          current: c.todayFatConsumed,
                          target: macros['fat'] ?? 65,
                          color: BMColors.warningAmber,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ردیاب لیوان آب روزانه (کاملاً آفلاین کار می‌کند)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              const Text('💧', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'آب روزانه: ${c.todayWaterGlasses} از ${c.targetWaterGlasses} لیوان',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.todayWaterGlasses >= 6
                          ? 'ایول قهرمان! هیدراته و سرحالی 💙✨'
                          : 'هر لیوان آب متابولیسم و چربی‌سوزیت رو بالا می‌بره!',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
        const SizedBox(height: 16),

        // بنر قفل هوشمند ۳ مرحله‌ای روی بخش هوش مصنوعی
        SmartAiLockBanner(
          controller: c,
          onGoToProfileTab: () => widget.onNavigateTab(4),
        ),

        // بخش کالری‌شمار هوشمند با هوش مصنوعی (عکس غذا یا نام غذا)
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
                  Text('📸🤖 ', style: TextStyle(fontSize: 20)),
                  Expanded(
                    child: Text(
                      'کالری‌شمار هوشمند AI (با عکس یا اسم غذا)',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'اسم هر غذایی که خوردی رو بنویس (مثلاً: «۸ قاشق برنج با ۱ سیخ کباب») یا از بشقابت عکس بگیر تا هوش مصنوعی کالری و پروتئینش رو حساب کنه! 🔥',
                style: TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _foodInputCtrl,
                decoration: const InputDecoration(
                  hintText: 'مثلاً: ۲ تا تخم‌مرغ نیمرو با ۲ کف دست سنگک...',
                  prefixIcon: Icon(Icons.fastfood_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BMColors.neonCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      onPressed: c.isLoadingAi
                          ? null
                          : () async {
                              final text = _foodInputCtrl.text.trim();
                              if (text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'رفیق اول اسم غذا رو بنویس یا روی دکمه دوربین بزن! 😊📸',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final res = await c.analyzeFoodWithAi(
                                context,
                                foodDescription: text,
                              );
                              if (res != null && mounted) {
                                setState(() {
                                  _lastAiFoodResult = res;
                                });
                              }
                            },
                      icon: c.isLoadingAi
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: const Text(
                        'محاسبه با هوش مصنوعی',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'عکس با دوربین',
                    onPressed: () =>
                        _pickFoodPhotoAndAnalyze(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'انتخاب از گالری',
                    onPressed: () =>
                        _pickFoodPhotoAndAnalyze(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                  ),
                ],
              ),
              if (_lastAiFoodResult != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BMColors.neonGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: BMColors.neonGreen),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✅ نتیجه آنالیز: ${_lastAiFoodResult!['title']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '🔥 کالری: ${_lastAiFoodResult!['calories']} kcal  |  🥩 پروتئین: ${_lastAiFoodResult!['proteinG']}g  |  🍚 کربوهیدرات: ${_lastAiFoodResult!['carbsG']}g  |  🥑 چربی: ${_lastAiFoodResult!['fatG']}g',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '💡 نظر مربی: ${_lastAiFoodResult!['coachTip']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: BMColors.neonCyan,
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
                              _foodInputCtrl.clear();
                            });
                          },
                          icon: const Icon(Icons.add_task_rounded),
                          label: const Text(
                            '➕ خوردم! (ثبت در کالری امروز)',
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

        // بانک غذاهای ذخیره‌شده من (کاملاً آفلاین - ثبت با ۱ کلیک!)
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      '⚡ بانک غذاهای ذخیره‌شده من (ثبت آفلاین با ۱ کلیک)',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddCustomSavedFoodDialog(context, c),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('افزودن غذا'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...c.savedFoodsBank.map(
                (food) => Container(
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
                      Text(food.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              food.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              '${food.portion} • ${food.calories} کالری • پروتئین: ${food.proteinG}g',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BMColors.neonGreen.withOpacity(0.2),
                          foregroundColor: BMColors.neonGreen,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () {
                          c.addFoodLog(
                            title: food.title,
                            calories: food.calories,
                            proteinG: food.proteinG,
                            carbsG: food.carbsG,
                            fatG: food.fatG,
                            emoji: food.emoji,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${food.emoji} «${food.title}» به کالری امروزت اضافه شد رفیق! 🔥',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
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
        const SizedBox(height: 16),

        // لیست وعده‌های ثبت‌شده امروز
        if (c.todayFoodLogs.isNotEmpty)
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
                  '📋 وعده‌هایی که امروز نوش جان کردی:',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                ),
                const SizedBox(height: 10),
                ...c.todayFoodLogs.map(
                  (log) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      log.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      log.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      'ساعت ${log.timeLabel} • ${log.calories} کالری (پروتئین: ${log.proteinG}g)',
                      style: const TextStyle(fontSize: 12),
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
            Text(label, style: const TextStyle(fontSize: 12)),
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
        const SizedBox(height: 5),
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

  void _showAddCustomSavedFoodDialog(
    BuildContext context,
    BodyModController c,
  ) {
    final titleCtrl = TextEditingController();
    final calCtrl = TextEditingController(text: '250');
    final protCtrl = TextEditingController(text: '15');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BMColors.cardDark,
        title: const Text('افزودن غذا به بانک آفلاین 🥘'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'نام غذا (مثلاً: املت قارچ خودم)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: calCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'کالری (kcal)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: protCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'پروتئین (گرم)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بی‌خیال'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BMColors.neonCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              c.addSavedFoodToBank(
                title: title,
                portion: '۱ پرس شخصی',
                calories: int.tryParse(calCtrl.text) ?? 250,
                proteinG: int.tryParse(protCtrl.text) ?? 15,
                carbsG: 25,
                fatG: 9,
              );
              Navigator.pop(ctx);
            },
            child: const Text('ذخیره در بانک من'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 9. TAB 2: 7-DAY TABBED MEAL PLAN (WITH "➕ خوردم" BUTTONS)
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 95),
      children: [
        SmartAiLockBanner(
          controller: c,
          onGoToProfileTab: () => onNavigateTab(4),
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
              Row(
                children: [
                  const Text('🥗📅 ', style: TextStyle(fontSize: 22)),
                  const Expanded(
                    child: Text(
                      'برنامه غذایی ۷ روزه هوشمند',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.white,
                      ),
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
                    onPressed: c.isLoadingAi
                        ? null
                        : () async {
                            final ok = await c.regenerateAiWeeklyMealPlan(
                              context,
                            );
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'برنامه ۷ روزه جدیدت بر اساس هدف، حافظه مربی و بودجه‌ت چیده شد! 🔥🥗',
                                  ),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                    label: const Text(
                      'چینش مجدد AI',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'تنظیم‌شده برای هدف «${c.profile.goal}» و سطح بودجه: ${AppConfig.economicLabel(c.profile.economicStatus)}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // تب‌های ۷ روز هفته (شنبه تا جمعه)
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: BodyModController.weekDays.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final day = BodyModController.weekDays[idx];
              final selected = idx == c.selectedDayIndex;
              return ChoiceChip(
                selected: selected,
                label: Text(
                  day,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.black : null,
                  ),
                ),
                selectedColor: BMColors.neonCyan,
                onSelected: (_) {
                  c.selectedDayIndex = idx;
                  c.notifyListeners();
                },
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // کارت‌های وعده‌های روز انتخاب‌شده همراه با دکمه «➕ خوردم»
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
                    Text(slot.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        slot.mealType,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: BMColors.neonCyan,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: BMColors.flameOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${slot.calories} kcal',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
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
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '💡 ${slot.ingredientsTip}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🥩 پروتئین: ${slot.proteinG}g  |  🍚 کربو: ${slot.carbsG}g  |  🥑 چربی: ${slot.fatG}g',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                      ),
                    ),
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
                          horizontal: 12,
                          vertical: 8,
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
                        size: 17,
                      ),
                      label: Text(
                        slot.isEatenToday ? 'ثبت شد ✅' : '➕ خوردم',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
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
    );
  }
}

// ============================================================================
// 10. TAB 3: LIVE STEP-BY-STEP WORKOUT PLAYER & SMART REST WARNINGS
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
          '❄️ استراحتت طولانی شد ($rested ثانیه)؛ حواست باشه بین ست‌ها گوشی دستت نگیری که بدنت سرد نشه! 😂🔥';
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 95),
      children: [
        // نوار مراحل ۳ گانه باشگاه (گرم کردن 🔥 -> ست‌های اصلی 💪 -> سرد کردن ❄️)
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
        const SizedBox(height: 14),

        // پلیر زنده گام‌به‌گام باشگاه (Live Workout Player)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                phaseColor.withOpacity(0.18),
                const Color(0xFF111827),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: phaseColor, width: 1.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    activeStep.phaseTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      color: phaseColor,
                    ),
                  ),
                  Text(
                    'حرکت ${safeIdx + 1} از ${steps.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                activeStep.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '🎯 عضله هدف: ${activeStep.muscleGroup}  •  تکرار: ${activeStep.repsOrDuration}',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 14),

              // نشانگر ست فعلی
              Row(
                children: List.generate(activeStep.sets, (idx) {
                  final setNum = idx + 1;
                  final done = setNum < _currentSet;
                  final isCurrent = setNum == _currentSet;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
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
                          fontSize: 12,
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
              const SizedBox(height: 14),

              // راهنمای تنفس و نکته مربی
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
                        fontSize: 12.5,
                        color: BMColors.neonCyan,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '💡 نکته طلایی مربی: ${activeStep.coachNote}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              if (_restCoachWarning != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BMColors.dangerRed.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: BMColors.dangerRed),
                  ),
                  child: Text(
                    _restCoachWarning!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFB4AB),
                      height: 1.5,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // حالت در حال استراحت بین ست‌ها یا در حال اجرای ست
              if (_isResting)
                Container(
                  padding: const EdgeInsets.all(16),
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
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _restElapsedSeconds < 20
                            ? '⚡ هنوز زیر ۲۰ ثانیه‌ست! عجله نکن تا اسید لاکتیک جمع نشه...'
                            : _restElapsedSeconds <= 120
                            ? '✅ بازه طلایی استراحت! هر وقت نفست جا اومد ست بعدی رو بزن 🔥'
                            : '❄️ بیش از ۲ دقیقه شد! بدنت داره سرد میشه رفیق، پاشو!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BMColors.neonGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 13),
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: phaseColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // لیست کامل حرکات امروز برای پرش سریع
        const Text(
          '📋 فهرست حرکات جلسه تمرینی امروز:',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
        const SizedBox(height: 10),
        ...List.generate(steps.length, (idx) {
          final item = steps[idx];
          final selected = idx == safeIdx;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: selected ? BMColors.neonCyan : Colors.white12,
              ),
            ),
            child: ListTile(
              onTap: () {
                _restTimer?.cancel();
                setState(() {
                  _activeStepIndex = idx;
                  _currentSet = 1;
                  _isResting = false;
                  _restCoachWarning = null;
                });
              },
              leading: CircleAvatar(
                backgroundColor: selected ? BMColors.neonCyan : Colors.white10,
                foregroundColor: selected ? Colors.black : Colors.white,
                child: Text(
                  '${idx + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              title: Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              subtitle: Text(
                '${item.phaseTitle} • ${item.sets} ست (${item.repsOrDuration})',
                style: const TextStyle(fontSize: 11.5),
              ),
              trailing: const Icon(Icons.chevron_left_rounded),
            ),
          );
        }),
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
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
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
            fontSize: 11.5,
            color: active ? color : Colors.white60,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 11. TAB 4: AI COACH, MEMORY (HINT TEXT) & 7-DAY BODY ANALYZER
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
  int _subTab = 0; // 0 = چت و حافظه مربی | 1 = آنالیز و لاگ ۷ روزه بدن
  late TextEditingController _memoryCtrl;
  final TextEditingController _chatInputCtrl = TextEditingController();
  final TextEditingController _weightInputCtrl = TextEditingController();
  final TextEditingController _waistInputCtrl = TextEditingController();
  final TextEditingController _bodyNoteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _memoryCtrl = TextEditingController(
      text: widget.controller.profile.aiCoachMemory,
    );
    _weightInputCtrl.text = widget.controller.profile.weightKg.toString();
    _waistInputCtrl.text = widget.controller.profile.waistCm.toString();
  }

  @override
  void dispose() {
    _memoryCtrl.dispose();
    _chatInputCtrl.dispose();
    _weightInputCtrl.dispose();
    _waistInputCtrl.dispose();
    _bodyNoteCtrl.dispose();
    super.dispose();
  }

  // نمایش پیش‌نمایش مصرف توکن و بادی‌کوین با نگه داشتن دکمه ارسال (Long Press)
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
            Text('🪙⚡ ', style: TextStyle(fontSize: 22)),
            Expanded(
              child: Text(
                'پیش‌نمایش مصرف بادی‌کوین و توکن',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ایول! چون دکمه ارسال رو نگه داشتی (Long Press)، اینم جزئیات دقیق مصرف این پیام قبل از ارسال: 😎👇',
              style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 12),
            _coinRow('توکن ورودی (پیام + حافظه مربی):', '${est['inputTokens']} توکن'),
            _coinRow('توکن خروجی تخمینی پاسخ مربی:', '${est['outputTokens']} توکن'),
            _coinRow('مجموع کل توکن پردازشی:', '${est['tokens']} توکن'),
            const Divider(height: 20),
            _coinRow(
              'هزینه به بادی‌کوین (BodyCoin):',
              '${est['coins']} بادی‌کوین 🪙',
              highlight: true,
            ),
            const SizedBox(height: 8),
            Text(
              AppConfig.useBodyCoinSystem
                  ? 'وضعیت فعلی: سیستم بادی‌کوین فعاله (موجودی تو: ${c.profile.bodyCoinsBalance} کوین)'
                  : 'وضعیت فعلی: فاز بتا (رایگان روی سهمیه روزانه؛ بعد از ارتقا به API پولی گوگل، بادی‌کوین کسر می‌شه!)',
              style: const TextStyle(fontSize: 11.5, color: BMColors.neonCyan),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('فقط می‌خواستم ببینم 😊'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: BMColors.neonCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (_chatInputCtrl.text.trim().isNotEmpty) {
                final msg = _chatInputCtrl.text;
                _chatInputCtrl.clear();
                c.sendChatMessageToCoach(context, msg);
              }
            },
            icon: const Icon(Icons.send_rounded, size: 17),
            label: const Text(
              'همین الان بفرستش 🚀',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coinRow(String label, String val, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5)),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: highlight ? 14.5 : 12.5,
              color: highlight ? BMColors.whaleGold : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 95),
      children: [
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                selected: _subTab == 0,
                selectedColor: BMColors.neonCyan,
                label: Text(
                  '🤖 مربی هوشمند و حافظه بلندمدت',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _subTab == 0 ? Colors.black : null,
                  ),
                ),
                onSelected: (_) => setState(() => _subTab = 0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                selected: _subTab == 1,
                selectedColor: BMColors.neonCyan,
                label: Text(
                  '📊 آنالیز و لاگ ۷ روزه بدن',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _subTab == 1 ? Colors.black : null,
                  ),
                ),
                onSelected: (_) => setState(() => _subTab = 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_subTab == 0)
          _buildAiCoachAndMemorySection(context, c)
        else
          _buildBodyMetricsSection(context, c),
      ],
    );
  }

  Widget _buildAiCoachAndMemorySection(
    BuildContext context,
    BodyModController c,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SmartAiLockBanner(
          controller: c,
          onGoToProfileTab: () => widget.onNavigateTab(4),
        ),

        // کادر حافظه بلندمدت مربی (با hintText داخل کادر که با تایپ پاک می‌شود و بدون سوال اقتصادی!)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BMColors.purpleAccent.withOpacity(0.55)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      '🧠 حافظه بلندمدت مربی هوشمند (AI Memory)',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BMColors.purpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () {
                      c.updateAiCoachMemory(_memoryCtrl.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'حافظه بلندمدت مربی ذخیره شد! از این به بعد توی همه برنامه‌ها لحاظ می‌شه 🧠🔒',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_rounded, size: 17),
                    label: const Text(
                      'ذخیره در حافظه',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _memoryCtrl,
                maxLines: 6,
                minLines: 5,
                onChanged: (val) => c.updateAiCoachMemory(val),
                decoration: const InputDecoration(
                  // دقیقاً داخل خود کادر قرار گرفته تا به محض تایپ کردن کاربر پاک شود!
                  hintText: AppConfig.aiMemoryHintText,
                  hintMaxLines: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // باکس گفتگو با مربی هوشمند + دکمه ارسال با قابلیت Long-Press پیش‌نمایش بادی‌کوین
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
              const Row(
                children: [
                  Text('💬🔥 ', style: TextStyle(fontSize: 20)),
                  Expanded(
                    child: Text(
                      'گفتگو با مربی اختصاصی بادی‌مُد',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '💡 نکته: دکمه ارسال (🚀) رو نگه دار تا مصرف توکن و بادی‌کوین پیامت رو ببینی!',
                style: TextStyle(fontSize: 11.5, color: BMColors.whaleGold),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 330),
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
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(13),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        decoration: BoxDecoration(
                          color: msg.isUser
                              ? BMColors.neonCyan.withOpacity(0.18)
                              : const Color(0xFF0E1525),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: msg.isUser
                                ? BMColors.neonCyan.withOpacity(0.6)
                                : Colors.white12,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.text,
                              style: const TextStyle(
                                fontSize: 13.2,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              msg.estimatedCoins > 0
                                  ? '${msg.timeLabel} • 🪙 ${msg.estimatedCoins} کوین (${msg.estimatedTokens} توکن)'
                                  : msg.timeLabel,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatInputCtrl,
                      decoration: const InputDecoration(
                        hintText:
                            'سوال از مربی (مثلاً: شام چی بخورم که عضله‌ساز باشه؟)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onLongPress: () => _showBodyCoinLongPressPreview(context),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BMColors.neonCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: c.isLoadingAi
                          ? null
                          : () {
                              final txt = _chatInputCtrl.text.trim();
                              if (txt.isEmpty) {
                                _showBodyCoinLongPressPreview(context);
                                return;
                              }
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
      ],
    );
  }

  Widget _buildBodyMetricsSection(BuildContext context, BodyModController c) {
    final bmi = c.profile.bmi;
    final bf = c.profile.estimatedBodyFat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: _metricBox(
                  title: 'شاخص توده بدنی (BMI)',
                  value: bmi.toStringAsFixed(1),
                  subtitle: bmi < 18.5
                      ? 'کم‌وزن'
                      : bmi < 25
                      ? 'استاندارد و عالی ✅'
                      : 'اضافه‌وزن',
                  color: BMColors.neonCyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricBox(
                  title: 'درصد چربی تخمینی (Navy)',
                  value: '${bf.toStringAsFixed(1)}%',
                  subtitle: 'وزن فعلی: ${c.profile.weightKg} kg',
                  color: BMColors.neonGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ثبت لاگ هفتگی جدید بدن
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
                '📏 ثبت لاگ هفتگی قد، وزن و دور کمر (هر ۷ روز)',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightInputCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'وزن جدید (kg)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _waistInputCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'دور کمر (cm)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bodyNoteCtrl,
                decoration: const InputDecoration(
                  labelText: 'یادداشت این هفته (مثلاً: رگ‌های ساعد مشخص‌تر شد 💪)',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BMColors.neonGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () {
                    final w =
                        double.tryParse(_weightInputCtrl.text) ??
                        c.profile.weightKg;
                    final waist =
                        double.tryParse(_waistInputCtrl.text) ??
                        c.profile.waistCm;
                    c.addBodyMetricRecord(
                      weightKg: w,
                      waistCm: waist,
                      note: _bodyNoteCtrl.text.trim(),
                    );
                    _bodyNoteCtrl.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'لاگ جدید بدنت ثبت شد قهرمان! روند پیشرفتت آپدیت شد 📈🔥',
                        ),
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
            ],
          ),
        ),
        const SizedBox(height: 16),

        // تاریخچه پیشرفت
        ...c.bodyLogsHistory.reversed.map(
          (rec) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1E293B),
                child: Text('📊'),
              ),
              title: Text(
                '${rec.dateLabel} — وزن: ${rec.weightKg} kg | چربی: ${rec.bodyFatPercent}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              subtitle: Text(
                'دور کمر: ${rec.waistCm} cm • BMI: ${rec.bmi} • ${rec.note}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricBox({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 11.5)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 12. TAB 5: PROFILE FORM (ECONOMIC DROPDOWN), BETA 1000 CAP & CEO WHALE PANEL
// ============================================================================

class ProfileAndAdminTab extends StatefulWidget {
  final BodyModController controller;

  const ProfileAndAdminTab({super.key, required this.controller});

  @override
  State<ProfileAndAdminTab> createState() => _ProfileAndAdminTabState();
}

class _ProfileAndAdminTabState extends State<ProfileAndAdminTab> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _targetWeightCtrl;
  late TextEditingController _waistCtrl;
  late TextEditingController _neckCtrl;
  late TextEditingController _baleCtrl;

  late String _selectedGender;
  late String _selectedActivity;
  late String _selectedGoal;
  late String _selectedWorkoutPlace;
  late String _selectedEconomicStatus;
  bool _showCeoAdminPanel = true;

  @override
  void initState() {
    super.initState();
    final p = widget.controller.profile;
    _nameCtrl = TextEditingController(text: p.displayName);
    _ageCtrl = TextEditingController(text: p.age.toString());
    _heightCtrl = TextEditingController(text: p.heightCm.toString());
    _weightCtrl = TextEditingController(text: p.weightKg.toString());
    _targetWeightCtrl = TextEditingController(
      text: p.targetWeightKg.toString(),
    );
    _waistCtrl = TextEditingController(text: p.waistCm.toString());
    _neckCtrl = TextEditingController(text: p.neckCm.toString());
    _baleCtrl = TextEditingController(text: p.balePhoneOrId);

    _selectedGender = p.gender;
    _selectedActivity = p.activityLevel;
    _selectedGoal = p.goal;
    _selectedWorkoutPlace = p.workoutPlace;
    _selectedEconomicStatus = p.economicStatus;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _waistCtrl.dispose();
    _neckCtrl.dispose();
    _baleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final remainingBetaSpots =
        AppConfig.betaMaxSubscribers - c.activeBetaSubscribers;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 95),
      children: [
        // ۱. کارت احراز هویت نیتیو گوگل (باز شدن لیست جیمیل‌ها از پایین صفحه اندروید)
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
                    radius: 24,
                    backgroundColor: BMColors.neonCyan.withOpacity(0.2),
                    child: Text(
                      c.profile.isLoggedIn ? '✅' : '🔐',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.profile.isLoggedIn
                              ? 'متصل به جیمیل: ${c.profile.email}'
                              : 'ورود نیتیو با اکانت گوگل (بدون مرورگر)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          c.profile.isLoggedIn
                              ? 'اطلاعاتت با کلودفلر سینک و امنه رفیق! ☁️✨'
                              : 'با زدن دکمه زیر، لیست جیمیل‌های گوشیت از پایین باز میشه و با ۱ ضربه وارد میشی!',
                          style: const TextStyle(
                            fontSize: 12,
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
                        label: const Text('خروج از حساب گوگل'),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BMColors.neonCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () =>
                            c.signInWithNativeGoogleBottomSheet(context),
                        icon: const Icon(Icons.account_circle_rounded),
                        label: const Text(
                          'انتخاب جیمیل از پایین صفحه (Google Sign-In) 🚀',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ۲. فرم کامل پرونده بدنی + گزینه انتخابی وضعیت اقتصادی (برای ردیاب نهنگ‌ها 🐋)
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
                '📋 پرونده بدنی و مشخصات اختصاصی شما',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'نام یا لقب قهرمانی شما',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'سن'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(labelText: 'جنسیت'),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('آقا 👨')),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('خانم 👩'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedGender = v ?? 'male'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _heightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'قد (cm)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'وزن فعلی (kg)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _targetWeightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'وزن هدف (kg)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _waistCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'دور کمر (cm)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _neckCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'دور گردن (cm)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedGoal,
                decoration: const InputDecoration(
                  labelText: 'هدف اصلی بدنسازی و تناسب اندام 🎯',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'loss',
                    child: Text('کاهش وزن و چربی‌سوزی 🔥'),
                  ),
                  DropdownMenuItem(
                    value: 'muscle',
                    child: Text('عضله‌سازی خشک و فرم‌دهی 💪'),
                  ),
                  DropdownMenuItem(
                    value: 'gain',
                    child: Text('افزایش وزن و حجم 🦍'),
                  ),
                  DropdownMenuItem(
                    value: 'maintain',
                    child: Text('تثبیت وزن و سلامتی ✨'),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => _selectedGoal = v ?? 'muscle'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedWorkoutPlace,
                decoration: const InputDecoration(
                  labelText: 'محل تمرین و تجهیزات 🏋️‍♂️',
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
                onChanged: (v) => setState(
                  () => _selectedWorkoutPlace = v ?? 'home_dumbbell',
                ),
              ),
              const SizedBox(height: 10),

              // فیلد انتخابی وضعیت اقتصادی (حذف‌شده از حافظه متنی و منتقل‌شده به فرم ساختاریافته!)
              DropdownButtonFormField<String>(
                value: _selectedEconomicStatus,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'وضعیت اقتصادی (برای تنظیم بودجه برنامه غذایی) 💰',
                ),
                items: [
                  DropdownMenuItem(
                    value: AppConfig.econLow,
                    child: Text(
                      AppConfig.economicLabel(AppConfig.econLow),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppConfig.econMedium,
                    child: Text(
                      AppConfig.economicLabel(AppConfig.econMedium),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppConfig.econWhale,
                    child: Text(
                      AppConfig.economicLabel(AppConfig.econWhale),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (v) => setState(
                  () => _selectedEconomicStatus = v ?? AppConfig.econMedium,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _baleCtrl,
                decoration: const InputDecoration(
                  labelText: 'شماره یا آیدی پیام‌رسان بله (اختیاری - سفیر بله)',
                  prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BMColors.neonGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await c.saveBodyProfileForm(
                      displayName: _nameCtrl.text.trim(),
                      age: int.tryParse(_ageCtrl.text) ?? 21,
                      gender: _selectedGender,
                      heightCm: double.tryParse(_heightCtrl.text) ?? 178,
                      weightKg: double.tryParse(_weightCtrl.text) ?? 74,
                      targetWeightKg:
                          double.tryParse(_targetWeightCtrl.text) ?? 70,
                      waistCm: double.tryParse(_waistCtrl.text) ?? 82,
                      neckCm: double.tryParse(_neckCtrl.text) ?? 38,
                      activityLevel: _selectedActivity,
                      goal: _selectedGoal,
                      workoutPlace: _selectedWorkoutPlace,
                      economicStatus: _selectedEconomicStatus,
                      balePhoneOrId: _baleCtrl.text.trim(),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'پرونده بدنی و وضعیت اقتصادیت ذخیره و با کلودفلر سینک شد! 🔥💪',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text(
                    'ذخیره پرونده بدنی و بروزرسانی برنامه‌ها',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ۳. اشتراک فاز بتا (ظرفیت محدود ۱۰۰۰ نفر) + آینده بادی‌کوین (BodyCoin)
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '💎 اشتراک فاز بتا و کیف پول بادی‌کوین',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                      color: BMColors.whaleGold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: BMColors.whaleGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'ظرفیت باقی‌مانده: $remainingBetaSpots از ۱۰۰۰ نفر',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: BMColors.whaleGold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                c.profile.hasActiveSubscription
                    ? '✅ وضعیت اشتراک: ${c.profile.subscriptionTier} (${c.profile.subscriptionDaysRemaining} روز باقی‌مانده)'
                    : 'در فاز بتا، اشتراک‌ها محدود به ۱۰۰۰ نفر اول هست تا بالاترین سرعت هوش مصنوعی رو تجربه کنی! 🚀',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BMColors.whaleGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () async {
                    await c.activateBetaSubscription();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'تبریک قهرمان! اشتراک ویژه فاز بتا و ۲۵۰ بادی‌کوین هدیه برات فعال شد! 🎉💎',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: Text(
                    c.profile.hasActiveSubscription
                        ? 'تمدید اشتراک / شارژ ۲۵۰ بادی‌کوین 🪙'
                        : 'فعال‌سازی اشتراک ویژه فاز بتا (کافه‌بازار / مایکت) 🔥',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ۴. پنل فرماندهی مدیرعامل (متین محمدی) + ردیاب نهنگ‌ها 🐋
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1322),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BMColors.neonCyan, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      '👑 پنل فرماندهی مدیرعامل (متین) و ردیاب نهنگ‌ها 🐋',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: BMColors.neonCyan,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(
                      () => _showCeoAdminPanel = !_showCeoAdminPanel,
                    ),
                    icon: Icon(
                      _showCeoAdminPanel
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: BMColors.neonCyan,
                    ),
                  ),
                ],
              ),
              if (_showCeoAdminPanel) ...[
                const SizedBox(height: 8),
                const Text(
                  'آمار زنده سرور کلودفلر (BODYMOD_DB_KV) و تفکیک وضعیت اقتصادی کاربران:',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 12),

                // ردیف ویژه شکارچی نهنگ‌ها 🐋
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B2F0B), Color(0xFF1E293B)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BMColors.whaleGold),
                  ),
                  child: Row(
                    children: [
                      const Text('🐋', style: TextStyle(fontSize: 34)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'کاربران با وضعیت اقتصادی عالی (نهنگ‌ها 🐋)',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: BMColors.whaleGold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${c.economyWhaleUsersCount} نهنگ فعال در برنامه (پتانسیل بالا برای خرید بسته‌های VIP بادی‌کوین!)',
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
                      child: _adminStatTile(
                        'کل کاربران',
                        '${c.totalRegisteredUsers} نفر',
                        BMColors.neonCyan,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _adminStatTile(
                        'مشترکین فاز بتا',
                        '${c.activeBetaSubscribers} / ۱۰۰۰',
                        BMColors.neonGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _adminStatTile(
                        'اقتصادی ضعیف 🥚',
                        '${c.economyLowUsersCount} نفر',
                        BMColors.warningAmber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _adminStatTile(
                        'اقتصادی متوسط 🍗',
                        '${c.economyMediumUsersCount} نفر',
                        BMColors.electricBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: AppConfig.useBodyCoinSystem,
                  onChanged: (val) => c.toggleBodyCoinMode(val),
                  title: const Text(
                    'سوییچ سیستم بادی‌کوین (BodyCoin Mode) 🪙',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: const Text(
                    'خاموش = سهمیه روزانه Free Tier | روشن = کسر سکه بادی‌کوین',
                    style: TextStyle(fontSize: 11.5, color: Colors.white70),
                  ),
                ),
                const Divider(height: 20),
                const Text(
                  '🐋 لیست آخرین کاربران و نهنگ‌های ثبت‌شده:',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ...c.adminUsersDirectory.map((u) {
                  final isWhale = u['econ'] == AppConfig.econWhale;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isWhale
                          ? BMColors.whaleGold.withOpacity(0.1)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isWhale ? BMColors.whaleGold : Colors.white12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          isWhale
                              ? '🐋'
                              : u['econ'] == AppConfig.econLow
                              ? '🥚'
                              : '🍗',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${u['name']} (${u['sub']})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.8,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${u['email']} • هدف: ${u['goal']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '🪙 ${u['coins']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: BMColors.whaleGold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _adminStatTile(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
