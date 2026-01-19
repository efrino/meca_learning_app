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
/// Supports multiple_choice, true_false, and essay types
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

  bool get isMultipleChoice => questionType == 'multiple_choice';
  bool get isTrueFalse => questionType == 'true_false';
  bool get isEssay => questionType == 'essay';

  String get questionTypeLabel {
    switch (questionType) {
      case 'multiple_choice':
        return 'Pilihan Ganda';
      case 'true_false':
        return 'Benar/Salah';
      case 'essay':
        return 'Uraian';
      default:
        return questionType;
    }
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    // Parse options - bisa berupa List atau Map dari database
    List<Map<String, dynamic>>? parsedOptions;

    try {
      if (json['options'] != null) {
        final rawOptions = json['options'];

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

  Map<String, dynamic> toInsertJson() {
    return {
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
    };
  }

  QuestionModel copyWith({
    String? id,
    String? moduleId,
    String? quizId,
    String? questionText,
    String? questionImageGdriveId,
    String? questionType,
    List<Map<String, dynamic>>? options,
    String? correctAnswer,
    String? explanation,
    int? points,
    int? orderIndex,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      quizId: quizId ?? this.quizId,
      questionText: questionText ?? this.questionText,
      questionImageGdriveId:
          questionImageGdriveId ?? this.questionImageGdriveId,
      questionType: questionType ?? this.questionType,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      points: points ?? this.points,
      orderIndex: orderIndex ?? this.orderIndex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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
  /// For essay type, this does a case-insensitive comparison
  /// and checks if answer contains key phrases
  bool isCorrectAnswer(String answer) {
    if (isEssay) {
      // For essay, check if key phrases from correct answer are present
      final correctLower = correctAnswer.toLowerCase().trim();
      final answerLower = answer.toLowerCase().trim();

      // Simple keyword matching for essay
      final keywords = correctLower
          .split(RegExp(r'[\s,;.]+'))
          .where((w) => w.length > 3)
          .toList();

      if (keywords.isEmpty) {
        return answerLower.contains(correctLower) ||
            correctLower.contains(answerLower);
      }

      // Check if at least 50% of keywords are present
      int matchCount = 0;
      for (final keyword in keywords) {
        if (answerLower.contains(keyword)) {
          matchCount++;
        }
      }

      return matchCount >= (keywords.length * 0.5).ceil();
    }

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
/// MODEL: USER ANSWER
/// ============================================================
class UserAnswerModel {
  final String id;
  final String userId;
  final String questionId;
  final String? moduleId;
  final int attemptNumber;
  final String selectedAnswer;
  final bool isCorrect;
  final int? timeSpentSeconds;
  final DateTime answeredAt;

  UserAnswerModel({
    required this.id,
    required this.userId,
    required this.questionId,
    this.moduleId,
    this.attemptNumber = 1,
    required this.selectedAnswer,
    required this.isCorrect,
    this.timeSpentSeconds,
    required this.answeredAt,
  });

  factory UserAnswerModel.fromJson(Map<String, dynamic> json) {
    return UserAnswerModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      questionId: json['question_id'] as String,
      moduleId: json['module_id'] as String?,
      attemptNumber: json['attempt_number'] as int? ?? 1,
      selectedAnswer: json['selected_answer'] as String,
      isCorrect: json['is_correct'] as bool,
      timeSpentSeconds: json['time_spent_seconds'] as int?,
      answeredAt: DateTime.parse(json['answered_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'question_id': questionId,
      'module_id': moduleId,
      'attempt_number': attemptNumber,
      'selected_answer': selectedAnswer,
      'is_correct': isCorrect,
      'time_spent_seconds': timeSpentSeconds,
      'answered_at': answeredAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'question_id': questionId,
      'module_id': moduleId,
      'attempt_number': attemptNumber,
      'selected_answer': selectedAnswer,
      'is_correct': isCorrect,
      'time_spent_seconds': timeSpentSeconds,
    };
  }
}

/// ============================================================
/// MODEL: QUIZ ATTEMPT SUMMARY
/// For displaying attempt history
/// ============================================================
class QuizAttemptSummary {
  final int attemptNumber;
  final int correctCount;
  final int totalAnswered;
  final int totalQuestions;
  final int earnedPoints;
  final int totalPoints;
  final int score;
  final int timeSpentSeconds;
  final DateTime? completedAt;

  QuizAttemptSummary({
    required this.attemptNumber,
    required this.correctCount,
    required this.totalAnswered,
    required this.totalQuestions,
    required this.earnedPoints,
    required this.totalPoints,
    required this.score,
    required this.timeSpentSeconds,
    this.completedAt,
  });

  factory QuizAttemptSummary.fromJson(Map<String, dynamic> json) {
    return QuizAttemptSummary(
      attemptNumber: json['attempt_number'] as int? ?? 1,
      correctCount: json['correct_count'] as int? ?? 0,
      totalAnswered: json['total_answered'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      earnedPoints: json['earned_points'] as int? ?? 0,
      totalPoints: json['total_points'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
      timeSpentSeconds: json['time_spent_seconds'] as int? ?? 0,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }

  bool get isPassed => score >= 70;

  String get formattedTime {
    if (timeSpentSeconds < 60) return '${timeSpentSeconds}s';
    final minutes = timeSpentSeconds ~/ 60;
    final secs = timeSpentSeconds % 60;
    return '${minutes}m ${secs}s';
  }

  String get formattedDate {
    if (completedAt == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(completedAt!);

    if (diff.inDays == 0) {
      return 'Hari ini';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return '${completedAt!.day}/${completedAt!.month}/${completedAt!.year}';
    }
  }
}
