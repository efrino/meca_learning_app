class ModuleModel {
  final String id;
  final String title;
  final String? description;
  final String category; // 'module', 'animation', 'meca_aid', 'meca_sheet'
  final String gdriveFileId;
  final String? gdriveUrl;
  final String fileType; // 'pdf', 'mp4', 'image', 'xls', 'xlsx', 'swf'
  final String? thumbnailUrl;
  final String? thumbnailGdriveId;
  final int? durationMinutes;
  final int orderIndex;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String?
      parentFolderId; // Reference to meca_aid_folders.gdrive_folder_id
  final String? folderName;

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
    this.parentFolderId,
    this.folderName,
  });

  bool get isPdf => fileType == 'pdf';
  bool get isVideo => fileType == 'mp4';
  bool get isImage => fileType == 'image';
  bool get isExcel => fileType == 'xls' || fileType == 'xlsx';
  bool get isSwf => fileType == 'swf';

  bool get isModuleCategory => category == 'module';
  bool get isAnimationCategory => category == 'animation';
  bool get isMecaAidCategory => category == 'meca_aid';
  bool get isMecaSheetCategory => category == 'meca_sheet';

  String get categoryLabel {
    switch (category) {
      case 'module':
        return 'Modul';
      case 'animation':
        return 'Animasi';
      case 'meca_aid':
        return 'Meca Aid';
      case 'meca_sheet':
        return 'Meca Sheet';
      default:
        return category;
    }
  }

  String get fileTypeLabel {
    switch (fileType) {
      case 'pdf':
        return 'PDF';
      case 'mp4':
        return 'Video';
      case 'image':
        return 'Gambar';
      case 'xls':
      case 'xlsx':
        return 'Excel';
      case 'swf':
        return 'Flash';
      default:
        return fileType.toUpperCase();
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
      parentFolderId: json['parent_folder_id'] as String?,
      folderName: json['folder_name'] as String?,
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
      'parent_folder_id': parentFolderId,
      'folder_name': folderName,
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
      'parent_folder_id': parentFolderId,
      'folder_name': folderName,
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
    String? parentFolderId,
    String? folderName,
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
      parentFolderId: parentFolderId ?? this.parentFolderId,
      folderName: folderName ?? this.folderName,
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

  /// URL untuk file Excel dari Google Drive
  String get gdriveExcelUrl {
    if (!isExcel) return '';
    return 'https://drive.google.com/uc?export=download&id=$gdriveFileId';
  }

  /// URL thumbnail dari Google Drive
  /// Mengkonversi berbagai format URL ke format download langsung
  String getThumbnailUrl({int size = 220}) {
    // Prioritas 1: Jika ada thumbnailGdriveId, gunakan format thumbnail
    if (thumbnailGdriveId != null && thumbnailGdriveId!.isNotEmpty) {
      return 'https://drive.google.com/thumbnail?id=$thumbnailGdriveId&sz=s$size';
    }

    // Prioritas 2: Jika thumbnailUrl adalah Google Drive link, extract ID dan konversi
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      // Cek apakah URL adalah Google Drive link
      if (thumbnailUrl!.contains('drive.google.com')) {
        // Extract file ID dari berbagai format URL Google Drive
        String? fileId;

        // Format: /d/{fileId}/
        final dMatch = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(thumbnailUrl!);
        if (dMatch != null) {
          fileId = dMatch.group(1);
        }

        // Format: id={fileId}
        if (fileId == null) {
          final idMatch =
              RegExp(r'id=([a-zA-Z0-9_-]+)').firstMatch(thumbnailUrl!);
          if (idMatch != null) {
            fileId = idMatch.group(1);
          }
        }

        if (fileId != null) {
          return 'https://drive.google.com/thumbnail?id=$fileId&sz=s$size';
        }
      }

      // Jika bukan Google Drive URL, kembalikan apa adanya
      return thumbnailUrl!;
    }

    return '';
  }

  /// Get Google Drive file ID from thumbnail URL or thumbnailGdriveId
  String? get thumbnailFileId {
    // Prioritas 1: thumbnailGdriveId langsung
    if (thumbnailGdriveId != null && thumbnailGdriveId!.isNotEmpty) {
      return thumbnailGdriveId;
    }

    // Prioritas 2: Extract dari thumbnailUrl
    if (thumbnailUrl != null && thumbnailUrl!.contains('drive.google.com')) {
      // Format: /d/{fileId}/
      final dMatch = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(thumbnailUrl!);
      if (dMatch != null) {
        return dMatch.group(1);
      }

      // Format: id={fileId}
      final idMatch = RegExp(r'id=([a-zA-Z0-9_-]+)').firstMatch(thumbnailUrl!);
      if (idMatch != null) {
        return idMatch.group(1);
      }
    }

    return null;
  }
}
