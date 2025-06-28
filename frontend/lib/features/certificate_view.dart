import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thai_herbal_gacp/core/constants/app_colors.dart';
import 'package:thai_herbal_gacp/core/constants/app_text_styles.dart';
import 'package:thai_herbal_gacp/features/gacp_certification/models/certificate.dart';
import 'package:thai_herbal_gacp/features/gacp_certification/providers/certificate_provider.dart';
import 'package:thai_herbal_gacp/widgets/certificate_card.dart';
import 'package:thai_herbal_gacp/widgets/loading_indicator.dart';

class CertificateViewScreen extends StatefulWidget {
  const CertificateViewScreen({super.key});

  @override
  State<CertificateViewScreen> createState() => _CertificateViewScreenState();
}

class _CertificateViewScreenState extends State<CertificateViewScreen> {
  late Future<void> _fetchCertificates;

  @override
  void initState() {
    super.initState();
    _fetchCertificates = context.read<CertificateProvider>().fetchCertificates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ใบรับรองทั้งหมด'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: _fetchCertificates,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาดในการโหลดข้อมูล',
                    style: AppTextStyles.header3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: AppTextStyles.bodyText,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _fetchCertificates = context.read<CertificateProvider>().fetchCertificates();
                    }),
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ],
              ),
            );
          }
          
          return Consumer<CertificateProvider>(
            builder: (context, provider, child) {
              if (provider.certificates.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment, size: 64, color: AppColors.grey400),
                      const SizedBox(height: 16),
                      Text(
                        'ยังไม่มีใบรับรอง',
                        style: AppTextStyles.header3.copyWith(color: AppColors.grey600),
                      ),
                      const SizedBox(height: 8),
                      const Text('ส่งคำร้องขอรับรองมาตรฐาน GACP เพื่อรับใบรับรอง'),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/gacp/step1'),
                        child: const Text('เริ่มคำร้องใหม่'),
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () => provider.fetchCertificates(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.certificates.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final certificate = provider.certificates[index];
                    return CertificateCard(
                      certificate: certificate,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/gacp/certificate/detail',
                        arguments: certificate,
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
