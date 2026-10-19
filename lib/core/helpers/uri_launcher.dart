import 'package:url_launcher/url_launcher.dart';

class UriLauncher {
  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  static Future<void> sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  static Future<void> openWhatsApp(String phone, {String? message}) async {
    final encoded = message != null ? '?text=$message' : '';
    final url = 'https://wa.me/$phone$encoded';
    await openUrl(url);
  }
}
