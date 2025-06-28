import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thai_herbal_gacp_backend/event_ledger/event_store.dart';
import 'package:thai_herbal_gacp_backend/gacp_certification/application_service.dart';
import 'package:thai_herbal_gacp_backend/services/ai_validator.dart';
import 'package:thai_herbal_gacp_backend/services/document_storage.dart';
import 'package:thai_herbal_gacp_backend/services/fda_client.dart';
import 'package:thai_herbal_gacp_models/application.dart';
import 'package:thai_herbal_gacp_models/certificate.dart';

@GenerateMocks([
  EventStore,
  AiValidator,
  DocumentStorage,
  FdaClient,
])
import 'gacp_flow_test.mocks.dart';

void main() {
  group('GACP Application Flow', () {
    late MockEventStore mockEventStore;
    late MockAiValidator mockAiValidator;
    late MockDocumentStorage mockDocumentStorage;
    late MockFdaClient mockFdaClient;
    late GacpApplicationService service;

    setUp(() {
      mockEventStore = MockEventStore();
      mockAiValidator = MockAiValidator();
      mockDocumentStorage = MockDocumentStorage();
      mockFdaClient = MockFdaClient();
      
      service = GacpApplicationService(
        eventStore: mockEventStore,
        aiValidator: mockAiValidator,
        documentStorage: mockDocumentStorage,
        fdaClient: mockFdaClient,
      );
    });

    test('Successful application flow', () async {
      // Setup
      final application = GacpApplication(
        id: 'app_123',
        companyName: 'สมุนไพรไทย จำกัด',
        taxId: '1234567890123',
        address: '123 ถนนสมุนไพร แขวงอนุสาวรีย์ เขตบางเขน กรุงเทพฯ',
        phone: '021234567',
        email: 'info@thaiherb.com',
        herbalTypes: ['ฟ้าทะลายโจร', 'กระชาย'],
        farmArea: 5.0,
        productionCapacity: 1000.0,
        status: ApplicationStatus.draft,
      );

      final documents = {
        DocumentType.commercialRegistration: File('path/to/regis.pdf'),
        DocumentType.landDocument: File('path/to/land.pdf'),
      };

      final documentUrls = {
        DocumentType.commercialRegistration: 'https://storage.com/regis.pdf',
        DocumentType.landDocument: 'https://storage.com/land.pdf',
      };

      // Mock document storage
      when(mockDocumentStorage.uploadDocument(any, any)).thenAnswer(
        (_) async => 'https://storage.com/file.pdf',
      );

      // Mock AI validation
      when(mockAiValidator.validateDocuments(any, any)).thenAnswer(
        (_) async => DocumentValidationResult(isValid: true, errors: []),
      );

      // Mock FDA submission
      when(mockFdaClient.submitApplication(any)).thenAnswer(
        (_) async => FdaSubmissionResponse.success(
          referenceId: 'fda_ref_123',
          message: 'Success',
        ),
      );

      // Execute
      final result = await service.submitApplication(application, documents);

      // Verify
      expect(result.status, ApplicationStatus.approved);
      expect(result.fdaReferenceId, 'fda_ref_123');
      
      // Verify event sequence
      verifyInOrder([
        mockEventStore.saveEvent(
          application.id,
          'GacpApplicationSubmitted',
          any,
        ),
        mockEventStore.saveEvent(
          application.id,
          'GacpApplicationValidated',
          any,
        ),
        mockEventStore.saveEvent(
          application.id,
          'GacpApplicationApproved',
          any,
        ),
      ]);
    });

    test('Application rejection due to invalid documents', () async {
      // Setup
      final application = GacpApplication(
        id: 'app_456',
        companyName: 'เฮิร์บฟาร์ม',
        taxId: '9876543210987',
        address: '456 หมู่บ้านสมุนไพร จังหวัดเชียงใหม่',
        phone: '053123456',
        email: 'contact@herbfarm.com',
        herbalTypes: ['ขิง'],
        farmArea: 3.5,
        productionCapacity: 500.0,
        status: ApplicationStatus.draft,
      );

      final documents = {
        DocumentType.commercialRegistration: File('path/to/regis.pdf'),
      };

      // Mock document storage
      when(mockDocumentStorage.uploadDocument(any, any)).thenAnswer(
        (_) async => 'https://storage.com/file.pdf',
      );

      // Mock AI validation to fail
      when(mockAiValidator.validateDocuments(any, any)).thenAnswer(
        (_) async => DocumentValidationResult(
          isValid: false,
          errors: ['Missing land document'],
        ),
      );

      // Execute & Verify
      expect(
        () => service.submitApplication(application, documents),
        throwsA(isA<ApplicationException>()),
      );

      // Verify rejection event
      verify(mockEventStore.saveEvent(
        application.id,
        'GacpApplicationRejected',
        any,
      ));
    });

    test('Application status retrieval', () async {
      // Setup
      final applicationId = 'app_789';
      
      // Mock event store
      when(mockEventStore.getEvents(applicationId)).thenAnswer(
        (_) async => [
          EventRecord(
            eventType: 'GacpApplicationSubmitted',
            eventData: {
              'id': applicationId,
              'companyName': 'Green Herb Co.',
              'status': 'draft',
            },
            timestamp: DateTime.now(),
            version: 1,
          ),
          EventRecord(
            eventType: 'GacpApplicationValidated',
            eventData: {'status': 'under_review'},
            timestamp: DateTime.now(),
            version: 2,
          ),
          EventRecord(
            eventType: 'GacpApplicationApproved',
            eventData: {
              'status': 'approved',
              'fdaReferenceId': 'fda_ref_789',
            },
            timestamp: DateTime.now(),
            version: 3,
          ),
        ],
      );

      // Execute
      final result = await service.getApplicationStatus(applicationId);

      // Verify
      expect(result.id, applicationId);
      expect(result.status, ApplicationStatus.approved);
      expect(result.fdaReferenceId, 'fda_ref_789');
    });
  });
}
