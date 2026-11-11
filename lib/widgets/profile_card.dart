import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.person, color: Colors.amber),
        ),
        title: const Text("Theophilus T. Nueva"),
        subtitle: const Text("BS Information Technology\nLPU Cavite"),
        minTileHeight: 50,
      ),
    );
  }
}
