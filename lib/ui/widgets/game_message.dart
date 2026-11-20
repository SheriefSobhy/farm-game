import 'package:flutter/material.dart';

import '../../models/action_result.dart';

/// Shows a short message at the bottom: green for success, red for problems.
void showGameMessage(BuildContext context, ActionResult result) {
  final message = result.message;
  if (message == null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            result.ok ? const Color(0xFF43A047) : const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
}
