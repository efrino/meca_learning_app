// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../shared/models/module_model.dart';
import '../../../shared/models/question_model.dart';

class QuizScreen extends StatefulWidget {
  final ModuleModel module;
  const QuizScreen({super.key, required this.module});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _activityLogService = ActivityLogService();
  
  List<QuestionModel> _questions = [];
  int _currentIndex = 0;
  Map<String, String> _answers = {};
  Map<String, int> _timeSpent = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showResult = false;
  
  DateTime? _questionStartTime;
  int _correctCount = 0;
  int _totalTimeSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final data = await SupabaseService.getQuestionsByModuleId(widget.module.id);
      setState(() {
        _questions = data.map((e) => QuestionModel.fromJson(e)).toList();
        _isLoading = false;
        _questionStartTime = DateTime.now();
      });
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat soal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_showResult) return true;
        return await _showExitConfirmation();
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(_showResult ? 'Hasil Quiz' : 'Quiz: ${widget.module.title}', style: const TextStyle(fontSize: 16)),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (_showResult || await _showExitConfirmation()) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _showResult
                ? _buildResultView()
                : _buildQuizView(),
      ),
    );
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Quiz?'),
        content: const Text('Progress Anda akan hilang. Apakah Anda yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildQuizView() {
    if (_questions.isEmpty) {
      return const Center(child: Text('Tidak ada soal tersedia'));
    }

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(value: progress, backgroundColor: AppTheme.primaryColor.withOpacity(0.1), valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor), minHeight: 4),
        
        // Question number
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Soal ${_currentIndex + 1} dari ${_questions.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.mecaAidColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('${question.points} poin', style: const TextStyle(color: AppTheme.mecaAidColor, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ),
        ),

        // Question content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.cardShadow),
                  child: Text(question.questionText, style: const TextStyle(fontSize: 16, height: 1.5)),
                ),
                const SizedBox(height: 24),

                // Options
                if (question.options != null)
                  ...question.options!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final optionLetter = String.fromCharCode(65 + index);
                    final isSelected = _answers[question.id] == option;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _answers[question.id] = option),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor, width: isSelected ? 2 : 1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.primaryColor : AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(optionLetter, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.textSecondary)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(option, style: TextStyle(color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary))),
                                if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primaryColor),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),

        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
          child: SafeArea(
            child: Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _goToPrevious(),
                      child: const Text('Sebelumnya'),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: _currentIndex > 0 ? 1 : 2,
                  child: ElevatedButton(
                    onPressed: _answers.containsKey(question.id)
                        ? (_currentIndex < _questions.length - 1 ? _goToNext : _submitQuiz)
                        : null,
                    child: Text(_currentIndex < _questions.length - 1 ? 'Selanjutnya' : 'Selesai'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _recordTimeSpent();
      setState(() {
        _currentIndex--;
        _questionStartTime = DateTime.now();
      });
    }
  }

  void _goToNext() {
    if (_currentIndex < _questions.length - 1) {
      _recordTimeSpent();
      setState(() {
        _currentIndex++;
        _questionStartTime = DateTime.now();
      });
    }
  }

  void _recordTimeSpent() {
    if (_questionStartTime != null) {
      final question = _questions[_currentIndex];
      final elapsed = DateTime.now().difference(_questionStartTime!).inSeconds;
      _timeSpent[question.id] = (_timeSpent[question.id] ?? 0) + elapsed;
    }
  }

  Future<void> _submitQuiz() async {
    _recordTimeSpent();
    setState(() { _isSubmitting = true; });

    final user = AuthService().currentUser;
    if (user == null) return;

    // Calculate results
    _correctCount = 0;
    _totalTimeSeconds = 0;

    for (final question in _questions) {
      final userAnswer = _answers[question.id];
      final isCorrect = userAnswer == question.correctAnswer;
      if (isCorrect) _correctCount++;
      
      final timeSpent = _timeSpent[question.id] ?? 0;
      _totalTimeSeconds += timeSpent;

      // Submit answer to database
      await SupabaseService.submitAnswer({
        'user_id': user.id,
        'question_id': question.id,
        'module_id': widget.module.id,
        'selected_answer': userAnswer,
        'is_correct': isCorrect,
        'time_spent_seconds': timeSpent,
      });

      // Log each answer
      await _activityLogService.logAnswerSubmission(
        questionId: question.id,
        moduleId: widget.module.id,
        isCorrect: isCorrect,
        timeSpentSeconds: timeSpent,
      );
    }

    // Log quiz completion
    await _activityLogService.logQuizComplete(
      moduleId: widget.module.id,
      moduleTitle: widget.module.title,
      score: _correctCount,
      totalQuestions: _questions.length,
      totalTimeSeconds: _totalTimeSeconds,
    );

    // Update user progress
    await SupabaseService.upsertUserProgress({
      'user_id': user.id,
      'module_id': widget.module.id,
      'quiz_best_score': _correctCount,
      'quiz_attempts': 1, // Will be incremented by trigger
      'quiz_last_attempt_at': DateTime.now().toIso8601String(),
      'last_accessed_at': DateTime.now().toIso8601String(),
    });

    setState(() {
      _isSubmitting = false;
      _showResult = true;
    });
  }

  Widget _buildResultView() {
    final score = (_correctCount / _questions.length * 100).round();
    final isPassed = score >= 70;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Result icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (isPassed ? AppTheme.successColor : AppTheme.errorColor).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPassed ? Iconsax.tick_circle : Iconsax.close_circle,
              size: 80,
              color: isPassed ? AppTheme.successColor : AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 24),

          // Result message
          Text(
            isPassed ? 'Selamat!' : 'Tetap Semangat!',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isPassed ? 'Anda lulus quiz ini' : 'Coba lagi untuk hasil lebih baik',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),

          // Score card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.cardShadow),
            child: Column(
              children: [
                Text('$score%', style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: isPassed ? AppTheme.successColor : AppTheme.errorColor)),
                const SizedBox(height: 8),
                Text('Skor Anda', style: TextStyle(color: AppTheme.textSecondary)),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(Iconsax.tick_circle, '$_correctCount', 'Benar', AppTheme.successColor),
                    _buildStatItem(Iconsax.close_circle, '${_questions.length - _correctCount}', 'Salah', AppTheme.errorColor),
                    _buildStatItem(Iconsax.clock, _formatTime(_totalTimeSeconds), 'Waktu', AppTheme.primaryColor),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Answer review
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ringkasan Jawaban', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                ..._questions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final question = entry.value;
                  final userAnswer = _answers[question.id];
                  final isCorrect = userAnswer == question.correctAnswer;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: (isCorrect ? AppTheme.successColor : AppTheme.errorColor).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Icon(isCorrect ? Icons.check : Icons.close, size: 18, color: isCorrect ? AppTheme.successColor : AppTheme.errorColor)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Soal ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w500))),
                        Text(isCorrect ? 'Benar' : 'Salah', style: TextStyle(color: isCorrect ? AppTheme.successColor : AppTheme.errorColor, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                      _answers = {};
                      _timeSpent = {};
                      _showResult = false;
                      _questionStartTime = DateTime.now();
                    });
                  },
                  child: const Text('Ulangi Quiz'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }
}