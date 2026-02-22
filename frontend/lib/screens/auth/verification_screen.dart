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
  bool _codeSent = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleVerification() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      UiHelper.showError(context, 'Please enter a valid 6-digit code');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.isPasswordReset) {
        Navigator.pop(context, code);
      } else {
        await _authService.verifyEmail(widget.email, code);
        if (!mounted) return;
        UiHelper.showSuccess(context, 'Account verified successfully!');
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      UiHelper.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendCode() async {
    setState(() => _isLoading = true);
    final isResend = _codeSent;
    try {
      await _authService.resendVerificationCode(widget.email);
      if (!mounted) return;
      setState(() => _codeSent = true);
      UiHelper.showSuccess(context, isResend ? 'Code resent to ${widget.email}' : 'Code sent to ${widget.email}');
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
            if (_codeSent)
              ElevatedButton(
                onPressed: _isLoading ? null : _handleVerification,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify'),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _sendCode,
                child: _isLoading && !_codeSent
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_codeSent ? 'Resend Code' : 'Send Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
