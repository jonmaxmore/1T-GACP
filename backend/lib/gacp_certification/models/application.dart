import 'package:freezed_annotation/freezed_annotation.dart';

part 'application.freezed.dart';
part 'application.g.dart';

enum ApplicationStatus {
  draft,
  submitted,
  underReview,
  approved,
  rejected,
  issued,
}

enum DocumentType {
  commercialRegistration,
  landDocument,
  farmMap,
  soilTestReport,
  productionProcess,
  qualityControl,
}

@freezed
class GacpApplication with _$GacpApplication {
  const factory GacpApplication({
    required String id,
    required String companyName,
    required String taxId,
    required String address,
    required String phone,
    required String email,
    required List<String> herbalTypes,
    required double farmArea,
    required double productionCapacity,
    required ApplicationStatus status,
    DateTime? submissionDate,
    DateTime? approvalDate,
    String? rejectionReason,
    String? fdaReferenceId,
    @Default({}) Map<DocumentType, String> documentUrls,
  }) = _GacpApplication;

  factory GacpApplication.fromJson(Map<String, dynamic> json) =>
      _$GacpApplicationFromJson(json);
}
