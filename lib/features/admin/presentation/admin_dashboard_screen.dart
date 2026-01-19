// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  bool _isAuthorized = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAdminAccess();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAccess() async {
    final currentUser = AuthService().currentUser;

    // Check if user is logged in and has admin role locally
    if (currentUser == null || !currentUser.isAdmin) {
      _showAccessDenied();
      return;
    }

    // User passed local admin check, authorize access
    setState(() {
      _isAuthorized = true;
    });
    _loadAnalytics();
  }

  void _showAccessDenied() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Iconsax.shield_cross, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Akses ditolak. Hanya admin yang dapat mengakses halaman ini.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    });
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.getAnalytics();
      setState(() {
        _analytics = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Gagal memuat data analytics');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.warning_2, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking authorization
    if (!_isAuthorized) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Memverifikasi akses admin...',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
        ],
        body: _isLoading
            ? const LoadingWidget(message: 'Memuat data...')
            : RefreshIndicator(
                onRefresh: _loadAnalytics,
                color: AppTheme.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: 20),
                      _buildAnalyticsSection(),
                      const SizedBox(height: 24),
                      _buildQuickActionsSection(),
                      const SizedBox(height: 24),
                      _buildManagementSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withBlue(180),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                right: 30,
                bottom: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.refresh, color: Colors.white),
          onPressed: _loadAnalytics,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    final user = AuthService().currentUser;
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Selamat Pagi';
      greetingIcon = Iconsax.sun_1;
    } else if (hour < 17) {
      greeting = 'Selamat Siang';
      greetingIcon = Iconsax.sun;
    } else {
      greeting = 'Selamat Malam';
      greetingIcon = Iconsax.moon;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withBlue(200),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(greetingIcon, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  user?.fullName ?? 'Admin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.shield_tick, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Administrator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Iconsax.user_octagon,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Iconsax.chart_21,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Ringkasan Hari Ini',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            _buildAnalyticsCard(
              icon: Iconsax.people,
              value: '${_analytics['total_users'] ?? 0}',
              label: 'Total User',
              color: AppTheme.primaryColor,
              trend: '+${_analytics['new_users_today'] ?? 0} hari ini',
            ),
            _buildAnalyticsCard(
              icon: Iconsax.user_tick,
              value: '${_analytics['active_users_today'] ?? 0}',
              label: 'User Aktif',
              color: AppTheme.successColor,
              trend: 'Online sekarang',
            ),
            _buildAnalyticsCard(
              icon: Iconsax.book,
              value: '${_analytics['total_modules'] ?? 0}',
              label: 'Total Modul',
              color: AppTheme.moduleColor,
              trend: 'Konten pembelajaran',
            ),
            _buildAnalyticsCard(
              icon: Iconsax.activity,
              value: '${_analytics['today_activities'] ?? 0}',
              label: 'Aktivitas',
              color: AppTheme.animationColor,
              trend: 'Hari ini',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    String? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (trend != null)
            Text(
              trend,
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Iconsax.flash_1,
                color: AppTheme.accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Aksi Cepat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickActionChip(
                icon: Iconsax.user_add,
                label: 'Tambah User',
                color: AppTheme.primaryColor,
                onTap: () => _showAddUserDialog(),
              ),
              const SizedBox(width: 12),
              _buildQuickActionChip(
                icon: Iconsax.book_1,
                label: 'Tambah Modul',
                color: AppTheme.moduleColor,
                onTap: () => _showAddModuleDialog('module'),
              ),
              const SizedBox(width: 12),
              _buildQuickActionChip(
                icon: Iconsax.folder_add,
                label: 'Tambah Folder',
                color: AppTheme.mecaAidColor,
                onTap: () => _showAddMecaAidFolderDialog(),
              ),
              const SizedBox(width: 12),
              _buildQuickActionChip(
                icon: Iconsax.danger,
                label: 'Error Code',
                color: AppTheme.errorCodeColor,
                onTap: () => _showAddErrorCodeDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.moduleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Iconsax.setting_2,
                color: AppTheme.moduleColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Manajemen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildManagementCard(
          icon: Iconsax.people,
          title: 'Kelola User',
          subtitle: 'Tambah, edit, atau hapus user',
          color: AppTheme.primaryColor,
          count: _analytics['total_users']?.toString(),
          onTap: () => _showManageUsers(),
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          icon: Iconsax.book,
          title: 'Kelola Modul',
          subtitle: 'Tambah modul pembelajaran baru',
          color: AppTheme.moduleColor,
          count: _analytics['total_modules']?.toString(),
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
          icon: Iconsax.folder_2,
          title: 'Kelola Meca Aid Folders',
          subtitle: 'Atur folder untuk materi Meca Aid',
          color: AppTheme.mecaAidColor,
          onTap: () => _showManageMecaAidFolders(),
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          icon: Iconsax.task_square,
          title: 'Kelola Meca Aid',
          subtitle: 'Tambah materi dan soal quiz',
          color: AppTheme.mecaAidColor.withGreen(150),
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
          count: _analytics['today_activities']?.toString(),
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
    String? count,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (count != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      count,
                      style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MANAGEMENT DIALOGS
  // ============================================================

  void _showManageUsers() {
    _showManagementSheet(
      title: 'Kelola User',
      icon: Iconsax.people,
      color: AppTheme.primaryColor,
      content: _buildUserManagement(),
    );
  }

  void _showManageModules() {
    _showManagementSheet(
      title: 'Kelola Modul',
      icon: Iconsax.book,
      color: AppTheme.moduleColor,
      content: _buildContentManagement('module'),
    );
  }

  void _showManageAnimations() {
    _showManagementSheet(
      title: 'Kelola Animasi',
      icon: Iconsax.play_circle,
      color: AppTheme.animationColor,
      content: _buildContentManagement('animation'),
    );
  }

  void _showManageMecaAidFolders() {
    _showManagementSheet(
      title: 'Kelola Meca Aid Folders',
      icon: Iconsax.folder_2,
      color: AppTheme.mecaAidColor,
      content: _buildMecaAidFolderManagement(),
    );
  }

  void _showManageMecaAid() {
    _showManagementSheet(
      title: 'Kelola Meca Aid',
      icon: Iconsax.task_square,
      color: AppTheme.mecaAidColor,
      content: _buildContentManagement('meca_aid'),
    );
  }

  void _showManageErrorCodes() {
    _showManagementSheet(
      title: 'Kelola Error Code',
      icon: Iconsax.warning_2,
      color: AppTheme.errorCodeColor,
      content: _buildErrorCodeManagement(),
    );
  }

  void _showActivityReport() {
    _showManagementSheet(
      title: 'Laporan Aktivitas',
      icon: Iconsax.chart,
      color: AppTheme.accentColor,
      content: _buildActivityReport(),
    );
  }

  void _showManagementSheet({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.dividerColor.withOpacity(0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close, size: 18),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // USER MANAGEMENT
  // ============================================================

  Widget _buildUserManagement() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: LoadingWidget(),
          );
        }

        final users = snapshot.data ?? [];

        return Column(
          children: [
            // Add user button
            _buildAddButton(
              icon: Iconsax.user_add,
              label: 'Tambah User Baru',
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
                _showAddUserDialog();
              },
            ),
            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                _buildMiniStat(
                  label: 'Total',
                  value: users.length.toString(),
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                _buildMiniStat(
                  label: 'Admin',
                  value: users
                      .where((u) => u['role'] == 'admin')
                      .length
                      .toString(),
                  color: AppTheme.accentColor,
                ),
                const SizedBox(width: 12),
                _buildMiniStat(
                  label: 'Aktif',
                  value: users
                      .where((u) => u['is_active'] == true)
                      .length
                      .toString(),
                  color: AppTheme.successColor,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // User list
            if (users.isEmpty)
              const EmptyStateWidget(
                icon: Iconsax.people,
                title: 'Belum ada user',
                subtitle: 'Tambahkan user baru',
              )
            else
              ...users.map((user) => _buildUserCard(user)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isAdmin = user['role'] == 'admin';
    final isActive = user['is_active'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: isAdmin
            ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isAdmin
                      ? [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withBlue(200)
                        ]
                      : [AppTheme.textLight, AppTheme.textSecondary],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  (user['full_name'] as String? ?? 'U')
                      .split(' ')
                      .take(2)
                      .map((e) => e.isNotEmpty ? e[0] : '')
                      .join()
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user['full_name'] ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Nonaktif',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NRP: ${user['nrp'] ?? '-'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (user['department'] != null)
                    Text(
                      user['department'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isAdmin
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isAdmin
                      ? AppTheme.primaryColor.withOpacity(0.3)
                      : AppTheme.dividerColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAdmin ? Iconsax.shield_tick : Iconsax.user,
                    size: 14,
                    color: isAdmin
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isAdmin ? 'Admin' : 'User',
                    style: TextStyle(
                      fontSize: 12,
                      color: isAdmin
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Edit button
            IconButton(
              icon: const Icon(Iconsax.edit_2, size: 18),
              color: AppTheme.textSecondary,
              onPressed: () => _showEditUserDialog(user),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MECA AID FOLDER MANAGEMENT
  // ============================================================

  Widget _buildMecaAidFolderManagement() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.getMecaAidFolders(activeOnly: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: LoadingWidget(),
          );
        }

        final folders = snapshot.data ?? [];

        return Column(
          children: [
            _buildAddButton(
              icon: Iconsax.folder_add,
              label: 'Tambah Folder Baru',
              color: AppTheme.mecaAidColor,
              onTap: () {
                Navigator.pop(context);
                _showAddMecaAidFolderDialog();
              },
            ),
            const SizedBox(height: 20),
            if (folders.isEmpty)
              const EmptyStateWidget(
                icon: Iconsax.folder_2,
                title: 'Belum ada folder',
                subtitle: 'Tambahkan folder Meca Aid baru',
              )
            else
              ...folders.map((folder) => _buildFolderCard(folder)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildFolderCard(Map<String, dynamic> folder) {
    final isActive = folder['is_active'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.mecaAidColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Iconsax.folder_2,
                color: AppTheme.mecaAidColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder['folder_name'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (folder['description'] != null)
                    Text(
                      folder['description'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isActive ? Iconsax.tick_circle : Iconsax.close_circle,
                        size: 14,
                        color: isActive
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Order: ${folder['order_index'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Iconsax.edit_2, size: 18),
              color: AppTheme.textSecondary,
              onPressed: () => _showEditMecaAidFolderDialog(folder),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT MANAGEMENT (MODULE, ANIMATION, MECA AID)
  // ============================================================

  Widget _buildContentManagement(String category) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.getModules(category: category, activeOnly: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: LoadingWidget(),
          );
        }

        final modules = snapshot.data ?? [];
        final categoryLabel = _getCategoryLabel(category);
        final categoryIcon = _getCategoryIcon(category);
        final categoryColor = _getCategoryColor(category);

        return Column(
          children: [
            _buildAddButton(
              icon: Iconsax.add,
              label: 'Tambah $categoryLabel Baru',
              color: categoryColor,
              onTap: () {
                Navigator.pop(context);
                _showAddModuleDialog(category);
              },
            ),
            const SizedBox(height: 20),
            if (modules.isEmpty)
              EmptyStateWidget(
                icon: categoryIcon,
                title: 'Belum ada konten',
                subtitle: 'Tambahkan $categoryLabel baru',
              )
            else
              ...modules
                  .map((module) =>
                      _buildModuleCard(module, categoryColor, categoryIcon))
                  .toList(),
          ],
        );
      },
    );
  }

  Widget _buildModuleCard(
      Map<String, dynamic> module, Color color, IconData icon) {
    final isActive = module['is_active'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module['title'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (module['description'] != null)
                    Text(
                      module['description'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isActive ? Iconsax.tick_circle : Iconsax.close_circle,
                        size: 14,
                        color: isActive
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.textLight.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          module['file_type']?.toString().toUpperCase() ?? '-',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Iconsax.edit_2, size: 18),
              color: AppTheme.textSecondary,
              onPressed: () => _showEditModuleDialog(module),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR CODE MANAGEMENT
  // ============================================================

  Widget _buildErrorCodeManagement() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.getErrorCodes(activeOnly: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: LoadingWidget(),
          );
        }

        final errorCodes = snapshot.data ?? [];

        return Column(
          children: [
            _buildAddButton(
              icon: Iconsax.add,
              label: 'Tambah Error Code Baru',
              color: AppTheme.errorCodeColor,
              onTap: () {
                Navigator.pop(context);
                _showAddErrorCodeDialog();
              },
            ),
            const SizedBox(height: 20),
            if (errorCodes.isEmpty)
              const EmptyStateWidget(
                icon: Iconsax.warning_2,
                title: 'Belum ada error code',
                subtitle: 'Tambahkan error code baru',
              )
            else
              ...errorCodes.map((code) => _buildErrorCodeCard(code)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildErrorCodeCard(Map<String, dynamic> code) {
    final severity = code['severity'] ?? 'medium';
    final severityColor = AppTheme.getSeverityColor(severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: severityColor.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                code['code'] ?? '-',
                style: TextStyle(
                  color: severityColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code['title'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: severityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getSeverityLabel(severity),
                        style: TextStyle(
                          fontSize: 12,
                          color: severityColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Iconsax.edit_2, size: 18),
              color: AppTheme.textSecondary,
              onPressed: () => _showEditErrorCodeDialog(code),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTIVITY REPORT
  // ============================================================

  Widget _buildActivityReport() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.getActivityLogs(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: LoadingWidget(),
          );
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return const EmptyStateWidget(
            icon: Iconsax.activity,
            title: 'Belum ada aktivitas',
            subtitle: 'Aktivitas user akan muncul di sini',
          );
        }

        return Column(
          children: [
            // Summary stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActivityStat(
                    icon: Iconsax.eye,
                    label: 'Total',
                    value: activities.length.toString(),
                  ),
                  _buildActivityStat(
                    icon: Iconsax.login,
                    label: 'Login',
                    value: activities
                        .where((a) => a['activity_type'] == 'login')
                        .length
                        .toString(),
                  ),
                  _buildActivityStat(
                    icon: Iconsax.book,
                    label: 'View',
                    value: activities
                        .where((a) =>
                            a['activity_type']?.toString().startsWith('view') ==
                            true)
                        .length
                        .toString(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Activity list
            ...activities
                .map((activity) => _buildActivityCard(activity))
                .toList(),
          ],
        );
      },
    );
  }

  Widget _buildActivityStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final activityType = activity['activity_type'] ?? '-';
    final icon = _getActivityIcon(activityType);
    final color = _getActivityColor(activityType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getActivityLabel(activityType),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (activity['resource_title'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      activity['resource_title'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Text(
              _formatActivityTime(activity['started_at']),
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ADD DIALOGS
  // ============================================================

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nrpController = TextEditingController();
    final nameController = TextEditingController();
    final deptController = TextEditingController();
    final positionController = TextEditingController();
    String selectedRole = 'user';
    bool isActive = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Iconsax.user_add,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Tambah User Baru'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: nrpController,
                    label: 'NRP',
                    icon: Iconsax.card,
                    validator: (v) =>
                        v?.isEmpty == true ? 'NRP wajib diisi' : null,
                    inputFormatters: [UpperCaseTextFormatter()],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: nameController,
                    label: 'Nama Lengkap',
                    icon: Iconsax.user,
                    validator: (v) =>
                        v?.isEmpty == true ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: deptController,
                    label: 'Departemen',
                    icon: Iconsax.building,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: positionController,
                    label: 'Posisi/Jabatan',
                    icon: Iconsax.briefcase,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Role',
                    icon: Iconsax.shield,
                    value: selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) =>
                        setState(() => selectedRole = v ?? 'user'),
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchField(
                    label: 'Status Aktif',
                    value: isActive,
                    onChanged: (v) => setState(() => isActive = v),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Iconsax.info_circle,
                            color: AppTheme.textSecondary, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Password default: asto2025',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() == true) {
                  try {
                    await SupabaseService.createUser({
                      'nrp': nrpController.text.toUpperCase(),
                      'full_name': nameController.text,
                      'department': deptController.text.isNotEmpty
                          ? deptController.text
                          : null,
                      'position': positionController.text.isNotEmpty
                          ? positionController.text
                          : null,
                      'role': selectedRole,
                      'is_active': isActive,
                      'password': 'asto2025',
                    });
                    Navigator.pop(context);
                    _showSuccessSnackBar('User berhasil ditambahkan');
                    _loadAnalytics();
                  } catch (e) {
                    _showErrorSnackBar('Gagal menambahkan user: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMecaAidFolderDialog() {
    final formKey = GlobalKey<FormState>();
    final folderNameController = TextEditingController();
    final gdriveIdController = TextEditingController();
    final descController = TextEditingController();
    final orderController = TextEditingController(text: '0');
    bool isActive = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.mecaAidColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Iconsax.folder_add,
                  color: AppTheme.mecaAidColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Tambah Folder'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: folderNameController,
                    label: 'Nama Folder',
                    icon: Iconsax.folder,
                    validator: (v) =>
                        v?.isEmpty == true ? 'Nama folder wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: gdriveIdController,
                    label: 'Google Drive Folder ID',
                    icon: Iconsax.document_cloud,
                    validator: (v) =>
                        v?.isEmpty == true ? 'Folder ID wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: descController,
                    label: 'Deskripsi (opsional)',
                    icon: Iconsax.note_text,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: orderController,
                    label: 'Urutan (Order Index)',
                    icon: Iconsax.sort,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchField(
                    label: 'Status Aktif',
                    value: isActive,
                    onChanged: (v) => setState(() => isActive = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() == true) {
                  try {
                    await SupabaseService.createMecaAidFolder({
                      'gdrive_folder_id': gdriveIdController.text,
                      'folder_name': folderNameController.text,
                      'description': descController.text.isNotEmpty
                          ? descController.text
                          : null,
                      'order_index': int.tryParse(orderController.text) ?? 0,
                      'is_active': isActive,
                    });
                    Navigator.pop(context);
                    _showSuccessSnackBar('Folder berhasil ditambahkan');
                    _loadAnalytics();
                  } catch (e) {
                    _showErrorSnackBar('Gagal menambahkan folder: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.mecaAidColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddModuleDialog(String category) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final gdriveIdController = TextEditingController();
    final orderController = TextEditingController(text: '0');
    String selectedFileType = category == 'animation' ? 'mp4' : 'pdf';
    bool isActive = true;

    final categoryLabel = _getCategoryLabel(category);
    final categoryColor = _getCategoryColor(category);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Iconsax.add,
                  color: categoryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text('Tambah $categoryLabel'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: titleController,
                    label: 'Judul',
                    icon: Iconsax.text,
                    validator: (v) =>
                        v?.isEmpty == true ? 'Judul wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: descController,
                    label: 'Deskripsi',
                    icon: Iconsax.note_text,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: gdriveIdController,
                    label: 'Google Drive File ID',
                    icon: Iconsax.document_cloud,
                    validator: (v) =>
                        v?.isEmpty == true ? 'File ID wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Tipe File',
                    icon: Iconsax.document,
                    value: selectedFileType,
                    items: const [
                      DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                      DropdownMenuItem(
                          value: 'mp4', child: Text('Video (MP4)')),
                      DropdownMenuItem(value: 'image', child: Text('Gambar')),
                      DropdownMenuItem(value: 'xlsx', child: Text('Excel')),
                      DropdownMenuItem(
                          value: 'swf', child: Text('Flash (SWF)')),
                    ],
                    onChanged: (v) =>
                        setState(() => selectedFileType = v ?? 'pdf'),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: orderController,
                    label: 'Urutan',
                    icon: Iconsax.sort,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchField(
                    label: 'Status Aktif',
                    value: isActive,
                    onChanged: (v) => setState(() => isActive = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() == true) {
                  try {
                    await SupabaseService.createModule({
                      'title': titleController.text,
                      'description': descController.text.isNotEmpty
                          ? descController.text
                          : null,
                      'category': category,
                      'gdrive_file_id': gdriveIdController.text,
                      'file_type': selectedFileType,
                      'order_index': int.tryParse(orderController.text) ?? 0,
                      'is_active': isActive,
                      'created_by': AuthService().currentUser?.id,
                    });
                    Navigator.pop(context);
                    _showSuccessSnackBar('$categoryLabel berhasil ditambahkan');
                    _loadAnalytics();
                  } catch (e) {
                    _showErrorSnackBar('Gagal menambahkan $categoryLabel: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: categoryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddErrorCodeDialog() {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();
    final titleController = TextEditingController();
    final causeController = TextEditingController();
    final solutionController = TextEditingController();
    final symptomController = TextEditingController();
    final notesController = TextEditingController();
    String selectedSeverity = 'medium';
    bool isActive = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorCodeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Iconsax.warning_2,
                  color: AppTheme.errorCodeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Tambah Error Code'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: codeController,
                    label: 'Kode Error',
                    icon: Iconsax.code,
                    validator: (v) =>
                        v?.isEmpty == true ? 'Kode wajib diisi' : null,
                    inputFormatters: [UpperCaseTextFormatter()],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: titleController,
                    label: 'Judul',
                    icon: Iconsax.text,
                    validator: (v) =>
                        v?.isEmpty == true ? 'Judul wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Tingkat Keparahan',
                    icon: Iconsax.danger,
                    value: selectedSeverity,
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Rendah')),
                      DropdownMenuItem(value: 'medium', child: Text('Sedang')),
                      DropdownMenuItem(value: 'high', child: Text('Tinggi')),
                      DropdownMenuItem(
                          value: 'critical', child: Text('Kritis')),
                    ],
                    onChanged: (v) =>
                        setState(() => selectedSeverity = v ?? 'medium'),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: symptomController,
                    label: 'Gejala (opsional)',
                    icon: Iconsax.health,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: causeController,
                    label: 'Penyebab',
                    icon: Iconsax.message_question,
                    maxLines: 3,
                    validator: (v) =>
                        v?.isEmpty == true ? 'Penyebab wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: solutionController,
                    label: 'Solusi',
                    icon: Iconsax.tick_circle,
                    maxLines: 3,
                    validator: (v) =>
                        v?.isEmpty == true ? 'Solusi wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: notesController,
                    label: 'Catatan (opsional)',
                    icon: Iconsax.note,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchField(
                    label: 'Status Aktif',
                    value: isActive,
                    onChanged: (v) => setState(() => isActive = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() == true) {
                  try {
                    await SupabaseService.createErrorCode({
                      'code': codeController.text.toUpperCase(),
                      'title': titleController.text,
                      'cause': causeController.text,
                      'solution': solutionController.text,
                      'symptom': symptomController.text.isNotEmpty
                          ? symptomController.text
                          : null,
                      'notes': notesController.text.isNotEmpty
                          ? notesController.text
                          : null,
                      'severity': selectedSeverity,
                      'is_active': isActive,
                      'created_by': AuthService().currentUser?.id,
                    });
                    Navigator.pop(context);
                    _showSuccessSnackBar('Error code berhasil ditambahkan');
                    _loadAnalytics();
                  } catch (e) {
                    _showErrorSnackBar('Gagal menambahkan error code: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorCodeColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EDIT DIALOGS (Stubs - implement similar to add dialogs)
  // ============================================================

  void _showEditUserDialog(Map<String, dynamic> user) {
    // Similar to _showAddUserDialog but pre-filled with user data
    _showInfoDialog('Edit User', 'Fitur edit user akan segera tersedia');
  }

  void _showEditMecaAidFolderDialog(Map<String, dynamic> folder) {
    // Similar to _showAddMecaAidFolderDialog but pre-filled
    _showInfoDialog('Edit Folder', 'Fitur edit folder akan segera tersedia');
  }

  void _showEditModuleDialog(Map<String, dynamic> module) {
    _showInfoDialog('Edit Modul', 'Fitur edit modul akan segera tersedia');
  }

  void _showEditErrorCodeDialog(Map<String, dynamic> code) {
    _showInfoDialog(
        'Edit Error Code', 'Fitur edit error code akan segera tersedia');
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPER WIDGETS
  // ============================================================

  Widget _buildAddButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.backgroundColor,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.backgroundColor,
      ),
    );
  }

  Widget _buildSwitchField({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                value ? Iconsax.tick_circle : Iconsax.close_circle,
                color: value ? AppTheme.successColor : AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.successColor,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  String _getCategoryLabel(String category) {
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'module':
        return Iconsax.book;
      case 'animation':
        return Iconsax.play_circle;
      case 'meca_aid':
        return Iconsax.task_square;
      default:
        return Iconsax.document;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'module':
        return AppTheme.moduleColor;
      case 'animation':
        return AppTheme.animationColor;
      case 'meca_aid':
        return AppTheme.mecaAidColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getSeverityLabel(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return 'Rendah';
      case 'medium':
        return 'Sedang';
      case 'high':
        return 'Tinggi';
      case 'critical':
        return 'Kritis';
      default:
        return severity;
    }
  }

  String _getActivityLabel(String type) {
    switch (type) {
      case 'login':
        return 'Login';
      case 'logout':
        return 'Logout';
      case 'view_module':
        return 'Melihat Modul';
      case 'view_animation':
        return 'Melihat Animasi';
      case 'view_meca_aid':
        return 'Melihat Meca Aid';
      case 'start_quiz':
        return 'Memulai Quiz';
      case 'complete_quiz':
        return 'Menyelesaikan Quiz';
      case 'view_error_code':
        return 'Melihat Error Code';
      case 'search':
        return 'Pencarian';
      default:
        return type;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
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
      case 'start_quiz':
      case 'complete_quiz':
        return Iconsax.medal;
      case 'view_error_code':
        return Iconsax.warning_2;
      case 'search':
        return Iconsax.search_normal;
      default:
        return Iconsax.activity;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
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
      case 'start_quiz':
      case 'complete_quiz':
        return AppTheme.accentColor;
      case 'view_error_code':
        return AppTheme.errorCodeColor;
      case 'search':
        return AppTheme.primaryColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatActivityTime(dynamic time) {
    if (time == null) return '-';
    try {
      final dt = DateTime.parse(time.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) {
        return 'Baru saja';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m lalu';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}j lalu';
      } else {
        return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return '-';
    }
  }
}

/// Text formatter to convert input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
