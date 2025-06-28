class FormValidator {
  static String? validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกข้อมูลนี้';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'กรุณากรอกอีเมล';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'กรุณากรอกอีเมลให้ถูกต้อง';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'กรุณากรอกเบอร์โทรศัพท์';
    if (value.length != 10) return 'เบอร์โทรศัพท์ต้องมี 10 หลัก';
    return null;
  }

  static String? validateTaxId(String? value) {
    if (value == null || value.isEmpty) return 'กรุณากรอกเลขประจำตัวผู้เสียภาษี';
    if (value.length != 13) return 'เลขประจำตัวผู้เสียภาษีต้องมี 13 หลัก';
    return null;
  }

  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) return 'กรุณากรอกที่อยู่';
    if (value.length < 15) return 'กรุณากรอกที่อยู่ให้ละเอียด';
    return null;
  }
}
