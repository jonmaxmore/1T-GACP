import 'package:thai_herbal_gacp_event_ledger/event_store.dart';
import 'package:thai_herbal_gacp_models/certificate.dart';

class CertificateQueryHandler {
  final EventStore eventStore;

  CertificateQueryHandler(this.eventStore);

  Future<CertificateStatusResponse> getCertificateStatus(
    String certificateId,
  ) async {
    final events = await eventStore.getEvents(certificateId);
    if (events.isEmpty) {
      throw CertificateNotFoundException(certificateId);
    }

    CertificateStatus status = CertificateStatus.active;
    DateTime? expiryDate;
    DateTime? revocationDate;
    String? revocationReason;
    DateTime? suspensionEndDate;
    String? suspensionReason;

    // Rebuild state from events
    for (final event in events) {
      switch (event.eventType) {
        case 'CertificateIssued':
          expiryDate = DateTime.parse(
            event.eventData['expiryDate'] as String,
          );
          break;
        case 'CertificateRenewed':
          expiryDate = DateTime.parse(
            event.eventData['newExpiryDate'] as String,
          );
          break;
        case 'CertificateRevoked':
          status = CertificateStatus.revoked;
          revocationDate = DateTime.parse(
            event.eventData['revokedAt'] as String,
          );
          revocationReason = event.eventData['reason'] as String;
          break;
        case 'CertificateSuspended':
          status = CertificateStatus.suspended;
          suspensionEndDate = DateTime.parse(
            event.eventData['suspensionEndDate'] as String,
          );
          suspensionReason = event.eventData['reason'] as String;
          break;
        case 'CertificateReinstated':
          status = CertificateStatus.active;
          suspensionEndDate = null;
          suspensionReason = null;
          break;
      }
    }

    return CertificateStatusResponse(
      certificateId: certificateId,
      status: status,
      expiryDate: expiryDate,
      revocationDate: revocationDate,
      revocationReason: revocationReason,
      suspensionEndDate: suspensionEndDate,
      suspensionReason: suspensionReason,
      lastEventVersion: events.last.version,
    );
  }

  Future<GacpCertificate> getCertificateDetails(
    String certificateId,
  ) async {
    final events = await eventStore.getEvents(certificateId);
    if (events.isEmpty) {
      throw CertificateNotFoundException(certificateId);
    }

    // Find the issue event
    final issueEvent = events.firstWhere(
      (e) => e.eventType == 'CertificateIssued',
      orElse: () => throw StateError('No issue event found'),
    );

    return GacpCertificate.fromJson(issueEvent.eventData);
  }
}

class CertificateStatusResponse {
  final String certificateId;
  final CertificateStatus status;
  final DateTime? expiryDate;
  final DateTime? revocationDate;
  final String? revocationReason;
  final DateTime? suspensionEndDate;
  final String? suspensionReason;
  final int lastEventVersion;

  CertificateStatusResponse({
    required this.certificateId,
    required this.status,
    this.expiryDate,
    this.revocationDate,
    this.revocationReason,
    this.suspensionEndDate,
    this.suspensionReason,
    required this.lastEventVersion,
  });

  Map<String, dynamic> toJson() => {
        'certificateId': certificateId,
        'status': status.name,
        'expiryDate': expiryDate?.toIso8601String(),
        'revocationDate': revocationDate?.toIso8601String(),
        'revocationReason': revocationReason,
        'suspensionEndDate': suspensionEndDate?.toIso8601String(),
        'suspensionReason': suspensionReason,
        'lastEventVersion': lastEventVersion,
      };
}

class CertificateNotFoundException implements Exception {
  final String certificateId;
  CertificateNotFoundException(this.certificateId);

  @override
  String toString() => 'Certificate $certificateId not found';
}
