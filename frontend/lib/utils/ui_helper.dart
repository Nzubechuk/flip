import 'package:flutter/material.dart';
import 'toast_helper.dart';

class UiHelper {
  static void showSuccess(BuildContext context, String message) {
    ToastHelper.showSuccess(context, message);
  }

  static void showError(BuildContext context, String message) {
    ToastHelper.showError(context, message);
  }

  static void showInfo(BuildContext context, String message) {
    ToastHelper.showInfo(context, message);
  }

  static Future<bool?> showLogoutConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Color(0xFFEF4444)), // Red
            SizedBox(width: 12),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)), // slateSecondary
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444), // Red
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

}
