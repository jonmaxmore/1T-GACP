import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thai_herbal_gacp/core/constants/app_colors.dart';
import 'package:thai_herbal_gacp/core/constants/app_text_styles.dart';
import 'package:thai_herbal_gacp/core/utils/ui_utils.dart';
import 'package:thai_herbal_gacp/features/gacp_certification/models/document.dart';
import 'package:thai_herbal_gacp/features/gacp_certification/providers/gacp_application_provider.dart';
import 'package:thai_herbal_gacp/widgets/app_buttons.dart';
import 'package:thai_herbal_gacp/widgets/document_review_item.dart';
import 'package:thai_herbal_gacp/widgets/info_card.dart';

class Step3ReviewScreen extends StatefulWidget {
  const Step3ReviewScreen({super.key});

  @override
  State<Step3ReviewScreen> createState() => _Step3ReviewScreenState();
}

class _Step3ReviewScreenState extends State<Step3ReviewScreen> {
  bool _isSubmitting = false;

  Future<void> _submitApplication() async {
    setState(() => _isSubmitting = true);
    try {
      final provider = context.read<GacpApplicationProvider>();
      // Simulate API call for submission
      await Future.delayed(const Duration(seconds: 2));
      provider.submitApplication();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/gacp/certificate', 
        (route) => false
      );
    } catch (e) {
      UIUtils.showErrorSnackBar(context, 'ส่งคำร้องไม่สำเร็จ: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตรวจสอบข้อมูล'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Consumer<GacpApplicationProvider>(
          builder: (context, provider, child) {
            final application = provider.application!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ProgressIndicator(step: 3, totalSteps: 4),
                  const SizedBox(height: 24),
                  const Text(
                    'ตรวจสอบข้อมูลก่อนส่งคำร้อง',
                    style: AppTextStyles.header2,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'กรุณาตรวจสอบข้อมูลให้ถูกต้องก่อนกดส่งคำร้อง',
                    style: AppTextStyles.bodyText,
                  ),
                  const SizedBox(height: 32),
                  
                  // Company Info
                  InfoCard(
                    title: 'ข้อมูลบริษัท',
                    items: [
                      InfoItem(label: 'ชื่อบริษัท', value: application.companyName),
                      InfoItem(label: 'เลขประจำตัวผู้เสียภาษี', value: application.taxId),
                      InfoItem(label: 'ที่อยู่', value: application.address),
                      InfoItem(label: 'โทรศัพท์', value: application.phone),
                      InfoItem(label: 'อีเมล', value: application.email),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Documents
                  const Text(
                    'เอกสารประกอบ',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 12),
                  DocumentReviewItem(
                    title: 'สำเนาทะเบียนพาณิชย์',
                    isUploaded: provider.isDocumentUploaded(DocumentType.commercialRegistration),
                  ),
                  DocumentReviewItem(
                    title: 'เอกสารแสดงกรรมสิทธิ์ในที่ดิน',
                    isUploaded: provider.isDocumentUploaded(DocumentType.landDocument),
                  ),
                  DocumentReviewItem(
                    title: 'แผนผังพื้นที่การปลูก',
                    isUploaded: provider.isDocumentUploaded(DocumentType.farmMap),
                  ),
                  DocumentReviewItem(
                    title: 'รายงานผลการตรวจวิเคราะห์ดิน',
                    isUploaded: provider.isDocumentUploaded(DocumentType.soilTestReport),
                  ),
                  const SizedBox(height: 40),
                  
                  // Submit Button
                  PrimaryButton(
                    text: 'ส่งคำร้องขอรับรอง',
                    isLoading: _isSubmitting,
                    onPressed: _submitApplication,
                  ),
                  const SizedBox(height: 16),
                  SecondaryButton(
                    text: 'แก้ไขข้อมูล',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }
}
