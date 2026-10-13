import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget{
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: const Text("Theophilus T. Nueva"),
        subtitle: const Text("BS Information Technology\nSamsung Galaxy A54"),
        minTileHeight: 50,
      ),
    );
  }
}