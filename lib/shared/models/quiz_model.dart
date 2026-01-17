/// ============================================================
/// MODEL: QUIZ
/// ============================================================
class QuizModel {
  final String id;
  final String? moduleId;
  final String title;
  final String? description;
  final String quizType; // 'quiz', 'certification', 'practice_test'
  final String? sourceGdriveId;
  final String? sourceGdriveName;
  final int? timeLimitMinutes;
  final int passingScore;
  final int? maxAttempts;
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final bool showCorrectAnswers;
  final int totalQuestions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuizModel({
    required this.id,
    this.moduleId,
    required this.title,
    this.description,
    this.quizType = 'quiz',
    this.sourceGdriveId,
    this.sourceGdriveName,
    this.timeLimitMinutes,
    this.passingScore = 70,
    this.maxAttempts,
    this.shuffleQuestions = false,
    this.shuffleOptions = false,
    this.showCorrectAnswers = true,
    this.totalQuestions = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] as String,
      moduleId: json['module_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      quizType: json['quiz_type'] as String? ?? 'quiz',
      sourceGdriveId: json['source_gdrive_id'] as String?,
      sourceGdriveName: json['source_gdrive_name'] as String?,
      timeLimitMinutes: json['time_limit_minutes'] as int?,
      passingScore: json['passing_score'] as int? ?? 70,
      maxAttempts: json['max_attempts'] as int?,
      shuffleQuestions: json['shuffle_questions'] as bool? ?? false,
      shuffleOptions: json['shuffle_options'] as bool? ?? false,
      showCorrectAnswers: json['show_correct_answers'] as bool? ?? true,
      totalQuestions: json['total_questions'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module_id': moduleId,
      'title': title,
      'description': description,
      'quiz_type': quizType,
      'source_gdrive_id': sourceGdriveId,
      'source_gdrive_name': sourceGdriveName,
      'time_limit_minutes': timeLimitMinutes,
      'passing_score': passingScore,
      'max_attempts': maxAttempts,
      'shuffle_questions': shuffleQuestions,
      'shuffle_options': shuffleOptions,
      'show_correct_answers': showCorrectAnswers,
      'total_questions': totalQuestions,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// ============================================================
/// MODEL: QUESTION
/// ============================================================
class QuestionModel {
  final String id;
  final String? moduleId;
  final String? quizId;
  final String questionText;
  final String? questionImageGdriveId;
  final String questionType; // 'multiple_choice', 'true_false', 'essay'
  final List<Map<String, dynamic>>? options;
  final String correctAnswer;
  final String? explanation;
  final int points;
  final int orderIndex;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuestionModel({
    required this.id,
    this.moduleId,
    this.quizId,
    required this.questionText,
    this.questionImageGdriveId,
    this.questionType = 'multiple_choice',
    this.options,
    required this.correctAnswer,
    this.explanation,
    this.points = 10,
    this.orderIndex = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    // Parse options - bisa berupa List atau Map dari database
    List<Map<String, dynamic>>? parsedOptions;

    try {
      if (json['options'] != null) {
        final rawOptions = json['options'];

        // Debug: print type of rawOptions
        // debugPrint('Options type: ${rawOptions.runtimeType}');

        if (rawOptions is List) {
          // Jika sudah berupa List
          parsedOptions = [];
          for (int i = 0; i < rawOptions.length; i++) {
            final item = rawOptions[i];
            if (item is Map<String, dynamic>) {
              parsedOptions.add(item);
            } else if (item is Map) {
              parsedOptions.add(Map<String, dynamic>.from(item));
            } else if (item is String) {
              // Jika item hanya string, buat map dengan key dan text
              final key = String.fromCharCode(65 + i); // A, B, C, D
              parsedOptions.add({'key': key, 'text': item});
            } else {
              final key = String.fromCharCode(65 + i);
              parsedOptions.add({'key': key, 'text': item?.toString() ?? ''});
            }
          }
        } else if (rawOptions is Map) {
          // Jika berupa Map {"A": "text", "B": "text", ...}
          parsedOptions = [];
          final mapOptions = Map<String, dynamic>.from(rawOptions);
          mapOptions.forEach((key, value) {
            if (value is Map) {
              // Jika value sudah Map, tambahkan key jika belum ada
              final optionMap = Map<String, dynamic>.from(value);
              optionMap['key'] = optionMap['key'] ?? key.toString();
              parsedOptions!.add(optionMap);
            } else {
              // Jika value adalah string atau nilai lain
              parsedOptions!.add({
                'key': key.toString(),
                'text': value?.toString() ?? '',
              });
            }
          });
          // Sort by key (A, B, C, D)
          parsedOptions.sort(
              (a, b) => (a['key'] as String).compareTo(b['key'] as String));
        }
      }
    } catch (e) {
      // Jika gagal parsing options, gunakan null
      parsedOptions = null;
      // debugPrint('Error parsing options: $e');
    }

    return QuestionModel(
      id: json['id'] as String,
      moduleId: json['module_id'] as String?,
      quizId: json['quiz_id'] as String?,
      questionText: json['question_text'] as String,
      questionImageGdriveId: json['question_image_gdrive_id'] as String?,
      questionType: json['question_type'] as String? ?? 'multiple_choice',
      options: parsedOptions,
      correctAnswer: json['correct_answer'] as String,
      explanation: json['explanation'] as String?,
      points: json['points'] as int? ?? 10,
      orderIndex: json['order_index'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module_id': moduleId,
      'quiz_id': quizId,
      'question_text': questionText,
      'question_image_gdrive_id': questionImageGdriveId,
      'question_type': questionType,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'points': points,
      'order_index': orderIndex,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get list of option texts
  List<String> get optionTexts {
    if (options == null || options!.isEmpty) return [];
    return options!.map((o) => o['text']?.toString() ?? '').toList();
  }

  /// Get list of option keys (A, B, C, D)
  List<String> get optionKeys {
    if (options == null || options!.isEmpty) return [];
    return options!.map((o) => o['key']?.toString() ?? '').toList();
  }

  /// Get option text by key
  String? getOptionText(String key) {
    if (options == null || options!.isEmpty) return null;
    try {
      final option = options!.firstWhere(
        (o) => o['key']?.toString().toUpperCase() == key.toUpperCase(),
      );
      return option['text']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Check if answer is correct
  bool isCorrectAnswer(String answer) {
    return answer.toLowerCase().trim() == correctAnswer.toLowerCase().trim();
  }

  /// Get formatted options for display (returns list of "A. Option text" format)
  List<String> get formattedOptions {
    if (options == null || options!.isEmpty) return [];
    return options!.map((o) {
      final key = o['key']?.toString() ?? '';
      final text = o['text']?.toString() ?? '';
      return '$key. $text';
    }).toList();
  }
}

/// ============================================================
/// MODEL: MECA AID FOLDER
/// ============================================================
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
}
