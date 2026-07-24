import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../data/models/managed_collection.dart';
import '../../data/models/managed_document.dart';
import '../../data/repositories/admin_repository.dart';

class FirestoreManagerViewModel extends ChangeNotifier {
  FirestoreManagerViewModel({AdminRepository? adminRepository})
    : _adminRepository = adminRepository ?? const FirebaseAdminRepository();

  final AdminRepository _adminRepository;

  List<ManagedCollection> _collections = [];
  final List<ManagedDocument> _documents = [];
  ManagedDocument? _selectedDocument;
  String _nextPageToken = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<ManagedCollection> get collections => List.unmodifiable(_collections);

  List<ManagedDocument> get documents => List.unmodifiable(_documents);

  ManagedDocument? get selectedDocument => _selectedDocument;

  bool get isLoading => _isLoading;

  bool get hasMoreDocuments => _nextPageToken.isNotEmpty;

  String? get errorMessage => _errorMessage;

  Future<void> loadCollections() async {
    await _run(() async {
      _collections = await _adminRepository.listManagedCollections();
    });
  }

  Future<void> loadDocuments(
    String collectionName, {
    bool refresh = false,
  }) async {
    await _run(() async {
      if (refresh) {
        _documents.clear();
        _nextPageToken = '';
      }

      final result = await _adminRepository.listManagedDocuments(
        collectionName: collectionName,
        startAfterId: _nextPageToken.isEmpty ? null : _nextPageToken,
      );
      _documents.addAll(result.documents);
      _nextPageToken = result.nextPageToken;
    });
  }

  Future<void> loadDocument({
    required String collectionName,
    required String documentId,
  }) async {
    await _run(() async {
      _selectedDocument = await _adminRepository.getManagedDocument(
        collectionName: collectionName,
        documentId: documentId,
      );
    });
  }

  Future<void> saveDocument({
    required String collectionName,
    required String documentId,
    required String jsonText,
  }) async {
    late final Map<String, dynamic> decoded;
    try {
      final value = jsonDecode(jsonText);
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Document JSON must be an object.');
      }
      decoded = value;
    } on FormatException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return;
    }

    await _run(() async {
      _selectedDocument = await _adminRepository.saveManagedDocument(
        collectionName: collectionName,
        documentId: documentId,
        data: decoded,
      );
    });
  }

  Future<void> deleteDocument({
    required String collectionName,
    required String documentId,
  }) async {
    await _run(() async {
      await _adminRepository.deleteManagedDocument(
        collectionName: collectionName,
        documentId: documentId,
      );
      _selectedDocument = null;
    });
  }

  String prettyJson(Object? value) {
    return const JsonEncoder.withIndent('  ').convert(value ?? const {});
  }

  Future<void> _run(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } on Exception catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
