import 'package:flutter/material.dart';
import 'package:thai_herbal_gacp/core/constants/app_colors.dart';
import 'package:thai_herbal_gacp/core/constants/app_text_styles.dart';
import 'package:thai_herbal_gacp/features/gacp_certification/models/certificate.dart';

class CertificateCard extends StatelessWidget {
  final Certificate certificate;

  const CertificateCard({
    super.key,
    required this.certificate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryColor, width: 1.5),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Image.asset(
                'assets/images/gacp_logo.png',
                width: 50,
                height: 50,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ใบรับรองมาตรฐาน GACP',
                      style: AppTextStyles.header3.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'กรมการแพทย์แผนไทยและการแพทย์ทางเลือก',
                      style: AppTextStyles.bodyText.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: certificate.statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              certificate.statusText,
              style: AppTextStyles.bodyText.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Certificate Info
          _buildInfoRow('ชื่อบริษัท', certificate.companyName),
          _buildInfoRow('เลขที่ใบรับรอง', certificate.certificateNumber),
          _buildInfoRow('วันที่ออก', certificate.issueDate),
          _buildInfoRow('วันหมดอายุ', certificate.expiryDate),
          const SizedBox(height: 16),
          
          // Footer
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user, color: AppColors.primaryColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'ใบรับรองอิเล็กทรอนิกส์นี้ได้รับการรับรองความถูกต้องด้วยลายเซ็นดิจิทัล',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodyText.copyWith(
                color: AppColors.grey600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyText.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
