import 'package:flutter/material.dart';
import 'package:thai_herbal_gacp/features/gacp_certification/models/gacp_application.dart';

class GacpApplicationProvider extends ChangeNotifier {
  GacpApplication? _application;

  GacpApplication? get application => _application;

  Future<void> updateApplication({
    required String companyName,
    required String taxId,
    required String address,
    required String phone,
    required String email,
  }) async {
    _application = GacpApplication(
      companyName: companyName,
      taxId: taxId,
      address: address,
      phone: phone,
      email: email,
      createdAt: DateTime.now(),
      status: ApplicationStatus.draft,
    );
    notifyListeners();
  }

  void clearApplication() {
    _application = null;
    notifyListeners();
  }
}
