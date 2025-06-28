import 'package:thai_herbal_gacp_backend/models/application.dart';

class ValidationService {
  static ApplicationValidationResult validateApplication(
    GacpApplication application,
  ) {
    final errors = <String>[];

    // Company info validation
    if (application.companyName.isEmpty) {
      errors.add('กรุณากรอกชื่อบริษัท');
    }
    if (application.taxId.length != 13) {
      errors.add('เลขประจำตัวผู้เสียภาษีต้องมี 13 หลัก');
    }
    if (application.address.length < 20) {
      errors.add('ที่อยู่ต้องมีความยาวอย่างน้อย 20 ตัวอักษร');
    }
    if (!_isValidPhone(application.phone)) {
      errors.add('รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง');
    }
    if (!_isValidEmail(application.email)) {
      errors.add('รูปแบบอีเมลไม่ถูกต้อง');
    }

    // Herbal selection validation
    if (application.herbalTypes.isEmpty) {
      errors.add('กรุณาเลือกสมุนไพรอย่างน้อย 1 ชนิด');
    }

    // Farm info validation
    if (application.farmArea <= 0) {
      errors.add('พื้นที่ฟาร์มต้องมากกว่า 0');
    }
    if (application.productionCapacity <= 0) {
      errors.add('กำลังการผลิตต้องมากกว่า 0');
    }

    return ApplicationValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  static bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^0[0-9]{9}$');
    return phoneRegex.hasMatch(phone);
  }

  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$',
    );
    return emailRegex.hasMatch(email);
  }
}

class ApplicationValidationResult {
  final bool isValid;
  final List<String> errors;

  ApplicationValidationResult({
    required this.isValid,
    required this.errors,
  });
}
