class MecaAidFolder {
  final String id;
  final String gdriveFolderId;
  final String folderName;
  final String? description;
  final int orderIndex;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MecaAidFolder({
    required this.id,
    required this.gdriveFolderId,
    required this.folderName,
    this.description,
    this.orderIndex = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MecaAidFolder.fromJson(Map<String, dynamic> json) {
    return MecaAidFolder(
      id: json['id'] as String,
      gdriveFolderId: json['gdrive_folder_id'] as String,
      folderName: json['folder_name'] as String,
      description: json['description'] as String?,
      orderIndex: json['order_index'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gdrive_folder_id': gdriveFolderId,
      'folder_name': folderName,
      'description': description,
      'order_index': orderIndex,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'gdrive_folder_id': gdriveFolderId,
      'folder_name': folderName,
      'description': description,
      'order_index': orderIndex,
      'is_active': isActive,
    };
  }

  MecaAidFolder copyWith({
    String? id,
    String? gdriveFolderId,
    String? folderName,
    String? description,
    int? orderIndex,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MecaAidFolder(
      id: id ?? this.id,
      gdriveFolderId: gdriveFolderId ?? this.gdriveFolderId,
      folderName: folderName ?? this.folderName,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
