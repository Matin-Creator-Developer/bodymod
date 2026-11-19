import os

main_path = "lib/main.dart"
billing_stub_path = "lib/store_billing.dart"
bazaar_yml = ".github/workflows/build-cafebazaar.yml"
myket_yml = ".github/workflows/build-myket.yml"

def safe_replace(text, old, new, label, fname):
    if old in text:
        print(f"✅ [{fname}] {label}")
        return text.replace(old, new, 1)
    else:
        print(f"⚠️ [{fname}] Skipped (not found or already patched): {label}")
        return text

# ============================================================================
# 1. CREATE DEFAULT lib/store_billing.dart (Replaced per-store in CI builds)
# ============================================================================
stub_code = r"""import 'package:url_launcher/url_launcher.dart';

class BmStoreBilling {
  static const String storeFlavor = String.fromEnvironment('STORE_FLAVOR', defaultValue: 'market');
  static const String rsaKey = String.fromEnvironment('STORE_RSA_KEY', defaultValue: '');

  static Future?> purchase({
    required String sku,
    String payload = '',
    bool consumeImmediately = true,
  }) async {
    return null;
  }

  static Future<void> openStoreUpdate() async {
    final uri = Uri.parse(
      storeFlavor == 'myket'
          ? 'myket://details?id=ir.matinmohammadi.bodymod'
          : 'bazaar://details?id=ir.matinmohammadi.bodymod',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        final web = Uri.parse(
          storeFlavor == 'myket'
              ? 'https://myket.ir/app/ir.matinmohammadi.bodymod'
              : 'https://cafebazaar.ir/app/ir.matinmohammadi.bodymod',
        );
        await launchUrl(web, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}
"""
with open(billing_stub_path, "w", encoding="utf-8") as f:
    f.write(stub_code)
print("✅ [lib/store_billing.dart] Created store billing adapter")

# ============================================================================
# 2. PATCH lib/main.dart (Connect Native Billing Popup & Force Update Button)
# ============================================================================
with open(main_path, "r", encoding="utf-8") as f:
    dart = f.read()

if "import 'store_billing.dart';" not in dart:
    dart = safe_replace(
        dart,
        "import 'package:video_player/video_player.dart';",
        "import 'package:video_player/video_player.dart';\nimport 'store_billing.dart';",
        "Import store_billing.dart",
        "main.dart",
    )

# وصل کردن دکمه پاپ‌آپ آپدیت به مارکت مربوطه
dart = safe_replace(
    dart,
    """            onPressed: () {},
            icon: const Icon(Icons.system_update_rounded, color: Colors.black),""",
    """            onPressed: () => BmStoreBilling.openStoreUpdate(),
            icon: const Icon(Icons.system_update_rounded, color: Colors.black),""",
    "Wire force-update popup button to store update page",
    "main.dart",
)

# وصل کردن خرید اشتراک ۱ ماهه به پاپ‌آپ نیتیو بازار / مایکت
old_sub_invoke = """      // فراخوانی درگاه پرداخت درون‌برنامه‌ای کافه‌بازار / مایکت
      final dynamic billingResult = await AppConfig.marketBillingChannel
          .invokeMethod('purchaseSubscription', {
            'sku': sku,
            'priceToman': discountedSubscriptionPriceToman,
            'userKey': profile.userKey,
          });"""

new_sub_invoke = """      // فراخوانی پاپ‌آپ پرداخت درون‌برنامه‌ای نیتیو کافه‌بازار / مایکت
      final dynamic billingResult = await BmStoreBilling.purchase(
        sku: sku,
        payload: profile.userKey,
        consumeImmediately: true,
      );"""

dart = safe_replace(dart, old_sub_invoke, new_sub_invoke, "Connect subscription to native Bazaar/Myket popup", "main.dart")

# وصل کردن حمایت مالی نامحدود به پاپ‌آپ نیتیو بازار / مایکت
old_don_invoke = """      final dynamic billingResult = await AppConfig.marketBillingChannel
          .invokeMethod('purchaseConsumableDonation', {
            'sku': sku,
            'amountToman': amountToman,
            'consumeImmediately': true, // قابلیت خرید چندباره و نامحدود (حتی ۱۰ بار پشت سر هم!)
          });"""

new_don_invoke = """      final dynamic billingResult = await BmStoreBilling.purchase(
        sku: sku,
        payload: profile.userKey,
        consumeImmediately: true, // قابلیت خرید چندباره و نامحدود (حتی ۱۰ بار پشت سر هم!)
      );"""

dart = safe_replace(dart, old_don_invoke, new_don_invoke, "Connect unlimited donations to native Bazaar/Myket popup", "main.dart")

with open(main_path, "w", encoding="utf-8") as f:
    f.write(dart)

# ============================================================================
# 3. PATCH build-cafebazaar.yml (Inject flutter_poolakey ONLY in Bazaar build)
# ============================================================================
with open(bazaar_yml, "r", encoding="utf-8") as f:
    b_code = f.read()

bazaar_step = """      - name: Configure CafeBazaar Native In-App Billing (Poolakey)
        run: |
          if ! grep -q "flutter_poolakey:" pubspec.yaml; then
            sed -i '/url_launcher:/a\\  flutter_poolakey: ^2.2.0+1.0.0' pubspec.yaml
          fi
          cat << 'BAZAAR_BILLING_EOF' > lib/store_billing.dart
          import 'dart:async';
          import 'package:flutter_poolakey/flutter_poolakey.dart';
          import 'package:url_launcher/url_launcher.dart';

          class BmStoreBilling {
            static const String storeFlavor = 'bazaar';
            static const String rsaKey = String.fromEnvironment('STORE_RSA_KEY', defaultValue: '');

            static Future?> purchase({
              required String sku,
              String payload = '',
              bool consumeImmediately = true,
            }) async {
              if (rsaKey.trim().isEmpty) return null;
              try {
                final completer = Completer<bool>();
                await FlutterPoolakey.connect(
                  rsaKey.trim(),
                  onSucceed: () {
                    if (!completer.isCompleted) completer.complete(true);
                  },
                  onFailed: () {
                    if (!completer.isCompleted) completer.complete(false);
                  },
                  onDisconnected: () {},
                );
                final connected = await completer.future.timeout(
                  const Duration(seconds: 8),
                  onTimeout: () => false,
                );
                if (!connected) return null;

                final purchaseInfo = await FlutterPoolakey.purchase(
                  sku,
                  payload: payload,
                );
                final token = purchaseInfo.purchaseToken;
                if (token.isNotEmpty) {
                  if (consumeImmediately) {
                    try {
                      await FlutterPoolakey.consume(token);
                    } catch (_) {}
                  }
                  return {
                    'purchaseToken': token,
                    'market': 'cafebazaar',
                    'sku': sku,
                  };
                }
              } catch (_) {}
              return null;
            }

            static Future<void> openStoreUpdate() async {
              final uri = Uri.parse('bazaar://details?id=ir.matinmohammadi.bodymod');
              try {
                final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (!ok) {
                  await launchUrl(
                    Uri.parse('https://cafebazaar.ir/app/ir.matinmohammadi.bodymod'),
                    mode: LaunchMode.externalApplication,
                  );
                }
              } catch (_) {}
            }
          }
          BAZAAR_BILLING_EOF

      - name: Build CafeBazaar Release APK (32/64-bit)"""

if "Configure CafeBazaar Native In-App Billing (Poolakey)" not in b_code:
    b_code = safe_replace(
        b_code,
        "      - name: Build CafeBazaar Release APK (32/64-bit)",
        bazaar_step,
        "Inject flutter_poolakey SDK into CafeBazaar workflow",
        "build-cafebazaar.yml",
    )
    with open(bazaar_yml, "w", encoding="utf-8") as f:
        f.write(b_code)
else:
    print("ℹ️ [build-cafebazaar.yml] Poolakey step already present")

# ============================================================================
# 4. PATCH build-myket.yml (Inject myket_iap + Maven + Placeholders ONLY in Myket)
# ============================================================================
with open(myket_yml, "r", encoding="utf-8") as f:
    m_code = f.read()

myket_step = """      - name: Configure Myket Native In-App Billing (myket_iap)
        run: |
          if ! grep -q "myket_iap:" pubspec.yaml; then
            sed -i '/url_launcher:/a\\  myket_iap: ^2.0.1' pubspec.yaml
          fi
          python3 - << 'MYKET_GRADLE_EOF'
          import os
          if os.path.exists("android/build.gradle.kts"):
              with open("android/build.gradle.kts", "r", encoding="utf-8") as f:
                  s = f.read()
              if "maven.myket.ir" not in s:
                  s = s.replace("mavenCentral()", 'mavenCentral()\\n        maven { url = uri("https://maven.myket.ir") }')
                  with open("android/build.gradle.kts", "w", encoding="utf-8") as f:
                      f.write(s)
          elif os.path.exists("android/build.gradle"):
              with open("android/build.gradle", "r", encoding="utf-8") as f:
                  s = f.read()
              if "maven.myket.ir" not in s:
                  s = s.replace("mavenCentral()", 'mavenCentral()\\n        maven { url "https://maven.myket.ir" }')
                  with open("android/build.gradle", "w", encoding="utf-8") as f:
                      f.write(s)

          if os.path.exists("android/app/build.gradle.kts"):
              with open("android/app/build.gradle.kts", "r", encoding="utf-8") as f:
                  s = f.read()
              if "marketApplicationId" not in s:
                  ph = '''        manifestPlaceholders["marketApplicationId"] = "ir.mservices.market"
                  manifestPlaceholders["marketBindAddress"] = "ir.mservices.market.InAppBillingService.BIND"
                  manifestPlaceholders["marketPermission"] = "ir.mservices.market.BILLING"
          '''
                  s = s.replace("defaultConfig {", "defaultConfig {\\n" + ph, 1)
                  with open("android/app/build.gradle.kts", "w", encoding="utf-8") as f:
                      f.write(s)
          elif os.path.exists("android/app/build.gradle"):
              with open("android/app/build.gradle", "r", encoding="utf-8") as f:
                  s = f.read()
              if "marketApplicationId" not in s:
                  ph = '''        manifestPlaceholders += [
                      marketApplicationId: "ir.mservices.market",
                      marketBindAddress: "ir.mservices.market.InAppBillingService.BIND",
                      marketPermission: "ir.mservices.market.BILLING"
                  ]
          '''
                  s = s.replace("defaultConfig {", "defaultConfig {\\n" + ph, 1)
                  with open("android/app/build.gradle", "w", encoding="utf-8") as f:
                      f.write(s)
          MYKET_GRADLE_EOF
          cat << 'MYKET_BILLING_EOF' > lib/store_billing.dart
          import 'package:myket_iap/myket_iap.dart';
          import 'package:myket_iap/util/iab_result.dart';
          import 'package:myket_iap/util/purchase.dart';
          import 'package:url_launcher/url_launcher.dart';

          class BmStoreBilling {
            static const String storeFlavor = 'myket';
            static const String rsaKey = String.fromEnvironment('STORE_RSA_KEY', defaultValue: '');

            static Future?> purchase({
              required String sku,
              String payload = '',
              bool consumeImmediately = true,
            }) async {
              if (rsaKey.trim().isEmpty) return null;
              try {
                final IabResult? initRes = await MyketIAP.init(
                  rsaKey: rsaKey.trim(),
                  enableDebugLogging: false,
                );
                if (initRes == null || !initRes.isSuccess()) return null;

                final Map resultMap = await MyketIAP.launchPurchaseFlow(
                  sku: sku,
                  payload: payload,
                );
                final IabResult? res = resultMap[MyketIAP.RESULT] as IabResult?;
                final Purchase? purchase = resultMap[MyketIAP.PURCHASE] as Purchase?;

                if (res != null && res.isSuccess() && purchase != null) {
                  final token = purchase.mToken;
                  if (consumeImmediately) {
                    try {
                      await MyketIAP.consume(purchase: purchase);
                    } catch (_) {}
                  }
                  try {
                    await MyketIAP.dispose();
                  } catch (_) {}
                  return {
                    'purchaseToken': token,
                    'market': 'myket',
                    'sku': sku,
                  };
                }
                try {
                  await MyketIAP.dispose();
                } catch (_) {}
              } catch (_) {}
              return null;
            }

            static Future<void> openStoreUpdate() async {
              final uri = Uri.parse('myket://details?id=ir.matinmohammadi.bodymod');
              try {
                final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (!ok) {
                  await launchUrl(
                    Uri.parse('https://myket.ir/app/ir.matinmohammadi.bodymod'),
                    mode: LaunchMode.externalApplication,
                  );
                }
              } catch (_) {}
            }
          }
          MYKET_BILLING_EOF

      - name: Build Myket Release APK (32/64-bit)"""

if "Configure Myket Native In-App Billing (myket_iap)" not in m_code:
    m_code = safe_replace(
        m_code,
        "      - name: Build Myket Release APK (32/64-bit)",
        myket_step,
        "Inject myket_iap SDK & Gradle placeholders into Myket workflow",
        "build-myket.yml",
    )
    with open(myket_yml, "w", encoding="utf-8") as f:
        f.write(m_code)
else:
    print("ℹ️ [build-myket.yml] Myket IAP step already present")

print("🎉 تموم شد! پرداخت پاپ‌آپ نیتیو بازار و مایکت + دکمه آپدیت کاملاً جداگانه وصل شدن! 🚀🔥")
