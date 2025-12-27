import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../pages/login_page.dart';
import '../pages/user_management_page.dart';
import '../../../reports/presentation/bloc/report_bloc.dart';
import '../../../reports/domain/entities/report_entity.dart';
import '../../../reports/presentation/pages/report_detail_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil'), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bilgiler Bölümü
                  _buildSectionTitle('Bilgiler'),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.business_outlined,
                    label: 'Birim',
                    value: user.unit,
                    color: Colors.tealAccent,
                  ),
                  const SizedBox(height: 28),

                  // İlanlarım Bölümü
                  _buildSectionTitle('İlanlarım'),
                  const SizedBox(height: 12),
                  BlocBuilder<ReportBloc, ReportState>(
                    builder: (context, state) {
                      final mine = state.reports
                          .where((r) => r.creatorUid == user.id)
                          .toList();
                      if (mine.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: const Text(
                            'Henüz ilanınız yok.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        );
                      }
                      return Column(
                        children: mine
                            .map(
                              (r) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildReportCard(context, r),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Ayarlar Bölümü
                  _buildSectionTitle('Ayarlar'),
                  const SizedBox(height: 12),
                  if (user.role == UserRole.admin) ...[
                    _buildSettingCard(
                      icon: Icons.people_alt_outlined,
                      title: 'Kullanıcı Yönetimi',
                      subtitle: 'Kullanıcıları yönet ve admin rolü ata',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserManagementPage(
                              repository: context.read<AuthRepository>(),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  _buildSettingCard(
                    icon: Icons.lock_outlined,
                    title: 'Şifre Değiştir',
                    subtitle: 'Hesap şifrenizi güncelle',
                    color: Colors.orangeAccent,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Şifre değiştirme özelliği yakında geliyor',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildSettingCard(
                    icon: Icons.notifications_outlined,
                    title: 'Bildirimler',
                    subtitle: 'Bildirim tercihlerini yönet',
                    color: Colors.greenAccent,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bildirim ayarları yakında geliyor'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildSettingCard(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Gizlilik',
                    subtitle: 'Gizlilik politikasını görüntüle',
                    color: Colors.purpleAccent,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gizlilik sayfası yakında geliyor'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Çıkış Butonu
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Çıkış Yap'),
                            content: const Text(
                              'Oturumunuzu kapatmak istediğinizden emin misiniz?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('İptal'),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.read<AuthBloc>().add(
                                    AuthLogoutRequested(),
                                  );
                                  Navigator.pop(context);
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginPage(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                child: const Text('Evet, Çıkış Yap'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Çıkış Yap'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
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
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
  }

  String _statusLabel(ReportStatus status) {
    switch (status) {
      case ReportStatus.open:
        return 'Açık';
      case ReportStatus.reviewing:
        return 'İnceleniyor';
      case ReportStatus.resolved:
        return 'Çözüldü';
    }
  }

  String _typeLabel(ReportType type) {
    switch (type) {
      case ReportType.health:
        return 'Sağlık';
      case ReportType.security:
        return 'Güvenlik';
      case ReportType.environment:
        return 'Çevre';
      case ReportType.lostFound:
        return 'Kayıp/Buluntu';
      case ReportType.technical:
        return 'Teknik';
    }
  }

  Widget _buildReportCard(BuildContext context, ReportEntity report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<ReportBloc>(),
                child: ReportDetailPage(
                  report: report,
                  isAdmin: false,
                  isOwner: true, // Sahibi olduğu için düzenleme/silme yapabilir
                ),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _smallChip(_statusLabel(report.status)),
                const SizedBox(width: 8),
                _smallChip(_typeLabel(report.type)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
