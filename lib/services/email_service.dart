import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  final String smtpServer;
  final int smtpPort;
  final String username;
  final String password;
  final String fromEmail;
  final String fromName;

  EmailService({
    required this.smtpServer,
    required this.smtpPort,
    required this.username,
    required this.password,
    required this.fromEmail,
    required this.fromName,
  });

  Future<bool> sendVerificationEmail(String toEmail, String verificationCode) async {
    if (kIsWeb) {
      // For web platform, we'll use a mock implementation
      print('Sending verification email to $toEmail with code: $verificationCode');
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      return true;
    }

    // For mobile platforms, use the actual SMTP implementation
    final smtpServer = dotenv.env['SMTP_SERVER'] ?? '';
    final smtpPort = int.tryParse(dotenv.env['SMTP_PORT'] ?? '587') ?? 587;
    final smtpUsername = dotenv.env['SMTP_USERNAME'] ?? '';
    final smtpPassword = dotenv.env['SMTP_PASSWORD'] ?? '';
    final fromEmail = dotenv.env['SMTP_FROM_EMAIL'] ?? '';
    final fromName = dotenv.env['SMTP_FROM_NAME'] ?? 'ResqTail';

    final smtpConfig = SmtpServer(
      smtpServer,
      port: smtpPort,
      username: smtpUsername,
      password: smtpPassword,
      ssl: smtpPort == 465,
      allowInsecure: smtpPort != 465,
    );

    final message = Message()
      ..from = Address(fromEmail, fromName)
      ..recipients.add(toEmail)
      ..subject = 'Verify your ResqTail account'
      ..text = 'Your verification code is: $verificationCode\n\nThis code will expire in 24 hours.';

    try {
      final sendReport = await send(message, smtpConfig);
      return sendReport.toString().contains('OK');
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }
} 