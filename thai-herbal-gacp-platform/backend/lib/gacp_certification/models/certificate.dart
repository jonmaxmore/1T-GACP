import 'package:freezed_annotation/freezed_annotation.dart';

part 'certificate.freezed.dart';
part 'certificate.g.dart';

enum CertificateStatus {
  active,
  expired,
  revoked,
  suspended,
}

@freezed
class GacpCertificate with _$GacpCertificate {
  const factory GacpCertificate({
    required String id,
    required String certificateNumber,
    required String companyName,
    required List<String> herbalTypes,
    required DateTime issueDate,
    required DateTime expiryDate,
    required CertificateStatus status,
    required String verificationUrl,
    String? fdaReferenceId,
    String? issuerName,
    String? issuerTitle,
  }) = _GacpCertificate;

  factory GacpCertificate.fromJson(Map<String, dynamic> json) =>
      _$GacpCertificateFromJson(json);
}
