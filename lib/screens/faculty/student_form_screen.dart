import 'package:flutter/material.dart';

import '../../widgets/app_dropdown_field.dart';

import '../../models/activity_item.dart';
import '../../models/student.dart';
import '../../services/app_services.dart';
import '../../widgets/common.dart';

/// Faculty / Add Student, also used for Edit (Week 3 form → Week 4 CRUD).
/// Required: name, ID, email, programme, year level. Optional: grade,
/// contact number, address.
class StudentFormScreen extends StatefulWidget {
  const StudentFormScreen({super.key, this.studentId});

  /// Null for Add, the existing ID for Edit.
  final String? studentId;

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _id = TextEditingController();
  final _email = TextEditingController();
  final _grade = TextEditingController();
  final _contact = TextEditingController();
  final _address = TextEditingController();
  String? _program;
  String? _year;
  Student? _original;
  bool _loaded = false;

  bool get _isEdit => widget.studentId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    if (!_isEdit) return;
    final s = AppScope.of(context).students.byId(widget.studentId!);
    if (s == null) return;
    _original = s;
    _name.text = s.name;
    _id.text = s.id;
    _email.text = s.email;
    _grade.text = s.grade.toStringAsFixed(1);
    _contact.text = s.contact;
    _address.text = s.address;
    _program = s.program;
    _year = s.yearLevel;
  }

  @override
  void dispose() {
    for (final c in [_name, _id, _email, _grade, _contact, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, String what) =>
      (v == null || v.trim().isEmpty) ? 'Please enter the $what.' : null;

  Future<void> _save() async {
    final services = AppScope.of(context);
    final repo = services.students;
    if (!_formKey.currentState!.validate()) {
      showAppSnack(context, 'Please fill in all required fields.', error: true);
      return;
    }
    final id = _id.text.trim();
    if (id != _original?.id && repo.idExists(id)) {
      showAppSnack(context, 'Student ID $id already exists.', error: true);
      return;
    }
    final student = Student(
      id: id,
      name: _name.text.trim(),
      email: _email.text.trim(),
      program: _program!,
      yearLevel: _year!,
      grade: double.tryParse(_grade.text.trim()) ?? 0,
      contact: _contact.text.trim(),
      address: _address.text.trim(),
    );
    if (_isEdit) {
      await repo.update(_original!.id, student);
    } else {
      await repo.add(student);
    }
    await services.activity.add(
      ActivityKind.record,
      _isEdit ? 'Student updated' : 'Student added',
      '${student.name} · ${student.id}',
    );
    if (!mounted) return;
    showAppSnack(context, 'Saved ${student.name}');
    Navigator.of(context).pop();
  }

  Widget _label(String text, {bool required = true}) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(required ? '$text *' : text),
  );

  @override
  Widget build(BuildContext context) {
    final missing = _isEdit && _original == null;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Student' : 'Add Student')),
      body: missing
          ? const StateMessage(
              icon: Icons.person_off,
              title: 'Student not found',
              message: 'This record may have been deleted.',
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _label('Student Name'),
                  TextFormField(
                    key: const Key('form.name'),
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Last name, First name M.',
                    ),
                    validator: (v) => _required(v, 'student name'),
                  ),
                  _label('Student ID'),
                  TextFormField(
                    key: const Key('form.id'),
                    controller: _id,
                    decoration: const InputDecoration(hintText: '2024-1-00123'),
                    validator: (v) => _required(v, 'student ID'),
                  ),
                  _label('Email Address'),
                  TextFormField(
                    key: const Key('form.email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final empty = _required(v, 'email address');
                      if (empty != null) return empty;
                      return v!.contains('@') ? null : 'Enter a valid email.';
                    },
                  ),
                  _label('Program'),
                  AppDropdownField<String>(
                    key: const Key('form.program'),
                    initialValue: _program,
                    values: Student.programs,
                    labelOf: (p) => Student.programNames[p] ?? p,
                    onChanged: (v) => setState(() => _program = v),
                    validator: (v) => v == null ? 'Choose a program.' : null,
                  ),
                  _label('Year Level'),
                  AppDropdownField<String>(
                    key: const Key('form.year'),
                    initialValue: _year,
                    values: Student.yearLevels,
                    labelOf: (y) => y,
                    onChanged: (v) => setState(() => _year = v),
                    validator: (v) => v == null ? 'Choose a year level.' : null,
                  ),
                  _label('Grade', required: false),
                  TextFormField(
                    key: const Key('form.grade'),
                    controller: _grade,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final g = double.tryParse(v.trim());
                      return g == null || g < 0 || g > 100
                          ? 'Enter a grade from 0 to 100.'
                          : null;
                    },
                  ),
                  _label('Contact Number', required: false),
                  TextFormField(
                    controller: _contact,
                    keyboardType: TextInputType.phone,
                  ),
                  _label('Address', required: false),
                  TextFormField(controller: _address, maxLines: 3),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    key: const Key('form.save'),
                    onPressed: _save,
                    child: Text(_isEdit ? 'Save Changes' : 'Save Student'),
                  ),
                ],
              ),
            ),
    );
  }
}
