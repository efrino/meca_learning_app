import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../shared/models/quiz_model.dart';

/// ============================================================
/// QUIZ PLAY SCREEN
/// Screen untuk mengerjakan quiz dengan dukungan essay
/// ============================================================
class QuizPlayScreen extends StatefulWidget {
  final QuizModel quiz;
  final List<QuestionModel> questions;
  final int attemptNumber;

  const QuizPlayScreen({
    super.key,
    required this.quiz,
    required this.questions,
    this.attemptNumber = 1,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  int _currentIndex = 0;
  Map<String, String> _answers = {};
  Map<String, TextEditingController> _essayControllers = {};
  Timer? _timer;
  int _timeRemaining = 0;
  int _timeSpent = 0;
  bool _isSubmitting = false;

  QuestionModel get _currentQuestion => widget.questions[_currentIndex];

  @override
  void initState() {
    super.initState();
    _initEssayControllers();
    _startTimer();
    ActivityLogService().logButtonClick(
        buttonId: 'quiz_started_${widget.quiz.id}',
        screenName: 'quiz_play_screen');
  }

  void _initEssayControllers() {
    for (final question in widget.questions) {
      if (question.isEssay) {
        _essayControllers[question.id] = TextEditingController();
      }
    }
  }

  void _startTimer() {
    if (widget.quiz.timeLimitMinutes != null) {
      _timeRemaining = widget.quiz.timeLimitMinutes! * 60;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeSpent++;
        if (widget.quiz.timeLimitMinutes != null) {
          _timeRemaining--;
          if (_timeRemaining <= 0) {
            _submitQuiz();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _essayControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Color get _typeColor {
    switch (widget.quiz.quizType) {
      case 'certification':
        return const Color(0xFF9C27B0);
      case 'practice_test':
        return const Color(0xFFFF9800);
      default:
        return AppTheme.mecaAidColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Soal ${_currentIndex + 1}/${widget.questions.length}'),
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left),
        onPressed: () async {
          if (await _showExitDialog()) {
            Navigator.pop(context);
          }
        },
      ),
      actions: [
        // Attempt number badge
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Attempt #${widget.attemptNumber}',
            style: TextStyle(
              color: _typeColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        // Timer
        if (widget.quiz.timeLimitMinutes != null)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timeRemaining < 60
                  ? Colors.red.withOpacity(0.1)
                  : _typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.clock,
                  size: 16,
                  color: _timeRemaining < 60 ? Colors.red : _typeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_timeRemaining),
                  style: TextStyle(
                    color: _timeRemaining < 60 ? Colors.red : _typeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Bar
          _buildProgressBar(),
          const SizedBox(height: 24),

          // Question Card
          _buildQuestionCard(),
          const SizedBox(height: 20),

          // Answer section based on question type
          _buildAnswerSection(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${_answers.length}/${widget.questions.length} dijawab',
              style: TextStyle(
                fontSize: 12,
                color: _typeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _answers.length / widget.questions.length,
            backgroundColor: _typeColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(_typeColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question type and number badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Pertanyaan ${_currentIndex + 1}',
                  style: TextStyle(
                    color: _typeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getQuestionTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentQuestion.questionTypeLabel,
                  style: TextStyle(
                    color: _getQuestionTypeColor(),
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question text
          Text(
            _currentQuestion.questionText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),

          // Question image (jika ada)
          if (_currentQuestion.questionImageGdriveId != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'https://drive.google.com/thumbnail?id=${_currentQuestion.questionImageGdriveId}&sz=s600',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: AppTheme.backgroundColor,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    color: AppTheme.backgroundColor,
                    child: const Center(
                      child: Icon(Iconsax.image, color: AppTheme.textLight),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Points
          Row(
            children: [
              Icon(Iconsax.medal_star, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                '${_currentQuestion.points} poin',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getQuestionTypeColor() {
    switch (_currentQuestion.questionType) {
      case 'multiple_choice':
        return Colors.blue;
      case 'true_false':
        return Colors.orange;
      case 'essay':
        return Colors.purple;
      default:
        return _typeColor;
    }
  }

  Widget _buildAnswerSection() {
    switch (_currentQuestion.questionType) {
      case 'true_false':
        return _buildTrueFalseOptions();
      case 'essay':
        return _buildEssayInput();
      default:
        return _buildMultipleChoiceOptions();
    }
  }

  Widget _buildMultipleChoiceOptions() {
    final options = _currentQuestion.options ?? [];
    final selectedAnswer = _answers[_currentQuestion.id];

    return Column(
      children: List.generate(options.length, (index) {
        final option = options[index];
        final optionKey =
            option['key']?.toString() ?? String.fromCharCode(65 + index);
        final optionText = option['text']?.toString() ?? '';
        final isSelected = selectedAnswer == optionKey;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildOptionItem(
            optionText,
            optionKey,
            isSelected,
            label: optionKey,
          ),
        );
      }),
    );
  }

  Widget _buildTrueFalseOptions() {
    final selectedAnswer = _answers[_currentQuestion.id];

    return Column(
      children: [
        _buildOptionItem(
          'Benar',
          'Benar',
          selectedAnswer == 'Benar',
          icon: Iconsax.tick_circle,
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildOptionItem(
          'Salah',
          'Salah',
          selectedAnswer == 'Salah',
          icon: Iconsax.close_circle,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildEssayInput() {
    final controller = _essayControllers[_currentQuestion.id];
    final currentAnswer = _answers[_currentQuestion.id] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.edit_2, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Jawaban Uraian',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 8,
            minLines: 5,
            decoration: InputDecoration(
              hintText: 'Tulis jawaban Anda di sini...',
              hintStyle: const TextStyle(color: AppTheme.textLight),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.purple, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (value) {
              setState(() {
                if (value.trim().isNotEmpty) {
                  _answers[_currentQuestion.id] = value.trim();
                } else {
                  _answers.remove(_currentQuestion.id);
                }
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentAnswer.split(' ').where((w) => w.isNotEmpty).length} kata',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight,
                ),
              ),
              if (currentAnswer.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Iconsax.tick_circle, size: 14, color: Colors.purple),
                      SizedBox(width: 4),
                      Text(
                        'Tersimpan',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              children: const [
                Icon(Iconsax.info_circle, size: 18, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jawaban akan diperiksa berdasarkan kata kunci. Pastikan jawaban Anda jelas dan lengkap.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem(
    String text,
    String answerValue,
    bool isSelected, {
    String? label,
    IconData? icon,
    Color? color,
  }) {
    final effectiveColor = color ?? _typeColor;

    return InkWell(
      onTap: () => _selectAnswer(answerValue),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? effectiveColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? effectiveColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (label != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? effectiveColor : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ] else if (icon != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? effectiveColor : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected ? Colors.white : effectiveColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: isSelected ? effectiveColor : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(Iconsax.tick_circle, color: effectiveColor, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    _answers.containsKey(_currentQuestion.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Question navigator dots
            _buildQuestionNavigator(),
            const SizedBox(height: 12),
            // Navigation buttons
            Row(
              children: [
                // Previous button
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previousQuestion,
                      icon: const Icon(Iconsax.arrow_left_2),
                      label: const Text('Sebelumnya'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: _typeColor),
                        foregroundColor: _typeColor,
                      ),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),

                // Next/Submit button
                Expanded(
                  flex: _currentIndex > 0 ? 1 : 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : (_currentIndex == widget.questions.length - 1
                            ? _submitQuiz
                            : _nextQuestion),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _currentIndex == widget.questions.length - 1
                                ? Iconsax.tick_square
                                : Iconsax.arrow_right_3,
                          ),
                    label: Text(
                      _isSubmitting
                          ? 'Memproses...'
                          : (_currentIndex == widget.questions.length - 1
                              ? 'Selesai'
                              : 'Selanjutnya'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _typeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionNavigator() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(widget.questions.length, (index) {
          final question = widget.questions[index];
          final isAnswered = _answers.containsKey(question.id);
          final isCurrent = index == _currentIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = index;
              });
            },
            child: Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isCurrent
                    ? _typeColor
                    : isAnswered
                        ? _typeColor.withOpacity(0.2)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: isCurrent
                    ? null
                    : Border.all(
                        color: isAnswered ? _typeColor : Colors.grey.shade300,
                      ),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isCurrent
                        ? Colors.white
                        : isAnswered
                            ? _typeColor
                            : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _selectAnswer(String answer) {
    setState(() {
      _answers[_currentQuestion.id] = answer;
    });
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Quiz?'),
        content: const Text(
            'Progress kamu akan hilang jika keluar sekarang. Yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _submitQuiz() async {
    // Cek apakah semua soal sudah dijawab
    if (_answers.length < widget.questions.length) {
      final unanswered = widget.questions.length - _answers.length;
      final shouldSubmit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Soal Belum Lengkap'),
          content: Text(
              'Masih ada $unanswered soal yang belum dijawab. Yakin ingin submit?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Kembali'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      if (shouldSubmit != true) return;
    }

    setState(() => _isSubmitting = true);
    _timer?.cancel();

    final user = AuthService().currentUser;

    // Hitung skor
    int correctAnswers = 0;
    int totalPoints = 0;
    int earnedPoints = 0;
    Map<String, int> timeSpentPerQuestion = {};

    for (int i = 0; i < widget.questions.length; i++) {
      final question = widget.questions[i];
      totalPoints += question.points;
      final userAnswer = _answers[question.id];

      // Approximate time spent per question
      final avgTimePerQuestion = _timeSpent ~/ widget.questions.length;
      timeSpentPerQuestion[question.id] = avgTimePerQuestion;

      bool isCorrect = false;
      if (userAnswer != null) {
        isCorrect = question.isCorrectAnswer(userAnswer);
        if (isCorrect) {
          correctAnswers++;
          earnedPoints += question.points;
        }
      }

      // Save jawaban ke database
      if (user != null && userAnswer != null) {
        try {
          await SupabaseService.saveUserAnswer(
            questionId: question.id,
            selectedAnswer: userAnswer,
            isCorrect: isCorrect,
            moduleId: question.moduleId,
            attemptNumber: widget.attemptNumber,
            timeSpentSeconds: avgTimePerQuestion,
          );
        } catch (e) {
          debugPrint('Error saving answer: $e');
        }
      }
    }

    final score =
        totalPoints > 0 ? ((earnedPoints / totalPoints) * 100).round() : 0;

    ActivityLogService().logButtonClick(
        buttonId: 'quiz_completed_${widget.quiz.id}',
        screenName: 'quiz_play_screen');

    // Navigate to result
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.quizResult,
      arguments: {
        'quiz': widget.quiz,
        'score': score,
        'totalQuestions': widget.questions.length,
        'correctAnswers': correctAnswers,
        'timeSpent': _timeSpent,
        'answers': _answers,
        'questions': widget.questions,
        'attemptNumber': widget.attemptNumber,
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
