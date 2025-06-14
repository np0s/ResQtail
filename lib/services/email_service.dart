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

  Future<bool> sendVerificationEmail(
      String toEmail, String verificationCode) async {
    if (kIsWeb) {
      // For web platform, we'll use a mock implementation
      print(
          'Sending verification email to $toEmail with code: $verificationCode');
      await Future.delayed(
          const Duration(seconds: 1)); // Simulate network delay
      return true;
    }

    // For mobile platforms, use the actual SMTP implementation
    final smtpServer = dotenv.env['SMTP_SERVER'] ?? '';
    final smtpPort = int.tryParse(dotenv.env['SMTP_PORT'] ?? '587') ?? 587;
    final smtpUsername = dotenv.env['SMTP_USERNAME'] ?? '';
    final smtpPassword = dotenv.env['SMTP_PASSWORD'] ?? '';
    final fromEmail = dotenv.env['SMTP_FROM_EMAIL'] ?? '';
    final fromName = dotenv.env['SMTP_FROM_NAME'] ?? 'ResqTail';

    if (smtpServer.isEmpty || smtpUsername.isEmpty || smtpPassword.isEmpty) {
      print('Error: SMTP configuration is incomplete');
      return false;
    }

    try {
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
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #6750A4;">Welcome to ResqTail!</h2>
            <p>Thank you for registering. Please use the following code to verify your email address:</p>
            <div style="background-color: #f5f5f5; padding: 20px; text-align: center; font-size: 24px; font-weight: bold; color: #6750A4; margin: 20px 0;">
              $verificationCode
            </div>
            <p>This code will expire in 24 hours.</p>
            <p>If you didn't request this verification, please ignore this email.</p>
          </div>
        ''';

      final sendReport = await send(message, smtpConfig);
      print('Email sent successfully to $toEmail');
      return true;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }
}
