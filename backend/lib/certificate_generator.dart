import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:thai_herbal_gacp_backend/models/certificate.dart';
import 'package:thai_herbal_gacp_backend/services/signature_service.dart';

class CertificateGenerator {
  final String templatePath;
  final String outputDirectory;
  final SignatureService signatureService;

  CertificateGenerator({
    required this.templatePath,
    required this.outputDirectory,
    required this.signatureService,
  });

  Future<CertificateFile> generateCertificate(
    GacpCertificate certificate,
  ) async {
    // Load template image
    final templateFile = File(templatePath);
    if (!await templateFile.exists()) {
      throw CertificateException('ไม่พบไฟล์เทมเพลตใบรับรอง');
    }

    // Decode template image
    final templateImage = img.decodeImage(await templateFile.readAsBytes());
    if (templateImage == null) {
      throw CertificateException('ไม่สามารถอ่านไฟล์เทมเพลตได้');
    }

    // Create PDF document
    final pdf = pw.Document();
    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      buildBackground: (context) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Image(
          pw.MemoryImage(await templateFile.readAsBytes()),
        ),
      ),
    );

    // Add content to PDF
    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (context) => pw.Stack(
          children: [
            // Certificate number
            pw.Positioned(
              top: 160,
              right: 150,
              child: pw.Text(
                certificate.certificateNumber,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            
            // Company name
            pw.Positioned(
              top: 220,
              left: 150,
              child: pw.Text(
                certificate.companyName,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            
            // Herbal types
            pw.Positioned(
              top: 260,
              left: 150,
              child: pw.Text(
                certificate.herbalTypes.join(', '),
                style: const pw.TextStyle(fontSize: 16),
              ),
            ),
            
            // Issue date
            pw.Positioned(
              top: 300,
              left: 150,
              child: pw.Text(
                certificate.issueDate,
                style: const pw.TextStyle(fontSize: 16),
              ),
            ),
            
            // Expiry date
            pw.Positioned(
              top: 300,
              right: 150,
              child: pw.Text(
                certificate.expiryDate,
                style: const pw.TextStyle(fontSize: 16),
              ),
            ),
            
            // QR code placeholder
            pw.Positioned(
              bottom: 100,
              right: 100,
              child: pw.BarcodeWidget(
                data: certificate.verificationUrl,
                barcode: pw.Barcode.qrCode(),
                width: 100,
                height: 100,
              ),
            ),
          ],
        ),
      ),
    );

    // Generate PDF file
    final outputPath = path.join(
      outputDirectory,
      'certificates',
      '${certificate.certificateNumber}.pdf',
    );
    final file = File(outputPath);
    await file.create(recursive: true);
    await file.writeAsBytes(await pdf.save());

    // Add digital signature
    final signedFile = await signatureService.signPdf(file);

    return CertificateFile(
      file: signedFile,
      fileName: '${certificate.certificateNumber}.pdf',
      mimeType: 'application/pdf',
    );
  }

  Future<CertificateFile> generateCertificatePreview(
    GacpCertificate certificate,
  ) async {
    final fullCertificate = await generateCertificate(certificate);
    return fullCertificate;
  }
}

class CertificateFile {
  final File file;
  final String fileName;
  final String mimeType;

  CertificateFile({
    required this.file,
    required this.fileName,
    required this.mimeType,
  });
}

class CertificateException implements Exception {
  final String message;
  CertificateException(this.message);

  @override
  String toString() => 'CertificateException: $message';
}
