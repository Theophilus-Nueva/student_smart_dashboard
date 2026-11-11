import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationFormBody extends StatefulWidget {
  const RegistrationFormBody({super.key});

  @override
  State<RegistrationFormBody> createState() => _RegistrationFormBodyState();
}

class _RegistrationFormBodyState extends State<RegistrationFormBody> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _programController = TextEditingController();
  final _yearController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _nameController.text = prefs.getString('studentName') ?? '';
        _idController.text = prefs.getString('studentId') ?? '';
        _emailController.text = prefs.getString('email') ?? '';
        _programController.text = prefs.getString('program') ?? '';
        _yearController.text = prefs.getString('yearLevel') ?? '';
        _contactController.text = prefs.getString('contactNumber') ?? '';
        _addressController.text = prefs.getString('address') ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _programController.dispose();
    _yearController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final isEmpty =
        _nameController.text.trim().isEmpty ||
        _idController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _programController.text.trim().isEmpty ||
        _yearController.text.trim().isEmpty ||
        _contactController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty;

    if (isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('studentName', _nameController.text.trim());
    await prefs.setString('studentId', _idController.text.trim());
    await prefs.setString('email', _emailController.text.trim());
    await prefs.setString('program', _programController.text.trim());
    await prefs.setString('yearLevel', _yearController.text.trim());
    await prefs.setString('contactNumber', _contactController.text.trim());
    await prefs.setString('address', _addressController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration Saved to SharedPreferences!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Student Registration",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text("Student Name:"),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text("Student ID:"),
          TextField(
            controller: _idController,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text("Email Address:"),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text("Program:"),
          TextField(
            controller: _programController,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text("Year Level:"),
          TextField(
            controller: _yearController,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text("Contact Number:"),
          TextField(
            controller: _contactController,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text("Address:"),
          TextField(
            controller: _addressController,
            maxLines: 3,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _submitForm, child: const Text("Submit")),
        ],
      ),
    );
  }
}
