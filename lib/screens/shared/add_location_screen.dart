import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/activity_item.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/slide_up_sheet.dart';

/// Picks a photo from the camera or the photo library; null if cancelled.
typedef LocationPhotoPicker = Future<File?> Function({required bool camera});

/// Shared / Add Location (Week 7 offline queue): add a campus location with
/// a photo. It is saved on the phone first (`synced = false`) and uploads
/// automatically when the phone is online.
class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  /// Replaced in tests, which have no camera or photo library.
  @visibleForTesting
  static LocationPhotoPicker pickPhoto = _pickWithImagePicker;

  static Future<File?> _pickWithImagePicker({required bool camera}) async {
    final file = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    return file == null ? null : File(file.path);
  }

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _description = TextEditingController();
  final _hours = TextEditingController();
  File? _photo;
  bool _photoMissing = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _description.dispose();
    _hours.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    final camera = await showSlideUpSheet<bool>(
      context,
      children: (sheetContext) => [
        const Text(
          'Add a photo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        // ListTiles need their own Material on the sheet's white panel.
        Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(sheetContext, true),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Library'),
                onTap: () => Navigator.pop(sheetContext, false),
              ),
            ],
          ),
        ),
      ],
    );
    if (camera == null) return;
    try {
      final file = await AddLocationScreen.pickPhoto(camera: camera);
      if (file == null || !mounted) return;
      setState(() {
        _photo = file;
        _photoMissing = false;
      });
    } on Exception catch (e) {
      if (mounted) {
        showAppSnack(context, 'Could not get the photo: $e', error: true);
      }
    }
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _photoMissing = _photo == null);
    if (!valid || _photo == null) return;
    setState(() => _saving = true);
    final services = AppScope.of(context);
    final online = services.sync.online;
    try {
      final location = await services.tour.addLocation(
        title: _title.text,
        subtitle: _subtitle.text,
        description: _description.text,
        hours: _hours.text,
        photo: _photo,
      );
      await services.activity.add(
        ActivityKind.visit,
        'Added ${location.title}',
        online
            ? 'Campus tour location'
            : 'Saved offline · uploads when you are back online',
      );
      if (!mounted) return;
      showAppSnack(
        context,
        online
            ? 'Location saved'
            : 'Location saved offline · uploads when you are back online',
      );
      Navigator.of(context).pop();
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnack(context, 'Could not save the location: $e', error: true);
    }
  }

  String? _required(String? v, String what) =>
      v == null || v.trim().isEmpty ? 'Enter the $what.' : null;

  Widget _label(String text, {bool required = true}) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(required ? '$text *' : text),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Location')),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _label('Photo'),
              _PhotoPicker(
                photo: _photo,
                missing: _photoMissing,
                onTap: _saving ? null : _choosePhoto,
              ),
              _label('Location Name'),
              TextFormField(
                key: const Key('location.title'),
                controller: _title,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'e.g. Chapel'),
                validator: (v) => _required(v, 'location name'),
              ),
              _label('Short Label', required: false),
              TextFormField(
                key: const Key('location.subtitle'),
                controller: _subtitle,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'e.g. Place of worship',
                ),
              ),
              _label('Description'),
              TextFormField(
                key: const Key('location.description'),
                controller: _description,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'What is here and what is it used for?',
                ),
                validator: (v) => _required(v, 'description'),
              ),
              _label('Opening Hours', required: false),
              TextFormField(
                key: const Key('location.hours'),
                controller: _hours,
                decoration: const InputDecoration(
                  hintText: 'e.g. Open 7:00 AM – 6:00 PM',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                key: const Key('location.save'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save Location'),
              ),
              const SizedBox(height: 12),
              const Text(
                'New locations are saved on your phone first and upload '
                'automatically when you are online.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photo,
    required this.missing,
    required this.onTap,
  });

  final File? photo;
  final bool missing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = photo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: p == null ? 'Add a photo' : 'Change photo',
          child: InkWell(
            key: const Key('location.photo'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 180,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: missing ? AppColors.brand : const Color(0xFFBDBDBD),
                ),
              ),
              child: p == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 36),
                        SizedBox(height: 8),
                        Text('Add a photo'),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(p, fit: BoxFit.cover),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Change photo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (missing)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 12),
            child: Text(
              'Add a photo of the location.',
              style: TextStyle(color: AppColors.brand, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
