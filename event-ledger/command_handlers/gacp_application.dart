import 'dart:async';
import 'package:thai_herbal_gacp_event_ledger/event_store.dart';
import 'package:thai_herbal_gacp_models/application.dart';

class GacpApplicationCommandHandler {
  final EventStore eventStore;

  GacpApplicationCommandHandler(this.eventStore);

  Future<String> handleSubmitApplication(
    GacpApplication application,
  ) async {
    final aggregateId = application.id;

    await eventStore.saveEvent(
      aggregateId,
      'GacpApplicationSubmitted',
      application.toJson(),
      expectedVersion: 0, // New aggregate
    );

    return aggregateId;
  }

  Future<void> handleValidateDocuments(
    String applicationId,
    DocumentValidationResult validationResult,
  ) async {
    if (validationResult.isValid) {
      await eventStore.saveEvent(
        applicationId,
        'GacpApplicationValidated',
        {'validatedAt': DateTime.now().toIso8601String()},
      );
    } else {
      await eventStore.saveEvent(
        applicationId,
        'GacpApplicationRejected',
        {
          'reason': 'เอกสารไม่ผ่านการตรวจสอบ',
          'errors': validationResult.errors,
        },
      );
    }
  }

  Future<void> handleApproveApplication(
    String applicationId,
    String fdaReferenceId,
  ) async {
    await eventStore.saveEvent(
      applicationId,
      'GacpApplicationApproved',
      {
        'fdaReferenceId': fdaReferenceId,
        'approvedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> handleRejectApplication(
    String applicationId,
    String reason,
  ) async {
    await eventStore.saveEvent(
      applicationId,
      'GacpApplicationRejected',
      {'reason': reason},
    );
  }

  Future<void> handleIssueCertificate(
    String applicationId,
    GacpCertificate certificate,
  ) async {
    await eventStore.saveEvent(
      applicationId,
      'CertificateIssued',
      certificate.toJson(),
    );
  }
}
