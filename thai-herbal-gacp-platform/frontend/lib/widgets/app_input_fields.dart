import 'package:flutter/material.dart';
import 'package:thai_herbal_gacp/core/constants/app_colors.dart';
import 'package:thai_herbal_gacp/core/constants/app_text_styles.dart';

class AppInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final String? Function(String?)? validator;
  final bool obscureText;

  const AppInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.validator,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.inputLabel,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(prefixIcon, color: AppColors.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
          style: AppTextStyles.bodyText,
          validator: validator,
        ),
      ],
    );
  }
}
