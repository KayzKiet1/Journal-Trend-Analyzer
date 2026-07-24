class ManagedDocument {
  const ManagedDocument({
    required this.id,
    required this.path,
    required this.exists,
    required this.data,
  });

  final String id;
  final String path;
  final bool exists;
  final Map<String, dynamic> data;

  factory ManagedDocument.fromMap(Map<String, dynamic> map) {
    return ManagedDocument(
      id: map['id']?.toString() ?? '',
      path: map['path']?.toString() ?? '',
      exists: map['exists'] != false,
      data: Map<String, dynamic>.from(map['data'] as Map? ?? const {}),
    );
  }
}
