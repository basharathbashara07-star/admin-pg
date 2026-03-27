class PhoneValidator {
  // Validate Indian phone number
  static String? validate(String phone) {
    if (phone.isEmpty) {
      return "Phone number is required";
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      return "Phone number must be exactly 10 digits";
    }
    return null; // valid
  }
}