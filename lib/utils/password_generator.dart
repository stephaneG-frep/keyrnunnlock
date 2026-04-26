import 'dart:math';

class PasswordGenerator {
  static const String _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const String _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _digits = '0123456789';
  static const String _symbols = '@#%^&*()_+-=[]{}!?';

  static String generate({
    int length = 16,
    bool withSymbols = true,
  }) {
    final random = Random.secure();
    final charset = withSymbols
        ? _lower + _upper + _digits + _symbols
        : _lower + _upper + _digits;

    return List<String>.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
