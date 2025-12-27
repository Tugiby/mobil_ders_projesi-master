import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/report_entity.dart';
import '../bloc/report_bloc.dart';

class ReportDetailPage extends StatefulWidget {
  const ReportDetailPage({
    super.key,
    required this.report,
    required this.isAdmin,
    this.isOwner = false,
  });

  final ReportEntity report;
  final bool isAdmin;
  final bool isOwner; // Kullanıcı raporu oluşturmuş (düzenleme/silme için)

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  late TextEditingController _descriptionCtrl;
  bool _isEditingDescription = false;

  @override
  void initState() {
    super.initState();
    _descriptionCtrl = TextEditingController(text: widget.report.description);
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.report.title),
        actions: [
          // Admin menüsü: durum + acil uyarı + açıklama + silme
          if (widget.isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) => _handleAdminAction(context, value),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'edit_description',
                  child: Text('Açıklamayı Düzenle'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Sil', style: TextStyle(color: Colors.red)),
                ),
                const PopupMenuItem(
                  value: 'emergency',
                  child: Text('Acil Durum Uyarısı'),
                ),
              ],
            )
          // Sahibi menüsü: açıklama + silme (durum yok)
          else if (widget.isOwner)
            PopupMenuButton<String>(
              onSelected: (value) => _handleOwnerAction(context, value),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'edit_description',
                  child: Text('Açıklamayı Düzenle'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Sil', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBadgeRow(widget.report),
            const SizedBox(height: 16),
            if (widget.isAdmin) ...[
              _buildAdminStatusChanger(context),
              const SizedBox(height: 16),
            ],
            if (_isEditingDescription)
              _buildDescriptionEditor(context)
            else
              Text(
                widget.report.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text('Konum: ${widget.report.address}')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Oluşturulma: ${df.format(widget.report.createdAt)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.report.photoUrls.isNotEmpty) ...[
              const Text(
                'Fotoğraflar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.report.photoUrls.length,
                  separatorBuilder: (context, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final url = widget.report.photoUrls[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        width: 160,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 160,
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeRow(ReportEntity report) {
    return Row(
      children: [
        _buildStatusChip(report.status),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _typeLabel(report.type),
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(ReportStatus status) {
    final color = switch (status) {
      ReportStatus.open => Colors.redAccent,
      ReportStatus.reviewing => Colors.orange,
      ReportStatus.resolved => Colors.green,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAdminStatusChanger(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Durum Yönetimi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final status in ReportStatus.values)
              FilterChip(
                label: Text(_statusLabel(status)),
                selected: widget.report.status == status,
                onSelected: (_) {
                  context.read<ReportBloc>().add(
                    ReportStatusUpdated(widget.report.id, status),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionEditor(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _descriptionCtrl,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Açıklamayı düzenle...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditingDescription = false;
                  _descriptionCtrl.text = widget.report.description;
                });
              },
              child: const Text('İptal'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                context.read<ReportBloc>().add(
                  ReportDescriptionUpdated(
                    widget.report.id,
                    _descriptionCtrl.text,
                  ),
                );
                setState(() => _isEditingDescription = false);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ],
    );
  }

  void _handleAdminAction(BuildContext context, String action) {
    switch (action) {
      case 'edit_description':
        setState(() => _isEditingDescription = true);
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
      case 'emergency':
        _showEmergencyAlertDialog(context);
        break;
    }
  }

  void _handleOwnerAction(BuildContext context, String action) {
    switch (action) {
      case 'edit_description':
        setState(() => _isEditingDescription = true);
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bildirimi Sil'),
        content: const Text('Bu bildirimi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              context.read<ReportBloc>().add(ReportDeleted(widget.report.id));
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEmergencyAlertDialog(BuildContext context) {
    final messageCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Acil Durum Uyarısı'),
        content: TextField(
          controller: messageCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Uyarı mesajını yazın...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final msg = messageCtrl.text.trim();
              if (msg.isEmpty) return;
              try {
                final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
                await FirebaseFirestore.instance.collection('alerts').add({
                  'message': msg,
                  'reportId': widget.report.id,
                  'createdAt': FieldValue.serverTimestamp(),
                  'authorUid': uid,
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Acil durum uyarısı yayınlandı'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Uyarı gönderilemedi: $e')),
                  );
                }
              } finally {
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Gönder', style: TextStyle(color: Colors.white)),
          ),
        ],
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
}
