import 'package:url_launcher/url_launcher.dart';

class BmStoreBilling {
  static const String storeFlavor = String.fromEnvironment('STORE_FLAVOR', defaultValue: 'market');
  static const String rsaKey = String.fromEnvironment('STORE_RSA_KEY', defaultValue: '');

  static Future purchase({
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
