import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/report_entity.dart';
import '../bloc/report_bloc.dart';

class CreateReportPage extends StatefulWidget {
  const CreateReportPage({super.key});

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _latCtrl = TextEditingController(text: '39.9069');
  final _lngCtrl = TextEditingController(text: '41.2779');
  ReportType _type = ReportType.security;
  final List<XFile> _images = [];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _addrCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Bildirim')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Başlık'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Başlık gerekli' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Açıklama gerekli' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ReportType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Tür'),
                  items: ReportType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(_typeLabel(t)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Adres/Konum açıklaması',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Enlem (lat)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lngCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Boylam (lng)',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Haritadan seç',
                      onPressed: _openMapPicker,
                      icon: const Icon(Icons.map_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _photoPicker(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _submit(context),
                    child: const Text('Gönder'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final lat = double.tryParse(_latCtrl.text) ?? 39.9069;
    final lng = double.tryParse(_lngCtrl.text) ?? 41.2779;
    final now = DateTime.now();
    final report = ReportEntity(
      id: 'temp',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      type: _type,
      status: ReportStatus.open,
      location: LatLng(lat, lng),
      createdAt: now,
      address: _addrCtrl.text.trim(),
      creatorUid: '',
      photoUrls: const [],
    );
    context.read<ReportBloc>().add(
      ReportCreateRequested(
        report,
        imagePaths: _images.map((e) => e.path).toList(),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _openMapPicker() async {
    final currentLat = double.tryParse(_latCtrl.text) ?? 39.9069;
    final currentLng = double.tryParse(_lngCtrl.text) ?? 41.2779;
    LatLng temp = LatLng(currentLat, currentLng);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Konum Seç',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: temp,
                            initialZoom: 15,
                            onTap: (_, point) {
                              setModalState(() => temp = point);
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.example.mobile_project',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: temp,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 36,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Lat: ${temp.latitude.toStringAsFixed(5)}  Lng: ${temp.longitude.toStringAsFixed(5)}',
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            _latCtrl.text = temp.latitude.toStringAsFixed(6);
                            _lngCtrl.text = temp.longitude.toStringAsFixed(6);
                            Navigator.pop(context);
                          },
                          child: const Text('Konumu Kullan'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _photoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Fotoğraflar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library_outlined),
              tooltip: 'Fotoğraf ekle',
            ),
            IconButton(
              onPressed: _pickCamera,
              icon: const Icon(Icons.camera_alt_outlined),
              tooltip: 'Kamera',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_images.isEmpty)
          const Text(
            'Fotoğraf eklenmedi',
            style: TextStyle(color: Colors.black54),
          )
        else
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (context, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final img = _images[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(img.path),
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () {
                          setState(() => _images.removeAt(index));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() => _images.addAll(picked));
    }
  }

  Future<void> _pickCamera() async {
    final picker = ImagePicker();
    final shot = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (shot != null) {
      setState(() => _images.add(shot));
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
