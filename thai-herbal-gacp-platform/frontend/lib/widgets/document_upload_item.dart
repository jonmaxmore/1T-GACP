import 'package:flutter/material.dart';
import 'package:thai_herbal_gacp/core/constants/app_colors.dart';
import 'package:thai_herbal_gacp/core/constants/app_text_styles.dart';
import 'package:thai_herbal_gacp/features/gacp_certification/models/document.dart';

class DocumentUploadItem extends StatelessWidget {
  final String title;
  final String description;
  final bool isUploaded;
  final VoidCallback onTap;

  const DocumentUploadItem({
    super.key,
    required this.title,
    required this.description,
    required this.isUploaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUploaded ? AppColors.successLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUploaded ? AppColors.success : AppColors.grey300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isUploaded ? Icons.check_circle : Icons.upload_file,
              color: isUploaded ? AppColors.success : AppColors.primaryColor,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            if (isUploaded)
              const Icon(Icons.check, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}
