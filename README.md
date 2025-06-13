# ResqTail

A Flutter application for pet rescue and management.

## Environment Setup

1. Copy the example environment file:
```bash
cp .env.example .env
```

2. Edit the `.env` file with your SMTP credentials:
```env
# SMTP Configuration
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587

# Email Credentials
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Sender Information
SMTP_FROM_EMAIL=your-email@gmail.com
SMTP_FROM_NAME=ResqTail
```

### Gmail Setup Instructions

If you're using Gmail as your SMTP server:

1. Enable 2-factor authentication in your Google Account
2. Generate an App Password:
   - Go to your Google Account settings
   - Navigate to Security
   - Under "2-Step Verification", click on "App passwords"
   - Select "Mail" and your device
   - Copy the generated 16-character password
3. Use this App Password as your `SMTP_PASSWORD` in the `.env` file

### Platform-Specific Notes

#### Web Platform
When running on web, the email functionality is simulated for development purposes. In a production environment, you should:
1. Set up a backend API to handle email sending
2. Update the `EmailService` to use your API instead of direct SMTP

#### Mobile/Desktop Platforms
The email functionality works as expected on mobile and desktop platforms using the configured SMTP server.

## Getting Started

1. Install dependencies:
```bash
flutter pub get
```

2. Set up your environment:
   - Copy `.env.example` to `.env`
   - Edit `.env` with your actual credentials

3. Run the app:
```bash
flutter run
```