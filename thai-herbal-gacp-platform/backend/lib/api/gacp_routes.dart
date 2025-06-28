import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:thai_herbal_gacp_backend/gacp_certification/application_service.dart';
import 'package:thai_herbal_gacp_backend/gacp_certification/certificate_generator.dart';
import 'package:thai_herbal_gacp_backend/gacp_certification/validation_service.dart';
import 'package:thai_herbal_gacp_backend/models/application.dart';
import 'package:thai_herbal_gacp_backend/services/response_handler.dart';

class GacpRoutes {
  final GacpApplicationService applicationService;
  final CertificateGenerator certificateGenerator;
  final ResponseHandler responseHandler;

  GacpRoutes({
    required this.applicationService,
    required this.certificateGenerator,
    required this.responseHandler,
  });

  Router get router {
    final router = Router();

    // Submit new application
    router.post('/applications', (Request request) async {
      try {
        final body = await request.readAsString();
        final jsonData = jsonDecode(body) as Map<String, dynamic>;
        
        // Parse application data
        final application = GacpApplication.fromJson(jsonData['application']);
        final documents = <DocumentType, File>{};
        
        // Validate application data
        final validation = ValidationService.validateApplication(application);
        if (!validation.isValid) {
          return responseHandler.errorResponse(
            message: 'ข้อมูลไม่ถูกต้อง',
            errors: validation.errors,
            statusCode: 400,
          );
        }
        
        // Process documents
        final files = jsonData['documents'] as Map<String, dynamic>;
        for (final entry in files.entries) {
          final docType = DocumentType.values.firstWhere(
            (e) => e.name == entry.key,
            orElse: () => throw Exception('Invalid document type'),
          );
          
          final fileData = base64Decode(entry.value as String);
          final tempFile = File('${Directory.systemTemp.path}/${entry.key}.tmp');
          await tempFile.writeAsBytes(fileData);
          
          documents[docType] = tempFile;
        }
        
        // Submit application
        final result = await applicationService.submitApplication(
          application,
          documents,
        );
        
        return responseHandler.successResponse(
          data: result.toJson(),
          message: 'ส่งคำร้องสำเร็จ',
        );
      } catch (e) {
        return responseHandler.errorResponse(
          message: 'ส่งคำร้องไม่สำเร็จ',
          error: e.toString(),
          statusCode: 500,
        );
      }
    });

    // Get application status
    router.get('/applications/<applicationId>', (Request request, String applicationId) async {
      try {
        final application = await applicationService.getApplicationStatus(applicationId);
        return responseHandler.successResponse(
          data: application.toJson(),
        );
      } catch (e) {
        return responseHandler.errorResponse(
          message: 'ไม่พบข้อมูลคำร้อง',
          error: e.toString(),
          statusCode: 404,
        );
      }
    });

    // Generate certificate
    router.post('/certificates/generate', (Request request) async {
      try {
        final body = await request.readAsString();
        final jsonData = jsonDecode(body) as Map<String, dynamic>;
        final certificate = GacpCertificate.fromJson(jsonData);
        
        final certificateFile = await certificateGenerator.generateCertificate(certificate);
        
        return Response.ok(
          certificateFile.file.readAsBytesSync(),
          headers: {
            'Content-Type': certificateFile.mimeType,
            'Content-Disposition': 'attachment; filename=${certificateFile.fileName}',
          },
        );
      } catch (e) {
        return responseHandler.errorResponse(
          message: 'สร้างใบรับรองไม่สำเร็จ',
          error: e.toString(),
          statusCode: 500,
        );
      }
    });

    // Verify certificate
    router.get('/certificates/verify/<certificateNumber>', 
      (Request request, String certificateNumber) async {
        try {
          // In production, this would check a database
          return responseHandler.successResponse(
            data: {
              'valid': true,
              'certificateNumber': certificateNumber,
              'issueDate': '2023-10-01',
              'expiryDate': '2025-10-01',
              'status': 'active',
            },
            message: 'ใบรับรองถูกต้อง',
          );
        } catch (e) {
          return responseHandler.errorResponse(
            message: 'ตรวจสอบใบรับรองไม่สำเร็จ',
            error: e.toString(),
            statusCode: 500,
          );
        }
      },
    );

    return router;
  }
}
