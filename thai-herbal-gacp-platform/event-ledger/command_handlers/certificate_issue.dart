import 'package:thai_herbal_gacp_event_ledger/event_store.dart';
import 'package:thai_herbal_gacp_models/certificate.dart';

class CertificateCommandHandler {
  final EventStore eventStore;

  CertificateCommandHandler(this.eventStore);

  Future<void> issueCertificate(
    String certificateId,
    GacpCertificate certificate,
  ) async {
    await eventStore.saveEvent(
      certificateId,
      'CertificateIssued',
      certificate.toJson(),
      expectedVersion: 0, // New aggregate
    );
  }

  Future<void> renewCertificate(
    String certificateId,
    DateTime newExpiryDate,
  ) async {
    await eventStore.saveEvent(
      certificateId,
      'CertificateRenewed',
      {
        'newExpiryDate': newExpiryDate.toIso8601String(),
        'renewedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> revokeCertificate(
    String certificateId,
    String reason,
  ) async {
    await eventStore.saveEvent(
      certificateId,
      'CertificateRevoked',
      {
        'reason': reason,
        'revokedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> suspendCertificate(
    String certificateId,
    String reason,
    DateTime suspensionEndDate,
  ) async {
    await eventStore.saveEvent(
      certificateId,
      'CertificateSuspended',
      {
        'reason': reason,
        'suspendedAt': DateTime.now().toIso8601String(),
        'suspensionEndDate': suspensionEndDate.toIso8601String(),
      },
    );
  }

  Future<void> reinstateCertificate(
    String certificateId,
  ) async {
    await eventStore.saveEvent(
      certificateId,
      'CertificateReinstated',
      {'reinstatedAt': DateTime.now().toIso8601String()},
    );
  }
}
