import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:thai_herbal_gacp/core/constants/app_colors.dart';
import 'package:thai_herbal_gacp/core/constants/app_text_styles.dart';
import 'package:thai_herbal_gacp/core/utils/form_validator.dart';
import 'package:thai_herbal_gacp/core/utils/ui_utils.dart';
import 'package:thai_herbal_gacp/features/gacp_certification/providers/gacp_application_provider.dart';
import 'package:thai_herbal_gacp/widgets/app_buttons.dart';
import 'package:thai_herbal_gacp/widgets/app_input_fields.dart';

class Step1InfoScreen extends StatefulWidget {
  const Step1InfoScreen({super.key});

  @override
  State<Step1InfoScreen> createState() => _Step1InfoScreenState();
}

class _Step1InfoScreenState extends State<Step1InfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  void _loadSavedData() {
    final provider = context.read<GacpApplicationProvider>();
    final application = provider.application;
    
    if (application != null) {
      _companyNameController.text = application.companyName;
      _taxIdController.text = application.taxId;
      _addressController.text = application.address;
      _phoneController.text = application.phone;
      _emailController.text = application.email;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<GacpApplicationProvider>();
      
      await provider.updateApplication(
        companyName: _companyNameController.text,
        taxId: _taxIdController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        email: _emailController.text,
      );

      if (!mounted) return;
      Navigator.pushNamed(context, '/gacp/step2');
    } catch (e) {
      if (!mounted) return;
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
        title: const Text('ข้อมูลบริษัท'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ProgressIndicator(step: 1, totalSteps: 4),
                const SizedBox(height: 24),
                const Text(
                  'ข้อมูลพื้นฐานของบริษัท',
                  style: AppTextStyles.header2,
                ),
                const SizedBox(height: 8),
                const Text(
                  'กรุณากรอกข้อมูลบริษัทอย่างถูกต้องตามเอกสารทางราชการ',
                  style: AppTextStyles.bodyText,
                ),
                const SizedBox(height: 32),
                
                // Company Name
                AppInputField(
                  controller: _companyNameController,
                  label: 'ชื่อบริษัท (ตามทะเบียนพาณิชย์)',
                  hintText: 'กรอกชื่อบริษัท',
                  prefixIcon: Icons.business,
                  validator: FormValidator.validateRequired,
                ),
                const SizedBox(height: 20),
                
                // Tax ID
                AppInputField(
                  controller: _taxIdController,
                  label: 'เลขประจำตัวผู้เสียภาษี (Tax ID)',
                  hintText: 'กรอกเลขประจำตัวผู้เสียภาษี',
                  prefixIcon: Icons.numbers,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: FormValidator.validateTaxId,
                ),
                const SizedBox(height: 20),
                
                // Address
                AppInputField(
                  controller: _addressController,
                  label: 'ที่อยู่บริษัท',
                  hintText: 'กรอกที่อยู่ตามทะเบียนพาณิชย์',
                  prefixIcon: Icons.location_on,
                  maxLines: 3,
                  validator: FormValidator.validateAddress,
                ),
                const SizedBox(height: 20),
                
                // Phone
                AppInputField(
                  controller: _phoneController,
                  label: 'เบอร์โทรศัพท์',
                  hintText: 'กรอกเบอร์โทรศัพท์ติดต่อ',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: FormValidator.validatePhone,
                ),
                const SizedBox(height: 20),
                
                // Email
                AppInputField(
                  controller: _emailController,
                  label: 'อีเมลติดต่อ',
                  hintText: 'กรอกอีเมลสำหรับติดต่อ',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: FormValidator.validateEmail,
                ),
                const SizedBox(height: 40),
                
                // Submit Button
                PrimaryButton(
                  text: 'ต่อไป',
                  isLoading: _isLoading,
                  onPressed: _submitForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}

class ProgressIndicator extends StatelessWidget {
  final int step;
  final int totalSteps;

  const ProgressIndicator({
    super.key,
    required this.step,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ขั้นตอนที่ $step/$totalSteps',
          style: AppTextStyles.subtitle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: step / totalSteps,
          backgroundColor: AppColors.grey200,
          color: AppColors.primaryColor,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
