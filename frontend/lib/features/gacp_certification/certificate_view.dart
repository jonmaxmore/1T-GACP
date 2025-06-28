import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thai_herbal_gacp/core/constants/app_colors.dart';
import 'package:thai_herbal_gacp/core/constants/app_text_styles.dart';
import 'package:thai_herbal_gacp/features/gacp_certification/models/certificate.dart';
import 'package:thai_herbal_gacp/features/gacp_certification/providers/certificate_provider.dart';
import 'package:thai_herbal_gacp/widgets/certificate_card.dart';
import 'package:thai_herbal_gacp/widgets/loading_indicator.dart';

class GacpCertificateScreen extends StatelessWidget {
  const GacpCertificateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Certificate certificate =
        ModalRoute.of(context)!.settings.arguments as Certificate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ใบรับรอง GACP'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Certificate Card
            CertificateCard(certificate: certificate),
            const SizedBox(height: 32),
            
            // Details
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'รายละเอียดใบรับรอง',
                style: AppTextStyles.header3,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailItem('เลขที่ใบรับรอง', certificate.certificateNumber),
            _buildDetailItem('วันที่ออก', certificate.issueDate),
            _buildDetailItem('วันหมดอายุ', certificate.expiryDate),
            _buildDetailItem('สถานะ', certificate.statusText),
            const SizedBox(height: 24),
            
            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'QR Code สำหรับตรวจสอบ',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grey200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/images/qr_placeholder.png',
                      width: 150,
                      height: 150,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'สแกนเพื่อตรวจสอบความถูกต้องของใบรับรอง',
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.download, color: AppColors.primaryColor),
                    label: const Text('ดาวน์โหลด PDF'),
                    onPressed: () => context
                        .read<CertificateProvider>()
                        .downloadCertificate(certificate),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('แชร์'),
                    onPressed: () => context
                        .read<CertificateProvider>()
                        .shareCertificate(certificate),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.bodyText.copyWith(
              fontWeight: FontWeight.w600,
            )),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyText),
          ),
        ],
      ),
    );
  }
}
