class EmployeeDocument {
  final String id;
  final String employeeId;
  final String name;
  final String fileName;
  final String category;
  final String filePath;
  final DateTime uploadedAt;
  final int fileSize;

  const EmployeeDocument({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.fileName,
    required this.category,
    required this.filePath,
    required this.uploadedAt,
    this.fileSize = 0,
  });

  EmployeeDocument copyWith({
    String? id,
    String? employeeId,
    String? name,
    String? fileName,
    String? category,
    String? filePath,
    DateTime? uploadedAt,
    int? fileSize,
  }) {
    return EmployeeDocument(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      fileName: fileName ?? this.fileName,
      category: category ?? this.category,
      filePath: filePath ?? this.filePath,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeId': employeeId,
    'name': name,
    'fileName': fileName,
    'category': category,
    'filePath': filePath,
    'uploadedAt': uploadedAt.toIso8601String(),
    'fileSize': fileSize,
  };

  factory EmployeeDocument.fromJson(Map<String, dynamic> json) {
    return EmployeeDocument(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      name: json['name'] as String,
      fileName: json['fileName'] as String,
      category: json['category'] as String,
      filePath: json['filePath'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      fileSize: json['fileSize'] as int? ?? 0,
    );
  }

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
