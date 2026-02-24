import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:flutter/material.dart';

class ToastHelper {
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    CherryToast.success(
      title: const Text(
        'Success',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      description: Text(message),
      animationType: AnimationType.fromTop,
      animationDuration: const Duration(milliseconds: 1000),
      autoDismiss: true,
    ).show(context);
  }

  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    CherryToast.error(
      title: const Text(
        'Error',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      description: Text(message),
      animationType: AnimationType.fromTop,
      animationDuration: const Duration(milliseconds: 1000),
      autoDismiss: true,
    ).show(context);
  }

  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;
    CherryToast.info(
      title: const Text(
        'Information',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      description: Text(message),
      animationType: AnimationType.fromTop,
      animationDuration: const Duration(milliseconds: 1000),
      autoDismiss: true,
    ).show(context);
  }

  static void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;
    CherryToast.warning(
      title: const Text(
        'Warning',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      description: Text(message),
      animationType: AnimationType.fromTop,
      animationDuration: const Duration(milliseconds: 1000),
      autoDismiss: true,
    ).show(context);
  }
}
