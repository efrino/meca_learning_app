class ModuleModel {
  final String id;
  final String title;
  final String? description;
  final String category; // 'module', 'animation', 'meca_aid'
  final String gdriveFileId;
  final String? gdriveUrl;
  final String fileType; // 'pdf', 'mp4', 'image'
  final String? thumbnailUrl;
  final String? thumbnailGdriveId;
  final int? durationMinutes;
  final int orderIndex;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ModuleModel({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.gdriveFileId,
    this.gdriveUrl,
    required this.fileType,
    this.thumbnailUrl,
    this.thumbnailGdriveId,
    this.durationMinutes,
    this.orderIndex = 0,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPdf => fileType == 'pdf';
  bool get isVideo => fileType == 'mp4';
  bool get isImage => fileType == 'image';

  bool get isModuleCategory => category == 'module';
  bool get isAnimationCategory => category == 'animation';
  bool get isMecaAidCategory => category == 'meca_aid';

  String get categoryLabel {
    switch (category) {
      case 'module':
        return 'Modul';
      case 'animation':
        return 'Animasi';
      case 'meca_aid':
        return 'Meca Aid';
      default:
        return category;
    }
  }

  String get durationLabel {
    if (durationMinutes == null) return '';
    if (durationMinutes! < 60) {
      return '$durationMinutes menit';
    }
    final hours = durationMinutes! ~/ 60;
    final minutes = durationMinutes! % 60;
    if (minutes == 0) {
      return '$hours jam';
    }
    return '$hours jam $minutes menit';
  }

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      gdriveFileId: json['gdrive_file_id'] as String,
      gdriveUrl: json['gdrive_url'] as String?,
      fileType: json['file_type'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      thumbnailGdriveId: json['thumbnail_gdrive_id'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      orderIndex: json['order_index'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'gdrive_file_id': gdriveFileId,
      'gdrive_url': gdriveUrl,
      'file_type': fileType,
      'thumbnail_url': thumbnailUrl,
      'thumbnail_gdrive_id': thumbnailGdriveId,
      'duration_minutes': durationMinutes,
      'order_index': orderIndex,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'gdrive_file_id': gdriveFileId,
      'gdrive_url': gdriveUrl,
      'file_type': fileType,
      'thumbnail_url': thumbnailUrl,
      'thumbnail_gdrive_id': thumbnailGdriveId,
      'duration_minutes': durationMinutes,
      'order_index': orderIndex,
      'is_active': isActive,
      'created_by': createdBy,
    };
  }

  ModuleModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? gdriveFileId,
    String? gdriveUrl,
    String? fileType,
    String? thumbnailUrl,
    String? thumbnailGdriveId,
    int? durationMinutes,
    int? orderIndex,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModuleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      gdriveFileId: gdriveFileId ?? this.gdriveFileId,
      gdriveUrl: gdriveUrl ?? this.gdriveUrl,
      fileType: fileType ?? this.fileType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      thumbnailGdriveId: thumbnailGdriveId ?? this.thumbnailGdriveId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      orderIndex: orderIndex ?? this.orderIndex,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// URL langsung ke file PDF dari Google Drive
  /// Format: https://drive.google.com/uc?export=download&id=<FILE_ID>
  String get gdrivePdfUrl {
    if (!isPdf) return '';

    // Jika gdriveUrl berformat view, ubah ke format download
    if (gdriveUrl != null && gdriveUrl!.isNotEmpty) {
      if (gdriveUrl!.contains('/view') || gdriveUrl!.contains('/d/')) {
        final fileId =
            RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(gdriveUrl!)?.group(1);
        if (fileId != null) {
          return 'https://drive.google.com/uc?export=download&id=$fileId';
        }
      }
      return gdriveUrl!;
    }

    return 'https://drive.google.com/uc?export=download&id=$gdriveFileId';
  }

  /// URL untuk video streaming dari Google Drive
  String get gdriveVideoUrl {
    if (!isVideo) return '';
    return 'https://drive.google.com/uc?export=download&id=$gdriveFileId';
  }

  /// URL thumbnail dari Google Drive
  String getThumbnailUrl({int size = 220}) {
    if (thumbnailGdriveId != null) {
      return 'https://drive.google.com/thumbnail?id=$thumbnailGdriveId&sz=s$size';
    }
    return thumbnailUrl ?? '';
  }
}
