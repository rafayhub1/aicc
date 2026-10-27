import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/place.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../services/place_photo_store.dart';
import '../../widgets/app_button.dart';
import 'admin_shell.dart';

class AdminPlaceFormScreen extends StatefulWidget {
  const AdminPlaceFormScreen({super.key, this.place});

  final CampusPlace? place;

  @override
  State<AdminPlaceFormScreen> createState() => _AdminPlaceFormScreenState();
}

class _AdminPlaceFormScreenState extends State<AdminPlaceFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _id;
  late final TextEditingController _name;
  late final TextEditingController _aliases;
  late final TextEditingController _hours;
  late final TextEditingController _description;
  late final TextEditingController _building;
  late final TextEditingController _floor;
  late String _nodeId;
  late String _category;
  late bool _active;
  late double _lat;
  late double _lng;
  String _photo = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final place = widget.place;
    _id = TextEditingController(text: place?.id ?? '');
    _name = TextEditingController(text: place?.name ?? '');
    _aliases = TextEditingController(text: place?.aliases.join('; ') ?? '');
    _hours = TextEditingController(text: place?.hours ?? '');
    _description = TextEditingController(text: place?.description ?? '');
    _building = TextEditingController(text: place?.building ?? '');
    _floor = TextEditingController(text: place?.floor ?? '');
    _nodeId = place?.nodeId ?? '';
    _category = place?.category ?? 'Academic';
    _active = place?.isActive ?? true;
    _lat = place?.lat ?? 31.4698;
    _lng = place?.lng ?? 74.4064;
    _photo = place?.photoUrl ?? '';
  }

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _aliases.dispose();
    _hours.dispose();
    _description.dispose();
    _building.dispose();
    _floor.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (file == null || !mounted) return;
    try {
      final id = _id.text.trim().isEmpty ? 'place' : _id.text.trim();
      final url = await PlacePhotoStore.upload(File(file.path), id);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _photo = url);
        showAdminNotice(context, 'Photo uploaded.');
      });
    } catch (error) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showAdminNotice(context, '$error');
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final id = _id.text.trim();
    final place = CampusPlace(
      id: id,
      name: _name.text.trim(),
      aliases: _aliases.text.split(RegExp(r'[;,]')).map((item) => item.trim()).where((item) => item.isNotEmpty).toList(),
      category: _category,
      lat: _lat,
      lng: _lng,
      entranceLat: _lat,
      entranceLng: _lng,
      building: _building.text.trim(),
      floor: _floor.text.trim(),
      hours: _hours.text.trim(),
      description: _description.text.trim(),
      photoUrl: _photo,
      nodeId: _nodeId,
      isActive: _active,
    );
    try {
      await context.read<ApiService>().savePlace(place.toMap(), create: widget.place == null);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.place?.id;
    if (id == null) return;
    setState(() => _saving = true);
    try {
      await context.read<ApiService>().deletePlace(id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.place == null ? 'New place' : 'Edit place')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _id,
              enabled: widget.place == null,
              decoration: const InputDecoration(labelText: 'Id'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _aliases,
              decoration: const InputDecoration(labelText: 'Aliases, separated by semicolons'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [for (final category in placeCategories) DropdownMenuItem(value: category, child: Text(category))],
              onChanged: (value) => setState(() => _category = value ?? _category),
            ),
            TextFormField(controller: _building, decoration: const InputDecoration(labelText: 'Building')),
            TextFormField(controller: _floor, decoration: const InputDecoration(labelText: 'Floor')),
            TextFormField(controller: _hours, decoration: const InputDecoration(labelText: 'Hours, for example 08:30-16:00')),
            TextFormField(controller: _description, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
            SwitchListTile(
              value: _active,
              onChanged: (value) => setState(() => _active = value),
              title: const Text('Active'),
            ),
            TextButton.icon(onPressed: _pickPhoto, icon: const Icon(Icons.photo_outlined), label: Text(_photo.isEmpty ? 'Upload photo' : 'Replace photo')),
            const SizedBox(height: 12),
            AppButton(label: 'Save place', loading: _saving, onPressed: _saving ? null : _save),
            if (widget.place != null) ...[
              const SizedBox(height: 8),
              AppButton(label: 'Delete', variant: AppButtonVariant.danger, onPressed: _saving ? null : _delete),
            ],
          ],
        ),
      ),
    );
  }
}
