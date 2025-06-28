import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:thai_herbal_gacp_backend/services/fda_client.dart';
import 'package:thai_herbal_gacp_models/application.dart';
import 'package:thai_herbal_gacp_models/certificate.dart';

@GenerateMocks([Dio])
import 'fda_connector_test.mocks.dart';

void main() {
  group('FDA Client Integration', () {
    late MockDio mockDio;
    late FdaClient fdaClient;
    const baseUrl = 'https://fda-sandbox.api.com';
    const apiKey = 'test-api-key';

    setUp(() {
      mockDio = MockDio();
      fdaClient = FdaClient(
        baseUrl: baseUrl,
        apiKey: apiKey,
        mapper: GacpMapper(),
        certificateAdapter: CertificateAdapter(),
        dio: mockDio,
      );
    });

    test('Successful application submission', () async {
      // Setup
      final application = GacpApplication(
        id: 'app_123',
        companyName: 'สมุนไพรไทย จำกัด',
        taxId: '1234567890123',
        address: '123 ถนนสมุนไพร กรุงเทพฯ',
        phone: '021234567',
        email: 'info@thaiherb.com',
        herbalTypes: ['ฟ้าทะลายโจร'],
        farmArea: 5.0,
        productionCapacity: 1000.0,
      );

      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/gacp/applications'),
          statusCode: 202,
          data: {'referenceId': 'fda_ref_123'},
        ),
      );

      // Execute
      final result = await fdaClient.submitApplication(application);

      // Verify
      expect(result.success, isTrue);
      expect(result.referenceId, 'fda_ref_123');
    });

    test('Certificate issuance', () async {
      // Setup
      final certificate = GacpCertificate(
        id: 'cert_456',
        certificateNumber: 'GACP-2023-001',
        companyName: 'สมุนไพรไทย จำกัด',
        herbalTypes: ['ฟ้าทะลายโจร'],
        issueDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        status: CertificateStatus.active,
        verificationUrl: 'https://verify.gacp.th/cert_456',
      );

      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/gacp/certificates'),
          statusCode: 201,
          data: {
            'certificateId': 'fda_cert_456',
            'issueDate': '2023-10-01T00:00:00Z',
            'expiryDate': '2024-10-01T00:00:00Z',
          },
        ),
      );

      // Execute
      final result = await fdaClient.issueCertificate(certificate);

      // Verify
      expect(result.success, isTrue);
      expect(result.fdaCertificateId, 'fda_cert_456');
    });

    test('Certificate verification', () async {
      // Setup
      const certificateNumber = 'GACP-2023-001';

      when(mockDio.get(any)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/gacp/certificates/$certificateNumber/verify',
          ),
          statusCode: 200,
          data: {
            'status': 'active',
            'issueDate': '2023-10-01T00:00:00Z',
            'expiryDate': '2024-10-01T00:00:00Z',
          },
        ),
      );

      // Execute
      final result = await fdaClient.verifyCertificate(certificateNumber);

      // Verify
      expect(result.isValid, isTrue);
      expect(result.status, 'active');
    });

    test('Handle API errors', () async {
      // Setup
      final application = GacpApplication(
        id: 'app_789',
        companyName: 'ทดสอบ',
        taxId: '1111111111111',
        address: 'ที่อยู่',
        phone: '000000000',
        email: 'test@test.com',
        herbalTypes: ['สมุนไพร'],
        farmArea: 1.0,
        productionCapacity: 100.0,
      );

      when(mockDio.post(any, data: anyNamed('data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/gacp/applications'),
          response: Response(
            requestOptions: RequestOptions(path: '/gacp/applications'),
            statusCode: 400,
            data: {'error': 'Invalid tax ID'},
          ),
        ),
      );

      // Execute
      final result = await fdaClient.submitApplication(application);

      // Verify
      expect(result.success, isFalse);
      expect(result.errorMessage, 'Invalid tax ID');
    });
  });
}
