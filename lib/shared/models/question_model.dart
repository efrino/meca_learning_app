class QuestionModel {
  final String id;
  final String moduleId;
  final String questionText;
  final String? questionImageGdriveId;
  final String questionType; // 'multiple_choice', 'true_false', 'essay'
  final List<String>? options;
  final String correctAnswer;
  final String? explanation;
  final int points;
  final int orderIndex;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuestionModel({
    required this.id,
    required this.moduleId,
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
        return 'Essay';
      default:
        return questionType;
    }
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    List<String>? options;
    if (json['options'] != null) {
      options = List<String>.from(json['options'] as List);
    }

    return QuestionModel(
      id: json['id'] as String,
      moduleId: json['module_id'] as String,
      questionText: json['question_text'] as String,
      questionImageGdriveId: json['question_image_gdrive_id'] as String?,
      questionType: json['question_type'] as String? ?? 'multiple_choice',
      options: options,
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
    String? questionText,
    String? questionImageGdriveId,
    String? questionType,
    List<String>? options,
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
}

class UserAnswerModel {
  final String id;
  final String userId;
  final String questionId;
  final String moduleId;
  final int attemptNumber;
  final String selectedAnswer;
  final bool isCorrect;
  final int? timeSpentSeconds;
  final DateTime answeredAt;

  UserAnswerModel({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.moduleId,
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
      moduleId: json['module_id'] as String,
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
