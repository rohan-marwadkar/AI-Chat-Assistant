import 'package:flutter/material.dart';

class CustomSnackbar {

  void showCustomSnackbar({
    required BuildContext context,
    required String message,
    Color backgroundColor = Colors.green,
    Duration duration = const Duration(seconds: 2),
  }) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(15),
      ),
    );
  }
}
