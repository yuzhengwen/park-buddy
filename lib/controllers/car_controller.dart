class CarValidationController {
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

  static String? validatePlate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'License plate is required';
    }
    // Regex breakdown for Singapore (S-series):
    // ^S          - Must start with 'S'
    // [A-Z]{1,2}  - Followed by 1 or 2 letters (e.g., 'J', 'JA', 'LX')
    // \s?         - Optional space
    // [0-9]{1,4}  - 1 to 4 digits
    // \s?         - Optional space
    // [A-Z]$      - Ends with exactly 1 checksum letter
    final plateRegex = RegExp(r'^S[A-Z]{1,2}\s?[0-9]{1,4}\s?[A-Z]$');
    
    final cleanPlate = value.trim().toUpperCase();
    
    if (!plateRegex.hasMatch(cleanPlate)) {
      return 'Enter a valid license plate';
    }
    
    return null;
  }
}