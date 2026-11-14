import 'package:flutter/material.dart';

import '../services/api.dart';

class DashboardCards extends StatefulWidget {
  const DashboardCards({super.key});

  @override
  State<DashboardCards> createState() => _DashboardCardsState();
}

class _DashboardCardsState extends State<DashboardCards> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LPU Dashboard")),
      body: SafeArea(
        top: false,
        bottom: false,
        child: FutureBuilder(
          future: getUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text("API Error");
            }

            var users = snapshot.data!;

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return Card(child: ListTile(title: Text(users[index]['name'])));
              },
            );
          },
        ),
      ),
    );
  }
}
