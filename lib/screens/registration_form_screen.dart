import 'package:flutter/material.dart';

class RegistrationFormBody extends StatelessWidget {
  const RegistrationFormBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text("Student Name:"),
        TextField(),
        Text("Student ID:"),
        TextField(),
        Text("Email Address:"),
        TextField(),
        Text("Program:"),
        TextField(),
        Text("Year Level:"),
        TextField(),
        Text("Contact Number:"),
        TextField(),
        Text("Address:"),
        TextField(),
      ],
    );
  }
}
