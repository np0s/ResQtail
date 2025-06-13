import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigService {
  static String get smtpServer => dotenv.env['SMTP_SERVER'] ?? 'smtp.gmail.com';
  static int get smtpPort => int.parse(dotenv.env['SMTP_PORT'] ?? '587');
  static String get smtpUsername => dotenv.env['SMTP_USERNAME'] ?? '';
  static String get smtpPassword => dotenv.env['SMTP_PASSWORD'] ?? '';
  static String get smtpFromEmail => dotenv.env['SMTP_FROM_EMAIL'] ?? '';
  static String get smtpFromName => dotenv.env['SMTP_FROM_NAME'] ?? 'ResqTail';

  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }
} 