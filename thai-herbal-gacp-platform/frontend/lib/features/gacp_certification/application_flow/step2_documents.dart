import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:thai_herbal_gacp/core/constants/app_colors.dart';
import 'package:thai_herbal_gacp/core/constants/app_text_styles.dart';
import 'package:thai_herbal_gacp/core/utils/ui_utils.dart';
import 'package:thai_herbal_gacp/features/gacp_certification/models/document.dart';
import 'package:thai_herbal_gacp/features/gacp_certification/providers/gacp_application_provider.dart';
import 'package:thai_herbal_gacp/widgets/app_buttons.dart';
import 'package:thai_herbal_gacp/widgets/document_upload_item.dart';

class Step2DocumentsScreen extends StatefulWidget {
  const Step2DocumentsScreen({super.key});

  @override
  State<Step2DocumentsScreen> createState() => _Step2DocumentsScreenState();
}

class _Step2DocumentsScreenState extends State<Step2DocumentsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickDocument(DocumentType type) async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        final provider = context.read<GacpApplicationProvider>();
        await provider.uploadDocument(type, File(file.path));
      }
    } catch (e) {
      UIUtils.showErrorSnackBar(context, 'ไม่สามารถเลือกไฟล์: ${e.toString()}');
    }
  }

  Future<void> _submit() async {
    final provider = context.read<GacpApplicationProvider>();
    if (!provider.areDocumentsUploaded) {
      UIUtils.showErrorSnackBar(context, 'กรุณาอัพโหลดเอกสารให้ครบถ้วน');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Simulate document verification
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushNamed(context, '/gacp/step3');
    } catch (e) {
      UIUtils.showErrorSnackBar(context, 'เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เอกสารประกอบ'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Consumer<GacpApplicationProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ProgressIndicator(step: 2, totalSteps: 4),
                  const SizedBox(height: 24),
                  const Text(
                    'เอกสารที่จำเป็นสำหรับการขอรับรองมาตรฐาน GACP',
                    style: AppTextStyles.header2,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'กรุณาอัพโหลดเอกสารต่อไปนี้ในรูปแบบไฟล์ภาพหรือ PDF',
                    style: AppTextStyles.bodyText,
                  ),
                  const SizedBox(height: 32),
                  
                  // Document List
                  DocumentUploadItem(
                    title: 'สำเนาทะเบียนพาณิชย์',
                    description: 'ต้องมีอายุไม่เกิน 6 เดือน',
                    isUploaded: provider.isDocumentUploaded(DocumentType.commercialRegistration),
                    onTap: () => _pickDocument(DocumentType.commercialRegistration),
                  ),
                  const SizedBox(height: 16),
                  
                  DocumentUploadItem(
                    title: 'เอกสารแสดงกรรมสิทธิ์ในที่ดิน',
                    description: 'เช่น โฉนดที่ดิน, หนังสือสัญญาเช่า',
                    isUploaded: provider.isDocumentUploaded(DocumentType.landDocument),
                    onTap: () => _pickDocument(DocumentType.landDocument),
                  ),
                  const SizedBox(height: 16),
                  
                  DocumentUploadItem(
                    title: 'แผนผังพื้นที่การปลูก',
                    description: 'แสดงตำแหน่งแปลงปลูกอย่างชัดเจน',
                    isUploaded: provider.isDocumentUploaded(DocumentType.farmMap),
                    onTap: () => _pickDocument(DocumentType.farmMap),
                  ),
                  const SizedBox(height: 16),
                  
                  DocumentUploadItem(
                    title: 'รายงานผลการตรวจวิเคราะห์ดิน',
                    description: 'จากหน่วยงานที่ได้รับอนุญาต',
                    isUploaded: provider.isDocumentUploaded(DocumentType.soilTestReport),
                    onTap: () => _pickDocument(DocumentType.soilTestReport),
                  ),
                  const SizedBox(height: 40),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          text: 'ย้อนกลับ',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PrimaryButton(
                          text: 'ต่อไป',
                          isLoading: _isLoading,
                          onPressed: _submit,
                        ),
                      ),
                    ],
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
