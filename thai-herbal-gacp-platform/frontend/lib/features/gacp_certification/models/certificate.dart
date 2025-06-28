class Certificate {
  final String id;
  final String certificateNumber;
  final String companyName;
  final String issueDate;
  final String expiryDate;
  final CertificateStatus status;

  Certificate({
    required this.id,
    required this.certificateNumber,
    required this.companyName,
    required this.issueDate,
    required this.expiryDate,
    required this.status,
  });

  String get statusText {
    switch (status) {
      case CertificateStatus.active:
        return 'ใช้งานได้';
      case CertificateStatus.pending:
        return 'รอการอนุมัติ';
      case CertificateStatus.expired:
        return 'หมดอายุ';
      case CertificateStatus.revoked:
        return 'ถูกเพิกถอน';
    }
  }

  Color get statusColor {
    switch (status) {
      case CertificateStatus.active:
        return Colors.green;
      case CertificateStatus.pending:
        return Colors.orange;
      case CertificateStatus.expired:
        return Colors.grey;
      case CertificateStatus.revoked:
        return Colors.red;
    }
  }
}

enum CertificateStatus { active, pending, expired, revoked }
