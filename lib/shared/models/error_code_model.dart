class ErrorCodeModel {
  final String id;
  final String code;
  final String title;
  final String cause;
  final String solution;
  final String? errorIdentification;
  final String? symptom;
  final String? notes;
  final String? category;
  final String? machineType;
  final String? serialNumber;
  final String severity; // 'low', 'medium', 'high', 'critical'
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ErrorCodeImageModel>? images;

  ErrorCodeModel({
    required this.id,
    required this.code,
    required this.title,
    required this.cause,
    required this.solution,
    this.errorIdentification,
    this.symptom,
    this.notes,
    this.category,
    this.machineType,
    this.serialNumber,
    this.severity = 'medium',
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.images,
  });

  String get severityLabel {
    switch (severity.toLowerCase()) {
      case 'low':
        return 'Rendah';
      case 'medium':
        return 'Sedang';
      case 'high':
        return 'Tinggi';
      case 'critical':
        return 'Kritis';
      default:
        return severity;
    }
  }

  factory ErrorCodeModel.fromJson(Map<String, dynamic> json) {
    List<ErrorCodeImageModel>? images;
    if (json['error_code_images'] != null) {
      images = (json['error_code_images'] as List)
          .map((e) => ErrorCodeImageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ErrorCodeModel(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      cause: json['cause'] as String,
      solution: json['solution'] as String,
      errorIdentification: json['error_identification'] as String?,
      symptom: json['symptom'] as String?,
      notes: json['notes'] as String?,
      category: json['category'] as String?,
      machineType: json['machine_type'] as String?,
      serialNumber: json['serial_number'] as String?,
      severity: json['severity'] as String? ?? 'medium',
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      images: images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'cause': cause,
      'solution': solution,
      'error_identification': errorIdentification,
      'symptom': symptom,
      'notes': notes,
      'category': category,
      'machine_type': machineType,
      'serial_number': serialNumber,
      'severity': severity,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'code': code,
      'title': title,
      'cause': cause,
      'solution': solution,
      'error_identification': errorIdentification,
      'symptom': symptom,
      'notes': notes,
      'category': category,
      'machine_type': machineType,
      'serial_number': serialNumber,
      'severity': severity,
      'is_active': isActive,
      'created_by': createdBy,
    };
  }

  ErrorCodeModel copyWith({
    String? id,
    String? code,
    String? title,
    String? cause,
    String? solution,
    String? errorIdentification,
    String? symptom,
    String? notes,
    String? category,
    String? machineType,
    String? serialNumber,
    String? severity,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ErrorCodeImageModel>? images,
  }) {
    return ErrorCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      cause: cause ?? this.cause,
      solution: solution ?? this.solution,
      errorIdentification: errorIdentification ?? this.errorIdentification,
      symptom: symptom ?? this.symptom,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      machineType: machineType ?? this.machineType,
      serialNumber: serialNumber ?? this.serialNumber,
      severity: severity ?? this.severity,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      images: images ?? this.images,
    );
  }
}

class ErrorCodeImageModel {
  final String id;
  final String errorCodeId;
  final String gdriveFileId;
  final String? gdriveUrl;
  final String? caption;
  final String imageType; // 'cause', 'solution', 'reference'
  final int orderIndex;
  final DateTime createdAt;

  ErrorCodeImageModel({
    required this.id,
    required this.errorCodeId,
    required this.gdriveFileId,
    this.gdriveUrl,
    this.caption,
    this.imageType = 'reference',
    this.orderIndex = 0,
    required this.createdAt,
  });

  String get imageTypeLabel {
    switch (imageType) {
      case 'cause':
        return 'Penyebab';
      case 'solution':
        return 'Solusi';
      case 'reference':
        return 'Referensi';
      default:
        return imageType;
    }
  }

  factory ErrorCodeImageModel.fromJson(Map<String, dynamic> json) {
    return ErrorCodeImageModel(
      id: json['id'] as String,
      errorCodeId: json['error_code_id'] as String,
      gdriveFileId: json['gdrive_file_id'] as String,
      gdriveUrl: json['gdrive_url'] as String?,
      caption: json['caption'] as String?,
      imageType: json['image_type'] as String? ?? 'reference',
      orderIndex: json['order_index'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'error_code_id': errorCodeId,
      'gdrive_file_id': gdriveFileId,
      'gdrive_url': gdriveUrl,
      'caption': caption,
      'image_type': imageType,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'error_code_id': errorCodeId,
      'gdrive_file_id': gdriveFileId,
      'gdrive_url': gdriveUrl,
      'caption': caption,
      'image_type': imageType,
      'order_index': orderIndex,
    };
  }
}
