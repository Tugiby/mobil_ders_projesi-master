import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:ui';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';
import '../../../reports/domain/entities/report_entity.dart';
import '../../../reports/presentation/bloc/report_bloc.dart';
import '../../../reports/presentation/pages/report_detail_page.dart';
import '../../../reports/presentation/pages/create_report_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user});

  final UserEntity user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchCtrl = TextEditingController();
  ReportEntity? _selected;
  bool _showFilters = false;
  bool _showDetailView = false;
  final Map<String, String> _locationCache = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<String> _getLocationName(LatLng location) async {
    final cacheKey = '${location.latitude},${location.longitude}';
    if (_locationCache.containsKey(cacheKey)) {
      return _locationCache[cacheKey]!;
    }

    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final name =
            place.thoroughfare ??
            place.subLocality ??
            place.locality ??
            'Bilinmeyen Konum';
        _locationCache[cacheKey] = name;
        return name;
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    return 'Kampüs Alanı';
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.initial) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            }
          },
        ),
        BlocListener<ReportBloc, ReportState>(
          listenWhen: (prev, next) => prev.selectedId != next.selectedId,
          listener: (context, state) {
            if (state.selectedId != null) {
              setState(() {
                _showDetailView = true;
              });
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F5F9),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _topBar(context),
                const SizedBox(height: 12),
                Expanded(
                  child: BlocBuilder<ReportBloc, ReportState>(
                    builder: (context, state) {
                      if (state.status == ReportLoadStatus.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state.status == ReportLoadStatus.error) {
                        return Center(
                          child: Text('Hata: ${state.errorMessage}'),
                        );
                      }
                      ReportEntity? selected = _selected;
                      if (state.selectedId != null) {
                        try {
                          selected = state.filtered.firstWhere(
                            (e) => e.id == state.selectedId,
                          );
                        } catch (_) {}
                      }
                      if (selected != null &&
                          !state.filtered.any((e) => e.id == selected!.id)) {
                        selected = null;
                      }
                      _selected = selected;

                      if (_showDetailView && _selected != null) {
                        return _detailView(_selected!);
                      }

                      return Column(
                        children: [
                          _mapSection(state.filtered, selected),
                          const SizedBox(height: 12),
                          _filterToggleButton(),
                          if (_showFilters) ...[
                            const SizedBox(height: 8),
                            _filterRow(context, state),
                          ],
                          const SizedBox(height: 8),
                          _searchField(context),
                          const SizedBox(height: 8),
                          _listSection(context, state.filtered),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        const Text(
          'İhbar Uygulaması',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Profil',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfilePage(user: widget.user)),
            );
          },
          icon: const Icon(Icons.person_outline),
        ),
        IconButton(
          tooltip: 'Yeni Bildirim',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<ReportBloc>(),
                  child: const CreateReportPage(),
                ),
              ),
            );
          },
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _mapSection(List<ReportEntity> reports, ReportEntity? selected) {
    final mapHeight = MediaQuery.of(context).size.height * 0.42;
    final center =
        selected?.location ??
        (reports.isNotEmpty
            ? reports.first.location
            : const LatLng(39.9069, 41.2779));

    return SizedBox(
      height: mapHeight,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15.0,
                onTap: (_, __) => setState(() => _selected = null),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mobile_project',
                ),
                MarkerLayer(
                  markers: reports.map((r) => _markerForReport(r)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Marker _markerForReport(ReportEntity report) {
    final color = _typeColor(report.type);
    return Marker(
      point: report.location,
      width: 80,
      height: 80,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selected = report;
            _showDetailView = true;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, color: color, size: 40),
            const SizedBox(height: 2),
            Container(
              width: 76,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                report.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Not: _pinCard ve _openDetail metodları artık kullanılmadığı için kaldırıldı.

  Widget _filterToggleButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _showFilters = !_showFilters),
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            label: Text(
              _showFilters ? 'Filtreleri Gizle' : 'Filtreleri Göster',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.8),
              foregroundColor: Colors.black87,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterRow(BuildContext context, ReportState state) {
    final isAdmin = widget.user.role == UserRole.admin;
    final chips = ReportType.values
        .map(
          (t) => FilterChip(
            label: Text(_typeLabel(t)),
            selected: state.filterTypes.contains(t),
            onSelected: (v) {
              final next = Set<ReportType>.from(state.filterTypes);
              if (v) {
                next.add(t);
              } else {
                next.remove(t);
              }
              context.read<ReportBloc>().add(ReportTypeFilterChanged(next));
            },
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: chips),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Hepsi'),
              selected: state.scope == ReportFilterScope.all,
              onSelected: (_) => context.read<ReportBloc>().add(
                const ReportScopeChanged(ReportFilterScope.all),
              ),
            ),
            ChoiceChip(
              label: const Text('Açık Olanlar'),
              selected: state.scope == ReportFilterScope.openOnly,
              onSelected: (_) => context.read<ReportBloc>().add(
                const ReportScopeChanged(ReportFilterScope.openOnly),
              ),
            ),
            ChoiceChip(
              label: const Text('Takip Ettiklerim'),
              selected: state.scope == ReportFilterScope.followed,
              onSelected: (_) => context.read<ReportBloc>().add(
                const ReportScopeChanged(ReportFilterScope.followed),
              ),
            ),
            if (isAdmin)
              ChoiceChip(
                label: const Text('Yetki Alanım'),
                selected: state.ownerScope == ReportOwnerScope.adminArea,
                onSelected: (_) => context.read<ReportBloc>().add(
                  const ReportOwnerScopeChanged(ReportOwnerScope.adminArea),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _searchField(BuildContext context) {
    return TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Başlık veya açıklamada ara...',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (val) =>
          context.read<ReportBloc>().add(ReportSearchChanged(val)),
    );
  }

  Widget _listSection(BuildContext context, List<ReportEntity> reports) {
    if (reports.isEmpty) {
      return const Expanded(
        child: Center(child: Text('Kriterlere uygun bildirim yok.')),
      );
    }
    return Expanded(
      child: ListView.separated(
        itemCount: reports.length,
        separatorBuilder: (context, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final r = reports[index];
          return _reportTile(r);
        },
      ),
    );
  }

  Widget _reportTile(ReportEntity report) {
    final df = DateFormat('dd MMM HH:mm');
    return FutureBuilder<String>(
      future: _getLocationName(report.location),
      builder: (context, snapshot) {
        final locationName = snapshot.data ?? 'Kampüs Alanı';
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                color: Colors.white.withValues(alpha: 0.88),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selected = report;
                      _showDetailView = true;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: _typeColor(
                                report.type,
                              ).withValues(alpha: 0.2),
                              radius: 28,
                              child: Icon(
                                _typeIcon(report.type),
                                color: _typeColor(report.type),
                                size: 26,
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
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _typeColor(
                                            report.type,
                                          ).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          _typeLabel(report.type),
                                          style: TextStyle(
                                            color: _typeColor(report.type),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        df.format(report.createdAt),
                                        style: const TextStyle(
                                          color: Colors.black45,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _statusPill(report.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          report.description,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.black45,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  locationName,
                                  style: const TextStyle(
                                    color: Colors.black45,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                report.isFollowed
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: report.isFollowed
                                    ? _typeColor(report.type)
                                    : Colors.black45,
                                size: 20,
                              ),
                              onPressed: () {
                                context.read<ReportBloc>().add(
                                  ReportFollowToggled(report.id),
                                );
                              },
                              constraints: const BoxConstraints(minWidth: 32),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statusPill(ReportStatus status) {
    final color = switch (status) {
      ReportStatus.open => Colors.redAccent,
      ReportStatus.reviewing => Colors.orange,
      ReportStatus.resolved => Colors.green,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _detailView(ReportEntity report) {
    final df = DateFormat('dd MMM yyyy HH:mm');
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: report.location,
                    initialZoom: 16.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mobile_project',
                    ),
                    MarkerLayer(markers: [_markerForReport(report)]),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _showDetailView = false;
                        _selected = null;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SingleChildScrollView(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Card(
                  margin: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                  color: Colors.white.withValues(alpha: 0.92),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _typeColor(
                                report.type,
                              ).withValues(alpha: 0.15),
                              radius: 24,
                              child: Icon(
                                _typeIcon(report.type),
                                color: _typeColor(report.type),
                                size: 28,
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
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _typeLabel(report.type),
                                    style: TextStyle(
                                      color: _typeColor(report.type),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _statusPill(report.status),
                          ],
                        ),
                        const Divider(height: 24),
                        const Text(
                          'Açıklama',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report.description,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        if (report.photoUrls.isNotEmpty) ...[
                          const Text(
                            'Fotoğraflar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: report.photoUrls.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    report.photoUrls[index],
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.error),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              df.format(report.createdAt),
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                report.isFollowed
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: report.isFollowed ? Colors.blue : null,
                              ),
                              onPressed: () {
                                context.read<ReportBloc>().add(
                                  ReportFollowToggled(report.id),
                                );
                              },
                            ),
                            if (widget.user.role == UserRole.admin)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Düzenle'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: context.read<ReportBloc>(),
                                        child: ReportDetailPage(
                                          report: report,
                                          isAdmin: true,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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

  Color _typeColor(ReportType type) {
    switch (type) {
      case ReportType.health:
        return Colors.pinkAccent;
      case ReportType.security:
        return Colors.blueAccent;
      case ReportType.environment:
        return Colors.green;
      case ReportType.lostFound:
        return Colors.teal;
      case ReportType.technical:
        return Colors.deepPurple;
    }
  }

  IconData _typeIcon(ReportType type) {
    switch (type) {
      case ReportType.health:
        return Icons.healing_outlined;
      case ReportType.security:
        return Icons.shield_outlined;
      case ReportType.environment:
        return Icons.public;
      case ReportType.lostFound:
        return Icons.wallet_travel_outlined;
      case ReportType.technical:
        return Icons.build;
    }
  }
}