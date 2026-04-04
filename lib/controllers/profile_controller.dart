class ProfileController {
  static String? validateNickname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nickname cannot be empty';
    }
    if (value.length < 5) {
      return 'Nickname must be at least 5 characters';
    }
    if (value.length > 20) {
      return 'Keep it short! (Max 20 characters)';
    }
    return null;
  }
}