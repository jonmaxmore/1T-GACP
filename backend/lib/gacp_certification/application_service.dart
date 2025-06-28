import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:thai_herbal_gacp_backend/event_ledger/event_store.dart';
import 'package:thai_herbal_gacp_backend/gacp_certification/validation_service.dart';
import 'package:thai_herbal_gacp_backend/models/application.dart';
import 'package:thai_herbal_gacp_backend/services/ai_validator.dart';
import 'package:thai_herbal_gacp_backend/services/document_storage.dart';
import 'package:thai_herbal_gacp_backend/services/fda_client.dart';

class GacpApplicationService {
  final EventStore eventStore;
  final AiValidator aiValidator;
  final DocumentStorage documentStorage;
  final FdaClient fdaClient;

  GacpApplicationService({
    required this.eventStore,
    required this.aiValidator,
    required this.documentStorage,
    required this.fdaClient,
  });

  Future<GacpApplication> submitApplication(
    GacpApplication application,
    Map<DocumentType, File> documents,
  ) async {
    // Save initial event
    await eventStore.saveEvent(
      application.id,
      'GacpApplicationSubmitted',
      application.toJson(),
    );

    // Upload documents
    final documentUrls = await _uploadDocuments(application.id, documents);

    // Validate documents with AI
    final validationResult = await aiValidator.validateDocuments(
      documentUrls,
      application.herbalTypes,
    );

    if (!validationResult.isValid) {
      await eventStore.saveEvent(
        application.id,
        'GacpApplicationRejected',
        {
          'reason': 'เอกสารไม่ผ่านการตรวจสอบ',
          'errors': validationResult.errors,
        },
      );
      throw ApplicationException('เอกสารไม่ถูกต้อง: ${validationResult.errors.join(', ')}');
    }

    // Update application status
    final updatedApplication = application.copyWith(
      status: ApplicationStatus.underReview,
      documentUrls: documentUrls,
    );

    // Save validation event
    await eventStore.saveEvent(
      application.id,
      'GacpApplicationValidated',
      updatedApplication.toJson(),
    );

    // Submit to FDA
    final fdaResponse = await fdaClient.submitApplication(updatedApplication);

    if (!fdaResponse.success) {
      await eventStore.saveEvent(
        application.id,
        'GacpApplicationFDASubmissionFailed',
        {'error': fdaResponse.errorMessage},
      );
      throw ApplicationException('ส่งข้อมูล FDA ไม่สำเร็จ: ${fdaResponse.errorMessage}');
    }

    // Final update
    final approvedApplication = updatedApplication.copyWith(
      status: ApplicationStatus.approved,
      fdaReferenceId: fdaResponse.referenceId,
      approvalDate: DateTime.now(),
    );

    await eventStore.saveEvent(
      application.id,
      'GacpApplicationApproved',
      approvedApplication.toJson(),
    );

    return approvedApplication;
  }

  Future<Map<DocumentType, String>> _uploadDocuments(
    String applicationId,
    Map<DocumentType, File> documents,
  ) async {
    final documentUrls = <DocumentType, String>{};

    for (final entry in documents.entries) {
      final url = await documentStorage.uploadDocument(
        'applications/$applicationId/${entry.key.name}',
        entry.value,
      );
      documentUrls[entry.key] = url;
    }

    return documentUrls;
  }

  Future<GacpApplication> getApplicationStatus(String applicationId) async {
    final events = await eventStore.getEvents(applicationId);
    
    if (events.isEmpty) {
      throw ApplicationException('ไม่พบข้อมูลคำร้อง');
    }

    // Rebuild application state from events
    GacpApplication? currentState;
    for (final event in events) {
      switch (event.eventType) {
        case 'GacpApplicationSubmitted':
          currentState = GacpApplication.fromJson(event.eventData);
          break;
        case 'GacpApplicationValidated':
          currentState = currentState?.copyWith(
            status: ApplicationStatus.underReview,
            documentUrls: Map<DocumentType, String>.from(
              event.eventData['documentUrls'] as Map,
            ),
          );
          break;
        case 'GacpApplicationApproved':
          currentState = currentState?.copyWith(
            status: ApplicationStatus.approved,
            fdaReferenceId: event.eventData['fdaReferenceId'] as String,
            approvalDate: DateTime.parse(event.eventData['approvalDate'] as String),
          );
          break;
        case 'GacpApplicationRejected':
          currentState = currentState?.copyWith(
            status: ApplicationStatus.rejected,
            rejectionReason: event.eventData['reason'] as String,
          );
          break;
      }
    }

    if (currentState == null) {
      throw ApplicationException('ไม่สามารถสร้างสถานะคำร้องได้');
    }

    return currentState;
  }
}

class ApplicationException implements Exception {
  final String message;
  ApplicationException(this.message);

  @override
  String toString() => 'ApplicationException: $message';
}
