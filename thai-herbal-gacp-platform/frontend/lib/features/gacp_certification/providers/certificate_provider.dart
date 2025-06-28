import 'package:flutter/material.dart';
import 'package:thai_herbal_gacp/features/gacp_certification/models/certificate.dart';

class CertificateProvider extends ChangeNotifier {
  List<Certificate> _certificates = [];
  bool _isLoading = false;

  List<Certificate> get certificates => _certificates;
  bool get isLoading => _isLoading;

  Future<void> fetchCertificates() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock data
      _certificates = [
        Certificate(
          id: '1',
          certificateNumber: 'GACP-2023-0001',
          companyName: 'สมุนไพรไทยจำกัด',
          issueDate: '10 มกราคม 2566',
          expiryDate: '10 มกราคม 2568',
          status: CertificateStatus.active,
        ),
        Certificate(
          id: '2',
          certificateNumber: 'GACP-2023-0002',
          companyName: 'ฟาร์มเกษตรอินทรีย์',
          issueDate: '15 กุมภาพันธ์ 2566',
          expiryDate: '15 กุมภาพันธ์ 2568',
          status: CertificateStatus.pending,
        ),
      ];
    } catch (e) {
      // Handle error
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> downloadCertificate(Certificate certificate) async {
    // Implement download functionality
  }

  Future<void> shareCertificate(Certificate certificate) async {
    // Implement share functionality
  }
}
