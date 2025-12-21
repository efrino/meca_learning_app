import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../shared/models/user_model.dart';
import '../../modules/presentation/modules_screen.dart';
import '../../animations/presentation/animations_screen.dart';
import '../../meca_aid/presentation/meca_aid_screen.dart';
import '../../error_codes/presentation/error_codes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _activityLogService = ActivityLogService();

  final List<Widget> _screens = [
    const _HomeContent(),
    const ModulesScreen(embedded: true),
    const AnimationsScreen(embedded: true),
    const MecaAidScreen(embedded: true),
    const ErrorCodesScreen(embedded: true),
  ];

  final List<String> _screenNames = [
    'home',
    'modules',
    'animations',
    'meca_aid',
    'error_codes',
  ];

  @override
  void initState() {
    super.initState();
    _activityLogService.setCurrentScreen('home');
  }

  void _onTabChanged(int index) {
    if (_currentIndex != index) {
      final fromScreen = _screenNames[_currentIndex];
      final toScreen = _screenNames[index];

      _activityLogService.logNavigation(fromScreen, toScreen);

      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Iconsax.home, 'Beranda'),
                _buildNavItem(1, Iconsax.book, 'Modul'),
                _buildNavItem(2, Iconsax.play_circle, 'Animasi'),
                _buildNavItem(3, Iconsax.task_square, 'Meca Aid'),
                _buildNavItem(4, Iconsax.warning_2, 'Error'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _onTabChanged(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textLight,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar(context, user)),
            SliverToBoxAdapter(child: _buildWelcomeCard(context, user)),
            SliverToBoxAdapter(child: _buildQuickActions(context)),
            SliverToBoxAdapter(child: _buildRecentSection(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, UserModel? user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showProfileMenu(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  user?.initials ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14),
                ),
                Text(
                  user?.fullName ?? 'User',
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (user?.isAdmin ?? false)
            IconButton(
              icon: const Icon(Iconsax.setting_2),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.adminDashboard),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, UserModel? user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selamat Datang di',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('Meca Learning',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('NRP: ${user?.nrp ?? '-'}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.precision_manufacturing_rounded,
                    color: Colors.white, size: 40),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.activityLog),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.activity, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Lihat Aktivitas Saya',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Menu Utama', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _QuickActionCard(
                  icon: Iconsax.book_1,
                  title: 'Modul',
                  subtitle: 'Materi pembelajaran',
                  color: AppTheme.moduleColor,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.modules)),
              _QuickActionCard(
                  icon: Iconsax.play_circle,
                  title: 'Animasi',
                  subtitle: 'Video pembelajaran',
                  color: AppTheme.animationColor,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.animations)),
              _QuickActionCard(
                  icon: Iconsax.task_square,
                  title: 'Meca Aid',
                  subtitle: 'Latihan soal',
                  color: AppTheme.mecaAidColor,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.mecaAid)),
              _QuickActionCard(
                  icon: Iconsax.warning_2,
                  title: 'Error Code',
                  subtitle: 'Panduan troubleshoot',
                  color: AppTheme.errorCodeColor,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.errorCodes)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tips Penggunaan',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow),
            child: Column(
              children: [
                _buildTipItem(Icons.touch_app_rounded,
                    'Semua aktivitas Anda tercatat secara otomatis'),
                const Divider(height: 24),
                _buildTipItem(Icons.timer_rounded,
                    'Durasi belajar Anda akan dihitung untuk evaluasi'),
                const Divider(height: 24),
                _buildTipItem(Icons.quiz_rounded,
                    'Kerjakan quiz di Meca Aid untuk mengukur pemahaman'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary))),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi,';
    if (hour < 15) return 'Selamat Siang,';
    if (hour < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const _ProfileBottomSheet(),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ProfileBottomSheet extends StatelessWidget {
  const _ProfileBottomSheet();

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20)),
            child: Center(
                child: Text(user?.initials ?? 'U',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold))),
          ),
          const SizedBox(height: 16),
          Text(user?.fullName ?? 'User',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('NRP: ${user?.nrp ?? '-'}',
              style: const TextStyle(color: AppTheme.textSecondary)),
          if (user?.department != null) ...[
            const SizedBox(height: 4),
            Text(user!.department!,
                style: const TextStyle(color: AppTheme.textSecondary))
          ],
          const SizedBox(height: 24),
          _buildMenuItem(context,
              icon: Iconsax.activity, title: 'Aktivitas Saya', onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.activityLog);
          }),
          if (user?.isAdmin ?? false)
            _buildMenuItem(context,
                icon: Iconsax.setting_2, title: 'Admin Panel', onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.adminDashboard);
            }),
          _buildMenuItem(context,
              icon: Iconsax.logout,
              title: 'Keluar',
              isDestructive: true, onTap: () async {
            Navigator.pop(context);
            await AuthService().logout();
            if (context.mounted)
              Navigator.pushReplacementNamed(context, AppRoutes.login);
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon,
          color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimary),
      title: Text(title,
          style: TextStyle(
              color:
                  isDestructive ? AppTheme.errorColor : AppTheme.textPrimary)),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 16, color: AppTheme.textLight),
      onTap: onTap,
    );
  }
}
