class Validators {
  static String? requiredField(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label est requis';
    }
    return null;
  }

  static String? masterPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe maître est requis';
    }
    if (value.length < 10) {
      return 'Minimum 10 caractères';
    }
    return null;
  }
}
