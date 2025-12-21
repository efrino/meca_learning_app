import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../config/theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/models/activity_log_model.dart';
import '../../../../shared/widgets/common_widgets.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  List<ActivityLogModel> _activities = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

  final Map<String, String> _filters = {
    'all': 'Semua',
    'view_module': 'Modul',
    'view_animation': 'Animasi',
    'view_meca_aid': 'Meca Aid',
    'view_error_code': 'Error Code',
    'complete_quiz': 'Quiz',
    'login': 'Login',
  };

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', timeago.IdMessages());
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.getActivityLogs(
        userId: user.id,
        activityType: _selectedFilter == 'all' ? null : _selectedFilter,
        limit: 100,
      );
      setState(() {
        _activities = data.map((e) => ActivityLogModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat aktivitas: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Aktivitas Saya'),
        actions: [
          IconButton(
              icon: const Icon(Iconsax.refresh), onPressed: _loadActivities),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final key = _filters.keys.elementAt(index);
          final label = _filters[key]!;
          final isSelected = _selectedFilter == key;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = key;
                });
                _loadActivities();
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color:
                    isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const ShimmerList();
    if (_error != null)
      return ErrorStateWidget(message: _error!, onRetry: _loadActivities);
    if (_activities.isEmpty)
      return const EmptyStateWidget(
          icon: Iconsax.activity,
          title: 'Belum Ada Aktivitas',
          subtitle: 'Aktivitas Anda akan muncul di sini');

    // Group activities by date
    final groupedActivities = <String, List<ActivityLogModel>>{};
    for (final activity in _activities) {
      final dateKey = DateFormat('yyyy-MM-dd').format(activity.startedAt);
      groupedActivities.putIfAbsent(dateKey, () => []).add(activity);
    }

    return RefreshIndicator(
      onRefresh: _loadActivities,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: groupedActivities.length,
        itemBuilder: (context, index) {
          final dateKey = groupedActivities.keys.elementAt(index);
          final activities = groupedActivities[dateKey]!;
          final date = DateTime.parse(dateKey);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _formatDateHeader(date),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      fontSize: 13),
                ),
              ),
              ...activities
                  .map((activity) => _ActivityCard(activity: activity)),
            ],
          );
        },
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final activityDate = DateTime(date.year, date.month, date.day);

    if (activityDate == today) return 'Hari Ini';
    if (activityDate == yesterday) return 'Kemarin';
    return DateFormat('EEEE, d MMMM yyyy', 'id').format(date);
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityLogModel activity;
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getActivityColor(activity.activityType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getActivityIcon(activity.activityType),
                color: _getActivityColor(activity.activityType), size: 20),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.activityTypeLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(activity.startedAt),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textLight),
                    ),
                  ],
                ),
                if (activity.resourceTitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    activity.resourceTitle!,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (activity.durationSeconds != null &&
                    activity.durationSeconds! > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Iconsax.clock,
                          size: 14, color: AppTheme.textLight),
                      const SizedBox(width: 4),
                      Text(activity.durationLabel,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textLight)),
                      if (activity.scrollDepthPercent != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Iconsax.document,
                            size: 14, color: AppTheme.textLight),
                        const SizedBox(width: 4),
                        Text('${activity.scrollDepthPercent}% dibaca',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textLight)),
                      ],
                      if (activity.videoWatchPercent != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Iconsax.video,
                            size: 14, color: AppTheme.textLight),
                        const SizedBox(width: 4),
                        Text('${activity.videoWatchPercent}% ditonton',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textLight)),
                      ],
                      if (activity.quizScore != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Iconsax.medal,
                            size: 14, color: AppTheme.textLight),
                        const SizedBox(width: 4),
                        Text(
                            'Skor: ${activity.quizScore}/${activity.quizTotalQuestions}',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textLight)),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'login':
        return Iconsax.login;
      case 'logout':
        return Iconsax.logout;
      case 'view_module':
        return Iconsax.book;
      case 'view_animation':
        return Iconsax.play_circle;
      case 'view_meca_aid':
        return Iconsax.task_square;
      case 'view_error_code':
        return Iconsax.warning_2;
      case 'complete_quiz':
        return Iconsax.medal;
      case 'search':
        return Iconsax.search_normal;
      default:
        return Iconsax.activity;
    }
  }

  Color _getActivityColor(String activityType) {
    switch (activityType) {
      case 'login':
        return AppTheme.successColor;
      case 'logout':
        return AppTheme.textSecondary;
      case 'view_module':
        return AppTheme.moduleColor;
      case 'view_animation':
        return AppTheme.animationColor;
      case 'view_meca_aid':
        return AppTheme.mecaAidColor;
      case 'view_error_code':
        return AppTheme.errorCodeColor;
      case 'complete_quiz':
        return AppTheme.accentColor;
      case 'search':
        return AppTheme.primaryColor;
      default:
        return AppTheme.primaryColor;
    }
  }
}
