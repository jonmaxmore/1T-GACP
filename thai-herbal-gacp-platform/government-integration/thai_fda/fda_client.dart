import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:thai_herbal_gacp_models/application.dart';
import 'package:thai_herbal_gacp_models/certificate.dart';
import 'package:thai_herbal_gacp_government_integration/gacp_mapper.dart';
import 'package:thai_herbal_gacp_government_integration/certificate_adapter.dart';

class FdaClient {
  final Dio _dio;
  final String _baseUrl;
  final String _apiKey;
  final GacpMapper _mapper;
  final CertificateAdapter _certificateAdapter;

  FdaClient({
    required String baseUrl,
    required String apiKey,
    required GacpMapper mapper,
    required CertificateAdapter certificateAdapter,
  })  : _baseUrl = baseUrl,
        _apiKey = apiKey,
        _mapper = mapper,
        _certificateAdapter = certificateAdapter,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['X-API-KEY'] = _apiKey;
        options.headers['Content-Type'] = 'application/json';
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token refresh logic would go here
        }
        return handler.next(error);
      },
    ));
  }

  Future<FdaSubmissionResponse> submitApplication(
    GacpApplication application,
  ) async {
    try {
      final fdaRequest = _mapper.toFdaApplication(application);
      final response = await _dio.post(
        '$_baseUrl/gacp/applications',
        data: jsonEncode(fdaRequest),
      );

      if (response.statusCode == 202) {
        return FdaSubmissionResponse.success(
          referenceId: response.data['referenceId'] as String,
          message: 'Application submitted successfully',
        );
      } else {
        return FdaSubmissionResponse.error(
          errorMessage: response.data['error'] as String? ?? 'Unknown error',
        );
      }
    } on DioException catch (e) {
      return FdaSubmissionResponse.error(
        errorMessage: e.response?.data?['error'] as String? ??
            e.message ??
            'FDA API connection failed',
      );
    } catch (e) {
      return FdaSubmissionResponse.error(
        errorMessage: 'Unexpected error: $e',
      );
    }
  }

  Future<FdaCertificateResponse> issueCertificate(
    GacpCertificate certificate,
  ) async {
    try {
      final fdaCertificate = _certificateAdapter.toGovernmentFormat(certificate);
      final response = await _dio.post(
        '$_baseUrl/gacp/certificates',
        data: jsonEncode(fdaCertificate),
      );

      if (response.statusCode == 201) {
        return FdaCertificateResponse.success(
          fdaCertificateId: response.data['certificateId'] as String,
          issueDate: DateTime.parse(response.data['issueDate'] as String),
          expiryDate: DateTime.parse(response.data['expiryDate'] as String),
        );
      } else {
        return FdaCertificateResponse.error(
          errorMessage: response.data['error'] as String? ?? 'Unknown error',
        );
      }
    } on DioException catch (e) {
      return FdaCertificateResponse.error(
        errorMessage: e.response?.data?['error'] as String? ??
            e.message ??
            'FDA API connection failed',
      );
    } catch (e) {
      return FdaCertificateResponse.error(
        errorMessage: 'Unexpected error: $e',
      );
    }
  }

  Future<FdaVerificationResponse> verifyCertificate(
    String certificateNumber,
  ) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/gacp/certificates/$certificateNumber/verify',
      );

      if (response.statusCode == 200) {
        return FdaVerificationResponse(
          isValid: true,
          status: response.data['status'] as String? ?? 'active',
          issueDate: DateTime.parse(response.data['issueDate'] as String),
          expiryDate: DateTime.parse(response.data['expiryDate'] as String),
        );
      } else {
        return FdaVerificationResponse(
          isValid: false,
          errorMessage: response.data['error'] as String? ?? 'Verification failed',
        );
      }
    } on DioException catch (e) {
      return FdaVerificationResponse(
        isValid: false,
        errorMessage: e.response?.data?['error'] as String? ??
            e.message ??
            'FDA API connection failed',
      );
    } catch (e) {
      return FdaVerificationResponse(
        isValid: false,
        errorMessage: 'Unexpected error: $e',
      );
    }
  }

  Future<void> uploadSignedCertificate(
    String certificateId,
    File signedPdf,
  ) async {
    try {
      final formData = FormData.fromMap({
        'certificate': await MultipartFile.fromFile(
          signedPdf.path,
          filename: '$certificateId.pdf',
        ),
      });

      await _dio.post(
        '$_baseUrl/gacp/certificates/$certificateId/upload',
        data: formData,
      );
    } on DioException catch (e) {
      throw FdaException(
        'Failed to upload certificate: ${e.response?.data?['error'] ?? e.message}',
      );
    }
  }
}

class FdaSubmissionResponse {
  final bool success;
  final String? referenceId;
  final String? errorMessage;
  final String? message;

  FdaSubmissionResponse.success({
    required this.referenceId,
    this.message,
  })  : success = true,
        errorMessage = null;

  FdaSubmissionResponse.error({
    required this.errorMessage,
  })  : success = false,
        referenceId = null,
        message = null;
}

class FdaCertificateResponse {
  final bool success;
  final String? fdaCertificateId;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? errorMessage;

  FdaCertificateResponse.success({
    required this.fdaCertificateId,
    required this.issueDate,
    required this.expiryDate,
  })  : success = true,
        errorMessage = null;

  FdaCertificateResponse.error({
    required this.errorMessage,
  })  : success = false,
        fdaCertificateId = null,
        issueDate = null,
        expiryDate = null;
}

class FdaVerificationResponse {
  final bool isValid;
  final String? status;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? errorMessage;

  FdaVerificationResponse({
    required this.isValid,
    this.status,
    this.issueDate,
    this.expiryDate,
    this.errorMessage,
  });
}

class FdaException implements Exception {
  final String message;
  FdaException(this.message);

  @override
  String toString() => 'FdaException: $message';
}
