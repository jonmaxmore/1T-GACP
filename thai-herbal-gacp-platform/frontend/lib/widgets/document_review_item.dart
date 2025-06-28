import 'package:flutter/material.dart';
import 'package:thai_herbal_gacp/core/constants/app_colors.dart';
import 'package:thai_herbal_gacp/core/constants/app_text_styles.dart';

class DocumentReviewItem extends StatelessWidget {
  final String title;
  final bool isUploaded;

  const DocumentReviewItem({
    super.key,
    required this.title,
    required this.isUploaded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isUploaded ? Icons.check_circle : Icons.error,
            color: isUploaded ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: AppTextStyles.bodyText.copyWith(
              color: isUploaded ? AppColors.grey800 : AppColors.warning,
              fontWeight: isUploaded ? FontWeight.normal : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
