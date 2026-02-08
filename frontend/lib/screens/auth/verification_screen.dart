import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/ui_helper.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final bool isPasswordReset;

  const VerificationScreen({
    super.key,
    required this.email,
    this.isPasswordReset = false,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _codeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _handleVerification() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      UiHelper.showError(context, 'Please enter a valid 6-digit code');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.isPasswordReset) {
         // Logic handled by parent or next screen for password reset
         // Actually for password reset, we verify the code implicitly when resetting
         // But maybe we want to verify code first? 
         // For now, let's just return the code to the caller (ForgotPasswordScreen)
         Navigator.pop(context, code);
      } else {
        // Account Verification
        await _authService.verifyEmail(widget.email, code);
        if (!mounted) return;
        UiHelper.showSuccess(context, 'Account verified successfully!');
        // Navigate to Login and clear stack
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      UiHelper.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resendCode() async {
    setState(() => _isLoading = true);
    try {
      await _authService.resendVerificationCode(widget.email);
      if (!mounted) return;
      UiHelper.showSuccess(context, 'Verification code resent');
    } catch (e) {
      if (!mounted) return;
      UiHelper.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Enter the 6-digit code sent to ${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleVerification,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator()
                  : const Text('Verify'),
            ),
            TextButton(
              onPressed: _isLoading ? null : _resendCode,
              child: const Text('Resend Code'),
            ),
          ],
        ),
      ),
    );
  }
}
