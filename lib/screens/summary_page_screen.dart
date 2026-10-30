import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SummaryPage extends StatefulWidget {
  final String? studentName;
  final String? program;
  final String? specialization;

  const SummaryPage({
    super.key,
    this.studentName,
    this.program,
    this.specialization,
  });

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  String _name = '';
  String _id = '';
  String _email = '';
  String _program = '';
  String _year = '';
  String _contact = '';
  String _address = '';

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
  }

  Future<void> _loadSummaryData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _name = prefs.getString('studentName') ?? widget.studentName ?? 'N/A';
        _id = prefs.getString('studentId') ?? 'N/A';
        _email = prefs.getString('email') ?? 'N/A';
        _program = prefs.getString('program') ?? widget.program ?? 'N/A';
        _year = prefs.getString('yearLevel') ?? 'N/A';
        _contact = prefs.getString('contactNumber') ?? 'N/A';
        _address = prefs.getString('address') ?? 'N/A';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Summary Page",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Name"),
              subtitle: Text(_name),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge),
              title: const Text("Student ID"),
              subtitle: Text(_id),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email),
              title: const Text("Email"),
              subtitle: Text(_email),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.school),
              title: const Text("Program"),
              subtitle: Text(_program),
            ),
          ),
          if (widget.specialization != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.star),
                title: const Text("Specialization"),
                subtitle: Text(widget.specialization!),
              ),
            ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Year Level"),
              subtitle: Text(_year),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone),
              title: const Text("Contact Number"),
              subtitle: Text(_contact),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Address"),
              subtitle: Text(_address),
            ),
          ),
        ],
      ),
    );
  }
}
