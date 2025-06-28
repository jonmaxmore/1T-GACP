import 'package:thai_herbal_gacp_models/application.dart';

class GacpMapper {
  Map<String, dynamic> toFdaApplication(GacpApplication application) {
    return {
      'applicationId': application.id,
      'company': {
        'name': application.companyName,
        'taxId': application.taxId,
        'address': application.address,
        'phone': application.phone,
        'email': application.email,
      },
      'production': {
        'herbalTypes': application.herbalTypes,
        'farmArea': application.farmArea,
        'annualCapacity': application.productionCapacity,
        'productionMethods': application.productionMethods,
      },
      'qualityControl': {
        'testingFacilities': application.testingFacilities,
        'qualityStandards': application.qualityStandards,
      },
      'documents': application.documentUrls.map((key, value) => 
        MapEntry(key.name, value)),
      'submissionDate': application.submissionDate?.toIso8601String(),
    };
  }

  GacpApplication fromFdaApplication(Map<String, dynamic> json) {
    return GacpApplication(
      id: json['applicationId'] as String,
      companyName: json['company']['name'] as String,
      taxId: json['company']['taxId'] as String,
      address: json['company']['address'] as String,
      phone: json['company']['phone'] as String,
      email: json['company']['email'] as String,
      herbalTypes: List<String>.from(json['production']['herbalTypes'] as List),
      farmArea: json['production']['farmArea'] as double,
      productionCapacity: json['production']['annualCapacity'] as double,
      productionMethods: List<String>.from(
        json['production']['productionMethods'] as List? ?? [],
      ),
      testingFacilities: List<String>.from(
        json['qualityControl']['testingFacilities'] as List? ?? [],
      ),
      qualityStandards: List<String>.from(
        json['qualityControl']['qualityStandards'] as List? ?? [],
      ),
      status: _parseStatus(json['status'] as String?),
      submissionDate: json['submissionDate'] != null
          ? DateTime.parse(json['submissionDate'] as String)
          : null,
      approvalDate: json['approvalDate'] != null
          ? DateTime.parse(json['approvalDate'] as String)
          : null,
      fdaReferenceId: json['referenceId'] as String?,
      documentUrls: (json['documents'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          DocumentType.values.firstWhere((e) => e.name == key),
          value as String,
        ),
      ) ?? {},
    );
  }

  ApplicationStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'submitted':
        return ApplicationStatus.submitted;
      case 'under_review':
        return ApplicationStatus.underReview;
      case 'approved':
        return ApplicationStatus.approved;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'issued':
        return ApplicationStatus.issued;
      default:
        return ApplicationStatus.draft;
    }
  }
}
