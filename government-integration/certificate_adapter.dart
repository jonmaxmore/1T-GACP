import 'package:thai_herbal_gacp_models/certificate.dart';

class CertificateAdapter {
  Map<String, dynamic> toGovernmentFormat(GacpCertificate certificate) {
    return {
      'certificateId': certificate.id,
      'certificateNumber': certificate.certificateNumber,
      'company': {
        'name': certificate.companyName,
        'registrationId': certificate.companyRegistrationId,
      },
      'herbs': certificate.herbalTypes,
      'issueDate': certificate.issueDate.toIso8601String(),
      'expiryDate': certificate.expiryDate.toIso8601String(),
      'standardVersion': 'GACP-TH-2023',
      'productionLocation': {
        'province': certificate.productionProvince,
        'district': certificate.productionDistrict,
        'coordinates': certificate.productionCoordinates,
      },
      'verificationUrl': certificate.verificationUrl,
      'issuer': {
        'name': certificate.issuerName ?? 'กรมการแพทย์แผนไทยและการแพทย์ทางเลือก',
        'title': certificate.issuerTitle ?? 'ผู้อำนวยการ',
        'signature': certificate.issuerSignature,
      },
      'metadata': {
        'gacpVersion': '1.0',
        'complianceLevel': certificate.complianceLevel ?? 'A',
      },
    };
  }

  GacpCertificate fromGovernmentFormat(Map<String, dynamic> json) {
    return GacpCertificate(
      id: json['certificateId'] as String,
      certificateNumber: json['certificateNumber'] as String,
      companyName: json['company']['name'] as String,
      companyRegistrationId: json['company']['registrationId'] as String?,
      herbalTypes: List<String>.from(json['herbs'] as List),
      issueDate: DateTime.parse(json['issueDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      status: _parseStatus(json['status'] as String?),
      verificationUrl: json['verificationUrl'] as String,
      productionProvince: json['productionLocation']['province'] as String?,
      productionDistrict: json['productionLocation']['district'] as String?,
      productionCoordinates: json['productionLocation']['coordinates'] as String?,
      issuerName: json['issuer']['name'] as String?,
      issuerTitle: json['issuer']['title'] as String?,
      issuerSignature: json['issuer']['signature'] as String?,
      complianceLevel: json['metadata']['complianceLevel'] as String?,
      fdaReferenceId: json['fdaReferenceId'] as String?,
    );
  }

  CertificateStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return CertificateStatus.active;
      case 'expired':
        return CertificateStatus.expired;
      case 'revoked':
        return CertificateStatus.revoked;
      case 'suspended':
        return CertificateStatus.suspended;
      default:
        return CertificateStatus.active;
    }
  }

  Map<String, dynamic> toVerificationRequest(
    String certificateNumber,
    String verificationCode,
  ) {
    return {
      'certificateNumber': certificateNumber,
      'verificationCode': verificationCode,
      'requestedAt': DateTime.now().toIso8601String(),
    };
  }
}
