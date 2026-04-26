import 'package:flutter/material.dart';

class PasswordStrengthResult {
  const PasswordStrengthResult({
    required this.score,
    required this.label,
    required this.color,
  });

  final int score;
  final String label;
  final Color color;

  bool get isWeak => score <= 1;
}

class PasswordStrength {
  static PasswordStrengthResult evaluate(String password) {
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(password);

    var score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    final classes = <bool>[
      hasLower,
      hasUpper,
      hasDigit,
      hasSymbol,
    ].where((v) => v).length;
    if (classes >= 2) score++;
    if (classes >= 3) score++;

    if (password.length < 6) {
      score = 0;
    }

    if (score <= 1) {
      return const PasswordStrengthResult(
        score: 1,
        label: 'Faible',
        color: Color(0xFFFF6B6B),
      );
    }
    if (score == 2) {
      return const PasswordStrengthResult(
        score: 2,
        label: 'Moyen',
        color: Color(0xFFFFB86B),
      );
    }
    if (score == 3) {
      return const PasswordStrengthResult(
        score: 3,
        label: 'Bon',
        color: Color(0xFF70D6A1),
      );
    }

    return const PasswordStrengthResult(
      score: 4,
      label: 'Fort',
      color: Color(0xFF3DEBFF),
    );
  }
}
