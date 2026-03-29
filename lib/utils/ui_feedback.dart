import 'package:flutter/material.dart';

String formatUserFacingError(Object error) {
  var message = error.toString().trim();

  if (message.startsWith('Exception: ')) {
    message = message.substring('Exception: '.length).trim();
  }

  if (message.startsWith('[cloud_firestore/permission-denied]')) {
    return 'You do not have permission to perform that action yet. Please try again after signing in again.';
  }

  if (message.startsWith('[firebase_auth/')) {
    final closingBracket = message.indexOf(']');
    if (closingBracket != -1 && closingBracket + 1 < message.length) {
      message = message.substring(closingBracket + 1).trim();
    }
  }

  if (message.isEmpty || message == 'Error') {
    return 'Something went wrong. Please try again.';
  }

  return message;
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? const Color(0xFF9B1C1C) : null,
    ),
  );
}

void showErrorSnackBar(BuildContext context, Object error) {
  showAppSnackBar(
    context,
    formatUserFacingError(error),
    isError: true,
  );
}