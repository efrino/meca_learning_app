// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../config/theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/widgets/common_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
    _loadAnalytics();
  }

  void _checkAdmin() {
    if (!AuthService().isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Akses ditolak. Hanya admin yang dapat mengakses halaman ini.')),
        );
      });
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await SupabaseService.getAnalytics();
      setState(() {
        _analytics = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
              icon: const Icon(Iconsax.refresh), onPressed: _loadAnalytics),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Memuat data...')
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnalyticsCards(),
                    const SizedBox(height: 24),
                    _buildManagementSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAnalyticsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ringkasan Hari Ini',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            StatsCard(
              icon: Iconsax.people,
              value: '${_analytics['total_users'] ?? 0}',
              label: 'Total User',
              color: AppTheme.primaryColor,
            ),
            StatsCard(
              icon: Iconsax.user_tick,
              value: '${_analytics['active_users_today'] ?? 0}',
              label: 'Aktif Hari Ini',
              color: AppTheme.successColor,
            ),
            StatsCard(
              icon: Iconsax.book,
              value: '${_analytics['total_modules'] ?? 0}',
              label: 'Total Modul',
              color: AppTheme.moduleColor,
            ),
            StatsCard(
              icon: Iconsax.activity,
              value: '${_analytics['today_activities'] ?? 0}',
              label: 'Aktivitas Hari Ini',
              color: AppTheme.animationColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Manajemen', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildManagementCard(
          icon: Iconsax.people,
          title: 'Kelola User',
          subtitle: 'Tambah, edit, atau hapus user',
          color: AppTheme.primaryColor,
          onTap: () => _showManageUsers(),
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          icon: Iconsax.book,
          title: 'Kelola Modul',
          subtitle: 'Tambah modul pembelajaran baru',
          color: AppTheme.moduleColor,
          onTap: () => _showManageModules(),
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          icon: Iconsax.play_circle,
          title: 'Kelola Animasi',
          subtitle: 'Tambah video animasi baru',
          color: AppTheme.animationColor,
          onTap: () => _showManageAnimations(),
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          icon: Iconsax.task_square,
          title: 'Kelola Meca Aid',
          subtitle: 'Tambah materi dan soal quiz',
          color: AppTheme.mecaAidColor,
          onTap: () => _showManageMecaAid(),
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          icon: Iconsax.warning_2,
          title: 'Kelola Error Code',
          subtitle: 'Tambah atau edit kode error',
          color: AppTheme.errorCodeColor,
          onTap: () => _showManageErrorCodes(),
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          icon: Iconsax.chart,
          title: 'Laporan Aktivitas',
          subtitle: 'Lihat detail aktivitas semua user',
          color: AppTheme.accentColor,
          onTap: () => _showActivityReport(),
        ),
      ],
    );
  }

  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppTheme.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showManageUsers() {
    _showManagementDialog('Kelola User', _buildUserManagement());
  }

  void _showManageModules() {
    _showManagementDialog('Kelola Modul', _buildContentManagement('module'));
  }

  void _showManageAnimations() {
    _showManagementDialog(
        'Kelola Animasi', _buildContentManagement('animation'));
  }

  void _showManageMecaAid() {
    _showManagementDialog(
        'Kelola Meca Aid', _buildContentManagement('meca_aid'));
  }

  void _showManageErrorCodes() {
    _showManagementDialog('Kelola Error Code', _buildErrorCodeManagement());
  }

  void _showActivityReport() {
    _showManagementDialog('Laporan Aktivitas', _buildActivityReport());
  }

  void _showManagementDialog(String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserManagement() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        final users = snapshot.data ?? [];

        return Column(
          children: [
            // Add user button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(),
                icon: const Icon(Iconsax.user_add),
                label: const Text('Tambah User Baru'),
              ),
            ),
            const SizedBox(height: 16),

            // User list
            ...users
                .map((user) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                (user['full_name'] as String? ?? 'U')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['full_name'] ?? '-',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text('NRP: ${user['nrp'] ?? '-'}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary)),
                                if (user['department'] != null)
                                  Text(user['department'],
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: user['role'] == 'admin'
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user['role'] == 'admin' ? 'Admin' : 'User',
                              style: TextStyle(
                                fontSize: 12,
                                color: user['role'] == 'admin'
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        );
      },
    );
  }

  Widget _buildContentManagement(String category) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.getModules(category: category, activeOnly: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        final modules = snapshot.data ?? [];
        final categoryLabel = category == 'module'
            ? 'Modul'
            : category == 'animation'
                ? 'Animasi'
                : 'Meca Aid';

        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddModuleDialog(category),
                icon: const Icon(Iconsax.add),
                label: Text('Tambah $categoryLabel Baru'),
              ),
            ),
            const SizedBox(height: 16),
            if (modules.isEmpty)
              const EmptyStateWidget(
                  icon: Iconsax.book,
                  title: 'Belum ada konten',
                  subtitle: 'Tambahkan konten baru')
            else
              ...modules
                  .map((module) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(module['title'] ?? '-',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                          module['is_active'] == true
                                              ? Iconsax.tick_circle
                                              : Iconsax.close_circle,
                                          size: 14,
                                          color: module['is_active'] == true
                                              ? AppTheme.successColor
                                              : AppTheme.errorColor),
                                      const SizedBox(width: 4),
                                      Text(
                                          module['is_active'] == true
                                              ? 'Aktif'
                                              : 'Nonaktif',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: module['is_active'] == true
                                                  ? AppTheme.successColor
                                                  : AppTheme.errorColor)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Iconsax.edit, size: 20),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ))
                  .toList(),
          ],
        );
      },
    );
  }

  Widget _buildErrorCodeManagement() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.getErrorCodes(activeOnly: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        final errorCodes = snapshot.data ?? [];

        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddErrorCodeDialog(),
                icon: const Icon(Iconsax.add),
                label: const Text('Tambah Error Code Baru'),
              ),
            ),
            const SizedBox(height: 16),
            ...errorCodes
                .map((code) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.getSeverityColor(
                                      code['severity'] ?? 'medium')
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              code['code'] ?? '-',
                              style: TextStyle(
                                color: AppTheme.getSeverityColor(
                                    code['severity'] ?? 'medium'),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(code['title'] ?? '-',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ),
                          IconButton(
                            icon: const Icon(Iconsax.edit, size: 20),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        );
      },
    );
  }

  Widget _buildActivityReport() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.getActivityLogs(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return const EmptyStateWidget(
              icon: Iconsax.activity, title: 'Belum ada aktivitas');
        }

        return Column(
          children: activities
              .map((activity) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(activity['activity_type'] ?? '-',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                                activity['started_at']
                                        ?.toString()
                                        .substring(0, 16) ??
                                    '-',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                        if (activity['resource_title'] != null) ...[
                          const SizedBox(height: 4),
                          Text(activity['resource_title'],
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.textSecondary)),
                        ],
                      ],
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  void _showAddUserDialog() {
    final nrpController = TextEditingController();
    final nameController = TextEditingController();
    final deptController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah User Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nrpController,
                decoration: const InputDecoration(labelText: 'NRP')),
            const SizedBox(height: 12),
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap')),
            const SizedBox(height: 12),
            TextField(
                controller: deptController,
                decoration: const InputDecoration(labelText: 'Departemen')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.createUser({
                'nrp': nrpController.text.toUpperCase(),
                'full_name': nameController.text,
                'department': deptController.text,
                'password': 'asto2025',
              });
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User berhasil ditambahkan')));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddModuleDialog(String category) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final gdriveIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Tambah ${category == 'module' ? 'Modul' : category == 'animation' ? 'Animasi' : 'Meca Aid'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Judul')),
              const SizedBox(height: 12),
              TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 3),
              const SizedBox(height: 12),
              TextField(
                  controller: gdriveIdController,
                  decoration:
                      const InputDecoration(labelText: 'Google Drive File ID')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.createModule({
                'title': titleController.text,
                'description': descController.text,
                'category': category,
                'gdrive_file_id': gdriveIdController.text,
                'file_type': category == 'animation' ? 'mp4' : 'pdf',
                'created_by': AuthService().currentUser?.id,
              });
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Konten berhasil ditambahkan')));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddErrorCodeDialog() {
    final codeController = TextEditingController();
    final titleController = TextEditingController();
    final causeController = TextEditingController();
    final solutionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Error Code'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Kode Error')),
              const SizedBox(height: 12),
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Judul')),
              const SizedBox(height: 12),
              TextField(
                  controller: causeController,
                  decoration: const InputDecoration(labelText: 'Penyebab'),
                  maxLines: 3),
              const SizedBox(height: 12),
              TextField(
                  controller: solutionController,
                  decoration: const InputDecoration(labelText: 'Solusi'),
                  maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.createErrorCode({
                'code': codeController.text.toUpperCase(),
                'title': titleController.text,
                'cause': causeController.text,
                'solution': solutionController.text,
                'created_by': AuthService().currentUser?.id,
              });
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Error code berhasil ditambahkan')));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
